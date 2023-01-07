#!/bin/bash
# Put this file in /etc/libvirt/hooks/qemu.d/{VMName}/prepare/begin/start.sh
# Helpful to read output when debugging
set -x

# load variables we defined
source "/etc/libvirt/hooks/kvm.conf"

# Stop display manager
#systemctl stop display-manager.service
systemctl stop sddm.service
## Uncomment the following line if you use GDM
#killall gdm-x-session

# Unbind VTconsoles
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI-Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Avoid a Race condition by waiting 2 seconds. This can be calibrated to be shorter or longer if required for your system
sleep 10

#Unload Nvidia
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
# modprobe -r drm_kms_helper
modprobe -r nvidia
modprobe -r i2c_nvidia_gpu
# modprobe -r drm
modprobe -r nvidia_uvm

# Unbind the GPU from display driver
virsh nodedev-detach $VIRSH_GPU_VIDEO
virsh nodedev-detach $VIRSH_GPU_AUDIO

# Load VFIO Kernel Module  
modprobe vfio_pci  
modprobe vfio
modprobe vfio_iommu_type1
modprobe vfio_virqfd

# CPU isolation
systemctl set-property --runtime -- user.slice AllowedCPUs=0,1,6,7
systemctl set-property --runtime -- system.slice AllowedCPUs=0,1,6,7
systemctl set-property --runtime -- init.scope AllowedCPUs=0,1,6,7
