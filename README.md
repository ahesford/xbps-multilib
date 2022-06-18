# Generic XBPS Multilib Manager

The [Void Linux](https://www.voidlinux.org/) package-building infrastructure
includes special-case support for creating 32-bit "multilib" packages when
compiling native 32-bit `i686` packages. This works only for `x86_64` and
`i686` glibc systems and relies on some hacks to extract relevant portions of
32-bit packages for their multilib derivatives. Eventually, it would be nice to
eliminate this special case.

This script wraps XBPS commands to manage installation of Void packages for any
architecture in alternate roots. Although these roots can be fully populated
for use as chroot environments (*e.g.*, if you intend to run 64-bit glibc
packages on a musl system), it is also possible to use a 32-bit alternate root
in a multilib-style configuration when the architectures are compatible. It may
even be possible to configure binfmt and qemu to run programs for incompatible
architectures from an alternate root, although I have not attempted to do so.

The script is a generic wrapper for any XBPS command that derives the target
architecture and command to run from its own name, structured as

    <XBPS_ARCH>-<XBPS_COMMAND>

where `<XBPS_ARCH>` is a value for the `$XBPS_ARCH` environment variable that
XBPS will find meaningful. "Installation" of this script, therefore, involves
symlinking all desired commands for all desired architectures to the wrapper.

The script expects each alternate root to reside in the directory

    ${XBPS_MULTILIB_ROOT}/${XBPS_ARCH}

Set the variable `$XBPS_MULTILIB_ROOT` to any desired directory. If the
variable is unset, a default of `/multilib` is assumed if that directory
exists; otherwise, `/usr` will be used as the root, yielding multilib trees
such as, *e.g.*, `/usr/i686`.

> The multilib arrangement supported by this script relies on symlinking
> `/usr/lib32` to the `usr/lib` directory in your desired multilib root. This
> is *not* compatible with standard XBPS multilib. Make sure no `-32bit`
> packages are installed when configuring a new-style multilib setup.

# Setup

All examples below assume the host is an `x86_64` installation and the multilib
target is `i686`. For other configurations, such as an `aarch64` to `armv7l`
target, it is generally sufficient to replace `i686` with `armv7l` or another
desired target. These instructions are known to work for both `x86_64 -> i686`
and `aarch64 -> armv7l`.

1. Copy the script to a desired location that will not be in your path. For
   system installations, `/usr/local/libexec` is a good choice. For per-user
   installation, `~/.local/libexec` works as well.

2. In a directory in your `$PATH`, symlink architecture-prefixed versions of
   all desired XBPS commands to the wrapper script. For example, links

       /usr/local/bin/i686-xbps-install -> /usr/local/libexec/xbps-multilib.sh
       /usr/local/bin/i686-xbps-remove -> /usr/local/libexec/xbps-multilib.sh
       /usr/local/bin/i686-xbps-pkgdb -> /usr/local/libexec/xbps-multilib.sh
       /usr/local/bin/i686-xbps-query -> /usr/local/libexec/xbps-multilib.sh
       /usr/local/bin/i686-xbps-reconfigure -> /usr/local/libexec/xbps-multilib.sh

   will provide a functional setup for managing an `i686` multilib root.

3. Set `$XBPS_MULTILIB_ROOT` to the desired root for all multilib
   installations, or rely on the default root selection behavior. (Subsequent
   steps assume the variable is set and use it as a stand-in for your preferred
   path.)

4. Create the target root, including an XBPS configuration directory

       mkdir -p "${XBPS_MULTILIB_ROOT}/<ARCH>/etc/xbps.d

   where `<ARCH>` is your desired XBPS architecture.

5. Add XBPS configuration files to the directory. Specifically, ensure that

       ${XBPS_MULTILIB_ROOT}/<ARCH>/etc/xbps.d/00-repository-main.conf

   exists and specifies the repositories from which you would like to pull.

6. If you have specified an alternative `$XBPS_MULTILIB_ROOT`, make sure that
   the variable has been exported to your environment.

7. Populate the initial root with `base-files`; for example,

       i686-xbps-install base-files

8. Install what you like! For that sweet, sweet classic in 32-bit glory,

       i686-xbps-install xterm

9. Tell your host XBPS installation never to extract files to `/usr/lib32`;
   this will now be owned by the multilib root.

       echo "noextract=/usr/lib32/*" > /etc/xbps.d/30-multilib.conf

10. Remove any existing `/usr/lib32` directory. On a stock Void installation,
    this should only contain a `locale` symlink installed by `base_files`.

        rm /usr/lib32/locale
        rmdir /usr/lib32

    If there is more content in `/usr/lib32` that prevents its removal, tread
    carefully and make sure you know what you are deleting.

11. Link `/usr/lib32` to the `usr/lib` subdirectory of your desired target.

        ln -s ${XBPS_MULTILIB_ROOT}/<ARCH>/usr/lib /usr/lib32

    where, again, `<ARCH>` is the architecture you intend to target.

12. Link the target C library in `/usr/lib`. The name of the library depends on
    the architecture. For `i686`,

        ln -s ${XBPS_MULTILIB_ROOT}/i686/usr/lib/ld-linux.so.2 /usr/lib

    For `armv7l`,

        ln -s ${XBPS_MULTILIB_ROOT}/armv7l/usr/lib/ld-linux-armhf.so.3 /usr/lib

    For other architectures, you will need to do some discovery. (Whether a
    multilib setup with `musl` is feasible is unknown.)

    > NEVER REPLACE AN EXISTING FILE in `/usr/lib` with these symlinks. The
    > symlinks should not conflict with your host system installation. If
    > creating the links fails because a file already exists at the
    > destination, tread carefully!

13. Add the target to your path, *e.g.*,

        export PATH="${PATH}:${XBPS_MULTILIB_ROOT}/i686/usr/bin"

14. Run your 32-bit executables!

15. Remember to maintain the root by periodically upgrading; it will not be
    maintained automatically by the host.
