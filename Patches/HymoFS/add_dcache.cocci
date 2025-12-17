@@
@@
 error = path_with_deleted(path, &root, &res, &buflen);
 rcu_read_unlock();
+#ifdef CONFIG_HYMOFS
+	if (error < 0) {
+		return ERR_PTR(error);
+	}
+
+    {
+		char *src = hymofs_reverse_lookup(res);
+		if (src) {
+			if (strlen(src) < buflen) {
+				/* Overwrite with source path for masking */
+				strscpy(buf, src, buflen);
+				kfree(src);
+				return buf;
+			}
+			kfree(src);
+		}
+	    return res;
+    }
+#else
 if (error < 0)
 	res = ERR_PTR(error);
 return res;
+#endif
