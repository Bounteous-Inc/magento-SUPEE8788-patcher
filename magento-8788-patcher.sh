#!/usr/bin/env bash

function show_usage {
cat <<- _EOF_
Magento Patch 8788 applier

Usage: ./magento-8788-patch.sh [-v \$magento_version -e EE|CE]
Options:
  -v version      : OPTIONAL Manually set Magento Version
  -e edition      : OPTIONAL Manually set Magento Edition EE or CE

_EOF_
exit 1
}

function validate_version {

VersionsEE=("1.14.2.4" "1.14.2.3" "1.14.2.2" "1.14.2.1" "1.14.2.0" "1.14.1.0" "1.14.0.1" "1.14.0.0" "1.13.1.0" "1.13.0.2" "1.13.0.1" "1.13.0.0" "1.12.0.0" "1.12.0.1" "1.12.0.2" "1.11.2.0" "1.11.1.0" "1.11.0.2" "1.11.0.1" "1.11.0.0" "1.10.1.1" "1.10.1.0" "1.10.0.2" "1.10.0.1" "1.10.0.0" "1.9.1.1" "1.9.1.0" "1.9.0.0")

VersionsCE=("1.4.0.0" "1.4.0.1" "1.4.1.0" "1.4.1.1" "1.4.2.0" "1.5.0.1" "1.5.1.0" "1.6.0.0" "1.6.1.0" "1.6.2.0" "1.7.0.0" "1.7.0.1" "1.7.0.2" "1.8.0.0" "1.8.1.0" "1.9.0.0" "1.9.0.1" "1.9.1.0" "1.9.1.1" "1.9.2.0" "1.9.2.1" "1.9.2.2" "1.9.2.3" "1.9.2.4")

if [ "$MageEdition" = "EE" ] ; then
    if [[ " ${VersionsEE[@]} " =~ " ${MageVersion} " ]]; then
        echo 'Valid Version'
    else
        echo 'Only the following Magento EE Versions are Supported: 1.14.2.4, 1.14.2.3, 1.14.2.2, 1.14.2.1, 1.14.2.0, 1.14.1.0, 1.14.0.1, 1.14.0.0, 1.13.1.0, 1.13.0.2, 1.13.0.1, 1.13.0.0, 1.12.0.0, 1.12.0.1, 1.12.0.2, 1.11.2.0, 1.11.1.0, 1.11.0.2, 1.11.0.1, 1.11.0.0, 1.10.1.1, 1.10.1.0, 1.10.0.2, 1.10.0.1, 1.10.0.0, 1.9.1.1, 1.9.1.0, 1.9.0.0'
    fi
else
    if [[ " ${VersionsCE[@]} " =~ " ${MageVersion} " ]]; then
        echo 'Valid Version'
    else
        echo 'Only the following Magento CE Versions are Supported: 1.4.0.0, 1.4.0.1, 1.4.1.0, 1.4.1.1, 1.4.2.0, 1.5.0.1, 1.5.1.0, 1.6.0.0, 1.6.1.0, 1.6.2.0, 1.7.0.0, 1.7.0.1, 1.7.0.2, 1.8.0.0, 1.8.1.0, 1.9.0.0, 1.9.0.1, 1.9.1.0, 1.9.1.1, 1.9.2.0, 1.9.2.1, 1.9.2.2, 1.9.2.3, 1.9.2.4'
    fi
fi
}

function revert_1533 {
    PATCH=""
    if [ "$MageEdition" = "EE" ] ; then
        VersionsA=("1.14.2.4" "1.14.2.3" "1.14.2.2" "1.14.2.1" "1.14.2.0" "1.14.1.0" "1.14.0.1" "1.14.0.0" "1.13.1.0" "1.13.0.2" "1.13.0.1" "1.13.0.0")
        VersionsB=("1.12.0.0" "1.12.0.1" "1.12.0.2")
        VersionsC=("1.11.2.0" "1.11.1.0" "1.11.0.2" "1.11.0.1" "1.11.0.0")
        VersionsD=("1.10.1.1" "1.10.1.0")
        VersionsE=("1.10.0.2" "1.10.0.1" "1.10.0.0")
        VersionsF=("1.9.1.1" "1.9.1.0" "1.9.0.0")

        if [[ " ${VersionsA[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.13.x_v1-2014-10-03-04-00-17.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.13.x_v1-2014-10-03-04-00-17.sh'
        elif [[ " ${VersionsB[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.12.x_v1-2014-10-03-04-00-32.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.12.x_v1-2014-10-03-04-00-32.sh'
        elif [[ " ${VersionsC[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.11.x_v1-2014-10-03-04-00-47.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.11.x_v1-2014-10-03-04-00-47.sh'
        elif [[ " ${VersionsD[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.10.1.x_v1-2014-10-03-04-00-58.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.10.1.x_v1-2014-10-03-04-00-58.sh'
        elif [[ " ${VersionsE[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.10.0.x_v1-2014-10-03-04-01-11.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.10.0.x_v1-2014-10-03-04-01-11.sh'
        elif [[ " ${VersionsF[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.9.x_v1-2014-10-03-04-01-23.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.9.x_v1-2014-10-03-04-01-23.sh'
        fi
    else
        VersionsA=("1.8.0.0" "1.8.1.0" "1.9.0.0" "1.9.0.1" "1.9.1.0" "1.9.1.1" "1.9.2.0" "1.9.2.1" "1.9.2.2" "1.9.2.3" "1.9.2.4")
        VersionsB=("1.7.0.0" "1.7.0.1" "1.7.0.2")
        VersionsC=("1.6.0.0" "1.6.1.0" "1.6.2.0")
        VersionsD=("1.5.1.0")
        VersionsE=("1.5.0.1")
        VersionsF=("1.4.0.0" "1.4.0.1" "1.4.1.0" "1.4.1.1" "1.4.2.0")

        if [[ " ${VersionsA[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.13.x_v1-2014-10-03-04-00-17.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.13.x_v1-2014-10-03-04-00-17.sh'
        elif [[ " ${VersionsB[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.12.x_v1-2014-10-03-04-00-32.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.12.x_v1-2014-10-03-04-00-32.sh'
        elif [[ " ${VersionsC[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.11.x_v1-2014-10-03-04-00-47.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.11.x_v1-2014-10-03-04-00-47.sh'
        elif [[ " ${VersionsD[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.10.1.x_v1-2014-10-03-04-00-58.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.10.1.x_v1-2014-10-03-04-00-58.sh'
        elif [[ " ${VersionsE[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.10.0.x_v1-2014-10-03-04-01-11.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.10.0.x_v1-2014-10-03-04-01-11.sh'
        elif [[ " ${VersionsF[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-1533_EE_1.9.x_v1-2014-10-03-04-01-23.sh"
            echo 'Reverting 1533 Using PATCH_SUPEE-1533_EE_1.9.x_v1-2014-10-03-04-01-23.sh'
        fi
    fi

    cp "${PatchDir}1533/${PATCH}" ${PATCH}

    APPLIED=$(bash ${PATCH} --list | grep 'SUPEE-1533');

    if [ "$APPLIED" = "" ] ; then
        echo '1533 Does not appear to be applied'

    else
        echo "Patch 1533 Found"
    fi

    bash ${PATCH} --revert

    rm ${PATCH}
}

function apply_3941 {
    PATCH=""
    if [ "$MageEdition" = "EE" ] ; then
        VersionsA=("1.14.0.1" "1.14.0.0" "1.13.1.0" "1.13.0.2" "1.13.0.1" "1.13.0.0" "1.12.0.0" "1.12.0.1" "1.12.0.2")
        VersionsB=("1.11.2.0")
        VersionsC=("1.11.1.0" "1.11.0.2" "1.11.0.1" "1.11.0.0")
        VersionsD=("1.10.1.1" "1.10.1.0" "1.10.0.2" "1.10.0.1" "1.10.0.0" "1.9.1.1" "1.9.1.0" "1.9.0.0")

        if [[ " ${VersionsA[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-3941_EE_1.14.0.1_v1-2016-10-14-09-02-41.sh"
            echo 'Applying 3941 Using PATCH_SUPEE-3941_EE_1.14.0.1_v1-2016-10-14-09-02-41.sh'
        elif [[ " ${VersionsB[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-3941_EE_1.11.2.0_v1-2016-10-14-09-00-34.sh"
            echo 'Applying 3941 Using PATCH_SUPEE-3941_EE_1.11.2.0_v1-2016-10-14-09-00-34.sh'
        elif [[ " ${VersionsC[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-3941_EE_1.11.1.0-1.11.0.0_CE_1.6.1.0-1.6.0.0_v1-2016-10-14-08-56-18.sh"
            echo 'Applying 3941 Using PATCH_SUPEE-3941_EE_1.11.1.0-1.11.0.0_CE_1.6.1.0-1.6.0.0_v1-2016-10-14-08-56-18.sh'
        elif [[ " ${VersionsD[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-3941_EE_1.10.1.0_v1-2016-10-14-08-49-52.sh"
            echo 'Applying 3941 Using PATCH_SUPEE-3941_EE_1.10.1.0_v1-2016-10-14-08-49-52.sh'
        else
            echo 'Patch 3941 Not Needed for this version.'
            return
        fi
    else
        VersionsA=("1.8.0.0" "1.8.1.0" "1.9.0.0" "1.9.0.1")

        if [[ " ${VersionsA[@]} " =~ " ${MageVersion} " ]]; then
            PATCH="PATCH_SUPEE-3941_EE_1.14.0.1_v1-2015-02-10-08-32-02.sh"
            echo 'Applying 3941 Using PATCH_SUPEE-3941_EE_1.14.0.1_v1-2015-02-10-08-32-02.sh'
        else
            echo 'Patch 3941 Not Needed for this version.'
            return
        fi
    fi

    cp "${PatchDir}3941/${PATCH}" ${PATCH}

    APPLIED=$(bash ${PATCH} --list | grep 'SUPEE-3941');

    if [ "$APPLIED" = "" ] ; then
        echo '3941 Does not appear to be applied'
        bash ${PATCH}
    else
        echo "Patch 3943 Found"
    fi

    rm ${PATCH}
}

function apply_8788 {
    PATCH=""

    if [ "$MageEdition" = "EE" ] ; then
        case $MageVersion in
            "1.14.2.4")
                PATCH="PATCH_SUPEE-8788_EE_1.14.2.4_v2-2016-10-14-09-37-37.sh"
                ;;
            "1.14.2.3")
                PATCH="PATCH_SUPEE-8788_EE_1.14.2.3_v2-2016-10-14-09-38-01.sh"
                ;;
            "1.14.2.2")
                PATCH="PATCH_SUPEE-8788_EE_1.14.2.2_v2-2016-10-14-09-38-23.sh"
                ;;
            "1.14.2.1")
                PATCH="PATCH_SUPEE-8788_EE_1.14.2.1_v2-2016-10-14-09-40-55.sh"
                ;;
            "1.14.2.0")
                PATCH="PATCH_SUPEE-8788_EE_1.14.2.0_v2-2016-10-14-09-39-05.sh"
                ;;
            "1.14.1.0")
                PATCH="PATCH_SUPEE-8788_EE_1.14.1.0_v2-2016-10-14-09-40-20.sh"
                ;;
            "1.14.0.1")
                PATCH="PATCH_SUPEE-8788_EE_1.14.0.1_v2-2016-10-14-11-53-41.sh"
                ;;
            "1.14.0.0")
                PATCH="PATCH_SUPEE-8788_EE_1.14.0.0_v2-2016-10-14-09-41-18.sh"
                ;;
            "1.13.1.0")
                PATCH="PATCH_SUPEE-8788_EE_1.13.1.0_v2-2016-10-14-11-52-21.sh"
                ;;
            "1.13.0.2")
                PATCH="PATCH_SUPEE-8788_EE_1.13.0.2_v3-2016-10-17-05-05-45.sh"
                ;;
            "1.13.0.1")
                PATCH="PATCH_SUPEE-8788_EE_1.13.0.1_v3-2016-10-17-05-04-02.sh"
                ;;
            "1.13.0.0")
                PATCH="PATCH_SUPEE-8788_EE_1.13.0.0_v3-2016-10-17-05-03-32.sh"
                ;;
            "1.12.0.2")
                PATCH="PATCH_SUPEE-8788_EE_1.12.0.2_v2-2016-10-14-11-47-59.sh"
                ;;
            "1.12.0.1")
                PATCH="PATCH_SUPEE-8788_EE_1.12.0.1_v2-2016-10-14-11-47-13.sh"
                ;;
            "1.12.0.0")
                PATCH="PATCH_SUPEE-8788_EE_1.12.0.0_v2-2016-10-14-11-45-57.sh"
                ;;
            "1.11.2.0")
                PATCH="PATCH_SUPEE-8788_EE_1.11.2.0_v2-2016-10-14-11-45-13.sh"
                ;;
            "1.11.1.0")
                PATCH="PATCH_SUPEE-8788_EE_1.11.1.0_v2-2016-10-14-11-44-23.sh"
                ;;
            "1.11.0.2")
                PATCH="PATCH_SUPEE-8788_EE_1.11.0.2_v2-2016-10-14-11-43-25.sh"
                ;;
            "1.11.0.1")
                PATCH="PATCH_SUPEE-8788_EE_1.11.0.1_v1-2016-10-10-09-54-41.sh"
                ;;
            "1.11.0.0")
                PATCH="PATCH_SUPEE-8788_EE_1.11.0.0_v2-2016-10-14-11-41-33.sh"
                ;;
            "1.10.1.1")
                PATCH="PATCH_SUPEE-8788_EE_1.10.1.1_v2-2016-10-14-11-40-36.sh"
                ;;
            "1.10.1.0")
                PATCH="PATCH_SUPEE-8788_EE_1.10.1.0_v2-2016-10-14-11-36-02.sh"
                ;;
            "1.10.0.2")
                PATCH="PATCH_SUPEE-8788_EE_1.10.0.2_v2-2016-10-14-11-34-50.sh"
                ;;
            "1.10.0.1")
                PATCH="PATCH_SUPEE-8788_EE_1.10.0.1_v2-2016-10-14-11-33-56.sh"
                ;;
            "1.10.0.0")
                PATCH="PATCH_SUPEE-8788_EE_1.10.0.0_v2-2016-10-14-10-04-40.sh"
                ;;
            "1.9.1.1")
                PATCH="PATCH_SUPEE-8788_EE_1.9.1.1_v2-2016-10-14-09-59-37.sh"
                ;;
            "1.9.1.0")
                PATCH="PATCH_SUPEE-8788_EE_1.9.1.0_v2-2016-10-14-09-58-17.sh"
                ;;
            "1.9.0.0")
                PATCH="PATCH_SUPEE-8788_EE_1.9.0.0_v2-2016-10-14-09-57-23.sh"
                ;;
            *)
                show_usage
                ;;
        esac
    else
        case $MageVersion in
            "1.5.0.1")
                PATCH="PATCH_SUPEE-8788_CE_1.5.0.1_v2-2016-10-14-09-30-34.sh"
                ;;
            "1.5.1.0")
                PATCH="PATCH_SUPEE-8788_CE_1.5.1.0_v2-2016-10-14-09-30-10.sh"
                ;;
            "1.6.0.0")
                PATCH="PATCH_SUPEE-8788_CE_1.6.0.0_v2-2016-10-14-09-29-30.sh"
                ;;
            "1.6.1.0")
                PATCH="PATCH_SUPEE-8788_CE_1.6.1.0_v2-2016-10-14-09-29-05.sh"
                ;;
            "1.6.2.0")
                PATCH="PATCH_SUPEE-8788_CE_1.6.2.0_v2-2016-10-14-09-28-41.sh"
                ;;
            "1.7.0.0")
                PATCH="PATCH_SUPEE-8788_CE_1.7.0.0_v2-2016-10-14-09-28-11.sh"
                ;;
            "1.7.0.1")
                PATCH="PATCH_SUPEE-8788_CE_1.7.0.1_v2-2016-10-14-09-31-31.sh"
                ;;
            "1.7.0.2")
                PATCH="PATCH_SUPEE-8788_CE_1.7.0.2_v2-2016-10-14-09-32-17.sh"
                ;;
            "1.8.0.0")
                PATCH="PATCH_SUPEE-8788_CE_1.8.0.0_v2-2016-10-14-09-33-04.sh"
                ;;
            "1.8.1.0")
                PATCH="PATCH_SUPEE-8788_CE_1.8.1.0_v2-2016-10-14-09-35-11.sh"
                ;;
            "1.9.0.0")
                PATCH="PATCH_SUPEE-8788_CE_1.9.0.0_v2-2016-10-14-09-35-54.sh"
                ;;
            "1.9.0.1")
                PATCH="PATCH_SUPEE-8788_CE_1.9.0.1_v2-2016-10-14-09-37-14.sh"
                ;;
            "1.9.1.0")
                PATCH="PATCH_SUPEE-8788_CE_1.9.1.0_v2-2016-10-14-09-38-31.sh"
                ;;
            "1.9.1.1")
                PATCH="PATCH_SUPEE-8788_CE_1.9.1.1_v2-2016-10-14-09-39-13.sh"
                ;;
            "1.9.2.0")
                PATCH="PATCH_SUPEE-8788_CE_1.9.2.0_v2-2016-10-14-09-39-55.sh"
                ;;
            "1.9.2.1")
                PATCH="PATCH_SUPEE-8788_CE_1.9.2.1_v2-2016-10-14-09-40-36.sh"
                ;;
            "1.9.2.2")
                PATCH="PATCH_SUPEE-8788_CE_1.9.2.2_v2-2016-10-14-09-41-22.sh"
                ;;
            "1.9.2.3")
                PATCH="PATCH_SUPEE-8788_CE_1.9.2.3_v2-2016-10-14-09-42-08.sh"
                ;;
            "1.9.2.4")
                PATCH="PATCH_SUPEE-8788_CE_1.9.2.4_v2-2016-10-14-09-42-47.sh"
                ;;
            *)
                show_usage
                ;;
        esac
    fi

    cp "${PatchDir}8788/${PATCH}" ${PATCH}

    APPLIED=$(bash ${PATCH} --list | grep 'SUPEE-8788');

    if [ "$APPLIED" = "" ] ; then
        echo '8788 Does not appear to be applied'
        bash ${PATCH}
    else
        echo "Patch 8788 Found"
    fi

    rm ${PATCH}
}

# Set Defaults
MageVersion=""
PatchDir="var/patches/"

#Parse flags
while getopts "v:e:PT" OPTION; do
    case $OPTION in
        v)
            MageVersion=$OPTARG
            ;;
        e)
            MageEdition=$OPTARG
            ;;
        *)
            show_usage
            ;;
    esac
done

if [ "$MageVersion" = "" ] ; then
    MageVersion=$(php -r "require 'app/Mage.php'; echo Mage::getVersion(); ")
    echo "${MageVersion} Detected"
else
    echo "${MageVersion} Manually Set"
fi

if [ "$MageEdition" = "" ] ; then
    if [ -f "app/code/core/Enterprise/Enterprise/etc/config.xml" ]; then
        MageEdition="EE"
    else
        MageEdition="CE"
    fi
    echo "${MageEdition} Detected"
else
    echo "${MageEdition} Manually Set"
fi

#Validate Mage Version
validate_version

#Revert 1533
revert_1533

#Apply if not found 3941
apply_3941

#Apply 8788
apply_8788