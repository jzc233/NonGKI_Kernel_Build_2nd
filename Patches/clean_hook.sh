#!/bin/bash
# Shell authon: JackA1ltman <cs2dtzq@163.com>
# Tested kernel versions: 5.4, 4.19, 4.14, 4.9, 4.4, 3.18
# 20251120

CLEAN_FILES=("fs/exec.c" "fs/read_write.c" "fs/open.c" "fs/stat.c" "fs/devpts/inode.c" "drivers/input/input.c" "drivers/tty/pty.c" "security/selinux/hooks.c" "kernel/reboot.c" "kernel/sys.c")

for file in "${CLEAN_FILES[@]}"; do
    sed -i '/#ifdef CONFIG_KSU/,/#endif/d' "${file}"

    if grep "CONFIG_KSU" "${file}"; then
        echo "[-] Could not remove hook from ${file}"
    else
        echo "Cleaned Hook for ${file}."
    fi
done
