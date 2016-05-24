# 备份/恢复/迁移Linux系统 Backup Whole Linux

以下命令需在fillinx上执行

These command need to be executed on fillinx

假设要备份/恢复/迁移的分区为/dev/vda1并在硬盘/dev/vda上

Suppose you are going to backup/recovery/migration /dev/vda1 on disk /dev/vda

## 通过ssh备份 Backup over ssh
 
1. Give root passwd
⋅⋅⋅
```bash
passwd
```

2. Start ssh
⋅⋅⋅
```bash
sudo service ssh start
```

3. Mount directory
```bash
mount /dev/vad1 /media/vda1
```

4. Backup
```bash
cd /media/vda1
sudo tar -cvpz ./ | ssh username@hostname -p port "( cat > ssh_backup.tar.gz )"
```

**如果你要通过网络存储备份的计算机在防火墙或NAT下，使用以下命令进行反向连接到服务器**

**If the computer which you want to save you backup to is running under firewall, run this to start a reverse connection**
```bash
ssh -CfNR 7777:losalhost:22 root@SERVER_NAME 
```

之后服务器可以在7777端口链接localhost进行备份

Then the server can connect to localhost port 7777 to connect to your computer

## 迁移系统 System Migration

假设想要从A服务器迁移到B服务器
Suppost you want to migrate from server A to server B

### B服务器 Server B

1. mount directory
```bash
mount /dev/vda1 /media/vda1
```

2. Start listen
```bash
nc -l 1024 | sudo tar -xvpzf - -C /media/vda1 --numeric-owner
```
### A服务器 Server A

1. mount directory

```bash
mount /dev/vda1 /media/vda1
```

2. send the whole system
```bash
cd /media/vda1
tar -cvpz ./ | nc -q 0 RECEIVING_HOST 1024
```

**有关安全性**

**Security Concern**

由于这种方式使用nc命令，所以数据在网络传输过程中未经加密，此种办法适用于私有网络环境

nc transfers files without encryption, so this is only useful for migration under private network

### 迁移之后 After Migration

**在迁移后，需要修改/etc/fstab 中的UUID信息以适应新环境**

**After migration, the UUID information in /etc/fatab need to be changed for the new server**

1. Get UUID information
```bash
ls -l /dev/disk/by-uuid/
```

2. Modify /etc/fstab
```bash
sudo vi /etc/fstab
```

**可能需要重新设置引导分区**

**Maybe you need to set boot flag for you new disk**
```bash
fdisk /dev/vda
```
使用'p'命令显示分区列表

Use 'p' command to list partions

使用'a'命令设置启动分区

Use 'a' command to set bootable partion

**可能需要恢复GRUB**

**Maybe you need to restore GRUB**

```bash
sudo -s
for f in dev dev/pts proc ; do mount --bind /$f /media/whatever/$f ; done
chroot /media/whatever
dpkg-reconfigure grub-pc
```

## 参考 Reference

Finnix

http://www.finnix.org/

BackupYourSystem/TAR

https://help.ubuntu.com/community/BackupYourSystem/TAR

7 Linux fdisk Command Examples to Manage Hard Disk Partition

http://www.thegeekstuff.com/2010/09/linux-fdisk/
