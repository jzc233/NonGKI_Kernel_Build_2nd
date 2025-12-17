@@
identifier f, buf, error, lastdirent, count, d_off;
@@
 	f = fdget_pos(fd);
 	if (!f.file)
 		return -EBADF;
+#ifdef CONFIG_HYMOFS
+	hymofs_prepare_readdir(&buf.hymo, f.file);
+	if (f.file->f_pos >= HYMO_MAGIC_POS) {
+		void *dir_ptr = buf.current_dir;
+		int res = hymofs_inject_entries64(&buf.hymo, &dir_ptr, &buf.count, &f.file->f_pos);
+		if (res >= 0)
+			error = count - buf.count;
+		else
+			error = res;
+		hymofs_cleanup_readdir(&buf.hymo);
+		fdput_pos(f);
+		return error;
+	}
+#endif
 	error = iterate_dir(f.file, &buf.ctx);
 	if (error >= 0)
 		error = buf.error;
 	lastdirent = buf.previous;
 	if (lastdirent) {
 		typeof(lastdirent->d_off) d_off = buf.ctx.pos;
 		if (__put_user(d_off, &lastdirent->d_off))
 			error = -EFAULT;
 		else
 			error = count - buf.count;
 	}
+#ifdef CONFIG_HYMOFS
+	if (error >= 0 && !buf.buffer_full && buf.ctx.pos < HYMO_MAGIC_POS && !signal_pending(current) && buf.count == count) {
+		void *dir_ptr = buf.current_dir;
+		int res = hymofs_inject_entries64(&buf.hymo, &dir_ptr, &buf.count, &f.file->f_pos);
+		if (res > 0)
+			error = count - buf.count;
+	}
+	hymofs_cleanup_readdir(&buf.hymo);
+#endif
 	fdput_pos(f);
 	return error;
