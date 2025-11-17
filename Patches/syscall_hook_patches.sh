#!/bin/bash
# Patches author: backslashxx @ Github
# Shell authon: JackA1ltman <cs2dtzq@163.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9, 4.4, 3.18
# 20250309

patch_files=(
    fs/exec.c
    fs/open.c
    fs/read_write.c
    fs/stat.c
    fs/namei.c
    drivers/input/input.c
    drivers/tty/pty.c
    security/security.c
    security/selinux/hooks.c
    kernel/reboot.c
    kernel/sys.c
)

PATCH_LEVEL="1.6"
KERNEL_VERSION=$(head -n 3 Makefile | grep -E 'VERSION|PATCHLEVEL' | awk '{print $3}' | paste -sd '.')
FIRST_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $1}')
SECOND_VERSION=$(echo "$KERNEL_VERSION" | awk -F '.' '{print $2}')

echo "Current syscall patch version:$PATCH_LEVEL"

for i in "${patch_files[@]}"; do

    if grep -q "ksu" "$i"; then
        echo "[-] Warning: $i contains KernelSU"
        echo "[+] Code in here:"
        grep -n "ksu" "$i"
        echo "[-] End of file."
        continue
    fi

    case $i in

    # fs/ changes
    ## exec.c
    fs/exec.c)
        if grep -q "ksu_handle_execve_ksud" "drivers/kernelsu/ksud.c"; then
            echo "[+] Checked ksu_handle_execve_ksud existed in KernelSU!"

            sed -i '/^SYSCALL_DEFINE3(execve,/i\n#ifdef CONFIG_KSU\nextern bool ksu_execveat_hook __read_mostly;\extern __attribute__((hot, always_inline)) int ksu_handle_execve_sucompat(int *fd, const char __user **filename_user,\n\t\t\t       void *__never_use_argv, void *__never_use_envp,\n\t\t\t       int *__never_use_flags);\nextern int ksu_handle_execve_ksud(const char __user *filename_user,\n\t\t\tconst char __user *const __user *__argv);\n#endif\n' fs/exec.c
            sed -i '/return do_execve(getname(filename), argv, envp);/i\#ifdef CONFIG_KSU\n\tif (unlikely(ksu_execveat_hook))\n\t\tksu_handle_execve_ksud(filename, argv);\n\telse\n\t\tksu_handle_execve_sucompat((int *)AT_FDCWD, \&filename, NULL, NULL, NULL);\n#endif' fs/exec.c
            sed -i '/return compat_do_execve(getname(filename), argv, envp);/i\#ifdef CONFIG_KSU\n\tif (!ksu_execveat_hook)\n\t\tksu_handle_execve_sucompat((int *)AT_FDCWD, \&filename, NULL, NULL, NULL);\n#endif' fs/exec.c
        else
            echo "[-] KernelSU have no execve_ksud."

            sed -i '/^SYSCALL_DEFINE3(execve,/i\#ifdef CONFIG_KSU\n__attribute__((hot))\nextern int ksu_handle_execve_sucompat(int *fd,  const char __user **filename_user,\n\t\t\t\tvoid *__never_use_argv, void *__never_use_envp,\n\t\t\t\tint *__never_use_flags);\n#endif\n' fs/exec.c
            sed -i '/return do_execve(getname(filename), argv, envp);/i\#ifdef CONFIG_KSU\n\tksu_handle_execve_sucompat((int *)AT_FDCWD, \&filename, NULL, NULL, NULL);\n#endif' fs/exec.c
            sed -i '/return compat_do_execve(getname(filename), argv, envp);/i\#ifdef CONFIG_KSU\n\tksu_handle_execve_sucompat((int *)AT_FDCWD, \&filename, NULL, NULL, NULL);\n#endif' fs/exec.c
        fi

        if grep -q "ksu_handle_execve_sucompat" "fs/exec.c"; then
            echo "[+] fs/exec.c Patched!"
        else
            echo "[-] fs/exec.c patch failed for unknown reasons, please provide feedback in time."
        fi
        ;;

    ## open.c
    fs/open.c)
        if [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 19 ]; then
            sed -i '/^SYSCALL_DEFINE3(faccessat, int, dfd, const char __user \*, filename, int, mode)/i\#ifdef CONFIG_KSU\n__attribute__((hot))\nextern int ksu_handle_faccessat(int *dfd, const char __user **filename_user,\n\t\t\t\tint *mode, int *flags);\n#endif\n' fs/open.c
            sed -i '/if (mode & ~S_IRWXO)/i \#ifdef CONFIG_KSU\n\tksu_handle_faccessat(&dfd, &filename, &mode, NULL);\n#endif' fs/open.c
        else
            sed -i '/^SYSCALL_DEFINE3(faccessat, int, dfd, const char __user \*, filename, int, mode)/i\#ifdef CONFIG_KSU\n__attribute__((hot))\nextern int ksu_handle_faccessat(int *dfd, const char __user **filename_user,\n\t\t\t\tint *mode, int *flags);\n#endif\n' fs/open.c
            sed -i '/return do_faccessat(dfd, filename, mode);/i \#ifdef CONFIG_KSU\n\tksu_handle_faccessat(&dfd, &filename, &mode, NULL);\n#endif' fs/open.c
        fi

        if grep -q "ksu_handle_faccessat" "fs/open.c"; then
            echo "[+] fs/open.c Patched!"
        else
            echo "[-] fs/open.c patch failed for unknown reasons, please provide feedback in time."
        fi
        ;;

    ## read_write.c
    fs/read_write.c)
        if [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 19 ]; then
            sed -i '/^SYSCALL_DEFINE3(read, unsigned int, fd, char __user \*, buf, size_t, count)/i \#ifdef CONFIG_KSU\nextern bool ksu_vfs_read_hook __read_mostly;\nextern __attribute__((cold)) int ksu_handle_sys_read(unsigned int fd,\n\t\t\tchar __user **buf_ptr, size_t *count_ptr);\n#endif' fs/read_write.c
            sed -i '0,/if (f\.file) {/{s/if (f\.file) {/\n#ifdef CONFIG_KSU\n\tif (unlikely(ksu_vfs_read_hook))\n\t\tksu_handle_sys_read(fd, \&buf, \&count);\n#endif\n\tif (f.file) {/}' fs/read_write.c
        else
            sed -i '/^SYSCALL_DEFINE3(read, unsigned int, fd, char __user \*, buf, size_t, count)/i \#ifdef CONFIG_KSU\nextern bool ksu_vfs_read_hook __read_mostly;\nextern __attribute__((cold)) int ksu_handle_sys_read(unsigned int fd,\n\t\t\tchar __user **buf_ptr, size_t *count_ptr);\n#endif' fs/read_write.c
            sed -i '/return ksys_read(fd, buf, count);/i\#ifdef CONFIG_KSU\n\tif (unlikely(ksu_vfs_read_hook))\n\t\tksu_handle_sys_read(fd, &buf, &count);\n#endif' fs/read_write.c
        fi

        if grep -q "ksu_handle_sys_read" "fs/read_write.c"; then
            echo "[+] fs/read_write.c Patched!"
        else
            echo "[-] fs/read_write.c patch failed for unknown reasons, please provide feedback in time."
        fi
        ;;

    ## stat.c
    fs/stat.c)
        sed -i '/^#if !defined(__ARCH_WANT_STAT64) || defined(__ARCH_WANT_SYS_NEWFSTATAT)/i\#ifdef CONFIG_KSU\n__attribute__((hot))\nextern int ksu_handle_stat(int *dfd, const char __user **filename_user,\n\t\t\t\tint *flags);\n#endif\n' fs/stat.c
        sed -i '/error = vfs_fstatat(dfd, filename, \&stat, flag);/i\#ifdef CONFIG_KSU\n\tksu_handle_stat(\&dfd, \&filename, \&flag);\n#endif' fs/stat.c

        if grep -q "ksu_handle_stat" "fs/stat.c"; then
            echo "[+] fs/stat.c Patched!"
        else
            echo "[-] fs/stat.c patch failed for unknown reasons, please provide feedback in time."
        fi
        ;;

    ## namei.c
    fs/namei.c)
        if [ "$FIRST_VERSION" -lt 4 ] && [ "$SECOND_VERSION" -lt 5 ]; then
            sed -i '/err = lookup_slow(nd, name, path);/c \ \t\tif (strstr(current->comm, "throne_tracker") == NULL)\n\t\t\terr = lookup_slow(nd, name, path);\n\t\telse\n\t\t\terr = -ENOENT;\n' fs/namei.c

            if grep -q "throne_tracker" "fs/namei.c"; then
                echo "[+] fs/namei.c Patched!"
            else
                echo "[-] fs/namei.c patch failed for unknown reasons, please provide feedback in time."
            fi
        elif [ "$FIRST_VERSION" -lt 4 ] && [ "$SECOND_VERSION" -lt 19 ]; then
            sed -i '/if (unlikely(err)) {/a \#ifdef CONFIG_KSU\n\t\tif (unlikely(strstr(current->comm, "throne_tracker"))) {\n\t\t\terr = -ENOENT;\n\t\t\tgoto out_err;\n\t\t}\n#endif' fs/namei.c

            if grep -q "throne_tracker" "fs/namei.c"; then
                echo "[+] fs/namei.c Patched!"
            else
                echo "[-] fs/namei.c patch failed for unknown reasons, please provide feedback in time."
            fi
        fi
        ;;

    # drivers changes
    ## input/input.c
    drivers/input/input.c)
        sed -i '/^void input_event(struct input_dev \*dev,/i \#ifdef CONFIG_KSU\nextern bool ksu_input_hook __read_mostly;\nextern __attribute__((cold)) int ksu_handle_input_handle_event(\n\t\t\tunsigned int *type, unsigned int *code, int *value);\n#endif' drivers/input/input.c
        sed -i '0,/\tif (is_event_supported(type, dev->evbit, EV_MAX)) {/s//#ifdef CONFIG_KSU\n\tif (unlikely(ksu_input_hook))\n\t\tksu_handle_input_handle_event(\&type, \&code, \&value);\n#endif\n&/' drivers/input/input.c

        if grep -q "ksu_handle_input_handle_event" "drivers/input/input.c"; then
            echo "[+] drivers/input/input.c Patched!"
        else
            echo "[-] drivers/input/input.c patch failed for unknown reasons, please provide feedback in time."
        fi
        ;;
    ## tty/pty.c
    drivers/tty/pty.c)
        if grep -q "ksu_handle_devpts" "kernel/sucompat.c"; then
            echo "[+] Checked ksu_handle_devpts existed in KernelSU!"

            sed -i '/^static struct tty_struct \*pts_unix98_lookup(struct tty_driver \*driver,/i\#ifdef CONFIG_KSU\nextern int ksu_handle_devpts(struct inode*);\n#endif\n' drivers/tty/pty.c
            sed -i '0,/struct tty_struct \*tty;/{s/struct tty_struct \*tty;/&\n#ifdef CONFIG_KSU\n\tksu_handle_devpts((struct inode *)file->f_path.dentry->d_inode);\n#endif/}' drivers/tty/pty.c

            if grep -q "ksu_handle_devpts" "drivers/tty/pty.c"; then
                echo "[+] drivers/tty/pty.c Patched!"
            else
                echo "[-] drivers/tty/pty.c patch failed for unknown reasons, please provide feedback in time."
            fi
        else
            echo "[-] KernelSU have no devpts, Skipped."
        fi
        ;;

    # security/ changes
    ## security.c
    security/security.c)
        if [ "$FIRST_VERSION" -lt 4 ] && [ "$SECOND_VERSION" -lt 19 ]; then
            sed -i '/int security_binder_set_context_mgr(struct task_struct/i \#ifdef CONFIG_KSU\n\extern int ksu_bprm_check(struct linux_binprm *bprm);\n\extern int ksu_handle_rename(struct dentry *old_dentry, struct dentry *new_dentry);\n\extern int ksu_handle_setuid(struct cred *new, const struct cred *old);\n\extern int ksu_key_permission(key_ref_t key_ref, const struct cred *cred,\n\t\t\t\tunsigned perm);\n\#endif' security/security.c
            sed -i '/ret = security_ops->bprm_check_security(bprm);/i \#ifdef CONFIG_KSU\n\tksu_bprm_check(bprm);\n\#endif' security/security.c
            sed -i '/if (unlikely(IS_PRIVATE(old_dentry->d_inode) ||/i \#ifdef CONFIG_KSU\n\tksu_handle_rename(old_dentry, new_dentry);\n\#endif' security/security.c
            sed -i '/return security_ops->task_fix_setuid(new, old, flags);/i \#ifdef CONFIG_KSU\n\tksu_handle_setuid(new, old);\n\#endif' security/security.c
            sed -i '/return security_ops->key_permission(key_ref, cred, perm);/i \#ifdef CONFIG_KSU\n\tksu_key_permission(key_ref, cred, perm);\n\#endif' security/security.c

            if grep -q "ksu_handle_setuid" "security/security.c"; then
                echo "[+] security/security.c Patched!"
            else
                echo "[-] security/security.c patch failed for unknown reasons, please provide feedback in time."
            fi
        fi
        ;;

    ## selinux/hooks.c
    security/selinux/hooks.c)
        if [ "$FIRST_VERSION" -lt 4 ] && [ "$SECOND_VERSION" -lt 18 ]; then
            sed -i '/^static int selinux_bprm_set_creds(struct linux_binprm \*bprm)/i \#ifdef CONFIG_KSU\nextern bool is_ksu_transition(const struct task_security_struct *old_tsec,\n\t\t\t\tconst struct task_security_struct *new_tsec);\n#endif' security/selinux/hooks.c
            sed -i '/^\s*new_tsec->exec_sid = 0;/a \#ifdef CONFIG_KSU\n\t\tif (is_ksu_transition(old_tsec, new_tsec))\n\t\t\treturn 0;\n#endif' security/selinux/hooks.c

            if grep -q "is_ksu_transition" "security/selinux/hooks.c"; then
                echo "[+] security/selinux/hooks.c Patched!"
            else
                echo "[-] security/selinux/hooks.c patch failed for unknown reasons, please provide feedback in time."
            fi
        elif [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 10 ] && grep -q "grab_transition_sids" "drivers/kernelsu/ksud.c"; then
            sed -i '/^static int check_nnp_nosuid(const struct linux_binprm \*bprm,/i\#ifdef CONFIG_KSU\nextern bool is_ksu_transition(const struct task_security_struct *old_tsec,\n\t\t\t\tconst struct task_security_struct *new_tsec);\n#endif\n' security/selinux/hooks.c
            sed -i '/rc = security_bounded_transition(old_tsec->sid, new_tsec->sid);/i\#ifdef CONFIG_KSU\n\tif (is_ksu_transition(old_tsec, new_tsec))\n\t\treturn 0;\n#endif\n' security/selinux/hooks.c

            if grep -q "is_ksu_transition" "security/selinux/hooks.c"; then
                echo "[+] security/selinux/hooks.c Patched!"
            else
                echo "[-] security/selinux/hooks.c patch failed for unknown reasons, please provide feedback in time."
            fi
        elif [ "$FIRST_VERSION" -lt 5 ] && [ "$SECOND_VERSION" -lt 10 ]; then
            sed -i '/int nnp = (bprm->unsafe & LSM_UNSAFE_NO_NEW_PRIVS);/i\#ifdef CONFIG_KSU\n    static u32 ksu_sid;\n    char *secdata;\n#endif' security/selinux/hooks.c
            sed -i '/if (!nnp && !nosuid)/i\#ifdef CONFIG_KSU\n    int error;\n    u32 seclen;\n#endif' security/selinux/hooks.c
            sed -i '/return 0; \/\* No change in credentials \*\//a\\n#ifdef CONFIG_KSU\n    if (!ksu_sid)\n        security_secctx_to_secid("u:r:su:s0", strlen("u:r:su:s0"), &ksu_sid);\n\n    error = security_secid_to_secctx(old_tsec->sid, &secdata, &seclen);\n    if (!error) {\n        rc = strcmp("u:r:init:s0", secdata);\n        security_release_secctx(secdata, seclen);\n        if (rc == 0 && new_tsec->sid == ksu_sid)\n            return 0;\n    }\n#endif' security/selinux/hooks.c
        fi
        ;;

    # kernel/ changes
    ## kernel/reboot.c
    kernel/reboot.c)
        if [ -f "drivers/kernelsu/supercalls.c" ] || [ -f "drivers/kernelsu/core_hook.c" ]; then
            if grep -q "ksu_handle_sys_reboot" "drivers/kernelsu/core_hook.c"; then
                echo "[+] Checked ksu_handle_sys_reboot existed in KernelSU!"

                sed -i '/SYSCALL_DEFINE4(reboot, int, magic1, int, magic2, unsigned int, cmd,/i \#ifdef CONFIG_KSU\n\extern int ksu_handle_sys_reboot(int magic1, int magic2, unsigned int cmd, void __user **arg);\n\#endif' kernel/reboot.c
                sed -i '/int ret = 0;/a \#ifdef CONFIG_KSU\n\tksu_handle_sys_reboot(magic1, magic2, cmd, &arg);\n\#endif' kernel/reboot.c

                if grep -q "ksu_handle_sys_reboot" "kernel/reboot.c"; then
                    echo "[+] kernel/reboot.c Patched!"
                else
                    echo "[-] kernel/reboot.c patch failed for unknown reasons, please provide feedback in time."
                fi
            elif grep -q "ksu_handle_sys_reboot" "drivers/kernelsu/supercalls.c"; then
                echo "[+] Checked ksu_handle_sys_reboot existed in KernelSU!"

                sed -i '/SYSCALL_DEFINE4(reboot, int, magic1, int, magic2, unsigned int, cmd,/i \#ifdef CONFIG_KSU\n\extern int ksu_handle_sys_reboot(int magic1, int magic2, unsigned int cmd, void __user **arg);\n\#endif' kernel/reboot.c
                sed -i '/int ret = 0;/a \#ifdef CONFIG_KSU\n\tksu_handle_sys_reboot(magic1, magic2, cmd, &arg);\n\#endif' kernel/reboot.c

                if grep -q "ksu_handle_sys_reboot" "kernel/reboot.c"; then
                    echo "[+] kernel/reboot.c Patched!"
                else
                    echo "[-] kernel/reboot.c patch failed for unknown reasons, please provide feedback in time."
                fi
            fi
        else
            echo "[-] KernelSU have no sys_reboot, Skipped."
        fi
        ;;
    kernel/sys.c)
        if [ -f "drivers/kernelsu/setuid_hook.c" ] && grep -q "ksu_handle_setresuid " "drivers/kernelsu/setuid_hook.c"; then
            if grep -q "__sys_setresuid" "kernel/sys.c"; then
                echo "[+] Checked ksu_handle_setresuid existed in KernelSU!"

                sed -i '/^SYSCALL_DEFINE3(setresuid, uid_t, ruid, uid_t, euid, uid_t, suid)/i\#ifdef CONFIG_KSU\nextern int ksu_handle_setresuid(uid_t ruid, uid_t euid, uid_t suid);\n#endif\n' kernel/sys.c
                sed -i '/return __sys_setresuid(ruid, euid, suid);/i\#ifdef CONFIG_KSU\n\tif (ksu_handle_setresuid(ruid, euid, suid)) {\n\t\tpr_info("Something wrong with ksu_handle_setresuid()\\");\n\t}\n#endif' kernel/sys.c
            else
                sed -i '/^SYSCALL_DEFINE3(setresuid, uid_t, ruid, uid_t, euid, uid_t, suid)/i\#ifdef CONFIG_KSU\nextern int ksu_handle_setresuid(uid_t ruid, uid_t euid, uid_t suid);\n#endif\n' kernel/sys.c
                ed -i '0,/\tif ((ruid != (uid_t) -1) && !uid_valid(kruid))/b; /\tif ((ruid != (uid_t) -1) && !uid_valid(kruid))/i\#ifdef CONFIG_KSU_SUSFS\n\tif (ksu_handle_setresuid(ruid, euid, suid)) {\n\t\tpr_info("Something wrong with ksu_handle_setresuid()\\");\n\t}\n#endif' kernel/sys.c
            fi

            if grep -q "ksu_handle_setresuid" "kernel/sys.c"; then
                echo "[+] kernel/sys.c Patched!"
            else
                echo "[-] kernel/sys.c patch failed for unknown reasons, please provide feedback in time."
            fi
        else
            echo "[-] KernelSU have no setresuid, Skipped."
        fi
        ;;
    esac

done
