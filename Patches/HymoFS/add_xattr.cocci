@@
@@
ssize_t
vfs_getxattr(struct dentry *dentry, const char *name, void *value, size_t size)
{
 struct inode *inode = dentry->d_inode;
 int error;
+#ifdef CONFIG_HYMOFS
+	if (hymofs_is_overlay_xattr(dentry, name))
+		return -ENODATA;
+#endif
...
}
