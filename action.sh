MODPATH="${0%/*}"

# ensure not running in busybox ash standalone shell
set +o standalone
unset ASH_STANDALONE

sh $MODPATH/helper.sh -m || exit 1

echo -e "\nDone!"

# warn since KernelSU/APatch's implementation automatically closes if successful
if [ "$KSU" = "true" -o "$APATCH" = "true" ] && [ "$KSU_NEXT" != "true" ] && [ "$WKSU" != "true" ] && [ "$MMRL" != "true" ]; then
    echo -e "\nClosing dialog in 5 seconds ..."
    sleep 5
fi
