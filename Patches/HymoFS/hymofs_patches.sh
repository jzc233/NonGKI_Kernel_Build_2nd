#!/bin/bash
# Patches author: Anatdx @ Github
# Shell authon: JackA1ltman <cs2dtzq@163.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9, 4.4, 3.18
# 20251216

patch_files=(
    fs/Kconfig
    fs/Makefile
    fs/dcache.c
    fs/namei.c
    fs/readdir.c
    fs/stat.c
    fs/xattr.c
)

PATCH_LEVEL="1.3"
KERNEL_VERSION=$(head -n 3 Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
FIRST_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $1}')
SECOND_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')

echo "Current hymofs patch version:$PATCH_LEVEL"

for i in "${patch_files[@]}"; do

    if grep -q "CONFIG_HYMOFS" "$i"; then
        echo "[-] Warning: $i contains HymoFS"
        echo "[+] Code in here:"
        grep -n "CONFIG_HYMOFS" "$i"
        echo "[-] End of file."
        echo "======================================"
        continue
    fi

    case $i in

    # fs/ changes
    ## Kconfig
    fs/Kconfig)
        echo "======================================"

        sed -i '/menu "File systems"/a\ \nconfig HYMOFS\n\tbool "HymoFS support"\n\tdefault y\n\thelp\n\t  HymoFS is a kernel-level path manipulation and hiding framework.' fs/Kconfig

        if grep -q "HymoFS" "fs/Kconfig"; then
            echo "[+] fs/Kconfig Patched!"
            echo "[+] Count: $(grep -c "HymoFS" "fs/Kconfig")"
        else
            echo "[-] fs/Kconfig patch failed for unknown reasons, please provide feedback in time."
        fi

        echo "======================================"
        ;;

    ## Makefile
    fs/Makefile)
        sed -i '$a\obj-$(CONFIG_HYMOFS) += hymofs.o' fs/Makefile

        if grep -q "hymofs" "fs/Makefile"; then
            echo "[+] fs/Makefile Patched!"
            echo "[+] Count: $(grep -c "hymofs" "fs/Makefile")"
        else
            echo "[-] fs/Makefile patch failed for unknown reasons, please provide feedback in time."
        fi

        echo "======================================"
        ;;

    ## dcache.c
    fs/dcache.c)
        if [ -f "fs/d_path.c" ]; then
            echo "[+] Detected d_path."
            sed -i '/#include "mount.h"/a\#ifdef CONFIG_HYMOFS\n#include "hymofs.h"\n#endif\n' fs/d_path.c

            spatch --sp-file add_dcache.cocci --in-place fs/d_path.c
            rm -f add_dcache.cocci

        else
            echo "[-] Not detect d_path,so patch to dcache."
            sed -i '/#include "mount.h"/a\#ifdef CONFIG_HYMOFS\n#include "hymofs.h"\n#endif\n' fs/dcache.c

            spatch --sp-file add_dcache.cocci --in-place fs/dcache.c
            rm -f add_dcache.cocci
        fi

        if grep -q "hymofs" "fs/dcache.c"; then
            echo "[+] fs/dcache.c Patched!"
            echo "[+] Count: $(grep -c "hymofs" "fs/dcache.c")"
        elif grep -q "hymofs" "fs/d_path.c"; then
            echo "[+] fs/d_path.c Patched!"
            echo "[+] Count: $(grep -c "hymofs" "fs/d_path.c")"
        else
            echo "[-] fs/dcache.c or fs/d_path.c patch failed for unknown reasons, please provide feedback in time."
        fi

        echo "======================================"
        ;;

    ## namei.c
    fs/namei.c)
        sed -i '/#include "mount.h"/a\#ifdef CONFIG_HYMOFS\n#include "hymofs.h"\n#endif\n' fs/namei.c
        sed -i '/#define EMBEDDED_NAME_MAX\t(PATH_MAX - offsetof(struct filename, iname))/a\#ifdef CONFIG_HYMOFS\nstruct filename *__original_getname_flags(const char __user *filename, int flags, int *empty);\n\n/* Hook getname_flags to intercept path lookups */\nstruct filename *getname_flags(const char __user *filename, int flags, int *empty)\n{\n\tstruct filename *result = __original_getname_flags(filename, flags, empty);\n\treturn hymofs_handle_getname(result);\n}\n#endif\n' fs/namei.c
        sed -i '/^getname_flags(const char __user \*filename, int flags, int \*empty)/i\#ifdef CONFIG_HYMOFS\n__original_getname_flags(const char __user *filename, int flags, int *empty)\n#else' fs/namei.c
        sed -i '/^getname_flags(const char __user \*filename, int flags, int \*empty)/a\#endif' fs/namei.c

        if grep -q "hymofs" "fs/namei.c"; then
            echo "[+] fs/namei.c Patched!"
            echo "[+] Count: $(grep -c "hymofs" "fs/namei.c")"
        else
            echo "[-] fs/namei.c patch failed for unknown reasons, please provide feedback in time."
        fi

        echo "======================================"
        ;;

    ## readdir.c
    fs/readdir.c)
        sed -i '/#include <asm\/uaccess.h>/a\#ifdef CONFIG_HYMOFS\n#include "hymofs.h"\n#endif\n' fs/readdir.c
        sed -i '/int count;/{n;/int error;/a\#ifdef CONFIG_HYMOFS\n\tbool buffer_full;\n#endif
                                      }' fs/readdir.c
        sed -i '/struct dir_context ctx;/a\#ifdef CONFIG_HYMOFS\n\tstruct hymo_readdir_context hymo;\n#endif\n' fs/readdir.c
        sed -i '/buf->error = verify_dirent_name(name, namlen);/a \#ifdef CONFIG_HYMOFS\n\tif (hymofs_check_filldir(\&buf->hymo, name, strlen(name))) return true;\n#endif' fs/readdir.c
        sed -i '/if (unlikely(buf->error))/c\ \tif (reclen > buf->count) {\n#ifdef CONFIG_HYMOFS\n\t\tbuf->buffer_full = true;\n#endif' fs/readdir.c
        sed -i '/return buf->error;/a\ \t}' fs/readdir.c

        spatch --sp-file add_readdir_parti.cocci --in-place fs/readdir.c
        rm -f add_readdir_parti.cocci

        spatch --sp-file add_readdir_partii.cocci --in-place fs/readdir.c
        rm -f add_readdir_partii.cocci

        spatch --sp-file add_readdir_partiii.cocci --in-place fs/readdir.c
        rm -f add_readdir_partiii.cocci

        sed -i 's/void \*dir_ptr = buf\.current_dir;/void __user *dir_ptr = buf.current_dir;/' fs/readdir.c
        sed -i '/\.current_dir = dirent/a\#ifdef CONFIG_HYMOFS\n\t\t, .buffer_full = false\n#endif' fs/readdir.c

        if grep -q "hymofs" "fs/readdir.c"; then
            echo "[+] fs/readdir.c Patched!"
            echo "[+] Count: $(grep -c "hymofs" "fs/readdir.c")"
        else
            echo "[-] fs/readdir.c patch failed for unknown reasons, please provide feedback in time."
        fi

        echo "======================================"
        ;;

    ## stat.c
    fs/stat.c)
        sed -i '/#include <asm\unistd.h>/a\#ifdef CONFIG_HYMOFS\n#include "hymofs.h"\n#endif\n' fs/readdir.c
        sed -i '/query_flags &= KSTAT_QUERY_FLAGS;/a\#ifdef CONFIG_HYMOFS\n\tif (inode->i_op->getattr) {\n\t\tint ret = inode->i_op->getattr(path, stat, request_mask,\n\t\t\t\t\t\t\t\t\t   query_flags);\n        if (ret == 0)\n\t\t\thymofs_spoof_stat(path, stat);\n        return ret;\n    }\n#else' fs/stat.c
        sed -i '/generic_fillattr(inode, stat);/i\#endif' fs/stat.c
        sed -i '/generic_fillattr(inode, stat);/a\#ifdef CONFIG_HYMOFS\n\t/* HymoFS: Spoof timestamps if needed */\n\thymofs_spoof_stat(path, stat);\n#endif\n' fs/stat.c

        if grep -q "hymofs" "fs/stat.c"; then
            echo "[+] fs/stat.c Patched!"
            echo "[+] Count: $(grep -c "hymofs" "fs/stat.c")"
        else
            echo "[-] fs/stat.c patch failed for unknown reasons, please provide feedback in time."
        fi

        echo "======================================"
        ;;

    ## xattr.c
    fs/xattr.c)
        sed -i '/#include <asm\/uaccess.h>/a\#ifdef CONFIG_HYMOFS\n#include "hymofs.h"\n#endif\n' fs/xattr.c

        spatch --sp-file add_xattr.cocci --in-place fs/xattr.c
        rm -f add_xattr.cocci

        sed -i '/char \*klist = NULL;/a\#ifdef CONFIG_HYMOFS\n\tsize_t alloc_size = size;\n\n\tif (!size) {\n\t\tssize_t res = vfs_listxattr(d, NULL, 0);\n\t\tif (res <= 0)\n\t\t\treturn res;\n\t\talloc_size = res;\n\t}\n\n\tif (alloc_size > XATTR_LIST_MAX)\n\t\talloc_size = XATTR_LIST_MAX;\n\n\tklist = kmalloc(size, __GFP_NOWARN | GFP_KERNEL);\n\tif (!klist)\n\t\treturn -ENOMEM;\n\n\terror = vfs_listxattr(d, klist, alloc_size);\n\tif (error > 0) {\n\t\terror = hymofs_filter_xattrs(d, klist, error);\n\n\t\tif (size && copy_to_user(list, klist, error))\n\t\t\terror = -EFAULT;\n\t} else if (error == -ERANGE && size >= XATTR_LIST_MAX) {\n\t\t/* The file system tried to returned a list bigger\n\t\t   than XATTR_LIST_MAX bytes. Not possible. */\n\t\terror = -E2BIG;\n\t}\n#else' fs/xattr.c
        sed -i '/kvfree(klist);/i\#endif' fs/xattr.c

        if grep -q "hymofs" "fs/xattr.c"; then
            echo "[+] fs/xattr.c Patched!"
            echo "[+] Count: $(grep -c "hymofs" "fs/xattr.c")"
        else
            echo "[-] fs/xattr.c patch failed for unknown reasons, please provide feedback in time."
        fi

        echo "======================================"
        ;;
    esac

done
