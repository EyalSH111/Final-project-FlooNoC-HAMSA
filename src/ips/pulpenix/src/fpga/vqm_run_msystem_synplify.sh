# archive
rm -rf rev_1.prev
if $? != 0 then
    mv rev_1.prev DELETE_ME
endif
mv rev_1 rev_1.prev

# this is a hack for targeting quartus18.1 when not installed
setenv QUARTUS_ROOTDIR /home/noytzach/bin/quartus/18.1

# run synplify
qrun /opt/synopsys/fpga/P-2019.09-SP1/bin/synplify_premier -batch vqm_msystem_synplify.tcl
if $? != 0 then
    echo ' >>> Synplify failed.'
    exit 1
endif

# pack outputs needed for quartus
tar -czf fpgnix_hir.tgz rev_1/vqm_msystem_wrap.vqm rev_1/*.mif 
if $? == 0 then
    echo ' >>> Created tarball: fpgnix_hir.tgz'
    exit 0
endif

echo ' >>> Something failed.'
exit 1
