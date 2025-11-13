#!/bin/bash
# Patches author: backslashxx @ Github
# Shell author: JackA1ltman <cs2dtzq@163.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9, 4.4, 3.18, 3.10, 3.4
# 20250323
patch_files=(
    fs/namespace.c
    fs/internal.h
    security/selinux/hooks.c
    security/selinux/selinuxfs.c
    security/selinux/include/objsec.h
    include/linux/seccomp.h
)

KERNEL_VERSION=$(head -n 3 Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
FIRST_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $1}')
SECOND_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')

for i in "${patch_files[@]}"; do

    if grep -q "path_umount" "$i"; then
        echo "Warning: $i contains KernelSU"
        continue
    elif grep -q "selinux_inode(inode)" "$i"; then
        echo "Warning: $i contains KernelSU"
        continue
    fi

    case $i in

    # fs/ changes
    ## fs/namespace.c
    fs/namespace.c)
        if grep -q "static inline bool may_mandlock(void)" fs/namespace.c; then
            sed -i '/^static bool is_mnt_ns_file/i static int can_umount(const struct path *path, int flags)\n\{\n\tstruct mount *mnt = real_mount(path->mnt);\n\tif (flags & ~(MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW))\n\t\treturn -EINVAL;\n\tif (!may_mount())\n\t\treturn -EPERM;\n\tif (path->dentry != path->mnt->mnt_root)\n\t\treturn -EINVAL;\n\tif (!check_mnt(mnt))\n\t\treturn -EINVAL;\n\tif (mnt->mnt.mnt_flags & MNT_LOCKED)\n\t\treturn -EINVAL;\n\tif (flags & MNT_FORCE && !capable(CAP_SYS_ADMIN))\n\t\treturn -EPERM;\n\treturn 0;\n}\n' fs/namespace.c
            sed -i '/^static bool is_mnt_ns_file/i int path_umount(struct path *path, int flags)\n{\n\tstruct mount *mnt = real_mount(path->mnt);\n\tint ret;\n\tret = can_umount(path, flags);\n\tif (!ret)\n\t\tret = do_umount(mnt, flags);\n\tdput(path->dentry);\n\tmntput_no_expire(mnt);\n\treturn ret;\n}\n' fs/namespace.c
        else
            sed -i '/SYSCALL_DEFINE2(umount, char __user \*, name, int, flags)/i\#ifdef CONFIG_KSU\nstatic int can_umount(const struct path *path, int flags)\n{\n\tstruct mount *mnt = real_mount(path->mnt);\n\n\tif (flags & ~(MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW))\n\t\treturn -EINVAL;\n\tif (!may_mount())\n\t\treturn -EPERM;\n\tif (path->dentry != path->mnt->mnt_root)\n\t\treturn -EINVAL;\n\tif (!check_mnt(mnt))\n\t\treturn -EINVAL;\n\tif (mnt->mnt.mnt_flags & MNT_LOCKED) /* Check optimistically */\n\t\treturn -EINVAL;\n\tif (flags & MNT_FORCE && !capable(CAP_SYS_ADMIN))\n\t\treturn -EPERM;\n\treturn 0;\n}\n\nint path_umount(struct path *path, int flags)\n{\n\tstruct mount *mnt = real_mount(path->mnt);\n\tint ret;\n\n\tret = can_umount(path, flags);\n\tif (!ret)\n\t\tret = do_umount(mnt, flags);\n\n\t/* we mustn'\''t call path_put() as that would clear mnt_expiry_mark */\n\tdput(path->dentry);\n\tmntput_no_expire(mnt);\n\treturn ret;\n}\n#endif\n' fs/namespace.c
        fi
        ;;
    ## fs/internal.h
    fs/internal.h)
        if grep -q "extern void __mnt_drop_write_file(struct file \*)" fs/internal.h; then
            sed -i '/extern void __mnt_drop_write_file(struct file \*);/a int path_umount(struct path \*path, int flags);' fs/internal.h
        elif grep -q "extern void __init mnt_init(void)" fs/internal.h; then
            sed -i '/extern void __init mnt_init(void);/a int path_umount(struct path *path, int flags);' fs/internal.h
        else
            sed -i '/^extern void __init mnt_init/a int path_umount(struct path *path, int flags);' fs/internal.h
        fi
        ;;

    # security/
    ## selinux/hooks.c
    security/selinux/hooks.c)
        sed -i 's/inode->i_security/selinux_inode(inode)/g' security/selinux/hooks.c
        ;;
    ## selinux/selinuxfs.c
    security/selinux/selinuxfs.c)
        sed -i 's/(struct inode_security_struct \*)inode->i_security/selinux_inode(inode)/g' security/selinux/selinuxfs.c
        ;;
    ## selinux/include/objsec.h
    security/selinux/include/objsec.h)
        sed -i '/#endif \/\* _SELINUX_OBJSEC_H_ \*\//i\static inline struct inode_security_struct *selinux_inode(\n\t\t\t\t\t\tconst struct inode *inode)\n{\n\treturn inode->i_security;\n}' security/selinux/include/objsec.h
        ;;

    # include/ changes
    ## linux/seccomp.h
    include/linux/seccomp.h)
        if grep "atomic_t filter_count;" "/include/linux/seccomp.h"; then
            sed -i '/int mode;/a\	atomic_t filter_count;' include/linux/seccomp.h
            sed -i '/#include <linux\/thread_info.h>/a\#include <linux/atomic.h>' include/linux/seccomp.h
        fi
        ;;
    esac

done
