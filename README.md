# Pi-router

Pi-router is a tool used to generate a custom Raspberry Pi OS image that transforms an `RPi`(tested on `RPi` 4) board into a secure router(strictly
speaking an access point). Pi-router is derived from [pi-gen](https://github.com/RPi-Distro/pi-gen) and is based on
[2020-12-02](https://github.com/RPi-Distro/pi-gen/releases/tag/2020-12-02-raspbian-buster) release.

`Pi-router` is secured with [nftables](https://wiki.nftables.org) and [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy).

## TL;DR

- Grab the binary package from [here](https://github.com/mahsank/pi-router/releases/download/v1.0/image_2021-03-08-pirouter.zip) and unzip it.

```bash
$ unzip image_2021-03-08-pirouter.zip
```
- Dump the image on an sd card.

```bash
$ sudo dd if=2021-03-08-pirouter.img of=/dev/mmcblk0 bs=4M status=progress conv=fdatasync
```
- Insert the card into sd card slot of RPi board, boot and you should be good to go. Login password is `Ra5pb3rry`.

- Change the two letter country code from `fi` to your country in `/etc/hostapd/hostapd.conf`.

- Optional: It might be helpful to read the section [Network Configuration Details](#network-configuration-details).

## Dependencies

Pi-router build is tested with Debian *buster* and Fedora *33*.

To install the required dependencies for pi-router on Debian *buster*, run:

```bash
$ apt-get install coreutils quilt parted qemu-user-static debootstrap zerofree \
zip dosfstools bsdtar libcap2-bin grep rsync xz-utils file git curl bc
```

To achieve the same on Fedora *33*, run:

```bash
$ dnf install coreutils quilt parted qemu-user-static debootstrap zerofree \
zip dosfstools bsdtar libcap grep rsync xz file git curl bc
```

Other distributions should work but not tested. Feel free to give `pi-router` a spin on your favorite distro and let me
know the results.

## Router-Config

Upon execution, `build.sh` will source the file `router-config` in the current working directory. This bash shell fragment is
intended to set needed environment variables.

The following environment variables are supported:

- `IMG_DATE`

  Date on which the image is built.

- `IMG_FILENAME`

  Combination of `IMG_DATE` and `IMG_NAME`(defined in `router-config`).

- `ZIP_FILENAME (Default: unset)`

  `IMG_FILENAME` prefixed with `image_`.

- `RELEASE` (Default: `buster`)

  The release version to build image against. Valid values are `jessie`, `stretch`, `buster`, `bullseye`, and `testing`.
  Note that `pi-router` is tested with `buster` only.

- `APT_PROXY` (Default: unset)

  If you need to use apt proxy, set it here. The proxy setting will not be included in the image, making it safe to use an `apt-cacher` or similar package for development.

  If Docker is installed, it is possible to set up a local apt caching proxy to speed up subsequent builds like this:

  ```bash
  $ docker-compose up -d
  $ echo 'APT_PROXY=http://172.17.0.1:3142' >> router-config
  ```

- `BASE_DIR` (Default location of `build.sh`)

  This is the top-level directory for `pi-router`. It contains `stage` directories, build scripts, and by default both `work` and
`deploy` directories. Changing this variable is not recommended.

- `SCRIPT_DIR`

  Directory containing helper scripts.

- `WORK_DIR` (Default: `"$BASE_DIR/work"`)

  Directory in which `pi-router` builds the target system. This value can be changed if a sufficiently large, fast, storage
location is available for running build stages and caching purposes. It is important to note that `WORK_DIR` stores a
complete copy of the target system for each build stage and it can grow extremely rapidly. This will result in hogging
the storage space quickly. If you are building frequently, periodic cleaning of this directory is recommended.

- `DEPLOY_DIR` (Default: `"$BASE_DIR/deploy"`)

  Output directory for target system image.

- `DEPLOY_ZIP` (Default: 0)

  By default, the image is deployed only as a regular `iso` image.

- `LOG_FILE` (Default: `"$WORK_DIR/build.log"`)

- `ENABLE_DEBUG` (Default: unset)

  Sets the UART connectivity for debugging purposes

- `TARGET_HOSTNAME` (Default: `rpirouter`)

- `FIRST_USER_NAME` (Default: `pi`)

  User name for the first user

- `FIRST_USER_PASS` (Default: `Ra5pb3rry`)

  Password for the first user.

- `WPA_ESSID` (Default: `pisecrouter`)

- `WPA_PASSWORD` (Default: `3T01F24h15h~`)

- `WPA_COUNTRY` (Default: `fi`)

  This value should be changed with the corresponding two letters country code.

- `ENABLE_SSH` (Default: 1)

  `SSH` is enabled by default.

- `LOCALE_DEFAULT` (Default: English("US"))

- `KEYBOARD_MAP` (Default: `us`)

- `KEYBOARD_LAYOUT` (Default: "English (US)")

- `TIMEZONE_DEFAULT` (Default: "Europe/Helsinki")

- `STAGE_LIST` (Default: `stage*`)

  If set, then instead of working through the numeric stages in order, this list will be followed. For example, setting to
"stage0 stage1 mystage stage2" will run the contents of "mystage" before "stage2". Note the quotes, they are needed
around the list. An absolute or relative path can be given for stages outside the `pi-router` directory.

A minimal `router-config` file is included in the build and is the default for `build.sh`.If needed, this file can be customized further.

## Build Process

The image is built with the following process:

- Loop through all of the stage directories in alphanumeric order

- Run the script prerun.sh which is generally just used to copy the build directory between stages.  In each stage
  directory loop through each subdirectory and then run each of the install scripts it contains, again in alphanumeric
  order. These need to be named with a two digit padded number at the beginning. There are a number of different files
  and directories which can be used to control different parts of the build process:

  - **00-run.sh**- An executable unix shell script.
  - **00-run-chroot.sh**- An executable unix shell script that will run in the `chroot` of the image build directory.
  - **00-debconf**- Contents of this file are passed to `debconf-set-selections` to configure things like locale, etc.
  - **00-packages**- A list of packages to be installed.
  - **00-packages-nr**- As `00-packages`, except these will be installed using the `--no-install-recommends -y`
    parameter to `apt-get`.
  - **00-patches**- A directory containing patch files to be applied, using `quilt`. If a file named `EDIT` is present
    in the directory, the build process will be interrupted with a bash session, allowing an opportunity to
    create/revise the patches.

- If the `stage` directory contains a file called `EXPORT_IMAGE` then add this stage to a list of images to generate.
  This is relevant for stage2 only as no image is exported for stage0 or stage1.

- Generate the image for the stages with the above file; in this case, for stage2 only.

- If the build process is interrupted, it is possible to start from the point of interruption by setting `CONTINUE`=1,
  e.g.

  ```bash
  $ CONTINUE=1 ./build.sh
  ```

Please refer to `build.sh` for finer details.

## Docker Build

Docker can be used to perform the build inside a container. This partially isolates the build from the host system, and allows using the script on distributions other than `Debian` or `Fedora`. It might be worth noting that Docker build can be used on `Debian` or `Fedora` as well. Running Docker build is as simple as issuing the command below:

  ```bash
  $ ./build-docker.sh
  ```

If everything goes well, the final image will be in `deploy/` directory. The build container can be removed after the build with the command:

```bash
$ docker rm -v pirouter_work
```
Similar to `build.sh`, `build-docker.sh` can be continued from where it left during an interruption:

```bash
$ CONTINUE=1 ./build-docker.sh
```

In case of a failure, the container can be examined by issuing the following command:

```bash
$ sudo docker run -it --privileged --volumes-from=pirouter_work pi-router /bin/bash
```

In case of successful build, the build container is by default removed. This can be changed by issuing the command:

```bash
PRESERVE_CONTAINER=1 ./build-docker.sh
```

## Stage Anatomy

The build process is divided up into several stages for logical clarity and modularity. This causes some initial complexity, but it simplifies maintenance and allows for more easy customization.

**Stage 0** - bootstrap. The primary purpose of this stage is to create a usable filesystem. This is accomplished largely through the use of debootstrap, which creates a minimal filesystem suitable for use as a base.tgz on Debian systems. This stage also configures apt settings and installs raspberrypi-bootloader which is missed by debootstrap. The minimal core is installed but not configured, and the system will not quite boot yet.

**Stage 1** - truly minimal system. This stage makes the system bootable by installing system files like `/etc/fstab`, configures the bootloader, makes the network operable, and installs packages like raspi-config. At this stage the system should boot to a local console from which you have the means to perform basic tasks needed to configure and install the system. This is as minimal as a system can possibly get, and its arguably not really usable in a traditional sense yet. Still, if you want minimal, this is minimal and the rest you could reasonably do yourself as sysadmin.

**Stage 2** - router system. This stage produces the router image. It installs some optimized memory functions, sets timezone and charmap defaults, installs fake-hwclock and ntp, wireless LAN and bluetooth support, dphys-swapfile, and other basics for managing the hardware. It also creates necessary groups and gives the pi user access to sudo and the standard console hardware permission groups.

All the customizations needed to transform `RPi`  into a secure router are done at this stage. Contrary to `pi-gen` build stages, `pi-router` does not need to go beyond this stage.

## Network Configuration Details

`Pi-router` makes use of `dnsmasq`, `dhcpcd`, and `hostapd`, to transform the `RPi` into a router. The default LAN side gateway ip address is `172.31.31.1/24` and the connected clients are assigned addresses in the range of `172.31.31.2-254`. WAN side address is supplied by the RJ-45 connector on `RPi` board.

## Known Limitations

- `Pi-router` does not handle the case of WAN side address supplied by a *USB to RJ-45* dongle plugged into one of the four `RPi` USB ports.

- IPv6 support is not fully baked.

## Troubleshooting

### binfmt_misc

Linux is able execute binaries from other architectures, meaning that it should be possible to make use of `pi-router` on an `x86_64` system, even though it will be running *ARM* binaries. This requires support from the `binfmt_misc` kernel module.

You may see the following error:

```bash
update-binfmts: warning: Could not load the binfmt_misc module.
```

To resolve this, make sure that `binfmt_misc` module is loaded and `qemu-arm-static` binary is available.

```bash
$ lsmod | grep binfmt_misc
$ command -v qemu-arm-static
```

If you find this work useful, [consider buying me a coffee](https://ko-fi.com/buchal).
