#make BR2_JLEVEL=16 2>&1 | tee remote-os_build_$(date +"%Y%m%d_%H%M%S").log
make 2>&1 | tee remote-os_build_$(date +"%Y%m%d_%H%M%S").log
