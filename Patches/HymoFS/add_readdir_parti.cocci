
@@
identifier f, buf, error;
@@
 	if (!f.file)
 		return -EBADF;
+#ifdef CONFIG_HYMOFS
+	hymofs_prepare_readdir(&buf.hymo, f.file);
+#endif
 	error = iterate_dir(f.file, &buf.ctx);
 	if (buf.result)
 		error = buf.result;
+#ifdef CONFIG_HYMOFS
+	hymofs_cleanup_readdir(&buf.hymo);
+#endif
 	fdput_pos(f);
