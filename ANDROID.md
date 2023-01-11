# 步骤

## 下载指定NDK
sudo apt-get install axle
axel "https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip"
unzip android-ndk-r21e-linux-x86_64.zip -d ndk

## 生成及修改Toolchain
cd ndk/android-ndk-r21e/
./build/tools/make_standalone_toolchain.py --arch arm --api 21 --install-dir ~/arm-linux-androideabi
./build/tools/make_standalone_toolchain.py --arch arm64 --api 21 --install-dir ~/aarch64-linux-android

## 配置Toolchain
export PATH=$PATH:$HOME/arm-linux-androideabi/bin

## 配置模块（以udhcpd为例）
make menuconfig
打开networking/udhcpd,保存退出

## 修改一些兼容问题（参考尾部patch）

## 编译指定模块
注意模块名要大写
./make_single_applets.sh UDHCPD

## Patch

```patch
 # Native bionic (Android) port of Busybox

 ## Prepare a standalone Android Toolchain
diff --git a/Makefile.flags b/Makefile.flags
index 4d60f2f9a..98c0f001f 100644
--- a/Makefile.flags
+++ b/Makefile.flags
@@ -22,8 +22,9 @@ CFLAGS += $(call cc-option,-Wshadow,)
 CFLAGS += $(call cc-option,-Wwrite-strings,)
 CFLAGS += $(call cc-option,-Wundef,)
 CFLAGS += $(call cc-option,-Wstrict-prototypes,)
-CFLAGS += $(call cc-option,-Wunused -Wunused-parameter,)
-CFLAGS += $(call cc-option,-Wunused-function -Wunused-value,)
+CFLAGS += $(call cc-option,-Wstrict-prototypes,)
+#CFLAGS += $(call cc-option,-Wunused -Wunused-parameter,)
+#CFLAGS += $(call cc-option,-Wunused-function -Wunused-value,)
 CFLAGS += $(call cc-option,-Wmissing-prototypes -Wmissing-declarations,)
 CFLAGS += $(call cc-option,-Wno-format-security,)
 # warn about C99 declaration after statement
@@ -31,8 +32,12 @@ CFLAGS += $(call cc-option,-Wdeclaration-after-statement,)
 # If you want to add more -Wsomething above, make sure that it is
 # still possible to build bbox without warnings.

+CFLAGS += $(call cc-option,-Wno-unused-result,)
+CFLAGS += $(call cc-option,-Wno-error=unused-result,)
+
+
 ifeq ($(CONFIG_WERROR),y)
-CFLAGS += $(call cc-option,-Werror,)
+#CFLAGS += $(call cc-option,-Werror,)
 ## TODO:
 ## gcc version 4.4.0 20090506 (Red Hat 4.4.0-4) (GCC) is a PITA:
 ## const char *ptr; ... off_t v = *(off_t*)ptr; -> BOOM
diff --git a/include/libbb.h b/include/libbb.h
index 6aeec249d..47c7b1521 100644
--- a/include/libbb.h
+++ b/include/libbb.h
@@ -2339,7 +2339,7 @@ void XZALLOC_CONST_PTR(const void *pptr, size_t size) FAST_FUNC;
  * use bb_default_login_shell and following defines.
  * If you change LIBBB_DEFAULT_LOGIN_SHELL,
  * don't forget to change increment constant. */
-#define LIBBB_DEFAULT_LOGIN_SHELL  "-/bin/sh"
+#define LIBBB_DEFAULT_LOGIN_SHELL  "-/system/bin/sh"
 extern const char bb_default_login_shell[] ALIGN1;
 /* "/bin/sh" */
 #define DEFAULT_SHELL              (bb_default_login_shell+1)
diff --git a/init/init.c b/init/init.c
index 785a3b460..72f99dc61 100644
--- a/init/init.c
+++ b/init/init.c
@@ -1107,7 +1107,7 @@ int init_main(int argc UNUSED_PARAM, char **argv)
        /* Make sure environs is set to something sane */
        putenv((char *) "HOME=/");
        putenv((char *) bb_PATH_root_path);
-       putenv((char *) "SHELL=/bin/sh");
+       putenv((char *) "SHELL=/system/bin/sh");
        putenv((char *) "USER=root"); /* needed? why? */

        if (argv[1])
diff --git a/util-linux/setarch.c b/util-linux/setarch.c
index cf8ef0064..efb7da29c 100644
--- a/util-linux/setarch.c
+++ b/util-linux/setarch.c
@@ -95,7 +95,7 @@ int setarch_main(int argc UNUSED_PARAM, char **argv)

        argv += optind;
        if (!argv[0])
-               (--argv)[0] = (char*)"/bin/sh";
+               (--argv)[0] = (char*)"/system/bin/sh";

        /* Try to execute the program */
        BB_EXECVP_or_die(argv);
```

# 编译脚本使用
bash 01_udhcpd/build.sh -a arm 
bash 01_udhcpd/build.sh -a arm64


# Native bionic (Android) port of Busybox

## Prepare a standalone Android Toolchain

- download Android NDK from [https://developer.android.com/ndk/downloads/index.html](https://developer.android.com/ndk/downloads/index.html)
- unpack android-ndk-rXX-linux-x86\_64.zip into a suitable directory (tested with r17b)
- cd in thejust unpacked directory launch \
  `./build/tools/make_standalone_toolchain.py --arch arm --api 21 --install-dir ~/arm-linux-androideabi` \
  adding your preferred architecture to the command line like `--arch arm` and if you want and your minimum api
  level
- open `~/arm-linux-androideabi/sysroot/usr/include/android/api-level.h` \
  and change:

  `#define __ANDROID_API__ __ANDROID_API_FUTURE__` \
  with \
  `#define __ANDROID_API__ 21`

  (the same number used on commandline or the default if not specified)

## Configuring busybox

- execute (or add to your bashrc): `export PATH=$PATH:$HOME/arm-linux-androideabi/bin`,
  adjust the path if needed
- verify that the compiler is in the path with `arm-linux-androideabi-gcc -v`
- in busybox source tree launch `make sherpya_android_defconfig`
- if you want to configure further, launch `make menuconfig`,
  if needed change `Cross Compiler prefix` in `Busybox Settings`
- launch make (add -jX if you want to use multiple jobs


/opt/arm-linux-androideabi/sysroot/usr/include/android/api-level.h

## Bugs & Limitations

- The current Android NDK has a fake resolver stub, so if you build a static busybox, the resulting
  executable will not be able to resolve hosts, e.g. `ping www.google.it` will fail,
  so just leave it dynamic
- Android versions before 4.1 (API 16) do not support PIE, you need to disable it
- Android versions after 5.0 (API 21) require PIE, you need to enabled it (default in my config)
- Running executables built with ancient API on newer Android versions may crash 
