#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-8788 | CE_1.9.2.0 | v2 | 51f5e77c972c94d0886f0c7c145a55e3c460558a | Mon Sep 26 14:03:23 2016 +0300 | 6f0af734aa..51f5e77c97

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
index 7ebf6de..ba81b7d 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
@@ -34,6 +34,12 @@
  */
 class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends Mage_Adminhtml_Block_Widget
 {
+    /**
+     * Type of uploader block
+     *
+     * @var string
+     */
+    protected $_uploaderType = 'uploader/multiple';
 
     public function __construct()
     {
@@ -44,17 +50,17 @@ class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends M
     protected function _prepareLayout()
     {
         $this->setChild('uploader',
-            $this->getLayout()->createBlock('adminhtml/media_uploader')
+            $this->getLayout()->createBlock($this->_uploaderType)
         );
 
-        $this->getUploader()->getConfig()
-            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/catalog_product_gallery/upload'))
-            ->setFileField('image')
-            ->setFilters(array(
-                'images' => array(
-                    'label' => Mage::helper('adminhtml')->__('Images (.gif, .jpg, .png)'),
-                    'files' => array('*.gif', '*.jpg','*.jpeg', '*.png')
-                )
+        $this->getUploader()->getUploaderConfig()
+            ->setFileParameterName('image')
+            ->setTarget(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/catalog_product_gallery/upload'));
+
+        $browseConfig = $this->getUploader()->getButtonConfig();
+        $browseConfig
+            ->setAttributes(array(
+                'accept' => $browseConfig->getMimeTypesByExtensions('gif, png, jpeg, jpg')
             ));
 
         Mage::dispatchEvent('catalog_product_gallery_prepare_layout', array('block' => $this));
@@ -65,7 +71,7 @@ class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends M
     /**
      * Retrive uploader block
      *
-     * @return Mage_Adminhtml_Block_Media_Uploader
+     * @return Mage_Uploader_Block_Multiple
      */
     public function getUploader()
     {
diff --git app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
index 470dd1c..69da2b6 100644
--- app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
+++ app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
@@ -31,29 +31,24 @@
  * @package    Mage_Adminhtml
  * @author     Magento Core Team <core@magentocommerce.com>
 */
-class Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader extends Mage_Adminhtml_Block_Media_Uploader
+class Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader extends Mage_Uploader_Block_Multiple
 {
+    /**
+     * Uploader block constructor
+     */
     public function __construct()
     {
         parent::__construct();
-        $params = $this->getConfig()->getParams();
         $type = $this->_getMediaType();
         $allowed = Mage::getSingleton('cms/wysiwyg_images_storage')->getAllowedExtensions($type);
-        $labels = array();
-        $files = array();
-        foreach ($allowed as $ext) {
-            $labels[] = '.' . $ext;
-            $files[] = '*.' . $ext;
-        }
-        $this->getConfig()
-            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload', array('type' => $type)))
-            ->setParams($params)
-            ->setFileField('image')
-            ->setFilters(array(
-                'images' => array(
-                    'label' => $this->helper('cms')->__('Images (%s)', implode(', ', $labels)),
-                    'files' => $files
-                )
+        $this->getUploaderConfig()
+            ->setFileParameterName('image')
+            ->setTarget(
+                Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload', array('type' => $type))
+            );
+        $this->getButtonConfig()
+            ->setAttributes(array(
+                'accept' => $this->getButtonConfig()->getMimeTypesByExtensions($allowed)
             ));
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Media/Uploader.php app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
index 9108041..3f471f5 100644
--- app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
+++ app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
@@ -31,189 +31,20 @@
  * @package    Mage_Adminhtml
  * @author      Magento Core Team <core@magentocommerce.com>
  */
-class Mage_Adminhtml_Block_Media_Uploader extends Mage_Adminhtml_Block_Widget
-{
-
-    protected $_config;
-
-    public function __construct()
-    {
-        parent::__construct();
-        $this->setId($this->getId() . '_Uploader');
-        $this->setTemplate('media/uploader.phtml');
-        $this->getConfig()->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload'));
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField('file');
-        $this->getConfig()->setFilters(array(
-            'images' => array(
-                'label' => Mage::helper('adminhtml')->__('Images (.gif, .jpg, .png)'),
-                'files' => array('*.gif', '*.jpg', '*.png')
-            ),
-            'media' => array(
-                'label' => Mage::helper('adminhtml')->__('Media (.avi, .flv, .swf)'),
-                'files' => array('*.avi', '*.flv', '*.swf')
-            ),
-            'all'    => array(
-                'label' => Mage::helper('adminhtml')->__('All Files'),
-                'files' => array('*.*')
-            )
-        ));
-    }
-
-    protected function _prepareLayout()
-    {
-        $this->setChild(
-            'browse_button',
-            $this->getLayout()->createBlock('adminhtml/widget_button')
-                ->addData(array(
-                    'id'      => $this->_getButtonId('browse'),
-                    'label'   => Mage::helper('adminhtml')->__('Browse Files...'),
-                    'type'    => 'button',
-                    'onclick' => $this->getJsObjectName() . '.browse()'
-                ))
-        );
-
-        $this->setChild(
-            'upload_button',
-            $this->getLayout()->createBlock('adminhtml/widget_button')
-                ->addData(array(
-                    'id'      => $this->_getButtonId('upload'),
-                    'label'   => Mage::helper('adminhtml')->__('Upload Files'),
-                    'type'    => 'button',
-                    'onclick' => $this->getJsObjectName() . '.upload()'
-                ))
-        );
-
-        $this->setChild(
-            'delete_button',
-            $this->getLayout()->createBlock('adminhtml/widget_button')
-                ->addData(array(
-                    'id'      => '{{id}}-delete',
-                    'class'   => 'delete',
-                    'type'    => 'button',
-                    'label'   => Mage::helper('adminhtml')->__('Remove'),
-                    'onclick' => $this->getJsObjectName() . '.removeFile(\'{{fileId}}\')'
-                ))
-        );
-
-        return parent::_prepareLayout();
-    }
-
-    protected function _getButtonId($buttonName)
-    {
-        return $this->getHtmlId() . '-' . $buttonName;
-    }
-
-    public function getBrowseButtonHtml()
-    {
-        return $this->getChildHtml('browse_button');
-    }
-
-    public function getUploadButtonHtml()
-    {
-        return $this->getChildHtml('upload_button');
-    }
-
-    public function getDeleteButtonHtml()
-    {
-        return $this->getChildHtml('delete_button');
-    }
-
-    /**
-     * Retrive uploader js object name
-     *
-     * @return string
-     */
-    public function getJsObjectName()
-    {
-        return $this->getHtmlId() . 'JsObject';
-    }
-
-    /**
-     * Retrive config json
-     *
-     * @return string
-     */
-    public function getConfigJson()
-    {
-        return Mage::helper('core')->jsonEncode($this->getConfig()->getData());
-    }
-
-    /**
-     * Retrive config object
-     *
-     * @return Varien_Config
-     */
-    public function getConfig()
-    {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
-    }
-
-    public function getPostMaxSize()
-    {
-        return ini_get('post_max_size');
-    }
-
-    public function getUploadMaxSize()
-    {
-        return ini_get('upload_max_filesize');
-    }
-
-    public function getDataMaxSize()
-    {
-        return min($this->getPostMaxSize(), $this->getUploadMaxSize());
-    }
-
-    public function getDataMaxSizeInBytes()
-    {
-        $iniSize = $this->getDataMaxSize();
-        $size = substr($iniSize, 0, strlen($iniSize)-1);
-        $parsedSize = 0;
-        switch (strtolower(substr($iniSize, strlen($iniSize)-1))) {
-            case 't':
-                $parsedSize = $size*(1024*1024*1024*1024);
-                break;
-            case 'g':
-                $parsedSize = $size*(1024*1024*1024);
-                break;
-            case 'm':
-                $parsedSize = $size*(1024*1024);
-                break;
-            case 'k':
-                $parsedSize = $size*1024;
-                break;
-            case 'b':
-            default:
-                $parsedSize = $size;
-                break;
-        }
-        return $parsedSize;
-    }
 
+/**
+ * @deprecated
+ * Class Mage_Adminhtml_Block_Media_Uploader
+ */
+class Mage_Adminhtml_Block_Media_Uploader extends Mage_Uploader_Block_Multiple
+{
     /**
-     * Retrieve full uploader SWF's file URL
-     * Implemented to solve problem with cross domain SWFs
-     * Now uploader can be only in the same URL where backend located
-     *
-     * @param string $url url to uploader in current theme
-     *
-     * @return string full URL
+     * Constructor for uploader block
      */
-    public function getUploaderUrl($url)
+    public function __construct()
     {
-        if (!is_string($url)) {
-            $url = '';
-        }
-        $design = Mage::getDesign();
-        $theme = $design->getTheme('skin');
-        if (empty($url) || !$design->validateFile($url, array('_type' => 'skin', '_theme' => $theme))) {
-            $theme = $design->getDefaultTheme();
-        }
-        return Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB) . 'skin/' .
-            $design->getArea() . '/' . $design->getPackageName() . '/' . $theme . '/' . $url;
+        parent::__construct();
+        $this->getUploaderConfig()->setTarget(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload'));
+        $this->getUploaderConfig()->setFileParameterName('file');
     }
 }
diff --git app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php
index 274f2c5..740d335 100644
--- app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php
+++ app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php
@@ -119,7 +119,7 @@ class Mage_Adminhtml_Block_Urlrewrite_Category_Tree extends Mage_Adminhtml_Block
             'parent_id'      => (int)$node->getParentId(),
             'children_count' => (int)$node->getChildrenCount(),
             'is_active'      => (bool)$node->getIsActive(),
-            'name'           => $node->getName(),
+            'name'           => $this->escapeHtml($node->getName()),
             'level'          => (int)$node->getLevel(),
             'product_count'  => (int)$node->getProductCount()
         );
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php
index 771268b..bad3d24 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php
@@ -29,8 +29,17 @@ class Mage_Adminhtml_Model_System_Config_Backend_Serialized extends Mage_Core_Mo
     protected function _afterLoad()
     {
         if (!is_array($this->getValue())) {
-            $value = $this->getValue();
-            $this->setValue(empty($value) ? false : unserialize($value));
+            $serializedValue = $this->getValue();
+            $unserializedValue = false;
+            if (!empty($serializedValue)) {
+                try {
+                    $unserializedValue = Mage::helper('core/unserializeArray')
+                        ->unserialize($serializedValue);
+                } catch (Exception $e) {
+                    Mage::logException($e);
+                }
+            }
+            $this->setValue($unserializedValue);
         }
     }
 
diff --git app/code/core/Mage/Adminhtml/controllers/DashboardController.php app/code/core/Mage/Adminhtml/controllers/DashboardController.php
index 93774d7..aa9d55f 100644
--- app/code/core/Mage/Adminhtml/controllers/DashboardController.php
+++ app/code/core/Mage/Adminhtml/controllers/DashboardController.php
@@ -91,7 +91,7 @@ class Mage_Adminhtml_DashboardController extends Mage_Adminhtml_Controller_Actio
         $gaHash = $this->getRequest()->getParam('h');
         if ($gaData && $gaHash) {
             $newHash = Mage::helper('adminhtml/dashboard_data')->getChartDataHash($gaData);
-            if ($newHash == $gaHash) {
+            if (hash_equals($newHash, $gaHash)) {
                 $params = json_decode(base64_decode(urldecode($gaData)), true);
                 if ($params) {
                     $response = $httpClient->setUri(Mage_Adminhtml_Block_Dashboard_Graph::API_URL)
diff --git app/code/core/Mage/Adminhtml/controllers/IndexController.php app/code/core/Mage/Adminhtml/controllers/IndexController.php
index 8527304..dba311b 100644
--- app/code/core/Mage/Adminhtml/controllers/IndexController.php
+++ app/code/core/Mage/Adminhtml/controllers/IndexController.php
@@ -391,7 +391,7 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
         }
 
         $userToken = $user->getRpToken();
-        if (strcmp($userToken, $resetPasswordLinkToken) != 0 || $user->isResetPasswordLinkTokenExpired()) {
+        if (!hash_equals($userToken, $resetPasswordLinkToken) || $user->isResetPasswordLinkTokenExpired()) {
             throw Mage::exception('Mage_Core', Mage::helper('adminhtml')->__('Your password reset link has expired.'));
         }
     }
diff --git app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
index 65ca7e4..33c97fc 100644
--- app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
+++ app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
@@ -43,7 +43,7 @@ class Mage_Adminhtml_Media_UploaderController extends Mage_Adminhtml_Controller_
     {
         $this->loadLayout();
         $this->_addContent(
-            $this->getLayout()->createBlock('adminhtml/media_uploader')
+            $this->getLayout()->createBlock('uploader/multiple')
         );
         $this->renderLayout();
     }
diff --git app/code/core/Mage/Catalog/Helper/Image.php app/code/core/Mage/Catalog/Helper/Image.php
index 01adf38..6735129 100644
--- app/code/core/Mage/Catalog/Helper/Image.php
+++ app/code/core/Mage/Catalog/Helper/Image.php
@@ -33,6 +33,7 @@ class Mage_Catalog_Helper_Image extends Mage_Core_Helper_Abstract
 {
     const XML_NODE_PRODUCT_BASE_IMAGE_WIDTH = 'catalog/product_image/base_width';
     const XML_NODE_PRODUCT_SMALL_IMAGE_WIDTH = 'catalog/product_image/small_width';
+    const XML_NODE_PRODUCT_MAX_DIMENSION = 'catalog/product_image/max_dimension';
 
     /**
      * Current model
@@ -634,10 +635,16 @@ class Mage_Catalog_Helper_Image extends Mage_Core_Helper_Abstract
      * @throws Mage_Core_Exception
      */
     public function validateUploadFile($filePath) {
-        if (!getimagesize($filePath)) {
+        $maxDimension = Mage::getStoreConfig(self::XML_NODE_PRODUCT_MAX_DIMENSION);
+        $imageInfo = getimagesize($filePath);
+        if (!$imageInfo) {
             Mage::throwException($this->__('Disallowed file type.'));
         }
 
+        if ($imageInfo[0] > $maxDimension || $imageInfo[1] > $maxDimension) {
+            Mage::throwException($this->__('Disalollowed file format.'));
+        }
+
         $_processor = new Varien_Image($filePath);
         return $_processor->getMimeType() !== null;
     }
diff --git app/code/core/Mage/Catalog/etc/config.xml app/code/core/Mage/Catalog/etc/config.xml
index 1bd15f4..33b41c4 100644
--- app/code/core/Mage/Catalog/etc/config.xml
+++ app/code/core/Mage/Catalog/etc/config.xml
@@ -807,6 +807,7 @@
             <product_image>
                 <base_width>1800</base_width>
                 <small_width>210</small_width>
+                <max_dimension>5000</max_dimension>
             </product_image>
             <seo>
                 <product_url_suffix>.html</product_url_suffix>
diff --git app/code/core/Mage/Catalog/etc/system.xml app/code/core/Mage/Catalog/etc/system.xml
index 37de868..35a841e 100644
--- app/code/core/Mage/Catalog/etc/system.xml
+++ app/code/core/Mage/Catalog/etc/system.xml
@@ -211,6 +211,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
                         </small_width>
+                        <max_dimension translate="label comment">
+                            <label>Maximum resolution for upload image</label>
+                            <comment>Maximum width and height resolutions for upload image</comment>
+                            <frontend_type>text</frontend_type>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>1</show_in_store>
+                        </max_dimension>
                     </fields>
                 </product_image>
                 <placeholder translate="label">
diff --git app/code/core/Mage/Centinel/Model/Api.php app/code/core/Mage/Centinel/Model/Api.php
index 5dc0ccd..b2af2a35 100644
--- app/code/core/Mage/Centinel/Model/Api.php
+++ app/code/core/Mage/Centinel/Model/Api.php
@@ -25,11 +25,6 @@
  */
 
 /**
- * 3D Secure Validation Library for Payment
- */
-include_once '3Dsecure/CentinelClient.php';
-
-/**
  * 3D Secure Validation Api
  */
 class Mage_Centinel_Model_Api extends Varien_Object
@@ -73,19 +68,19 @@ class Mage_Centinel_Model_Api extends Varien_Object
     /**
      * Centinel validation client
      *
-     * @var CentinelClient
+     * @var Mage_Centinel_Model_Api_Client
      */
     protected $_clientInstance = null;
 
     /**
      * Return Centinel thin client object
      *
-     * @return CentinelClient
+     * @return Mage_Centinel_Model_Api_Client
      */
     protected function _getClientInstance()
     {
         if (empty($this->_clientInstance)) {
-            $this->_clientInstance = new CentinelClient();
+            $this->_clientInstance = new Mage_Centinel_Model_Api_Client();
         }
         return $this->_clientInstance;
     }
@@ -136,7 +131,7 @@ class Mage_Centinel_Model_Api extends Varien_Object
      * @param $method string
      * @param $data array
      *
-     * @return CentinelClient
+     * @return Mage_Centinel_Model_Api_Client
      */
     protected function _call($method, $data)
     {
diff --git app/code/core/Mage/Centinel/Model/Api/Client.php app/code/core/Mage/Centinel/Model/Api/Client.php
new file mode 100644
index 0000000..e91a482
--- /dev/null
+++ app/code/core/Mage/Centinel/Model/Api/Client.php
@@ -0,0 +1,79 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Centinel
+ * @copyright Copyright (c) 2006-2014 X.commerce, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * 3D Secure Validation Library for Payment
+ */
+include_once '3Dsecure/CentinelClient.php';
+
+/**
+ * 3D Secure Validation Api
+ */
+class Mage_Centinel_Model_Api_Client extends CentinelClient
+{
+    public function sendHttp($url, $connectTimeout = "", $timeout)
+    {
+        // verify that the URL uses a supported protocol.
+        if ((strpos($url, "http://") === 0) || (strpos($url, "https://") === 0)) {
+
+            //Construct the payload to POST to the url.
+            $data = $this->getRequestXml();
+
+            // create a new cURL resource
+            $ch = curl_init($url);
+
+            // set URL and other appropriate options
+            curl_setopt($ch, CURLOPT_POST ,1);
+            curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
+            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
+            curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
+            curl_setopt($ch, CURLOPT_TIMEOUT, $timeout);
+
+            // Execute the request.
+            $result = curl_exec($ch);
+            $succeeded = curl_errno($ch) == 0 ? true : false;
+
+            // close cURL resource, and free up system resources
+            curl_close($ch);
+
+            // If Communication was not successful set error result, otherwise
+            if (!$succeeded) {
+                $result = $this->setErrorResponse(CENTINEL_ERROR_CODE_8030, CENTINEL_ERROR_CODE_8030_DESC);
+            }
+
+            // Assert that we received an expected Centinel Message in reponse.
+            if (strpos($result, "<CardinalMPI>") === false) {
+                $result = $this->setErrorResponse(CENTINEL_ERROR_CODE_8010, CENTINEL_ERROR_CODE_8010_DESC);
+            }
+        } else {
+            $result = $this->setErrorResponse(CENTINEL_ERROR_CODE_8000, CENTINEL_ERROR_CODE_8000_DESC);
+        }
+        $parser = new XMLParser;
+        $parser->deserializeXml($result);
+        $this->response = $parser->deserializedResponse;
+    }
+}
diff --git app/code/core/Mage/Core/Block/Abstract.php app/code/core/Mage/Core/Block/Abstract.php
index 2c332b2..3723f81 100644
--- app/code/core/Mage/Core/Block/Abstract.php
+++ app/code/core/Mage/Core/Block/Abstract.php
@@ -37,6 +37,10 @@
 abstract class Mage_Core_Block_Abstract extends Varien_Object
 {
     /**
+     * Prefix for cache key
+     */
+    const CACHE_KEY_PREFIX = 'BLOCK_';
+    /**
      * Cache group Tag
      */
     const CACHE_GROUP = 'block_html';
@@ -1289,7 +1293,13 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
     public function getCacheKey()
     {
         if ($this->hasData('cache_key')) {
-            return $this->getData('cache_key');
+            $cacheKey = $this->getData('cache_key');
+            if (strpos($cacheKey, self::CACHE_KEY_PREFIX) !== 0) {
+                $cacheKey = self::CACHE_KEY_PREFIX . $cacheKey;
+                $this->setData('cache_key', $cacheKey);
+            }
+
+            return $cacheKey;
         }
         /**
          * don't prevent recalculation by saving generated cache key
diff --git app/code/core/Mage/Core/Helper/Url.php app/code/core/Mage/Core/Helper/Url.php
index 99cf1cf..4cc386e 100644
--- app/code/core/Mage/Core/Helper/Url.php
+++ app/code/core/Mage/Core/Helper/Url.php
@@ -51,7 +51,7 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
             $port = (in_array($port, $defaultPorts)) ? '' : ':' . $port;
         }
         $url = $request->getScheme() . '://' . $request->getHttpHost() . $port . $request->getServer('REQUEST_URI');
-        return $url;
+        return $this->escapeUrl($url);
 //        return $this->_getUrl('*/*/*', array('_current' => true, '_use_rewrite' => true));
     }
 
diff --git app/code/core/Mage/Core/Model/Encryption.php app/code/core/Mage/Core/Model/Encryption.php
index 8182f13..c1e5060 100644
--- app/code/core/Mage/Core/Model/Encryption.php
+++ app/code/core/Mage/Core/Model/Encryption.php
@@ -98,9 +98,9 @@ class Mage_Core_Model_Encryption
         $hashArr = explode(':', $hash);
         switch (count($hashArr)) {
             case 1:
-                return $this->hash($password) === $hash;
+                return hash_equals($this->hash($password), $hash);
             case 2:
-                return $this->hash($hashArr[1] . $password) === $hashArr[0];
+                return hash_equals($this->hash($hashArr[1] . $password),  $hashArr[0]);
         }
         Mage::throwException('Invalid hash.');
     }
diff --git app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
index 3c2f034..1fde1fa 100644
--- app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
+++ app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
@@ -65,7 +65,13 @@ class Mage_Core_Model_Input_Filter_MaliciousCode implements Zend_Filter_Interfac
      */
     public function filter($value)
     {
-        return preg_replace($this->_expressions, '', $value);
+        $result = false;
+        do {
+            $subject = $result ? $result : $value;
+            $result = preg_replace($this->_expressions, '', $subject, -1, $count);
+        } while ($count !== 0);
+
+        return $result;
     }
 
     /**
diff --git app/code/core/Mage/Core/functions.php app/code/core/Mage/Core/functions.php
index 336b08e..52f6cda 100644
--- app/code/core/Mage/Core/functions.php
+++ app/code/core/Mage/Core/functions.php
@@ -375,3 +375,38 @@ if ( !function_exists('sys_get_temp_dir') ) {
         }
     }
 }
+
+if (!function_exists('hash_equals')) {
+    /**
+     * Compares two strings using the same time whether they're equal or not.
+     * A difference in length will leak
+     *
+     * @param string $known_string
+     * @param string $user_string
+     * @return boolean Returns true when the two strings are equal, false otherwise.
+     */
+    function hash_equals($known_string, $user_string)
+    {
+        $result = 0;
+
+        if (!is_string($known_string)) {
+            trigger_error("hash_equals(): Expected known_string to be a string", E_USER_WARNING);
+            return false;
+        }
+
+        if (!is_string($user_string)) {
+            trigger_error("hash_equals(): Expected user_string to be a string", E_USER_WARNING);
+            return false;
+        }
+
+        if (strlen($known_string) != strlen($user_string)) {
+            return false;
+        }
+
+        for ($i = 0; $i < strlen($known_string); $i++) {
+            $result |= (ord($known_string[$i]) ^ ord($user_string[$i]));
+        }
+
+        return 0 === $result;
+    }
+}
diff --git app/code/core/Mage/Customer/Block/Address/Book.php app/code/core/Mage/Customer/Block/Address/Book.php
index 4e4366c..c07e512 100644
--- app/code/core/Mage/Customer/Block/Address/Book.php
+++ app/code/core/Mage/Customer/Block/Address/Book.php
@@ -56,7 +56,8 @@ class Mage_Customer_Block_Address_Book extends Mage_Core_Block_Template
 
     public function getDeleteUrl()
     {
-        return $this->getUrl('customer/address/delete');
+        return $this->getUrl('customer/address/delete',
+            array(Mage_Core_Model_Url::FORM_KEY => Mage::getSingleton('core/session')->getFormKey()));
     }
 
     public function getAddressEditUrl($address)
diff --git app/code/core/Mage/Customer/controllers/AddressController.php app/code/core/Mage/Customer/controllers/AddressController.php
index dd56ec3..287d08d 100644
--- app/code/core/Mage/Customer/controllers/AddressController.php
+++ app/code/core/Mage/Customer/controllers/AddressController.php
@@ -163,6 +163,9 @@ class Mage_Customer_AddressController extends Mage_Core_Controller_Front_Action
 
     public function deleteAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*/');
+        }
         $addressId = $this->getRequest()->getParam('id', false);
 
         if ($addressId) {
diff --git app/code/core/Mage/Dataflow/Model/Profile.php app/code/core/Mage/Dataflow/Model/Profile.php
index bfb881f..bea527d 100644
--- app/code/core/Mage/Dataflow/Model/Profile.php
+++ app/code/core/Mage/Dataflow/Model/Profile.php
@@ -64,10 +64,14 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
 
     protected function _afterLoad()
     {
+        $guiData = '';
         if (is_string($this->getGuiData())) {
-            $guiData = unserialize($this->getGuiData());
-        } else {
-            $guiData = '';
+            try {
+                $guiData = Mage::helper('core/unserializeArray')
+                    ->unserialize($this->getGuiData());
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
         $this->setGuiData($guiData);
 
@@ -127,7 +131,13 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
     protected function _afterSave()
     {
         if (is_string($this->getGuiData())) {
-            $this->setGuiData(unserialize($this->getGuiData()));
+            try {
+                $guiData = Mage::helper('core/unserializeArray')
+                    ->unserialize($this->getGuiData());
+                $this->setGuiData($guiData);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
 
         $profileHistory = Mage::getModel('dataflow/profile_history');
diff --git app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
index 99840f2..eede8ef 100644
--- app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
+++ app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
@@ -32,7 +32,7 @@
  * @author      Magento Core Team <core@magentocommerce.com>
  */
 class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Links
-    extends Mage_Adminhtml_Block_Template
+    extends Mage_Uploader_Block_Single
 {
     /**
      * Purchased Separately Attribute cache
@@ -242,6 +242,7 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
      */
      protected function _prepareLayout()
     {
+        parent::_prepareLayout();
         $this->setChild(
             'upload_button',
             $this->getLayout()->createBlock('adminhtml/widget_button')->addData(array(
@@ -251,6 +252,10 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
                 'onclick' => 'Downloadable.massUploadByType(\'links\');Downloadable.massUploadByType(\'linkssample\')'
             ))
         );
+        $this->_addElementIdsMapping(array(
+            'container' => $this->getHtmlId() . '-new',
+            'delete'    => $this->getHtmlId() . '-delete'
+        ));
     }
 
     /**
@@ -270,33 +275,56 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
      */
     public function getConfigJson($type='links')
     {
-        $this->getConfig()->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()
-            ->getUrl('*/downloadable_file/upload', array('type' => $type, '_secure' => true)));
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField($type);
-        $this->getConfig()->setFilters(array(
-            'all'    => array(
-                'label' => Mage::helper('adminhtml')->__('All Files'),
-                'files' => array('*.*')
+
+        $this->getUploaderConfig()
+            ->setFileParameterName($type)
+            ->setTarget(
+                Mage::getModel('adminhtml/url')
+                    ->addSessionParam()
+                    ->getUrl('*/downloadable_file/upload', array('type' => $type, '_secure' => true))
+            );
+        $this->getMiscConfig()
+            ->setReplaceBrowseWithRemove(true)
+        ;
+        return Mage::helper('core')->jsonEncode(parent::getJsonConfig());
+    }
+
+    /**
+     * @return string
+     */
+    public function getBrowseButtonHtml($type = '')
+    {
+        return $this->getChild('browse_button')
+            // Workaround for IE9
+            ->setBeforeHtml(
+                '<div style="display:inline-block; " id="downloadable_link_{{id}}_' . $type . 'file-browse">'
             )
-        ));
-        $this->getConfig()->setReplaceBrowseWithRemove(true);
-        $this->getConfig()->setWidth('32');
-        $this->getConfig()->setHideUploadButton(true);
-        return Mage::helper('core')->jsonEncode($this->getConfig()->getData());
+            ->setAfterHtml('</div>')
+            ->setId('downloadable_link_{{id}}_' . $type . 'file-browse_button')
+            ->toHtml();
     }
 
+
     /**
-     * Retrive config object
+     * @return string
+     */
+    public function getDeleteButtonHtml($type = '')
+    {
+        return $this->getChild('delete_button')
+            ->setLabel('')
+            ->setId('downloadable_link_{{id}}_' . $type . 'file-delete')
+            ->setStyle('display:none; width:31px;')
+            ->toHtml();
+    }
+
+    /**
+     * Retrieve config object
      *
-     * @return Varien_Config
+     * @deprecated
+     * @return $this
      */
     public function getConfig()
     {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
+        return $this;
     }
 }
diff --git app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php
index 620d84f..99a6646 100644
--- app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php
+++ app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php
@@ -32,7 +32,7 @@
  * @author      Magento Core Team <core@magentocommerce.com>
  */
 class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Samples
-    extends Mage_Adminhtml_Block_Widget
+    extends Mage_Uploader_Block_Single
 {
     /**
      * Class constructor
@@ -148,6 +148,7 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Sa
      */
     protected function _prepareLayout()
     {
+        parent::_prepareLayout();
         $this->setChild(
             'upload_button',
             $this->getLayout()->createBlock('adminhtml/widget_button')
@@ -158,6 +159,11 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Sa
                     'onclick' => 'Downloadable.massUploadByType(\'samples\')'
                 ))
         );
+
+        $this->_addElementIdsMapping(array(
+            'container' => $this->getHtmlId() . '-new',
+            'delete'    => $this->getHtmlId() . '-delete'
+        ));
     }
 
     /**
@@ -171,40 +177,59 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Sa
     }
 
     /**
-     * Retrive config json
+     * Retrieve config json
      *
      * @return string
      */
     public function getConfigJson()
     {
-        $this->getConfig()->setUrl(Mage::getModel('adminhtml/url')
-            ->addSessionParam()
-            ->getUrl('*/downloadable_file/upload', array('type' => 'samples', '_secure' => true)));
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField('samples');
-        $this->getConfig()->setFilters(array(
-            'all'    => array(
-                'label' => Mage::helper('adminhtml')->__('All Files'),
-                'files' => array('*.*')
-            )
-        ));
-        $this->getConfig()->setReplaceBrowseWithRemove(true);
-        $this->getConfig()->setWidth('32');
-        $this->getConfig()->setHideUploadButton(true);
-        return Mage::helper('core')->jsonEncode($this->getConfig()->getData());
+        $this->getUploaderConfig()
+            ->setFileParameterName('samples')
+            ->setTarget(
+                Mage::getModel('adminhtml/url')
+                    ->addSessionParam()
+                    ->getUrl('*/downloadable_file/upload', array('type' => 'samples', '_secure' => true))
+            );
+        $this->getMiscConfig()
+            ->setReplaceBrowseWithRemove(true)
+        ;
+        return Mage::helper('core')->jsonEncode(parent::getJsonConfig());
     }
 
     /**
-     * Retrive config object
+     * @return string
+     */
+    public function getBrowseButtonHtml()
+    {
+        return $this->getChild('browse_button')
+            // Workaround for IE9
+            ->setBeforeHtml('<div style="display:inline-block; " id="downloadable_sample_{{id}}_file-browse">')
+            ->setAfterHtml('</div>')
+            ->setId('downloadable_sample_{{id}}_file-browse_button')
+            ->toHtml();
+    }
+
+
+    /**
+     * @return string
+     */
+    public function getDeleteButtonHtml()
+    {
+        return $this->getChild('delete_button')
+            ->setLabel('')
+            ->setId('downloadable_sample_{{id}}_file-delete')
+            ->setStyle('display:none; width:31px;')
+            ->toHtml();
+    }
+
+    /**
+     * Retrieve config object
      *
-     * @return Varien_Config
+     * @deprecated
+     * @return $this
      */
     public function getConfig()
     {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
+        return $this;
     }
 }
diff --git app/code/core/Mage/Downloadable/Helper/File.php app/code/core/Mage/Downloadable/Helper/File.php
index 1a95461..ec0a011 100644
--- app/code/core/Mage/Downloadable/Helper/File.php
+++ app/code/core/Mage/Downloadable/Helper/File.php
@@ -33,15 +33,35 @@
  */
 class Mage_Downloadable_Helper_File extends Mage_Core_Helper_Abstract
 {
+    /**
+     * @see Mage_Uploader_Helper_File::getMimeTypes
+     * @var array
+     */
+    protected $_mimeTypes;
+
+    /**
+     * @var Mage_Uploader_Helper_File
+     */
+    protected $_fileHelper;
+
+    /**
+     * Populate self::_mimeTypes array with values that set in config or pre-defined
+     */
     public function __construct()
     {
-        $nodes = Mage::getConfig()->getNode('global/mime/types');
-        if ($nodes) {
-            $nodes = (array)$nodes;
-            foreach ($nodes as $key => $value) {
-                self::$_mimeTypes[$key] = $value;
-            }
+        $this->_mimeTypes = $this->_getFileHelper()->getMimeTypes();
+    }
+
+    /**
+     * @return Mage_Uploader_Helper_File
+     */
+    protected function _getFileHelper()
+    {
+        if (!$this->_fileHelper) {
+            $this->_fileHelper = Mage::helper('uploader/file');
         }
+
+        return $this->_fileHelper;
     }
 
     /**
@@ -152,628 +172,48 @@ class Mage_Downloadable_Helper_File extends Mage_Core_Helper_Abstract
         return $file;
     }
 
+    /**
+     * Get MIME type for $filePath
+     *
+     * @param $filePath
+     * @return string
+     */
     public function getFileType($filePath)
     {
         $ext = substr($filePath, strrpos($filePath, '.')+1);
         return $this->_getFileTypeByExt($ext);
     }
 
+    /**
+     * Get MIME type by file extension
+     *
+     * @param $ext
+     * @return string
+     * @deprecated
+     */
     protected function _getFileTypeByExt($ext)
     {
-        $type = 'x' . $ext;
-        if (isset(self::$_mimeTypes[$type])) {
-            return self::$_mimeTypes[$type];
-        }
-        return 'application/octet-stream';
+        return $this->_getFileHelper()->getMimeTypeByExtension($ext);
     }
 
+    /**
+     * Get all MIME types
+     *
+     * @return array
+     */
     public function getAllFileTypes()
     {
-        return array_values(self::getAllMineTypes());
+        return array_values($this->getAllMineTypes());
     }
 
+    /**
+     * Get list of all MIME types
+     *
+     * @return array
+     */
     public function getAllMineTypes()
     {
-        return self::$_mimeTypes;
+        return $this->_mimeTypes;
     }
 
-    protected static $_mimeTypes =
-        array(
-            'x123' => 'application/vnd.lotus-1-2-3',
-            'x3dml' => 'text/vnd.in3d.3dml',
-            'x3g2' => 'video/3gpp2',
-            'x3gp' => 'video/3gpp',
-            'xace' => 'application/x-ace-compressed',
-            'xacu' => 'application/vnd.acucobol',
-            'xaep' => 'application/vnd.audiograph',
-            'xai' => 'application/postscript',
-            'xaif' => 'audio/x-aiff',
-
-            'xaifc' => 'audio/x-aiff',
-            'xaiff' => 'audio/x-aiff',
-            'xami' => 'application/vnd.amiga.ami',
-            'xapr' => 'application/vnd.lotus-approach',
-            'xasf' => 'video/x-ms-asf',
-            'xaso' => 'application/vnd.accpac.simply.aso',
-            'xasx' => 'video/x-ms-asf',
-            'xatom' => 'application/atom+xml',
-            'xatomcat' => 'application/atomcat+xml',
-
-            'xatomsvc' => 'application/atomsvc+xml',
-            'xatx' => 'application/vnd.antix.game-component',
-            'xau' => 'audio/basic',
-            'xavi' => 'video/x-msvideo',
-            'xbat' => 'application/x-msdownload',
-            'xbcpio' => 'application/x-bcpio',
-            'xbdm' => 'application/vnd.syncml.dm+wbxml',
-            'xbh2' => 'application/vnd.fujitsu.oasysprs',
-            'xbmi' => 'application/vnd.bmi',
-
-            'xbmp' => 'image/bmp',
-            'xbox' => 'application/vnd.previewsystems.box',
-            'xboz' => 'application/x-bzip2',
-            'xbtif' => 'image/prs.btif',
-            'xbz' => 'application/x-bzip',
-            'xbz2' => 'application/x-bzip2',
-            'xcab' => 'application/vnd.ms-cab-compressed',
-            'xccxml' => 'application/ccxml+xml',
-            'xcdbcmsg' => 'application/vnd.contact.cmsg',
-
-            'xcdkey' => 'application/vnd.mediastation.cdkey',
-            'xcdx' => 'chemical/x-cdx',
-            'xcdxml' => 'application/vnd.chemdraw+xml',
-            'xcdy' => 'application/vnd.cinderella',
-            'xcer' => 'application/pkix-cert',
-            'xcgm' => 'image/cgm',
-            'xchat' => 'application/x-chat',
-            'xchm' => 'application/vnd.ms-htmlhelp',
-            'xchrt' => 'application/vnd.kde.kchart',
-
-            'xcif' => 'chemical/x-cif',
-            'xcii' => 'application/vnd.anser-web-certificate-issue-initiation',
-            'xcil' => 'application/vnd.ms-artgalry',
-            'xcla' => 'application/vnd.claymore',
-            'xclkk' => 'application/vnd.crick.clicker.keyboard',
-            'xclkp' => 'application/vnd.crick.clicker.palette',
-            'xclkt' => 'application/vnd.crick.clicker.template',
-            'xclkw' => 'application/vnd.crick.clicker.wordbank',
-            'xclkx' => 'application/vnd.crick.clicker',
-
-            'xclp' => 'application/x-msclip',
-            'xcmc' => 'application/vnd.cosmocaller',
-            'xcmdf' => 'chemical/x-cmdf',
-            'xcml' => 'chemical/x-cml',
-            'xcmp' => 'application/vnd.yellowriver-custom-menu',
-            'xcmx' => 'image/x-cmx',
-            'xcom' => 'application/x-msdownload',
-            'xconf' => 'text/plain',
-            'xcpio' => 'application/x-cpio',
-
-            'xcpt' => 'application/mac-compactpro',
-            'xcrd' => 'application/x-mscardfile',
-            'xcrl' => 'application/pkix-crl',
-            'xcrt' => 'application/x-x509-ca-cert',
-            'xcsh' => 'application/x-csh',
-            'xcsml' => 'chemical/x-csml',
-            'xcss' => 'text/css',
-            'xcsv' => 'text/csv',
-            'xcurl' => 'application/vnd.curl',
-
-            'xcww' => 'application/prs.cww',
-            'xdaf' => 'application/vnd.mobius.daf',
-            'xdavmount' => 'application/davmount+xml',
-            'xdd2' => 'application/vnd.oma.dd2+xml',
-            'xddd' => 'application/vnd.fujixerox.ddd',
-            'xdef' => 'text/plain',
-            'xder' => 'application/x-x509-ca-cert',
-            'xdfac' => 'application/vnd.dreamfactory',
-            'xdis' => 'application/vnd.mobius.dis',
-
-            'xdjv' => 'image/vnd.djvu',
-            'xdjvu' => 'image/vnd.djvu',
-            'xdll' => 'application/x-msdownload',
-            'xdna' => 'application/vnd.dna',
-            'xdoc' => 'application/msword',
-            'xdot' => 'application/msword',
-            'xdp' => 'application/vnd.osgi.dp',
-            'xdpg' => 'application/vnd.dpgraph',
-            'xdsc' => 'text/prs.lines.tag',
-
-            'xdtd' => 'application/xml-dtd',
-            'xdvi' => 'application/x-dvi',
-            'xdwf' => 'model/vnd.dwf',
-            'xdwg' => 'image/vnd.dwg',
-            'xdxf' => 'image/vnd.dxf',
-            'xdxp' => 'application/vnd.spotfire.dxp',
-            'xecelp4800' => 'audio/vnd.nuera.ecelp4800',
-            'xecelp7470' => 'audio/vnd.nuera.ecelp7470',
-            'xecelp9600' => 'audio/vnd.nuera.ecelp9600',
-
-            'xecma' => 'application/ecmascript',
-            'xedm' => 'application/vnd.novadigm.edm',
-            'xedx' => 'application/vnd.novadigm.edx',
-            'xefif' => 'application/vnd.picsel',
-            'xei6' => 'application/vnd.pg.osasli',
-            'xeml' => 'message/rfc822',
-            'xeol' => 'audio/vnd.digital-winds',
-            'xeot' => 'application/vnd.ms-fontobject',
-            'xeps' => 'application/postscript',
-
-            'xesf' => 'application/vnd.epson.esf',
-            'xetx' => 'text/x-setext',
-            'xexe' => 'application/x-msdownload',
-            'xext' => 'application/vnd.novadigm.ext',
-            'xez' => 'application/andrew-inset',
-            'xez2' => 'application/vnd.ezpix-album',
-            'xez3' => 'application/vnd.ezpix-package',
-            'xfbs' => 'image/vnd.fastbidsheet',
-            'xfdf' => 'application/vnd.fdf',
-
-            'xfe_launch' => 'application/vnd.denovo.fcselayout-link',
-            'xfg5' => 'application/vnd.fujitsu.oasysgp',
-            'xfli' => 'video/x-fli',
-            'xflo' => 'application/vnd.micrografx.flo',
-            'xflw' => 'application/vnd.kde.kivio',
-            'xflx' => 'text/vnd.fmi.flexstor',
-            'xfly' => 'text/vnd.fly',
-            'xfnc' => 'application/vnd.frogans.fnc',
-            'xfpx' => 'image/vnd.fpx',
-
-            'xfsc' => 'application/vnd.fsc.weblaunch',
-            'xfst' => 'image/vnd.fst',
-            'xftc' => 'application/vnd.fluxtime.clip',
-            'xfti' => 'application/vnd.anser-web-funds-transfer-initiation',
-            'xfvt' => 'video/vnd.fvt',
-            'xfzs' => 'application/vnd.fuzzysheet',
-            'xg3' => 'image/g3fax',
-            'xgac' => 'application/vnd.groove-account',
-            'xgdl' => 'model/vnd.gdl',
-
-            'xghf' => 'application/vnd.groove-help',
-            'xgif' => 'image/gif',
-            'xgim' => 'application/vnd.groove-identity-message',
-            'xgph' => 'application/vnd.flographit',
-            'xgram' => 'application/srgs',
-            'xgrv' => 'application/vnd.groove-injector',
-            'xgrxml' => 'application/srgs+xml',
-            'xgtar' => 'application/x-gtar',
-            'xgtm' => 'application/vnd.groove-tool-message',
-
-            'xgtw' => 'model/vnd.gtw',
-            'xh261' => 'video/h261',
-            'xh263' => 'video/h263',
-            'xh264' => 'video/h264',
-            'xhbci' => 'application/vnd.hbci',
-            'xhdf' => 'application/x-hdf',
-            'xhlp' => 'application/winhlp',
-            'xhpgl' => 'application/vnd.hp-hpgl',
-            'xhpid' => 'application/vnd.hp-hpid',
-
-            'xhps' => 'application/vnd.hp-hps',
-            'xhqx' => 'application/mac-binhex40',
-            'xhtke' => 'application/vnd.kenameaapp',
-            'xhtm' => 'text/html',
-            'xhtml' => 'text/html',
-            'xhvd' => 'application/vnd.yamaha.hv-dic',
-            'xhvp' => 'application/vnd.yamaha.hv-voice',
-            'xhvs' => 'application/vnd.yamaha.hv-script',
-            'xice' => '#x-conference/x-cooltalk',
-
-            'xico' => 'image/x-icon',
-            'xics' => 'text/calendar',
-            'xief' => 'image/ief',
-            'xifb' => 'text/calendar',
-            'xifm' => 'application/vnd.shana.informed.formdata',
-            'xigl' => 'application/vnd.igloader',
-            'xigx' => 'application/vnd.micrografx.igx',
-            'xiif' => 'application/vnd.shana.informed.interchange',
-            'ximp' => 'application/vnd.accpac.simply.imp',
-
-            'xims' => 'application/vnd.ms-ims',
-            'xin' => 'text/plain',
-            'xipk' => 'application/vnd.shana.informed.package',
-            'xirm' => 'application/vnd.ibm.rights-management',
-            'xirp' => 'application/vnd.irepository.package+xml',
-            'xitp' => 'application/vnd.shana.informed.formtemplate',
-            'xivp' => 'application/vnd.immervision-ivp',
-            'xivu' => 'application/vnd.immervision-ivu',
-            'xjad' => 'text/vnd.sun.j2me.app-descriptor',
-
-            'xjam' => 'application/vnd.jam',
-            'xjava' => 'text/x-java-source',
-            'xjisp' => 'application/vnd.jisp',
-            'xjlt' => 'application/vnd.hp-jlyt',
-            'xjoda' => 'application/vnd.joost.joda-archive',
-            'xjpe' => 'image/jpeg',
-            'xjpeg' => 'image/jpeg',
-            'xjpg' => 'image/jpeg',
-            'xjpgm' => 'video/jpm',
-
-            'xjpgv' => 'video/jpeg',
-            'xjpm' => 'video/jpm',
-            'xjs' => 'application/javascript',
-            'xjson' => 'application/json',
-            'xkar' => 'audio/midi',
-            'xkarbon' => 'application/vnd.kde.karbon',
-            'xkfo' => 'application/vnd.kde.kformula',
-            'xkia' => 'application/vnd.kidspiration',
-            'xkml' => 'application/vnd.google-earth.kml+xml',
-
-            'xkmz' => 'application/vnd.google-earth.kmz',
-            'xkon' => 'application/vnd.kde.kontour',
-            'xksp' => 'application/vnd.kde.kspread',
-            'xlatex' => 'application/x-latex',
-            'xlbd' => 'application/vnd.llamagraphics.life-balance.desktop',
-            'xlbe' => 'application/vnd.llamagraphics.life-balance.exchange+xml',
-            'xles' => 'application/vnd.hhe.lesson-player',
-            'xlist' => 'text/plain',
-            'xlog' => 'text/plain',
-
-            'xlrm' => 'application/vnd.ms-lrm',
-            'xltf' => 'application/vnd.frogans.ltf',
-            'xlvp' => 'audio/vnd.lucent.voice',
-            'xlwp' => 'application/vnd.lotus-wordpro',
-            'xm13' => 'application/x-msmediaview',
-            'xm14' => 'application/x-msmediaview',
-            'xm1v' => 'video/mpeg',
-            'xm2a' => 'audio/mpeg',
-            'xm3a' => 'audio/mpeg',
-
-            'xm3u' => 'audio/x-mpegurl',
-            'xm4u' => 'video/vnd.mpegurl',
-            'xmag' => 'application/vnd.ecowin.chart',
-            'xmathml' => 'application/mathml+xml',
-            'xmbk' => 'application/vnd.mobius.mbk',
-            'xmbox' => 'application/mbox',
-            'xmc1' => 'application/vnd.medcalcdata',
-            'xmcd' => 'application/vnd.mcd',
-            'xmdb' => 'application/x-msaccess',
-
-            'xmdi' => 'image/vnd.ms-modi',
-            'xmesh' => 'model/mesh',
-            'xmfm' => 'application/vnd.mfmp',
-            'xmgz' => 'application/vnd.proteus.magazine',
-            'xmid' => 'audio/midi',
-            'xmidi' => 'audio/midi',
-            'xmif' => 'application/vnd.mif',
-            'xmime' => 'message/rfc822',
-            'xmj2' => 'video/mj2',
-
-            'xmjp2' => 'video/mj2',
-            'xmlp' => 'application/vnd.dolby.mlp',
-            'xmmd' => 'application/vnd.chipnuts.karaoke-mmd',
-            'xmmf' => 'application/vnd.smaf',
-            'xmmr' => 'image/vnd.fujixerox.edmics-mmr',
-            'xmny' => 'application/x-msmoney',
-            'xmov' => 'video/quicktime',
-            'xmovie' => 'video/x-sgi-movie',
-            'xmp2' => 'audio/mpeg',
-
-            'xmp2a' => 'audio/mpeg',
-            'xmp3' => 'audio/mpeg',
-            'xmp4' => 'video/mp4',
-            'xmp4a' => 'audio/mp4',
-            'xmp4s' => 'application/mp4',
-            'xmp4v' => 'video/mp4',
-            'xmpc' => 'application/vnd.mophun.certificate',
-            'xmpe' => 'video/mpeg',
-            'xmpeg' => 'video/mpeg',
-
-            'xmpg' => 'video/mpeg',
-            'xmpg4' => 'video/mp4',
-            'xmpga' => 'audio/mpeg',
-            'xmpkg' => 'application/vnd.apple.installer+xml',
-            'xmpm' => 'application/vnd.blueice.multipass',
-            'xmpn' => 'application/vnd.mophun.application',
-            'xmpp' => 'application/vnd.ms-project',
-            'xmpt' => 'application/vnd.ms-project',
-            'xmpy' => 'application/vnd.ibm.minipay',
-
-            'xmqy' => 'application/vnd.mobius.mqy',
-            'xmrc' => 'application/marc',
-            'xmscml' => 'application/mediaservercontrol+xml',
-            'xmseq' => 'application/vnd.mseq',
-            'xmsf' => 'application/vnd.epson.msf',
-            'xmsh' => 'model/mesh',
-            'xmsi' => 'application/x-msdownload',
-            'xmsl' => 'application/vnd.mobius.msl',
-            'xmsty' => 'application/vnd.muvee.style',
-
-            'xmts' => 'model/vnd.mts',
-            'xmus' => 'application/vnd.musician',
-            'xmvb' => 'application/x-msmediaview',
-            'xmwf' => 'application/vnd.mfer',
-            'xmxf' => 'application/mxf',
-            'xmxl' => 'application/vnd.recordare.musicxml',
-            'xmxml' => 'application/xv+xml',
-            'xmxs' => 'application/vnd.triscape.mxs',
-            'xmxu' => 'video/vnd.mpegurl',
-
-            'xn-gage' => 'application/vnd.nokia.n-gage.symbian.install',
-            'xngdat' => 'application/vnd.nokia.n-gage.data',
-            'xnlu' => 'application/vnd.neurolanguage.nlu',
-            'xnml' => 'application/vnd.enliven',
-            'xnnd' => 'application/vnd.noblenet-directory',
-            'xnns' => 'application/vnd.noblenet-sealer',
-            'xnnw' => 'application/vnd.noblenet-web',
-            'xnpx' => 'image/vnd.net-fpx',
-            'xnsf' => 'application/vnd.lotus-notes',
-
-            'xoa2' => 'application/vnd.fujitsu.oasys2',
-            'xoa3' => 'application/vnd.fujitsu.oasys3',
-            'xoas' => 'application/vnd.fujitsu.oasys',
-            'xobd' => 'application/x-msbinder',
-            'xoda' => 'application/oda',
-            'xodc' => 'application/vnd.oasis.opendocument.chart',
-            'xodf' => 'application/vnd.oasis.opendocument.formula',
-            'xodg' => 'application/vnd.oasis.opendocument.graphics',
-            'xodi' => 'application/vnd.oasis.opendocument.image',
-
-            'xodp' => 'application/vnd.oasis.opendocument.presentation',
-            'xods' => 'application/vnd.oasis.opendocument.spreadsheet',
-            'xodt' => 'application/vnd.oasis.opendocument.text',
-            'xogg' => 'application/ogg',
-            'xoprc' => 'application/vnd.palm',
-            'xorg' => 'application/vnd.lotus-organizer',
-            'xotc' => 'application/vnd.oasis.opendocument.chart-template',
-            'xotf' => 'application/vnd.oasis.opendocument.formula-template',
-            'xotg' => 'application/vnd.oasis.opendocument.graphics-template',
-
-            'xoth' => 'application/vnd.oasis.opendocument.text-web',
-            'xoti' => 'application/vnd.oasis.opendocument.image-template',
-            'xotm' => 'application/vnd.oasis.opendocument.text-master',
-            'xots' => 'application/vnd.oasis.opendocument.spreadsheet-template',
-            'xott' => 'application/vnd.oasis.opendocument.text-template',
-            'xoxt' => 'application/vnd.openofficeorg.extension',
-            'xp10' => 'application/pkcs10',
-            'xp7r' => 'application/x-pkcs7-certreqresp',
-            'xp7s' => 'application/pkcs7-signature',
-
-            'xpbd' => 'application/vnd.powerbuilder6',
-            'xpbm' => 'image/x-portable-bitmap',
-            'xpcl' => 'application/vnd.hp-pcl',
-            'xpclxl' => 'application/vnd.hp-pclxl',
-            'xpct' => 'image/x-pict',
-            'xpcx' => 'image/x-pcx',
-            'xpdb' => 'chemical/x-pdb',
-            'xpdf' => 'application/pdf',
-            'xpfr' => 'application/font-tdpfr',
-
-            'xpgm' => 'image/x-portable-graymap',
-            'xpgn' => 'application/x-chess-pgn',
-            'xpgp' => 'application/pgp-encrypted',
-            'xpic' => 'image/x-pict',
-            'xpki' => 'application/pkixcmp',
-            'xpkipath' => 'application/pkix-pkipath',
-            'xplb' => 'application/vnd.3gpp.pic-bw-large',
-            'xplc' => 'application/vnd.mobius.plc',
-            'xplf' => 'application/vnd.pocketlearn',
-
-            'xpls' => 'application/pls+xml',
-            'xpml' => 'application/vnd.ctc-posml',
-            'xpng' => 'image/png',
-            'xpnm' => 'image/x-portable-anymap',
-            'xportpkg' => 'application/vnd.macports.portpkg',
-            'xpot' => 'application/vnd.ms-powerpoint',
-            'xppd' => 'application/vnd.cups-ppd',
-            'xppm' => 'image/x-portable-pixmap',
-            'xpps' => 'application/vnd.ms-powerpoint',
-
-            'xppt' => 'application/vnd.ms-powerpoint',
-            'xpqa' => 'application/vnd.palm',
-            'xprc' => 'application/vnd.palm',
-            'xpre' => 'application/vnd.lotus-freelance',
-            'xprf' => 'application/pics-rules',
-            'xps' => 'application/postscript',
-            'xpsb' => 'application/vnd.3gpp.pic-bw-small',
-            'xpsd' => 'image/vnd.adobe.photoshop',
-            'xptid' => 'application/vnd.pvi.ptid1',
-
-            'xpub' => 'application/x-mspublisher',
-            'xpvb' => 'application/vnd.3gpp.pic-bw-var',
-            'xpwn' => 'application/vnd.3m.post-it-notes',
-            'xqam' => 'application/vnd.epson.quickanime',
-            'xqbo' => 'application/vnd.intu.qbo',
-            'xqfx' => 'application/vnd.intu.qfx',
-            'xqps' => 'application/vnd.publishare-delta-tree',
-            'xqt' => 'video/quicktime',
-            'xra' => 'audio/x-pn-realaudio',
-
-            'xram' => 'audio/x-pn-realaudio',
-            'xrar' => 'application/x-rar-compressed',
-            'xras' => 'image/x-cmu-raster',
-            'xrcprofile' => 'application/vnd.ipunplugged.rcprofile',
-            'xrdf' => 'application/rdf+xml',
-            'xrdz' => 'application/vnd.data-vision.rdz',
-            'xrep' => 'application/vnd.businessobjects',
-            'xrgb' => 'image/x-rgb',
-            'xrif' => 'application/reginfo+xml',
-
-            'xrl' => 'application/resource-lists+xml',
-            'xrlc' => 'image/vnd.fujixerox.edmics-rlc',
-            'xrm' => 'application/vnd.rn-realmedia',
-            'xrmi' => 'audio/midi',
-            'xrmp' => 'audio/x-pn-realaudio-plugin',
-            'xrms' => 'application/vnd.jcp.javame.midlet-rms',
-            'xrnc' => 'application/relax-ng-compact-syntax',
-            'xrpss' => 'application/vnd.nokia.radio-presets',
-            'xrpst' => 'application/vnd.nokia.radio-preset',
-
-            'xrq' => 'application/sparql-query',
-            'xrs' => 'application/rls-services+xml',
-            'xrsd' => 'application/rsd+xml',
-            'xrss' => 'application/rss+xml',
-            'xrtf' => 'application/rtf',
-            'xrtx' => 'text/richtext',
-            'xsaf' => 'application/vnd.yamaha.smaf-audio',
-            'xsbml' => 'application/sbml+xml',
-            'xsc' => 'application/vnd.ibm.secure-container',
-
-            'xscd' => 'application/x-msschedule',
-            'xscm' => 'application/vnd.lotus-screencam',
-            'xscq' => 'application/scvp-cv-request',
-            'xscs' => 'application/scvp-cv-response',
-            'xsdp' => 'application/sdp',
-            'xsee' => 'application/vnd.seemail',
-            'xsema' => 'application/vnd.sema',
-            'xsemd' => 'application/vnd.semd',
-            'xsemf' => 'application/vnd.semf',
-
-            'xsetpay' => 'application/set-payment-initiation',
-            'xsetreg' => 'application/set-registration-initiation',
-            'xsfs' => 'application/vnd.spotfire.sfs',
-            'xsgm' => 'text/sgml',
-            'xsgml' => 'text/sgml',
-            'xsh' => 'application/x-sh',
-            'xshar' => 'application/x-shar',
-            'xshf' => 'application/shf+xml',
-            'xsilo' => 'model/mesh',
-
-            'xsit' => 'application/x-stuffit',
-            'xsitx' => 'application/x-stuffitx',
-            'xslt' => 'application/vnd.epson.salt',
-            'xsnd' => 'audio/basic',
-            'xspf' => 'application/vnd.yamaha.smaf-phrase',
-            'xspl' => 'application/x-futuresplash',
-            'xspot' => 'text/vnd.in3d.spot',
-            'xspp' => 'application/scvp-vp-response',
-            'xspq' => 'application/scvp-vp-request',
-
-            'xsrc' => 'application/x-wais-source',
-            'xsrx' => 'application/sparql-results+xml',
-            'xssf' => 'application/vnd.epson.ssf',
-            'xssml' => 'application/ssml+xml',
-            'xstf' => 'application/vnd.wt.stf',
-            'xstk' => 'application/hyperstudio',
-            'xstr' => 'application/vnd.pg.format',
-            'xsus' => 'application/vnd.sus-calendar',
-            'xsusp' => 'application/vnd.sus-calendar',
-
-            'xsv4cpio' => 'application/x-sv4cpio',
-            'xsv4crc' => 'application/x-sv4crc',
-            'xsvd' => 'application/vnd.svd',
-            'xswf' => 'application/x-shockwave-flash',
-            'xtao' => 'application/vnd.tao.intent-module-archive',
-            'xtar' => 'application/x-tar',
-            'xtcap' => 'application/vnd.3gpp2.tcap',
-            'xtcl' => 'application/x-tcl',
-            'xtex' => 'application/x-tex',
-
-            'xtext' => 'text/plain',
-            'xtif' => 'image/tiff',
-            'xtiff' => 'image/tiff',
-            'xtmo' => 'application/vnd.tmobile-livetv',
-            'xtorrent' => 'application/x-bittorrent',
-            'xtpl' => 'application/vnd.groove-tool-template',
-            'xtpt' => 'application/vnd.trid.tpt',
-            'xtra' => 'application/vnd.trueapp',
-            'xtrm' => 'application/x-msterminal',
-
-            'xtsv' => 'text/tab-separated-values',
-            'xtxd' => 'application/vnd.genomatix.tuxedo',
-            'xtxf' => 'application/vnd.mobius.txf',
-            'xtxt' => 'text/plain',
-            'xumj' => 'application/vnd.umajin',
-            'xunityweb' => 'application/vnd.unity',
-            'xuoml' => 'application/vnd.uoml+xml',
-            'xuri' => 'text/uri-list',
-            'xuris' => 'text/uri-list',
-
-            'xurls' => 'text/uri-list',
-            'xustar' => 'application/x-ustar',
-            'xutz' => 'application/vnd.uiq.theme',
-            'xuu' => 'text/x-uuencode',
-            'xvcd' => 'application/x-cdlink',
-            'xvcf' => 'text/x-vcard',
-            'xvcg' => 'application/vnd.groove-vcard',
-            'xvcs' => 'text/x-vcalendar',
-            'xvcx' => 'application/vnd.vcx',
-
-            'xvis' => 'application/vnd.visionary',
-            'xviv' => 'video/vnd.vivo',
-            'xvrml' => 'model/vrml',
-            'xvsd' => 'application/vnd.visio',
-            'xvsf' => 'application/vnd.vsf',
-            'xvss' => 'application/vnd.visio',
-            'xvst' => 'application/vnd.visio',
-            'xvsw' => 'application/vnd.visio',
-            'xvtu' => 'model/vnd.vtu',
-
-            'xvxml' => 'application/voicexml+xml',
-            'xwav' => 'audio/x-wav',
-            'xwax' => 'audio/x-ms-wax',
-            'xwbmp' => 'image/vnd.wap.wbmp',
-            'xwbs' => 'application/vnd.criticaltools.wbs+xml',
-            'xwbxml' => 'application/vnd.wap.wbxml',
-            'xwcm' => 'application/vnd.ms-works',
-            'xwdb' => 'application/vnd.ms-works',
-            'xwks' => 'application/vnd.ms-works',
-
-            'xwm' => 'video/x-ms-wm',
-            'xwma' => 'audio/x-ms-wma',
-            'xwmd' => 'application/x-ms-wmd',
-            'xwmf' => 'application/x-msmetafile',
-            'xwml' => 'text/vnd.wap.wml',
-            'xwmlc' => 'application/vnd.wap.wmlc',
-            'xwmls' => 'text/vnd.wap.wmlscript',
-            'xwmlsc' => 'application/vnd.wap.wmlscriptc',
-            'xwmv' => 'video/x-ms-wmv',
-
-            'xwmx' => 'video/x-ms-wmx',
-            'xwmz' => 'application/x-ms-wmz',
-            'xwpd' => 'application/vnd.wordperfect',
-            'xwpl' => 'application/vnd.ms-wpl',
-            'xwps' => 'application/vnd.ms-works',
-            'xwqd' => 'application/vnd.wqd',
-            'xwri' => 'application/x-mswrite',
-            'xwrl' => 'model/vrml',
-            'xwsdl' => 'application/wsdl+xml',
-
-            'xwspolicy' => 'application/wspolicy+xml',
-            'xwtb' => 'application/vnd.webturbo',
-            'xwvx' => 'video/x-ms-wvx',
-            'xx3d' => 'application/vnd.hzn-3d-crossword',
-            'xxar' => 'application/vnd.xara',
-            'xxbd' => 'application/vnd.fujixerox.docuworks.binder',
-            'xxbm' => 'image/x-xbitmap',
-            'xxdm' => 'application/vnd.syncml.dm+xml',
-            'xxdp' => 'application/vnd.adobe.xdp+xml',
-
-            'xxdw' => 'application/vnd.fujixerox.docuworks',
-            'xxenc' => 'application/xenc+xml',
-            'xxfdf' => 'application/vnd.adobe.xfdf',
-            'xxfdl' => 'application/vnd.xfdl',
-            'xxht' => 'application/xhtml+xml',
-            'xxhtml' => 'application/xhtml+xml',
-            'xxhvml' => 'application/xv+xml',
-            'xxif' => 'image/vnd.xiff',
-            'xxla' => 'application/vnd.ms-excel',
-
-            'xxlc' => 'application/vnd.ms-excel',
-            'xxlm' => 'application/vnd.ms-excel',
-            'xxls' => 'application/vnd.ms-excel',
-            'xxlt' => 'application/vnd.ms-excel',
-            'xxlw' => 'application/vnd.ms-excel',
-            'xxml' => 'application/xml',
-            'xxo' => 'application/vnd.olpc-sugar',
-            'xxop' => 'application/xop+xml',
-            'xxpm' => 'image/x-xpixmap',
-
-            'xxpr' => 'application/vnd.is-xpr',
-            'xxps' => 'application/vnd.ms-xpsdocument',
-            'xxsl' => 'application/xml',
-            'xxslt' => 'application/xslt+xml',
-            'xxsm' => 'application/vnd.syncml+xml',
-            'xxspf' => 'application/xspf+xml',
-            'xxul' => 'application/vnd.mozilla.xul+xml',
-            'xxvm' => 'application/xv+xml',
-            'xxvml' => 'application/xv+xml',
-
-            'xxwd' => 'image/x-xwindowdump',
-            'xxyz' => 'chemical/x-xyz',
-            'xzaz' => 'application/vnd.zzazz.deck+xml',
-            'xzip' => 'application/zip',
-            'xzmm' => 'application/vnd.handheld-entertainment+xml',
-            'xodt' => 'application/x-vnd.oasis.opendocument.spreadsheet'
-        );
 }
diff --git app/code/core/Mage/Oauth/Model/Server.php app/code/core/Mage/Oauth/Model/Server.php
index 3bb92a1..6456ff9 100644
--- app/code/core/Mage/Oauth/Model/Server.php
+++ app/code/core/Mage/Oauth/Model/Server.php
@@ -328,10 +328,10 @@ class Mage_Oauth_Model_Server
             if (self::REQUEST_TOKEN == $this->_requestType) {
                 $this->_validateVerifierParam();
 
-                if ($this->_token->getVerifier() != $this->_protocolParams['oauth_verifier']) {
+                if (!hash_equals($this->_token->getVerifier(), $this->_protocolParams['oauth_verifier'])) {
                     $this->_throwException('', self::ERR_VERIFIER_INVALID);
                 }
-                if ($this->_token->getConsumerId() != $this->_consumer->getId()) {
+                if (!hash_equals($this->_token->getConsumerId(), $this->_consumer->getId())) {
                     $this->_throwException('', self::ERR_TOKEN_REJECTED);
                 }
                 if (Mage_Oauth_Model_Token::TYPE_REQUEST != $this->_token->getType()) {
@@ -544,7 +544,7 @@ class Mage_Oauth_Model_Server
             $this->_request->getScheme() . '://' . $this->_request->getHttpHost() . $this->_request->getRequestUri()
         );
 
-        if ($calculatedSign != $this->_protocolParams['oauth_signature']) {
+        if (!hash_equals($calculatedSign, $this->_protocolParams['oauth_signature'])) {
             $this->_throwException('', self::ERR_SIGNATURE_INVALID);
         }
     }
diff --git app/code/core/Mage/Paygate/Model/Authorizenet.php app/code/core/Mage/Paygate/Model/Authorizenet.php
index 94bc44d..70d1b0b 100644
--- app/code/core/Mage/Paygate/Model/Authorizenet.php
+++ app/code/core/Mage/Paygate/Model/Authorizenet.php
@@ -1273,8 +1273,10 @@ class Mage_Paygate_Model_Authorizenet extends Mage_Payment_Model_Method_Cc
         $uri = $this->getConfigData('cgi_url');
         $client->setUri($uri ? $uri : self::CGI_URL);
         $client->setConfig(array(
-            'maxredirects'=>0,
-            'timeout'=>30,
+            'maxredirects' => 0,
+            'timeout' => 30,
+            'verifyhost' => 2,
+            'verifypeer' => true,
             //'ssltransport' => 'tcp',
         ));
         foreach ($request->getData() as $key => $value) {
@@ -1543,7 +1545,11 @@ class Mage_Paygate_Model_Authorizenet extends Mage_Payment_Model_Method_Cc
         $uri = $this->getConfigData('cgi_url_td');
         $uri = $uri ? $uri : self::CGI_URL_TD;
         $client->setUri($uri);
-        $client->setConfig(array('timeout'=>45));
+        $client->setConfig(array(
+            'timeout' => 45,
+            'verifyhost' => 2,
+            'verifypeer' => true,
+        ));
         $client->setHeaders(array('Content-Type: text/xml'));
         $client->setMethod(Zend_Http_Client::POST);
         $client->setRawData($requestBody);
diff --git app/code/core/Mage/Payment/Block/Info/Checkmo.php app/code/core/Mage/Payment/Block/Info/Checkmo.php
index cc2b365..cd78572 100644
--- app/code/core/Mage/Payment/Block/Info/Checkmo.php
+++ app/code/core/Mage/Payment/Block/Info/Checkmo.php
@@ -70,7 +70,13 @@ class Mage_Payment_Block_Info_Checkmo extends Mage_Payment_Block_Info
      */
     protected function _convertAdditionalData()
     {
-        $details = @unserialize($this->getInfo()->getAdditionalData());
+        $details = false;
+        try {
+            $details = Mage::helper('core/unserializeArray')
+                ->unserialize($this->getInfo()->getAdditionalData());
+        } catch (Exception $e) {
+            Mage::logException($e);
+        }
         if (is_array($details)) {
             $this->_payableTo = isset($details['payable_to']) ? (string) $details['payable_to'] : '';
             $this->_mailingAddress = isset($details['mailing_address']) ? (string) $details['mailing_address'] : '';
@@ -80,7 +86,7 @@ class Mage_Payment_Block_Info_Checkmo extends Mage_Payment_Block_Info
         }
         return $this;
     }
-    
+
     public function toPdf()
     {
         $this->setTemplate('payment/info/pdf/checkmo.phtml');
diff --git app/code/core/Mage/Paypal/Model/Express/Checkout.php app/code/core/Mage/Paypal/Model/Express/Checkout.php
index 7855dc4..258613d 100644
--- app/code/core/Mage/Paypal/Model/Express/Checkout.php
+++ app/code/core/Mage/Paypal/Model/Express/Checkout.php
@@ -945,7 +945,7 @@ class Mage_Paypal_Model_Express_Checkout
         $shipping   = $quote->isVirtual() ? null : $quote->getShippingAddress();
 
         $customerId = $this->_lookupCustomerId();
-        if ($customerId) {
+        if ($customerId && !$this->_customerEmailExists($quote->getCustomerEmail())) {
             $this->getCustomerSession()->loginById($customerId);
             return $this->_prepareCustomerQuote();
         }
@@ -1061,4 +1061,26 @@ class Mage_Paypal_Model_Express_Checkout
     {
         return $this->_customerSession;
     }
+
+    /**
+     * Check if customer email exists
+     *
+     * @param string $email
+     * @return bool
+     */
+    protected function _customerEmailExists($email)
+    {
+        $result    = false;
+        $customer  = Mage::getModel('customer/customer');
+        $websiteId = Mage::app()->getStore()->getWebsiteId();
+        if (!is_null($websiteId)) {
+            $customer->setWebsiteId($websiteId);
+        }
+        $customer->loadByEmail($email);
+        if (!is_null($customer->getId())) {
+            $result = true;
+        }
+
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
index 63d7b88..08d3dcf 100644
--- app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
+++ app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
@@ -53,6 +53,30 @@ class Mage_Paypal_Model_Resource_Payment_Transaction extends Mage_Core_Model_Res
     }
 
     /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                    ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
+
+    /**
      * Load the transaction object by specified txn_id
      *
      * @param Mage_Paypal_Model_Payment_Transaction $transaction
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Payment.php app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
index 83eb0f0..e0b68cd 100644
--- app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
+++ app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
@@ -58,4 +58,28 @@ class Mage_Sales_Model_Resource_Order_Payment extends Mage_Sales_Model_Resource_
     {
         $this->_init('sales/order_payment', 'entity_id');
     }
+
+    /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
 }
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php
index fa68eb2..7db98f2 100644
--- app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php
+++ app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php
@@ -53,6 +53,30 @@ class Mage_Sales_Model_Resource_Order_Payment_Transaction extends Mage_Sales_Mod
     }
 
     /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
+
+    /**
      * Update transactions in database using provided transaction as parent for them
      * have to repeat the business logic to avoid accidental injection of wrong transactions
      *
diff --git app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php
index 01011ce..a3ae8a0 100644
--- app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php
+++ app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php
@@ -51,4 +51,28 @@ class Mage_Sales_Model_Resource_Quote_Payment extends Mage_Sales_Model_Resource_
     {
         $this->_init('sales/quote_payment', 'payment_id');
     }
+
+    /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                    ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
 }
diff --git app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php
index 78a806e..b4c5c1f 100644
--- app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php
+++ app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php
@@ -54,6 +54,33 @@ class Mage_Sales_Model_Resource_Recurring_Profile extends Mage_Sales_Model_Resou
     }
 
     /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        if ($field != 'additional_info') {
+            return parent::_unserializeField($object, $field, $defaultValue);
+        }
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
+
+    /**
      * Return recurring profile child Orders Ids
      *
      *
diff --git app/code/core/Mage/Uploader/Block/Abstract.php app/code/core/Mage/Uploader/Block/Abstract.php
new file mode 100644
index 0000000..a11c23a
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Abstract.php
@@ -0,0 +1,247 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+abstract class Mage_Uploader_Block_Abstract extends Mage_Adminhtml_Block_Widget
+{
+    /**
+     * Template used for uploader
+     *
+     * @var string
+     */
+    protected $_template = 'media/uploader.phtml';
+
+    /**
+     * @var Mage_Uploader_Model_Config_Misc
+     */
+    protected $_misc;
+
+    /**
+     * @var Mage_Uploader_Model_Config_Uploader
+     */
+    protected $_uploaderConfig;
+
+    /**
+     * @var Mage_Uploader_Model_Config_Browsebutton
+     */
+    protected $_browseButtonConfig;
+
+    /**
+     * @var Mage_Uploader_Model_Config_Misc
+     */
+    protected $_miscConfig;
+
+    /**
+     * @var array
+     */
+    protected $_idsMapping = array();
+
+    /**
+     * Default browse button ID suffix
+     */
+    const DEFAULT_BROWSE_BUTTON_ID_SUFFIX = 'browse';
+
+    /**
+     * Constructor for uploader block
+     *
+     * @see https://github.com/flowjs/flow.js/tree/v2.9.0#configuration
+     * @description Set unique id for block
+     */
+    public function __construct()
+    {
+        parent::__construct();
+        $this->setId($this->getId() . '_Uploader');
+    }
+
+    /**
+     * Helper for file manipulation
+     *
+     * @return Mage_Uploader_Helper_File
+     */
+    protected function _getHelper()
+    {
+        return Mage::helper('uploader/file');
+    }
+
+    /**
+     * @return string
+     */
+    public function getJsonConfig()
+    {
+        return $this->helper('core')->jsonEncode(array(
+            'uploaderConfig'    => $this->getUploaderConfig()->getData(),
+            'elementIds'        => $this->_getElementIdsMapping(),
+            'browseConfig'      => $this->getButtonConfig()->getData(),
+            'miscConfig'        => $this->getMiscConfig()->getData(),
+        ));
+    }
+
+    /**
+     * Get mapping of ids for front-end use
+     *
+     * @return array
+     */
+    protected function _getElementIdsMapping()
+    {
+        return $this->_idsMapping;
+    }
+
+    /**
+     * Add mapping ids for front-end use
+     *
+     * @param array $additionalButtons
+     * @return $this
+     */
+    protected function _addElementIdsMapping($additionalButtons = array())
+    {
+        $this->_idsMapping = array_merge($this->_idsMapping, $additionalButtons);
+
+        return $this;
+    }
+
+    /**
+     * Prepare layout, create buttons, set front-end elements ids
+     *
+     * @return Mage_Core_Block_Abstract
+     */
+    protected function _prepareLayout()
+    {
+        $this->setChild(
+            'browse_button',
+            $this->getLayout()->createBlock('adminhtml/widget_button')
+                ->addData(array(
+                    // Workaround for IE9
+                    'before_html'   => sprintf(
+                        '<div style="display:inline-block;" id="%s">',
+                        $this->getElementId(self::DEFAULT_BROWSE_BUTTON_ID_SUFFIX)
+                    ),
+                    'after_html'    => '</div>',
+                    'id'            => $this->getElementId(self::DEFAULT_BROWSE_BUTTON_ID_SUFFIX . '_button'),
+                    'label'         => Mage::helper('uploader')->__('Browse Files...'),
+                    'type'          => 'button',
+                ))
+        );
+
+        $this->setChild(
+            'delete_button',
+            $this->getLayout()->createBlock('adminhtml/widget_button')
+                ->addData(array(
+                    'id'      => '{{id}}',
+                    'class'   => 'delete',
+                    'type'    => 'button',
+                    'label'   => Mage::helper('uploader')->__('Remove')
+                ))
+        );
+
+        $this->_addElementIdsMapping(array(
+            'container'         => $this->getHtmlId(),
+            'templateFile'      => $this->getElementId('template'),
+            'browse'            => $this->_prepareElementsIds(array(self::DEFAULT_BROWSE_BUTTON_ID_SUFFIX))
+        ));
+
+        return parent::_prepareLayout();
+    }
+
+    /**
+     * Get browse button html
+     *
+     * @return string
+     */
+    public function getBrowseButtonHtml()
+    {
+        return $this->getChildHtml('browse_button');
+    }
+
+    /**
+     * Get delete button html
+     *
+     * @return string
+     */
+    public function getDeleteButtonHtml()
+    {
+        return $this->getChildHtml('delete_button');
+    }
+
+    /**
+     * Get uploader misc settings
+     *
+     * @return Mage_Uploader_Model_Config_Misc
+     */
+    public function getMiscConfig()
+    {
+        if (is_null($this->_miscConfig)) {
+            $this->_miscConfig = Mage::getModel('uploader/config_misc');
+        }
+        return $this->_miscConfig;
+    }
+
+    /**
+     * Get uploader general settings
+     *
+     * @return Mage_Uploader_Model_Config_Uploader
+     */
+    public function getUploaderConfig()
+    {
+        if (is_null($this->_uploaderConfig)) {
+            $this->_uploaderConfig = Mage::getModel('uploader/config_uploader');
+        }
+        return $this->_uploaderConfig;
+    }
+
+    /**
+     * Get browse button settings
+     *
+     * @return Mage_Uploader_Model_Config_Browsebutton
+     */
+    public function getButtonConfig()
+    {
+        if (is_null($this->_browseButtonConfig)) {
+            $this->_browseButtonConfig = Mage::getModel('uploader/config_browsebutton');
+        }
+        return $this->_browseButtonConfig;
+    }
+
+    /**
+     * Get button unique id
+     *
+     * @param string $suffix
+     * @return string
+     */
+    public function getElementId($suffix)
+    {
+        return $this->getHtmlId() . '-' . $suffix;
+    }
+
+    /**
+     * Prepare actual elements ids from suffixes
+     *
+     * @param array $targets $type => array($idsSuffixes)
+     * @return array $type => array($htmlIds)
+     */
+    protected function _prepareElementsIds($targets)
+    {
+        return array_map(array($this, 'getElementId'), array_unique(array_values($targets)));
+    }
+}
diff --git app/code/core/Mage/Uploader/Block/Multiple.php app/code/core/Mage/Uploader/Block/Multiple.php
new file mode 100644
index 0000000..abf47df
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Multiple.php
@@ -0,0 +1,71 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+class Mage_Uploader_Block_Multiple extends Mage_Uploader_Block_Abstract
+{
+    /**
+     *
+     * Default upload button ID suffix
+     */
+    const DEFAULT_UPLOAD_BUTTON_ID_SUFFIX = 'upload';
+
+
+    /**
+     * Prepare layout, create upload button
+     *
+     * @return Mage_Uploader_Block_Multiple
+     */
+    protected function _prepareLayout()
+    {
+        parent::_prepareLayout();
+
+        $this->setChild(
+            'upload_button',
+            $this->getLayout()->createBlock('adminhtml/widget_button')
+                ->addData(array(
+                    'id'      => $this->getElementId(self::DEFAULT_UPLOAD_BUTTON_ID_SUFFIX),
+                    'label'   => Mage::helper('uploader')->__('Upload Files'),
+                    'type'    => 'button',
+                ))
+        );
+
+        $this->_addElementIdsMapping(array(
+            'upload' => $this->_prepareElementsIds(array(self::DEFAULT_UPLOAD_BUTTON_ID_SUFFIX))
+        ));
+
+        return $this;
+    }
+
+    /**
+     * Get upload button html
+     *
+     * @return string
+     */
+    public function getUploadButtonHtml()
+    {
+        return $this->getChildHtml('upload_button');
+    }
+}
diff --git app/code/core/Mage/Uploader/Block/Single.php app/code/core/Mage/Uploader/Block/Single.php
new file mode 100644
index 0000000..ed298a0
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Single.php
@@ -0,0 +1,52 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+class Mage_Uploader_Block_Single extends Mage_Uploader_Block_Abstract
+{
+    /**
+     * Prepare layout, change button and set front-end element ids mapping
+     *
+     * @return Mage_Core_Block_Abstract
+     */
+    protected function _prepareLayout()
+    {
+        parent::_prepareLayout();
+        $this->getChild('browse_button')->setLabel(Mage::helper('uploader')->__('...'));
+
+        return $this;
+    }
+
+    /**
+     * Constructor for single uploader block
+     */
+    public function __construct()
+    {
+        parent::__construct();
+
+        $this->getUploaderConfig()->setSingleFile(true);
+        $this->getButtonConfig()->setSingleFile(true);
+    }
+}
diff --git app/code/core/Mage/Uploader/Helper/Data.php app/code/core/Mage/Uploader/Helper/Data.php
new file mode 100644
index 0000000..2650976
--- /dev/null
+++ app/code/core/Mage/Uploader/Helper/Data.php
@@ -0,0 +1,30 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+class Mage_Uploader_Helper_Data extends Mage_Core_Helper_Abstract
+{
+
+}
diff --git app/code/core/Mage/Uploader/Helper/File.php app/code/core/Mage/Uploader/Helper/File.php
new file mode 100644
index 0000000..b0f17cb
--- /dev/null
+++ app/code/core/Mage/Uploader/Helper/File.php
@@ -0,0 +1,750 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+class Mage_Uploader_Helper_File extends Mage_Core_Helper_Abstract
+{
+    /**
+     * List of pre-defined MIME types
+     *
+     * @var array
+     */
+    protected $_mimeTypes =
+        array(
+            'x123' => 'application/vnd.lotus-1-2-3',
+            'x3dml' => 'text/vnd.in3d.3dml',
+            'x3g2' => 'video/3gpp2',
+            'x3gp' => 'video/3gpp',
+            'xace' => 'application/x-ace-compressed',
+            'xacu' => 'application/vnd.acucobol',
+            'xaep' => 'application/vnd.audiograph',
+            'xai' => 'application/postscript',
+            'xaif' => 'audio/x-aiff',
+
+            'xaifc' => 'audio/x-aiff',
+            'xaiff' => 'audio/x-aiff',
+            'xami' => 'application/vnd.amiga.ami',
+            'xapr' => 'application/vnd.lotus-approach',
+            'xasf' => 'video/x-ms-asf',
+            'xaso' => 'application/vnd.accpac.simply.aso',
+            'xasx' => 'video/x-ms-asf',
+            'xatom' => 'application/atom+xml',
+            'xatomcat' => 'application/atomcat+xml',
+
+            'xatomsvc' => 'application/atomsvc+xml',
+            'xatx' => 'application/vnd.antix.game-component',
+            'xau' => 'audio/basic',
+            'xavi' => 'video/x-msvideo',
+            'xbat' => 'application/x-msdownload',
+            'xbcpio' => 'application/x-bcpio',
+            'xbdm' => 'application/vnd.syncml.dm+wbxml',
+            'xbh2' => 'application/vnd.fujitsu.oasysprs',
+            'xbmi' => 'application/vnd.bmi',
+
+            'xbmp' => 'image/bmp',
+            'xbox' => 'application/vnd.previewsystems.box',
+            'xboz' => 'application/x-bzip2',
+            'xbtif' => 'image/prs.btif',
+            'xbz' => 'application/x-bzip',
+            'xbz2' => 'application/x-bzip2',
+            'xcab' => 'application/vnd.ms-cab-compressed',
+            'xccxml' => 'application/ccxml+xml',
+            'xcdbcmsg' => 'application/vnd.contact.cmsg',
+
+            'xcdkey' => 'application/vnd.mediastation.cdkey',
+            'xcdx' => 'chemical/x-cdx',
+            'xcdxml' => 'application/vnd.chemdraw+xml',
+            'xcdy' => 'application/vnd.cinderella',
+            'xcer' => 'application/pkix-cert',
+            'xcgm' => 'image/cgm',
+            'xchat' => 'application/x-chat',
+            'xchm' => 'application/vnd.ms-htmlhelp',
+            'xchrt' => 'application/vnd.kde.kchart',
+
+            'xcif' => 'chemical/x-cif',
+            'xcii' => 'application/vnd.anser-web-certificate-issue-initiation',
+            'xcil' => 'application/vnd.ms-artgalry',
+            'xcla' => 'application/vnd.claymore',
+            'xclkk' => 'application/vnd.crick.clicker.keyboard',
+            'xclkp' => 'application/vnd.crick.clicker.palette',
+            'xclkt' => 'application/vnd.crick.clicker.template',
+            'xclkw' => 'application/vnd.crick.clicker.wordbank',
+            'xclkx' => 'application/vnd.crick.clicker',
+
+            'xclp' => 'application/x-msclip',
+            'xcmc' => 'application/vnd.cosmocaller',
+            'xcmdf' => 'chemical/x-cmdf',
+            'xcml' => 'chemical/x-cml',
+            'xcmp' => 'application/vnd.yellowriver-custom-menu',
+            'xcmx' => 'image/x-cmx',
+            'xcom' => 'application/x-msdownload',
+            'xconf' => 'text/plain',
+            'xcpio' => 'application/x-cpio',
+
+            'xcpt' => 'application/mac-compactpro',
+            'xcrd' => 'application/x-mscardfile',
+            'xcrl' => 'application/pkix-crl',
+            'xcrt' => 'application/x-x509-ca-cert',
+            'xcsh' => 'application/x-csh',
+            'xcsml' => 'chemical/x-csml',
+            'xcss' => 'text/css',
+            'xcsv' => 'text/csv',
+            'xcurl' => 'application/vnd.curl',
+
+            'xcww' => 'application/prs.cww',
+            'xdaf' => 'application/vnd.mobius.daf',
+            'xdavmount' => 'application/davmount+xml',
+            'xdd2' => 'application/vnd.oma.dd2+xml',
+            'xddd' => 'application/vnd.fujixerox.ddd',
+            'xdef' => 'text/plain',
+            'xder' => 'application/x-x509-ca-cert',
+            'xdfac' => 'application/vnd.dreamfactory',
+            'xdis' => 'application/vnd.mobius.dis',
+
+            'xdjv' => 'image/vnd.djvu',
+            'xdjvu' => 'image/vnd.djvu',
+            'xdll' => 'application/x-msdownload',
+            'xdna' => 'application/vnd.dna',
+            'xdoc' => 'application/msword',
+            'xdot' => 'application/msword',
+            'xdp' => 'application/vnd.osgi.dp',
+            'xdpg' => 'application/vnd.dpgraph',
+            'xdsc' => 'text/prs.lines.tag',
+
+            'xdtd' => 'application/xml-dtd',
+            'xdvi' => 'application/x-dvi',
+            'xdwf' => 'model/vnd.dwf',
+            'xdwg' => 'image/vnd.dwg',
+            'xdxf' => 'image/vnd.dxf',
+            'xdxp' => 'application/vnd.spotfire.dxp',
+            'xecelp4800' => 'audio/vnd.nuera.ecelp4800',
+            'xecelp7470' => 'audio/vnd.nuera.ecelp7470',
+            'xecelp9600' => 'audio/vnd.nuera.ecelp9600',
+
+            'xecma' => 'application/ecmascript',
+            'xedm' => 'application/vnd.novadigm.edm',
+            'xedx' => 'application/vnd.novadigm.edx',
+            'xefif' => 'application/vnd.picsel',
+            'xei6' => 'application/vnd.pg.osasli',
+            'xeml' => 'message/rfc822',
+            'xeol' => 'audio/vnd.digital-winds',
+            'xeot' => 'application/vnd.ms-fontobject',
+            'xeps' => 'application/postscript',
+
+            'xesf' => 'application/vnd.epson.esf',
+            'xetx' => 'text/x-setext',
+            'xexe' => 'application/x-msdownload',
+            'xext' => 'application/vnd.novadigm.ext',
+            'xez' => 'application/andrew-inset',
+            'xez2' => 'application/vnd.ezpix-album',
+            'xez3' => 'application/vnd.ezpix-package',
+            'xfbs' => 'image/vnd.fastbidsheet',
+            'xfdf' => 'application/vnd.fdf',
+
+            'xfe_launch' => 'application/vnd.denovo.fcselayout-link',
+            'xfg5' => 'application/vnd.fujitsu.oasysgp',
+            'xfli' => 'video/x-fli',
+            'xflo' => 'application/vnd.micrografx.flo',
+            'xflw' => 'application/vnd.kde.kivio',
+            'xflx' => 'text/vnd.fmi.flexstor',
+            'xfly' => 'text/vnd.fly',
+            'xfnc' => 'application/vnd.frogans.fnc',
+            'xfpx' => 'image/vnd.fpx',
+
+            'xfsc' => 'application/vnd.fsc.weblaunch',
+            'xfst' => 'image/vnd.fst',
+            'xftc' => 'application/vnd.fluxtime.clip',
+            'xfti' => 'application/vnd.anser-web-funds-transfer-initiation',
+            'xfvt' => 'video/vnd.fvt',
+            'xfzs' => 'application/vnd.fuzzysheet',
+            'xg3' => 'image/g3fax',
+            'xgac' => 'application/vnd.groove-account',
+            'xgdl' => 'model/vnd.gdl',
+
+            'xghf' => 'application/vnd.groove-help',
+            'xgif' => 'image/gif',
+            'xgim' => 'application/vnd.groove-identity-message',
+            'xgph' => 'application/vnd.flographit',
+            'xgram' => 'application/srgs',
+            'xgrv' => 'application/vnd.groove-injector',
+            'xgrxml' => 'application/srgs+xml',
+            'xgtar' => 'application/x-gtar',
+            'xgtm' => 'application/vnd.groove-tool-message',
+
+            'xsvg' => 'image/svg+xml',
+
+            'xgtw' => 'model/vnd.gtw',
+            'xh261' => 'video/h261',
+            'xh263' => 'video/h263',
+            'xh264' => 'video/h264',
+            'xhbci' => 'application/vnd.hbci',
+            'xhdf' => 'application/x-hdf',
+            'xhlp' => 'application/winhlp',
+            'xhpgl' => 'application/vnd.hp-hpgl',
+            'xhpid' => 'application/vnd.hp-hpid',
+
+            'xhps' => 'application/vnd.hp-hps',
+            'xhqx' => 'application/mac-binhex40',
+            'xhtke' => 'application/vnd.kenameaapp',
+            'xhtm' => 'text/html',
+            'xhtml' => 'text/html',
+            'xhvd' => 'application/vnd.yamaha.hv-dic',
+            'xhvp' => 'application/vnd.yamaha.hv-voice',
+            'xhvs' => 'application/vnd.yamaha.hv-script',
+            'xice' => '#x-conference/x-cooltalk',
+
+            'xico' => 'image/x-icon',
+            'xics' => 'text/calendar',
+            'xief' => 'image/ief',
+            'xifb' => 'text/calendar',
+            'xifm' => 'application/vnd.shana.informed.formdata',
+            'xigl' => 'application/vnd.igloader',
+            'xigx' => 'application/vnd.micrografx.igx',
+            'xiif' => 'application/vnd.shana.informed.interchange',
+            'ximp' => 'application/vnd.accpac.simply.imp',
+
+            'xims' => 'application/vnd.ms-ims',
+            'xin' => 'text/plain',
+            'xipk' => 'application/vnd.shana.informed.package',
+            'xirm' => 'application/vnd.ibm.rights-management',
+            'xirp' => 'application/vnd.irepository.package+xml',
+            'xitp' => 'application/vnd.shana.informed.formtemplate',
+            'xivp' => 'application/vnd.immervision-ivp',
+            'xivu' => 'application/vnd.immervision-ivu',
+            'xjad' => 'text/vnd.sun.j2me.app-descriptor',
+
+            'xjam' => 'application/vnd.jam',
+            'xjava' => 'text/x-java-source',
+            'xjisp' => 'application/vnd.jisp',
+            'xjlt' => 'application/vnd.hp-jlyt',
+            'xjoda' => 'application/vnd.joost.joda-archive',
+            'xjpe' => 'image/jpeg',
+            'xjpeg' => 'image/jpeg',
+            'xjpg' => 'image/jpeg',
+            'xjpgm' => 'video/jpm',
+
+            'xjpgv' => 'video/jpeg',
+            'xjpm' => 'video/jpm',
+            'xjs' => 'application/javascript',
+            'xjson' => 'application/json',
+            'xkar' => 'audio/midi',
+            'xkarbon' => 'application/vnd.kde.karbon',
+            'xkfo' => 'application/vnd.kde.kformula',
+            'xkia' => 'application/vnd.kidspiration',
+            'xkml' => 'application/vnd.google-earth.kml+xml',
+
+            'xkmz' => 'application/vnd.google-earth.kmz',
+            'xkon' => 'application/vnd.kde.kontour',
+            'xksp' => 'application/vnd.kde.kspread',
+            'xlatex' => 'application/x-latex',
+            'xlbd' => 'application/vnd.llamagraphics.life-balance.desktop',
+            'xlbe' => 'application/vnd.llamagraphics.life-balance.exchange+xml',
+            'xles' => 'application/vnd.hhe.lesson-player',
+            'xlist' => 'text/plain',
+            'xlog' => 'text/plain',
+
+            'xlrm' => 'application/vnd.ms-lrm',
+            'xltf' => 'application/vnd.frogans.ltf',
+            'xlvp' => 'audio/vnd.lucent.voice',
+            'xlwp' => 'application/vnd.lotus-wordpro',
+            'xm13' => 'application/x-msmediaview',
+            'xm14' => 'application/x-msmediaview',
+            'xm1v' => 'video/mpeg',
+            'xm2a' => 'audio/mpeg',
+            'xm3a' => 'audio/mpeg',
+
+            'xm3u' => 'audio/x-mpegurl',
+            'xm4u' => 'video/vnd.mpegurl',
+            'xmag' => 'application/vnd.ecowin.chart',
+            'xmathml' => 'application/mathml+xml',
+            'xmbk' => 'application/vnd.mobius.mbk',
+            'xmbox' => 'application/mbox',
+            'xmc1' => 'application/vnd.medcalcdata',
+            'xmcd' => 'application/vnd.mcd',
+            'xmdb' => 'application/x-msaccess',
+
+            'xmdi' => 'image/vnd.ms-modi',
+            'xmesh' => 'model/mesh',
+            'xmfm' => 'application/vnd.mfmp',
+            'xmgz' => 'application/vnd.proteus.magazine',
+            'xmid' => 'audio/midi',
+            'xmidi' => 'audio/midi',
+            'xmif' => 'application/vnd.mif',
+            'xmime' => 'message/rfc822',
+            'xmj2' => 'video/mj2',
+
+            'xmjp2' => 'video/mj2',
+            'xmlp' => 'application/vnd.dolby.mlp',
+            'xmmd' => 'application/vnd.chipnuts.karaoke-mmd',
+            'xmmf' => 'application/vnd.smaf',
+            'xmmr' => 'image/vnd.fujixerox.edmics-mmr',
+            'xmny' => 'application/x-msmoney',
+            'xmov' => 'video/quicktime',
+            'xmovie' => 'video/x-sgi-movie',
+            'xmp2' => 'audio/mpeg',
+
+            'xmp2a' => 'audio/mpeg',
+            'xmp3' => 'audio/mpeg',
+            'xmp4' => 'video/mp4',
+            'xmp4a' => 'audio/mp4',
+            'xmp4s' => 'application/mp4',
+            'xmp4v' => 'video/mp4',
+            'xmpc' => 'application/vnd.mophun.certificate',
+            'xmpe' => 'video/mpeg',
+            'xmpeg' => 'video/mpeg',
+
+            'xmpg' => 'video/mpeg',
+            'xmpg4' => 'video/mp4',
+            'xmpga' => 'audio/mpeg',
+            'xmpkg' => 'application/vnd.apple.installer+xml',
+            'xmpm' => 'application/vnd.blueice.multipass',
+            'xmpn' => 'application/vnd.mophun.application',
+            'xmpp' => 'application/vnd.ms-project',
+            'xmpt' => 'application/vnd.ms-project',
+            'xmpy' => 'application/vnd.ibm.minipay',
+
+            'xmqy' => 'application/vnd.mobius.mqy',
+            'xmrc' => 'application/marc',
+            'xmscml' => 'application/mediaservercontrol+xml',
+            'xmseq' => 'application/vnd.mseq',
+            'xmsf' => 'application/vnd.epson.msf',
+            'xmsh' => 'model/mesh',
+            'xmsi' => 'application/x-msdownload',
+            'xmsl' => 'application/vnd.mobius.msl',
+            'xmsty' => 'application/vnd.muvee.style',
+
+            'xmts' => 'model/vnd.mts',
+            'xmus' => 'application/vnd.musician',
+            'xmvb' => 'application/x-msmediaview',
+            'xmwf' => 'application/vnd.mfer',
+            'xmxf' => 'application/mxf',
+            'xmxl' => 'application/vnd.recordare.musicxml',
+            'xmxml' => 'application/xv+xml',
+            'xmxs' => 'application/vnd.triscape.mxs',
+            'xmxu' => 'video/vnd.mpegurl',
+
+            'xn-gage' => 'application/vnd.nokia.n-gage.symbian.install',
+            'xngdat' => 'application/vnd.nokia.n-gage.data',
+            'xnlu' => 'application/vnd.neurolanguage.nlu',
+            'xnml' => 'application/vnd.enliven',
+            'xnnd' => 'application/vnd.noblenet-directory',
+            'xnns' => 'application/vnd.noblenet-sealer',
+            'xnnw' => 'application/vnd.noblenet-web',
+            'xnpx' => 'image/vnd.net-fpx',
+            'xnsf' => 'application/vnd.lotus-notes',
+
+            'xoa2' => 'application/vnd.fujitsu.oasys2',
+            'xoa3' => 'application/vnd.fujitsu.oasys3',
+            'xoas' => 'application/vnd.fujitsu.oasys',
+            'xobd' => 'application/x-msbinder',
+            'xoda' => 'application/oda',
+            'xodc' => 'application/vnd.oasis.opendocument.chart',
+            'xodf' => 'application/vnd.oasis.opendocument.formula',
+            'xodg' => 'application/vnd.oasis.opendocument.graphics',
+            'xodi' => 'application/vnd.oasis.opendocument.image',
+
+            'xodp' => 'application/vnd.oasis.opendocument.presentation',
+            'xods' => 'application/vnd.oasis.opendocument.spreadsheet',
+            'xodt' => 'application/vnd.oasis.opendocument.text',
+            'xogg' => 'application/ogg',
+            'xoprc' => 'application/vnd.palm',
+            'xorg' => 'application/vnd.lotus-organizer',
+            'xotc' => 'application/vnd.oasis.opendocument.chart-template',
+            'xotf' => 'application/vnd.oasis.opendocument.formula-template',
+            'xotg' => 'application/vnd.oasis.opendocument.graphics-template',
+
+            'xoth' => 'application/vnd.oasis.opendocument.text-web',
+            'xoti' => 'application/vnd.oasis.opendocument.image-template',
+            'xotm' => 'application/vnd.oasis.opendocument.text-master',
+            'xots' => 'application/vnd.oasis.opendocument.spreadsheet-template',
+            'xott' => 'application/vnd.oasis.opendocument.text-template',
+            'xoxt' => 'application/vnd.openofficeorg.extension',
+            'xp10' => 'application/pkcs10',
+            'xp7r' => 'application/x-pkcs7-certreqresp',
+            'xp7s' => 'application/pkcs7-signature',
+
+            'xpbd' => 'application/vnd.powerbuilder6',
+            'xpbm' => 'image/x-portable-bitmap',
+            'xpcl' => 'application/vnd.hp-pcl',
+            'xpclxl' => 'application/vnd.hp-pclxl',
+            'xpct' => 'image/x-pict',
+            'xpcx' => 'image/x-pcx',
+            'xpdb' => 'chemical/x-pdb',
+            'xpdf' => 'application/pdf',
+            'xpfr' => 'application/font-tdpfr',
+
+            'xpgm' => 'image/x-portable-graymap',
+            'xpgn' => 'application/x-chess-pgn',
+            'xpgp' => 'application/pgp-encrypted',
+            'xpic' => 'image/x-pict',
+            'xpki' => 'application/pkixcmp',
+            'xpkipath' => 'application/pkix-pkipath',
+            'xplb' => 'application/vnd.3gpp.pic-bw-large',
+            'xplc' => 'application/vnd.mobius.plc',
+            'xplf' => 'application/vnd.pocketlearn',
+
+            'xpls' => 'application/pls+xml',
+            'xpml' => 'application/vnd.ctc-posml',
+            'xpng' => 'image/png',
+            'xpnm' => 'image/x-portable-anymap',
+            'xportpkg' => 'application/vnd.macports.portpkg',
+            'xpot' => 'application/vnd.ms-powerpoint',
+            'xppd' => 'application/vnd.cups-ppd',
+            'xppm' => 'image/x-portable-pixmap',
+            'xpps' => 'application/vnd.ms-powerpoint',
+
+            'xppt' => 'application/vnd.ms-powerpoint',
+            'xpqa' => 'application/vnd.palm',
+            'xprc' => 'application/vnd.palm',
+            'xpre' => 'application/vnd.lotus-freelance',
+            'xprf' => 'application/pics-rules',
+            'xps' => 'application/postscript',
+            'xpsb' => 'application/vnd.3gpp.pic-bw-small',
+            'xpsd' => 'image/vnd.adobe.photoshop',
+            'xptid' => 'application/vnd.pvi.ptid1',
+
+            'xpub' => 'application/x-mspublisher',
+            'xpvb' => 'application/vnd.3gpp.pic-bw-var',
+            'xpwn' => 'application/vnd.3m.post-it-notes',
+            'xqam' => 'application/vnd.epson.quickanime',
+            'xqbo' => 'application/vnd.intu.qbo',
+            'xqfx' => 'application/vnd.intu.qfx',
+            'xqps' => 'application/vnd.publishare-delta-tree',
+            'xqt' => 'video/quicktime',
+            'xra' => 'audio/x-pn-realaudio',
+
+            'xram' => 'audio/x-pn-realaudio',
+            'xrar' => 'application/x-rar-compressed',
+            'xras' => 'image/x-cmu-raster',
+            'xrcprofile' => 'application/vnd.ipunplugged.rcprofile',
+            'xrdf' => 'application/rdf+xml',
+            'xrdz' => 'application/vnd.data-vision.rdz',
+            'xrep' => 'application/vnd.businessobjects',
+            'xrgb' => 'image/x-rgb',
+            'xrif' => 'application/reginfo+xml',
+
+            'xrl' => 'application/resource-lists+xml',
+            'xrlc' => 'image/vnd.fujixerox.edmics-rlc',
+            'xrm' => 'application/vnd.rn-realmedia',
+            'xrmi' => 'audio/midi',
+            'xrmp' => 'audio/x-pn-realaudio-plugin',
+            'xrms' => 'application/vnd.jcp.javame.midlet-rms',
+            'xrnc' => 'application/relax-ng-compact-syntax',
+            'xrpss' => 'application/vnd.nokia.radio-presets',
+            'xrpst' => 'application/vnd.nokia.radio-preset',
+
+            'xrq' => 'application/sparql-query',
+            'xrs' => 'application/rls-services+xml',
+            'xrsd' => 'application/rsd+xml',
+            'xrss' => 'application/rss+xml',
+            'xrtf' => 'application/rtf',
+            'xrtx' => 'text/richtext',
+            'xsaf' => 'application/vnd.yamaha.smaf-audio',
+            'xsbml' => 'application/sbml+xml',
+            'xsc' => 'application/vnd.ibm.secure-container',
+
+            'xscd' => 'application/x-msschedule',
+            'xscm' => 'application/vnd.lotus-screencam',
+            'xscq' => 'application/scvp-cv-request',
+            'xscs' => 'application/scvp-cv-response',
+            'xsdp' => 'application/sdp',
+            'xsee' => 'application/vnd.seemail',
+            'xsema' => 'application/vnd.sema',
+            'xsemd' => 'application/vnd.semd',
+            'xsemf' => 'application/vnd.semf',
+
+            'xsetpay' => 'application/set-payment-initiation',
+            'xsetreg' => 'application/set-registration-initiation',
+            'xsfs' => 'application/vnd.spotfire.sfs',
+            'xsgm' => 'text/sgml',
+            'xsgml' => 'text/sgml',
+            'xsh' => 'application/x-sh',
+            'xshar' => 'application/x-shar',
+            'xshf' => 'application/shf+xml',
+            'xsilo' => 'model/mesh',
+
+            'xsit' => 'application/x-stuffit',
+            'xsitx' => 'application/x-stuffitx',
+            'xslt' => 'application/vnd.epson.salt',
+            'xsnd' => 'audio/basic',
+            'xspf' => 'application/vnd.yamaha.smaf-phrase',
+            'xspl' => 'application/x-futuresplash',
+            'xspot' => 'text/vnd.in3d.spot',
+            'xspp' => 'application/scvp-vp-response',
+            'xspq' => 'application/scvp-vp-request',
+
+            'xsrc' => 'application/x-wais-source',
+            'xsrx' => 'application/sparql-results+xml',
+            'xssf' => 'application/vnd.epson.ssf',
+            'xssml' => 'application/ssml+xml',
+            'xstf' => 'application/vnd.wt.stf',
+            'xstk' => 'application/hyperstudio',
+            'xstr' => 'application/vnd.pg.format',
+            'xsus' => 'application/vnd.sus-calendar',
+            'xsusp' => 'application/vnd.sus-calendar',
+
+            'xsv4cpio' => 'application/x-sv4cpio',
+            'xsv4crc' => 'application/x-sv4crc',
+            'xsvd' => 'application/vnd.svd',
+            'xswf' => 'application/x-shockwave-flash',
+            'xtao' => 'application/vnd.tao.intent-module-archive',
+            'xtar' => 'application/x-tar',
+            'xtcap' => 'application/vnd.3gpp2.tcap',
+            'xtcl' => 'application/x-tcl',
+            'xtex' => 'application/x-tex',
+
+            'xtext' => 'text/plain',
+            'xtif' => 'image/tiff',
+            'xtiff' => 'image/tiff',
+            'xtmo' => 'application/vnd.tmobile-livetv',
+            'xtorrent' => 'application/x-bittorrent',
+            'xtpl' => 'application/vnd.groove-tool-template',
+            'xtpt' => 'application/vnd.trid.tpt',
+            'xtra' => 'application/vnd.trueapp',
+            'xtrm' => 'application/x-msterminal',
+
+            'xtsv' => 'text/tab-separated-values',
+            'xtxd' => 'application/vnd.genomatix.tuxedo',
+            'xtxf' => 'application/vnd.mobius.txf',
+            'xtxt' => 'text/plain',
+            'xumj' => 'application/vnd.umajin',
+            'xunityweb' => 'application/vnd.unity',
+            'xuoml' => 'application/vnd.uoml+xml',
+            'xuri' => 'text/uri-list',
+            'xuris' => 'text/uri-list',
+
+            'xurls' => 'text/uri-list',
+            'xustar' => 'application/x-ustar',
+            'xutz' => 'application/vnd.uiq.theme',
+            'xuu' => 'text/x-uuencode',
+            'xvcd' => 'application/x-cdlink',
+            'xvcf' => 'text/x-vcard',
+            'xvcg' => 'application/vnd.groove-vcard',
+            'xvcs' => 'text/x-vcalendar',
+            'xvcx' => 'application/vnd.vcx',
+
+            'xvis' => 'application/vnd.visionary',
+            'xviv' => 'video/vnd.vivo',
+            'xvrml' => 'model/vrml',
+            'xvsd' => 'application/vnd.visio',
+            'xvsf' => 'application/vnd.vsf',
+            'xvss' => 'application/vnd.visio',
+            'xvst' => 'application/vnd.visio',
+            'xvsw' => 'application/vnd.visio',
+            'xvtu' => 'model/vnd.vtu',
+
+            'xvxml' => 'application/voicexml+xml',
+            'xwav' => 'audio/x-wav',
+            'xwax' => 'audio/x-ms-wax',
+            'xwbmp' => 'image/vnd.wap.wbmp',
+            'xwbs' => 'application/vnd.criticaltools.wbs+xml',
+            'xwbxml' => 'application/vnd.wap.wbxml',
+            'xwcm' => 'application/vnd.ms-works',
+            'xwdb' => 'application/vnd.ms-works',
+            'xwks' => 'application/vnd.ms-works',
+
+            'xwm' => 'video/x-ms-wm',
+            'xwma' => 'audio/x-ms-wma',
+            'xwmd' => 'application/x-ms-wmd',
+            'xwmf' => 'application/x-msmetafile',
+            'xwml' => 'text/vnd.wap.wml',
+            'xwmlc' => 'application/vnd.wap.wmlc',
+            'xwmls' => 'text/vnd.wap.wmlscript',
+            'xwmlsc' => 'application/vnd.wap.wmlscriptc',
+            'xwmv' => 'video/x-ms-wmv',
+
+            'xwmx' => 'video/x-ms-wmx',
+            'xwmz' => 'application/x-ms-wmz',
+            'xwpd' => 'application/vnd.wordperfect',
+            'xwpl' => 'application/vnd.ms-wpl',
+            'xwps' => 'application/vnd.ms-works',
+            'xwqd' => 'application/vnd.wqd',
+            'xwri' => 'application/x-mswrite',
+            'xwrl' => 'model/vrml',
+            'xwsdl' => 'application/wsdl+xml',
+
+            'xwspolicy' => 'application/wspolicy+xml',
+            'xwtb' => 'application/vnd.webturbo',
+            'xwvx' => 'video/x-ms-wvx',
+            'xx3d' => 'application/vnd.hzn-3d-crossword',
+            'xxar' => 'application/vnd.xara',
+            'xxbd' => 'application/vnd.fujixerox.docuworks.binder',
+            'xxbm' => 'image/x-xbitmap',
+            'xxdm' => 'application/vnd.syncml.dm+xml',
+            'xxdp' => 'application/vnd.adobe.xdp+xml',
+
+            'xxdw' => 'application/vnd.fujixerox.docuworks',
+            'xxenc' => 'application/xenc+xml',
+            'xxfdf' => 'application/vnd.adobe.xfdf',
+            'xxfdl' => 'application/vnd.xfdl',
+            'xxht' => 'application/xhtml+xml',
+            'xxhtml' => 'application/xhtml+xml',
+            'xxhvml' => 'application/xv+xml',
+            'xxif' => 'image/vnd.xiff',
+            'xxla' => 'application/vnd.ms-excel',
+
+            'xxlc' => 'application/vnd.ms-excel',
+            'xxlm' => 'application/vnd.ms-excel',
+            'xxls' => 'application/vnd.ms-excel',
+            'xxlt' => 'application/vnd.ms-excel',
+            'xxlw' => 'application/vnd.ms-excel',
+            'xxml' => 'application/xml',
+            'xxo' => 'application/vnd.olpc-sugar',
+            'xxop' => 'application/xop+xml',
+            'xxpm' => 'image/x-xpixmap',
+
+            'xxpr' => 'application/vnd.is-xpr',
+            'xxps' => 'application/vnd.ms-xpsdocument',
+            'xxsl' => 'application/xml',
+            'xxslt' => 'application/xslt+xml',
+            'xxsm' => 'application/vnd.syncml+xml',
+            'xxspf' => 'application/xspf+xml',
+            'xxul' => 'application/vnd.mozilla.xul+xml',
+            'xxvm' => 'application/xv+xml',
+            'xxvml' => 'application/xv+xml',
+
+            'xxwd' => 'image/x-xwindowdump',
+            'xxyz' => 'chemical/x-xyz',
+            'xzaz' => 'application/vnd.zzazz.deck+xml',
+            'xzip' => 'application/zip',
+            'xzmm' => 'application/vnd.handheld-entertainment+xml',
+        );
+
+    /**
+     * Extend list of MIME types if needed from config
+     */
+    public function __construct()
+    {
+        $nodes = Mage::getConfig()->getNode('global/mime/types');
+        if ($nodes) {
+            $nodes = (array)$nodes;
+            foreach ($nodes as $key => $value) {
+                $this->_mimeTypes[$key] = $value;
+            }
+        }
+    }
+
+    /**
+     * Get MIME type by file extension from list of pre-defined MIME types
+     *
+     * @param $ext
+     * @return string
+     */
+    public function getMimeTypeByExtension($ext)
+    {
+        $type = 'x' . $ext;
+        if (isset($this->_mimeTypes[$type])) {
+            return $this->_mimeTypes[$type];
+        }
+        return 'application/octet-stream';
+    }
+
+    /**
+     * Get all MIME Types
+     *
+     * @return array
+     */
+    public function getMimeTypes()
+    {
+        return $this->_mimeTypes;
+    }
+
+    /**
+     * Get array of MIME types associated with given file extension
+     *
+     * @param array|string $extensionsList
+     * @return array
+     */
+    public function getMimeTypeFromExtensionList($extensionsList)
+    {
+        if (is_string($extensionsList)) {
+            $extensionsList = array_map('trim', explode(',', $extensionsList));
+        }
+
+        return array_map(array($this, 'getMimeTypeByExtension'), $extensionsList);
+    }
+
+    /**
+     * Get post_max_size server setting
+     *
+     * @return string
+     */
+    public function getPostMaxSize()
+    {
+        return ini_get('post_max_size');
+    }
+
+    /**
+     * Get upload_max_filesize server setting
+     *
+     * @return string
+     */
+    public function getUploadMaxSize()
+    {
+        return ini_get('upload_max_filesize');
+    }
+
+    /**
+     * Get max upload size
+     *
+     * @return mixed
+     */
+    public function getDataMaxSize()
+    {
+        return min($this->getPostMaxSize(), $this->getUploadMaxSize());
+    }
+
+    /**
+     * Get maximum upload size in bytes
+     *
+     * @return int
+     */
+    public function getDataMaxSizeInBytes()
+    {
+        $iniSize = $this->getDataMaxSize();
+        $size = substr($iniSize, 0, strlen($iniSize)-1);
+        $parsedSize = 0;
+        switch (strtolower(substr($iniSize, strlen($iniSize)-1))) {
+            case 't':
+                $parsedSize = $size*(1024*1024*1024*1024);
+                break;
+            case 'g':
+                $parsedSize = $size*(1024*1024*1024);
+                break;
+            case 'm':
+                $parsedSize = $size*(1024*1024);
+                break;
+            case 'k':
+                $parsedSize = $size*1024;
+                break;
+            case 'b':
+            default:
+                $parsedSize = $size;
+                break;
+        }
+        return (int)$parsedSize;
+    }
+
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Abstract.php app/code/core/Mage/Uploader/Model/Config/Abstract.php
new file mode 100644
index 0000000..b11f11e
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Abstract.php
@@ -0,0 +1,69 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+abstract class Mage_Uploader_Model_Config_Abstract extends Varien_Object
+{
+    /**
+     * Get file helper
+     *
+     * @return Mage_Uploader_Helper_File
+     */
+    protected function _getHelper()
+    {
+        return Mage::helper('uploader/file');
+    }
+
+    /**
+     * Set/Get attribute wrapper
+     * Also set data in cameCase for config values
+     *
+     * @param string $method
+     * @param array $args
+     * @return bool|mixed|Varien_Object
+     * @throws Varien_Exception
+     */
+    public function __call($method, $args)
+    {
+        $key = lcfirst($this->_camelize(substr($method,3)));
+        switch (substr($method, 0, 3)) {
+            case 'get' :
+                $data = $this->getData($key, isset($args[0]) ? $args[0] : null);
+                return $data;
+
+            case 'set' :
+                $result = $this->setData($key, isset($args[0]) ? $args[0] : null);
+                return $result;
+
+            case 'uns' :
+                $result = $this->unsetData($key);
+                return $result;
+
+            case 'has' :
+                return isset($this->_data[$key]);
+        }
+        throw new Varien_Exception("Invalid method ".get_class($this)."::".$method."(".print_r($args,1).")");
+    }
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Browsebutton.php app/code/core/Mage/Uploader/Model/Config/Browsebutton.php
new file mode 100644
index 0000000..442f254
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Browsebutton.php
@@ -0,0 +1,63 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category  Mage
+ * @package   Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license   http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+
+ * @method Mage_Uploader_Model_Config_Browsebutton setDomNodes(array $domNodesIds)
+ *      Array of element browse buttons ids
+ * @method Mage_Uploader_Model_Config_Browsebutton setIsDirectory(bool $isDirectory)
+ *      Pass in true to allow directories to be selected (Google Chrome only)
+ * @method Mage_Uploader_Model_Config_Browsebutton setSingleFile(bool $isSingleFile)
+ *      To prevent multiple file uploads set this to true.
+ *      Also look at config parameter singleFile (Mage_Uploader_Model_Config_Uploader setSingleFile())
+ * @method Mage_Uploader_Model_Config_Browsebutton setAttributes(array $attributes)
+ *      Pass object of keys and values to set custom attributes on input fields.
+ *      @see http://www.w3.org/TR/html-markup/input.file.html#input.file-attributes
+ */
+
+class Mage_Uploader_Model_Config_Browsebutton extends Mage_Uploader_Model_Config_Abstract
+{
+    /**
+     * Set params for browse button
+     */
+    protected function _construct()
+    {
+        $this->setIsDirectory(false);
+    }
+
+    /**
+     * Get MIME types from files extensions
+     *
+     * @param string|array $exts
+     * @return string
+     */
+    public function getMimeTypesByExtensions($exts)
+    {
+        $mimes = array_unique($this->_getHelper()->getMimeTypeFromExtensionList($exts));
+
+        // Not include general file type
+        unset($mimes['application/octet-stream']);
+
+        return implode(',', $mimes);
+    }
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Misc.php app/code/core/Mage/Uploader/Model/Config/Misc.php
new file mode 100644
index 0000000..8231844
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Misc.php
@@ -0,0 +1,46 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category   Mage
+ * @package    Mage_Uploader
+ * @copyright  Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ * 
+ * @method Mage_Uploader_Model_Config_Misc setMaxSizePlural (string $sizePlural) Set plural info about max upload size
+ * @method Mage_Uploader_Model_Config_Misc setMaxSizeInBytes (int $sizeInBytes) Set max upload size in bytes
+ * @method Mage_Uploader_Model_Config_Misc setReplaceBrowseWithRemove (bool $replaceBrowseWithRemove)
+ *      Replace browse button with remove
+ *
+ * Class Mage_Uploader_Model_Config_Misc
+ */
+
+class Mage_Uploader_Model_Config_Misc extends Mage_Uploader_Model_Config_Abstract
+{
+    /**
+     * Prepare misc params
+     */
+    protected function _construct()
+    {
+        $this
+            ->setMaxSizeInBytes($this->_getHelper()->getDataMaxSizeInBytes())
+            ->setMaxSizePlural($this->_getHelper()->getDataMaxSize())
+        ;
+    }
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Uploader.php app/code/core/Mage/Uploader/Model/Config/Uploader.php
new file mode 100644
index 0000000..9e35570
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Uploader.php
@@ -0,0 +1,122 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category   Mage
+ * @package    Mage_Uploader
+ * @copyright  Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * @method Mage_Uploader_Model_Config_Uploader setTarget(string $url)
+ *      The target URL for the multipart POST request.
+ * @method Mage_Uploader_Model_Config_Uploader setSingleFile(bool $isSingleFile)
+ *      Enable single file upload.
+ *      Once one file is uploaded, second file will overtake existing one, first one will be canceled.
+ * @method Mage_Uploader_Model_Config_Uploader setChunkSize(int $chunkSize) The size in bytes of each uploaded chunk of data.
+ * @method Mage_Uploader_Model_Config_Uploader setForceChunkSize(bool $forceChunkSize)
+ *      Force all chunks to be less or equal than chunkSize.
+ * @method Mage_Uploader_Model_Config_Uploader setSimultaneousUploads(int $amountOfSimultaneousUploads)
+ * @method Mage_Uploader_Model_Config_Uploader setFileParameterName(string $fileUploadParam)
+ * @method Mage_Uploader_Model_Config_Uploader setQuery(array $additionalQuery)
+ * @method Mage_Uploader_Model_Config_Uploader setHeaders(array $headers)
+ *      Extra headers to include in the multipart POST with data.
+ * @method Mage_Uploader_Model_Config_Uploader setWithCredentials(bool $isCORS)
+ *      Standard CORS requests do not send or set any cookies by default.
+ *      In order to include cookies as part of the request, you need to set the withCredentials property to true.
+ * @method Mage_Uploader_Model_Config_Uploader setMethod(string $sendMethod)
+ *       Method to use when POSTing chunks to the server. Defaults to "multipart"
+ * @method Mage_Uploader_Model_Config_Uploader setTestMethod(string $testMethod) Defaults to "GET"
+ * @method Mage_Uploader_Model_Config_Uploader setUploadMethod(string $uploadMethod) Defaults to "POST"
+ * @method Mage_Uploader_Model_Config_Uploader setAllowDuplicateUploads(bool $allowDuplicateUploads)
+ *      Once a file is uploaded, allow reupload of the same file. By default, if a file is already uploaded,
+ *      it will be skipped unless the file is removed from the existing Flow object.
+ * @method Mage_Uploader_Model_Config_Uploader setPrioritizeFirstAndLastChunk(bool $prioritizeFirstAndLastChunk)
+ *      This can be handy if you can determine if a file is valid for your service from only the first or last chunk.
+ * @method Mage_Uploader_Model_Config_Uploader setTestChunks(bool $prioritizeFirstAndLastChunk)
+ *      Make a GET request to the server for each chunks to see if it already exists.
+ * @method Mage_Uploader_Model_Config_Uploader setPreprocess(bool $prioritizeFirstAndLastChunk)
+ *      Optional function to process each chunk before testing & sending.
+ * @method Mage_Uploader_Model_Config_Uploader setInitFileFn(string $function)
+ *      Optional function to initialize the fileObject (js).
+ * @method Mage_Uploader_Model_Config_Uploader setReadFileFn(string $function)
+ *      Optional function wrapping reading operation from the original file.
+ * @method Mage_Uploader_Model_Config_Uploader setGenerateUniqueIdentifier(string $function)
+ *      Override the function that generates unique identifiers for each file. Defaults to "null"
+ * @method Mage_Uploader_Model_Config_Uploader setMaxChunkRetries(int $maxChunkRetries) Defaults to 0
+ * @method Mage_Uploader_Model_Config_Uploader setChunkRetryInterval(int $chunkRetryInterval) Defaults to "undefined"
+ * @method Mage_Uploader_Model_Config_Uploader setProgressCallbacksInterval(int $progressCallbacksInterval)
+ * @method Mage_Uploader_Model_Config_Uploader setSpeedSmoothingFactor(int $speedSmoothingFactor)
+ *      Used for calculating average upload speed. Number from 1 to 0.
+ *      Set to 1 and average upload speed wil be equal to current upload speed.
+ *      For longer file uploads it is better set this number to 0.02,
+ *      because time remaining estimation will be more accurate.
+ * @method Mage_Uploader_Model_Config_Uploader setSuccessStatuses(array $successStatuses)
+ *      Response is success if response status is in this list
+ * @method Mage_Uploader_Model_Config_Uploader setPermanentErrors(array $permanentErrors)
+ *      Response fails if response status is in this list
+ *
+ * Class Mage_Uploader_Model_Config_Uploader
+ */
+
+class Mage_Uploader_Model_Config_Uploader extends Mage_Uploader_Model_Config_Abstract
+{
+    /**
+     * Type of upload
+     */
+    const UPLOAD_TYPE = 'multipart';
+
+    /**
+     * Test chunks on resumable uploads
+     */
+    const TEST_CHUNKS = false;
+
+    /**
+     * Used for calculating average upload speed.
+     */
+    const SMOOTH_UPLOAD_FACTOR = 0.02;
+
+    /**
+     * Progress check interval
+     */
+    const PROGRESS_CALLBACK_INTERVAL = 0;
+
+    /**
+     * Set default values for uploader
+     */
+    protected function _construct()
+    {
+        $this
+            ->setChunkSize($this->_getHelper()->getDataMaxSizeInBytes())
+            ->setWithCredentials(false)
+            ->setForceChunkSize(false)
+            ->setQuery(array(
+                'form_key' => Mage::getSingleton('core/session')->getFormKey()
+            ))
+            ->setMethod(self::UPLOAD_TYPE)
+            ->setAllowDuplicateUploads(true)
+            ->setPrioritizeFirstAndLastChunk(false)
+            ->setTestChunks(self::TEST_CHUNKS)
+            ->setSpeedSmoothingFactor(self::SMOOTH_UPLOAD_FACTOR)
+            ->setProgressCallbacksInterval(self::PROGRESS_CALLBACK_INTERVAL)
+            ->setSuccessStatuses(array(200, 201, 202))
+            ->setPermanentErrors(array(404, 415, 500, 501));
+    }
+}
diff --git app/code/core/Mage/Uploader/etc/config.xml app/code/core/Mage/Uploader/etc/config.xml
new file mode 100644
index 0000000..d3fcd40
--- /dev/null
+++ app/code/core/Mage/Uploader/etc/config.xml
@@ -0,0 +1,51 @@
+<?xml version="1.0"?>
+<!--
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright   Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+-->
+<config>
+    <modules>
+        <Mage_Uploader>
+            <version>0.1.0</version>
+        </Mage_Uploader>
+    </modules>
+    <global>
+        <blocks>
+            <uploader>
+                <class>Mage_Uploader_Block</class>
+            </uploader>
+        </blocks>
+        <helpers>
+            <uploader>
+                <class>Mage_Uploader_Helper</class>
+            </uploader>
+        </helpers>
+        <models>
+            <uploader>
+                <class>Mage_Uploader_Model</class>
+            </uploader>
+        </models>
+    </global>
+</config>
diff --git app/code/core/Mage/Uploader/etc/jstranslator.xml app/code/core/Mage/Uploader/etc/jstranslator.xml
new file mode 100644
index 0000000..4d7d405
--- /dev/null
+++ app/code/core/Mage/Uploader/etc/jstranslator.xml
@@ -0,0 +1,44 @@
+<?xml version="1.0"?>
+<!--
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category   Mage
+ * @package    Mage_Uploader
+ * @copyright  Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+-->
+<jstranslator>
+    <uploader-exceed_max-1 translate="message" module="uploader">
+        <message>Maximum allowed file size for upload is</message>
+    </uploader-exceed_max-1>
+    <uploader-exceed_max-2 translate="message" module="uploader">
+        <message>Please check your server PHP settings.</message>
+    </uploader-exceed_max-2>
+    <uploader-tab-change-event-confirm translate="message" module="uploader">
+        <message>There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?</message>
+    </uploader-tab-change-event-confirm>
+    <uploader-complete-event-text translate="message" module="uploader">
+        <message>Complete</message>
+    </uploader-complete-event-text>
+    <uploader-uploading-progress translate="message" module="uploader">
+        <message>Uploading...</message>
+    </uploader-uploading-progress>
+</jstranslator>
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
index 5d4a9b1..0cb55f4 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
@@ -538,8 +538,8 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl
                 $ch = curl_init();
                 curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                 curl_setopt($ch, CURLOPT_URL, $url);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
+                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
                 $responseBody = curl_exec($ch);
                 curl_close($ch);
@@ -1037,8 +1037,8 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl
             $ch = curl_init();
             curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
             curl_setopt($ch, CURLOPT_URL, $url);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
             $responseBody = curl_exec($ch);
             $debugData['result'] = $responseBody;
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
index 4982ab9..db81327 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
@@ -837,7 +837,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
     {
         $client = new Varien_Http_Client();
         $client->setUri((string)$this->getConfigData('gateway_url'));
-        $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
+        $client->setConfig(array(
+            'maxredirects' => 0,
+            'timeout' => 30,
+            'verifypeer' => $this->getConfigFlag('verify_peer'),
+            'verifyhost' => 2,
+        ));
         $client->setRawData(utf8_encode($request));
         return $client->request(Varien_Http_Client::POST)->getBody();
     }
@@ -1411,7 +1416,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
             try {
                 $client = new Varien_Http_Client();
                 $client->setUri((string)$this->getConfigData('gateway_url'));
-                $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
+                $client->setConfig(array(
+                    'maxredirects' => 0,
+                    'timeout' => 30,
+                    'verifypeer' => $this->getConfigFlag('verify_peer'),
+                    'verifyhost' => 2,
+                ));
                 $client->setRawData($request);
                 $responseBody = $client->request(Varien_Http_Client::POST)->getBody();
                 $debugData['result'] = $responseBody;
@@ -1603,7 +1613,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
             try {
                 $client = new Varien_Http_Client();
                 $client->setUri((string)$this->getConfigData('gateway_url'));
-                $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
+                $client->setConfig(array(
+                    'maxredirects' => 0,
+                    'timeout' => 30,
+                    'verifypeer' => $this->getConfigFlag('verify_peer'),
+                    'verifyhost' => 2,
+                ));
                 $client->setRawData($request);
                 $responseBody = $client->request(Varien_Http_Client::POST)->getBody();
                 $debugData['result'] = $responseBody;
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
index d615c19..e76ebc4 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
@@ -604,6 +604,7 @@ class Mage_Usa_Model_Shipping_Carrier_Fedex
     /**
      * Get xml quotes
      *
+     * @deprecated
      * @return Mage_Shipping_Model_Rate_Result
      */
     protected function _getXmlQuotes()
@@ -663,8 +664,8 @@ class Mage_Usa_Model_Shipping_Carrier_Fedex
                 $ch = curl_init();
                 curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                 curl_setopt($ch, CURLOPT_URL, $url);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
+                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
                 $responseBody = curl_exec($ch);
                 curl_close ($ch);
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
index 39bf897..561a486 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
@@ -937,7 +937,7 @@ XMLRequest;
                 curl_setopt($ch, CURLOPT_POST, 1);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $xmlRequest);
                 curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
                 $xmlResponse = curl_exec ($ch);
 
                 $debugData['result'] = $xmlResponse;
@@ -1578,7 +1578,7 @@ XMLAuth;
             curl_setopt($ch, CURLOPT_POST, 1);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $this->_xmlAccessRequest . $xmlRequest->asXML());
             curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
             $xmlResponse = curl_exec ($ch);
 
             $debugData['result'] = $xmlResponse;
@@ -1636,7 +1636,7 @@ XMLAuth;
             curl_setopt($ch, CURLOPT_POST, 1);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $xmlRequest);
             curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
             $xmlResponse = curl_exec($ch);
             if ($xmlResponse === false) {
                 throw new Exception(curl_error($ch));
diff --git app/code/core/Mage/Usa/etc/config.xml app/code/core/Mage/Usa/etc/config.xml
index 25dc346..17c1d88 100644
--- app/code/core/Mage/Usa/etc/config.xml
+++ app/code/core/Mage/Usa/etc/config.xml
@@ -114,6 +114,7 @@
                 <dutypaymenttype>R</dutypaymenttype>
                 <free_method>G</free_method>
                 <gateway_url>https://eCommerce.airborne.com/ApiLandingTest.asp</gateway_url>
+                <verify_peer>0</verify_peer>
                 <id backend_model="adminhtml/system_config_backend_encrypted"/>
                 <model>usa/shipping_carrier_dhl</model>
                 <password backend_model="adminhtml/system_config_backend_encrypted"/>
@@ -169,6 +170,7 @@
                 <tracking_xml_url>https://onlinetools.ups.com/ups.app/xml/Track</tracking_xml_url>
                 <shipconfirm_xml_url>https://onlinetools.ups.com/ups.app/xml/ShipConfirm</shipconfirm_xml_url>
                 <shipaccept_xml_url>https://onlinetools.ups.com/ups.app/xml/ShipAccept</shipaccept_xml_url>
+                <verify_peer>0</verify_peer>
                 <handling>0</handling>
                 <model>usa/shipping_carrier_ups</model>
                 <pickup>CC</pickup>
@@ -219,6 +221,7 @@
                 <doc_methods>2,5,6,7,9,B,C,D,U,K,L,G,W,I,N,O,R,S,T,X</doc_methods>
                 <free_method>G</free_method>
                 <gateway_url>https://xmlpi-ea.dhl.com/XMLShippingServlet</gateway_url>
+                <verify_peer>0</verify_peer>
                 <id backend_model="adminhtml/system_config_backend_encrypted"/>
                 <password backend_model="adminhtml/system_config_backend_encrypted"/>
                 <shipment_type>N</shipment_type>
diff --git app/code/core/Mage/Usa/etc/system.xml app/code/core/Mage/Usa/etc/system.xml
index afee8fe..813fbd4 100644
--- app/code/core/Mage/Usa/etc/system.xml
+++ app/code/core/Mage/Usa/etc/system.xml
@@ -130,6 +130,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gateway_url>
+                        <verify_peer translate="label">
+                            <label>Enable SSL Verification</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verify_peer>
                         <handling_type translate="label">
                             <label>Calculate Handling Fee</label>
                             <frontend_type>select</frontend_type>
@@ -744,6 +753,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gateway_url>
+                        <verify_peer translate="label">
+                            <label>Enable SSL Verification</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>45</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verify_peer>
                         <gateway_xml_url translate="label">
                             <label>Gateway XML URL</label>
                             <frontend_type>text</frontend_type>
@@ -1264,6 +1282,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gateway_url>
+                        <verify_peer translate="label">
+                            <label>Enable SSL Verification</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verify_peer>
                         <title translate="label">
                             <label>Title</label>
                             <frontend_type>text</frontend_type>
diff --git app/code/core/Mage/Wishlist/Helper/Data.php app/code/core/Mage/Wishlist/Helper/Data.php
index d7cb3b4..0e53ac9 100644
--- app/code/core/Mage/Wishlist/Helper/Data.php
+++ app/code/core/Mage/Wishlist/Helper/Data.php
@@ -274,7 +274,10 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
     public function getRemoveUrl($item)
     {
         return $this->_getUrl('wishlist/index/remove',
-            array('item' => $item->getWishlistItemId())
+            array(
+                'item' => $item->getWishlistItemId(),
+                Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
+            )
         );
     }
 
diff --git app/code/core/Mage/Wishlist/controllers/IndexController.php app/code/core/Mage/Wishlist/controllers/IndexController.php
index a8d9932..3837636 100644
--- app/code/core/Mage/Wishlist/controllers/IndexController.php
+++ app/code/core/Mage/Wishlist/controllers/IndexController.php
@@ -434,6 +434,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
      */
     public function removeAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $id = (int) $this->getRequest()->getParam('item');
         $item = Mage::getModel('wishlist/item')->load($id);
         if (!$item->getId()) {
diff --git app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
index 3df5a5d..01ba166 100644
--- app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
+++ app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
@@ -95,4 +95,21 @@ class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design
     {
         return true;
     }
+
+    /**
+     * Create browse button template
+     *
+     * @return string
+     */
+    public function getBrowseButtonHtml()
+    {
+        return $this->getLayout()->createBlock('adminhtml/widget_button')
+            ->addData(array(
+                'before_html'   => '<div style="display:inline-block; " id="{{file_field}}_{{id}}_file-browse">',
+                'after_html'    => '</div>',
+                'id'            => '{{file_field}}_{{id}}_file-browse_button',
+                'label'         => Mage::helper('uploader')->__('...'),
+                'type'          => 'button',
+            ))->toHtml();
+    }
 }
diff --git app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design/Images.php app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design/Images.php
index 4b9d99c..26577cd 100644
--- app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design/Images.php
+++ app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design/Images.php
@@ -31,7 +31,7 @@
  * @package     Mage_Xmlconnect
  * @author      Magento Core Team <core@magentocommerce.com>
  */
-class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage_Adminhtml_Block_Template
+class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage_Uploader_Block_Single
 {
     /**
      * Init block, set preview template
@@ -116,42 +116,56 @@ class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage
             'application_id' => $this->getApplicationId());
 
         if (isset($image['image_id'])) {
-            $this->getConfig()->setFileSave(Mage::getModel('xmlconnect/images')->getImageUrl($image['image_file']))
-                ->setImageId($image['image_id']);
-
-            $this->getConfig()->setThumbnail(Mage::getModel('xmlconnect/images')->getCustomSizeImageUrl(
+            $this->getMiscConfig()->setData('file_save',
+                Mage::getModel('xmlconnect/images')->getImageUrl($image['image_file']))
+                    ->setImageId($image['image_id']
+            )->setData('thumbnail',
+                Mage::getModel('xmlconnect/images')->getCustomSizeImageUrl(
                 $image['image_file'],
                 Mage_XmlConnect_Helper_Data::THUMBNAIL_IMAGE_WIDTH,
                 Mage_XmlConnect_Helper_Data::THUMBNAIL_IMAGE_HEIGHT
-            ))->setImageId($image['image_id']);
+            ))->setData('image_id', $image['image_id']);
 
             $imageActionData = Mage::helper('xmlconnect')->getApplication()->getImageActionModel()
                 ->getImageActionData($image['image_id']);
             if ($imageActionData) {
-                $this->getConfig()->setImageActionData($imageActionData);
+                $this->getMiscConfig()->setData('image_action_data', $imageActionData);
             }
         }
 
-        if (isset($image['show_uploader'])) {
-            $this->getConfig()->setShowUploader($image['show_uploader']);
-        }
+        $this->getUploaderConfig()
+            ->setFileParameterName($image['image_type'])
+            ->setTarget(
+                Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/uploadimages', $params)
+            );
+
+        $this->getButtonConfig()
+            ->setAttributes(
+                array('accept' => $this->getButtonConfig()->getMimeTypesByExtensions('gif, jpg, jpeg, png'))
+            );
+        $this->getMiscConfig()
+            ->setReplaceBrowseWithRemove(true)
+            ->setData('image_count', $this->getImageCount())
+        ;
+
+        return parent::getJsonConfig();
+    }
 
-        $this->getConfig()->setUrl(
-            Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/uploadimages', $params)
-        );
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField($image['image_type']);
-        $this->getConfig()->setFilters(array(
-            'images' => array(
-                'label' => Mage::helper('adminhtml')->__('Images (.gif, .jpg, .png)'),
-                'files' => array('*.gif', '*.jpg','*.jpeg', '*.png')
-        )));
-        $this->getConfig()->setReplaceBrowseWithRemove(true);
-        $this->getConfig()->setWidth('32');
-        $this->getConfig()->setHideUploadButton(true);
-        $this->getConfig()->setImageCount($this->getImageCount());
-
-        return $this->getConfig()->getData();
+    /**
+     * Prepare layout, change button and set front-end element ids mapping
+     *
+     * @return $this
+     */
+    protected function _prepareLayout()
+    {
+        parent::_prepareLayout();
+
+        $this->_addElementIdsMapping(array(
+            'container'     => $this->getHtmlId() . '-new',
+            'idToReplace'   => $this->getHtmlId(),
+        ));
+
+        return $this;
     }
 
     /**
@@ -168,15 +182,12 @@ class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage
     /**
      * Retrieve image config object
      *
-     * @return Varien_Object
+     * @deprecated
+     * @return $this
      */
     public function getConfig()
     {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
+        return $this;
     }
 
     /**
@@ -186,7 +197,13 @@ class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage
      */
     public function clearConfig()
     {
-        $this->_config = null;
+        $this->getMiscConfig()
+            ->unsetData('image_id')
+            ->unsetData('file_save')
+            ->unsetData('thumbnail')
+            ->unsetData('image_count')
+        ;
+        $this->getUploaderConfig()->unsetFileParameterName();
         return $this;
     }
 }
diff --git app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
index dd481ad..4fad8a3 100644
--- app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
+++ app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
@@ -337,7 +337,7 @@ class Mage_XmlConnect_Adminhtml_MobileController extends Mage_Adminhtml_Controll
             curl_setopt($curlHandler, CURLOPT_POSTFIELDS, $params);
             curl_setopt($curlHandler, CURLOPT_SSL_VERIFYHOST, 2);
             curl_setopt($curlHandler, CURLOPT_RETURNTRANSFER, 1);
-            curl_setopt($curlHandler, CURLOPT_SSL_VERIFYPEER, 0);
+            curl_setopt($curlHandler, CURLOPT_SSL_VERIFYPEER, 1);
             curl_setopt($curlHandler, CURLOPT_TIMEOUT, 60);
 
             // Execute the request.
@@ -1377,9 +1377,9 @@ class Mage_XmlConnect_Adminhtml_MobileController extends Mage_Adminhtml_Controll
     public function uploadImagesAction()
     {
         $data = $this->getRequest()->getParams();
-        if (isset($data['Filename'])) {
+        if (isset($data['flowFilename'])) {
             // Add random string to uploaded file new
-            $newFileName = Mage::helper('core')->getRandomString(5) . '_' . $data['Filename'];
+            $newFileName = Mage::helper('core')->getRandomString(5) . '_' . $data['flowFilename'];
         }
         try {
             $this->_initApp();
diff --git app/design/adminhtml/default/default/layout/cms.xml app/design/adminhtml/default/default/layout/cms.xml
index 58d168d..17ff6fc 100644
--- app/design/adminhtml/default/default/layout/cms.xml
+++ app/design/adminhtml/default/default/layout/cms.xml
@@ -82,7 +82,9 @@
         </reference>
         <reference name="content">
             <block name="wysiwyg_images.content"  type="adminhtml/cms_wysiwyg_images_content" template="cms/browser/content.phtml">
-                <block name="wysiwyg_images.uploader" type="adminhtml/cms_wysiwyg_images_content_uploader" template="cms/browser/content/uploader.phtml" />
+                <block name="wysiwyg_images.uploader" type="adminhtml/cms_wysiwyg_images_content_uploader" template="media/uploader.phtml">
+                    <block name="additional_scripts" type="core/template" template="cms/browser/content/uploader.phtml"/>
+                </block>
                 <block name="wysiwyg_images.newfolder" type="adminhtml/cms_wysiwyg_images_content_newfolder" template="cms/browser/content/newfolder.phtml" />
             </block>
         </reference>
diff --git app/design/adminhtml/default/default/layout/main.xml app/design/adminhtml/default/default/layout/main.xml
index 821cea6..bd1ac21 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -171,9 +171,10 @@ Layout for editor element
             <action method="setCanLoadExtJs"><flag>1</flag></action>
             <action method="addJs"><script>mage/adminhtml/variables.js</script></action>
             <action method="addJs"><script>mage/adminhtml/wysiwyg/widget.js</script></action>
-            <action method="addJs"><script>lib/flex.js</script></action>
-            <action method="addJs"><script>lib/FABridge.js</script></action>
-            <action method="addJs"><script>mage/adminhtml/flexuploader.js</script></action>
+            <action method="addJs"><name>lib/uploader/flow.min.js</name></action>
+            <action method="addJs"><name>lib/uploader/fusty-flow.js</name></action>
+            <action method="addJs"><name>lib/uploader/fusty-flow-factory.js</name></action>
+            <action method="addJs"><name>mage/adminhtml/uploader/instance.js</name></action>
             <action method="addJs"><script>mage/adminhtml/browser.js</script></action>
             <action method="addJs"><script>prototype/window.js</script></action>
             <action method="addItem"><type>js_css</type><name>prototype/windows/themes/default.css</name></action>
diff --git app/design/adminhtml/default/default/layout/xmlconnect.xml app/design/adminhtml/default/default/layout/xmlconnect.xml
index fb8be83..b529f2a 100644
--- app/design/adminhtml/default/default/layout/xmlconnect.xml
+++ app/design/adminhtml/default/default/layout/xmlconnect.xml
@@ -75,9 +75,10 @@
             <action method="setCanLoadExtJs"><flag>1</flag></action>
             <action method="addJs"><script>mage/adminhtml/variables.js</script></action>
             <action method="addJs"><script>mage/adminhtml/wysiwyg/widget.js</script></action>
-            <action method="addJs"><script>lib/flex.js</script></action>
-            <action method="addJs"><script>lib/FABridge.js</script></action>
-            <action method="addJs"><script>mage/adminhtml/flexuploader.js</script></action>
+             <action method="addJs"><name>lib/uploader/flow.min.js</name></action>
+             <action method="addJs"><name>lib/uploader/fusty-flow.js</name></action>
+             <action method="addJs"><name>lib/uploader/fusty-flow-factory.js</name></action>
+             <action method="addJs"><name>mage/adminhtml/uploader/instance.js</name></action>
             <action method="addJs"><script>mage/adminhtml/browser.js</script></action>
             <action method="addJs"><script>prototype/window.js</script></action>
             <action method="addItem"><type>js_css</type><name>prototype/windows/themes/default.css</name></action>
@@ -104,7 +105,6 @@
                 <block type="xmlconnect/adminhtml_mobile_edit_tab_offlineCatalog" name="mobile_edit_tab_offlineCatalog"/>
                 <block type="xmlconnect/adminhtml_mobile_edit_tab_general" name="mobile_edit_tab_general"/>
                 <block type="xmlconnect/adminhtml_mobile_edit_tab_design" name="mobile_edit_tab_design">
-                    <block type="adminhtml/media_uploader" name="adminhtml_media_uploader" as="media_uploader"/>
                     <block type="xmlconnect/adminhtml_mobile_edit_tab_design_images" name="mobile_edit_tab_design_images" as="design_images" />
                     <block type="xmlconnect/adminhtml_mobile_edit_tab_design_accordion" name="mobile_edit_tab_design_accordion" as="design_accordion">
                         <block type="xmlconnect/adminhtml_mobile_edit_tab_design_accordion_themes" name="accordion_themes" />
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index 9b91417..581c9d9 100644
--- app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
@@ -108,6 +108,7 @@ $_block = $this;
     <tfoot>
         <tr>
             <td colspan="100" class="last" style="padding:8px">
+                <?php echo Mage::helper('catalog')->__('Maximum width and height dimension for upload image is %s.', Mage::getStoreConfig(Mage_Catalog_Helper_Image::XML_NODE_PRODUCT_MAX_DIMENSION)); ?>
                 <?php echo $_block->getUploaderHtml() ?>
             </td>
         </tr>
@@ -120,6 +121,6 @@ $_block = $this;
 <input type="hidden" id="<?php echo $_block->getHtmlId() ?>_save_image" name="<?php echo $_block->getElement()->getName() ?>[values]" value="<?php echo $_block->escapeHtml($_block->getImagesValuesJson()) ?>" />
 <script type="text/javascript">
 //<![CDATA[
-var <?php echo $_block->getJsObjectName(); ?> = new Product.Gallery('<?php echo $_block->getHtmlId() ?>', <?php if ($_block->getElement()->getReadonly()):?>null<?php else:?><?php echo $_block->getUploader()->getJsObjectName() ?><?php endif;?>, <?php echo $_block->getImageTypesJson() ?>);
+var <?php echo $_block->getJsObjectName(); ?> = new Product.Gallery('<?php echo $_block->getHtmlId() ?>', <?php echo $_block->getImageTypesJson() ?>);
 //]]>
 </script>
diff --git app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
index ff1871c..c93c4c0 100644
--- app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
+++ app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
@@ -24,48 +24,8 @@
  * @license     http://opensource.org/licenses/afl-3.0.php  Academic Free License (AFL 3.0)
  */
 ?>
-<?php
-/**
- * Uploader template for Wysiwyg Images
- *
- * @see Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader
- */
-?>
-<div id="<?php echo $this->getHtmlId() ?>" class="uploader">
-    <div class="buttons">
-        <div id="<?php echo $this->getHtmlId() ?>-install-flash" style="display:none">
-            <?php echo Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/') ?>
-        </div>
-    </div>
-    <div class="clear"></div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template">
-        <div id="{{id}}" class="file-row">
-        <span class="file-info">{{name}} ({{size}})</span>
-        <span class="delete-button"><?php echo $this->getDeleteButtonHtml() ?></span>
-        <span class="progress-text"></span>
-        <div class="clear"></div>
-        </div>
-    </div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template-progress">
-        {{percent}}% {{uploaded}} / {{total}}
-    </div>
-</div>
-
 <script type="text/javascript">
 //<![CDATA[
-maxUploadFileSizeInBytes = <?php echo $this->getDataMaxSizeInBytes() ?>;
-maxUploadFileSize = '<?php echo $this->getDataMaxSize() ?>';
-
-<?php echo $this->getJsObjectName() ?> = new Flex.Uploader('<?php echo $this->getHtmlId() ?>', '<?php echo $this->getUploaderUrl('media/uploader.swf') ?>', <?php echo $this->getConfigJson() ?>);
-<?php echo $this->getJsObjectName() ?>.onFilesComplete = function(completedFiles){
-    completedFiles.each(function(file){
-        <?php echo $this->getJsObjectName() ?>.removeFile(file.id);
-    });
-    MediabrowserInstance.handleUploadComplete();
-}
-// hide flash buttons
-if ($('<?php echo $this->getHtmlId() ?>-flash') != undefined) {
-    $('<?php echo $this->getHtmlId() ?>-flash').setStyle({float:'left'});
-}
+    document.on('uploader:success', MediabrowserInstance.handleUploadComplete.bind(MediabrowserInstance));
 //]]>
 </script>
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml
index adf800b..66c684a 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml
@@ -34,19 +34,16 @@
 //<![CDATA[>
 
 var uploaderTemplate = '<div class="no-display" id="[[idName]]-template">' +
-                            '<div id="{{id}}" class="file-row file-row-narrow">' +
+                            '<div id="{{id}}-container" class="file-row file-row-narrow">' +
                                 '<span class="file-info">' +
                                     '<span class="file-info-name">{{name}}</span>' +
                                     ' ' +
-                                    '<span class="file-info-size">({{size}})</span>' +
+                                    '<span class="file-info-size">{{size}}</span>' +
                                 '</span>' +
                                 '<span class="progress-text"></span>' +
                                 '<div class="clear"></div>' +
                             '</div>' +
-                        '</div>' +
-                            '<div class="no-display" id="[[idName]]-template-progress">' +
-                            '{{percent}}% {{uploaded}} / {{total}}' +
-                            '</div>';
+                        '</div>';
 
 var fileListTemplate = '<span class="file-info">' +
                             '<span class="file-info-name">{{name}}</span>' +
@@ -88,7 +85,7 @@ var Downloadable = {
     massUploadByType : function(type){
         try {
             this.uploaderObj.get(type).each(function(item){
-                container = item.value.container.up('tr');
+                var container = item.value.elements.container.up('tr');
                 if (container.visible() && !container.hasClassName('no-display')) {
                     item.value.upload();
                 } else {
@@ -141,10 +138,11 @@ Downloadable.FileUploader.prototype = {
                ? this.fileValue.toJSON()
                : Object.toJSON(this.fileValue);
         }
+        var uploaderConfig = (Object.isString(this.config) && this.config.evalJSON()) || this.config;
         Downloadable.setUploaderObj(
             this.type,
             this.key,
-            new Flex.Uploader(this.idName, '<?php echo $this->getSkinUrl('media/uploaderSingle.swf') ?>', this.config)
+            new Uploader(uploaderConfig)
         );
         if (varienGlobalEvents) {
             varienGlobalEvents.attachEventHandler('tabChangeBefore', Downloadable.getUploaderObj(type, key).onContainerHideBefore);
@@ -167,16 +165,48 @@ Downloadable.FileList.prototype = {
         this.containerId  = containerId,
         this.container = $(this.containerId);
         this.uploader = uploader;
-        this.uploader.onFilesComplete = this.handleUploadComplete.bind(this);
+        document.on('uploader:fileSuccess', function(event) {
+            var memo = event.memo;
+            if(this._checkCurrentContainer(memo.containerId)) {
+                this.handleUploadComplete([{response: memo.response}]);
+                this.handleButtonsSwap();
+            }
+        }.bind(this));
+        document.on('uploader:fileError', function(event) {
+            var memo = event.memo;
+            if(this._checkCurrentContainer(memo.containerId)) {
+                this.handleButtonsSwap();
+            }
+        }.bind(this));
+        document.on('upload:simulateDelete', this.handleFileRemoveAll.bind(this));
+        document.on('uploader:simulateNewUpload', this.handleFileNew.bind(this));
         this.file = this.getElement('save').value.evalJSON();
         this.listTemplate = new Template(this.fileListTemplate, this.templatePattern);
         this.updateFiles();
         this.uploader.onFileRemoveAll = this.handleFileRemoveAll.bind(this);
         this.uploader.onFileSelect = this.handleFileSelect.bind(this);
     },
-    handleFileRemoveAll: function(fileId) {
-        $(this.containerId+'-new').hide();
-        $(this.containerId+'-old').show();
+
+    _checkCurrentContainer: function (child) {
+        return $(this.containerId).down('#' + child);
+    },
+
+    handleFileRemoveAll: function(e) {
+        if(e.memo && this._checkCurrentContainer(e.memo.containerId)) {
+            $(this.containerId+'-new').hide();
+            $(this.containerId+'-old').show();
+            this.handleButtonsSwap();
+        }
+    },
+    handleFileNew: function (e) {
+        if(e.memo && this._checkCurrentContainer(e.memo.containerId)) {
+            $(this.containerId + '-new').show();
+            $(this.containerId + '-old').hide();
+            this.handleButtonsSwap();
+        }
+    },
+    handleButtonsSwap: function () {
+        $$(['#' + this.containerId+'-browse', '#'+this.containerId+'-delete']).invoke('toggle');
     },
     handleFileSelect: function() {
         $(this.containerId+'_type').checked = true;
@@ -204,7 +234,6 @@ Downloadable.FileList.prototype = {
            newFile.size = response.size;
            newFile.status = 'new';
            this.file[0] = newFile;
-           this.uploader.removeFile(item.id);
         }.bind(this));
         this.updateFiles();
     },
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
index da9a280..342b701 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
@@ -28,6 +28,7 @@
 
 /**
  * @see Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Links
+ * @var $this Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Links
  */
 ?>
 <?php $_product = $this->getProduct()?>
@@ -137,17 +138,14 @@ var linkTemplate = '<tr>'+
     '</td>'+
     '<td>'+
         '<div class="files">'+
-            '<div class="row">'+
-                '<label for="downloadable_link_{{id}}_sample_file_type"><input type="radio" class="radio" id="downloadable_link_{{id}}_sample_file_type" name="downloadable[link][{{id}}][sample][type]" value="file"{{sample_file_checked}} /> File:</label>'+
+            '<div class="row a-right">'+
+                '<label for="downloadable_link_{{id}}_sample_file_type" class="a-left"><input type="radio" class="radio" id="downloadable_link_{{id}}_sample_file_type" name="downloadable[link][{{id}}][sample][type]" value="file"{{sample_file_checked}} /> File:</label>'+
                 '<input type="hidden" id="downloadable_link_{{id}}_sample_file_save" name="downloadable[link][{{id}}][sample][file]" value="{{sample_file_save}}" />'+
-                '<div id="downloadable_link_{{id}}_sample_file" class="uploader">'+
+                '<?php echo $this->getBrowseButtonHtml('sample_'); ?>'+
+                '<?php echo $this->getDeleteButtonHtml('sample_'); ?>'+
+                '<div id="downloadable_link_{{id}}_sample_file" class="uploader a-left">'+
                     '<div id="downloadable_link_{{id}}_sample_file-old" class="file-row-info"></div>'+
                     '<div id="downloadable_link_{{id}}_sample_file-new" class="file-row-info"></div>'+
-                    '<div class="buttons">'+
-                        '<div id="downloadable_link_{{id}}_sample_file-install-flash" style="display:none">'+
-                            '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                        '</div>'+
-                    '</div>'+
                     '<div class="clear"></div>'+
                 '</div>'+
             '</div>'+
@@ -161,17 +159,14 @@ var linkTemplate = '<tr>'+
     '</td>'+
     '<td>'+
         '<div class="files">'+
-            '<div class="row">'+
-                '<label for="downloadable_link_{{id}}_file_type"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_link_{{id}}_file_type" name="downloadable[link][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
+            '<div class="row a-right">'+
+                '<label for="downloadable_link_{{id}}_file_type" class="a-left"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_link_{{id}}_file_type" name="downloadable[link][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
             '<input type="hidden" class="validate-downloadable-file" id="downloadable_link_{{id}}_file_save" name="downloadable[link][{{id}}][file]" value="{{file_save}}" />'+
-                '<div id="downloadable_link_{{id}}_file" class="uploader">'+
+                '<?php echo $this->getBrowseButtonHtml(); ?>'+
+                '<?php echo $this->getDeleteButtonHtml(); ?>'+
+                '<div id="downloadable_link_{{id}}_file" class="uploader a-left">'+
                     '<div id="downloadable_link_{{id}}_file-old" class="file-row-info"></div>'+
                     '<div id="downloadable_link_{{id}}_file-new" class="file-row-info new-file"></div>'+
-                    '<div class="buttons">'+
-                        '<div id="downloadable_link_{{id}}_file-install-flash" style="display:none">'+
-                            '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                        '</div>'+
-                    '</div>'+
                     '<div class="clear"></div>'+
                 '</div>'+
             '</div>'+
@@ -282,6 +277,9 @@ var linkItems = {
         if (!data.sample_file_save) {
             data.sample_file_save = [];
         }
+        var UploaderConfigLinkSamples = <?php echo $this->getConfigJson('link_samples') ?>.replace(
+            new RegExp('<?php echo $this->getId(); ?>', 'g'),
+            'downloadable_link_'+data.id+'_sample_file');
 
         // link sample file
         new Downloadable.FileUploader(
@@ -291,8 +289,12 @@ var linkItems = {
             'downloadable[link]['+data.id+'][sample]',
             data.sample_file_save,
             'downloadable_link_'+data.id+'_sample_file',
-            <?php echo $this->getConfigJson('link_samples') ?>
+            UploaderConfigLinkSamples
         );
+
+        var UploaderConfigLink = <?php echo $this->getConfigJson() ?>.replace(
+            new RegExp('<?php echo $this->getId(); ?>', 'g'),
+            'downloadable_link_'+data.id+'_file');
         // link file
         new Downloadable.FileUploader(
             'links',
@@ -301,7 +303,7 @@ var linkItems = {
             'downloadable[link]['+data.id+']',
             data.file_save,
             'downloadable_link_'+data.id+'_file',
-            <?php echo $this->getConfigJson() ?>
+            UploaderConfigLink
         );
 
         linkFile = $('downloadable_link_'+data.id+'_file_type');
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml
index d1ca90e..41fae8c 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml
@@ -27,6 +27,7 @@
 <?php
 /**
  * @see Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Samples
+ * @var $this Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Samples
  */
 ?>
 
@@ -89,17 +90,14 @@ var sampleTemplate = '<tr>'+
                         '</td>'+
                         '<td>'+
                             '<div class="files-wide">'+
-                                '<div class="row">'+
-                                    '<label for="downloadable_sample_{{id}}_file_type"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_sample_{{id}}_file_type" name="downloadable[sample][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
+                                '<div class="row a-right">'+
+                                    '<label for="downloadable_sample_{{id}}_file_type" class="a-left"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_sample_{{id}}_file_type" name="downloadable[sample][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
                                     '<input type="hidden" class="validate-downloadable-file" id="downloadable_sample_{{id}}_file_save" name="downloadable[sample][{{id}}][file]" value="{{file_save}}" />'+
-                                    '<div id="downloadable_sample_{{id}}_file" class="uploader">'+
+                                    '<?php echo $this->getBrowseButtonHtml(); ?>'+
+                                    '<?php echo $this->getDeleteButtonHtml(); ?>'+
+                                    '<div id="downloadable_sample_{{id}}_file" class="uploader a-left">' +
                                         '<div id="downloadable_sample_{{id}}_file-old" class="file-row-info"></div>'+
                                         '<div id="downloadable_sample_{{id}}_file-new" class="file-row-info new-file"></div>'+
-                                        '<div class="buttons">'+
-                                            '<div id="downloadable_sample_{{id}}_file-install-flash" style="display:none">'+
-                                                '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                                            '</div>'+
-                                        '</div>'+
                                         '<div class="clear"></div>'+
                                     '</div>'+
                                 '</div>'+
@@ -161,6 +159,10 @@ var sampleItems = {
 
         sampleUrl = $('downloadable_sample_'+data.id+'_url_type');
 
+        var UploaderConfig = <?php echo $this->getConfigJson() ?>.replace(
+            new RegExp('<?php echo $this->getId(); ?>', 'g'),
+            'downloadable_sample_'+data.id+'_file');
+
         if (!data.file_save) {
             data.file_save = [];
         }
@@ -171,7 +173,7 @@ var sampleItems = {
             'downloadable[sample]['+data.id+']',
             data.file_save,
             'downloadable_sample_'+data.id+'_file',
-            <?php echo $this->getConfigJson() ?>
+            UploaderConfig
         );
         sampleUrl.advaiceContainer = 'downloadable_sample_'+data.id+'_container';
         sampleFile = $('downloadable_sample_'+data.id+'_file_type');
diff --git app/design/adminhtml/default/default/template/media/uploader.phtml app/design/adminhtml/default/default/template/media/uploader.phtml
index 3f58ce9..9a7f4c6 100644
--- app/design/adminhtml/default/default/template/media/uploader.phtml
+++ app/design/adminhtml/default/default/template/media/uploader.phtml
@@ -26,48 +26,30 @@
 ?>
 <?php
 /**
- * @see Mage_Adminhtml_Block_Media_Uploader
+ * @var $this Mage_Uploader_Block_Multiple|Mage_Uploader_Block_Single
  */
 ?>
-
-<?php echo $this->helper('adminhtml/js')->includeScript('lib/flex.js') ?>
-<?php echo $this->helper('adminhtml/js')->includeScript('mage/adminhtml/flexuploader.js') ?>
-<?php echo $this->helper('adminhtml/js')->includeScript('lib/FABridge.js') ?>
-
 <div id="<?php echo $this->getHtmlId() ?>" class="uploader">
-    <div class="buttons">
-        <?php /* buttons included in flex object */ ?>
-        <?php  /*echo $this->getBrowseButtonHtml()*/  ?>
-        <?php  /*echo $this->getUploadButtonHtml()*/  ?>
-        <div id="<?php echo $this->getHtmlId() ?>-install-flash" style="display:none">
-            <?php echo Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/') ?>
-        </div>
+    <div class="buttons a-right">
+        <?php echo $this->getBrowseButtonHtml(); ?>
+        <?php echo $this->getUploadButtonHtml(); ?>
     </div>
-    <div class="clear"></div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template">
-        <div id="{{id}}" class="file-row">
-        <span class="file-info">{{name}} ({{size}})</span>
+</div>
+<div class="no-display" id="<?php echo $this->getElementId('template') ?>">
+    <div id="{{id}}-container" class="file-row">
+        <span class="file-info">{{name}} {{size}}</span>
         <span class="delete-button"><?php echo $this->getDeleteButtonHtml() ?></span>
         <span class="progress-text"></span>
         <div class="clear"></div>
-        </div>
-    </div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template-progress">
-        {{percent}}% {{uploaded}} / {{total}}
     </div>
 </div>
-
 <script type="text/javascript">
-//<![CDATA[
-
-var maxUploadFileSizeInBytes = <?php echo $this->getDataMaxSizeInBytes() ?>;
-var maxUploadFileSize = '<?php echo $this->getDataMaxSize() ?>';
-
-<?php echo $this->getJsObjectName() ?> = new Flex.Uploader('<?php echo $this->getHtmlId() ?>', '<?php echo $this->getUploaderUrl('media/uploader.swf') ?>', <?php echo $this->getConfigJson() ?>);
-
-if (varienGlobalEvents) {
-    varienGlobalEvents.attachEventHandler('tabChangeBefore', <?php echo $this->getJsObjectName() ?>.onContainerHideBefore);
-}
+    (function() {
+        var uploader = new Uploader(<?php echo $this->getJsonConfig(); ?>);
 
-//]]>
+        if (varienGlobalEvents) {
+            varienGlobalEvents.attachEventHandler('tabChangeBefore', uploader.onContainerHideBefore);
+        }
+    })();
 </script>
+<?php echo $this->getChildHtml('additional_scripts'); ?>
diff --git app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design.phtml app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design.phtml
index 625aa9b..fefc962 100644
--- app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design.phtml
+++ app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design.phtml
@@ -24,19 +24,22 @@
  * @license     http://opensource.org/licenses/afl-3.0.php  Academic Free License (AFL 3.0)
  */
 ?>
+<?php
+/**
+ * @var $this Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design
+ */
+?>
 <script type="text/javascript">
 // <![CDATA[
 var imageTemplate = '<input type="hidden" name="{{file_field}}[image][{{id}}][image_id]" value="{{image_id}}" />'+
         '<div class="banner-image">'+
-            '<div class="row">'+
-                '<div id="{{file_field}}_{{id}}_file" class="uploader">'+
+            '<div class="row a-right">' +
+                '<div class="flex">' +
+                '<?php echo $this->getBrowseButtonHtml() ?>'+
+                '</div>' +
+                '<div id="{{file_field}}_{{id}}_file" class="uploader a-left">'+
                     '<div id="{{file_field}}_{{id}}_file-old" class="file-row-info"><div id="{{file_field}}_preview_{{id}}" style="background:url({{thumbnail}}) no-repeat center;" class="image-placeholder"></div></div>'+
                     '<div id="{{file_field}}_{{id}}_file-new" class="file-row-info new-file"></div>'+
-                    '<div class="buttons">'+
-                        '<div id="{{file_field}}_{{id}}_file-install-flash" style="display:none">'+
-                            '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                        '</div>'+
-                    '</div>'+
                     '<div class="clear"></div>'+
                 '</div>'+
             '</div>'+
@@ -66,6 +69,16 @@ var imageItems = {
     imageActionTruncateLenght: 35,
     add : function(config) {
         try {
+            if(Object.isString(config)) {
+                config = config.evalJSON();
+            }
+            config.file_field = config.uploaderConfig.fileParameterName;
+            config.file_save = config.miscConfig.file_save;
+            config.thumbnail = config.miscConfig.thumbnail;
+            config.image_id = config.miscConfig.image_id;
+            config.image_action_data = config.miscConfig.image_action_data;
+            config.image_count = config.miscConfig.image_count;
+
             var isUploadedImage = true, uploaderClass = '';
             this.template = new Template(this.templateText, this.templateSyntax);
 
@@ -89,7 +102,11 @@ var imageItems = {
             Element.insert(this.ulImages.down('li', config.id), {'bottom' : this.template.evaluate(config)});
             var container = $(config.file_field + '_' + config.id + '_file').up('li');
 
-            if (config.show_uploader == 1) {
+            if (config.image_id != 'uploader') {
+                container.down('.flex').remove();
+                imageItems.addEditButton(container, config);
+                imageItems.addDeleteButton(container, config);
+            } else {
                 config.file_save = [];
 
                 new Downloadable.FileUploader(
@@ -102,11 +119,6 @@ var imageItems = {
                     config
                 );
             }
-
-            if (config.image_id != 'uploader') {
-                imageItems.addEditButton(container, config);
-                imageItems.addDeleteButton(container, config);
-            }
         } catch (e) {
             alert(e.message);
         }
@@ -209,7 +221,10 @@ var imageItems = {
     },
     reloadImages : function(image_list) {
         try {
-            var imageType = image_list[0].file_field;
+            image_list = image_list.map(function (item) {
+                return Object.isString(item) ? item.evalJSON(): item;
+            });
+            var imageType = image_list[0].uploaderConfig.fileParameterName;
             Downloadable.unsetUploaderByType(imageType);
             var currentContainerId = imageType;
             var currentContainer = $(currentContainerId);
@@ -283,28 +298,18 @@ var imageItems = {
 
 jscolor.dir = '<?php echo $this->getJsUrl(); ?>jscolor/';
 
-var maxUploadFileSizeInBytes = <?php echo $this->getChild('media_uploader')->getDataMaxSizeInBytes() ?>;
-var maxUploadFileSize = '<?php echo $this->getChild('media_uploader')->getDataMaxSize() ?>';
-
 var uploaderTemplate = '<div class="no-display" id="[[idName]]-template">' +
-                            '<div id="{{id}}" class="file-row file-row-narrow">' +
+                            '<div id="{{id}}-container" class="file-row file-row-narrow">' +
                                 '<span class="file-info">' +
                                     '<span class="file-info-name">{{name}}</span>' + ' ' +
-                                    '<span class="file-info-size">({{size}})</span>' +
+                                    '<span class="file-info-size">{{size}}</span>' +
                                 '</span>' +
                                 '<span class="progress-text"></span>' +
                                 '<div class="clear"></div>' +
                             '</div>' +
-                        '</div>' +
-                        '<div class="no-display" id="[[idName]]-template-progress">' +
-                            '{{percent}}% {{uploaded}} / {{total}}' +
                         '</div>';
 
-var fileListTemplate = '<div style="background:url({{file}}) no-repeat center;" class="image-placeholder"></div>' +
-                        '<span class="file-info">' +
-                            '<span class="file-info-name">{{name}}</span>' + ' ' +
-                            '<span class="file-info-size">({{size}})</span>' +
-                        '</span>';
+var fileListTemplate = '<div style="background:url({{file}}) no-repeat center;" class="image-placeholder"></div>';
 
 var Downloadable = {
     uploaderObj : $H({}),
@@ -401,13 +406,17 @@ Downloadable.FileUploader.prototype = {
         if ($(this.idName + '_save')) {
             $(this.idName + '_save').value = this.fileValue.toJSON ? this.fileValue.toJSON() : Object.toJSON(this.fileValue);
         }
+
+        this.config = Object.toJSON(this.config).replace(
+            new RegExp(config.elementIds.idToReplace, 'g'),
+            config.file_field + '_'+ config.id + '_file').evalJSON();
+
         Downloadable.setUploaderObj(
             this.type,
             this.key,
-            new Flex.Uploader(this.idName, '<?php echo $this->getSkinUrl('media/uploaderSingle.swf') ?>', this.config)
+            new Uploader(this.config)
         );
         new Downloadable.FileList(this.idName, Downloadable.getUploaderObj(type, key), this.config);
-
         if (varienGlobalEvents) {
             varienGlobalEvents.attachEventHandler('tabChangeBefore', Downloadable.getUploaderObj(type, key).onContainerHideBefore);
         }
@@ -427,35 +436,34 @@ Downloadable.FileList.prototype = {
         this.containerId  = containerId,
         this.container = $(this.containerId);
         this.uploader = uploader;
-        this.uploader.onFilesComplete = this.handleUploadComplete.bind(this);
+        this.uploader.uploader.on('filesSubmitted', this.handleFileSelect.bind(this));
+        document.on('uploader:fileSuccess', function(event) {
+            var memo = event.memo;
+            if(this._checkCurrentContainer(memo.containerId)) {
+                this.handleUploadComplete([{response: memo.response}]);
+            }
+        }.bind(this));
         this.file = this.getElement('save').value.evalJSON();
         this.listTemplate = new Template(this.fileListTemplate, this.templatePattern);
         this.updateFiles();
-        this.uploader.handleSelect = this.handleFileSelect.bind(this);
-        this.uploader.onContainerHideBefore = this.handleContainerHideBefore.bind(this);
         this.uploader.config = config;
-    },
-    handleContainerHideBefore: function(container) {
-        if (container && Element.descendantOf(this.uploader.container, container) && !this.uploader.checkAllComplete()) {
-            if (!confirm('<?php echo $this->jsQuoteEscape($this->__('There are files that were selected but not uploaded yet. After switching to another tab your selections may be lost. Do you wish to continue ?')) ;?>')) {
-                return 'cannotchange';
-            } else {
+        this.onContainerHideBefore = this.uploader.onContainerHideBefore.bind(
+            this.uploader,
+            function () {
                 return 'change';
-            }
-        }
+            });
+    },
+    _checkCurrentContainer: function (child) {
+        return $(this.containerId).down('#' + child);
     },
     handleFileSelect: function(event) {
         try {
-            this.uploader.files = event.getData().files;
-            this.uploader.checkFileSize();
-            this.updateFiles();
-            if (!hasTooBigFiles) {
-                var uploaderList = $(this.uploader.flexContainerId);
-                for (i = 0; i < uploaderList.length; i++) {
-                    uploaderList[i].setStyle({visibility: 'hidden'});
-                }
-                Downloadable.massUploadByType(this.uploader.config.file_field);
+            if(this.uploader.uploader.files.length) {
+                $(this.containerId + '-old').hide();
+                this.uploader.elements.browse.invoke('setStyle', {'visibility': 'hidden'});
             }
+            this.updateFiles();
+            Downloadable.massUploadByType(this.uploader.config.file_field);
         } catch (e) {
             alert(e.message);
         }
@@ -485,7 +493,6 @@ Downloadable.FileList.prototype = {
                 newFile.size = response.size;
                 newFile.status = 'new';
                 this.file[0] = newFile;
-                this.uploader.removeFile(item.id);
                 imageItems.reloadImages(response.image_list);
             }.bind(this));
             this.updateFiles();
diff --git app/etc/modules/Mage_All.xml app/etc/modules/Mage_All.xml
index 4da57f3..826e97e 100644
--- app/etc/modules/Mage_All.xml
+++ app/etc/modules/Mage_All.xml
@@ -275,7 +275,7 @@
             <active>true</active>
             <codePool>core</codePool>
             <depends>
-                <Mage_Core/>
+                <Mage_Uploader/>
             </depends>
         </Mage_Cms>
         <Mage_Reports>
@@ -397,5 +397,12 @@
                 <Mage_Core/>
             </depends>
         </Mage_Index>
+        <Mage_Uploader>
+            <active>true</active>
+            <codePool>core</codePool>
+            <depends>
+                <Mage_Core/>
+            </depends>
+        </Mage_Uploader>
     </modules>
 </config>
diff --git app/locale/en_US/Mage_Media.csv app/locale/en_US/Mage_Media.csv
index 110331b..504a44a 100644
--- app/locale/en_US/Mage_Media.csv
+++ app/locale/en_US/Mage_Media.csv
@@ -1,3 +1,2 @@
 "An error occurred while creating the image.","An error occurred while creating the image."
 "The image does not exist or is invalid.","The image does not exist or is invalid."
-"This content requires last version of Adobe Flash Player. <a href=""%s"">Get Flash</a>","This content requires last version of Adobe Flash Player. <a href=""%s"">Get Flash</a>"
diff --git app/locale/en_US/Mage_Uploader.csv app/locale/en_US/Mage_Uploader.csv
new file mode 100644
index 0000000..c246b24
--- /dev/null
+++ app/locale/en_US/Mage_Uploader.csv
@@ -0,0 +1,8 @@
+"Browse Files...","Browse Files..."
+"Upload Files","Upload Files"
+"Remove", "Remove"
+"There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?", "There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?"
+"Maximum allowed file size for upload is","Maximum allowed file size for upload is"
+"Please check your server PHP settings.","Please check your server PHP settings."
+"Uploading...","Uploading..."
+"Complete","Complete"
\ No newline at end of file
diff --git downloader/lib/Mage/HTTP/Client/Curl.php downloader/lib/Mage/HTTP/Client/Curl.php
index e38c29a..5c474ec 100644
--- downloader/lib/Mage/HTTP/Client/Curl.php
+++ downloader/lib/Mage/HTTP/Client/Curl.php
@@ -373,7 +373,7 @@ implements Mage_HTTP_IClient
         $uriModified = $this->getModifiedUri($uri, $https);
         $this->_ch = curl_init();
         $this->curlOption(CURLOPT_URL, $uriModified);
-        $this->curlOption(CURLOPT_SSL_VERIFYPEER, false);
+        $this->curlOption(CURLOPT_SSL_VERIFYPEER, true);
         $this->curlOption(CURLOPT_SSL_CIPHER_LIST, 'TLSv1');
         $this->getCurlMethodSettings($method, $params, $isAuthorizationRequired);
 
diff --git js/lib/uploader/flow.min.js js/lib/uploader/flow.min.js
new file mode 100644
index 0000000..34b888e
--- /dev/null
+++ js/lib/uploader/flow.min.js
@@ -0,0 +1,2 @@
+/*! flow.js 2.9.0 */
+!function(a,b,c){"use strict";function d(b){if(this.support=!("undefined"==typeof File||"undefined"==typeof Blob||"undefined"==typeof FileList||!Blob.prototype.slice&&!Blob.prototype.webkitSlice&&!Blob.prototype.mozSlice),this.support){this.supportDirectory=/WebKit/.test(a.navigator.userAgent),this.files=[],this.defaults={chunkSize:1048576,forceChunkSize:!1,simultaneousUploads:3,singleFile:!1,fileParameterName:"file",progressCallbacksInterval:500,speedSmoothingFactor:.1,query:{},headers:{},withCredentials:!1,preprocess:null,method:"multipart",testMethod:"GET",uploadMethod:"POST",prioritizeFirstAndLastChunk:!1,target:"/",testChunks:!0,generateUniqueIdentifier:null,maxChunkRetries:0,chunkRetryInterval:null,permanentErrors:[404,415,500,501],successStatuses:[200,201,202],onDropStopPropagation:!1},this.opts={},this.events={};var c=this;this.onDrop=function(a){c.opts.onDropStopPropagation&&a.stopPropagation(),a.preventDefault();var b=a.dataTransfer;b.items&&b.items[0]&&b.items[0].webkitGetAsEntry?c.webkitReadDataTransfer(a):c.addFiles(b.files,a)},this.preventEvent=function(a){a.preventDefault()},this.opts=d.extend({},this.defaults,b||{})}}function e(a,b){this.flowObj=a,this.file=b,this.name=b.fileName||b.name,this.size=b.size,this.relativePath=b.relativePath||b.webkitRelativePath||this.name,this.uniqueIdentifier=a.generateUniqueIdentifier(b),this.chunks=[],this.paused=!1,this.error=!1,this.averageSpeed=0,this.currentSpeed=0,this._lastProgressCallback=Date.now(),this._prevUploadedSize=0,this._prevProgress=0,this.bootstrap()}function f(a,b,c){this.flowObj=a,this.fileObj=b,this.fileObjSize=b.size,this.offset=c,this.tested=!1,this.retries=0,this.pendingRetry=!1,this.preprocessState=0,this.loaded=0,this.total=0;var d=this.flowObj.opts.chunkSize;this.startByte=this.offset*d,this.endByte=Math.min(this.fileObjSize,(this.offset+1)*d),this.xhr=null,this.fileObjSize-this.endByte<d&&!this.flowObj.opts.forceChunkSize&&(this.endByte=this.fileObjSize);var e=this;this.event=function(a,b){b=Array.prototype.slice.call(arguments),b.unshift(e),e.fileObj.chunkEvent.apply(e.fileObj,b)},this.progressHandler=function(a){a.lengthComputable&&(e.loaded=a.loaded,e.total=a.total),e.event("progress",a)},this.testHandler=function(){var a=e.status(!0);"error"===a?(e.event(a,e.message()),e.flowObj.uploadNextChunk()):"success"===a?(e.tested=!0,e.event(a,e.message()),e.flowObj.uploadNextChunk()):e.fileObj.paused||(e.tested=!0,e.send())},this.doneHandler=function(){var a=e.status();if("success"===a||"error"===a)e.event(a,e.message()),e.flowObj.uploadNextChunk();else{e.event("retry",e.message()),e.pendingRetry=!0,e.abort(),e.retries++;var b=e.flowObj.opts.chunkRetryInterval;null!==b?setTimeout(function(){e.send()},b):e.send()}}}function g(a,b){var c=a.indexOf(b);c>-1&&a.splice(c,1)}function h(a,b){return"function"==typeof a&&(b=Array.prototype.slice.call(arguments),a=a.apply(null,b.slice(1))),a}function i(a,b){setTimeout(a.bind(b),0)}function j(a){return k(arguments,function(b){b!==a&&k(b,function(b,c){a[c]=b})}),a}function k(a,b,c){if(a){var d;if("undefined"!=typeof a.length){for(d=0;d<a.length;d++)if(b.call(c,a[d],d)===!1)return}else for(d in a)if(a.hasOwnProperty(d)&&b.call(c,a[d],d)===!1)return}}var l=a.navigator.msPointerEnabled;d.prototype={on:function(a,b){a=a.toLowerCase(),this.events.hasOwnProperty(a)||(this.events[a]=[]),this.events[a].push(b)},off:function(a,b){a!==c?(a=a.toLowerCase(),b!==c?this.events.hasOwnProperty(a)&&g(this.events[a],b):delete this.events[a]):this.events={}},fire:function(a,b){b=Array.prototype.slice.call(arguments),a=a.toLowerCase();var c=!1;return this.events.hasOwnProperty(a)&&k(this.events[a],function(a){c=a.apply(this,b.slice(1))===!1||c},this),"catchall"!=a&&(b.unshift("catchAll"),c=this.fire.apply(this,b)===!1||c),!c},webkitReadDataTransfer:function(a){function b(a){g+=a.length,k(a,function(a){if(a.isFile){var e=a.fullPath;a.file(function(a){c(a,e)},d)}else a.isDirectory&&a.createReader().readEntries(b,d)}),e()}function c(a,b){a.relativePath=b.substring(1),h.push(a),e()}function d(a){throw a}function e(){0==--g&&f.addFiles(h,a)}var f=this,g=a.dataTransfer.items.length,h=[];k(a.dataTransfer.items,function(a){var f=a.webkitGetAsEntry();return f?void(f.isFile?c(a.getAsFile(),f.fullPath):f.createReader().readEntries(b,d)):void e()})},generateUniqueIdentifier:function(a){var b=this.opts.generateUniqueIdentifier;if("function"==typeof b)return b(a);var c=a.relativePath||a.webkitRelativePath||a.fileName||a.name;return a.size+"-"+c.replace(/[^0-9a-zA-Z_-]/gim,"")},uploadNextChunk:function(a){var b=!1;if(this.opts.prioritizeFirstAndLastChunk&&(k(this.files,function(a){return!a.paused&&a.chunks.length&&"pending"===a.chunks[0].status()&&0===a.chunks[0].preprocessState?(a.chunks[0].send(),b=!0,!1):!a.paused&&a.chunks.length>1&&"pending"===a.chunks[a.chunks.length-1].status()&&0===a.chunks[0].preprocessState?(a.chunks[a.chunks.length-1].send(),b=!0,!1):void 0}),b))return b;if(k(this.files,function(a){return a.paused||k(a.chunks,function(a){return"pending"===a.status()&&0===a.preprocessState?(a.send(),b=!0,!1):void 0}),b?!1:void 0}),b)return!0;var c=!1;return k(this.files,function(a){return a.isComplete()?void 0:(c=!0,!1)}),c||a||i(function(){this.fire("complete")},this),!1},assignBrowse:function(a,c,d,e){"undefined"==typeof a.length&&(a=[a]),k(a,function(a){var f;"INPUT"===a.tagName&&"file"===a.type?f=a:(f=b.createElement("input"),f.setAttribute("type","file"),j(f.style,{visibility:"hidden",position:"absolute"}),a.appendChild(f),a.addEventListener("click",function(){f.click()},!1)),this.opts.singleFile||d||f.setAttribute("multiple","multiple"),c&&f.setAttribute("webkitdirectory","webkitdirectory"),k(e,function(a,b){f.setAttribute(b,a)});var g=this;f.addEventListener("change",function(a){g.addFiles(a.target.files,a),a.target.value=""},!1)},this)},assignDrop:function(a){"undefined"==typeof a.length&&(a=[a]),k(a,function(a){a.addEventListener("dragover",this.preventEvent,!1),a.addEventListener("dragenter",this.preventEvent,!1),a.addEventListener("drop",this.onDrop,!1)},this)},unAssignDrop:function(a){"undefined"==typeof a.length&&(a=[a]),k(a,function(a){a.removeEventListener("dragover",this.preventEvent),a.removeEventListener("dragenter",this.preventEvent),a.removeEventListener("drop",this.onDrop)},this)},isUploading:function(){var a=!1;return k(this.files,function(b){return b.isUploading()?(a=!0,!1):void 0}),a},_shouldUploadNext:function(){var a=0,b=!0,c=this.opts.simultaneousUploads;return k(this.files,function(d){k(d.chunks,function(d){return"uploading"===d.status()&&(a++,a>=c)?(b=!1,!1):void 0})}),b&&a},upload:function(){var a=this._shouldUploadNext();if(a!==!1){this.fire("uploadStart");for(var b=!1,c=1;c<=this.opts.simultaneousUploads-a;c++)b=this.uploadNextChunk(!0)||b;b||i(function(){this.fire("complete")},this)}},resume:function(){k(this.files,function(a){a.resume()})},pause:function(){k(this.files,function(a){a.pause()})},cancel:function(){for(var a=this.files.length-1;a>=0;a--)this.files[a].cancel()},progress:function(){var a=0,b=0;return k(this.files,function(c){a+=c.progress()*c.size,b+=c.size}),b>0?a/b:0},addFile:function(a,b){this.addFiles([a],b)},addFiles:function(a,b){var c=[];k(a,function(a){if((!l||l&&a.size>0)&&(a.size%4096!==0||"."!==a.name&&"."!==a.fileName)&&!this.getFromUniqueIdentifier(this.generateUniqueIdentifier(a))){var d=new e(this,a);this.fire("fileAdded",d,b)&&c.push(d)}},this),this.fire("filesAdded",c,b)&&k(c,function(a){this.opts.singleFile&&this.files.length>0&&this.removeFile(this.files[0]),this.files.push(a)},this),this.fire("filesSubmitted",c,b)},removeFile:function(a){for(var b=this.files.length-1;b>=0;b--)this.files[b]===a&&(this.files.splice(b,1),a.abort())},getFromUniqueIdentifier:function(a){var b=!1;return k(this.files,function(c){c.uniqueIdentifier===a&&(b=c)}),b},getSize:function(){var a=0;return k(this.files,function(b){a+=b.size}),a},sizeUploaded:function(){var a=0;return k(this.files,function(b){a+=b.sizeUploaded()}),a},timeRemaining:function(){var a=0,b=0;return k(this.files,function(c){c.paused||c.error||(a+=c.size-c.sizeUploaded(),b+=c.averageSpeed)}),a&&!b?Number.POSITIVE_INFINITY:a||b?Math.floor(a/b):0}},e.prototype={measureSpeed:function(){var a=Date.now()-this._lastProgressCallback;if(a){var b=this.flowObj.opts.speedSmoothingFactor,c=this.sizeUploaded();this.currentSpeed=Math.max((c-this._prevUploadedSize)/a*1e3,0),this.averageSpeed=b*this.currentSpeed+(1-b)*this.averageSpeed,this._prevUploadedSize=c}},chunkEvent:function(a,b,c){switch(b){case"progress":if(Date.now()-this._lastProgressCallback<this.flowObj.opts.progressCallbacksInterval)break;this.measureSpeed(),this.flowObj.fire("fileProgress",this,a),this.flowObj.fire("progress"),this._lastProgressCallback=Date.now();break;case"error":this.error=!0,this.abort(!0),this.flowObj.fire("fileError",this,c,a),this.flowObj.fire("error",c,this,a);break;case"success":if(this.error)return;this.measureSpeed(),this.flowObj.fire("fileProgress",this,a),this.flowObj.fire("progress"),this._lastProgressCallback=Date.now(),this.isComplete()&&(this.currentSpeed=0,this.averageSpeed=0,this.flowObj.fire("fileSuccess",this,c,a));break;case"retry":this.flowObj.fire("fileRetry",this,a)}},pause:function(){this.paused=!0,this.abort()},resume:function(){this.paused=!1,this.flowObj.upload()},abort:function(a){this.currentSpeed=0,this.averageSpeed=0;var b=this.chunks;a&&(this.chunks=[]),k(b,function(a){"uploading"===a.status()&&(a.abort(),this.flowObj.uploadNextChunk())},this)},cancel:function(){this.flowObj.removeFile(this)},retry:function(){this.bootstrap(),this.flowObj.upload()},bootstrap:function(){this.abort(!0),this.error=!1,this._prevProgress=0;for(var a=this.flowObj.opts.forceChunkSize?Math.ceil:Math.floor,b=Math.max(a(this.file.size/this.flowObj.opts.chunkSize),1),c=0;b>c;c++)this.chunks.push(new f(this.flowObj,this,c))},progress:function(){if(this.error)return 1;if(1===this.chunks.length)return this._prevProgress=Math.max(this._prevProgress,this.chunks[0].progress()),this._prevProgress;var a=0;k(this.chunks,function(b){a+=b.progress()*(b.endByte-b.startByte)});var b=a/this.size;return this._prevProgress=Math.max(this._prevProgress,b>.9999?1:b),this._prevProgress},isUploading:function(){var a=!1;return k(this.chunks,function(b){return"uploading"===b.status()?(a=!0,!1):void 0}),a},isComplete:function(){var a=!1;return k(this.chunks,function(b){var c=b.status();return"pending"===c||"uploading"===c||1===b.preprocessState?(a=!0,!1):void 0}),!a},sizeUploaded:function(){var a=0;return k(this.chunks,function(b){a+=b.sizeUploaded()}),a},timeRemaining:function(){if(this.paused||this.error)return 0;var a=this.size-this.sizeUploaded();return a&&!this.averageSpeed?Number.POSITIVE_INFINITY:a||this.averageSpeed?Math.floor(a/this.averageSpeed):0},getType:function(){return this.file.type&&this.file.type.split("/")[1]},getExtension:function(){return this.name.substr((~-this.name.lastIndexOf(".")>>>0)+2).toLowerCase()}},f.prototype={getParams:function(){return{flowChunkNumber:this.offset+1,flowChunkSize:this.flowObj.opts.chunkSize,flowCurrentChunkSize:this.endByte-this.startByte,flowTotalSize:this.fileObjSize,flowIdentifier:this.fileObj.uniqueIdentifier,flowFilename:this.fileObj.name,flowRelativePath:this.fileObj.relativePath,flowTotalChunks:this.fileObj.chunks.length}},getTarget:function(a,b){return a+=a.indexOf("?")<0?"?":"&",a+b.join("&")},test:function(){this.xhr=new XMLHttpRequest,this.xhr.addEventListener("load",this.testHandler,!1),this.xhr.addEventListener("error",this.testHandler,!1);var a=h(this.flowObj.opts.testMethod,this.fileObj,this),b=this.prepareXhrRequest(a,!0);this.xhr.send(b)},preprocessFinished:function(){this.preprocessState=2,this.send()},send:function(){var a=this.flowObj.opts.preprocess;if("function"==typeof a)switch(this.preprocessState){case 0:return this.preprocessState=1,void a(this);case 1:return}if(this.flowObj.opts.testChunks&&!this.tested)return void this.test();this.loaded=0,this.total=0,this.pendingRetry=!1;var b=this.fileObj.file.slice?"slice":this.fileObj.file.mozSlice?"mozSlice":this.fileObj.file.webkitSlice?"webkitSlice":"slice",c=this.fileObj.file[b](this.startByte,this.endByte,this.fileObj.file.type);this.xhr=new XMLHttpRequest,this.xhr.upload.addEventListener("progress",this.progressHandler,!1),this.xhr.addEventListener("load",this.doneHandler,!1),this.xhr.addEventListener("error",this.doneHandler,!1);var d=h(this.flowObj.opts.uploadMethod,this.fileObj,this),e=this.prepareXhrRequest(d,!1,this.flowObj.opts.method,c);this.xhr.send(e)},abort:function(){var a=this.xhr;this.xhr=null,a&&a.abort()},status:function(a){return this.pendingRetry||1===this.preprocessState?"uploading":this.xhr?this.xhr.readyState<4?"uploading":this.flowObj.opts.successStatuses.indexOf(this.xhr.status)>-1?"success":this.flowObj.opts.permanentErrors.indexOf(this.xhr.status)>-1||!a&&this.retries>=this.flowObj.opts.maxChunkRetries?"error":(this.abort(),"pending"):"pending"},message:function(){return this.xhr?this.xhr.responseText:""},progress:function(){if(this.pendingRetry)return 0;var a=this.status();return"success"===a||"error"===a?1:"pending"===a?0:this.total>0?this.loaded/this.total:0},sizeUploaded:function(){var a=this.endByte-this.startByte;return"success"!==this.status()&&(a=this.progress()*a),a},prepareXhrRequest:function(a,b,c,d){var e=h(this.flowObj.opts.query,this.fileObj,this,b);e=j(this.getParams(),e);var f=h(this.flowObj.opts.target,this.fileObj,this,b),g=null;if("GET"===a||"octet"===c){var i=[];k(e,function(a,b){i.push([encodeURIComponent(b),encodeURIComponent(a)].join("="))}),f=this.getTarget(f,i),g=d||null}else g=new FormData,k(e,function(a,b){g.append(b,a)}),g.append(this.flowObj.opts.fileParameterName,d,this.fileObj.file.name);return this.xhr.open(a,f,!0),this.xhr.withCredentials=this.flowObj.opts.withCredentials,k(h(this.flowObj.opts.headers,this.fileObj,this,b),function(a,b){this.xhr.setRequestHeader(b,a)},this),g}},d.evalOpts=h,d.extend=j,d.each=k,d.FlowFile=e,d.FlowChunk=f,d.version="2.9.0","object"==typeof module&&module&&"object"==typeof module.exports?module.exports=d:(a.Flow=d,"function"==typeof define&&define.amd&&define("flow",[],function(){return d}))}(window,document);
\ No newline at end of file
diff --git js/lib/uploader/fusty-flow-factory.js js/lib/uploader/fusty-flow-factory.js
new file mode 100644
index 0000000..3d09bb0
--- /dev/null
+++ js/lib/uploader/fusty-flow-factory.js
@@ -0,0 +1,14 @@
+(function (Flow, FustyFlow, window) {
+  'use strict';
+
+  var fustyFlowFactory = function (opts) {
+    var flow = new Flow(opts);
+    if (flow.support) {
+      return flow;
+    }
+    return new FustyFlow(opts);
+  }
+
+  window.fustyFlowFactory = fustyFlowFactory;
+
+})(window.Flow, window.FustyFlow, window);
diff --git js/lib/uploader/fusty-flow.js js/lib/uploader/fusty-flow.js
new file mode 100644
index 0000000..4519a81
--- /dev/null
+++ js/lib/uploader/fusty-flow.js
@@ -0,0 +1,428 @@
+(function (Flow, window, document, undefined) {
+  'use strict';
+
+  var extend = Flow.extend;
+  var each = Flow.each;
+
+  function addEvent(element, type, handler) {
+    if (element.addEventListener) {
+      element.addEventListener(type, handler, false);
+    } else if (element.attachEvent) {
+      element.attachEvent("on" + type, handler);
+    } else {
+      element["on" + type] = handler;
+    }
+  }
+
+  function removeEvent(element, type, handler) {
+    if (element.removeEventListener) {
+      element.removeEventListener(type, handler, false);
+    } else if (element.detachEvent) {
+      element.detachEvent("on" + type, handler);
+    } else {
+      element["on" + type] = null;
+    }
+  }
+
+  function removeElement(element) {
+    element.parentNode.removeChild(element);
+  }
+
+  function isFunction(functionToCheck) {
+    var getType = {};
+    return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
+  }
+
+  /**
+   * Not resumable file upload library, for IE7-IE9 browsers
+   * @name FustyFlow
+   * @param [opts]
+   * @param {bool} [opts.singleFile]
+   * @param {string} [opts.fileParameterName]
+   * @param {Object|Function} [opts.query]
+   * @param {Object} [opts.headers]
+   * @param {string} [opts.target]
+   * @param {Function} [opts.generateUniqueIdentifier]
+   * @param {bool} [opts.matchJSON]
+   * @constructor
+   */
+  function FustyFlow(opts) {
+    // Shortcut of "r instanceof Flow"
+    this.support = false;
+
+    this.files = [];
+    this.events = [];
+    this.defaults = {
+      simultaneousUploads: 3,
+      fileParameterName: 'file',
+      query: {},
+      target: '/',
+      generateUniqueIdentifier: null,
+      matchJSON: false
+    };
+
+    var $ = this;
+
+    this.inputChangeEvent = function (event) {
+      var input = event.target || event.srcElement;
+      removeEvent(input, 'change', $.inputChangeEvent);
+      var newClone = input.cloneNode(false);
+      // change current input with new one
+      input.parentNode.replaceChild(newClone, input);
+      // old input will be attached to hidden form
+      $.addFile(input, event);
+      // reset new input
+      newClone.value = '';
+      addEvent(newClone, 'change', $.inputChangeEvent);
+    };
+
+    this.opts = Flow.extend({}, this.defaults, opts || {});
+  }
+
+  FustyFlow.prototype = {
+    on: Flow.prototype.on,
+    off: Flow.prototype.off,
+    fire: Flow.prototype.fire,
+    cancel: Flow.prototype.cancel,
+    assignBrowse: function (domNodes) {
+      if (typeof domNodes.length == 'undefined') {
+        domNodes = [domNodes];
+      }
+      each(domNodes, function (domNode) {
+        var input;
+        if (domNode.tagName === 'INPUT' && domNode.type === 'file') {
+          input = domNode;
+        } else {
+          input = document.createElement('input');
+          input.setAttribute('type', 'file');
+
+          extend(domNode.style, {
+            display: 'inline-block',
+            position: 'relative',
+            overflow: 'hidden',
+            verticalAlign: 'top'
+          });
+
+          extend(input.style, {
+            position: 'absolute',
+            top: 0,
+            right: 0,
+            fontFamily: 'Arial',
+            // 4 persons reported this, the max values that worked for them were 243, 236, 236, 118
+            fontSize: '118px',
+            margin: 0,
+            padding: 0,
+            opacity: 0,
+            filter: 'alpha(opacity=0)',
+            cursor: 'pointer'
+          });
+
+          domNode.appendChild(input);
+        }
+        // When new files are added, simply append them to the overall list
+        addEvent(input, 'change', this.inputChangeEvent);
+      }, this);
+    },
+    assignDrop: function () {
+      // not supported
+    },
+    unAssignDrop: function () {
+      // not supported
+    },
+    isUploading: function () {
+      var uploading = false;
+      each(this.files, function (file) {
+        if (file.isUploading()) {
+          uploading = true;
+          return false;
+        }
+      });
+      return uploading;
+    },
+    upload: function () {
+      // Kick off the queue
+      var files = 0;
+      each(this.files, function (file) {
+        if (file.progress() == 1 || file.isPaused()) {
+          return;
+        }
+        if (file.isUploading()) {
+          files++;
+          return;
+        }
+        if (files++ >= this.opts.simultaneousUploads) {
+          return false;
+        }
+        if (files == 1) {
+          this.fire('uploadStart');
+        }
+        file.send();
+      }, this);
+      if (!files) {
+        this.fire('complete');
+      }
+    },
+    pause: function () {
+      each(this.files, function (file) {
+        file.pause();
+      });
+    },
+    resume: function () {
+      each(this.files, function (file) {
+        file.resume();
+      });
+    },
+    progress: function () {
+      var totalDone = 0;
+      var totalFiles = 0;
+      each(this.files, function (file) {
+        totalDone += file.progress();
+        totalFiles++;
+      });
+      return totalFiles > 0 ? totalDone / totalFiles : 0;
+    },
+    addFiles: function (elementsList, event) {
+      var files = [];
+      each(elementsList, function (element) {
+        // is domElement ?
+        if (element.nodeType === 1 && element.value) {
+          var f = new FustyFlowFile(this, element);
+          if (this.fire('fileAdded', f, event)) {
+            files.push(f);
+          }
+        }
+      }, this);
+      if (this.fire('filesAdded', files, event)) {
+        each(files, function (file) {
+          if (this.opts.singleFile && this.files.length > 0) {
+            this.removeFile(this.files[0]);
+          }
+          this.files.push(file);
+        }, this);
+      }
+      this.fire('filesSubmitted', files, event);
+    },
+    addFile: function (file, event) {
+      this.addFiles([file], event);
+    },
+    generateUniqueIdentifier: function (element) {
+      var custom = this.opts.generateUniqueIdentifier;
+      if (typeof custom === 'function') {
+        return custom(element);
+      }
+      return 'xxxxxxxx-xxxx-yxxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
+        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
+        return v.toString(16);
+      });
+    },
+    getFromUniqueIdentifier: function (uniqueIdentifier) {
+      var ret = false;
+      each(this.files, function (f) {
+        if (f.uniqueIdentifier == uniqueIdentifier) ret = f;
+      });
+      return ret;
+    },
+    removeFile: function (file) {
+      for (var i = this.files.length - 1; i >= 0; i--) {
+        if (this.files[i] === file) {
+          this.files.splice(i, 1);
+        }
+      }
+    },
+    getSize: function () {
+      // undefined
+    },
+    timeRemaining: function () {
+      // undefined
+    },
+    sizeUploaded: function () {
+      // undefined
+    }
+  };
+
+  function FustyFlowFile(flowObj, element) {
+    this.flowObj = flowObj;
+    this.element = element;
+    this.name = element.value && element.value.replace(/.*(\/|\\)/, "");
+    this.relativePath = this.name;
+    this.uniqueIdentifier = flowObj.generateUniqueIdentifier(element);
+    this.iFrame = null;
+
+    this.finished = false;
+    this.error = false;
+    this.paused = false;
+
+    var $ = this;
+    this.iFrameLoaded = function (event) {
+      // when we remove iframe from dom
+      // the request stops, but in IE load
+      // event fires
+      if (!$.iFrame || !$.iFrame.parentNode) {
+        return;
+      }
+      $.finished = true;
+      try {
+        // fixing Opera 10.53
+        if ($.iFrame.contentDocument &&
+          $.iFrame.contentDocument.body &&
+          $.iFrame.contentDocument.body.innerHTML == "false") {
+          // In Opera event is fired second time
+          // when body.innerHTML changed from false
+          // to server response approx. after 1 sec
+          // when we upload file with iframe
+          return;
+        }
+      } catch (error) {
+        //IE may throw an "access is denied" error when attempting to access contentDocument
+        $.error = true;
+        $.abort();
+        $.flowObj.fire('fileError', $, error);
+        return;
+      }
+      // iframe.contentWindow.document - for IE<7
+      var doc = $.iFrame.contentDocument || $.iFrame.contentWindow.document;
+      var innerHtml = doc.body.innerHTML;
+      if ($.flowObj.opts.matchJSON) {
+        innerHtml = /(\{.*\})/.exec(innerHtml)[0];
+      }
+
+      $.abort();
+      $.flowObj.fire('fileSuccess', $, innerHtml);
+      $.flowObj.upload();
+    };
+    this.bootstrap();
+  }
+
+  FustyFlowFile.prototype = {
+    getExtension: Flow.FlowFile.prototype.getExtension,
+    getType: function () {
+      // undefined
+    },
+    send: function () {
+      if (this.finished) {
+        return;
+      }
+      var o = this.flowObj.opts;
+      var form = this.createForm();
+      var params = o.query;
+      if (isFunction(params)) {
+        params = params(this);
+      }
+      params[o.fileParameterName] = this.element;
+      params['flowFilename'] = this.name;
+      params['flowRelativePath'] = this.relativePath;
+      params['flowIdentifier'] = this.uniqueIdentifier;
+
+      this.addFormParams(form, params);
+      addEvent(this.iFrame, 'load', this.iFrameLoaded);
+      form.submit();
+      removeElement(form);
+    },
+    abort: function (noupload) {
+      if (this.iFrame) {
+        this.iFrame.setAttribute('src', 'java' + String.fromCharCode(115) + 'cript:false;');
+        removeElement(this.iFrame);
+        this.iFrame = null;
+        !noupload && this.flowObj.upload();
+      }
+    },
+    cancel: function () {
+      this.flowObj.removeFile(this);
+      this.abort();
+    },
+    retry: function () {
+      this.bootstrap();
+      this.flowObj.upload();
+    },
+    bootstrap: function () {
+      this.abort(true);
+      this.finished = false;
+      this.error = false;
+    },
+    timeRemaining: function () {
+      // undefined
+    },
+    sizeUploaded: function () {
+      // undefined
+    },
+    resume: function () {
+      this.paused = false;
+      this.flowObj.upload();
+    },
+    pause: function () {
+      this.paused = true;
+      this.abort();
+    },
+    isUploading: function () {
+      return this.iFrame !== null;
+    },
+    isPaused: function () {
+      return this.paused;
+    },
+    isComplete: function () {
+      return this.progress() === 1;
+    },
+    progress: function () {
+      if (this.error) {
+        return 1;
+      }
+      return this.finished ? 1 : 0;
+    },
+
+    createIframe: function () {
+      var iFrame = (/MSIE (6|7|8)/).test(navigator.userAgent) ?
+        document.createElement('<iframe name="' + this.uniqueIdentifier + '_iframe' + '">') :
+        document.createElement('iframe');
+
+      iFrame.setAttribute('id', this.uniqueIdentifier + '_iframe_id');
+      iFrame.setAttribute('name', this.uniqueIdentifier + '_iframe');
+      iFrame.style.display = 'none';
+      document.body.appendChild(iFrame);
+      return iFrame;
+    },
+    createForm: function() {
+      var target = this.flowObj.opts.target;
+      if (typeof target === "function") {
+        target = target.apply(null);
+      }
+
+      var form = document.createElement('form');
+      form.encoding = "multipart/form-data";
+      form.method = "POST";
+      form.setAttribute('action', target);
+      if (!this.iFrame) {
+        this.iFrame = this.createIframe();
+      }
+      form.setAttribute('target', this.iFrame.name);
+      form.style.display = 'none';
+      document.body.appendChild(form);
+      return form;
+    },
+    addFormParams: function(form, params) {
+      var input;
+      each(params, function (value, key) {
+        if (value && value.nodeType === 1) {
+          input = value;
+        } else {
+          input = document.createElement('input');
+          input.setAttribute('value', value);
+        }
+        input.setAttribute('name', key);
+        form.appendChild(input);
+      });
+    }
+  };
+
+  FustyFlow.FustyFlowFile = FustyFlowFile;
+
+  if (typeof module !== 'undefined') {
+    module.exports = FustyFlow;
+  } else if (typeof define === "function" && define.amd) {
+    // AMD/requirejs: Define the module
+    define(function(){
+      return FustyFlow;
+    });
+  } else {
+    window.FustyFlow = FustyFlow;
+  }
+})(window.Flow, window, document);
diff --git js/mage/adminhtml/product.js js/mage/adminhtml/product.js
index 10e3901..8bf0490 100644
--- js/mage/adminhtml/product.js
+++ js/mage/adminhtml/product.js
@@ -34,18 +34,18 @@ Product.Gallery.prototype = {
     idIncrement :1,
     containerId :'',
     container :null,
-    uploader :null,
     imageTypes : {},
-    initialize : function(containerId, uploader, imageTypes) {
+    initialize : function(containerId, imageTypes) {
         this.containerId = containerId, this.container = $(this.containerId);
-        this.uploader = uploader;
         this.imageTypes = imageTypes;
-        if (this.uploader) {
-            this.uploader.onFilesComplete = this.handleUploadComplete
-                    .bind(this);
-        }
-        // this.uploader.onFileProgress = this.handleUploadProgress.bind(this);
-        // this.uploader.onFileError = this.handleUploadError.bind(this);
+
+        document.on('uploader:fileSuccess', function(event) {
+            var memo = event.memo;
+            if(memo && this._checkCurrentContainer(memo.containerId)) {
+                this.handleUploadComplete([{response: memo.response}]);
+            }
+        }.bind(this));
+
         this.images = this.getElement('save').value.evalJSON();
         this.imagesValues = this.getElement('save_image').value.evalJSON();
         this.template = new Template('<tr id="__id__" class="preview">' + this
@@ -56,6 +56,9 @@ Product.Gallery.prototype = {
         varienGlobalEvents.attachEventHandler('moveTab', this.onImageTabMove
                 .bind(this));
     },
+    _checkCurrentContainer: function(child) {
+        return $(this.containerId).down('#' + child);
+    },
     onImageTabMove : function(event) {
         var imagesTab = false;
         this.container.ancestors().each( function(parentItem) {
@@ -113,7 +116,6 @@ Product.Gallery.prototype = {
             newImage.disabled = 0;
             newImage.removed = 0;
             this.images.push(newImage);
-            this.uploader.removeFile(item.id);
         }.bind(this));
         this.container.setHasChanges();
         this.updateImages();
diff --git js/mage/adminhtml/uploader/instance.js js/mage/adminhtml/uploader/instance.js
new file mode 100644
index 0000000..483b2af
--- /dev/null
+++ js/mage/adminhtml/uploader/instance.js
@@ -0,0 +1,508 @@
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    design
+ * @package     default_default
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+(function(flowFactory, window, document) {
+'use strict';
+    window.Uploader = Class.create({
+
+        /**
+         * @type {Boolean} Are we in debug mode?
+         */
+        debug: false,
+
+        /**
+         * @constant
+         * @type {String} templatePattern
+         */
+        templatePattern: /(^|.|\r|\n)({{(\w+)}})/,
+
+        /**
+         * @type {JSON} Array of elements ids to instantiate DOM collection
+         */
+        elementsIds: [],
+
+        /**
+         * @type {Array.<HTMLElement>} List of elements ids across all uploader functionality
+         */
+        elements: [],
+
+        /**
+         * @type {(FustyFlow|Flow)} Uploader object instance
+         */
+        uploader: {},
+
+        /**
+         * @type {JSON} General Uploader config
+         */
+        uploaderConfig: {},
+
+        /**
+         * @type {JSON} browseConfig General Uploader config
+         */
+        browseConfig: {},
+
+        /**
+         * @type {JSON} Misc settings to manipulate Uploader
+         */
+        miscConfig: {},
+
+        /**
+         * @type {Array.<String>} Sizes in plural
+         */
+        sizesPlural: ['bytes', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
+
+        /**
+         * @type {Number} Precision of calculation during convetion to human readable size format
+         */
+        sizePrecisionDefault: 3,
+
+        /**
+         * @type {Number} Unit type conversion kib or kb, etc
+         */
+        sizeUnitType: 1024,
+
+        /**
+         * @type {String} Default delete button selector
+         */
+        deleteButtonSelector: '.delete',
+
+        /**
+         * @type {Number} Timeout of completion handler
+         */
+        onCompleteTimeout: 1000,
+
+        /**
+         * @type {(null|Array.<FlowFile>)} Files array stored for success event
+         */
+        files: null,
+
+
+        /**
+         * @name Uploader
+         *
+         * @param {JSON} config
+         *
+         * @constructor
+         */
+        initialize: function(config) {
+            this.elementsIds = config.elementIds;
+            this.elements = this.getElements(this.elementsIds);
+
+            this.uploaderConfig = config.uploaderConfig;
+            this.browseConfig = config.browseConfig;
+            this.miscConfig =  config.miscConfig;
+
+            this.uploader = flowFactory(this.uploaderConfig);
+
+            this.attachEvents();
+
+            /**
+             * Bridging functions to retain functionality of existing modules
+             */
+            this.formatSize = this._getPluralSize.bind(this);
+            this.upload = this.onUploadClick.bind(this);
+            this.onContainerHideBefore = this.onTabChange.bind(this);
+        },
+
+        /**
+         * Array of strings containing elements ids
+         *
+         * @param {JSON.<string, Array.<string>>} ids as JSON map,
+         *      {<type> => ['id1', 'id2'...], <type2>...}
+         * @returns {Array.<HTMLElement>} An array of DOM elements
+         */
+        getElements: function (ids) {
+            /** @type {Hash} idsHash */
+            var idsHash = $H(ids);
+
+            idsHash.each(function (id) {
+                var result = this.getElementsByIds(id.value);
+
+                idsHash.set(id.key, result);
+            }.bind(this));
+
+            return idsHash.toObject();
+        },
+
+        /**
+         * Get HTMLElement from hash values
+         *
+         * @param {(Array|String)}ids
+         * @returns {(Array.<HTMLElement>|HTMLElement)}
+         */
+        getElementsByIds: function (ids) {
+            var result = [];
+            if(ids && Object.isArray(ids)) {
+                ids.each(function(fromId) {
+                    var DOMElement = $(fromId);
+
+                    if (DOMElement) {
+                        // Add it only if it's valid HTMLElement, otherwise skip.
+                        result.push(DOMElement);
+                    }
+                });
+            } else {
+                result = $(ids)
+            }
+
+            return result;
+        },
+
+        /**
+         * Attach all types of events
+         */
+        attachEvents: function() {
+            this.assignBrowse();
+
+            this.uploader.on('filesSubmitted', this.onFilesSubmitted.bind(this));
+
+            this.uploader.on('uploadStart', this.onUploadStart.bind(this));
+
+            this.uploader.on('fileSuccess', this.onFileSuccess.bind(this));
+            this.uploader.on('complete', this.onSuccess.bind(this));
+
+            if(this.elements.container && !this.elements.delete) {
+                this.elements.container.on('click', this.deleteButtonSelector, this.onDeleteClick.bind(this));
+            } else {
+                if(this.elements.delete) {
+                    this.elements.delete.on('click', Event.fire.bind(this, document, 'upload:simulateDelete', {
+                        containerId: this.elementsIds.container
+                    }));
+                }
+            }
+            if(this.elements.upload) {
+                this.elements.upload.invoke('on', 'click', this.onUploadClick.bind(this));
+            }
+            if(this.debug) {
+                this.uploader.on('catchAll', this.onCatchAll.bind(this));
+            }
+        },
+
+        onTabChange: function (successFunc) {
+            if(this.uploader.files.length && !Object.isArray(this.files)) {
+                if(confirm(
+                        this._translate('There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?')
+                   )
+                ) {
+                    if(Object.isFunction(successFunc)) {
+                        successFunc();
+                    } else {
+                        this._handleDelete(this.uploader.files);
+                        document.fire('uploader:fileError', {
+                            containerId: this.elementsIds.container
+                        });
+                    }
+                } else {
+                    return 'cannotchange';
+                }
+            }
+        },
+
+        /**
+         * Assign browse buttons to appropriate targets
+         */
+        assignBrowse: function() {
+            if (this.elements.browse && this.elements.browse.length) {
+                this.uploader.assignBrowse(
+                    this.elements.browse,
+                    this.browseConfig.isDirectory || false,
+                    this.browseConfig.singleFile || false,
+                    this.browseConfig.attributes || {}
+                );
+            }
+        },
+
+        /**
+         * @event
+         * @param {Array.<FlowFile>} files
+         */
+        onFilesSubmitted: function (files) {
+            files.filter(function (file) {
+                if(this._checkFileSize(file)) {
+                    alert(
+                        this._translate('Maximum allowed file size for upload is') +
+                        " " + this.miscConfig.maxSizePlural + "\n" +
+                        this._translate('Please check your server PHP settings.')
+                    );
+                    file.cancel();
+                    return false;
+                }
+                return true;
+            }.bind(this)).each(function (file) {
+                this._handleUpdateFile(file);
+            }.bind(this));
+        },
+
+        _handleUpdateFile: function (file) {
+            var replaceBrowseWithRemove = this.miscConfig.replaceBrowseWithRemove;
+            if(replaceBrowseWithRemove) {
+                document.fire('uploader:simulateNewUpload', { containerId: this.elementsIds.container });
+            }
+            this.elements.container
+                [replaceBrowseWithRemove ? 'update':'insert'](this._renderFromTemplate(
+                    this.elements.templateFile,
+                    {
+                        name: file.name,
+                        size: file.size ? '(' + this._getPluralSize(file.size) + ')' : '',
+                        id: file.uniqueIdentifier
+                    }
+                )
+            );
+        },
+
+        /**
+         * Upload button is being pressed
+         *
+         * @event
+         */
+        onUploadStart: function () {
+            var files = this.uploader.files;
+
+            files.each(function (file) {
+                var id = file.uniqueIdentifier;
+
+                this._getFileContainerById(id)
+                    .removeClassName('new')
+                    .removeClassName('error')
+                    .addClassName('progress');
+                this._getProgressTextById(id).update(this._translate('Uploading...'));
+
+                var deleteButton = this._getDeleteButtonById(id);
+                if(deleteButton) {
+                    this._getDeleteButtonById(id).hide();
+                }
+            }.bind(this));
+
+            this.files = this.uploader.files;
+        },
+
+        /**
+         * Get file-line container by id
+         *
+         * @param {String} id
+         * @returns {HTMLElement}
+         * @private
+         */
+        _getFileContainerById: function (id) {
+            return $(id + '-container');
+        },
+
+        /**
+         * Get text update container
+         *
+         * @param id
+         * @returns {*}
+         * @private
+         */
+        _getProgressTextById: function (id) {
+            return this._getFileContainerById(id).down('.progress-text');
+        },
+
+        _getDeleteButtonById: function(id) {
+            return this._getFileContainerById(id).down('.delete');
+        },
+
+        /**
+         * Handle delete button click
+         *
+         * @event
+         * @param {Event} e
+         */
+        onDeleteClick: function (e) {
+            var element = Event.findElement(e);
+            var id = element.id;
+            if(!id) {
+                id = element.up(this.deleteButtonSelector).id;
+            }
+            this._handleDelete([this.uploader.getFromUniqueIdentifier(id)]);
+        },
+
+        /**
+         * Complete handler of uploading process
+         *
+         * @event
+         */
+        onSuccess: function () {
+            document.fire('uploader:success', { files: this.files });
+            this.files = null;
+        },
+
+        /**
+         * Successfully uploaded file, notify about that other components, handle deletion from queue
+         *
+         * @param {FlowFile} file
+         * @param {JSON} response
+         */
+        onFileSuccess: function (file, response) {
+            response = response.evalJSON();
+            var id = file.uniqueIdentifier;
+            var error = response.error;
+            this._getFileContainerById(id)
+                .removeClassName('progress')
+                .addClassName(error ? 'error': 'complete')
+            ;
+            this._getProgressTextById(id).update(this._translate(
+                error ? this._XSSFilter(error) :'Complete'
+            ));
+
+            setTimeout(function() {
+                if(!error) {
+                    document.fire('uploader:fileSuccess', {
+                        response: Object.toJSON(response),
+                        containerId: this.elementsIds.container
+                    });
+                } else {
+                    document.fire('uploader:fileError', {
+                        containerId: this.elementsIds.container
+                    });
+                }
+                this._handleDelete([file]);
+            }.bind(this) , !error ? this.onCompleteTimeout: this.onCompleteTimeout * 3);
+        },
+
+        /**
+         * Upload button click event
+         *
+         * @event
+         */
+        onUploadClick: function () {
+            try {
+                this.uploader.upload();
+            } catch(e) {
+                if(console) {
+                    console.error(e);
+                }
+            }
+        },
+
+        /**
+         * Event for debugging purposes
+         *
+         * @event
+         */
+        onCatchAll: function () {
+            if(console.group && console.groupEnd && console.trace) {
+                var args = [].splice.call(arguments, 1);
+                console.group();
+                    console.info(arguments[0]);
+                    console.log("Uploader Instance:", this);
+                    console.log("Event Arguments:", args);
+                    console.trace();
+                console.groupEnd();
+            } else {
+                console.log(this, arguments);
+            }
+        },
+
+        /**
+         * Handle deletition of files
+         * @param {Array.<FlowFile>} files
+         * @private
+         */
+        _handleDelete: function (files) {
+            files.each(function (file) {
+                file.cancel();
+                var container = $(file.uniqueIdentifier + '-container');
+                if(container) {
+                    container.remove();
+                }
+            }.bind(this));
+        },
+
+        /**
+         * Check whenever file size exceeded permitted amount
+         *
+         * @param {FlowFile} file
+         * @returns {boolean}
+         * @private
+         */
+        _checkFileSize: function (file) {
+            return file.size > this.miscConfig.maxSizeInBytes;
+        },
+
+        /**
+         * Make a translation of string
+         *
+         * @param {String} text
+         * @returns {String}
+         * @private
+         */
+        _translate: function (text) {
+            try {
+                return Translator.translate(text);
+            }
+            catch(e){
+                return text;
+            }
+        },
+
+        /**
+         * Render from given template and given variables to assign
+         *
+         * @param {HTMLElement} template
+         * @param {JSON} vars
+         * @returns {String}
+         * @private
+         */
+        _renderFromTemplate: function (template, vars) {
+            var t = new Template(this._XSSFilter(template.innerHTML), this.templatePattern);
+            return t.evaluate(vars);
+        },
+
+        /**
+         * Format size with precision
+         *
+         * @param {Number} sizeInBytes
+         * @param {Number} [precision]
+         * @returns {String}
+         * @private
+         */
+        _getPluralSize: function (sizeInBytes, precision) {
+                if(sizeInBytes == 0) {
+                    return 0 + this.sizesPlural[0];
+                }
+                var dm = (precision || this.sizePrecisionDefault) + 1;
+                var i = Math.floor(Math.log(sizeInBytes) / Math.log(this.sizeUnitType));
+
+                return (sizeInBytes / Math.pow(this.sizeUnitType, i)).toPrecision(dm) + ' ' + this.sizesPlural[i];
+        },
+
+        /**
+         * Purify template string to prevent XSS attacks
+         *
+         * @param {String} str
+         * @returns {String}
+         * @private
+         */
+        _XSSFilter: function (str) {
+            return str
+                .stripScripts()
+                // Remove inline event handlers like onclick, onload, etc
+                .replace(/(on[a-z]+=["][^"]+["])(?=[^>]*>)/img, '')
+                .replace(/(on[a-z]+=['][^']+['])(?=[^>]*>)/img, '')
+            ;
+        }
+    });
+})(fustyFlowFactory, window, document);
diff --git lib/Unserialize/Parser.php lib/Unserialize/Parser.php
index 423902a..2c01684 100644
--- lib/Unserialize/Parser.php
+++ lib/Unserialize/Parser.php
@@ -34,6 +34,7 @@ class Unserialize_Parser
     const TYPE_DOUBLE = 'd';
     const TYPE_ARRAY = 'a';
     const TYPE_BOOL = 'b';
+    const TYPE_NULL = 'N';
 
     const SYMBOL_QUOTE = '"';
     const SYMBOL_SEMICOLON = ';';
diff --git lib/Unserialize/Reader/Arr.php lib/Unserialize/Reader/Arr.php
index caa979e..cd37804 100644
--- lib/Unserialize/Reader/Arr.php
+++ lib/Unserialize/Reader/Arr.php
@@ -101,7 +101,10 @@ class Unserialize_Reader_Arr
         if ($this->_status == self::READING_VALUE) {
             $value = $this->_reader->read($char, $prevChar);
             if (!is_null($value)) {
-                $this->_result[$this->_reader->key] = $value;
+                $this->_result[$this->_reader->key] =
+                    ($value == Unserialize_Reader_Null::NULL_VALUE && $prevChar == Unserialize_Parser::TYPE_NULL)
+                        ? null
+                        : $value;
                 if (count($this->_result) < $this->_length) {
                     $this->_reader = new Unserialize_Reader_ArrKey();
                     $this->_status = self::READING_KEY;
diff --git lib/Unserialize/Reader/ArrValue.php lib/Unserialize/Reader/ArrValue.php
index d2a4937..c6c0221 100644
--- lib/Unserialize/Reader/ArrValue.php
+++ lib/Unserialize/Reader/ArrValue.php
@@ -84,6 +84,10 @@ class Unserialize_Reader_ArrValue
                     $this->_reader = new Unserialize_Reader_Dbl();
                     $this->_status = self::READING_VALUE;
                     break;
+                case Unserialize_Parser::TYPE_NULL:
+                    $this->_reader = new Unserialize_Reader_Null();
+                    $this->_status = self::READING_VALUE;
+                    break;
                 default:
                     throw new Exception('Unsupported data type ' . $char);
             }
diff --git lib/Unserialize/Reader/Null.php lib/Unserialize/Reader/Null.php
new file mode 100644
index 0000000..93c7e0b
--- /dev/null
+++ lib/Unserialize/Reader/Null.php
@@ -0,0 +1,64 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Unserialize
+ * @package     Unserialize_Reader_Null
+ * @copyright  Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Class Unserialize_Reader_Null
+ */
+class Unserialize_Reader_Null
+{
+    /**
+     * @var int
+     */
+    protected $_status;
+
+    /**
+     * @var string
+     */
+    protected $_value;
+
+    const NULL_VALUE = 'null';
+
+    const READING_VALUE = 1;
+
+    /**
+     * @param string $char
+     * @param string $prevChar
+     * @return string|null
+     */
+    public function read($char, $prevChar)
+    {
+        if ($prevChar == Unserialize_Parser::SYMBOL_SEMICOLON) {
+            $this->_value = self::NULL_VALUE;
+            $this->_status = self::READING_VALUE;
+            return null;
+        }
+
+        if ($this->_status == self::READING_VALUE && $char == Unserialize_Parser::SYMBOL_SEMICOLON) {
+            return $this->_value;
+        }
+        return null;
+    }
+}
diff --git skin/adminhtml/default/default/boxes.css skin/adminhtml/default/default/boxes.css
index 298423c..7bb41d2 100644
--- skin/adminhtml/default/default/boxes.css
+++ skin/adminhtml/default/default/boxes.css
@@ -76,7 +76,7 @@
     z-index:501;
     }
 #loading-mask {
-    background:background:url(../images/blank.gif) repeat;
+    background:url(images/blank.gif) repeat;
     position:absolute;
     color:#d85909;
     font-size:1.1em;
@@ -1394,8 +1394,6 @@ ul.super-product-attributes { padding-left:15px; }
 .uploader .file-row-info .file-info-name  { font-weight:bold; }
 .uploader .file-row .progress-text { float:right; font-weight:bold; }
 .uploader .file-row .delete-button { float:right; }
-.uploader .buttons { float:left; }
-.uploader .flex { float:right; }
 .uploader .progress { border:1px solid #f0e6b7; background-color:#feffcc; }
 .uploader .error { border:1px solid #aa1717; background-color:#ffe6de; }
 .uploader .error .progress-text { padding-right:10px; }
diff --git skin/adminhtml/default/default/media/flex.swf skin/adminhtml/default/default/media/flex.swf
deleted file mode 100644
index a8ecaa0..0000000
--- skin/adminhtml/default/default/media/flex.swf
+++ /dev/null
@@ -1,70 +0,0 @@
-CWS	-~  x�̽XK�8���i�޻��E��.X@PH	AB�Ih"`î�{��X����E,�b��������~���{�6;sΜ3sʜ�M��\��A�� �.	R�C�H�@���wTP�in�P$��5k�L���䔓����(��:�xyy99�:��:��<���� �ZX���xR�$-S�&�buN�8K�cm�����d��%�,S�N<!/�'�I�\] ��7_,���|9���4.c�� ���9�l�_ȑ
-8u5�hdi2!��?E��3�rM]M������&X㔮��v��Q;r�N�qJ��Y���I0�Y��4��'�����9�.��X��Ǒ�{��ax!G���I���q�u|����թ������|h��o�V@��|� �g�H aꪭ��Ю���,I"�ğ����.��	yI�I\����)l�X��p���*�eZ�q�K8<DqD�H;|� �LD�� �D$��qe�h�$M�J����b���1q+9�1Ӓ��}xZO�Ɂ+E3r����z@_���*��D|�Z/���ߔ4i���G"�N�
-�2�:��P�H���L!O���y*t�('%�!sR�%K8�<�.X"K��E�\Y�\.���,Y�PJ�!TH�s�H�ɂx�4Qf��������!s��"��e�Z
-�ϓHx)C;�3q��O�B.|*)b.�D�D9YP�,��N����	'�,�Am�D2�
-�+E����j(�t稕�+�7�P�21O�e�妉��0�f�Q�da�^�RW}D�`&��T
-]��?8-:�K,R�0X'���4��?�2�s���=�x�rT����A�ddRԈ�CÆ�*`��v�4����\'�N�D��1�Q�aCQWGgGGgFpTTD���
-���àB7���a"h�G�b�!�L%	/�'�7����)����ޝ~���)I��,{��w�dè�&�ILz6
-�z��K����������#���g��4Y'3H���$yF=H�~���N%%Ie�L��ap�S#�D��II�I0��A)2��#ĝV��x)����aC��0��Ȕ2�̸f��'��8�)��eh�h7����҄�4��;��hҬd)�!N�G���m�	c�)q�S@Qp�]1@�GD�������ffO�B�D�2��$�����!����,�Iy2����U����<�N��0:D�����r5*�Y� M�B�c
-�d|�i@d �XG'�D��'�Nc9���*�
-������
-�aL7F�6J	'���IdOF��ps���C����TX�8sD�e������x0�Ȣ��i���7�k��̿��'#f*J�,��T�i��"w4�I�	�8���8^���&w:OF�� �76�'�)��",F@�j\��t�CfX�&��Q�"��p�̓����p����#���[�q~�$l
-��z��`x6U5�s҄�S��C9���z �^�J��EɸE��0�,��6E�Nej�ꪓm]]]7�;�?ѡ��������O�����N��% 6�.�ndD(STT��54��I:�=�z�DUc`B3�ր���f�4�͜�7�$�Q��(��DJRBI�(사Fc �@QM(���j��J�CQ}��!J6BQc5AQS5CQsX��%
-�P�
-�Q�EmQ�E�Q���(ꈢN(������~(ꁢ�(ꅢ�(s ����
-�B�?���@�d ���HCA
-�Q0#P��XT/�K@��P�AA2j���E� cP DA
-D���(�	
-�(���Y�r6���*��|L(���P�9�P�y ՟a JX��}1�/�K�m���
-Ĭ(y5���k-�����i��+���� !!;��/ lM��i�	��&�2�;=�(������E P�@	�uoN��wj7���"� ���FJe��� �NW�Uu��k �&�	��$C 4��d��P}�( D� L#�(�a� ������� ZV Q��5@4l B����F�==����4P�%��!z}�}G@�C^Np�}�D�ҙ�X��.��J!��n�9�ؗB2'�)���QPs
-уB6G�:��S�d�F6���A���-
-	P�9��� 8� ���fŔ#	!Z' �c�#�P(*�^휠d��B&��9T;'��|�.���%��\�Z}=,��D7K��-��%Y�Q�D:��v�DnY"u�fl�Y���@'��T`�hg�.�K��#�JT��$ZX,�Lz���D���U�$�$�	郰��>�D[ye(��&�F�"l?6���:���P,KD��%��J�aEj,�:i�*Ah	�7�Vt�p�����=Q/A�2%\��zl
-?�m��ҋFl"l(JD�a��iq���޴�K��m��`F�}��n�j�����qI���P��%'�X��%��L��H&�$�%�	�7B�A
- �Zu�� �*�%��@�� ��j���$:�0!� ���e�}�a� �FMH8P�^� ��B:��P�K�viw˙L�3 X"��!�v�AV]��mb��N��e���X";���a،�W`�J�K��Ԁ��R@�;�:��	���;*�J��T�h����	ێ��
-�OԲh%�u@"Ԁj	��B&A?B#�yTE}5ԧm��:>"[lD��Sq��"�D�`e�����P,&��dW�J��ܨ��T��*�T;�8�B����3�����{L)B�"h�B�0c�	�:]"s�H$aX��NÀj왭g�y�ގ���b��Ω�p���#��ad6���-N��>����pF&�b�X�*�]��ANful��r���]���+}��jX�W��0n���+$U&�`F�$�s�L%loo'����ok��־��=���BA3(!,$č"�#���h��"	�ID�HC.�M�Y}����#�F��:�'0�6Jd���?ۑ��ه5Nn�����A㻃
-pPawP� ��&��fM��,N�,��vU�T���� &Y�yp��D(�+-�S6G	�Ʉ�dD� z�FG��`k���Ă��R�js 6�갩6`Ή�/�M5ؼ�Oؙ��#�		Я�L�����}��}1��F���b�-��Y�!y-��D���ܸ^��Ğ� �tq�(b
-�L&! hI"��a$I�"	F���D��ut�u�[�/Px,����ǰ�;*�|!^I�ׄ�䐐��@.��0>ܓ�un�F�	P#j�W(A���{�?�!�.+���m������	�ݪ�����Am�G`�A��a�Q���N���%a������	��H-�G�.�j)L�i�̆�XSm��Ѭ��Ʋ�3[�̖:�e��,gv�3�	�b���%`��:� V;â. &���U��G$3�3@�b1pI5x8�S�.e[c��s؄��`�/��Q�0ıփ:l�&�!�k�0�0U�p�a;��<(�)���9�ɤ���6�
-��&�Vׄ���'��V;�ؘ�X#aG#0���n_��C�^b��%uH� �3pc �ڈ �$������D���yZ�����a#�l+78y��	�@$Q�50,�)�H$��u
-��p#��qتg �ܩXs8\�
-4P>6\K48B�EǦ�Z�i�!��$��Xb�"��3ܿ�s��y�v�Z|�9�CR�P��}�*�s��у�7U�Ў�*٩�2�!�/�_��i�"قPꮰ�^�E��T7�X�m��+�����M��02�+& 	�&ې/O��F���'lH9��	n���	��cx'�����6�����^�/
-0K?*����)��8	26�����%<N8;�@m�m�\޴ە����4
-�K����ߨ��RV�)���UΤ�'��ΛVft
-A�Ağ/�B<�v��(��ի�7����O����{������%$�w�`��F�q����v߄�u�S��w?�|���d�@{Sr����M[�l�%�����"�������2��"�,�ݼR��$�|��!�vާ-�	������z����z=��y���R�s&C����'��l��S������O˼%�����Q;G���@��!dUDɽ[��}Шa��~M�\$<{�����<�aQfw��G��'�ߺ��j�b����W^�ܣ�?c�������'��಑��W��N��~ɻ�_��j鮐{+\��~�=w����!?	�J���y7���7��7b�M6�U��e�����&�{?���V�8�X�����.�_�~x{�)m����ϛ�O�f�|�7:Rw�FM�{��cו{#-�v����b����s���/����o�kDz�EÞzy}ڿ�ɿ���o��j:�r1�~��QЕ����'�5k^�a[�gh����a�[�i�����<�����?�KB�s�{.4yl��y2'�!ixʀ���^�G�{�`��5w�x��JN5(~����8�/ѕ*O/�<���ה���.�����>�G��m"ޫ��̹�M�j�	�q���}*M�OYf�d�?qS�e���SЏ�=c,�Yp/��7����k�B�ɜ'Y�gQ�~g[U���n��4R�x:q�w?�8��ѻl��tk���_������;+��3�K��^�9rv�\8}���+<=+6���<�e��݉g/�m��֨�_n]��_|����������h���m���Z:���w�Gc�NaU��Z˱e������,�~6u��ګ�%�]37o�L��gF��+k�����_�=�s&}q)�������Zz��Vf/�$����G	��vM�Y7��
-^������]����������k����e�֏��m_X����mи�qhX�3c3�{�o��P{�}ֶ/-޽&�u7�8�5vJɫKo��;�ap���zJ���CZ�;�i#�ͯ�3��=�0㵒yi�Z�9�_|�s9�����9cX�sE�K�ծ�w��s`g���h-��*(���dl�5Z��Tf_ϳ�=�[n�T�U��"x�̭�X?�Z4�8�\ͻ���QAC�N�Z�-�|w�����Ú��a�K�lw޼��n�h��)��'?ڶ�W:��`l{�Mf��e��=rT&GO�E���8�ʵ��ü�z�h�`���p�ֱ�%��{3�t��d�PG��m;�����ۼl���a�d���'w
-VM�9g۰���*K7���$ٿ�{ak�i�W�'ْ}n.c�����HU}2�Q�f�c�N�Ů	k��>\�{��֤_J�U7�h�0�0�)b
-��U��2bJ%{]��qs�VP�̼�Ǐ����o-���s�KW\h;�r/�_e��"��miSS�}CQ񗤦v""�Z�֩яɘ����N�n9R�|�Ƈ~�Nl�N��d��RljGo$���mC��ku-=���aB��LҏqQ?=fü��'u�&,,(6�_���0�?.�������x!}��8�[;q���+Gd�>h�ii��N�}��Rg���U�s.�Y��]��Ф�6UǱO���<�酉���_%?/�X�o7��;f~Y��H��C�Z:�M�,v�O��X�����k�̀�������ï�ÎH�/�W=T��1�v+�����ڥ�S�%/VMT�]6p}$�\霭�g�Z�w�o2v}��A���%Qi����vg�0��(�L)�>r����'��ڶ��z;�SIٞ����<��6�mۖ���s�4.���!b}�<�ѯ��K���X�_�?>�M�F3�y�!�^������^��-�Fs�E�3ɿ����4_��h\bX�����;Gn�9��иƪeNA�#�d�:X�u�ݽ)��'J7��!�#^���1�Ԝ��m�)X ��������c'S[�"�����u'w���;3~���+7Ffor����C��s�jI��G�w�o�t�)m:yz�,�K�M����T��~�v>�(l��q�ʺ3W�ç���v��&/���}�ma֝)o�Nzh����ݷ�%�tM�p'�����ƅ#>H]����[��N��n�B��Yw��\�>�´_S�#'j��e t���ѣ����<o�>��!��>{?��>m^�A��G:�ۋ�}֑6�ɻ���Sj��xy����,�*~��deI����q?Θ�#���@9�}��ުUZ]*��]���Z�C���i�6F���C�����M|���!n�0�unu`mKr���Q��AIm���G*���~{n�r�޻K&Ӎ/f��7'��
-Ύ\�x����%��K/�.^p���S�$݄��{���8�-�p���f���S��d^֮z��(}<��ڵn��$�N��/G�~�)�����.��f��Ieo֣ʖk7M}���s�ۣ��^��=G����9R�_;���譞�l�?�;lX���WgU����ҋ.m+�8��"�[x���OE�+����{�3)cI�4}�|��OK�W}�'����F��G��ؘ��N$����V���N��<�e�h�K���f�_W���Ν��>�##;��´�L�_���l������b������d"yuG�^�>��ƆS$}��sϥ�>����Μ��+��rV/�c����o%V=3k�4��㳍�g�N��f��*��V��Y�����#�V~�w�7O�O�ڷg���	G���Ⱥ �<����C�.li�>!?�ؘ��o�6�;yD�[�>������F]��A:�dY��V�շ@[�}>�N���9�:�J�Lu��`$��*_��{鱖�o>K,x�,޴kX/�z>�Akc�y#Ú�S���s���O��e`?w�|E�ńFQ]è��wߗD�X���`U�ɯ���o��^8W I9��fc�y�z�"�_v.z������/1��4{���_~�zr<�3)�Ǭ���о�k-��E�o��n8.>l[V" �Y�~0��E��#�����ͷX�p�N�>��������=��s�5i�IQ����'�^]<r����!�C��m�����W�/o-,��U?6ha|�%���&�w+6���%ڸ��;��C����l?��V������-{�X��\}߶}���:�B�б�W�P��c����E����S�4	&�W}��;�;�rc��#��I�h��#o�@I�̢�����K���ǻ�����4_�OCg���������6�S�f��o���>�fE�������[�GmO7k��q{��˓�FO#J|�V��t���}Xf=�?��k��M���?y��m�Ӯ;��\�R��:账�̧��s��_.ptr���r��'��4�K.L̘�m���sV~�F��@�X������'b]tT��g鮭F�f��9=]���4hh�:��k�*E��B�Vi�{PP�p�ɷ��|�}9��2�Úx���{˪�3�������J�~�5��:���u�/3�\��8`��[�*�GK��}��TY��O>\�Rj�5�/��c+�>��4���2�B�r����s��ƜW���|���W�~Vٚ8e�����M�k�{\�������5!�A�������̥MO�ԍ�ʝ3�+��Mۏ��ML6�Eo���}�꧟�3����������f��ؒ�e2y{�4�n̂���3�s�o�+B�6x����"��g�&�/ZZ����'�?9��S��6><����-W_]g��}9��>�̘�g�Y�O7�x���Nz�{���sid���m�s��W�[Z�"9�ұ�UF<�Z�����}�c����tp�Ց�'�YW��Q�p��Yǩ����&V.�=�j�����O�4�S~��<�+Ow5��!��?��*����5������X�;��-��Ǆ��S�v�k����S����׏31���C�Aq�o��ˈ���kdp�o5Ny��z|���f�c�iG���Q��|�S��p��y{]bڏ}.x�iȇq1s�OL�~C����+����nǨ���ee�ՓF�Si��^5k�rռK��.�]���e�Z��F�ד��N�,I�f^c|'�=���+�_�V�|�23�?߿�|��Ƨ��v筵ϗ5����'�c|��@�|���4w�c��n��~��6otD�΀�zZ��9�ρg��8}ޮ��E/f��{s�o��j[����� ��2k֬�ev���}[���<kL�U��D�e�KĴ�]>C��G�S߲ѧ�/���]s�w��W�5�����\�O>P��rut�xu���'*�]��}-V]~y5�e�Y5��!���ޟ~��Ų�vw���1��͵�'mfk�^>߅��ĩ�M�}f��-?R����g�V/}v��xI{�T�YkZ���w����:�����+��/:�~�ђ"��U��'��:Cv;��N	�������z�a��AΜԞ��8�W^�d�ϸ�U�ۦo(�s��9�꾦~�,�d'{i��A߅7�c�nq4H7���/K�,լ-T+)o>4�;c}ɶ���ecw|�kp�,�@L78SY���F���}C�w�H�������3��_{%�.ro���|`�hy�����ZR�1B�y���/�O-
-�9�����+�������k2E�Ϗi����_�k��O�2��i�F���;0vu���c��}>N�y����E�.pA����><g��<��{}S�������o�#ƣ�QC�l�<v�ˤ6��c�������x��׫�%�:w�q�_WF�.�඲r`���/o�i�|��iɗ'�A-Y'�)��xIs���e.q��=2~\>XqOM�{W�d3+����{F4I��!u�.ߞ���pԴs����8;���j�w����������+��Wlv��U�����%_�*n��vQ�]RQ��m�_7:-˗������ש{e<}�mfӏ��/"N~ٲwt��mF���s�׭����Z�?n� ]�m���[5coa������Q����Hnt/��^��1��Hʅ<^�[��߃ל���y���6G�;Hf1uL��_�氇d��(�5�3�H�uLF��iƆ��kEZI#���9�ܲw�-�ZCz'o^|}�WZ�)��Ǌ��Kf�W��,1�[IW"���$<�8�|����8ɬ3��ow��Q����$��ޓ���l��k���e�w�T����9�+�kQ���暴ICHm'�n��fV~��d��t&ieޜmNks�<m�rnHPs̬�gY_�\�O�X��8��g�j�*�v����كE�6ѳ�}��L[�m���.�冈>�u�W��>1��f�3�Z���+?��Go7�����OB�}?
-8��8��o����ߟ�'ڑ��as�S�qyiVn���
-V�៣�^�6K���8��������;$��&�ُ�N���+���y#3w���~��{t�X�Wc/��PKU��sy��j�i��A�����T�tt~��%u��K�>@�:�&rU����,���m����r�c� Q�ح+E:�u�'�s��w���|t�Q�d��0_&lWӚ_<@wo����)~��^O}�;�0���K�O���Gl�L��/��8�3���}�=�زŸ$g����鿨��	�ͤ3Τ2��GFDX�������Ny_�$QQ�(��x�k��Wh��늧�<n\*�zm�m����z��i3#~Ա~͙������9w��Ϙ_[�J���Ŕg�Q� jy���I��'�&�^^�/�}02΀�X���m8�;�^s̅
-��6����J�}M��M[�b�Dz��y\X��/~�ߔ�3�%n�k�����޳(�O�/9ݲ΃s|��y�Y'^^�_t����l��,Q\#mُ)y1E��$q���z-���^'k����_,I�|�i��}$I7_�;���̈�7������:_��Z���y��[Ѻ��ڗ��.;[��F��s��%���^��f��r4�-��(����|���+$�g<�]�vU��ᏩWm�������}��y�KSx�kS�9d��˵��/�:5�ۀm�W��?O����H2���~N�ۆj� ���:��k�ߝ}X4wBz�RƜC�o��ս>���R�� e�kK�O��*�jH�%.�IZ�<����i%�T��}Ez���G��]Qe��n�廡���pl٥^�~<�{mōk��>�g�����z7�����m�G��t���ݥI3��V�h�F��ꡝ{��/��1���ν�Ts퐸����_��H1��ۿ=ٿ�� *��^};v܀Ц�'g��K%�9�9��?Zʯ:�D�kޯʓ�����Lnx��X5���G��+l����,ԫ4��v�þ�I�YT0qoB��j��C��g��ܟq��V��Pm���0~w'��XP�=�QgБ���<m���}ض���r���ʳ}rtޜ�8�+@�~�\hqE�;zp�c�5�c��]��z~.�5�,�Ϳ���^��s�	���^qk�������嗕/W��ڛ��_e���93"N�^{$-���4�O�䟛�j՘�~�=���=�s�^8|V9g�����I~Dr1i������g��=���X9���*�JݵN�����Q<��ҹ��G/���:���#.�Ʌ�P����QM���zmq��q��uo���{nB2k���7ǟ��A�VK�hߏ�oU��H=���E:��y��k�S�w�k�b��,��o\ ^-<=�r�p��eǾ�̿耖WS����L���v�p�������자������e
-Z�%�QaYÞmZi}mߴ~e���N#gZ��xRqoђ��ǝ{|����T������#e�Dw���یA	%s<�Wܘ�+y��6����Q��r�l_=��棵ɓ������!��}̏ͤ�͑�����E	�6	�ŕ��]���ԸS�#�_�1�db�H�7�W�b�u��x�+�p�B��w��?�F�Rۦ憝Y�Һ��$O���蘗6�:c�.6굽�����bq����Z��z�j�Q�ԣ����_��4Q3�rvm�Ua�Jt��o�[�\ͽ��z�7�2���'��òu�^�l�*os��+uik�vc����_0=�OyX�h4>��*���u�^_U��~I��H=��oM���u{��}�y?3`����^k.X9`~���{���:��e~����]f�Uũ��ʆH�!:�t�yE�5&f}U~t����\G�O/�&����Y��Vq�;�0W(sz�����E:��'	VE���Y5��-�ʽN��[�i�o�k��G#���l�z?�Z�Q���b�@��k�wo�W�hK��oKo�Фo��6;?�m���og$�u�_����=�������o�P:dS��v4��įƷH�}j��̄�Z��J�����n╟�8�1�f�C�仳�t���*\��>��쮦�Y��A-ɕ�_�_ ��m���'���P�mY�?>�b�b�|ߍ�6�g����]�ԗ�Sc*��eQ_6`�����nL����sґ��N�KG�PSל]tU#u�P4~^��+CϏje��i	\l�#���@�o�jUY��K{���m��Y�=�ԭ5Δ��C4��+̧G͚{�^Í�'J�2��q�6��`i�|kO�H����c����G���� {����n��)^j�����P�:;Suaқ���_;E��ܒ��u���~�	��*�+�6>���gG�:��8�n�	�x{���s�$��$\��W�/��	�m�)�.kh_���g���>sR�f����7�g�����ݱ1��c��]�����>��d�mol־�����k���|&�o7�k�\Ӣ����(�ɘE�C��e?������qdxR�	Ngɟ���gyl��˝�5nn��H��u�[{���Tj[��ˈ��?!�zę�������AlZݴ(�I��"��'q�IŮU�ں.�%��7\�Ԉ�(^Vw���]Q���:tшo�g�N����7��iVo����������6�9��2g,c��E/�4�Gf�Bg<�I�}^Y��EIӒ�w���Ů�{ćh��r��^�#�煏�L�&n�*ߛJ��������vj�]n���-��Ii�<��ِ�y�(m��v�9����}�~��c�½���~?�.�=*�8��Ԁ��pf���<͋e[^����O�%�͏פ����v�n׎�.��G+" �R�7�sD\�1<O=�c}�ɱ�A�2}��X�4S�#iF�#�^�ۤ��~������'�+\t=���+�n��;�u/���#k�|j̹������D��cUoZ�
-�����0���ɱ;^Äz���m�5��$#��"7���m���%����V]}8rf���i���\>�q�uA΢��;������T�Kɜ�y�;�rYb�C	Y����#�e�1�CW�Z�#�zчx��ր��A����5��1콋���g|mn�2ܒK��0���0�8O?��j���X�c��e�#F�XC�zZ�P����3��ܞ�M�����A�
-֚����iA�j!ۇ�ܾ���B�5���1A�U�&��^~:t\�B/�3#U~<�>�q�շ���;��2��:�,�uyì�]�[cܝ^~�6�WP`ĺܦ��>���O�Mnɛy_j���eQ���W��z��m4%�Q�����LO���#���|}���[���ur��M���1�e&VZN�ў����rͽ{�i����*�54���˗�G�����֘�Q�#��"�V7�\�����ؿ��)W���m��ޒ����Ǐ}w�ܹ���-�9����긂���gJrZ�4�����k���Y}��nL[�bEَvcY�_M����|KQZ}H�z؃a˪}��?�IIן��� 	! �4	�/�M�
-�R^R�8G�=��l����2M�KA��!�2�*��~�N���'NՐ+��S�6�F��o&��mooG7��J.����r}-:k�.���GH_�67_^B~�t���HYwr�q�_������7f>�;l\�:��?h�z◯�+�i�K?��-j���[�Z?��%�>�<�3�Ȍo���W��&��Ƈ~��?�=�鮟�?�*���7P��;��r��h_�b9��P������C@z����u���,	�'U�R���s��S���Z�ݡY�<��Hh�3�t��<��C�N��<h�qFW%,������
-Ӱü�a%��ͤt���p���~?���E��EB�<.�T��Q�]����)Y"���b�+�Bq2GH���p�C8�:r0N��
-9\R9<z�$-�'e�%HC��<����U��S��@;�)/*â��j��xC��a'��������@�b1
-+c@�}��"'eJę<�,*?��/��d�Q&�LǠ�z�Q�nh����TN��q�Y^�ȴ�@�GM�9���*�)��*A��\YG� ��!z���0����ĕJ�8X��$i?�w|Hrq�������������Q�y8�susƅ�{+E~S�~�[���r�3�u\�:���5�?�TYR�(�������òW+��6}=\��su��a۫W��Ȓ�9
-f��}�y��uܫeP���p�&Ix�b	T_,I��B�')z$�|Rj?��ӥ��{?7OW����ț��ϳ��{_Ͼ�,zQũb�W/7g//O��yY�I.n^n}=]]=�P��Ix��#`Y����b+�u"; :�'�{�4���0QJ���4i�������I-��]3����R��&
-���Qo��Z+�F��q&G(��c�4�������CL���0��Y������)r��1-�R�����0�.#����$��4�H��p������4Y����!q�
-V$0��C�#,ׂVJ��;\�T�+F���f�k���,�ct3�F`t��˗
-�L���,l�
-�2��-��ך��ް�|؝��%�O������h���ިcadc��#�d*	Ē�q�A]�f�(weN@�Lm�r�d�?�,K��4��_�)�HUpub+��N�Cn#�%��,��Mq")]&�V�ˌH�8N)상�@N�7adrRR����29\��Q���-�{ldt�f�T�řd.�J7R�J�/��J8)X̒��o�
-Q�Z�����*]4x[u��đO8�h���H���z�(�\,�E���R�sгT��SSᶫC��]/E�R����f�9�{���1��\MX��nH����L�l��ܳ�������'�~�	�Gƀ^ݙ�N�[#3��Ԃ	�O��0KJƵ���2��I5�8\��MA�m�����Z/i�F��S��t��T�r���>��	�G1b�Ҳ��5���(���U![U�NjfG�Vn8y�4n���	����G[:�̯��W\�Hly�I��(;J8�TQ��(�HÚ������V���Bl'���R�~7��Njd�uP)pRF��� �t��8�hn9�"|1S��)K�2W���{ n��h�C����aa��-�Z��;��Q�`&�F�ྀ�[�0+3:=MD�)��-xX�ٱ�b5�̮��C��#S���#��U�>0�������7����n�v*R��h��S^(|���{aupt-���pH���F,�	�z��j��/��*r���]+#/E���.�B�|Z�)*���!=�SP���$T,k��e����C+�"���HC:�nPy�b�7H�%�x���áge����xh�V�%���-��`�%J>.G�#�T(]�ߖ`%S�� QG|��P�� ?�%������/p-��ai"$Ud�Q���JIǓ.*4��i�$6)��<-���[��ik�E�bL�Y�S�Xf
-�O)��ʦ�'_�Ktc9Tl�x�6�c��4MԋC&�~�@��G�s�Rl��,26li/���4�#����0��0\�e/1�W:����J��w.��6�w)p$�`O��#xڜ�2�I�x����R�2�ry�h'3�'�4�G K���2�3i�8ML(:`R�x��������� �}!�~��bZP����x?ι��Foo�</c(N���@%���K����x� �jm�6���V�V�����֡���]sx�t�ủ��� ]?ݿt�utu�t�uC�Cu�tQS��U�������i�l2�C҇��,UX���D�C��t&�dX�����ҕ� A��ނeCQJ�,�X�8�l �8cW`�(R��(��D<
-��@�ˇ�R4�4(4]��%@���i�2�P�1
-�Q�	�4E�f�����@Q�s�(۠�v(�GU�D�(�%;�4��7T�/
-�Q�(�D�J�FI�Q���}�P �	� !��@�(5��EM#P�H�tj�2�(̑(3eơ�Q(3e�F�	(3e&�L6��gI\`�RP�G�S�r�ӱ\)4J�H�b!3 ����| *��>��@�@-����|��x��W;�&h�$�Tɀl@A�,�������T�y�O�y�4/ f!uZ���ZB�yC�"�/���PZ JBi�(-E-�P�e�J0���aӵ���@HC�6��Vxm����I���hj��d[�-%J78�'I�,
-,�[|�@�D�8�X���e
-�oP�~�� �����""4�3��d*:!���v`���//\��B%���,5$�otTL�T�!:+ ��j1��s��!��T�4P�����lM�0� B�C�b܈��F�� � �0 ��!�U�@���n]S�h�D˜HSA��bh	{2A���T	�6�[L�v��+���@�8��Ɋ���"�V4�����4'�f�8�u�iAZ7$s�}!����ޗ��x#���tģ/M�����xY���Ļ/� 	C�[���� 
-��F|(4$;d�p��Dd�I����}	H�_D���� "�@@H�ဈ�� �����P5"u B����H8BF!h0����TEH�HBF��r�j$�ajD}�1Sp�A�GE�Uq�B ~H ��L���Ԉ�j�ar�p5J�5R����Fb�id�1f�E L@(@���K�z�HD#`N$S`IB����(v������LB�.����<A_���$�����?� !JA���(�/��I��П��H�z�!!)X��88QHd�h~ k� 0s@@�t�'` ����S��J�/120C�٧8LO�� �f�X� �I	E8C#����p�;'<q(ۉ341���	Ib��%b��J�v�N���Lc{q� '*ƉQ���F�,�E)�-,��[��u�����%ao�D�D���3�$j�w(K\�N�I��FMAF��F`Bk�#��l��6`���9��SM8	cX��N���N���$SX�,��[*�k����D�Ck�����`]�{��N���Dt"ŐM
-oR�Dv��tp(�=�&r�;	8�$rg�z5�:8C���?(}16�.�{u?�r*��ě,�
-�^�q����=�K���f K�9W��?��Y���f��*������Q g�B�N�%���^��4��^J��.�]�y��M��y],����u�3�r>p�(��q,��6�fv�p�B�Z��8��a�#�h�"'��_����P*�?J5��ۿ3��M����>��I},�엃����OεX�*p+{ѭ��\W�®���5���T��r=`m� ]�kc��Ʀ���	��Or߂� R�m�%��.ѷ�B��2V�0�?��6��ޡ�m��n��tS/�.�^ȝ=��٫Aiui/dY��rp�L�pC�����:צ=���ۅ���8u��}�����q9)9)����R��}��"�c�q�O{vW��WF֡?�]�m�v����Y�w��#r����OJt 8�t7���^:�O�©:��/=�p�)�G��5�(`�pΣ���A�8���?��Y��Ξ�z�N �y��d�d;���ԟ�i�:���t���v�y��ܟ��I�I��A��i��D�W�!���=��R��!�<`]�����.���r���%/�Im^� �K����C�˽�W {�y��*`�)�W�A_�����g>��U����o���8pj����{`�+����o�ى=�I��?jPq����/��
-_�'�nu��&ξ�O���
-���������Nª�[���q���T:u}�W�;]ʾ�y�y��{~����ǽ^���ߡ�\��;����~W���yp�Ҳ�2������ϼ��5��ݯ�?�~{mX��dߏ�V�ǽ�~�͛���>�z
-��^�f��@6�B� U���Y�����]{��.>�|���ԋ^��.��B������-��OZ�5`Rpݫ�7��@���~�����w�G���/��B'((��9A;BIЌ�D���Xr��ʔ�c'����k�[*F� 1(�;<��-�	��L'P�-.��q���j� *[g���Ahɴd�q1v.��R,	}6n,}t_��JlT� �;.�[�L�M&�9X~qz2y>l�LN&i�kogktr��p'J�cf� M&a<B� T�%�BC�X��tB7����4�ڠ�v*�J��&���=�H���?aZ\�օbeU5,߾�>�3�u������퉺�],�< �N�����Xk�*��#iu�7c*$
-�4S��z�	�'"�M�Bő��u	�	�5��`ݍ�HBH0�-k�4��@x�&��!�m��)v\R��W�E�j�L��v\�� �$�&�Xm�f]�D�@"����P�oԄ�;~�!@ �{j=�a�	$��İF`������`?`��e�&؆8c,�:FH��bI�I$r̫�LjBL@�X����5��I@끵�)x������$�2t\T��~�B�JR@IT�L&����S�,�W�hV1!D�y͈�U�1�K&��7�4$
-p��HɤZ���v�_]"�D��uQ�֫�K����:.�4B�:�t�:�|Xs=Efp��)XfpLn}Lny�r�_�	d�6���h�[5��LGV3Ol���Q"��%A�1�R�w|=j�����i,Y`	!f��t�,s�3��.m�Y�D{v���X��e��@�[X�"�����T�����}0�
-?�F���}C��Hu����r�3;ϙ=Ι�����b)Yۭ`s��\��=r��)2�'��{>V�/�� ��T������ˡ�W���v��8 �3'�����������%�f�y@��F�~!��X�����B̛���I�o!pɊC �+'7Qq@���ڕ�4E�{.�2mYJ���<4�<�₢��w�Z�5�����`ԸU�7������%���-�W��wf��!h2I�ν��s�9��{����:OB*5t�D��F�%U�x1Cd8y[`|x.��He���Dk[`�bo҄�KE�D8Z���	�J�F�K���ȝL%��������,�j$���hr�W��������\����Vk���Y��N�g�I�0O�Zqeb^\�bl{du d�ryj�*��:� k �|���A�=�����! ���25H��c7�SV��fNY��W�/9[;��m��*[���˷����=�J�R�hk��m�E��fQ݄E�0g�䚶CA%���݈K,*�$��ES�A�wS��.�����Y��i���m�2k�q��I2��$SMv�P-s�#��F��&V�XTl,'6�4���k�4�kzC=��1n����K��v/Fՠ�Y�~�(��7�],q�ss<��R���x?�Kڨ�p6bz$}%�eh=��
-��D�Z8s�z*�,��ܶC�m�z��� �fg�p�«A%;1�\3)���}��o�S����8|c�S�T��%� 2�g���d�]�s�g��e�X�� JpDw����jG��[����^΃Z?���p��Je���ȑxe�X稄d�����%S{!����$�aGԥ��w���A}���I6�suW��7|gj/�Q2�i켹tӇ#a4|8��Ր�����|1���������F��Dn�.�lJ�n-�r���s?B�.$����:�b��{�+���ְ�C�� ���
-�^KN C{#���C�*yE����0�|�����jl8�r�L���}'?��\?��j<?�3��� �ogG�1��H�t�s�	���_̞�AZ�󀬈�i��a�O�iE��ƁZ�����q\Q-�u��Q��	�
\ No newline at end of file
diff --git skin/adminhtml/default/default/media/uploader.swf skin/adminhtml/default/default/media/uploader.swf
deleted file mode 100644
index e38a5a5..0000000
--- skin/adminhtml/default/default/media/uploader.swf
+++ /dev/null
@@ -1,875 +0,0 @@
-CWSu� xڤ|	`E�wWWw���$��� �Cu�]�]�@B�IP��0IfȬ�cg&{"�� xq��*��(9�����/�߫�#�����^U���^�zU�c���IQ�s�BU)��U�?�0E�c�1<����xvs�%>�?mJ$�F�9k֬�N��1�N:i��G��Hql|NK"8�ؖ��CO�����H["��RL�`}k{�OC�ڥ66$mk�Ee��#C�Ps�%y܈�PPc��pk�9�89���4������7�6�;+83tl8�7�qd*!�ID���%m���Pqy44��$�]&�RP��T;O�F�A�[�K�HOG���룑xS(��S�N�
-�Pak{Kc��TB����k&'e�[f�g�N��M���I��A0:���;���ڱ���Q���j1��8��d����J��=�Ge�z��7��� в��>b�(���-�[���hk�1�k�]�lAձx]͜x"�<�
-*��|GQ(c8l���J� �r�j��U���{�q����.6�5�7{5��=�����o>����y�@b��{��������$�����d+���\���^8E�����ྎ���� ��<e�����S�����S��w۸?�ʯ�~J�E�G�:e�t�8�>�"ƴ�FC�mfk��#�kD{"��K#4~�؜,����E�s���T��[=uu%5'�Ս�j0N5`E��������XL]��-�����H���b�9FM"i��#-��R�X+�mU5#�ڬOnE��blS$�81O5m�H"dV#�!�k�	jt�(�"c�����	w-H�\25�m�B���bFe{s}(f�Ƃ-qZ\�V�`CC(��G��Ĝ>%�ɱֶP,	ŽS*ƶ6���`5k�h����I�[/#�DK���#YY���Էc�2���Y��Hs(fe�-}�1�G�
-bMjml��ʃ4�s�5�����٩�2�B����F�e�?MI��6c|2'�O0���Bg��a�Me�X��&oEU*`Z����)��Ck��i�XY�r[,d-�xaM[0vni�b8e�	Ʋ�C���X����PC;�z��*/ʈ���
-'�(����
-t�5.lk�4�mP&���h���D�h�!��	R*�t��c��F[gY��+Z*C�Px���V�ĩQ���YN�)�lD�ROZ������ fE� �ӐZ0�JT4�Y;��-��V��*��ˈ$��\(���f��Z\h���OI�5���PV��$�Fն7��#'�	V�4�fg��Cy��S|
-�1�p]����љ�3#o�%�����N�1��(�zd��l	�Hr3{�;��B9�.�1=3�:S��6��)��r�v�P�E����I@��F�	��m�<�M�E�JC�HK��w$^k�D��FP��nsv*���5����4��Z�`_O�@�DCiˑT\�1�Mh�\�5M�P�1~D�ef0��n26іDM��F[��HY�!C��T��$��m�	Z�+ #�C����h�h����b��@6�������s��L��j9g�b��L��h[SP�iL4M�Ȍ�$
-�$n5�����l8wF�,7f�5�~�p$
-)�����2�Jv�jO�4f͈�����[�ˊ�m'�&u�Q�YM�D-���M����'ػJ�n�X���8�3�W-Z%��`�����:3��i�.����PH%�Fd6K�4����!LM���G�:Q�e#�g�DC��`��ha$�hl�Ї�]*NO$.�D)w�8��Dc�FႺ^���@�o�2��ش(�N.��&K1�j�t4^�+�`��wd;�Y�����IAgL��N�4��4��X�(��9ضO�4�[��b�?�ţdf��:KԌ:)xu���u��>��������t�����L��	R��v�ޓ�Ϫk��!s5$���Y�B�.l�����l�<��2�G0-4+#�K*М��V�I��lEvf�;(m����P���IO-�Z�E�m���z��h�$��%��Qv]���֥��|kt�Sk�-���ѳ�ճ� E�u:=���R.'*<��/�H	�M�һ~K;Z,Y��g��A�Κ�����ڙ�en�rہ��{(/m��1K}��i��~I"���P�����%�/#&�N(���!��I�)�la��MJ���z��փ/�[��IE9)MEyh|�I��|XqR�8��N�3XC�2[����٪IS�e�5]KȎ>,�Eǆh(�D�8��}S�2S�s-��}nh��6�ߜ<8�TOlN~�µ��)q��"���d�B��hn��pꬱu�R� ۡ�Ȗ�)mv� ���iՋ:˚��3�,��}IDЄI�6�ܒ2z*sN�U��g���818��=Al[k<䩨9�ܶ��j��i���/��:�ճ�2�[4Ɲ,�^��TtA�Ä# ��f���w)���`c��W���12۸a9f]�^;�-�r<f�Ȍ�P���dcRҎJY!�٨iNy$�	0+#$H����U73����ʽ遼�a�v����(�[����b��7)8�^�i�RI"-=�DZd��HKC��1T�b�;�/h�1��R]�Ni��*-�#���N���f�X�8Hèl 9��^;d���t�	$fa+�Y�2D���f�<��RN4T}���&N�q׷'$�ZDC"�o��)No�b�j���d�2��2��ſj��	\H`�&Y�FS��ux�S�>��S�}�$//�I�}hѥ��ě��,N���k��%�
-:��u�OE2"1
-*�,j,��f!m-3�|l������$]�s�5�!��K��Kd�\���vΣS��9����h{(��h[�HQ�b��͹(�@��M,yc���z5;Қ�/}L{�@z��>X=�D͹�2CT2ݭa��%�$�}���d���CE&]�r�a�1XMG�PKC(����'�[:��H�lDA�]����4N^��O*��b�t$���+)N`��e���'7z��{%���������
-����c�{�B�Ͷ�؜y����Xz�SMK�t,�F�ړ�.4�h�����G��r��7� ؽ�I�k�D�>:��L��)��5���K?���*4yљUQ��t���䔥s��.CR�����`����U����S��_�b�iݤY���N��Ҕ��ҜT�����^��Ty�趜��VZX����<�]�q��H���n��o崖�mҰ_�������J��xh*ߤ�ʺ3*Jk��UT�_V�T25��][6��nRI�8��<�և���F*{H��Zs̺�`��]��gX�M<˛C^���(�6� �2������C�s��|��V�5�G�N��
-v�,:Gj2W�}%��1M�9O�9Q9u�3�N��ui��KM[�u3쨫>�6��2�)���uy��d�=Z�0zgxi�њ"���i�'��Ƀqd�P�\��q�ϥ���4��'���LՓ��<��>��ꩠ��P�����\���]������)��>>�Y�������[@r_�5���j���X!��%_5l}�?��ct�X���8��@��$���P�,��$Ϻ�d����k֐��F���	,FܖE�Zsb�]ķr�uA����ͨ2i�Ѵ3"�&�c&o
-�g��I�|N���Π���]�N��Cy,8]tIA&πHVT�P8���9��:��&?m�O�^��d�K3Gئ��ƞ�w��iJ����l�T*F$N6gnYzZa���������ѥm4%�'P�j�K'cs�Ƅ'���rǒ,? �*�ſ���z}�a?���/���`�[rMS
-w`Z�ѽ�0��q��8Ӻ��p��HZ~3�d�ַ�H�l����h��w8�uXRj�Q��$u��B.�c�%��Pv�q��+�b��IU�LU�r<R�Ǧ�Z�3e�Lwc,8�jl��ʭ���x�t�*�!��޵�%�8�9�K�]��,��'e�f<��H�G�!���&���sbvJ;�t��K!�4����Y�h��3�e�x�7Y����|�s��e�5U��ߌ8��F�ʮ(�XVW;���f|���,���-�>�d��6�D���9��8��-$-B�r~�Ċ����TM*;c|YuYv���5�-g5�QPZ5eJ�*���;�،�y���ԔՕV�Q�J��M�_�L7�������>,�.`��29��g_�%��[iY61�,W&;�)�&S��`k(Z��O���yJ}��CI���u�|�"�t�s��h�J����7�ޞ��ֶ���ݖ�Ǣ�Q����m!�d	����PRo��'������p�Ywg"�^��jj[�u�	ŦTWЮ#�E2^��j��������[��M�8�k5�F1&���(
-H�s�xHI���5���'za�5'���K$�~�+)-��\]6�������%iW|^J1�j��e�e��C�Ie��U�.�/�N���uR�I�#2���nrIuYem]�Ĳ���)�򒱵U�g�U��6���v`r��
-�>ٹH�O
-�e9�R�{�ff���Hm$G�_qt����S�˫�N��9��d\Y5}!QNoQ���L���WR%��|n�M�3�1Sjk����oL	V�eg�`�Ԕ���ϩ�9�iB���K*ǕՕU����P��赙5�%յ�-�~�����r�luYf�|=������R� �����{^�g��R]SU�5_ZR[��Ha�SRg��Fк���H��!z2�H]yuɤ�ܰsN.�(y���ѹ�2�́��P+�ZQkq���HB2�`�QQ����\T��� j]��4$"3�� =]i��2/��4��j�+J�4����gUT�^gH��V��Ȯ7��wSTE�Ċ��DE%~E��O����H�Gߤ��)"�m�=%�ISj�J�1�4C�4Z�ڧ���q%Xְ���gFf�G�r�&Z��L]�p帼��5A:��W���
-+&�֥	unKȺfJ��C�S]�O�R�l���!�eYH}�#�ZҀ%]RzfA�R����3����9I���ش]���d�a��n+$�š�d3��d��B�ՔM,k-9�8nFC��?k�5��g�[i��䒏'���9�R��R�S&cZ�W�����0����ʚ��IN��G��V�
-�B�z+�|V�=�NK�>g����k�&��m�IUo�[J[�}_�K1֥{�"�TQ�Wg��Id����L�H+fbUunF�Nf2���[��Fw]$^��k�����+�j9���Yp�`;w�g��Lj���A_��2ڏ�.x'FZ�g�4?Vy��I_~��H�]�?[8}�#+2�z��$[c&��e}®�LV�rZ����d�f�":09��x�����j�X� (��P���	�LfX��Y[5�nb��e��pl����X�q��,�R�)-�dW�7�Uk_���vJ���1��
-m��:�brIi݂�M���@���j+*K�؞� 5�� �;~��h����rO��������Q.G�\��.�]^û��rnZ���Qmݜ7�xv~o��q��s�4�GO;�Y����a����y���l�,m �r�UYUW3�db�wXn��$���榼VR�+cd��9�Oƍ�F4�2#�4��V*��TI�	ַR��0�"-Z[{�I�c�5ү����!�ż�ƽ�m��3���zm�$l��RY��Nә\�'�K���/��2��M�Lf�_��Hj3��������BK��xt�Owu�n(��I�c�[�7�Q(�����MܩC�����);��ˇ�]�[~[іh�� ��V����q%<7�v㱊�XVrz�;uA��q��%P��Y���
-s�E�wRMk���e#<t�)�|Ua6Ҍ����R�����S{��`HǍ��j8^4;yǚ�46��['�j/�������p�I�y�o[���W�-�VA�sk��\�֗Fߕj4�Z=N(F�iȆ��	I�(:�xy #�.Uܔ�B&5)�&1'r9�/zC4���0�[p*���&�o.a	��א�=>'�⼉���x^},�8#T��f��ϐΞ_���!@2$��,��jy��I^���-��q�d�eo��K�H����}-��?���w$;�����8*�_ff�Tm�g�{�Έ��=����(�k��q��k}��|ҙ�?DU��Ү�SQ�1T_flE��]�3���͌��yXX�A�p���;BK��CGd�<$͡��#�of��b�R"&B�Z�q7y�9�g����K�90�hyB
-Y�]Ef�+&Y72�?Gi �-J_��U��j����rՈ��z���,��R��C�.]����$�u����N����D�2Y#u-&�nJ�8���Ie6�&7�j쮵n�6'C�����f��2f�Dr�&�/�)s�K3��Z^/N��3����F�w=��h"�Ʀ�Ah��NH��Z�c��m��x"�ꒇ�I��c5ғv�%/��w�f�1�
-��I�Dˠ���X<iAxm���e��,�ĚY�.M����l�;�^~$i�u��*_ȋ�p�c]3W��6)�h���پx��tF�8iO�����Iǰ>�7���T�93�������dh�q9�����p���az�g7b��b�i��������G����e�Ëm�4��F����.[ׯ��7�`�npL��&�
-��kM��7,��?ʈJ��
-��x��Grt�Do��K*[����=U3?��Q.��}6WA�ma/�Ɉ����7����ɲٳF�}v陕%�*�N�62������4/"+&M���E��Xf�	S�nJu���NaG�#F�#F�ua���m�m:��6Cv/L���9A��&�,�L�ژ�Ӗv�H������w<]|7���D�ׇ��m�i���)n��G��H}�"[L_^Ƌ[c������D1$�i���ʺ8�|O��=���)�Sm^���_/U$���s�e�~�b���Y�dN�0��_~��WQ{��j�FC����byf*vn"18�eF�����^��X�1��ܟ���'Z����1��ql��]�Zc�g��q�V����]꧃���9LF��O����K�pP��M*V���W���t�����q�������zyۧ���J��Q,2۾>w���������qز~i�9,2���m�9j[�`�{���i���8/�,�8���*��Ɔ����I^���/�ü19�>�,�Ќ��my��M�-!d�K�������ӎ9Zo&�70N�y�/Aɧx�"`|(
-�+�y���ۗ
-BJ��b����]r�Y�c�����c��d'�&Q��洲��A=���%	V�F��괳���FZش�p{4j�<�;
-_*l}��5�"Q51[M�ɑk��ѰrhA��j�'��O�|��N�1�unKkùP��tl"s^�i7���S����F�ڂ��R�X�����L��E�t�Ay+`Z�Q�*p
-
-�
-/8�`p���N*����5��W{�
-�+��Y��u�Zx��+�K@\���{��(��Z�]-ܡ���j�侣��S?P?��Oj�A��<^8���箋��R#f�UD兏��'�u��o�S^�9/��|��%�R͵Ls��
-�h�7h�b�+z�2-0t�Oa�
-Vt�Qt�Qt�Q��(Zf-7
-/7\F�ה�Q/�\t�Z�S��]-�^����Eo���w��.��T����Q���qE���\����3������jj��~��3�:�/N�N���ײ�j��`�z'}fP3X�'T3 <�y�I숦H͑eGd.`�fGk5�t�Q(�eJ��V��y��9:6�u�p��5�ʙLOԌ��ŲO}R�f���NtM>���9"��d�w���?�Y�����?��U]��}Dd�X��.�T��Pu���L�{����+X�`ق���/�\��	�/����W��	~�`��1@��B(��=Hx��P�>J���aB.<�
-1B���{�p/�'�o���"�w��^d��?�E��B?E�?�D�ʄ�\��	�x��	�w��M�I�W)|U���W���
-��?]�������%�g��33O5��"0M��:�.A��h���E`�4�@D�*�@T�E�EZE�M�&1����3E��;K���sD��E�?D�?E�D�E�D�\&r��������E���%�B`�X\
-ԋ���\\\	,�˙�W13��}5�����k�ȿ�u��𯂻�	����� �c"�F������L�7����
-������l�ȿ��N�w�)������FY����m{�ȿ�m`����}��N����apw��	���
-�N2t2�Q�{x�'�kl�`�{�����g�n��U?oH��p�D~'
-�7"��}؃�^`���TcɊ���y�Z��v�`g6U�3;K��;U���U��W��U�5�u� ��&��6��.
-�l�`���>�d�A�W���Y����џ����O�O�π�Q����W||||��"b"�Gx~~A��\���q�?��P!����yT	6I�6��&��"�|U��@���E�yA�Ū(�X�B�E�"���K��2��ý�p��]w9ܫ஀���p��{-���^�����sD�5p ��½X�@.�O���{���lnnnn� ��03�7��x��x���ݨ�^`+p��_��/T��b�#��~�c����П���4��xx�t���:���U�؋�>`?��9�"ܗ(�*P/�kp^��(4�7��T�yտ��a!�������O�O��T1�s��K�+�kU��҇c쇣H�-��=�����(��z.�|.�_ \ \\��	� �E�b �/��7(�s��+�+�� ��o��]`$N���߯�����w�q�97U1z5�� k��u���z�&`'m�{3��]��U��.�}+\T=�6��~��pф�w�E3F�	M9�.�7[����{��
-��6�~��0y'a�N�䝴������`����䧀���y��S��v@'�t�{���>`?��"��2�
-�*��:p x������Ls	���\�i.�4���~���|�t���������/�(���q�q�����#��3�pi�S���	v�&�̓;��p�� �p/�{1�K�.���b�K�^
-�2��W��&*�W+41�j��Z�:�zM�4�Wk∵6(lf끛�߀26�3�M�������f�n�^`+p��x x���x��N�MLzxxxxx
-xx�w�@�&*���`n�~MTaL����� � ���> >>>� ���~ ~~���w`ppp	�X\\,�+���k����Z`�� l6��w����{��t��]L~P�=lv ;�G�G�ǀǁ'�'����i���xx�t �@�<��"�>��������+�k��~���M�)�6����� ��__�B�Z�7�R�p��~�}�#ܟ�����A`�!�y0w���Qs����
-8� �E�b`	p��O������V����E_�Z�:�z`�a�6��X� �3P����_�47b� �� �$��DS6�Y7#���w&����������C�pm��0��	<<
-<a�`�`��Q�O���4��x�%�q�J�4M��4̕��D|
-l���_ __������? ???� ឋ������K�E�b`	pp9p%�X�[��)˅�r�X	\`��CL���r�A�0X�l�w5�5�Z�`�0op�7Q���	�!�F��͢�J���¼Js�7�izL�jT������O���ۀ���Y�sL3T�~��#"[�<���˞D���y�
-^����[��p��25�<�@���\��*N]/�~>q�U�:R �槪��D�Ef��sHV?���i���j�����﫪�)��-dy[�˅f�)�����/����}a��9�,s>W�5h�N�����iƁO�πρ/�/���P����o����i&���D�|Q�Rͅ`��谹 ��%T���цy��bp/��D�rW�>XD.'r-���u.�4�1��+4�@���}��ߪE��P�*W�~�f����c�֣��\�gH�%�k����M�-��.1������]�f`p7pp����f�!�<��Y���42(]�Z-�&�Oj��,��EU5��hMq�n���ǣ���L�LJ�1��?/
-��BTV��e�Odd^�Ve؝²z��c��T��(>
-��&*�]�굓�@���"R��:���lYT�Q�^���ڣ�,�$j�J��[L�f��Qy
-�W�R�_�M�츟<�/7y��M�C�>iiXv�C�Y6���c�YAM�ۭR��T�T� I��Xͮ7Ǚ]���]o�rӷ��$=g��Ș�T=V��@J>)M�]���8d4 7-���bD8d P�N8|������ɶ#��7b�c!�v���+�^��MeR��%���J��k�0ˇ1�J���?��Q�'s��t˨�ć��~nVj�5(Նld��j��>d=�zM��#�O(�1�Q\�k���w����l �``��!ɽj�ץ�.�=����&$��kRvjn��P�[��l��h����0���wڟ�6L9�Q���+���rR=4��{ 5�y$�e �^g�ɣ���2Fd�I������AE�����1Xq���S��&��I�;�\��.�ʤ�ƌ��aB9^*��Y�����W�<���͑S�X-=�G����<y=�J�zu�Eԩ�Χ��1�~��,�AH=��(%sm@���J~��j����u�e���tࡍ�VFy�җ��Z�е���#��l����s���դZ93�`U���{�J������;,����Gg6����n���H�9�`�.�RtlZ����!6x�kKS��HK��4hT+����>ғ�$��V5xk	1w;l^��y�����%}����ݶR�:3c��i}��tT���C�:��h�<Y�/�Ф�(��w���P����+]=�������0��0":�M��\�'ͲRz�b)/ɀ�a����*2��X-�IVr��0e�����dg��*����Q��h�U�D��c��=f�$���1u�v�G�x�Ĕ��<�s���OaJ��L�-aJ
-�˔�R��)cJa9S��cJ�x���Ut^1������*�OR��I\X�*GT�ʑU\4YU��*C�Ueh5W��Q��kUe�U9�tU~��;UUF�ɔ�g1e��L9�/L9~SN8�)��c�o�3�� S~W�ii��ۉ��򇐪�1�*
-s���rJ�����+%U��ؿ�J�_�Rv����˕qQU�JE��Lh�ʩ-�2�UU&��JeW���*��ƕ�b�R�JM\Uj�\��P��\9�]U��s�̙�r�L��=KU�2�+�f��9��R7GU���J��R�w�4��)��dJ�_L	��)3��*Ms��#��uS�s�1�D���|>H�D�^ �v����&\�N���\��5Sf-�U��,"GYl���v_�Ȩ��r�\���q%���p�1e9#k�*F�V�J8W3��x��W�N~=#�\%�jFKb;B��d�2�޿���VCnB��y��c#���n�o.�D�s~�[���n�6���|v�ժ;8�݉��.������ma����Bv7�/b������V٬�࿄݇�l����"v?8��rg	{�K�C�_ƶ�^������+�N$Z�a�V�c�X�C�U�q�W�'07+ٓ�_͞��=z-{�:����\ϞC`7S:X�:���_ͺ�T�#���jڋ�Z�5�������"^@�F�"ֳ�_�����2�F�
-콛٫�ob��{�Vv �6����7A�`o�s'{�.��f�.�����}�{����A�������Ǡ��'���OA`��>�>}�}��}	�0�
-t�t'���-��;�������@�`?�>�~}���4��vt����������Wi��d@�����B���"�=�bн��}l!�~����E��%v)���2�W�堯�+@_cW��Ζ�`�@�`�A�dW���V���V��î�{�5�^���ˮ}�]����*�?`��������UI�o��c��v#�l=�g�&����/�F(k�v3B_�M�f_��[���#�����ʏ�VY�'���nSi߿�U��r���<P��<P9��BysU�4�)�U�f�v�-*�z�����^��
-��}��+��P�_%���/RP�r���L�8��ۥ�a��;d���/R��hrۦ������^ʕ�����+W��ÿ�+��'�_�>	z���
-�iЕ�3�W�r�.����u��_ʕU�s���u7�k���N�u�\�Q�=(WnR��ߠ>�Q�z3(W6�{��+�����x?�w�r����ʕ���-�K�w�/�ޣ�z��*�V�5���#��0Z��rxH���oJ�����nf���	;U�����*�����Q_���壾E�G}����.-�=Z>���|�h���>�����@�CUޅ�H�/c>sj���x����>����cU��r>U�6��|n9_XΗp�x�_���~m1����~K+E��V��=����?��P�@��V���� �u.ǺP��T���z�Ps��*�s���95p�3��v�%�t�����0�Cلo��9�%��(%���N��r����Ɵ� �,�9��`��4��q�y|��:-`T�|1�R���%;����c�%�]�*��Q�9\���/������+-g���2P��\ҫ$]!�JI��r@��I�������14W�U�K�j�e|�r���3G �z'�@M����9RYɇg�R��<N�`ua#_O]��k7��[8�ʭ|#�m�f��9�
-]���Mm淀n᷂��o���z/��Jy��wr�����p<�߇c���|�߅�|3�;A������\y����\y���$���@��4�
-�3�\���C���m��)]ܸ}��ū����C�|;ru򇑾���'�|��NN��#�,�G%}L�ǥ(=a����5[O[�3��|��,?B�˟�G*��sT&�Q�~P���;(1�W�y'8/�.9+��̻�y�?O����^EӸ��+۲���~*U�} �+o����/��&(W�����/����W@��R"�_C�=�:��� �������@?�oӊ��Њ��Ҋ��~���� �%��+����c�o�'���OA�㟁~�?�p�A�DC&��Ge��|��?)�i�+�f0dv�r��5_�}�I0n��|�n,ӾE7�k�!�*�{���+�A��~�F��Z��봃��ks5����]��]���J�����ஃ{��^w=܋���b��^w#܅���"�M��ЕVn�|�	Y^K4��/�h]^&��^!镒Ҳ�C[��wj�@�Җ�n֮ݢ� �[[	z�v5��5�[�k5��<��c�9V٩��5�|m�fzJ��5t�4˕��!kP�Z]��:˹�r�[�M���7�)P��(�im�ƕg���ōM`��6���v�յ[�zN����m�J3n�C��N�M
-ӝ`uiw�խ�e�6�����=��u7X{���ڧ�c��k�v/X/h[�e���zQ����m�~�^�����˫ڃ��i�5�+oh���Ic�����y_�!�;�v�w��A�ӎG�W�ki;P���N�?���+�i���9(W��C_j�kOh�ʷ����iOb�'*?k�z�2Z�Oi�@�����͟�^��4E��'���Z�WX�$T�$_5����nd�ܢ���ܦ�N��<wh�K3t�]��óEc�k��ܣ�=(�AXS��v�b�Ճ�UTFU�Ľ�F��հ�`*��AU��t�9N���܍���n�U4�y�5ͯ�Q_���^�����74�k����7_P����շ5��%���}Y}W�g������_U���9��o�����;����j�C��n�}D]������n�}��u>Oz�}/N�.OyWp��~B%��ص<Y٧薉���������tk�A�%�� ���7�����Op�}CE���o���j�;j�����Ue?�<���i���O��򼫱�5�����_4���Pc5���Xcsu���Tc��F��s��Ӎlϗ��9���S��y ]t���^c�F���.ԍ\���n�y���b������%�Q��������s���F����F_υ:[�E��uv�n��,��e�q�g��.׍��Kuv�n�\��+u�pϕ:[�Şe:[�=W�l�n�Y���t�H�5:[��<��l�n����պ1ĳFg���P�:�V7��ܨ��t�h�M:�^7�y��V��1��u�Z7�{n���8�s������:�A7Fz���:��٢�u�8�=:[��{���&�8��Mg��rW�qe;W�k>Ϲ3StC-���������q�����P�iܢ�
-�U�p���ZtE@��XWL�b]qC��n�-:Ԟr��dA�J6t���x�ޭz������n���~�0�􀘫=�\�i�s��]��k����=�]���Yh����Gu�E�c��w1����>��x�aO�7��t����͞�!u�b6���?��a�\�)�s[��gŽK�Co>���1�����P�|�n0o6�@]�މ$;��.�|��?M(�=hAA.ߋ��}�a��'SU�4ǻ�����^������_��mM�PS�I��AK��K��G�e��'mx�ڟ�`e��r�tc�
-�KƎ��������&Uc�����*�)��Uv���ϩl7�w���Ab������ʖ�����Ӕ���݆`΅�-��[��b��E���d?]�٥���l���^��Z�`E�������� .֔>wr��B���ܾq{Y)�������\�)���wl���X���+5�%��[�v���y��M�iʑ�j�:�����*����V��ƎՔ�hl��%r����8"����'���Q��8�fLuw��vj�T�i�8ں��NԄ⩬)�
-�4�:��<���OU�r���Ŝ��Ǜ���sf���u�S������s���'����yF���v�.m2���.�mz��Q��+��۠�ܠ��`L{U�,��/�;Hi�wi�\��0��]�b��}��s/��Z���k:�6�^�*]g��Yol`>��Y���(JǨ��a�Q�4��.�x���z�����ٸP�����s���5���iY]�Y�������kv~�{<���oR����=7�'S���jG��^�C�NK����e�]=��|�
-|��?ԃ���Q�{���� ��a��)zy@G	C�2
-���b��GQ�LUXx�>ի>Օ��3�\�_x��U�;�_�s�y�Z�
-S1����U���b���C�)���W:=�N�Z��ZW|CPﴫ٠�	W3�t꿆M?<���BG��ou��f(V` «�xE��r�gNǨ�Y{����ߡ�es{:�Φ+X�x��r�󗲙r�OG��+�8�d!�!I�jUA�]�,�0PN�b4�����@�������;����&���$�RU�ǅ`g�z��'�7P�R�(z.���ַ#�����D�d�M��R�6Q.�%���gJ���i����[����XǴc����b�Q-�6�N���[�D��j������cT'1�����;������QG�9j��0ww���t�=!L������=�o��_iJ���:�ʿ�Ԧ�Xz� &qP煩6l��Ei��Bu_��&Z�H�=��������]���f�aV��6 V��9�A��Ӛ���R���.$~��k���xu�v�����J�Bu�VPwo�CͿ$՝�^�֝�ԝE��(���(��T�(��2����@1�{��uR�?�D�;��?��� �eK��U��XG18(�2Y��1j�xzǡ��T�UL�<��WT��1����װv����t/��['�]�j�j�R�nO��� �`h��ku�Ԟe�,ڍ�ey��G)|U�x<JV8���q��M�p��q�مi���>���Z��0��i�����Ruw�i���U��T��r�e�)4�sL%J�F�{�þ����tN?��a+���D�k3�^i�.���f_��:��:��s�>�Z��'��.F)Q�*F����{)�n�1a7�s�xH�Z�@J�ii���8iC�:)�^�u��ݳYϧ�ՕlV7��(hmj��P�����c����;i���_'����**O�#���Sx}Za����Sa{���T�M̀f�!Q������W���UwVlOԗ�x�.h��c�l�x��Y����1=���K��k����Qgk0F�X��E����fb]�j�u7���fTo�C,ʦ�gl�Ǯx���#<?#�/|~��cS�x� �Y.�t�oR�R�`�}jx�!�a7^`i����8KQBl�"���!qn�=J`�������E�W^�x��%�ʱ�����v���β��׶_����2ۙ��i�鴞9��M��,2ttGVS^��Oqx��)p/uώ�˦ ��43��ͧ�l\qj���U�#uN���[�l�1NS�dS{Mk5��]�6�h=�YQ�ذǮ8|1:eoD+a��Y���g4i9�dĶ-����RZNR���U`�!�#���Z?���K�
-�Ęk�R�Խ*��?��4��
-�(���R.7pv��0��+�*н�P�E8)êw{<�2�|�q,�[h����IQ/��ዖ�!|1%�d�wB��.�^����|�kI��t本�N{�OU��G欜�=r{��Gγ�f4�
-K�ẽ>�d�;��F[�Ţ]�x��婙�8�
-���f�.��I�?*QS�O!�+U`���^�Z�	�O���h��,A{:�-����mwNj������uZ�r��.����v��T6�*EM�d�C����]!g������k����O�U�n�J�7�����*��6ѮP�]��:�>L �fMNE0�n�I�w2��(���}�4�ݝҞ�$��ku��2����2��;�n��mF{ȝL���1l/�ر�����.������.iP�[��su��2�f�&�o��ޑ�-iu�+9wKN��ǒ�{�-�*���˓ԽLnO�<�����`���u�%�).P��`|v�kT#��ק�o&6-�^/�g�� �� ]W�Q�� c�N,����v���L�ݞ�aERp,�G�ih⇌fc!�9�C�J����C��a���*
-r��S;��f�����@ڱ�c�.�,��w�������G3���l&U%�v�n*=����(��14��|���m�cD��YРa p�m0,�j��v獲����j��[��'~��"�7p� �0�{���*��Z'|H�	���5}�L)P�����>EA���w{n1h��B��t��EӔ�<9�sG5����I��>�¹�p0%�������LS�
-������2��n`��ݴ&�26aS��Bh�҆���b[�/�5���)Fqx����?�����12);,��l�)�m�B��@`$�n�Ӄzn�s����N�:�D�N��`t���%E�_��<U���ݴ���1�]����5W1���W4�Q����H�^CVGxCYqkb|�I4��wɦ6d�g�g�{;�p��z�>��9v��(�+�x�r�E]v��A�pΔt>=]A��dFd6�+��?��i��d����0��<�>�GN3�	������>�����l=xP���{�|7��&]_ԛ÷�W�Z�dԍ����)w�U��k����i�,��`�ky���9�󀜰��<wp���TmG�)4�I�i�&��km�x�Q/#��~Z,.Fw����o�,��Ǩ�e��j��$���[8�c�CRyk%�2�J�Uy��7�o�ڞY�m�跜�o�=,�0K�+5�^��S�m��Ԥw��oK��<D�?��yOrM�{l5�XZ�d���8J�tW�I��O�������Q��~yM◝���������tF�����$�.>�wJ�%{�搌���r ـ�\���
-�at�Չu!����ڴ<�OްAOuAE�(��z�:cB?f���{�_��̾�_����Y~�!���u�2�ѡ�R�Å4���H�Z��9�o�fK�L�uȁ/��qz���Hj��ַ��/�;�MH�ɸ��Y�R�W&Ժ�3��X Ke�1s_gx�]6}�Q~�A�[�\�m�Z���z�^��嫰>��z3�����(�3ܤ�4T]�ͤ�<:U�}g�
-y�z��4��D�o�BʳvHQ/��e�T˝�݋���m/�?-��t�x'M�Z��
-�7��g� ɼ������;�[���`,_���b��ΚJ�sܞ���R^�,y	o4��w1DtV�l(���aU���.�.(��[+�P���}�%�ǡ��%���-��ͬI�W;w�8�[��R�����cB?N'4=����f�mH�\^iZ��m�.���w�"����ˆ)K���0�u.�1�	#�Kݳ�g���K��/�A���A�?FR�<jt�/�vܪO�2���P)�����%��7�:��ɩj����D�Ev)�T���d�_�PD�\��4ɠ}힙�NU���{e���=ݖ�).a�b�0�����7Ӧx��M�eSHK��_��2�R>�R�4-�Zd�z����O��Zw�F����;H���j�D-d4��|��s�Aަ;z�l��b��kZ1���6��U�iH��bXi�<���X�-�;�|n�:��4��]�t��5����n�J�w }�}\������:��H2��yR�>Ψ@����9)U'҆��T�>�묇��%rb^�3Ԟ��MG�;��:9�jNZ���a�=�4i�J[�LP�����dG�8:���6�+��C;&l6��-#k�� ;�۱��2%�󒽧'{o��}���'��~�'�%�~�'��~�'�5�~�'��d����챶�7�K
-6�0�˞i��r���i&}��;e?��,γ��q��w-�����j�O�֪�� ���Lk���_�cI���BN]�(��"�Y$X��a�����Qv�v�W��?s�d���I�<8��c��A������tW]�2g����X�����݆��ߟиΪ{eZ���Fgx�1�3|<ۀ��7�������������E�d�vӡq��o��F�!���R�K!�`l��7�b<l3T_�b���;m��l1������0|#,�c6C��[�y��p��^}�3��6]�_���f���?Dc�^a>�v��4 �c�>,�,�;7�?a��4`�D�i�(��y�sK`�0�N�ic�<O�d�eg� ���~!���/��y��F�>�$�_4a��������4(�Z�Ǡ}��^,�b�l��g�-0D�;�vB֠_H��5)��#N�I6*�����U�|��|�}�~�}Π��3G���ˎ�{Ծ���j�K�Yt�_��!�D����wcC�T2�=�MQ�;�p.������S����S��-���NJb:�`���\�&��^F������\�B�[�U���"� 9�rz0�`�N�����`�����zݱ����t
-�}9��:���KݿA�$�r��}Kݮ_G[g�v�w��]3��:�.s�ё��
-�C�Z�tZ�P���lޛ�3d���u<��M�S:J�'�k7H߾�Ҵ�s�}��k�(��#Zw��6�r#����erC|CJ_�D;O���*l���E���0�p����4^�������Um�)�F���.�t�;�G�����MX��j��|��
-���e�(z�9�ٔ?�E�V����9<��~Q�k��;GW�J��)��s:�{��f�-
-K_U�䚂��C�af�\޽�S0q.��$0	�Y�j>���y��_�z�e�z(��a.0�2`�ġ��{�����,'̚�뽵�d!����i��vΞ�C+;�5�]=��)��mG�.�c�$��P�]�\�kw��Q�~�Jz�0� u�4���F�]
-������HHps�0�.l�S	�v�\hBD�
-��Y�]A�ӡ'T��zL0�a�+#�KA5����Y�a��W���5��l*J�Luc}���^�j3���8Ւn����lO�lVt��f�ٶ(�;L�f����(�듊 HTc��<�}���)(� ���l�7�\�Ap�� �=sklLu����_ހ��/	�
-���Jn�-�{��]�d��̂�D_2�3�}7�d'���2��	��oh#]s��j2��Q��>߳�Chv<�8�f��Cjv��8�fǋ�C�:^Rj��e��jv��8�͎7�I�C;��� o����Lk��^�ڟϴ��}\Z�����FVS>x��-ȁ_(��Ӑۖ.`�w����K0�"L�� j���TN�j�R���2����g"3�'� �����Tp�L3�P�lpB=�p��?�'�<�#�4��K�f�NA��(�>�r~�0ڂ�R��:�rz��2V���_1
-i���!W�Fe��
-�*,K%���x�5h7��7d���)��wN梅���.R�P��0�V��"�� y��\���=ϔO{���i�*�l"d�(�XA���}މc�W���Ō0J �Y�}���
-�2�� ����h�Ӈo�sjٹ�I�Ҳ ��z�ʐ��:��sG��G����fCE��N���~C�z�Yg�J!d�(�*�K.�����\��0�EK��/Q��?��Ä�r{��A�(4�� v��h�^p��h$��Y�tF��Э��5��?�΋����較�z��7 �ьS<�����⌽��7�M�'����������"���Y�k=o G��1R)�;=� ��M0W�9�(a`�I���;
-�H���
-�)ز�,�?�Wq���;���f&<��e=��q�<8�帻�]� *�?��ه��p�g��,���dщ)�r�=�NW85���(9]bl���'*���\঺�\��ft�־sG'��	T��+��
-�V�9��!��T������HGR��~FlP��,$q��ew�.:��H���ď�^��ޏ�Y��Y����iVopV�:'��I�쟶+�©��~��tK�Vh[&kW##��`�R�[{}��t!K����7edV\B�\��T��L|!��������������H��z7�K�z�C�H���\�B�7�(��xYf��ע-��$X�yH ��=�L����v�g�&7�Α؍�i������N�Pl�V_���W�7��Mj�F�pg�&5�Y߬�oQ÷������0����J�Xg�v5|��SoT ��{J�.5|���z�������z�W�N����8Ehm��녶F�u̝Y�^@d��)�(��<�z����l+��;�b��Rp�,FwD�R��\�^c7������_)�lI=6>N���B�Lm_+��%ι��e�~�I~s#�@(���������X�W��}�`uc5V7
-�V%AT��+�VT���1]Y^�~.��W�"���hS��u��~��B4���Ⱦ��(!+K����g��f�7Zk�qb��U�x_��7G��` >)Ǥ�uW�o�Ҫ�؍����r�䳸ͣ{� �$��9G��=�HE��02��"��%�6��;௢�Um3�:�-hwa��&�L��͸(ך�[0~������?ތ߅�A�d��I�hf�#f8Ɍ߃���}?�F�Ջh�{�ڪ)�(+8`i"��K�/|��-siSv7�$y��F�SR�ZI{J��H��%mD����&I+K���I�*RdT
-�,i�R�i)|��=��G�%J�n@�`y�T����~?��/��~��+�sU�n
-�KVvf�P]"��k4�И�Nc�*�=��I9��ߦ�ޮ��42�!k2�_�uދ=����� L����a���Wk���ݫ��7���ih�p�~SH�O�L��c�r�d�|���4F�ρ��=+s�y�d4�ځ_�1;�+>no��k2�>a��e���-����:Ze+�Ӫ=��))�Șt�#6�5B�b�ee��1���U{�
-�e]Q/H����j�A���0cQ�]�.�^�F�-J����V�ji+�r9}��v��m!�j��h^,&� �	n��X5�V]K�@�q�sf�U�w�\����7�ȶN�J�r�2:GX;W�(&�����O��e��=ǫ���U`a��U��ȶ@�6��[�@��A"~T�6��o���0 ܠ��Q<�r����?�2,��K4�`���G'�-����\b+>Oq��3�@.�g�^��1p����A��J�� ���|��4*z�W����x\��gv��
-���$�m��(�'����| P��-[�˱jig�<�/��;c+.%����7D<X�7�p�d)�j�/a�~��W�x ����7$8P�F�D��I@W`�����Ʌ�.��x {UH���Kh�����$U@�#��>ިRW�ι3Q�3�X���CQC���+��Nř�Y��LL?"oD�X�kR��5�I�}]��K�+0��K2rtX���'��5M��v�=C��:�К����?�ؼe����l�����:���Qx�΢����
-�Lk| ��v��:X�r�?��T�������+�m���N�[�-*�Ѧ����Z^�u��܅>l��1Jk��<a���2�Y&��r�)�6;OQ�6EM5��LmGW�KF���BBń���g�཮�@\�,�
-k*WtKf�j�45<�n$�"����T-�� �'� 8e@�Y���+�$s�3Re8A��]/�?�@�t���u	$U@���y��D����;ʯ;Vl�����T�|Kr⪣�S�Y��pm=$7��)���5�&�y�o�9W����h��Їe\߻%t�`�GXF�2��5D�JT�Uĥ�m	��mI�m�&>'Ћ��Mg�r�%����kc���_/�3�L����@]�U�pf�{c|/��.b��S��Ӥ��f�����q���D$ �E�/(g🡥Q��!Ս=L���j��w��ԑ`�g�ğH�o��9d� g�(-е:��r�s��M����oo=��2F�/���p�L$"�V�� Ȣ4�IܫՏ�y�c�J�,���~@F��`��!�_�5�,H��.�y���U�
-����f(W�}pA�W�����y~6?�}���x��).w��:
-�����������D���3�V�\L����FHG�C��Bw]ϫr�9u᫲x@�����>GI�H�q�nAvsr�6rC$�I/%X����rd�.}��p�qB"oB���@Ӌ��T0��U�xտ��}��ڰ��Ÿ����~.
-�c�x���g��Gz>�ޅ
-N�!�J��� A?Fʱ���������M��>��	xa�L�����;w���S��W�=~��R#�T��6���K��X@���J�Pc���+v�����*�N2G�����$ؽ��0�  ���{��`��� �#�i��8f�HXɼ�0�J3{�?��J^k{�����a[u����):||,���Ǹ"�D���W���D�q<��,��po[�G�;K����xK�T����^��JҖr�|�/P[5v��B�L���#�ip �#9�g�C�1K�L� ����j<9>�X��?Fý�6�b��B�����}$����e��{\@~�A�ݞ,��̹�5U��J���=��=>��lT?6Ǝ�v*v�����*^9Nd��c�uM�!Ǝ�:	W��K����f��O��(� �J�����^i]l���0I"�t�=��6r=\'n$�����*1�*y��_�M�?��v!�mX\&���PE6%v�m �T��s9^�,}%���;%�zc��o��.�WI_琄�a�����ɻ�>��.���T`F�/}�M��T06����m���Ǹ9#x�ĥM�K�g�.�d�FFi��?g~��뜛��g����4���0�@7���D?BaD�}�P})0uL�g����5lN��_�;��_�Ƀ0c}�^˾����j�W"s0zFB���p�:�v���7��,B�Z���"NS	��>��C�}�Z��9!Rq����ܤ���$����	�)�?$�p&�wv��J�/Q�<<`����R\��
-P�%{�e[Ԥ�h�>7�����i�-y|L�6���ګO(�r�Gs��7��v�v��Pk����\�w��!��ؔ��I�{R�})����/E>��eI�@�|(�G%�CdX>���k^��Q�t��Z�u�ץ��1�ף��Z�����s*�>������|��;(g$E�P0�`6����%vM��.�uQ���ؙ��j飾�R��t}�	�HE;Q�NB\�D`�H;)����ʂ'boP}+Ȳ$��R������	��1��
-�3FlHuI.�%���;AV$����S�!���TCB�*dN�Cv�.	��^���^�����5]?7Ϟv�գ�/f���{+g�j���_'bJ���J�vjA��_H���>�F%�!��!�&S�bJ�q*�����l�lI�\�Zs@���(�V;S��ܽ|$]D�RH}�DF1ӷNf+C3��<s�[�v�6��0	N�j��!�#�B�0�Z��q�+���j��a�*n]��` ʲ2/����,���`݂�����d�X��ω���*Z:�a���u���g�����9:^ԍp'���2�mYH;�O� d�����r�d	���m�A�X�|Bvj7(=r�-$ܟU�= rQ�?�8O��:�|2
-V�)�i��b�]�h����?w��X�,QvI�N2��i�b�y�3?_D��b�E���+ԅW���jB�Iw����%b�K��p�S;C��b��������3;c�,v�[ W���H�b���uD��n%}�{�X��J�@�ŕ`��*�Ҹ�ϦU�v
-8T�,qT�L���P�G<Ρ9>�����nڅ�~��~.���)�� Y�1�"��ow`���L��@�"��Չn��7�c�<ERU|����3Qw�\�[r��v湐�42]@���牺}f#�[����ik5Y�����I�W����V��&.e ;0=�i� .\/J��"�/2�е�j������Vb��Ꮵ�����KD$[p��~��u*Y��o�ĮS!L� J#��A������e������Q�Hү�܊L�u�(�\"��!���%���VS�vb�2B#��7�H��M���%��%��KصR������T�%{.��s�� �i,�TI�A�}.a��2��q��K�tE��U��G��G�أc��V��#�'[�{�{�{�{��ft��A]P)o�7B�cy�1���X6�j��X^IK�IѺ���/H�WR�k)���}-E��¯H�7R�[)|��}+E��¯K�wR�{)���}/E~��oK�R�/R�]I���Q
-�/i?J�q)����K���X�Jr�(9���%G��ßK��r�9���#G���_Kڱrd��V��ʑ�����v�Y'��"i����r�6Q;^�� �K�v�9Q-k'ʑ���v�9Y���N�#���u�v�9U� k�ʑ���I�v�9]�"k�ˑ3��i�v�9S�!kgʑ���Y�v�9[�#kgˑs��y�v�9W_ k�ʑ���E�v�9__"k�ˑ��@��ȅrxX�.�#���v��X_.kˑK��v�������A�\*����K�Ȑ�Vֆ�Ȱ�^ֆ��z9�I��ˑr�&Y� G.��7��er�r9|��].G��÷��r�J9|��]I/�L8��%��q���rn�kD�dz�I#Z�F�A���1{�q�����
-��&#�#y3$O��@��F��7C�4m��G��{�H�Ol[6]{χX�.7��e 5n�N��qa��Ը�t�N*��ScCJ���EE�W�|�5�.lfTTd��9��m�k�o�y��%������ܪ.�N�[IE�{��~@�ݮƥ�bw��;��]*��cw�r#v!��}H��"����&�?�va�0��b�9y���������������"Ð0�d������t�]��7�6�T~q	?�ǧ��i����|�Ur�jy�N�j\[D��v���A����4x�bq�0"��Jv!�Uс.�������ݯ�8�O�H?C��T~��I��1ݷ}R\Ў�ҳ��rx�<g�0�8<o�0�^03T0Ë����i��%�Ә�d�<�%��X�,�;Ļ�9��.���v#�w��7b�
-��P�Ih�N��G"��U�g��,8=�8�nfx3�a��fx�����G�Guh!�-Q�=��{1��	W/�gZ��Za�`p$���_5��=�����G�or��uT�~St�z|^l��x�V��X{��V����Ou&��}V5A�H�iGz���~=�x@�y$��E\�|�> 2�5�p\j��f&ܰ��n���9O�y��,]�����r�s���?�By�谳��]eԸV[�4��!i��(I��!��#b᳏�cB����-�#�/�r�Jn� s���^�8�h�1�l^~U{��ޫ�����t�ŀ���(��J�?���*��?`�������r/�j�{�[��'E����GT�eT$�z׭�:����GUg�	u#*����h���?��,/�F;�9�Ad�����-*>��.�"))���הÅ�g�>�>.$����5�Br�s&`D��Ti��ID�ʆvZV�ْq��n�3NJ����1��Ԅ��]#�D�{�52/�q/�������U1����qO������v�8�ƽ�O�2�313N?fbK��������9!_�0�
-�,7�Lhw�B)h�]����~+hfv?�*�.X"�b�J#3O<���]Q��&��n:�v`c���l��2���8b.Z4bnˈy �]fX�X>�s� �� �i���$��' ���L�F�j$6n7���F�Wς~�h`0�^��]EO��N���e��Գ�_��tCR�Kw/�g� Z�f�Q�#A;���@=/F��-�g�V��P�^�G~X�~At��q�/IF�H+c> ��|o�����U��
-�@Ȯ��!p�nO=f���t1�]@��DIu��!��v��>��r�k�˽��V�7���Lj�1��u���Fا+����a����[��:;GT����F_!gȹ��0J�E�__�>?�>f��d
-�Ģ��r���p�,.��dh,���$�;��h?e8e�P�H���u�*>���*vt��n�u�-:�t��>N�*��i��vG�i\�ǳ~�}�Y\_� �~V\?
-aW9�ƶ�u��p�㥓'���[@�P8|�.
-%�<��n<���O�@�Q��"Y
-�c �Q�Eě���s��|��>ހ/05#��'�Bg�s�d�OE4#-B���j���ŭ�PI?$Ы�a��d���;_���;zm��dH�
-�x�ˤ��L4���[�_X�_���� c�ɺ��L4�`00&��0&��1:��dL gf�H>�ԓ��LD��Nqdᝢ�t'������%.�+�S��` �Κ����`�x{��1�98�0��Ut���D�c���hC�����݀c����a�@-Z�63j�i��s������Sr��*�����CG~˜|G
-��P�2��Ow>��N�e��N<1�'ML��}�Mn�݆L����Cs��Ȏ������TC�G���:^��%�
-zB���ވУ���zL5�f�[݄е��[z\5����p4����A@F����e	 �}ZeQ:�.��k�k�e�w�� ؙSU|� 䬧յc�ݢ���ܻ W�Z�>���6c�ʑ� p��N�� �S�rd�㶒�\�9�C7�+c��ȍ�h�T�}㹱��M 9̈́�$G6�t�Y�\�3�F��#7�0\��n�#��mg�6�n�#�`�,�F���b�ȑ��n���FN@���;��U^R���K�����j��'��.����2��cj��\g�V��
-e�N�dac}�gڝ�g�&1���.M�)'�i��\Ɓ��f%�	��3��绠de��%`�]���k������@B�,������E=�xOt��x��Z'�k�s*������+�T��u��:�vǉ�M_v����^���[�Oɬ@+so�>}H�L{H�<,�������#rx���yT�$k����b��T���y�;�j�a��I5�,�K�(+h*w��R_�A�ܲ���&	5r����ȹ"�"�h��/�} r�H����P'��E�.�Kn�v��c��4���4{Lҍ����K�ȅS��{�����Rr���3r�{N�/)���ю0 {��pOgiOv��.TG*��=Kҵׯ�8͂�����G�lI�]'�ڣ�Զe;k_a��R3���Y��کS��)�$A��=I ?M�Q>]�ΐP�~�������q�i�ZF�����܍�Y�/9Bho��%}�t�X�;ͩxA��S��ч��!������A#��w!�.��YR�*.���vr뻎�dU�l���[+C%�ܦd\9��7K��*�mҚ�cY��MI���O�ts��S��m�^��g�gЀ�n&�i$�IIwk�M��wi�>�I�S�`mx������$I��A��5�MQ	��qi[G�|e�]"�ݱ
-�G����rC�>�ti���1T	���*=��3r��K��
-4�R\2�Aލ-+/8�dI<>]< ���i�D_Q�M��NӃ�R�Q��/���]�73g�Q��V�E$^�.l������h���h��=�9ۙ�Ob李#9��� ��7�:�Q�C��]CCx�����ť���=�9TZ�vl���[G��Լ�[Y������@�QB��[�I<x�һn�=�ӆ/��I�=ƴ�˧}�V�b�X�Ҵ�u�)yFɥ=%GF �Fp��Є�����~|-�l#�31��=_УOc�tQ�n��&I����M�(��x�$��|>���\}B�#!����b�vy���٦>��:��g�I۰'�_�����#暑��j�}�ª���Z�p�� $>eI|�L�����Jg�L�����V��i�X��Wk92*�rj�r�iy�'N�i9�E�q��m�#c�WDmL�l�����8����a��yK3Z�K��Gj��G�3��UHu'z����2�jWI �_���0�_���lf���~���I3����)3��F�k��#f��1{��~���z#{�̾	����7�7ٟ6�߄ٷ��o2��dd3�ߌٷ��o6��ld��~+f��~���V#�sf��1��f�ۍ��_0�߉�_4��id�������H��*J�u{$�{$B{$��H4�h�#ѴG��+%2|w�QB��+Q-��G��8.�0�$���]���H�2�p�-N��y��h�0\#�+x����W�
-	��������V�����ߢ0 6�+��K+�ҽ݈��~Ҁ'�t�w(�c�`<P�+ñ��x`4��}�<,��w��eLDx�.4���E[kG��6[[� ��zlM��ah��FÔ/b͇����-�����-��t��|�����.����7e�7�⍵{���o�6k�M:�l�y��o6M>���x�m8P�t��e��yὓ��j
-C�l�+��l]fC�*�����+KE�󊠼}�/�a�cuIq��X=wY*���"y�Ut����!���a�0����2�S'�k�q�pq�F����A��V�$�~�/_�Dn1
-n�~�[,������H����!�QzX�:�4�p �5�=�� ��Y����u?/��v�g�T����X�^�J��m�QN�?W��/T�j$�~���j������_�J�%��b_�=!jiaH�5�M۸���*@�W�_���Q��J���y��[L�c^|�i�a�7��2|�{�	(
-ڰDk��	��q�� HO�߫RL�L����J��!G�#p����x��ZCh-�t4,���a'5�ng�l�pѳ��w���t��Њ��:��{�yݛmu{����/�pԨ6�WǗ�������D�a�q/���	#�u^.ᖨQ'����-�:9����mu�̺}T��u_�g�+���'�֪aʫ:"�ng�����3r�Y9���=+G��ß��sȀ�&)��6T�C�`Iu*�the�	�ǈ�R�B,���?ڼ�wG%�^h1�tg��$���8��{h��]#�K#��j[��6� S�jOdIT�_�"�T���.��b�
->�}�ˢ}X�߲��}�������ԉ���,�������n�A��nFJ���� ���2 J�w�K� �G�Ad�U��P4�r�˄O�C�&�w��[\|����I��{Mc,��B���]B�@��Aq���+����e��x ���Ȭ�B��_�
-/����+>
-��(�x���(��Q*�򢪉�:<Je	�Q��(�`��W��������L��$}j�ljB8#�����W�h!��H�h,r���C\q�3B<�<�x��!>kB�ć�@�<��� �{0���Գio�Hζ�L�~)޸�L���f
-���� ��FJ]<@c���o�q�!�ߖr<\_KnF���l��ք�K*D���y�>^��WZ�Y��j�`%�8d�X�f�/[l|m6����h3_�-����Zk��F�M�ZkƵ��k�ë��<�*��_����c��[��x��^�Ƈ����e�J}��QꟵj� �أ8	Gtp ��%S�h��h_�?�"�/D��)S}������G��oL@1��7�����:�������!<��q���_8��p���C���½�oՆ�Eϔ�u�u�/�Oڥm��7�?�pv��}��f��h�rGaڛ���x�����"8��G����et����8N���`@m.�%�o����8��|||��Py�qιG�r�u�����k
-�7ǟ?X�����������´K3Jϸe�e��e�hY����c�c����౏�{;	%�̭Z5>����q��Mg����|n�ކ�-�=��u�����_��)e�?oX�����Z�����e���F�`�G������V�2�9��]<��S�K��q��߻�Ba���]}�;����Kf�mkulu{��Ө^���[_x���Ԡ�h�k��~#M4�0.8[\t�mq������ph�\���2�����L��)�����R��X"���B�1�[��O��9�\����|3�~�kȗL��@�f%m�,i��%S�a'�1_�{�8/��'R�PtlpJ�|�1,HNG]>U��ǧ��.n���z��*�x��xMtLq�����w6,��L���{��R�Qr8~������p�
-/�����kyi��//�v�� �Zi(R=T�Qǋ�;�t'����P� _�WY�X�/��B,l �C婽ϿB? ���ۃ���B�࿾z��,_���!X�l��;��p\�hu1<�b�	���6�C8�##��v�p��O��P���y=�B(�^�Ս�@��exz���<R{n����u8ܖz�>������|Ś�)���ū�A����y2�W^4N|=����'zq�z����W*�QY9	򫸮���尼���q�Z�ԃ�l��w�d���үj��zZ9���[�V���x[ۓ8^z=�$x�/�������q�x�
-��'�O�e�*?�?'+7�
-Xg���r�\~~.�"�7P@��P��D�����҄�g㶅��F{�H��(��w��;�<��^yɂ/գ0|�~V���1	��Ƿ���Qߎ���Q�o�۱|�&��m���8��Z��m�R�D��&÷�zREUN1j�u���\|��
-�f'Y+_�ƺTى'���q�rH1\D1>���Cf��o%��?�S8�$���pJ�������@6Y��X0���HP����m��	��Yh����8��8���2���D�8���x�{�K4�x�äa�����q�qz{?�����~����.܁_�f���/�f�c�����x�K����x�<����8��wb�:>:~��~�r�V�ձ-��8^��8^��k���~�V����T=4�l�:ώ�����3�ϟ�_m��?�O���$����4���M�w�j�/�2�R���o#�K+c�62�u^��{�K�U��	�D��K0:��wr�X��g�G�Ȝ���!��Q8���y'�f���Zނ���b/�};�����R�G�2*�Y/wϢ�����ى�����~*�md��;p�DP��U�k�8	~��~�����֍��.VN� �片�����v��8�>���r�F�������_�����r<�o��U���w��ڞ����'�K�xQ>?w������9�$꼐��B��X�o���ʍ7�a��[x7������V����l��u@X~[:�����L�PP-�dX��N�%�o�;�C%�4��b[�������1I?:~z?:x?:�Տ���cR����Q�~�Mҏ��ޏ�Gi[�h�V?���%��h�ѝW'��HM��c����W锜\���up~L�G��:�Z�_sq9P�d�߱�~�N�m�-ɥ�gVhſa�u�c���s�8�j�U�u����{]�7[f|�~.2�����vȜ�Ώ�v|�~@�uLv��D���nSJ����_3}��?;݇�9��zY�9��u9��d�[t������u<�����3ǵd��1�\�Zz�!�Xu���p���fd��mη�盷�r��sV9M����U��`)'��u�� n+�1oۜ7K�Ծ>oU�f�[��ج�Z�f�'��_c�l:]�A��ˁv9�Ð��mg�yk���|�x�L�-x
-�����m_X�o�RN��ؾ��l�d�ڶ9o�z>?4oU�f�[����g�7>a�x�����8�WK�v�F���y%�ڦX�c}���<�Z�%�~�*�%��.����m�$V�Ǌ�gV�������4�
-��v *�4�w��Nj]R������--�ll�����54���xm[ílK��w�ιL��r�>n���wl�T��I5��8U�ͷ�9.]B�;�_i;��1������˱��s���+M2|�J�����~G����a�Ħ�ְ+�а�C��������3�U���o�ޅ#3�����B.����yt0qE>6�e��ހ���
-��ަG��G��Ɏ�m41kn�`�2�m�Y0X����&���Q�P��(׸�r���F��m�38��i?QAZ�H�o�㺷�V'^��s��+�.=E�B<��d�R��[��{4����T���T��k�w�.���·���+�o�Q�R��G�Ob��Q�P�R]n���ԅ��Z�L�6}��w�y�]�g���3�{�Y�������?����o��>�$@em��R	��P<� 5@�"�@0�$U�.	ǔ�cK�ڒp\IXW�/	'��K�I%��pJI8�$�VN/	g��3K�Y%��pNI�VX�����/+G?v�z��S�)oPǟ��X?���(>q�fe����^�K��˗�����%���ߒ���~�Z�wmU.�����]_+��A.�~P���eu����w���r���g)o=q���S���n~[y��K�'��+�P�hsEKG-�{�1J�G�T:Z*�8����^%�������J��>{�]�K�܂� ����c�O`ߟ�1�
-t��9}導���rH|��|����/�q���;��g��]t��ܔ�ŷ����:>�^?��o���~��u��Y^�;��	���,}��_9 M�>:��������O��5+�(�������x�A���X^����!���ck���LR��6�(*K��L�
-un.�M��U��\>�tX׼\�@�?�_���\���3�Z=?S��ְ�n(��Xh:<��$i�,&Y�@+���SyO�����T�O9$M�v��~�]�C5��~��,O�U�lkf^������^�&����ؚT���K��B:���N��bA��b��l��0oɒ%��Jdclo7v�I���'RIJ��� �~(,��(K�k�fH����2u��9؟�M]B?��T�P]�Z�)�kF<�P�~	.��~��ՙKx�AP���B�k1��@!�c�!j�O�^(��WdSl��%���. 2��Sn�r +2��i>���0?qju�T���6�uF!6L|.1s�R�s0��!)��DA^���uAMyh8�2Ū����Ԛx.�O��yp�ӐXP����}(�M4Z����Cs����օ�v�|Ǌ�Ź�~u��^�ʭ�w�CU0�n�'k�F��tHne�B��T��f�U1�L��Y_-��r������Xx���3��X��l���A�p��K%3��D�(��N,��t�m>��.K�Z�io؇�l��T�%��{��i�l�`Xr5v���`��F��3А�s�\
-�W��0�{�k����mL/�T��%�S<ӟD"�X1����.�	��Q���30��$h�̇���,I�+`�C�"�)Z-0�\��:�����'�3?[���F�-�L*��k�cY]K��-��{ƥ���a�B	V��쐃q ծ���b��ٶ/�Q�4*���
-/��f�}��N���b[˯H�
-�)��_>uu��V�Yi��6�-�*z��9K��F�^�J(�L��,W��{WW�JN��W����b&[�w�aFSI�Y����5�VtY`!�t�m�p��Hy���՟�5�1�%�F2�Lf�e�5ƻ�Aڋ+�±�����M���S�:Z�[E��gf��4���(��$�S�����`c�N�Ac�b�XY��ύon��0?V�y�f�RyF&X��S@;2@Wi��\�J� R~��
- ��`�uu���X=��f0Au�.]�T�S$�r}D��.FƱ^�,A�I��7��#n�-<��)���Ez�m����(Z*�.D��`��`�`�J�3���#����˯q�]SL?���f��-�]8|
-e	b�w�i��U�T?�q����M��{������xj隁Լ� ��|�c���8���T�豌�<4W̤3�|�%�$����@��ų�:v@��`j0�-h9������k���@/���t��˦#~�ʓi\�1@m�i���3�t�^pҐ���$����J4z���,�Ŗ�bG�G�*I�$S�Xv@�qp Տ�'yT�s"����1����iZ�@����u�r7cqv�Z�P`�C���j<2�C2����?�_`�Y ��v���Z&TԨ��ҤmY�3� Y&a�pb����;��E�:,Pdg��#�����$�)�)_6Oe9ܛ�� �|�w�r���Pe�yb�8�Ւ��̈́t��Lj�>k�)h5���r�e}��Dr���9#�fc�����%l�"��Z�R&N90`;��L�
-��>�����MN@=�<q �H�x<�W�>�}���b6�\-��ĵ����������H1�bEVoLI�7���P�ht~���S �
-t��+�.�4cn�me�B�P� ���0!pp�D���֦�M\����pJ�6���3ɖ.;W��ɝ���,㾀6��Yx�=ͦ��3�@�� `֔��lEy��*d�;%�(qGkw?PZ�9���T��t�u��p�S��,��I"����cx<rf)�/�w��&#�o�e�b��
-ԯ4D�%�q:][VVI�bx���f�
-�����R6�.�y\�b17��s����=>/�"V@ߚ,��wEP,�q�ɺ����PWE[�n���\�X
-Tj�D8� 	@�-Y�K����L:�e
-�ŗ�)"2�� MKMMU@�2+tY5`yK����
-����ڢ�`��ऴ����*�B5���As��T_�uɗ�NU��:�.kO��@�����l�[KZ�=$'SEM]�v>���c��Q��\�\�M�z�i 찆�51R����6��c�Z���d9��~����#�
-��)��`��� X���ݙ��0eJ>�SؠG�r7r}גVd��v0�F�OLtS
-��>
-鬄��%wi9�f�ALΠ`����s�]U�`�JI�%DI�xY��)8鬨Vm��#�^��D��_g��"��1�t$�;ZЯ��R��!��˜/8�QP %T0�ȥ{ac�IMU�8�~g�ꨕC����e)S��\���ń�'z}a�i\MT�Ѩ��Y���l
-��'(����p>���0A���(!��?�g֢��T�׻�̈́p��	mM�Y~i,>s�����n��A3Χ�p~�9�m�fv䚍v͇��pm�o2EE- ,Isõ��2�rBn��UݜSl�\��)ܝ<qeb�!���K�PƉ�c�w�о�~��?1��G )�_Q��4��d[*�Z���$?��W���ɏ�&�g����lΧ�J��l(���|��OȄ-�1���� �VE�i{&i�L��tX?��Z�8��>��Z�j��OA����=k�/�IC��[�Oك�Xv�AR��BV}Q	n�֢�Ӣ���F�.�XaV .�)6�|ӭ�ɖ�؜"0oS�S�\aD��$���x�)x��I�#�&�Ԥ\6��,w�b"�`��B���ca�Q�Pe/C ˂�,!��-o���_�Z���T���J84��E����Y���5�� ��IS��gZ�n`�P�-FJ��6��-�f�XW ,��P;Hy뀹\a�O�)Dbq,��1��A���j,��3��V��H�Q������/3�����|�H�߭�0Bˌ�r%J�e��Tj�}Yt9�.g�#�v��}���������DO�{㉒7!l��ҏC��' ��r����nP����Lɗ�+ʵ+*��i������:dU�%G-����j7Z�[R���
-��5J;�v66�v�M�)UI���[�-�*
-&��Z�A���VM[mU�H0��۪���h����Y#�h�j�j�G����m Q��t0��Y�Z,t�
-�D��5�Lw4ɥE�h0@��D��$=��!lF��4`�"�o���0�Q�����bY	��]����}V���E����h64��C}Q��.!Y���e"'�8��Sn#�W�>k�)ZK��XX��EkU7�&@��*�d]U<�K�
-@R���[�p�u$`dbҴ-Vg$����?j�Q�$��_nCy��ucnC��V+W�Հ��=kh"$Z�sV�ԯ�	�@Ԧr��buQ��5`���`��j�d�\�V�*���p�l1��p3a0iTʈf�Ϩ����ܼ�ꡂ������ʪ���U`h�3kD*9�m@��B�Q�1:Q�{�
-ԕk���p���\a�z���l5Ђ��3K=׌�i�3@]U�5�`W�KfRt0�tgp�Rɮ��h��(7p؀ʿщ�Q]�.M�N*���e[ �&3�$�C)�D1�P@���� �d)����sŒI�:=0��ͧ�r+1�[�s�~(1HK�U(��.�n�{��j|햲�v[E�v[Mu��^5KY���/�I�D���s��d��	>JXL������L��|���۬�SL���A�Y0QP'�u�S��5����!+��m�Bt�ٖ�S���c>8��u��T�#�`Z#�dc-"`v��QF����E�h�)[4�PC�c�J�ŧ��~�z�Cs����U�Z7�كq�8�9��<T&�,aa� Ӓ#3��sy?s�'�G�Œ�,P���͓h½�;��1��C�����I�,�'���D��a6@�
-�����B5�ˑG����,=�`�������z+��7�(s--�X�Y�b��ʃ��2;�tպ�O�c����|	���&`�q6{i�l.�֭����p�dd񯑊?�YP�G����v�>��؄*��I�SÉ)����N:d1l	��L7!� �ݿ�����Su̢��z���Ħ�7S�MaT���̲L�l�Z��Y
-B^v>w��nLQ&�د���4�t�~�1?�
-�H�m�:����u&i3
-�'d?3U&��,��/��+X�f\�����f�a�:�hNu� Ji�t���T��K.)3֚b��0eJ�L����I��{�X��Ǽ Xf��"�5��7ʬ�|t��x�<�zMq�~x��x���xp OF���2�*
-��eJ#�7W!�2u�(4[�t��&��c���T�J�Z�����w�E�4#���Rw� ��]�[�AF��p�A�M����ف#Sk��V�s�|=l�G@^�̳=�f�I��S�{P7�bx���B6sz��G�Vq�>~�^J�iN1��9�gj4�X�ym����"ИE�D�NdZ���(���"L�1�
-�`�8m34_�����p2��y�9E����	��3�^�]����
-C��ӯ�C�%I��2�Y>�fm������ta:�jj�UW�F'��WH��4O�є�M��;%��~��<e��f�0y��b'�'���%�m��q�DDq�d�,�F}d�ʧ`�-o�'N��
-p��L=5�������]�?��b�W�w�m�4����8��C���s�H6y�g��g�]7��bst�,�^i�Y)������*6�gX#s�M��?��x�:���xp4�6������I{��á�Cc+3+Ћ�'�����\c$�_���ذ���3�8�j(���( y�@�_��������p�3׺@��	���)�x��Ezp.�p2�#�W�xO�y��G���.Ck�VvW�nYȦ&d�cq�:?�u��y�# �Y�(��x!H(3����AC���)j��u�;zO�����j�+�c%�^�;OH�cf���V�z:��}�#�#�u�m1�,�;73��݀`4cec+� Jp�o�p��O�J��v������[-/�b)o�Ljag��d�ʏ���]����Q�����ֱ:qv��bĹP��c$�KT�KP����D��[V�`r���^�9EG��ݺ|����4!l,=f�Ϛ�%%��b�V�\�窫�=�&��>)^K����n	-�&@Q��В��b�v�t(	Dm�\���Y0���VUGU|jt2��)�%X���L���^Esc�����ɖ[K���esm�EJ�D��NGe�$�N���k.����~"� ˔�Mj0� ��k��%��i�Z���F�k�����n����w*�vh�%Z{;7Ek9�6�����l���O�6Մ�/�ݭ���ګ!�?���k ��ICl2:�	��	V���b�F��Br�Hss�8`!�U��d�ꦖA�:j&5ZVBT�]6��)�X�u��I�s����S~Z-0;��Jb�bӞ�U��p��:�3�>�s�*�c��TǁL�M�@.�����j�MwF��ϭ���67�8r��u��v@�a7}��*c+8��Ҭ]ԗ-1N+,8���uj
-f��D6�7`�K:�� ��� �"V�)���̃Sd���A�e5r\6�\a��v��R)](m�o�[��
-�s"mrw�@D��`~zGɳ[���F�@��|U��~uV�ˎ���ޟt��Ֆh�M�&e��_́������Z�J��
-��N�����ݿU�8��@aq��jlx=Y`�g<sv��WDcf�:���0��/��]ӟ��ӟCF��J�;z��r�{F�:�)	YY7ݤ_�= ;bi����~]����I
-�FF������L�����}x��=����)��\~<��rn݋N+�
-��3��L�BRt0�����;l��~[̗L�W,�����[ ��e �f,��f�.�;R��G��X?�z)[9?�n�$a���zl�M�ܔ�^.﷭ʦ>>�ڧ���D�V�K�u6��sO�������/����i_��XÓ":-j�O���M�4��@��� ���p�^�˶s���z�_b������HQ�ނU6�S��٧�2؄��
-�+�ҍg���a�����kR�b�Y([k�(�u�\]�g.��������׼�/�Q��������W�
-r"�{�L˝A),���k�F˝|?�����Y�"e��Հ���9���d��^W��RS��R���[ ����bS�� �W{�{����\n���dG��Bt�������1?���Gɸ�j�P�xm@��-�N5�����L�%&>�{�M��ʿ�(��a��
-n3��t�:����/_g�h�[�u�mqQ!5�D�T��O���)빋�ŀ��~|*YgɮEI���0-(�s�b�nAE��0����*mwH�C �Q7�(�{�|^�P�{��{��L�y4$s�6�͉q�3{]a��
-O�7/�����,g�.��,��1M8S �ָ������c�+��3~]pU>6p����� ��+h�l6��"u��_1
-M�[�S��|?Ǳ͂v��4�"�2>=��9 ��B�X@/vP���[��K��d�_�W�#��1֛̖�V��I��	V?�4sҬ�WgM S����<����	��o~ a�=`�R�LybM��&��J{
-��W�4P�)�@fu*�a5Z$���>d��ư�����=�����o �o��j9w8����m�&��	m`��b�I�_���xWg5�q��>�o��Hf�fX������S�-��7������3�ݍăW�Y�����J��)�S�(���O6-�}å��
-����ŵS�[�~��~���w����\����(����;0��1%�&�z[Ҏ4���f�q:հ���m��,O\�oK�ء�dj'[�����_�o��t<7�ti.���nH V"2�荱�1��RI�x���,��x#uN6+��$�qٻ��L�����p.�EX�GbHAOӥ���5�I	��(��=����jα�Bm��3V=��$W?��w����pin0����;n�f�t!��@�wښ8���31�m��"��s���	���&�s�� Ʈ��f~��&���o��� bMj\J�E�L_,�f*����~�,$�Nz0��	����)b �:c�,^��(�uܐ���Y����l�|�4cDX�*Wc;z>�ف���U"�:����뇵�$���S�(�·�B'^��:���ѦP�}��a}/�v�z$i�ٓ$
-�H�t��s."�O�I���Tt������mO��Fb���j�IGB��Vi�q����"��6�������adK�f�5U;���}Ha����x�F������KKŒ�-���O�*Ԟ�R����=�x�}���pL�'Mm�"Cm���FBoi�ǭ�8Kؾ<�"��(>�����3�BJ��}��������Z�k���ӗ??��+�Đ�,�,O��_�X��x48�o؝9�6�\���d䮓#m�ٖ��e�1	���k>}�"0��R3�̬�6z@�)r��fV������ �/m��ַ���cfص�����!F�^��3�Acg��7�������v%���`Aʮ���7�nN���)�[�ϴ��TW����Y�f�`�~bG����n�w�(tWa�)�QW��p7[��g�[ٱF,�ޮ�C\280��[t&��nq@�����4��XvUlMa	]�I�k�h�E��'nЋ:3H�⍛n�~���_�I��T�6W|G���"�P���dp<)��Z]Z�/�)J6տ���E�d��!�j^`����c��Πc��-�-��ˌs
-�`BW®<2���U��{�������>sa�1sqȀ�ϝ>
-ƣgR7�j�hx0�oWb�T�.l�7��з�%9�}(�'A	��+4p�0�HƟz�lΘ 2i��+��^Z��[a�i,�砃iT<ƕ�z"�/�<���>Eo����m4ut�9�b�����r�ɷJ4r5�b��1�;!4�\.�$4�z��G����Z��*ԟ�?"��-5��ܲ��<.�b~�ץ9`�=L�D��`�,f�l���i^�*�x�)��0B�?�5�b�.�jܙ�f[-�G\����'�e
-K�՟#���p`�@q׸^��sx\�4�J�`�.�i�i���0��ًtV���Od`|p��^g�����6C4 �O���QO�9�r�A1����\?��Nw��o�� {UG��'b�HN�Ĺ�9萜�`��PW�l�6����~����j��0;�E/����z�#�ı|�)�����xtIN ��?�@�ܫG@����
-ԷxG�КX�0/%����Ib���;3���;ńy-��M�z�@몞���V�V?b�-Mu�f����-���� UR��eu��ȫ�J��M���2_�H4��m1�����}YcvK�rb�d�C(.�L��0Y5�53X���b-7^蛧�8J���p6ơF�����w9��e_v����拪����`��$�F�[#z6F�=,�U�o�җa�w��˃v�����Umgfn-�����huu!ZV'����_�E-C�����ױ�(�;�w�-�9���*����t��o{���� ]ƀh��mOU�8��}����0�d�/,PC!Qu�;�)TA�[!�	�$�dP��RjK�P��^ʼ37!O+c��δ�`��5!k�^Ѷ2����g!o�L��Vpf#~k� �E�����A��W�Z�k�엄p�S�o��+o�$�dv3*�������� o,+�s�ʽ�%�w�Y�ff�3�,e��|�%��ږ��)�O��ֲ�Օg����,���{/	$���B(!@�!	�B� 		��o9�I��og�|�{�=��S��V�,1�UgN��bi��&L�B-�Rב4�U7Gxz�mo|�oJO���JR��d��@ʾ��T�Mi�F��6d+7!���1e#Ez��>��$�����R,��a+;�I�Π����k�5�}ʒ�v�y�.���h�.u	���ƶo��l�*v8P�������ӑ� ^��(��}��q����u$!RKQ)��kd8X����V��k2�i��N���`A�()�vd4V븤:��(�!��S5��hɧ�AВ�����>
-����m���a���@�Avs��X�-DuGC�\��	��
-qo
-�O�������`&g�}r��G$ڃ� �F匀�v[k�xO�U*zd�ևO;蘏l&�޲�x��e6^�Q�����X!K���X�R�ni���m�VA.Z�v�"mpv�)?"p.t�,��7J���q+@\5�wz&cL�&\xZ��h�u4����>U��;us;�����uȅM��� 	�<��A��j�$]Z�|�XV25bC��e�=��V[����E�I!��6��p*���/���Y;������L��6X+�@m�9>U,a�kǠ���6�4�ᖥ�!�SnD�VH��@tos>3f,�l�'ČC�Y5=q������oҔ��r��新�:6�����\�-5l��X��E-�rڬ��b�ܐ���f��s[ق�Q	T�^.hN�z��. Ό��w��ED���mhd�)�z��8�5P��pCp:�M�t=u<f�P�qU��X'oƕtʙ�wH��p�69r�6p�%���b�^�ү[Fcx�8��_D���_�{!Rꮛ��$���6�z|]0�Ho���'y}�*��0o�0�GK���V�F�w�(�G���U��k� kԝ��~���������i�bդyqPp�ٸ�HIȩ�|�9�,t��S�Q�[�b#���x/B��e,�Ր�аח�(S�\�\��e	��Ħ�9�а�_������(�@�V �VCD��^��5Wx�t��>຀?\>�X�C�ڋ ��[B�S ��0']7�c_����?˞*�I0�l�����MO����,����!�f���S,��rF�?�<��S�3�H��IR	ag��(gBl)�vk�V���J+��94,��퐭��5��Q����K�E��	��B�%U6`_0[d?��m���pz�EV�oJCjB&i��� @3v�F(/�l�M
-�n�w/S���!�fk�/JӵIB
->T��"{��	V(ʶ��CL�I.n[LA���8U����\�̾�'uI[HZb-��	� Q�{��d�btadLeb���tvjRƴ��JW18�E�G�j��X�x���L�W�_�M���)����(�!��,D�g�6���;#Ut�J�'�d��OV�$���U�M����F��L���P@C�Y�u��P������.�'�$��C�ەpd'rZٶ]�����8tƵ �^��X��+���{�����u�N��oU=��/[()�r�`YC�ɑ,H�i����j�#BQr!�´#3h���w`���`k��@��Rn��
-�M��a:�O~�#|3M9/Bɘ�������Z�DbL�B�
-�l�|��,� *�82�0�uD\�f�4��2�	|��Z֔b�v�
-���[�ӝ��!0(]c�e��C5�M;�W2G2bdF�ul
-�7���?CE��nPp�/S��J���2FR��K�O����)��u�Q7(%�e�;�@+W�ц�(а #mJMJ�q~�X�n�$�~� H�.#4 TF��)a'�1 2=��@扏]0�K�@�LMJ �
-]	
-[��;g/����I����'O��M'�jr��kX������ނ("�WZM]B�������=��j��	�)tB���+���}��׏���؇S\Ц6���
-}T7����Y6)�s���va4ڱPI��-mTx�c���Ex[���(��`��;m(Ő<� F)nQ�n�^ة${�e�y��7C$�q�ߑ��6�_����N�!O~vXyJ�����o-��q�H���B�  �|[��&,rQi�_? �%07�JӖ
-b�k�M��?�{n)w"��fj6�9��v�e�~&m� ˦g���q0N�C/2	x��,,�0eG�F �i��w��0�Cd� �Ǝpf�,4)!��x�0(|=@�Dw�L��RYmv,Mٜ�<�%���^u��_�ݬ���^��) �-)��W��+A�C�U��{�V�1�!��B���kB������0��M� 8�ʠw?��v�M�WC�g�Թ�.���+D�e�B ����Ʉˣ$Bµ�����l_�S5@Hb>Q�[�k������;!�/�� �َ�������-֖����m��[b�$�����E��c<h��B��ܥh�&\G�
-"��n��]J,5�5Q�ܞ���s���
-�/Bר�+� �7#�-�G�����t�)�`Z��`Oݪ/*���Xm�>�Λ��ť�2�T�X4�S5�ǆ���LY�q8 M��p�g�)"͍�����t�����9�c��D	�}��`��rfA8�g��+���Ǣ��p��^�8�pZ�?7A���~v�W�Ai쫯�WdA�ňe�$��
-�e��d�C��ٹ��i�'97�I�����R�5�_+ɀ+)�@F��8��Z����N��4|Ͱc�Q��e��������>T��T��q9��ژ��6�i�^cE#5�Z ��\we'�_x��^x��J�߾�N9�e��НI�֒f��L�ߟ�lj$�6�y���F�.�-{8�Z�[Z`6���d(>Z��?skma�fd�Q�G�TNV^�!�o���y�h�S2�P1b����%Dރp{���:"9!>����o��s$�J��l���Ҵ6�@W��$K���k���9�%��jmh�C��p��l���D6Fnb�_���a�����j��6�F��2"$ee��dXG��d�mb�xY!&�n��Ӂ��E��E.��*�v�*I�(kW;FP��جˮ;B�*F�����n�(�3�=~�Cr���0�3�l2� �7
-dEKa+>�06� /�D�uj�G��#�rx����h	m�)�&�O!���ct"�G%����yN��&���*���gs1�Gd<�U��b[�:�J=5��@�h�3�	A��"I�{5��%'儹�J��"7,^�063fߞ{{[���Hۤր�0�K�����y��>��s��b��E�f+;�N���?�o	ڰ�nʄ�N���۲���%l#�X{>�pv� 
-�Z1�s
-G��.����4���Q�m�r\"��[~N�w �BK�T7�5���^:C�����X��DU�~�g�e;y����%�Y��t{��2<-ǒR#2l�a�NVG�Bid��Mʠ���k� Ė-ˋ���%�p���"Ln�Ȕ��-ʳ�.���ӎ(X9�v����rl�"�y�a�`�,���*�8��5��NTE��M	c�榰%Gp�j��������4k�h���N;x�v�k܃41O��n����9��ߺdjD���Yw^WZ����`�kZi!v$ŋ���By���J����|�mG����9��;=2����ĻJG(h�9��f1)!�N�=��ob�S��Cx���� ��2���d,:�;<���[�}�����Oj[�A��b����Q����+�����'a̸D�$X,-��[�n0��k��C�8=|�j����]��T�r'"�|gl�-�-F�k�5��A�!q�l�]Tf2S#j��5H�\�B7-�=� �N~'7�Dt'e+�jR�}Z�w��^��>�F��ѕ���:65�x0Zs��[>��C$j��g�ڸ�Y���=Ӆq3Rs*�GjNu{��g)�q[d4"�ȸŸ�Q)+ܥ�t�!Ϣ�	1EQ
-W{\d��B"���˻ި��P}!�I瘆p�UG}IrL��D�A�}T��s�xBtqMJ	���lwω��wB6>^��a;Z�E0B�1&��X�w`l��A6��N��(i(0�h�S��l$S8%ʢ0�&�IYq��;�hĀI�Q6,.ݹhbF��3?^Y��肌� �������.L��+�JO�<a�\��Y�M�C�Ͳq_�l�Q��e7��#	yz��&���2ȍN$҉��������6��OWp}2"���T��g"�l�C�qP|xw��d�C����P8\>Z�1�J�2�p��!��"���9��ʠ�'�S�v˻�>fq0�G���A!n;%Ǟ�i�)��I	�h�5(��{T�5kXB5{\B5{`�5kdB5{h"5�؄��U2�Wf�M!���Bf��6�m����#��T��:{���3y6���
-)1$2t&���'pP�����(��ƣ��x,�>">��y���Aq�
-�;�u�e�o��<�W�v�-�A�̄�3��@ښ.�_ښ.��	�G��̔eOɢN�8bbI��O?qj<wЦ�G��Xɝ{FFG�'���F�8	�NZzrBU�+���z�K�)�~.�ikd#bf�-��t^�{6�\����59��þ���z/��0����+�;	�`NL�l!9��a�WH�t[,��XI�46�p���-�o�B��#�Xa�L0��xm���Nȁ1HIx�qV�ILe�;��$ ��l?kĒ�R�3Dl�[}C��e�ͮ�0��������e�-@482�i��\�D:���~�$��ztR)��o��p�����̘led^��!o(#�0���;}���݇����^jJ������o
-�~�D���ϖm}D�K/�W+�U5�I�H��Ƭ�_K�Ǎ��SI�E��zW�Da����GO)夥���Q�T�5!�b�T�"��J�5�3�O�։�d0�Ybڲ���tl89�[�BN[M���W^�	�� �T�@�@t�X!�ֆ����@I�xM���G�?���!g�n��F���b8cꂶ;Sf�n�#)6t�N$���7������,��)�]@��w�����@˅��Ip6��O���E�K�{�N0��1�c�ObM�|}ā�"H�~�}���F�mnE��S@^��JH�b�#\���p�!��rŹ6�hK�,z	nw\������¦�O�;̝��X��<���L�]�e<,�0�_�O6?�h����Lx�Q� � �}P���6�YO�>�2�G�5&���(Y�#��X��߼+�D����z�D�xX���I#���6�\z�����+:�񶱎��OS��q���\�-����(��ֱ'�g䏹!�q3?��V��@�VH��A��%��Ʈۼ�3�F�5$i �Q�p"�GL5I�w`Sn�!_p�R�<=>;b@�>nlW(5;bN�>�x�RG���Gbᕊٌg�Lk��)M w�2xԑN 7��,Ri#�}�#Bd�x��H�f�M<��w���؊s�&�9Gx�7����{\G)�����n�����Ti���Î�mB��.C	����,�zC�Iq�FR��:��j�k����Ӗ���\#��$�8�i)�-�[P_~٤d��-��^/���q�-2z)�.�g��2`��,�6��"5d�Ʊѻ��-!�&�.�6b;z�6�x�TX���1��;BX��3���)I<: �J��jذ��p�∏*�>λQlD�?>�a?e�^[��c��
-����_���?޽�v~�5�~A���/�P��<��[C�$��B��q1<��\Qs�J��2��|�r�f�J̡R��k'e:5��И�Q2�*en��YRgΤK�H�܃��Ŝ�"��$`����R��K8K{c���XR�������@�%a]��X�S�:�"���6ZF#��q�q��M�:M�G�;&�@Bm�k���A��KB9 � �Xֵ�X�~�Y��D� 
-".k8v�̧F3�L��L��ĒKi!;�c��b I�όg&xD��������,)7_�L6�s���89OH"8��y2�c���F2�ڔ9#,�Qv�";`�{DJ&�)��UT��.�zM�#�l�.����}�,�.���g�Ɣ(�� y��H|j��nu!�_k��Y��G��"I)A���|�5[�{�-�@\p����B�0z<#L��wK�]��ΰ-��l�F�M.�Z�:1�~;�3�K=S�1];q�-�t���<޴�d�v��->q���o����M�O�#r;�p[]v\����,T�m���	�LA[�8�;/�x�f�A�.�X�;�[�<E�2�rf��K&�[�H �|�A���I"i�b������PL�.��iN☌�6(��Ɵ"'���!�d�o��h
-����|"Ph,'�w�(iʒڰG���ƕKs3�vtOx�KJ�c��k�i���Ήl��R�)�Yw��������r8T�-�)�9c'8���L�RF��'�`��I�$��zgAz|1���'/��Lm�
-�t�7��kcuz�e���R'�J��K��ݼ/�o�2���0K1���}�B!L?�r�Z,椃-����}Ä̀���U�i��Z��q�;$XNf�
-:��^�@<�"V�6���/�n�9sq^��J;xއ�s�{��m]:�?�#�J[f��+v>�yWٙ!m�	���(s��&"���m��ˎ6�^���^�"�ھ�%YB�P�X���j�ׇ��P��4�f:y�7�X���q�tF�XwY��
-�T�g�@fa�P?���5L3u�=`�A��y��?���2�X�F���T,C+�hw����n�՞�i���޿�2���o�bE	�Iv% ��A�� ��������$�3_��QZt.9�����Xڴ�*,w�#�^�e����v�w�_{籲�GLf�x-Є�Nܱ<p�r+�YȌU�P�H���" h�q��Z��ܕZ��o�~{o�Cɰ���y��Z��1Y��w�LSG���]�$�G�=�N����{ϡ,4D���'Ɠ�ϒ�t	��9�r�h��W�
-����a�e�<m�Z�_�u5�(K'��rd��
-�d=E3��D�Vk�*����a�; !)0��Δ���$�`�7������U/ú�c&�(�j�򔎠�d˲��Ŗ��G@��#� 1[c�-w	�d�%�ţE;S\���+�s'n��O����jm��������Bu13^.�p��X�b�t�buvbNKXi�s\˔.�ϗ׫�Bi�8_�F�������J�X=�'��(bݞ��eN�\��;��$`�ݾL�f
-
-A>���$d��l�e�0���s��?��������I`�����0�եbmu��Z\���������nYB�!�o�-�)l��c`�	kx�nE��Mb���)r��̈6��D�Ď�����_Q(�J+g�K��&�T�|.Uj7b�7jK�[+5�Y\����+��r���͗��kх�R����_�Q���6� P���%@�CaJp@��R�iL�D}�pR��g�
-����=_�^�I;��lFVL�)!<^'k�sd=�%F'C��������[�����b����(**���=(؋8#��:Q��"}z��K��0f��1��L�o��DpQD�J�^ZLv�E��3|�`ԕ.n$r�VBE$)B�R��}[k�L �k M?@��a�Y6ɋ��L�Th#�I�uL`��
-Lֻ��=���\'�a�g���#�9ΐV���?H�My�ޥ 7 or%Ӗ��stP"��0:l����>)IH�>J>��8%qc���²X��ZDu��z������$PqVO a䎈�ϕ���1f���P�E+��Z���u#Q��A�G!�]V�������XM�X��� ,��*�B�����g�����Z	;���Z������ 1�O����sW
-�Ѽp����W�<D�����4~B'4&v��	�̌%�	�{q����k'nvFN:#'���!;�PG�!����[a��͵�>Y;^;rĒ2�_Z+��kp�&.2ƙ��-�����)w�5��%�=��J"$�������;;	(�OJ��&%d&y�̲��������b�P>�Rt�R*m�a�ݡ�n�݇�],��i>e�v��<��'*s���Ny�u�����		�f��3s�rd�_�f�D6�Q��Ih���:�/��
-�|��K�a��|9L��p�$�6��Z,D�����|D:N�4�|��abXP[r�b]i O�r��M_��h�Wt��E������/�U}���%x��ղ�����mn����M����J�K�V(޺V,V�*�u�N��%�ZV�	D�ӵ �2�� ��qDp;�'q�_N!g�^�]l#P�#�~�> 7��F
-�V� I�����s�֢HP�ѩ��������m�0N+�ǚ-W<�l��.�X<�)}�UQڵw���k݉���D�� �^A��O�H�.s,�,�3�� M�mr�-S TuLܸ�Y{�z�yL.�\��I��"d>G^�f�ɊwQto.���)����C#�y�W��Xf�Ձ��T�/�m��R�� a~T�p����c����7���$�nѻ�r��.F8Pqa��2C��a��`��Ϗ�I���r�b��?4�9/�k
-)�N�ۯ��K5����""���
-ǵ4����_�m4$�Hl�T�ge
-�������#��HC$�JC���e'�?�GZh6�\�hc9h�n �=���gE�Ȱ���`����b>�g���Y�.y�NP�Jy������e@���JMܗc���J�qan�A��#�T�BX��W���U�C�B���HX+�¨��.kɤ��|�ĸ�4b��U���k�s|����U���A�L�� ���ke|�R~��(\�����Ja����Z'�s�d�!���Nw�{�����I�#BֵN�{y��,b	ޯ�Bvw���X)��3��˫�����Z�Q�j~)�e�Y���>��.��o[)V*�|�6W�V��z�8� �h��P�ׇ(E�CtI%Z}�F�1  �WG����
-�%:ڄFt�AX��� ��� ���z4����������K�D �	AT��&�qM���ޏVח�j��J	O����ܥpb��ۂ�BV<��%k�G�׋�H�kzW�+Eov��T�g�Vɱ�M1�A&��&l6jË���a]Y,-TC�	g�V{s�̯�������E���9,^e�^X+/�j�W*����B��N�.��f6U�`Xߘ��U��U[��>6|�6~%F�(
-�$���l��af.V=�Z��+�X��;����
-][8�+�t��_�%87V�g=�֥E��J��K�T˻�.%T�����d�E6w;����ŵ��Z�~k��q_r|�Z]�9X*G9P)�)U�D���A�I��Rn¿B�9hӲ�[_9�ȗF��	+t2.(�\5|���>���ix$���":����[��Ns�Uiw ��b�Eq#���|u�PdL��¦�T۔Ai4ٶ�K��mE��"L`$
-�����俽���[d��	_l�K\����V�V �7QY���H�Yp�Bk _��^̸�{5#��R�'iE0�W.�Ya������r�{�y���H�4#s�5\���*R"W:%�Y@�5�q�(am�k�
-��4�����@�BP0bR"��~�ۢ�|�wƘLÒHG��[u�z�k���w�x`K߲࢝': ����g#f�m��0q%dk6�	�T���?�����
-�Qe&�������j�l&�G�|����
-��Jq�P����&�7��<��p|��hQ���RQc���1B�>�jk�3px�2/�+H�///��H��9�+d�k�=Dʍ�����������Jo�_.V˅�P�#D��,�p���LYV@Y�~t��#��J�̃X��@>h붝[^"�;ۛe؉�D��M�.$*���y'M?" \0��\H	�9�����c�JZSz4��1&�o.D���v!`�^DmJ'�~Ȃ`�H��t�[�|sI�X�puu'M7�����%�Y�:�O�@�~�|��a���@ü��xѸ�i^$�뫺<�|t��+0��~���˓�?��咿�d����A�SCH	ACC}!#�*�ى8�V5�(��J�[�QR灎��gRT�̒B�v�_�xɬ�%05n��Gt4_�X�i}e��/���"6נ��V�XTW.+�B��X/�v/Dv�M�n��C�
-�	h�#�M��]Ȃ���t���a
-Сb�r�R-.�5��T�˯%�@@��6�1иz�Zi5��V^_)L9!�3�2��׊U$W����Yؔ�g�5-�`��m�jyu}55
--A��)����o�����%@��rUP(ϯ������J���R�F �+���1�rZy}�M��W�k�jym��c_����W �jLwp��<@w�W-vU�V>�Щ�챑���U�����6׀.�V�`��+ӣC��sgm�x���}��z�13`cy�#���b��Qx��[��puK�yiQW��ʷ�^Y�[�oe�����m�Hd,3<���s��9���n��̌�6��u���a��ۊ��v��^�8N�k�����F%G���Yv�`~��<�z��\'`Ƶ�F�����$\���/;M�U��"|��j~�=3���r/֥�{�V`8����@t���'�]"i����_2\�����|i	�+�ϴb!�.��S�b#F�4���)p�t�Xp��������]�Gk�'w�s������p���	�[��w_���C7t9������D}�;�J	��./,�iT,���,\N���r�G��ri����f�WC����8�j`��A�����PW�$wut4֖�gL /���	)��k�G�S�JS�=@��
-���Exf�i)+!�	��o+�0M;!�|X�3
-}DԂ�$V�xfƹ,xD©St�p�.uy�Z(��])�]p�f�B�Ckgǀ46T���4(�N�ϯV�a�b��I)P"��������!w]�<~���b������ pW��6�eF���		c#��"��	#g����r�T�_��N�l���HB�?'����n�<�\0���k��	n��׊��M���6���>0K���^�$¨,�Vw"�b��̺���S��f\i+�eQ������os��(������&��?8��՘�� P5Nv8&ʰq�֖jU:2ƴFV�<����*-��Y�;�wчB�>� �l��%�f0�eBC[h9f�<��ު�s'�R��"��b���> -Y�I�iA(Rp���W��\;_[�^��#�6�p�^	�=�>������d��ɯ��0qG(�Q�Zo:+�~��Z�d7�DC���U��6w�V*��,~�Mp�Dc"{� �A(;�`�� 
-����<zC%��HB�ɴHK�h͇p����hB^<)�|�z���V�Ȍ��������j�_V;\���!�j�/������!����0t�
-V�p���)��WRNV�:,o�� '��=b�m!-�#S^aE�}�`.!�M��0䈅���l͝�Çv.�$ySc��s����5z����Rq���J��	u��d��#�m<>_���#�n������v�����Pa��Z7��t)jɎ^��dɆ]��f�P�AN"�c�A���>�`�/4���*���K�֢N�L� �ޡ�͍�v~�#Y������t�BK��ͅ������L*��]���+g�w[� Դ����lr�����.�*	W�m��1�(���F�{K/;����œً�1;�h��� 7v�@K����!��l�p�e��G�����!����ޚ'�V7%!����5���euDh7�6`|�,C�@B#EA&�ڦ�Ӂktp9#��Ba0 �3d�����J}��eo���t@kڛ�����-����:9�֑��|4{�޵xe���4�����9L�c"dᐌU�=|�j�28܂�EA�r}��_ãg-D��0��V	Iڔw�.5gC�p����5=�*��n����(��;@qw��M���=���Ř���SgT�&LF���%^!�&��p�:��4�&ʪ�<�3l�-���W%�|ُa&ܓ����M�Jgs���jI��l�%y~6[Jl��ٕ	�NǏ��Z������L �'{.�!�!�?P7:�� E9P�i��:2����
-���|�~�{�6���B��(��^�����������<��~[ko�W4��)�;lK焜3�36��p
-�����*�N�(��h��M�v�[[��+�	KkC���b��d�e]��C�������vqO�������zs�����K���!d>9���NZ�p�Ѹ���Ξr��A�aS��lwG���2�%~JD���U�	���C���Wt�0�8�g�$ȁ~�a'����E.��jXd"��|���6
-�E�Edd���&d�&0G�;lC��sY!h�� �:��>N$�Y��Zҧ�KN'=N��N-�i�nw�	iR��1�mM��%8J�(�Ү������E+�R9U�^5�X�e=������fw�J0А?I>�m�)G��NE-9z��>�=��u���z���B��dsȨ�)�k��Xy���,.��[k7����Pr�c���`c�����
-�IP��#"��I�����m�By}eG0�e�E�xnD^@Y���j�!Ͷ~+[���ˣ��l��v{��&�\�v7;��u_#Ӆ]�ք<W�3�*��D��T^���N�k+%WZ��y���x��
-�7C"�G�A[��2�cIhfP��|Ǔ<�\�ɕ������Vw�m�����G��	rJx���_3�4�a�y���3��ᵄ���l_c��#9q�.��V3�K˱�����"���s�3�o��	�u��.3Q��M	���p��z��_��;�Qu�Ԕ
-1�j�fd�x������RԶ9��W���+��GF\�~��n��^W2����c�M���������ݒ����#����5{�� ٞ.@(h��{��t�a�iR��a�*䰎Gc�sx�*uQv�o8">�Nu�q�v�J6%<Ć�8C�(P��G{f�i��r��V��Wf����jjB�ć(�0H��B�W�Ұ���� ҭ_l_ ���m�����F���6�i)Q'Z���"M���bƐR�H�������з� ���;�	�3y(����<�3���9���\l�W>fֻ��/v3�v�Q�*b�>K�;s�\�-q<@rj(��㝚Q�Ӎ���Qp�P:�e��#z�]����h��uᄀ�GĢ�5".-7M��l�Gfa/�2Ǣm�ј�$Ihɱ8�ߴ{9�/�)K4��N,0����wz�z�dzɔSc�>EbL�W��f�8m[s���֠'.@1��C(�$f��X�s�]�H�v6z<�:ϠcY%����0��<9Lǯ"6Ƃ7��]�[��-��`���;7�ޤ���l5�i0�с�-������n�ك�r�K���v�J��Hn�7:��-U���d����1V�Q}R�q:���`��Kus(e�j���B�=�n����T�l[�MF��m){�	�����,��2�h�a���܄�.t;���,���W��_�p_��r�΃k6��6J���h;��Ĺl�,k�ȃ�?�s;=��q���h{On���x�M�=�����ۄAA�G���o��-$>�}��҂<�½~�+gZ�ݑ�l�-�LkЄC$�]�6��:t(�{a+I�{n$�6C�AFQ�mq5I�.���.�F�̈{3���'	����а����� Is��<l�=Y�<�t��nZ+�6�֖�_I.� �oT�&+2��㭽��2�\NX<9\hv�'L��C?c[��=o�3��t�ʀu$�WƯ@�+hb`mb���|�� 3�wl���H�N�����܀�{1<�5!:���.�{w��!���{&~�N�':�r��u�f"����l�yAB����"Hi+�0&󔫋�L����0�2�.��%u`c��a�/�?�褘��:�յ�����љʛ6\�P�ƌ�;�#n1J��oޚh���ԑ|���ͣu5/@>2�o�9���P+��;/.��Sj��G�j^���dd�:l�#J;��C�~�s}��5�c��+�M訌m�);h��Ǐ_��)�3���i�HD�q�	~�P:挠X��].�۷��w���#�-
-�>��O 'C)�f�/P���$h�L���t�����r�x�$
-�j�����.s���!�\i(g�×Z�킈Dr�X�a����1+��W朱q�AS�1PT�8g�ve����;:�'r�T����:ќ;*��r�b9w<*FZ8j��F�l����F !�>�O��9"�~-���O�����B�Y��A���/A��c�����g�"v�}s7r�$X�+0��2:�e�4p�s=�rm�)g>���fSN�5,��ړv汛�����j93��3㵌�v��#�-���3e��ToPK;(��8{N���� ��$7�;���U�~R��~а��Gݗ�}��k�]�E�Y���%W/�;v�h*����A������] �ݲ*x *��&�M����>��{[k/{u�R}��&i�Y�����ϋ�dM+�f�����Ŷ�[�d%-&�U�e��ɚ���jB���YǬ�b�mZ��l�m'H��r�	
-B��B���[�]<�3��#i~-���ƫ�]�,Cp����{�Ku����V�ZY"�e{�������F=��0�l�5̍_��s=���sP��`iP�g{��Xn���Oh<�����u���xZ�v"P����(|�a�)��f#]8�-V�UV�
-� ��/���7b��1�ኬ �P�l�����ܓ��k������:c3ܐ����mX:�ϴ�T��J�]Y,�=
-pt�Y0��دnLhs}Hc���I�� ��nqrޜ_Xx8~���*�����Gb�E2ږ;��bS��S'�n���m;�g�\�L�u)+�\�"i��=q�� g$��\Tp���.��g�켺�l��s�F�}����Z�a����+K�0�eH��Z\D��N�� �Tow�òAr���Z�K[ع=��*ٛ�͈ׯ(�Q�ԕ\����7��0�d�b�Ú���C�q�d��E�h��A6J�3�?:m�'k�����-�R��4͛1�]�l����jwBD���X���&$G�����]�1�w��^�F���Cl����Neљ�0���l�X�N&��P����.$�e�A��,����|�
-?��o��s٘҃C��4��eeCi�ý���?��Y�k�1� E���oh�}�ս0�J���C��e���ωR�͛Ҡ+�k��[X���*vh(�]�
-� �r`���ϼ^����F���6�]"+�� Y�t��=>
-��8��*G�=
-�%E�&Q�fG�wn��r���������������k�j��Z�B�r��h��Sڠ�GBU�ɖ�εɛ�Z΋�X�-i�#��7f�ο���'g���N�2xBH+���X�����5F��me}��V���%%�D���W��|���V���K}�c�G?^�D����0�΋h ���/N�[Ods�Ŧ�x�Ƞ�+l�G|9�(B�Vo���$#�S"☄z[���I��v�|�R�ާ�,��n�p�`,�1Aj�tq��1��e\�Oʸ��k��6f]�����5�Y�q�J�n�#��[=,��s���D�'LB��-��S�I\����g�kũ&���޲�6}�L9��׀s����V{&[��7�}<��?Jb�r�7�c�X���b�y���g�'a�"�N�	�rжe��J�{�*�Ea ��hɤP��ֻ�p�T�O�ax�k̏;7U�,K���]��'��T<'k(�����������d13!0�b�N@��e����8G�� e`a9�lّ Z�"yo/._�q���I���I���:: ��	�Z�ua�Y�����ܦ��ٶ���sC�.u��"���n�Q�2O5?��#'�6 Yp�.,����1���#�#ᢐ���>�P��	�H8O��z5L�Z�ao�w	��f+n
->�\3��e�z?,��t���G*lBȒ�B�q�pJX
-��Ԡ�	'��1�#����y�=��W4��	�Ф��֣G�l�U�^�3'T���٤����S���p����J�ݽ��n�+l%.��w6�0_��h� O���F6���[�VD�Me �d��ȉ�O`̳y����l����%\q&�v���T�����$-�ܴD�x��<i�k0�fy�T� P�X�.�q@m��y�Ӭ�̑����r,`�� txS��)�(�a��lfqT���L{�,�=6!�' �$���ӭ,�U�����	����J��{h����)����?�#�����D��Zh?!(�Y*�!Z��?,,0g�mݛ�5H��K�*����x��*��'Ƚ�,>�+�\�<7���y�<s���J5�3bL/��S뫨5o	��P�I/��<MT��h��� � ����ުm⩢���^�5���li�2cG-i�GE�����������<�s� z�w�n�x��3N�`�^�w���ܩj&TI�!:oQV�e���Y�t�RY�S��y#�3�+Rω��b$=*e��@b��e21C��xZ\�۔S��}f���H~w�[e)0r,܄A��!{�;$+�<� G��� 1F�U���{�gB|]��B���'d�;b:�#�я�.�6 ���n��\�4m`�asx;�Y��,kU��k�W?����z������w����`����-�]��!֐�罷�W�P��ޡc_IF�{D�� �6-/^n����Z�P5:��˅u4�gpyM�>r�X���/+��x�r20������	�2-/A6N˘���ᆃ.��s`�)�ꚳ����9��1�B�36&-���:*-��p�/3%��~ �����5R&npcYrT�ju���I�[>�D��4D��BvmA,vǎ"�L+�Z!� R.�����!d	]B��kw�J��-w;{^�恱abwkp�x���d��o�#h=�K=G��;;=��Sn�
-9lJ�XH$/+Rt9�&�ǔ�xa*�d��э���s �|ӯ�BKǯ�|{DBh�ڲ�<y*���-������4*t�	�ٖ���+�;#ļ�pw#`J������[E���KKj��o%G�����Љ��I���0v�t�^h����i�)�b����zd��ڋ�5�6,r\��M�~�4Ε�ħid���I"��T9L�X!<�|����*[6'����xȒ��SS�ۅ���^B�����9�����r���v���9�D՛�KD��,e&��
- ��p��l~��IY�K���K���f�c��A�_���agV�	�lHȆ�Q=�e?tDC� FgTDހ:x��{�u��Ц)M��� qC/2%��5r��l)�+7(��>>���4\� �?���Nǋ�u�+�a3��x� �!��iH~ē�m��#/�q��A����P�2Qk�n,�l~^ڦ{�)pO����,��0ͦ�o�����|�R,�TPn�E�%����PtD��HOo�n���A
-˺�/Q��uX������W�m�XO�ܴa"�߀�3 PBb�>~a�}",��F#'L�qR���C~��k^/X@�mz���ɑןTvuAnl�D 7��}�t��y0�v�H3���XB���BZ��|8��}Y���xo"j��C����i/[��"�2%�h��_�?������S��f���<Ms�T�X�01s1i�X�.t����ڋHj<��a��Dn�`/�
-��^)���Ʀ��ty Nm[0K�^��Ŗ=��ݰ_�Q����Q�ɲ�ڈ���,*��ge|͕�&uP�9��/\;Ba��ˎ��H����C`���� �7���'��q�#�]@,M]�X��<�Zd�n/�4����h���9�b�3��1��T���_�$D�pA��S�p�&��� 7����O8�pV�d|�9����ր�@��w7�n��j���&]��?m�,.��E/�EΒ�
-<~ж���p�5G�V��;X9�`7�������ji��Lu���0���sHXV�¹�X>�ڦ���,�bK��I	�Y�fx�˛v��C�|�z�+���b�tX�v��4$Ċ��.��/[R�#���jd%�}�z�t�)�L{�+�٠�nzJ劧�3=��y���v�3�<gK+�ZM���9廗=�\9繣{9T@wr�=ĕ�ζ��E�ר���R�$�@�ǲ><޲^l�^�����o��S�|�r���o�^�[�n>:���p}������������_~��f׻�]�2�(
-M�%i�e�@���� _����)��z?�����83#Z�.�4��#o���֊	z��m0$1����n��E��w��2��+��,(�S�N�Ź?4��"پ�̷r�4�R�ז�^��YdM��x��l�V�>��O��ؼbXu3�!ȣ����	<'N��6���mZ���J/zi��^X��a�eB�Ӗ� ɠ\�r�cڐ��lʆgd
-F���:c T��+B�rl�X��Yx�UDi4���(%Q��ۛg[��蚸e	Y �E_Y.-]#vJ,$g� �N��)'4Ǩ�2)g��o+�Z٩o��H��$k���&D�X[X:�;-'䎭`1��d�pn���exL��� ��{���1���և[6�c��=D�����9Dm�B4۔;6_�bW�����8��n�r�(���\�n��(i��D�59�,���!&6Ѫc��mk���˶7�H|�MР���cYX��f�gs �Z�Fs	�gqX4��&�(G��#��c��TvV\�����t�s.u�\H8�CF�4�B�*}�,Ie������*��S8,�w龵>#pǲ(W�dc�X�.�p���i�A"���߀Z�8kԝ�N�\�����Fڌ%@�`���/B�RC\
-0ì]�̅+�h����N/� �+0^k3î�$X��0�oN� ��7a��Lڷ2}�e�𜇝�Jg'�ro͑�jǾ#FT���!�����uϖ�"S2�}���|��͐���h�b~RT����ʠq����)�$E/ڐ�e��V}P!%� �s!��X�Ȱm��zS��,���~�C*��[,c�
-N����0F�Ei���u7_w]�Z����;Ec��ڤL��C���F e�!	���ႀ�5v�9"��C��5����ׁ�X��9q$��G�������k����|���Uhk>�7�l�y,{	��c4�[�L䲄_8 #_��^�x(�\`"�P���q8�{C����=�0�V\��.�Ջ�:��5�ɋR3��H�df�)�T�L9ݾ[z�ܻ�4u�.��	�z�u,ت�|N(nr	p�m���݉������;�#�����@W~�d��:���=��M��+��Tjj�F��N}����[m/���, oco���{�퍡�������Vkc�m�.�!�N�{{���^h�����;�w�7hA���w�����ك��`�v�0����T����;���6d���
-��;���ޠ�n\Pu�e�wn��Kj��6L�q�ڬ��m��R��0PwMu��nԭ���[�j�T�C���z{_�����Q�j���;ꠧvխ�jn��j���U����݁��Vw�����R7�TR�jk��Zj����u�=P/�Ջ]ukO���;�֮����7�;��v]��R7{�V[�1՝=u{[ݾS݆�ռ�n���;��P�C�]uXW�-u���@���NW���l��=0���6/�;�nW5jcO���������sԳ�S�]��z箧k�<������1����QW�j}��M���n�@n�MhuOݼݳ9��P/4^}Q��mhdG��Q;u���v�j���\Pw�ԝ���S�u��T�-�c���v���ޱ�����jBO{�i��P��!4�T/��K=u��i�[����6=�K�-���؝=ݦ�鶡/w@_z]��p���ly���gx��s��Mފ�~,��o������#�D:��Ig��G�צ�����~h��^IW���s��Jwҽ�����K����7�OW��R�/T�/SүR�oT�o�������L���w�����sT�y��"U�CU�U�kU���Vտ���P�o��wT����7��<�=�o������w�����{����ƻ���v~�?�h��0�]���f|�?Ҍ�j�]�q��g�ϋ��=��^��A������n|F7>�������7t㛺�-��w]��n�S���' �Ԁ��\�4`�<`�2`�6`� �����O�O��
-��������+`�4`�<`�?1h<)h<%h<-h<'�?/��4>4>����/�/�/������
-�?��
-OO���'�����g��g��焠�����!��!�M���?2>2�2�2�2��9^6^��/����;�ƻ��{����?������'��s��|��B��ƿ6~6�1�1�џ1�/��{�>b���jD�z����F���������!f�N�x{������1��1�C�W�x���?3>��������?�����������e��gō�č�ō{�Ҹ�r���������>�I�y��D��T��L��;��=�|>n|!n|)��r��g�k��f��v���^�0^�0^����;���	�}	�c�A��1����n
-�8e���3��c�x����)�1��SƇ���ƴOO韙2�8e|c_ß�L?ǿOH��=�����¤��Ҥ�2�!i�1i��Jƿ�L�J�?�4>��?���)�%�=i|��L�N��4��4�3i� `��Ə��O��)�)�T�e)�)�U)�5)�)��)�)�M)��!=�Δ�������Q,�Y����V��6��QJ�q��)���6�6�6�>�s�xѴ�i��7No����o̜s�~����#qM�U&s�'s�l�	���g3O���3�yҬ��Y�ٳ�Kg�7��o���1������Y�of�����9����%��k�c��%��C��J?�P�����|M�5}_��.d�|p�����O��/ w���n3�c2��d>��T�z��WA���(�{3����yn �'���$�-��yhw���a'��v��<��p�gp�gp}Ϭd������R8���̑.��c\p3�.9�g~����@,��+�kk泱��b����b�����#��0�y�Ր�����♗\�y)ƞ�</�y&,�.�����3o�����0l/�?�?��\a���.�.�������%��_A\�OOͼP�|q*��.�.��d�Eʼ,�yC>�Q�����W�|˼p�BC{�R �a~6��h*�T�۩̏��3��w�283o�~��U�]	*9�r�R���r�rULy�o�V��������Q��<�����Oz���N+�<�V��ǝ�X<}��%��g4u��U�T���ү]��G�:�f�����'�O�?����LGn;�MOJ[��gR��w<��x�葕�z��y��Q��}�����(Ԡ���~�Q�����U~���G��(����M?�����:�h?�� ���H�<�����xR����K��
-�N+��x~�߾��K��z��=�����^�l*O����~�s��$�f`��y�7�T�=�x����=O�b%�gx�o�C�>����B���ʳ����s���{Zy�7�f���|���h����'(�z�p���i��؋�r��XC,�N�i�%�e�����W9�EI�̋��|��~�����B�^�=X�Wy���J��������k�����B��[��(��%��:ޮ���C}�w�7z�� ��#�n�M�7C����Y	��J��ٷB�'��yǫ�������.��Ay;��`�+��/+�;�����T�gE���;!)�U�]P"�n��/Л�x����!V�)�P��PNcw������ ��+��ث|W���{ʟb0�&������g����������޿�\�}�7�c���导8�?U~�|��Ao�����BN��3�#޿�H�.���+��_*�ǽ����䗊r��c�~��)H�G���3^;G�ɪ�Y/�Կ�:!�L��9j�3Կ������{6����m�R��Uc����/x����_���#_�*_�r��կ8R�?���U�c/P���Sl�ר���_wW�U�Qɋ�o8��>,��T�꿹J)�P��WO��k�u���}��I��a��m*��;8(oU��|�z:�|׋���������]�i\{�T���ZeF�+U�/���W���ܣ�o�vP�ǫ���:�B��?�j���Z���c(L�Oz�F����r]�*|�*?�������?�~ZU���6��x����(��9�W^�~�T��|�C���������J��U��Ի}���}7�{����U�I>�k��m5�}�'�4���S����*�ߪr��S}���O��?Qk��>j���g��@@y���/�g����w{`Ԟ��w>��(x�O�y���>x��>�Ž x!��y �O�Z_�A��</��G�マ�z�WB0�</�\1�=t�9�g{^���<���§\|��>� /��{^�1�0���ػ�y^��_�y�Gy���Wx^烠�*O�Є�x���=�����O�ASTM�h�WS|���T]S�'�)a�ռ1��|S�����\5C�h��8�)�5�*͗ՂWk�k��u�v?-xT�^��7h��k�����/��7i�����YS�nѢ�<�b����4�i��k�oj�Ӛ�k����<�R�Ԣ�]��[5ߢ��MS�4uYK�5uUS�ִ���<�ig��y-�(m����c4�okޚ��?Z��E74���M-�҂��zA�niJ[Soׂ�ZzG�v����ޡE�1<�h%�i��zQS/i�4�N-�XM}��>^��?����2OP�ٻ�y"<���$E�<YтOQ��O��OS�C�P��3���y�����y></��^E��EP�Ŋ����TѲ/W��+ �x��y5<��������y��]�&E��-����z<��h��.�y��x��{����v�@���v�w��w+���@�{!���?�珡��h�?U��ߧh7�T���sx~�h�/�w���U;�D�{�x�x�
-�'��eU��)�<����tx��3�y<�V��sU����x�b/T��/��%�����rx^�+�y<���5�����zx� ��y<o��-�����;��.<o����<����Nx�ϻ�y����v���c5�BU��r�O�y<ϟ����%<���� <��C�|X�n�<�G��<��o����i�T�~�Ϩ�O�햿S�[>������#<�����<_��K�<[�z��>�+�|���k�|]Ղ���������=�[�|����̝`�y�of�0�H�$HP#Ǳ�$NE$d�Y�\eɊ�f\Ǳc;��X����`I�	�V�`�{�{{�o���(9�%/���������)�{����ڼp��U�סn�M���܅{p�Cm���~g��.��]�گi{��+8�������v#�Ym��t�	�t�}]���ӱ�^����uL� �s�q!�c>!�O&Cay��(��l7
-FC!���0�������f2a	L��
-�0���I�,��=�}r�����[�Þ��"�'y������6����v� e:V�MX)y({%�"��8�J��^�M��{l$�	6c3H���{;�����]���@�}��A���ls��(�>Nx��c:�"<M��Y8�}�m/�v�8�E�ξL���}��*���:���i���M�[p��]���<���0�k:vfH��؅���cWB�{J�!���C���E�G؛�a_�~��	$D�O8�p�P�a��	G҇t, �Q#	G�h(���1�'G8�p�D�I�El_L8���p
-�T��PJ8�8}R�tB�5�,��0{.�<���@�.�E����n�}-#^N��p9Tb���Q.}�Z�o�Մk�S�����CHo�q=i�7n"�踙��@�t܂MO����m�v�^F	��;�w���Y�kU���~�y �!8G�(i���	8	��mP��i��쳄��<\��Kؗ�
-����k���W�웄�;�&\H�����p�m��O�@�Y�	�w;<�3:�Lv�.]��\�L�{`�$�y���>>��#�?q���Y�!�c�b�R҆�1J1F����0��P�a�H�7�p4�(&e��8��aia�"(��PS`*��4�3`&̢��l�@�$��� �=c�b<�0��F1�t���x�=�p��N�B�{10^+���%���2(g_�ˡ{�J�U�_M��p-��^H�(痲��M�����J�6؎o�]��ூ����8��0y�ȹ�X�?�}�}����)8�}F�ܑ��r�QN1�)FEU-}0"*FDň���f��p.R�%ʾW(�*\þNZ50�x��&0�Pse������e�e�{���1�Q�as�F1�Q�as�F1�Q�as�F1�Q3��/�9�b��ϼD_��#B��r��w�3��
-� �C�	� zC�K�~q�` "�g��i��8���8��p����H�Q0
-�~���W�'^��xe>��W����0&�$(�b���L��S��c�+�+ӱg�L�k��q����w��`�1;�عq�v�|��=/μ:?μ� �`aM�p1,��T��4����/�WˡV�JX�ay��:�����7��DY�k�	��V�m��	w���p�݄{�W�%��p?!��������>�����C�=L����� <Ix��ӑ}���\���r��y�@�"y.�e�+\֫���N���M�[��	��%�4g�#�O�!����RO��1ٝ�B®�\b�%Vc$hv�f�hb���hz���hz���hv�f�hv�2����*]��t��.�.�2s)�;���	e[c^����@_��a �A���yue�ać��I|�h(�1�ǒw�x�@|"����.�"|�0J`
-L5F�{Wśק��c^�	����l�sa̧,N_\@���e���˰�:��:�ԋ�y���\
-l�&۾ɶo.�r���Pi̗V��*Xk`-�������F�M�f�-�{�v��A�Ә7V�༿A=ޠo�%�A]���a����>�(� �!�k~�0��>J�cpܘ/���p
-N��g�۞���\���|��u��pn��)T6ӥl�>��wOΥ�Gx�y{d�7Y:�������]���2e�iȻ]�ͻ2��o��Ŗ)vw��)�y�;޼��A`��S��`�A���M�,	�v�B|h�y8��Q@H}�g
-��H�HMXH8�p,�8���;{a�d��)0JaL�0f��l�9�Fύ7� ��n!�"�Ű�ƛ�,�W�_e�I[o��
-��w���|wik����x��݀��pS�1��M�m�&�5�2v�v���`/��p ƛ"<G�Mˣ��G'�OQ�i�srj���~r1���\�+p��u��pn��x;EY�}���ś��'|@]>�7��c�O;[�$k~���՚������^�8y�}�/���|�H�b�|�*�=��Y�0k�íI(��Q�a�X��0�:M�"(��Pb�GSH�
-�0��t��b�A8f�l�C�\��ɻ��Z��E��a	�����!�w儬�~WA��M�����*�W�JX�aۭ���6�&k~�ٚ�s������Y��v�.�{�
-��>�z�a?�8��G�(��pNZ��5��5]�y����x/[�+�\Y����-W�m��c�ʬ8W����u�T���)rK�6�ޱ��=k�䉁z�1=���f��ݙ����n~ө��|���[zC�KZ?�7� �|���f��Gh�P���a��F�U 2Rd��h�B�|�l�XcEƉ�� 2Qd�H�H��d��)"SEJE����5Cd��,��"C$�Nr��#ѹ"�D�,)Y(�Hd����"�D�E*D��T��Y)�ʭ��T�R�i"���Ւ�K��:��"k�W%�Z�ֹ�ʇ�����&m��V�7����-��5�&�v?.:��j�Dw���-��oL�m��8����f�,����bш��"G����uL��	�puR���e��)��9#rV�$v�s�9&r\�d9/r�Fv�Z]��Y��B�@Vm��ߌ���HY?�R�~��M�["�E���'��}��!�e�Q�c:�$�N]��8Eߦs��`&�^y	f��`��%ع*��.��Z$��XN��> ��H�d9�%r�K$�d�U"�D�w��?��'��j��0��"#D�;��2��%2Z�Pd��X�?Se�2U���x�	"E�I�;8AV?	�TM)a�7%�LSSE�FR!��4U�A��R��T@�/����.��i"Ӊ�c�1fbLc�+���Ȭcf'�������b��/�@�Ld��"��"KD��,)�Y.R)�Bd��*��"kD֊�Y�`g'8f�<r��6& �D6�l�*�Md�������MX{a_���O0Ρ�}4�$#<'�d�I>Ex���3O�K0mϋqA��%�.�q%��UW�]���f7ĸ)r��m1��%v����8�x$FN�Q�1�`tM��n��.��&�'��k���Qx��0y�{C/�٨�H�"E��"24�$K4����r�<�U,F��D�G%�g
-�5�z���0&�$(�b�%0�B)L��0fR�,�5'�,�}�y��\�zA����M�Z��,Y�h�%l�ʁ^ɩ �����VQ�5�D�J��IW�J1�]�&x�1"�"#D��-ѬV��F�L�J��{fS�Y��P�V��a��L4�n��"%^��7�Ib�)$S�D�Q�c��f�:$rX��Q�c"�EN��9%rZ��Y�s"�E.�\�$r�c�
-��/܀�pn����<�G�ӄ�.�r�;���w�L�&�߿�٥��a�K��i ��iX��g�Ԉ&&� F�(Mz!�iB�X��/2Ad"�IP��c�V�&K
-��*U��\\=��2M��R�i$UH�t�얝��!љ"�Df��y�b�'�v+�Z6�#�sE��Y R&2F����,���Y"�Td�H�H��rrT��5R�
-�Y%R%5�+�Z�kD֊�Y/�z�Jmk��&��"[(w+�ͷ�g������]M�^�G�ڋ��%rW�J�61��~�v@����8��PGE�{�!q�ձ&�:��ڟ�l�m�Y���8��Rg0�6�s�<\���$rY��U�k"��Q7�&܂�p��C�i�T�Aw�	y��B�0��ٔ�STl�X�"c�2��q0�v&�x<G�I'H��L'��(ɓ0NHM�(q2���S	K	�I��"3���3�p6�TF�i*�ŋ�y(BGrHz�C�Pd6���d��a��B�t�bXKa�C,�{��";E*ŷBd�\��b��ʭY#��=-M�Q�Ad��&��"[D��l�.����	�$�cT�^q��� ��: rP�9�9�p���ē��8�q�J��y1.�\�$r�݇�U�k"כS��W7En�坦愺�Դ�'�}�"E��$ѯA�
-� �C�	� zC�$6�+�O��� ��"�ȑ�%2Dd��0��"#D
-DF��-R�dN�1I�'2^�(iAq�1�	K$a�H���$��c.�3��jV2[d��\�y"�E���,Y$�X��D��l����E���������,�r&m2��	�̕d�$S����D&s2����L�x��ɄN�s2��ٜL�d.'S9���DN�q2��Y�L�d'�0��]T�)|��I�Z�dW'��y���{iEpR^���$֊�Y/���jd�1Wզ$ds��[������%!���&9�$S�v&�jw�����l��ߦx�ro�i�/�HJ4���$��a�#I�:*r,��Q'�:)K��2��N'!gDΊ�9/rA��%��2��Wᚔ}]jV�d���d�Iu�["��p��=�/�"S}�z(�#*O�(�s�<p����C�8��dz�z���WY���Y&�Td��%�A"�"k���c��u�#yg�H^�=Ry$�G�����0]5����M,=�]�저6��� 2T��u����������p�<B
-,�^z��h�B�1"c)vL�_k�GOq�Ɓ񧏞`�8%�b�X���2��bm�����E6����A��"����Xd2UY-��|1�����@�:EJ$�%�.�0H��"�U�<��#�R����p�8�XK�ſ,�)_
-�.rԇ̑bf8�3v��~zv �#2W����Q3�~z>��r������Lr.Y$�W.�����@]�	�g�!\��VL�J�ҲW�Yka���Q.զ�$�Zn�ض�j	;f��d��3$��0�����V���}c�(}�j	�B}�8��Z��N��l���ؿ��f��D.�x}EbWE��\�_7�&��m�;bܥ��~�{x��f�<��a)��y$Ր<9�F���΄G���]1�����p٪`/�"sI8)9�'#=��"�YO�?;��,�C$�#p��q�M/2�#�y��q�%�����J��H�"�M�Al48�L��'�!x��#� F�(��f9m6ŏM6�z��xʟ �M���QŒ�i+֓�z V�X%"S(l�Ř*�R�i"�EX^ˉP8��pNZ�=�r7I�Lg%��:ǚ)zN22Wd��� �`!,J6S�C�.�K��e"[�\�
-��"�"+DV��Y-�Fd�Ⱥd�_�lD[_�i�R'�[�dsj�&��z�fg��	���Nc��A�\b;1*�؅�\���b��X!F�PTC��^�}"�E�d��0��p��q�q8'�>@Q���p�J�0�����2\�H�U��y�WÍd�p3�<y+���wD�����Z�&ۧ����'#D�<�IA:�tIaЁn��.�WO�y��HB_�~��� � �
-�`8��	�`�P(2Fd��8��ޝ@��)f���<�7�uQ
-R�b�&��ɪ�)�SR�2#7)����Ez��L�Y"�SL�90/�,�edZ(�"��b,�X*�2���T�b���T���MW���)�R�Y'�����(�Id�Ȗ�rk�Y�s4�C��xd�X�Dv�l7���D���K1��S�SS�}�����N�{B��)�wJ��"gH?+�9�b���)��]b\�`��D��1.�U��A�W��:T��	��6ܥ�R�P��l�R��",�6�G�='��S��ڝeu�h�T�U�2���HOby��@_��ܦ��"�SM�0�2���*�7�'�_��A*EHt�� �|����(��"�"c(i��%���L,Ɖk|�I�@z��T�/I�Y>s@OMEJE�����b��)2Kd����"��&�Η�"e�x1�#�%�E�����
-��ɸ�u"�pn�s��Tdɷp�w�x*D�S|%����%�L5����"�D֋l �F16��C��a͖�l���t���v~g�9�w��I5�
-����z������ڽ�ڜ�GR��lv,՜�'D���bO���z�ל�g��O5��R�I��j.I�1�R��O!�b����7W��TD���TsM*�}����j��}�"E���4��"]D��t��.�C��H/�<��i�E����_d ��0�ah�����gx���G����ɦƐ4.�<��u��ӌ��fr��~�X��"%"SD����L�.2#��j¤ʙ�f�:sҰ�w�yb�!�b��Ht�X�D�,9/	K�ZF��4�ب�M"�E��W51�t��SAd���%�vL��W+���l��Ț4��F֥1�L3=��x7���f<[�ÄEmŻ-�4ߞf�"�Dv����+�Od����"�D�q�sX�#"GE�����i�Y:8[㐓iȩ4���9�E�t�!2�e�}Zr5&�L���� rQ��e�+"WE�Q��0E�G�i�On���Ν4�����@��\�Gif�����n��β�C�	����VS��X}p��~�_0A>N7��a0F����H�Q"�q��`<М�ɐg
-����7�<��#�EJD��LM7٥bL�.2Cd��,��"s(h������s��(�J�"��,!\�PˡV���+I_E��`�ſ{=l���	�f�-�5ݼ�v�N��ay��v/�K7���P�y��c����pN�v� �	�Y�s"�E.�H�s8D���	��:X�`&:��p��U��n&���l����:����pn��"�N�)v��G���f��@��#��fH�f&��'�%��ڌi䒲��t��DzB/ȃ�����I��� ��h�L�a ��0�C�jf>�B|ȅ���a!�1�L���97%rn���f3��f�:E��8������q0&BL�S`*v)Lkf���h:�0f�l�sa̇Pa,���L�S�Q!�r�J��V�*v��p����4��t�Rd�Ȧf�f�-"[E��loff8;Dv��.�{)r?��p�Ҏ633�cǛ�Y rN73���d;�%rA��%��"WD��\�Ά�pn�-�w�.܃�� �#�(�9ҹ�Q]��D�a�Bw�!��� O"�1��|ݷ����#�Hd�� �|��"�s�!�
-�`���0�57sݣ�@d"L�"(��~3ϙ�Q��̗\ܬS�L�i0f�L��a.̇2X��LSKD��,)�Y޼�߫DN�4U)�"+EV��YCAka�D֋l ���)�6\&ͻ�m޷�K6����Ͱ��v�	��
-��8G���Sp���W�T��w�ns�E�on��b��s@N�:C�
-��z@O���/�0�a0���-vȄk�P #[���]�%���Ay|\(�1"cEƵ0��\�[��	@/{_MĘEPLY�	K`
-L�R|�Z�q����-L���Ѵ��2T.tf�0��l�9l4����a��N��^#B74@/ha9e�Id1�X
-ˠ\�"�E*q����J�Eֈ�Y'�^d�ȩ��F�6�0��z��zK�Z"��[`쀝-��[���RgO��dA�,��/��/��*���p��f�sL�8�p��)wN��tS�ia�K��}��s"�E.�0�U�2@��%�,�+"WE��\�ᾨҌ}�Yo�`5 ����p��=��!<���4B���z@/ȃ>����y1�@ȇ!0�È�&��pdKS�-R(2�X�aL��IEP����T(�i0f�L��a̅y0@,�E���RX�PˡV�JX�a��u�6�F��al�m�v�N��aT�^��� �Cp��Q8����Sp��Y8��\�Kp��U�סn�M���܅{p�Cx9O��@�
-� �C�	� zC���?��0�a0��0��(��0
-FC!���0������a2���
-�0���	�`6́�0��(����	�"4M�i/~���KHYP��Y�Y)�
-�jXka����	V�06?aV9[D��l�.��ĝ�v�������8G��L�O��9-rF��f�s��0ٗ�`f}Y�
-��b\�N�Z�O��7�0��e��O�O��VG>쑯�J�|ިz����7�A���1\a"``Ф"��'��0,h�;A;���(��0h��8�ùgv:cE��Q`c�:%d�
-�A�3-hv���?�L�\up_u�y'�.�R燎ѹ�����o
-�7'h�87��-�ea�B��.��	�ci�^�I�*%�J�+`e��x���1�qV��6(�#%�n�I��Ϭq:7A֐ym�T9����'V����C�T�7ɮek��A{�IbKj����Ȇ �Qd��f�-"[E��lyd�b-�G�d۲x�4(�VQ��A��Ox �9;�q���8{4�d����I��ڭ�F�㤝��p
-N���٠=G��p.�U�D�e�"���rZ����z��A"�}���;Ġ���}d�M&��`O��H�7�"���A{ҟd�&c? �Cx��3�l�M�{`/��9�087�c�aWp-*�J�Z^��M�I�I�Zb�@|��!o�)qP��{p�]�vC��a�J84��px�!�[ ��;�rF�]�a�`��q0Q�G��9Ö��)ΰ��U�߱~i'3mI�\�
-)��WrS2��J=Ka�8�s l�S�߻��ragf���2l��$�����.܃�� �A5<������2lGm�i�0��v{�=�ˡ�C%����
-Vg��;��'���qɶ�$����uɻ2��4�*�\��i�S�iR�q��
-��"�"+4�Pj �t:H	��0ɰ���)��hs�9��$�ʠ�n>�M�iy&C�<�u�K�:�.ש8ϑ�<'���곳H�	�2R�e���IhFP��$���;�w�܇�0��Q�x�f9�R�:v�}�
-�"�� ���ъ�Գ���J6�2-�Z��2��@�V��4;F��huiv(���4Ze�=�f�KZ�4sι%�Z��+�9�H�`�q�0>��I:o�X���E�sZ��W�B�8�r�6�V��J��̮"\���5�ka_����]��6�x���V��a,%m'�B艽�p�n�=0��p �^«���p?ŷ�� ����i�b�>
-#���1��pN�8á\��p��~����eP�}�`�"�w��)��"��pz�~��!`�nf;CW�Fݻ�Bw�=���6�m�{C��)�?� �`��	�
-à��A��
-`$��W�6���b���=����\#��Q|3�K3;�<��瓧�p9��	��LX"�#��~��s(�7�t�0�(�:�Β��6�p��G�I�����	@���9~�/��ׄsK���9�
-�T�n�41�6z�	r�52^���D���il�-t�5�KsF�������`��߂�O����[ۄ��'l���A{�Hߘ��t�rvɴu�= �j�J4��n���c�RVk�8�2zfr�B��4�N)�o���om�����29������vs�c��g��ׂ�h|�=��=�e;�Z��S����O�i�O��;�OK��iاmt������m�`ߞ�}�`{	S�37iof�����ۙ�����t��ʘ�is����ly�-���tjG����v�1!����fk("��m�'LY9�y0@Y�ͳ-��3v��Bh���0�� x��]��-�-����[��n�+3m��vE��-��b��S�Fd�ȉ$�(���SvC槈l��x��L�rK��>iO�,�	��=c���O�
-ʴ)�Ͳ�2>�;2\8�XP�L/2X�Hd����C9�lB������UK�ͯmw��鏳���6�9�-���v�;�.��.�ݙ��2������ÁL�=Hx�e_�g���Y�0�Y{<�Y���g�&f�9Z�s�6���1(e26<�Yy��Z��U{��p".e���)�J��'��t����ݩ�kb])�G�Œ_vޖ�{'�!�9;)�9[�w�>������ȱ_��S�s�� �m�}*��䜄,�r�̓����/!3��v@B�}�������mN�	��p�@��ƾ���~��O�ٷ�=� +w��aL��8�L���6vr�_3��Q�IB1��6����a���W�-HliG%j.e��F���"�EF��+�cD�H�8��d�	�P�q��x�	"ˤ]�,EJ�*�DI�$�C|�D�%K���E&���L�*2=�	��D[�og%j;��/�����o7��/�o�/0}~�y�L�_`n����{��.�omW��зI���D���6��Ը��ۘ�y���Pa,��P!�ryS�!�z�3��8�ۋ4E6��g])�~c����[��aM|���`��p��q����M�#�^
-�M� lc�%|:�m��6f����y�$^�5�l�%b��W�d�k0֟M�Mʦ��6�u�M�-�6�M%��nz�M6[�.��%� �df{i⳽��׳rG��"���<yئ�#�m���l��ɶ9m��؄]���&"�m��"=Dz�����ִ�+F������ �$�/2X���kh[��{��1��lo/k��:��lAۗl��%�ݼdZ�l�$��i=�����%[��%����`|[;��e�������D|a�/�"�b�;�Lf���f����|���-���b�0�[(VQ&2������}���W_�l�����x��� 	��Y�l�ٗ(_f�|��d�l�qw���V����IbLA��x[���爔HuVROHB�D'%��ʱc�^�`
-����W���Y��Sm�ʤׂ��`y�nI�C>O}.���~�f�E��78�oUݖ����{��Y���^7oؽI	�7����o��or�޴C�޴yYoRʛv��Lx�B߬7M��_2@dC2P�A"�Y,�`H��N���,�9�%{�y�u�[�k�b]��ڷX���7�[���b��������_	~�d}Վ�ľf����e_�c�ϲ�ĿV�����~{E�^�_7��&E�)�B�fC���_���_g�u;���K�1-�N�����VG)vf�����*�8�osߦ�oS߷���������m��6��6�D�E����RX�P�esߴ��淹J7�ڮ���;�wh�+d�^)�Jv��9���j�c�d�c���C�38��yv����)��U���X���#R�f"y:�Dӕw�Zޱ�������~�Y��;m����A���w۾��8�^v�NJ!t��)�N�l�27���;g�w֭�FΉuD����"t��%�.�ܕ�q��d�k��(\�-��໶:�]{nB��m��fw���W�|����b��ewqz�c���}�0�ȹ/��8�p���ɀ��Y�,�d߷�R޷�pܾϜ�}{?�U�}��A�ϸ��䷃��vh2��k;Ӷ[;������=��6#Ʒ�?��o�����V��Ύ�~��O��=�����;����d�q��~`�����?`�,_浳7�?0=���!�=�b�[����NF�-zz�-zz�-zz'�S����U�x�ȃx;�����v�N���{7��k�ߵ��T}�NNɴ?������Iɲ���V�|ƮL�
-v�et��t�c�ub��D���HV'�V'��c�!�D�D��ٽ-:�*�[H��YHq;�m���;��)���[S�є��#)����Oi�@����i�?4J>{����Oij����R?�'�ANj��?ҽ�����['�O�#���e�`����vv�Ӿ洣�?�sq�k�� n�`����I�_���S�vB�g�?��������R5Y����q}~ʩ�)��OmI���S?�+S������ݜo�����$����!8�-�����_������J�烿��R;9�1-�P��v�c�܎[�0�#p�#ɿ1���]@5G0���Zڑi�2�X���L'�4�I8%���=��C:�9�9���?�{��ܖ"�i�i	vLڗ���K��5�ʯ��~m�a�C�H��^�Ӿb'�i[��=��oOc7���I�a��xY�-ɰ#I]�|���+Ҿ��]��=[B���;��P�?��������H��'�"c!�|dW=�Q�#;����GvK�Gv)�-�.�nO��i��I{<�Ӵ�5O'�_O�_�'�ӑ�Ⱥ'��"D覸�D6Jt���"�Ud��v�OO�{�7�������m~��?�3i�.Q9��LI����N�=Hkjq�:��l��x�P9�.ʖ�?K[����2�U�9iݔ�����ݕݖ�l�G+��L��)��U���ө����i�Oi_(�'N"q1�(m����+���>���l�X��k��t-������JH����Z�����h[���=���PU<	K��׉�?��Ę?6i��:g��$4	���3����'I��p]c�����z������j�J�������,���kw�ЦʍF�jC�̓"	)���a�wL����}����7�v�Z'�	_�&��K���.�T�5��ߨ����kO��t&&��f�uLC������h��fD�Fk_�uE�b�����b��/���m�t�?���_.�=���A<O@2đ2��}��h��ս:�;��-�i�����7O�1Jy�bd~�4Ь�g�Ml�VJ��_�܆ۄ{�g���X��m�@OP��:��de���
-�M%�֢n��1�ڽy�B���'�G���E�7GIU��X~w���܌�H��]\]�N���so�H�U+k�֍��4[��U�FԓްD����{�������ok�-�ß����蜘�{�O=UO<O�k�퉲���Ǐ�����I贸C�{�k���+����)"Τ�^ɥ��=ވ�WA��3�u���N�Xs.u�ψloC�Y�۟ՙ�i��3������B-��O~6,����MM�ړH'@�z��فcBei�@��$">�,�yT���$���i����(M{[{}2?�z9��J9=Nk���n��Ј/�jj�Q>��u�E�+��_c�	E"S�h��M~�,ґ$�,!�Ί4>�	��{bf�n<�G#M�H�Z�����yW��p�����m=I�ϻ=��I���t�SD������������vY�/��B#]�
-dE��P<+2����/�V|O58��eE�ͳ��G���|��F=/68�|̒�sr�:�NHkuᾺӏЬ%Pw��b����'q�Ê^�؃�9�@��Q��M�+��XO�����;���~1�O{�}ھCou���>��j��DIl�q���x�17E�C�c{�J���.4�Ԭ�j� �Q"�Ϫ'�e <)�NZݞBj`^r[|\c7Q�'%t�dE�Vg�c�$��|�:���Z�m�������z�N�eݙf�I~������>u��6C���b[�����lȪ��W�M��Hu*Vs�CW)#rj�@��+GF9�a_��u�:�"�ڧH�Z�pbB'�C�:�����r��>�������u�����*��+��B�v�7�y�/�h��/��URc����u��]�~��] �Y5DJm\���ㅝ�fM��c�˔���Gb�RcD{�W�x��0v��s'���&�>S�&�YNh�ް�8�ۯ�"��~��M��=��٫�Q�} �A�W��j䪄����;J� fp2�vB�­J�ˌ�g�8��?�'2�O����d_t���G1�,6kq�w"�y���F�}��4߄�P�p�Lx��c��~)�6�yb�x��x3�sk�1�p	1�Cݾ����u��Z�
-��?�ǺK�x�v"��ugJ�{g�8{W�L�7�Ȑ�\@��II�цQ�k4�|^���$��M�#N�P�OFMn�/�w�/qBAx��m�Q�~}+�4+Z��;�-٣�{�/��uġ�V��_x��Q��&+o��$�^�*���NõG���Y9���q:>��OH-w��_�!�K�*�`�׽}Y3�wq|��F�������v�p�t��J-f_�,��}C�o4�Ͼ-��6�hRd��,�7�%��!����I��u[���ر#-�UxݫR�9����.[ʽQ3��>��N��z*OS\���oF��@�m��l�N�I�.�j�������w�	�Ecǹ����������o�j�ݷX�E/����'�{^ÿ���,	���֟�|��E>�ru�Z�zw��a��Ku\O�$7��w��"w��<i��z��{j�5u��,42��:�>Q#�W���',���ƪU��1�m�ǩ�v�6&l4�����iG��
-��N�S����Uw�q�=�i|s���s�=�L7�����9 �o������Ǽ!�&EZ}O����"]�c
-�{�x~�h�Ic7[����b|;v�h��=j�wء[��̃��(P�ɓQ�����x����v{�@�Yb;��Y���c����a�oy8zP۾�=h�Ub�>#������۝����቏W�/n-_+�ô+�5���B����#R�W��B��V�ޔ:�Nw$;��S��⣱ڶ}��d2�򤇑1B�d��T$���O\u�Yu�"r/2��o���D���5ϳ#�O} ���ț����}W.�������RDUJh]�t� z��H+G�(r��\��?<��FÝG���R��Ƕ����Ӛ|�|���':���J��>�:����r�*����H~6�u���Q�^�B�5Z�����n��4x�E�h�_�R��k�݋/<��D������T�������F�������r�:uWo��SL����ћ!��T�=�6�gl��[��Z�����Ţ/=��o��o�g�=c�	���)s��i�l����}ȓT�%\#��)�j�;㉄&�)�(&f i�C�G����u^#���}�^�K�R�ZS��Wb�Z���Z�{=���}����|�Wg���ܳ�	7�>���|bWˮ�$٫C�V�#���t_�ڏ�?_[��Y���[�c�H�u��!~�0����:���t�9uF��7}�	�c�±�~�!��V�,�O�T�8��1�O�5�y� �Ŷ�&�O8�؏�<�^5'�}�ת��&�7�<1��Ze����+��Bo��x��������B��}�>+����}j�I��۩��6�����l`�a�E��i������W-�c���k��&O���Y��d�߫��}"�	l��(���
-u�ga�/�q%z���2Z����c��*Gv;����˹�����Ʌ�q���U��\�'������Q��P�Mux������(:�m(�>U�uV�7�?�J��xGK�Y��X���1��"e�<��̡#��~�����e��$+�6�t��)m�n;@��[�b:.�v��@��;�y��6�m_�C�_}t�r�'&���$v~��k����K�!�I�w�"O�xԢ��c%t`?��,�V���W"�_����~���������B��h�Q���t�QOt�Q�O��zk˚��v�y�j.r�B/<�>�h�GE����>�5(��ů�`!�yg�l���/C��ȇg��b��a�n[o�|8&��+��4Աr�4^���^$����t��y �=̣�2�r���K���Yv"���_:f	9��R�G���ҡ�U����j�֣�~���7�]"IZy��+w���𵌼c�����}(֯����cg���~#����x>
-K���mz��L������z/t�逻
-���4p�j�o���z�>r��@�e���ך�"3����7�N��g�m���:���m������9z�"o k�G���1��A�w�>��j�)����I��t�W[�7^�ri���ǜ�	�
-?G��u���D��*��b�u����E՟9���j_ſ�=lsG�+����;l�Y'=r���чMnWI�����by���A�~��	��@�=Z�d�/�}`��#����En�Z�:_�E���/�"]��S�����:�m�k�=N�Z.���ZEۓS��@�E��~Q�[��NV{����`�'��}�:o��=�.��t�FQ����.b��w�i�'��4��~�*�f���+�F����|�E��9�:?H�E?ͯyc�WI��CݷJ�����]�����b@�$�[gym׾΍~STw��v������1|����}1Y�F�jV�a=�9����(�t�m���5�f���[�Ov�3� A�}9n���,�}����]UW���W~/�N��N����{u�����@����xRݗE�1hfn��tDvDN����o�
-�$�t�n:��reX
-tW�#>��V�]�W�����j��?�7�4�����'�Q��U�f�<��?z��J�=}l����'}{�}ʉ���;wg+^�8�Q*�^��;��"Rw!�BO��g*�S�Z����ʧ5Q���765��_~�[7Y䱮���k�h��'�>��SUBK�Z��eՒ�>�u��Q��4t4���(�UV�AMCK�_F�S�����]�Y4FW����"��W���xt��^��H�zؤ�H��	�YZ�
-��9	��<�[��_t)�m\d�7�p�G�*�%��"n�F�@�j�|Q�sQ���q̯=u�ܺ�j��F>V�|�i(M��_5ɡe��x?a��L��x�?Ո��۩�1Yt�#����G�T����������&����j��x�}�ᣯj��}̈́�u��RY�~����5���ߘԮ�o夷v��N��M�_od������빪��.��,?�Z�ܦ�_56IS���w'�;5v���S�ZdA��V�5M�Z�����c';�65?���O8z�?I���{N4����@U�Q���o<����w��F���ƞ��7���1�Z���d,�ָ���?�c�����Ф�~���`�H��BMO5DE���S{����J�GX����R?_�E�c�ݵE(�JV�	eۈ>�+!U�}��:��bnņ�U��t��ܷ��N����b��PGr�����_?�|�^w�y��k~�Kcw����y�����_�Դ�`#Gb�8Խ讆��a�%�OE燞"�~R�^�a���vh/�ݒDc�؏��?�r_��o��m�Eo��m���������<�l����
-\�:�v"�כ����e��V�{�j+�z?���4)�:���N �8�[˫C�;5c�
-�r"Ob�F���V�u��c_���΄�F�2�ܽ�z�ڞ�\<j���~�;�-P����<{�=U���~��K�^�ޗ4�C��/�{�y�{���^���u�wj�b:��Q(o��j7ad�7R��C(��*���(��;��e���!�j�Ky�'��R���a�<TU��w[����*0L�nӡ/2U���:?���3���y�������$}YY��*�F2d�R*�6"V;�^�m���?���-��������)���R��2%Z�j���]�tu��+]]��jW׸���u��wu��]���fW�����m�nwu��;]���nW��Z��^�}j�9��AW�z��#�u����]=��IWO�z��3�g�97r���^t����]���UW��z��jWo�z��Pi�\��F�Q����f�F��/�r
-��c$ɯ���ÎG����xM'���$��)�T�*�?����4��4�B��T��S��(e��iH�t����L)��o��f���l�'gc=5����J��������y��t>֧�c����,��lֳeX�-���X��/a}n1�_-���%X�/E�f)��a��2�˱:�cu�`��ˑ�*�ϯ@��yy��j��5�kk���!_\���ys#�M�[��/oA�������kۑ��@��S���]$����~k7�����QU������{I��>��#��O�{�:����X�?���CX?<����X�x럎`���?���Q�9���cX?;���Ǳ~~�?wOq�J8I�Ó�}
-��Oa��4��������`��,���s���#� G�]9��U]$G7u��\�%_V�T�+$�RW�<���Vװ�������P��_U+Y��@��J���|u��C�]t(�Χ�q��g�� �:�Q�!F�Gh��aM2FuFǪ.�m��"���8���1�MR�x=4���)Q=�)���f*݋|�U/��P��V��<\sT���7�<���W}���h��.D�"�{��.Qѥj�L��j��~m��~m��~m��~m��~m��~�@;�E�1=R�Ts��v򳣵�(�c�X=Nw���=QO�E�XO�%�XM�S�fU�-u?ؘ&#��?��xF(2S��Y����H���憢�B�|�E��x��!W�m��v�0�Z�k�Z�k�Z��u�1�`�A�1��1���e��Q�n�<TDE(X
-*C�
-����`U(X
-�H�Y��:W׻��M��
-6�
-�L�:1q���h��o;�iy����g��Y�N4��]�IB�n��=�)������>-o��cR�9����9Ȅ��:���ޞ1@���?L�8��ab'��9�:��G�O�=�1쳨CG}�RΣ���O`_D���ľ����?�}mG��=\WJ�&V�θ�>���9��:�������w[] �-�:Kp�U�p�S*�r�y	�}u�%���v���N�<BS=9�vg4��E_��j2w�:�V����A#��7C��"������������~�t��{VO}��^�>v���[?]Ç��>Z%<�<�ՏH�sܯ�;;Y������3@wq��]���2���9)�|4�3X�bAS=Cuwt��g�@S=��H4��-{4��)Խ�Ǡ�����84�3^�e_t?t����g �$=�����z�#��Q>�d���Dv�9���)Z%u���0ҧ�Ꮌ��]��T8r�t�g���]<�q�j!�3u!ɳ�GVec���c������g<��z<�yz��g"��z��}<E�t�e�{���C	�"=��-�S]O)�%z��z:�^�U���3I�г����^�gSb����`.�z.��z�뙏g���g�^��C�2<kt��z��,׫�[��[��x	�z�#o䗑�Q/óI�;n���YW�ڢ���`%UܪU�J���P���ۮW�ڡW�\�ɷS���8w�5��ɬ%�n���.�Z��J�ǵWo�6�ڧ7�گ7�\�qЛq�[���J���
-l�wXos}�����Q���1��w;�w;�U�Nb'�.b��J�E��M�Vi����{ܲ��c�*|��^׷����Ứ����.Q�|��A�w��;��>���໦U�#��룮��j���wC���M}2tO��V-N��>-r�W�!�}�]}��>�6�����y������a콃������w��{��������dْ#��(ck��Q<[�e��(ΤX�Ľ$r�cO�{#z/D'A$H� �@��AD!@� @t `��ٗ��3���y�gϞ�����5�_k�ǈ�c���9N�}����w�s[�g�e�D!A�;�(�r{�1I܃&Y��A@�"@�*B�k�돡O��OO g�_�L1F�PE��蛝q���8IDM��K�9'&@�+&҄�%I?���$���d�K��1�B1r��&Q��!��З�иY&4�b&4eb�k�eCU.fCU!�@��I<չ�Q%��B���O��u���rI����QK�0�H�Ky��L�X}�X.�E�P6��`�X6�����(��T4	��%�l���b�&6"�+bxUl���5�"x]l;�K���)�HX��v�W�n�*xKlo���;�u���o�=�M��	��]��|(��������x|*����x|.��������/���+�	8(>��>���'�|P�G���8 �_���+��8��8N�����!�G�iq|/��3���U�	hfŷ�q���y�� N#�E�^|yDmg �����,�5�[� yD�� o����<�m�X\@�;�"�+.�{�2�/�HTIV�C�#x$�IT=��q�"~c�M0V��m0^�&H;`��&I{`���H`�t�IG`�tfH'`��̒b�˖b�)<'Ń�R�'%��RX %��S��NR*X�"IiЗJ�`���K�`��VJ�`��VK猿�j$!��_�<�V��#Ô�f+įz�l���F�l�J�f�� ���
-�E�/IU`�T^�j�6�<xE��B������ȫe"~Uj@�ۥF]��פf�����E�CjoH���R+�)]��6�[�ޒ����v��t�+]�I`�t�/�{�N���>���G�-�t|"��Jw�>��L��K��~�|!= ���K��JzJO�!�)�Z���g������1��F ǥ����
-|+���8%�Fּ���ii|/��3�8+�?H��9'M���[�Y� M�c���$��~Y�W���4~�f�5�BX���s��}���QS��0�c[Zą��nۑ��]iܓV�}�#�Hk�s��HZ��X� O�O��6!���X�6g��w��.�h����`�� L1���#0�x�O��0�#��c�lc�l`9�x�1�\c"�g��|�_n��p�И$��Ș�Dm1�@.5��s�1MF�t�hM��ʘ]�1�1f���`�1G&>�s�c�h���`��P��CW�Rºd,³Z�Ÿv�XM��>er���h(�d�֨
-������߼j��Jx�4V�]�Ⱥ��▱�m<�c-x�=c�#Pc=�^cOc�?46���M�cc3��x|j��[�g�K�sc+��7^_۠0^_�B�
-���y���xW����c8j���c �ƛ��A����߂� O��!O�oA�14ކ��P�x��.� b�h�y	����y�x�*��uB��ΰ�\\7�?�u����}(?��U�'�Sy��B�CT���d<��eI��G/dn���R��W��A<�q��1A�Zf�p��l#��Q=�1���7��2O��[ݙԝ)�V��QlZ�c��2m:��nט	���}#�
-�'�qF�g߱#�L ��W�㬌���М�����- ��"'/B����c�lr����Uȉ�*�$���֠J�נJ�׹�hR�h��O2_ ؄*]ބ*C�ҳa�Ly�,�3O�4��49�.�TyO��`f��tfW��=��/Q��1|�b��1|�'z�}��H�~��X�1�7bcMV"ǚDV*Ǚ��xӏ�L6|�}<��r�I�b%B]!��m����m�d(�d!:�j9����P��E�By^N�j�t�N�0��g�G����r�F9rL�~4ɹ`��g�)�G`�u?ˇ�r��B(Q�~��KrOI1�j����,���J᭍RR
-��짔�C}U~(��]�0���J�}M��r5��r��,�ϛЇʵ�o�u�;e�v�4��i�{K��m�~���]��'��Gn�|_nF�����@�>�[�G�%��
->�/�O�6�O�>�����v�_���^��ڀ||)߃��yP�<$�_�7��W!���Qy���7r/8.�����M����!O���;�������f���/���E����ɝ��e���]�݂\���(wC^�o����W�;&�#w���=pM����&���'��)?��G���,?w�������}�9x �����H �����
-�"�1�!0���3��0�4
-&���$��I6[H6M@�bz��H5MBN3M��w`�i�4��L3`�i��g��>�rM�93obT/�"璉��e��o.t�G�c6�gZÓ�M�\�M�i�B�'��N��	k-2	��	m1��+1m!���m���,7� .�����#��a���<�C����co�Nt�~)��X��ř�	�7S+�`� ʹ�d��J�WS�<��5�d��켩-k�)r�i�Poz	6�R�߳FS��=k2U"�ͦ43�J7�Gg�d��)KW�Ь�4���y,rp�O{����BsٔkY��j�S��,�j�Z�nʇ|�T ^7�&��&��&��NS	�e*��nS1x�Du�����S�caS)x�T������
-��T	>0U�M��#S��t|b�����>S=��� >75�wL��f�&G��>�l�_0�B�E3/�Fy"�L-���8nj'L����6����4]5��`��z9���n�?`�&v�R������r�/�]���::�|��j�i���f�Z����z�Y���,��M�I�nq���y��ׅ��6�=��C�H�x�� �<�}�����0�b��!������ef�����r3�.V���iev�``��>x�2?�=7��vl`��m��j��x�y�x�5�Z>FWcޥ�6旸�`~�ˍ�A�M�!�����s�1�0�����e�/��P�Q�ӝ7�H��L��[�ڤ�L��;�*q�L���6�"tż �*h`��w�fD?c��7C�e1�&�A����ۼ
-�h@�A�bkހ|� ��ɻo�!�4ϒ}�U$�O��/}0��͙�@a^wx�.�i9y���2Bxj^�%��W�f�g�Uh��?r{Y��߼�󺙾t�̀y���O�(7�yeބfмyȼ�6F���;��y5�c�s4�3ӜzܼO�n�9�[�Y���2������|o�Θc�͚c��8ET�>���D�e+f{<?���H��X�0x_5���?�S ��S�us�aN?�3�Ms&�e������)��5�shg;��U(���Y���
-�����qgٞ��7� �Cs)xd.�������V����jV���ʟ�E��G	-պS�;����y�;֤Ԃ�JxA���"�kQ _�^*��/�߱6�	��4+�q�
-�Q�������5�1�3֥�VX���n+B+�xG����C֣����#�@�n��Q�1{��W�'#Re���q�َП)�x�s��~��\�< �f�<�rTn�CJ'�Z���npD��*�S�o�4AT��pW�R��xq� �w�}^����\��{�n�Q��(Op���ټ"<E��>$�_�1E��%K� ����a�L��GH��h���l�q���?�B}� �<�9���w�?g�B/g^s�Ü#?E�8�|}Rh� E�1�}o8������b-��X&�R�[��2I��X��M!��;� ���`�-�4�='E�e��O�cg��E�t��D�߰G����yd�c�<J�e�k9��|,�+����}�5�u�7�O��\��������A�Zv�>��̲>����C�����/-'d � _����_�ז/��%�b`#��F-���@L�-q��-��(����K"8eI�Y��iK
-�ޒ
-�X��YK:���W<ʿcK9���2-�,�l���\\����zk!w~��~�[����?Y��MPd[��۠�>[
-!�"۵A�1��C> Evh)�|���R
-��K�k�Xk9�8Pd��
-�	 �k�J�I ��*�)��R�Ոb��L��3��`��̲փ��0����6���f0�z��Wb�w[�E���
-����"�VC<�Y/���V��*��c����e��de�%<wY-m�O���b��*����*�k�v���b�b��`oZ;�N�A�Z��q�z�c��Z��{�n��z�oE]P�ѥXQDk
-
-����M*
-�j�k������\��}�U�^2�p�����3���ɍ�@��;�䭏���V����^�#*Y��X��<�>�g�<9���O6�0V:�16q �=���BQ�����Wڰ�.�F�5�?��x� .'؆ '���l�!'�"K�CNE�f���,�6
-9��� g�0b���l�`�m�ё��B. 1�MB.1��MA.EVj{�Y�mr��=X	���6��6��>��A���� ׁ���!7��FPdM�E�͠�.ؖ _E�b[�|	Y�m�eC+�*�+��dE�5���ʶNVbheۀ|����	r'���mr�m�e�o�Z�>C�bheہ���mv�k��������|l;�؎������|f���m�ł��8��-�%�/m��+[8hK�l)V4o �7[*�͛-���͖yل-�[Pd��L�S ��,�Ӡ��۲!π"���@� �l�v�<(�[.�E[�d��m���\��m�Vњ+�T;+��������(�RCX�Yn�v�����*^����u �e��b�`�AH9���9{-�k����`���D���`�ng��
-1T��&�G)B3b7$Ith�*`����^ኝ�
-�f���x�5�E�:��@���� w�({+�nCk�eȷA����]��(��U��A4��v�@�=�_���c�u�O@�=�w@�E��~�sPd���T��N*{������~���~���~|m���#�p�~���o��q�C�_)Afg��|�e�a�n|�罷?��f�O ς"�`�{��}V���gT���T��_�5v{?<��_�� �r� �O������l�>�3���>yٞ�5�۷��\F�6���X�C�����01�1�$T��lR5z{k����&a1y�)X�y�:�;�}��0���8���R�{\�X������a�q��Bჵ�a���9j���F��or,��c	��X�]M�2�u�J��U~�Gn�k�����/;�q�cw^q|�:6�vY�5ǯz���0l����)��ئ$�:~�3"�����n9v ��c�]���{@4>�}2>��8 �a|�C2>��8"�a|�c2>��8!������^:��W��:b!�h|q��A4>�xȣ G�Ƒ�;��	c+G2�IPdS���@�M;R!�w��3��**-��n[q��6����"��e�^�NVe�96tH��\�H�!�UG��ȇ��D�7@����ƃ*MG.l9h�ܶ���}v�ֹm��u�ֹ=m��w��h`���G �aG)����8� �8� �:�!ǁ膝�@t��J�I �a'��K�;��Z��
-�t'�#�p���Lg��-g���q9�yA�8km|]��s�:�r�����<gT��F�^�l����9�b���%Nz�X�H�����z���U:/A�EV�l�\���2�u��u�+`��*��l���&�u���^p� /:o�-�N�luv�����6�m���x�ylw��9{����`������~`{�=D�����[ j��1�;�'�]ݱ�)n�q������^�s���|�|>r������ult��%}9x�*���Գ}�~���+hB�쯉�U���Y��b��=猤7X�"8�m�������+������4jC�̝7�3g����Ir��=]3Cǌ^��Q3zlf��e"��Zr���sΦ�+?����1�Yu�Sep.�k�E��%�J��cù����\���\�k�G��r~ąm����u��~�87pa��	�s�wn闷�����ˇ�Ϻj�#�T��]]�Չs�/�}�1��/�C0�uD��u&�N�����β$W��,Kvł)�8;F�x0͕ ���W��J�\)`�+�q���\�`�+�se���,����r쿭t�F�������5$~��\��r��;V��|�*]��*W.X��e5�����*C�˖g���Ρ&׻h���U6�*�&W��7�Z����F��U�%W>���j�沫�.Z;Q\�Rj���E�[�j�;]���Nk	����E[1�]�����\����k��.�Uw�5E�']o���q�8���iˤ�v�=r����.����5O�$]�߮�Eɞ�h#�s����a��=�.ڳ��E[_�hK� �������\��y�E�G\�Ќ�]�c�����]��.ڍ:�ݨo]��u�E�\�\��띋v{M�h'�{턚q��Y����s.�*9�F.�a��*�ؒ�\v�``��>�h�����5Pd�.Z!�p�
-�'��n�h%v�E���.Z��������h5u�E+���I���)ڜᚅ����hY��E��_\K�c�%ȱ�
-�8Sp��Sp��I1W+ �������mY�z���2�9<1Y�Z	�9��ΩUd�j5Y�ZCV��'+Wk�P��\�փ�j4% �Ej��L}K���F\�Pk��T� W��S�Z��b5*���Wi\�J;��T��V�6�No��U��[��V�T�ZT�I�T�I��EԘ�*՛6�Ŏ��*`����V�.ۻU��o�m��M�
-�N�*bѥ��=J���Z������NG�h�tW����ƛ�G��ۚZ���h�W�F�{���c��@�����v��ޱ�7{���}�]��z�����s�^<��=<4�A�B~�v�����vܾT��H;n_�_7���U�<����k������Vؿ��Q��D5cT}�uS�wL��7*��W!W&�y�>�pA��i����:�;��l�է��^�g�g�y��=�j����)
-c�ϲ�9<-�����\V��%����l�lZW�ʦA8�M��~d�����:t�y�<�ԯg~d�*�@�R_ۿn��Q������i&��L�WG�/ژ|�
-�A��Q����G��i#�:f����D�#jb��o�nO���$*�F���#E��L�_`I{K��杤�E�<�E�w��06�����5g�_�m�k�ye^�6K�����m��m��m�j��H5R[��-S��V���V�Fj�Fjk`���D�%j����G��oc}̱�5�\��sm�s�s��3��.�?�W�ޚu?o�1�6~9�U��o�=�U��oq8���.�QD�9bS���8]���]����$]�������TT���h�y~@u���4�{��9��3���&P��k��3����0�&-�!�f-݁>X� /j�`��^�����`(�0�D���!�9z�8*��v�O�r)b���[,�
-9����\.�,	3P��r�
-������q�{D�vQ���:��u����C��=7�z���zSk��N�����B�F}w����^7��-�~nk������.BsWk�|O��t�h����F�n{�Vhh���Z�H�>֮�O�v�v�Ӯ�ϴ�v��n�/�Np@�_j��+�8����;�k�.8��G�pT��i���8�='�G�[�18�=����;��֞�����Fo�g�~����6 �k/�����K����W�apU?j���6�ko�m��M���[pK���)���Ѧ�]��.Ź�3��m�|���ڑ�<���m��-�1�E0����ʸ�ݖ%�"]��I�n0�����Z4����Mu��47�"Mw�����M��n�n�v���9�u�νM.(�<�'�%n�&tE�M�ݣ�_W��W�rl;ɟ;�r�����9hk�>��|��3�#���xB�D���+�I�7�3�3�Iƞ����ƞ�;ɺ��;�p�}��F�]H'��.d���.d���ȍw��&:�r��9rSB.���y��B>�����8�BrsB�����s%�;�RrKB���6V�˝?��U�+��M�ʟ#}Ϫ�U��j��U���"�q�8�n�;�ַ�պ���ju����u�]ﮇ� ���������ӏ�ɭ�kv7�h�f��[��f�q�}�I_0�]�u�K����.������V\�쾬����m�+?o�������U'ߓٮ{�F�0Y��CW�Н��Ӊ0�����	/��]γ����p�o�o���;`����t��B������v���w�����^����~�w?{ݏy�@~�~
->t����������w?����s �g��s�+��=��8�~�t���#�{r����o�a�88��m�4�y޸m��G ougRw�t��L��{'�3N����y�Y?����p�������EpҽN����)�p�x�{7O�?��{�8�^?�7�9�'p޽	.���E�6���.�w��.���?���5���}n���-�1��>?���;�� w,�����;<r'�De��۔�eлF�V��d�I�@4�C�U��ک��@�~�M�����H�`�⢶!LsaFO2839�\��,�	��$œ�(�z΁i�\0ݓfx��LO��)�=E.������C��)���)���)<W�BO9�"OX�K<U`��,�Ԁ���SVz꠩�ԃ՞�����4���f��s��\<-`����iu!'�1�.C��i/y� Ov�#a�ϼ���x��:��v^�0L񰛐���a��Vv���-�]�.W�緻]��F��m��w8�r��������8r>�|��.?u�n�>����-�3��m�{�s?�����Cs������f��k��p�K�������W\3�C� 4�<CȎǞ��<�C~��<��3��������/<���-��3	��L���w��g|�y{f��,8�� �y��7�ypܳ Nx���%pҳNyV�w�Up����Y�<��g\�|=�(�uA�r�x�m�����g����<{ງNmx���'�>4��p�sn{���Ϡ�v<ǐwA��yN �";�|�|����(�X�!�/�X0���ʦ ī�^)A�mS��$�z�7L��P��Z�5��w�7M��Ι��A�L賽Yj�j�9j�!�{�.=2�\��.O�7 ��?�Tj�
-��HEU���K�%���-QEV�-U�],����"o�z�{��oX�˼U`����ր���`�����ց5�z��1j��vQ�Ռz/�f4xi��� ?M�F��ۤ6�ʡ����<�Uj`Z�n�%��
-��^�x����+����*��m�{������o�����j���P��M�;��ۉ[�{��~o7��{��_z�wU�`��[X�C�_�Q�ƪ>i�������ao���$|�F�t�K�_c^Z�z�}��~Za�K�V��>TO�s���q�I�#��kS^���;�c���k�^���{��>(H�Og�t�t�Kkk���6���^:���3��^:���e�SdǊ�ֈV��^��KkDk^ڹ���Cox���'�sp��ny_����������]�@�(��/�U���{��ti��{_!�N��t1���_�����.&�^��)>6�V�D�4��.�Ǆt߯�rs��l
-��/+d� g��پw�s|�s>��\ez���i����`
-|��B}E��G_Q(��WJ|���R}i��G_`(��*|��+}�y�*��j}�Ʒ�����P�W�r���!�z�2z��-���}�SM>:��죂�ࣂ��D�����K�w`�oZV�d��c�)[R0��gT~�fVw>��u���o���[I���'�$�۷�.�J��Ti���dI��+�U�(��nQ���Q��5�b���RW����'�7U}S,�}�G���s��oK�����}�o�����#ߎ��L�c�i~���ґ�>:���#��|t�﹏����������K��~��S�~�`�GK�C�}��k߁�ZW�Ѻ���P՗�l�GWc>Z]���q��O�hu���H���l���M�h���G��i��OA�9�}'hg|_����l����/V������hA~��}�R|ԥ.���ʿ�ʿ�K@+>Z�_����G�ݯ�h�~�GF���O>Z����
-���V�}dV�}����u�]_��u➏� ��������G�ˡ/Y���#}���GK�'>��%�?-l��S�DQ3�f(ޟ�}�XE�?M�z�=�O�O���$��A�?)K�gh߱4��c���C�~z���7Y�L��C2�~j�r�Y�YvΟ��s�<?�f����?�`(���"?-���i��T�J�T���Ԑ��ir��^NT�����S3W�υ�xޟ���)��S�X���_ }��l����b���^i\��h_���'������㨗�t���O�Z���X�U?km�ӱ�k~:�z�Og�;�tv��������ih(3B���wU�ܭ��6�8�5��5M9�#wo�k5Z��|�_;��Gf��7 *���`��	��o{�����C�V�)����K�Uc���4�y ._��a���׸�FgM���S?���x�3������w�/�]���|�����w4����~����7��E0c�{���������"�{���v���m��Kq/@w�7>����4^G<^��G�y�LO+2�Bl���'�Z�� ��� �˄ Յ� Յ� }�$9@�"I	<E��sƳ,-@���m�:F��!aV����:���8�`��q.P��LQ�&ZK�4��!�a�`/�M�0����>��^�(k�d��!-QP�Z`��!M�F`�$��� �h�4��6��¨���1�6�ѝqx-0۸����?hR�<�;�4�3�i����f��Y�홦|��q���F`��,P�Z�E=�%\�,�JW`Y�/�@�X��V`U������m`��6��_؀�n`�{�Ou�����4��5~�l�ro�3��4;�<�r�4�{�<�S�'�z#x�;G�Oo`�z��4p��<��}���,�E��UvtI�;�J�7�B�=S �-��@���_��@"8H_���@
-8HGi�X |� ���D |�'9�T��.�N����|p&P �
-��"p.P�J�[�C�KM��V�>˖常�p���z�*��͗�ݼ9��<�Y�Y�� ���F��a^�����n��ؤ�F���T��ܹ���-n�ۗt]+�m;@&�9p���,e�[�n��M;;h�B`���+p���v���򸓅q9PY���h�Wgp5&8����kn������?��=J��܇���]u UR� ���M�O�b`)�C�R��z"��JA��rSsHF�$#�v���LV�L&;xٟ���5���d�A��� YCa���(x,�K����`X��{�i��d`UA���:���l`�A�C�G���d�O���S�W������s�)�w�:tkP쇷��`�N,�G��'A� TW�P]���b,|�:��Cp�m@pr'�Z|�D}C���G �Q����{@���!N��7���8�08>
-�'�0�Ka��<�7���0���{ݙѝY7?��`�M}�<��\��^�f	���4/���Ӂ� �+d�Vq������:��M�O��pp���:y��P�7�~��z�7�M�ƃ[��mh&��м~vS���dp�� mLܥ�ܣ�ܧ�<��<��<��<��<�_��`�3�`,��W���j0�LׂI�z0�������f0�
-�����s0�	f���lp/��ρ�\�0����`x,��<�r5-�ӒX��V��ȥV�AI����rܓ� �B�`r��.^5՞��/�x�Wm�S��!u����J#}L�5y0�5y0�5#���0+t���9�K�P+X�������8t,	����k`Y�:X� +B7���M�*�	V����P��w����܂[�6�:�w��ý��=��p{�6���n/B�z ^=[B��K��`k(]�k��R�x�h�R�Y��>�|=!u%�CǾBtB�=Dg�����Cɴ{�+dx��n�������0��^z���+����z'4����t��I�Ay��:Ⰷז�?I#��04
->
-���Co�'�q(��9Cl��[�n!�߈�mԨ��c��:4����ph���!��f��Yȣ!���>x��
-�sx�Dh|Z 'C��{������c`B�e��
-�#�����Bk�|h\m���OT�B�����̖5l���C[0�ϡm�;���nh����=� ���n��n���n���n�N�C�/a���������V�Xj8L���J�l<]��D8I^���=R��fw�^̜�i^^��#+L�:���*��p��#?΅s���#7���_Oa����pX.��E`q�,	����R�,\�����pX���U`u�*����!����z�r]8�+*}������A伞�Z/�� �y�®z�rh1P��^����5��܅0%�"OnK��y)L	lS�.�)5m<�Wx���t��\7����^�Ff�c�j�G?�]��T���Y-�s+|	����;aZ����{aZ��	�J��0�t��i��A�V:�����&Ó�V�eD�i��Wd}�6/-�]�ҟy�X�Y8�"��a��i.�"Ls��0�E^�i.�*Ls��0�E��4�~�i�p��ތ��W�a���X��o�4��Le"�܆i�2���T�f*��4S���އ�3Y3a�L�l�>��!������¦�^�b���5��(�����.�o���N/�ߠ�}�.�P�¬����f�Д����p�A�6x΅v����,�&*��E��/N�՝{����[a��N��<Я=ԝG��Xw���S����v�g^ڎ��K�[b?9v�vj�Fh7a\�6�Gh7aB��r'F�,wR��r'G�,wJ��r�F�,wZ��r�G�,wF�vfFh�aV�vfGh�aN��r���Y���ϋ����a/�����a/�����a/������yI�-R�F�Ye�շH4ՠ�j"�^�����G��XcD���k/���0��R�m�)��ߊ�آ�7�y��B��Ƽ|���8�Oí	/�]y륱Ӥ^5�t��L��{ݙѝY8�����f�����Z�jY@�h�,ꥴD�9�UkdYW�P���@�Y�J�H�:�F�:�N�:�A�:�	�l�7"[���6��vEv���.U��U��>x'r ލ��"G`O��9{#_���h�4��6a�)ȼ��%��'H��	�����V;����H2�I�e/"��"i>Q�F���t���l<"d��D$�7�)�6aY>�Aێو!ۇ�-��{g"���|�咻�pm)�.G
-��H!�W�ی����)��l#R��?EJ���T�+�#e��)���l/�`��[EL��a.&�V��w�G�5a����V�����o�~d����I�������j|�]�u��NQ��GK�bu>����%������QԶgD5�Te�X���G�m�l��@��O���w�\Բ�{�uѧ��;��
-MA��B�{V�k<ˊ��gYI�um�2� ʣ.�Q����V%\Fޟ�*��wu'*����
-�UU�v���Bw��Nj��6G�/Du������n�R�-�5�6x9��u�u���ͅ>�!���}���g��W��>��-�t��<���ڣ�_}�B������S���w�3�aQ�}��Y殨��_+;��EI}<�g>�w��Nߌ�����=�����6��z s�b/ b��P�G�z��K��cLt��W���Ax:1�wQlȗ�U��L1���#���65��/D���Q��R���\�W�&��Qo���Ip=��J(V�|�Qg�!��>�^wf��՝�rN�5�;�rQ���;˺��s~t9ď��������Ta�6��D���n��E�Z�~�'�� j<�������(Zg>���K���F�q��`|�<�?��|�$���6��9)26%�ԉ�k�1~����e�)�GIBWmH<=����}%Ydy�j���=��6��،�=ˏ�u�
-��Yat".�
-,�}�E����i`It:X��E'�Qq������2:��N����q~%Ud�ёz��������<Ǚ˙Ǚ�Y�Y�ǷHO���e�[�b]t2X�h�e��Y�}���bD�9��]
-^�.[��������
-�g��hM��\���h��u%�vw]���Su��(�mӫ�m�.��O����9ףk���:�Ft=x3�V�;���F�;�v;݊n�|;��/*�"{���[g��i�ゟ�"��;-�s�Of+�e?_���=���R_�U��,�6�<�n��}|}����r0���ٷ��E7����L��\�MDo�;�|����K�޷�4֝��F�"��f���-�F��w���Pd��.|�l9Z����4t��Gw��"��|��_��og��ȈbLϢ����#��~ڟ��[��J��O!oD�!i�x�7��Aފ.����D����_w^�ݰ�o؋�{�2�F����<K_�GrR�uM��8zmZ��b�؆���z��~^kGn�Q0����pfL<C����L@N>�L93	���B~U�:�1��ϣ`XJ�[��rϜ���N�OyOYb�g���>�dN�5�3m�s�O�|�s�s��*�G�O+���׸n]/��mޙO�ZD�?C��g6��3�n��ق\|f,9�,=���٥�-dV����3��Yu�8��Pݲ�'����W�������!C�7�Zt��)����>���	3�}�lP\�_U<�˒��G~���/ˊU<��&8_�����"&�/�0���������L8�T鹐P��Bb��~Β�N�Z��s�`Nڼ`./K05�^�0NF�bd�3ٚ�}2��F0# �A��`��YV�I?g�f�9�	0���U�4�3�ޑ`�+M���C<�L/L�I��]3�9�� ���3��`N6_o��&�3�TH���
-EY��ᷙ��Y�Y,��n���������#����2� ��tߜW�@2�l�l����U����o���&~1��X�R�����<��Z$)F�C~�����44c��ƀfJ ��D�)�)I�ے�44k
-趥*�=My�������P&\�+Sy�R�,�b@ղ�)���Q޹T�9eڥzs��.՗�̸T�2�R��,T�\j�H�w��be��FJ�E�U�,���2e٥�)WV\�/T(�.�l���R��R�+B/�z�u(��v	�rCiE�n*�aX��=�6d��+��
-��W9ͬGʩ\����Oao���K��5���d���2�VR1��ݲrO\Qʍ�qU�P�Jg@5�)]����j^W6�_�zӭ �7�mJ���wQ ���@�u0J�~�-n)������9���>+����<F�{ʓ���+O��@���C�Y@�)�QR�J@u�(/��2P]1��U���BI�Yzܪ;�2P=	����M��{T_��5jm�(S�ɖ��H���`�%�²,��m�r-�'�!C-�	�Y��|�D@6J���2�6�d@6I>!�"�u�*{�\�i�e��=���R�o����z���I7� ����Ҳ�֤*�m��,�5�t��[N��t+u�U�f���˚[�5�n{�eí9�A��eӭ�.�n�Ų�ִK���j�qk�ˠ��f���+�d�U�"2�ݒ�Q��,�5t�r�rj+K�g��-#�!���ܲ�6��S���r��'ܳ�kd��>a�.5�����|����M��2da߮l�M˂��k��U۰�B��x��4�v�������������/�t~��(���Q@6����CX<	Ȗ"◀l�!J�	ʶ��ؠl���?����&S	A�%a"�d��%5�ԚtKe�� ��Ԕ sS[d8iA�XnM��
-kzP3U�ns�5#�*��Z+k���if�|���Ț>���}=�	-V!'H)�le��������>��N^PY���ZT�O��AU~j-
-��>kqP5?�nU�uۨZ�������uǨ���F��ҺgT���F�9h=0��!�QU_[���6l=6���Q��Z�U�5FV}o�o�Ư*A&��Af�[1�Ҕu�;���Z���2J0&a�`L�*(��|�b��w�*���Nu��pj�L�%v>������Z�X�����e�,_�6 �7�[V��g�η��@E Q�)�>�E`�'YY��m�~�ǋ��&��P��%�N+"�3vA?݆���]	2���� SD�d�ՠ ���� ���@�|��@m�n���l�(�m[�賭E�c��ص���=۝�jݷ���۽�j?��UǑ�~Pu�z����� ��_l��cTݱ��A�gT����A՗`���D���H�?��d{P�����RdW��/�T���Xl@\K�/�R�+ĵ�>����s�����+�J�=�TeB\����0�z�>����G�:��Zo��6؛��8JEd-���u��s��T�'MRQ���� �J��.�Ƶ�/LѸ��mv�ng�v�=/�i;[���t񴿚Af��g��/�H@�c	�u�#q�dv�c���Hv�v�K�����y�Ya�����#�%�#ŷ�/;X�㴽_�U�Yq]6qi��~BR\߉�H��{��������M���=��mz&T�)Sn��ʔN��K����lΡ�1Β�}��(�Vm��jcG�T;����� l9&$�E�1���B��e�!U�w$�Ti��R�����*/9�C�iّbVK1���;Y��=u�F���tԜ��Φ��8�e!&XfH���'���f ��K�W3���A�WS�@��sիZ����mĹ�U����s~��7�M��wnyUuR�����tN;O�1��k���A!������$,|���-�NSS�M��r~�)�!�P@A���J���J��Jӭ�LS�R���/��dEz��C�E��!�*���ʐl��BUH�KK~�:$;��PBW��/\s�Æ�<=z�/�ң?��:z4�D7\B=
-嶺Q��l�.���������vOu�?6�s0�j������4��(f�᷻�Iu�-o��]��'ߞ4�M��M\�&&j��E���>�B��X���5ږX��Z�4�F�6^�N�u�,�(���6�0c��X��e�Y����O������Z�S��cn�同����
-�#! \E�P�ڑ�_�P�?��x�����7K�X:p��nP
-2�M�3+ tR���.*�!M�ƽ�$�½�(ަ�������3�.�D����am��Du꡴H�}��ū�W�?��u�5�ᑮ��;<��I|������S��>$�Y�ޑKp�Q�;=��r��E��Y!&l�s��'�=ʹ����/���=��W��4o*{�w�fx�y�E�i=����u2È�%�|�zG��\����i�	��+��\�N�TK��mH�^�N�T�u�TH�wx߅T��tHuvz�=�	�S��7�{<��fB4S������;�<�#�!���},�ە9\�9�����X�����o�m�i'�J� �T>?��[�ܵX���F�b&[Ey���?����?�ȼ�vm�:�A!�^�#����[�Y5N�?!/�����w�-��y���y9��2��Y���y9��C^�?�	tTǕ0��m�E��~�����D	xK��q6�	Yz�I'3­V�ӓ1�'d�!���o��dۘ}��u#�}5�bc���{o�ׯ%�dΙ���������[��[��n�;Yt��TѵR��t�g�^�A��-���\эRo���t���BQ����b�`�����:�����!~�ц�q��QQ������0�W�\t�.Cm1�w 2�<��O�����x�c#�0��lZ�4�I�b6
-�F��yLj-f3m�/�����+�¢b�5��h�eI��W^Z|��PlO"~��Kvh�M%��+%��m-�t�q �s���J`vR*/�w[ �/��+]\*,+�-�\c{ח
-0$a������|я��	~��,�W*)��f��F���M���W�&�A�(f�� x�)~�����~��K윍:��~��3�jΗ΄��P:��U.���{��K?*��~�
-����B�<��P�~h��~a�_�����w��&�H'm�y��_��>��́���z���d}���_H��΅�:�yP�`�4J̓^���P�`��
-$s3�
-$�B?��ʥE~Xۉҫ~X��--���N�^���.(-�yU�R��4���թ�s4�u�Tǝ���#N6O˰�����M�8��h��N^[l��Q�A'����)�m����;P���r�7�M۫	m�#�pBNk�EM��	��)�z�;D��
-�"�SD���D���>0Id��L�0=S��:���A�!%l-����s�aU��A`�ڀ �K�F�)mRY�6c�Z�c[�G�.a�m����,]xI���Q����ȄN�4W��̗��o٬l�|^(a;0�K�Ņ����g*�be� k�����J����^[cS݈(����*#�=#�qBܨ�r`���7�IA!��)��1ع�c>u��]w[X��0Z�����T���=ж;��ж;�}ж���ж	� ����{I�Uo�T�!�زt;�$��].Ŏ}�t;�*ǎ��Î}�t;v/�$v�/K��cWJ��cE:�W�_��B����A�����UO�^�_�s��~��Oz߯��>����ja�A�_�����_-
-���~�8�u�c�Z|F�Z����_��)]�Z�[�U���-]����g~�{�;��~�,��tݯ���_������_
-~O���������zw�R��V(��`�Qi�����zM�'蕆ij��cR��~9�W����I�i�W������`Oi����X��}�?����{�?�Fk�}��Ic4��`X���F��.���_�B��_�����>��4AS���Ԩ��>.M��o-M��o��&k����HS4�;��JS5����I�4������k��@"������?�f���?�f����B�5ij�j��>5�����
-���?�y��$�|M�q�JzYS�MS�MS�/5kj8���PS�&�i�σ�ҫ���`TZ����^��_'-��_���j����Ԣ�������>�Koh�o��(�����^Z���'�-M��`����Vu�M�|ZZ��OH�jj$�i��V�(���h���JSk���5�wP�5��s��Ơ��4����55�ܠ��ͿQS��4�� r��>�z�� �������4��Я�k�3Яwh�?����'�׻4�Y��	M�3�k���_'5u�딦���nM��׭����m�����vM�w��{4�?�_�����~�OS���~M�o��4��A�>���T�!M�c�g�Ú:��Y:��CY�O�QM�g�g�c�:��,��(����Yp�tBS�c��H'5u��tJSG��J�5u��tFS�g���j�h�霦�a����k�X�/邦�c���.j�,Xˤ�5u<f���"�1�CM���C�tISYp(����[�}��ܺ�y���ǚW>���	]��gf�O t2��>҇2P#l��@��j��h 9W���HNPP^���l贈���*	���I�����&���6��U��k^u}`c�yC��JZ��J�N����*{ʥ:]U@g��*h�Cu5���u��)0L�ʛ���AW��N{�%a K�H�E��d��d`��UR����/ �1:�I����I��cubcg��������!~�V�îR6A�îR����R6򕏗�I��|��M���:E�%�[���o�����H�t$w��]�+p��P��YM�]x���
-��Q-��UrVJ�uA>���ۤ���s�ģ��%�}.�xl�y�W׽NT�4&����y�lp�|6���G��^G�%{��l789ϲ�d�1��gd����y�tMb��,����B�|��DY�[�X=�]�06ܮ�˗ϋ��[|S �;]a���f��Pe�`���-\��)�v�����B�
-[��9�)Y(��Î��B��I���Gr�|�̴�rX��0{��(��,t�`�\6���p�d[n�E�E������B�	����g��);أ���`c �s��M����l:���p��~y��-�r��-�+k�l1�_��d_���[��~Y��Ɋe����l��}��l�Sf��d[���]�6p�?_�b;���4��,<���B��]���\�b����:;.�cYx������wι�����.6�%ߝ�f}d�{���~��͚���|7�K~��f�B��W�l1���n��,<��ͺ�B��n�bt��V��}Y~|����O.��F����n�	ܟ]q����?s�����\�ܟ��˞��_��c�ܲ�yl2��|9���W�yl>��/�c/���y�oe�y�Y���<�b{*�m���籭����y�L��uam�?�k��绰}�F�va���~�;��Ytbv�5Ӻ����nfvܧ�ta�9b�]�q��]�Yp�owa�d����.C��S�����?�ݕ5���ӛ�2�,�֕U��we�!��ǻ�o��3'��V��D��,�������³�����-6����Fp����e��- �_�x�+���^��{��^��W{Y����˖�����l9��u���͓����@��]�m�0��R�X��퇘!�ɧ �P���P�~/��?�B{Z��y>6��sl��=��O�Q쏲0��gG!�<{>��PF�	��W�0�M�gB�X֞�ڡ����|�}����X�GƳ���";S���,La�B��~�2���ނ�I�m��̮�K��
-kI��il8,+a`Ngc�p��f�W`Z��P����7�2g1VP���>.d+��Į�]���҅,��ذn,	���nl7x���X+x泥����2{�;
-1ػ��)���.b����6�� ��T[�Elo[	�W٥"�<���"�<��t[�%l,����M*f[��¦���y��(f;���S�v��M6������-(f���[X�Z��6[\����;U�~"��yXÃ,}�}X̦�g�^�~*+���._f�؂�3YX���_������\ֲ�Rv0ֱ7K����M���l*�n`#aLlb�KYx6�եl'�oa�J�oda+�Zʞ��mlG)�	�Y��������Vv2��ރ�]�X);�;[
-�/���]O�]*e�uU�2�`?�7YH�*Z�i�Y~[�XȾ�-��v6~����lx��"�U��>v�Ϣ�����Y8�.��� p�}�g����g��s������虲p�5il,t�cl�ƒ p�m��6�`/�{l��jA�d	���Sl��F@�iv@c#���;���!�,{Oc��s����8�g4�x.�:��sT6<ﳴ��Y>`u:��z�5����9���=����s�M��<�|3<{��'l��^��?e�t��^a�u��2��j���,\c�u�p>c�t�<���:�	��]g��s���Y����%!�V|Og)�?��0�['��d����!i��|���S/���4L�`uE E�E6<�ŕ6<ω�ixF�Sr��&�G�{l
-4��� {�G�Gl9$�Oػ�+����'��U�yA�`� x�x5�&��E�F�키	���`�Q<�����l
- L7���I�1A�e9s}���){B�Oø+�m%�S˞`��k%z�Ĺ��	1>��e��gŲ'���+�����J��r|��e��i%��J�5���"�K+��T�cܯ,��Z�{ 1'�����|ݐ�d� ��V�`f%����3W�,�̢�>�u��c�pf!O� ��x��eSLmʤ��s�>���I��!� R��u"D���ya&y$w��c�L�L�|H���K3ɛ2YπdO<�63�$YJ��&J��I�I�HH�b"��$����t�G�O�+E�+
-�W��_-�{�_-����g�ZQ�ϊʻ�?+��9����^t�؟ů��A�E��E���x�����`������^�DqU-���W^)�W�����GZQWy��b`b�%Wן$���Wk�H]qc/�!2����G��Wu�,�+?+�+f�n����S$�>F��
-��z��� �pqE��b�!����+��򽢃P%��[�Od��Wklf��6#Y=��!:��v0Qv�~��SV�� �]B���mZӞL!�t�� $7뱅z�[��1��$�=F�U}��!�	/��a'S��=Z��\��*&"��P!�����s�v��[2�7$�J����%�+!����
-4_���`�5��=y�%��DE����GIU�s"��z"����#�p�Wd�_��J
-#�w���d�	��p��2/�
-��8��REH�&H@���Dl�,*�o�J"!��Epω���vA�t�s�Zbo�}�1�$��6�o���V"�H�,���{#��������h86�2DO�F�� �+���,����6"�f" 9�md�� ����󹡙������	D����7$��c+u/D? ^��?/�*�/.���A��X��Y��WSh'�EȮq�{DA�d@w���_A�z��&��Vdu����,n�߂��,��z�k��$�'����0��\�/��+�?I򚱓��I��:��J��FT�\���}��z]�Q��2�q�o?f�O�� ��<�������Y-�[����ވt�D:`!Ʉ�邒�L+�����2��}���(^�[G�]bY���=� �����\�Q��#B��0�P��<oT��M�W��^.� Y��=��n�\Uo�z��X��ϫ\�B��&%�
- ԯ����o���,�&w��$�r�=B�p7D�Ʊ@'��	Y�%,���sVVu`eU+'���J� �6#GDd�$5�}s�C5udመUE�2v�S_H�(�?m�?��ނ��/$�ȟ�����nA���H�+6��Ź�'�f5��ƛB�w����PU�W�E���KE���Iy 52�m��,a dQ4������[fG�y1k���-:ى,>'��<�r���;٤�|t�i�釷��dV��)�Kv�'���;f��-2=��鋔�e{����`?�5�_����F�����P���>!>b4�$#E�?"%��bf�E�D��+�"L�����yD�ꉜM�~M���de����Y��
-e�3��Yٟ��{�*��"f��C6k���zۡ��a���j���0�H΍e�>=�:`��l+#~A4�V=?�48�X'�ے7�.��糆���=�.�P�ݾP�w(�Ŭ�Q�>��B�o�������bV��ݪP�
-u��僬���7��
->��!j�bTO��q�ll�b#���% �Z1#���pE(f ."@]�E� u ��@7�<�auEC�����#6o�^�,�j'��!Rl��ч*Nk"6Jʴ�()��*质�ʺ�-�|����v)n�iS�>;L���X�y�OĻkŦ���3�lq ~��F[/����R2����i`+����6g��p��W���Q���{"wE���&�3�ͽ����e{g��&�;���d{���y�f\ 髼�;#�V��)���]��G��j+jdh��a)�Yo��@pn���:�m��P�H"��@������L���,Rр�QWpQ٨�\\+���mz��treW�u��y���4^eqC�*pKV��
-+�~��/g�E�ƺ\�1bFa����Y+�2�{�6V�U��$��r9/�AQ�;>v��Y*RO(F�`M	5 ʃ��,r҂l�ޮS�
-��4�_+=.Բ��k'�5�ǹZ|�� _��ۺU�ƹ,��8���;t��tT�R0�x��De0��8���$(��
-�X�x����W���z%��#A1�$J�k��9���4/�a��ޣ�����iL����h���:��A4R`o��?���b������3h��&fE��qS��8����!O�B8��� �`Z�)�n�A�Y g`�pfe�C��6�eh��� s�f:� �Kv�����1،�l�1X��ET���[�F˳�� �8#�p�M���u_.�*��FKq[���A��t:�;wR���D�[���p�ZdK��Zp�U����ņ�6���t�X@㺈X|A���6^���"���o Í��"�`�,�Bs�Y�Q�h [Hs�N�%��ZV����v\�6ry��M��惼����郓���|� xC=X�L�XK#VLh�I��w8y`���+Bss����Z��yB�y�H�PJ�a�!�AHF���4q���I�:���d	������&I���*U�X)S$��B6UZ$	�8����(2��Z_�-�zo�p$ǽ��8���}�� !�lF�\��n@|K���IɘC�}��5�!�cI������F-�L�RV�d�j�3���]l)��%����͈OEv>� a�F�P�O[�jr�m��8r  %�Z���g�g�˅��-l��LEy���*�o��Q}�aW�R�l@F�*T5�Ǻ�B�S�+i�Zjr&�%k ��Zx��� o���p�9���﬚����=�֋��7�[G|��AW����ؾ�fk:ݭS��E��l��M;�9��2;<�oe�:�Q�D�+�$%���eDY���2��k4#��,�fXI��a�nm�Yc�:�5%
-����6=֮S_jK�2$iAx$A(�Y@��*�\`B����ڈÂ��!G��j�<2�bH���$�%�`߲�\!nB.W����4G��ۣ��<_���E[�HkE��r�Q�ݫ���vb𪠜4J��|$�)��m6�]Ԙ��2hI7o�}:f�i�}��C;�&(e��A=�&u5"uDs�{T��C��U��l�j�*��ϑ�}'�v89�HK`��WP�[g��˻>�)[�)7� o ��,�7`��6g,C�-6������y����<�";\�%��	�Ӣ�;�ƽ��*0�M��˥ra1�t�&�_pb�rI��P^d�6 ]�g�%<c���3 v��J^c'���"���{�
-��D�W�<����S�!O�FY��<(�
-�Ӎ�\!�g�ݲ�y�]V`u�ɮB����k$l�5`P}�Th`D���k-)�gi�Im����C��m�КEw�Ew�ݑE��Fۄh�Yt7!�=6�؛��� �`�68`�@��Y ;���@/�����گ3o�
-��a�]wI�N����$��$�ۑ8�$��c��O	����`Iڃ��f${���h�^���B��}_�>Dߊ�'l�}6�>D?I��M��vH= f"׋p��&q�&q I��@�P�C&�D�M�M��8kWc;2|�:�=<�m7w����]Y��Ma/R�`S�kS�ۉB"��E��~��Ma�Ma'
-F��l��M�M�`'
-�,
-�l
-���GD��<|�����NDwg�l=�D?���Q��D�5��'D��ps��{<s
-�;@崟���:1U`������H�B�%��ȅdO6#��f�2~E�}�oa��6�3�L��D�t�ⓘW2|P��C:�ݖ�i� Z�H�� U�D�[bh���-"F�#�.�be�L ��a=��"��> ���P%_v���Ú|<(����A��h�LH�����j�p��z��:�����%Ļ �.��9Ԗqd\���H���CƏ�R&�����d��)�f1>����b�I��#�.2:d0$+�0����[+��%����z�T�$�J�d�>���i�2����>iT���X��$,`i6xL:���:���T2��6#ߒ.e��U�R�e�y�a|� #� >G�Q�?���Y@E�K�D�2�]f��0Ή�;��*g��
-w��Q����9�B����)*�;�'r�u���6#spu>��q����ü>ˉ�"NˆY7�Ѕ=�M`x���a6JM�4DN�^��i�����Dx�����@� �"<���x�j=R}Q�a�����m@�^�t&�F�d1i{�F��5d/핾����2F�f�� �2n�P4�Γ걺�Zþ 7������C��lV�J��Y���O���4'g5��9�� S�n��o��B�i�aF�|�b�2�y���������i��,��w�"n�I���2��}�>+}�϶�#@�d����̈́���2���A��(��v��Y>G�A�=B��������zyQP'*W�Q�����x��/��Yy���D�9P�����0JF`�U�܃ȭ"��!"� $i�D��\M9F�?���x	xK����u	���r=��dL �IƆ����T��%�]?"����:��u67�R�`�Σ��A%��%�ȰF�}�4���!TwRln�M��)�'9u|h}��,�=�l;�� �H���"^}�/������Sfv�Lv��eWL�%;fZٶY�%;f�2�w4cz�%�]ȓH����r\Z��hK$	2I�I�L�+�
-���Z����Nl����K�lI�f�Y�@�g��#�l���g���Qͣ��m+	�}�$�.���j�Z�3�b^�B3yYB��I;�kD2����(I�Ot��_�!�=�Z�!�8FM���n�^߫:�@ԛ �W��{���"���|�/[$6���0I��;���v7#���E�I����4L[J�A'��˲�mifH�^��������S�ZVJ�{�S_���Br�^z���#��a#�0���}_�H!���gMR�����Q�T�[7"{u�킸{A�ܫ3�5��@��0I�p�R0�z���'�Q�`i�bg����X����?C>���[�5�����1���aw��ۻ��d�0����,v�C�Z��7V�gVC��Ό�3-8�T=c���R9���|�X�O���z�=�Id*�t
-�W��0B���s����o�����U�<wsBfs��� �҂y�G��%��y��3#t����Eƈb�E��"|��Xbʷ��f	0�w�YK���$�=04�l��+�=��b� ��/�������Bd >���e�Ëd�`�<>Li��]���_���[}�h��N�^O���z�F���r���f�u�n��zd����:��c�lC�S�C]`=�K� �ׅ7$���ָoJ�u��ȀqBv<T���aW�e$p�T�M�G5R|dR$�KP(��?���Uj��H1�٪"�շ)� T�ޱ��|8�މpm1��1�80Wg�^����]<#��nN� �gI0���Y��D3Lq`��':�	��T��r�q- ]+c:�"����+�$�7e�,�#��J�B�UV+�F�QW#{�Q9�%�J$#=p��>Y�N��sZ!�y.��
-��֨�WYV_㸫�Ɖ;�.��X2�ku;.|Ľ���}i�=��<	:,�q@���6�:�J����"�!�,b��>A�:a�������ӂ�(4SZxJ�Q9B,��7�*ՋtH���Y�h������봁2ۣ9G�e���fD\jF��#�ȵ9ќ�Z�3��\�'�ڢܢ��/e���fΓ�oʹ��9g�_͠�N��	&�Ub�����\�3��&7��
-7����t1�%E�Mm��$ox�"�j�ß��9�ƕ��p���N�j�$�C�]ׅ�����FRP	�Ds~�����*IQݞ�.��52	��#p<�ʅN�uAT� �S쮺�<9���`��J��)�Dٗ r��J<di�B�TW'�����ؗ�4�0c������s�7C>k1��nM�X�9�x�E�T��s�J(�(��?:8��x�4��#�ր����9`��[g0��(;7��'�,�������H��?���Z�Ň�3����}�2�D5�is�x@���Pj�Ĉ}��&�iJ���0 @�ڙ{lH7�oO���\�g��Hq��W�����诪�L�p�ߢL?M���L��ge�)۫����:1��"ޝH�;t�[�'��tW_%�J�b�1�%���]�7tL���U]�Qr4;�ifpy:P�r\��vE����>ò�}�<�M�	��i|�@��S�����uA�OB�GT�P�GM�~Bpz�����nY�#B�$�
-xc8 te�jIv��O�.S�f�on��RT��
-�@�KU#=Z��xj��3�M*�MS�)�)Ki�b僫1�qа �t��)�P2��V�a�3шh�H�q�*Ws�{�!5G��3�u3gg���f
-��s�
-�K,Ki)� ��kG�JJ��Z�7�6�����-ߨ��@�"�([�L��N��&ߊ[���6�m,��"k��RN�{�h��h  �8��Ԇk\�6���v�r9#�H��Ea�p';�1�U��D�)��.zj�n[!��f��C4h��~䪪�|��JC�����~_V��[֑�uX��~�`)�2�QhZ�D�T����*�ZD��ۼ����Q�T���O�J��/�������s��8���r�g`��9r� AR�.�'�TМ��nW��OL�
-E������>Z�è| ,��B��ES�+\|�r�+|�~
-���h�hTt��فB�#�Y1@� i;|D�X�8ȼ�3dN�^�]!גh^]M)_e�FK���v�v�������VY����do$�kf�29���Zd��v��n�I��IW�qF��b���o�S���,;�2��}���.����h.1��w�-c!� ��=���׊<�.�d^d�a�����X�1g��n��F+gO YXSR.DKJ�L[�|���C��r��h�W.�!�U���e:Ք%�%�����U��s#�`:��Q2�E��NfDm�ը/2��֡��Bc���Q#�(������&��:��V����@�[�dF����4-�Ӊ�Gd.}��:�K���h��d��J�FsO�oP�W�m����;`�G��hS��.bI���ՠ��������u;�5VFk��	�ha��_:1m�`Tn���u~���zT.�3�l9	� �؛Ho�D�˽���ݬ����*�l�V=�j�=j�T�ݬ���R}�AW.b�,�܈[1�C���j��VК)�) �#��*�K:���R�M��/f%b�$�&Z\�P[|?��4BM�F��X�*��*�Od�( �Q��T`;�c�T�����6&�}*�N{~,� 
-�p?�$t�S��?�'���fQgh7cb����l��PܒD�ђ��+��A���}�F�F�!6j��s'��:YLzq�t~�Q��E7c�w���4�Ûd���d�~399�"����#K�tQ��wR�B/P���E'@�L���ړ�-#��"��:��\h������0�[��zh��.Yؚ%����9Y��X����?a�}U��"�~SD���|<�����M�޻��t8J�|��8�R�1�!��7�ͩ��qsN��p�ݰsڮ����A:vz� �?��B.r��'�E�S�UX�)	�����U[V�N�.�y��KĶ���FG�VpNhl�lͶws�&��h��(�Hv�L8"eۨ��p o�����`.�j��61�8弈W���6<ȹh�6��4�Iɦ�>�ٱ�c�pL�6s�	�0�rqV�Y��}�b;��y�6+�f�=Q�TJ�� �y8N��>�A��&��b#�0���ߐ��j���y.�m�-�Ҝ���D���̃QZv�§%�9E� d�^�"�d�NlΜ����z<�%�O�Dm�9��Od���&�;Q��q�>n\��}�I�^�'��S�P��H��bH�P�*z�F+vE��K�R�U1����z��T����+.!>L���0���o���^
-or�����7��mpS�C�_�귘���tg��ߠ�~w��~�������%��,�v�"�(�s�Q��H
-B�L+�<1β�����m��G�+({@FTγ�
-�V�dU��MV0'��8H�q8�Auz�F:}#�5��N�N�I��������Z��
-��tU�A�5���*2߆�]8e$��ўO'J�g*�g[+&a�)܋��E4I���� <���ޓ� .=V���[I��eZ���#d�:4l�$�3��*۳�g�ܳF����I�}�m�@6qATkʅ�&	�H��2>�ϋ4�A:a�R:Ȫo��|9��֛`p�ABhY�^�U2�[ 02H�Y1zw@��!s�dZ���l�0j���/�=[�u ; -6�d��u�)a�Em�ߙ-�:��P;�`w(q�]⦛K�d���J�S��?��������0�w�6K��D��ure`+ l6�d� ���X�1`' l+Z=�vI�cd`{
-��T��� ��"���f�vL�|�~;�	|����}N�d=]]y3u����~w�}��W�%�v���J����p���D�Oh�3�ٷ+�gM���M�)�v�7���6E��U�&��v��Qndϰ�X�>kjM�Ԋu���Ω�E}�d���4	� >�CuQ�AV�\��rN��U8^�3���n��e�3b�Ș�#��۔�@S���V��݁��w��xH`h�1vXJZ&���v��v�x#�������F�@۬�F֎ܑ��6kGoǚ�����Qɺ;����+9�b�P�qI��_᪫_+���;��*�e���@:��i��w�Q�_���n��rq�~w���x�z�(�? ���R5�5�ＩᥭV�� ��:(AE� b�{1�l���Z�D�iÀ�>��\������s��v����J�b�|W�%���yq�@ĹxS*�J1�����ll�޹����N� �uL�'�J��e|n��b���ѓ���	�I�j�m��^�Ȳ�3�O[Fǉʉb�5�2n��8h�ߨ�+����a��;k�M����x�n�w�ƛl�]��&�7��{�ƛr;�l��އ6����]��Yx�x�n�w�ƛn�}l�M��'���4�]�JR0-�H
-���rWt�Xc FE'�+���rO�aV��í�.e�.�ϖj<����o��@w�i�HIQ��Dax�Z|���o�	��-��h��"��.T�˅�ӌ"\�C���=m�=�+���x~��~.��E�d��
-��r����4��:3���g`c��3���T��@��32=�( E8���X��(0��	T���Y7%`d�B�������UFs�$pn
-Ȟ��\�pF ,���@Ѽh^���zz@��	X�J� ��şy�3?~9���}�n(�Hԃ�{eOe ������3	����53�%���`���c�m�[D��WI���C���u_�׳_������f_�bYE{׉��b����~1�A�hO��=�	��k��P⎿z�u!뙣�SLw~㨢����=��/~�(��Sp![_K|H��;���Ь<ןg�fB�L��N�chK�O�d��?�=�]��⠝]�S��5̝tc��⅞Z�z��k�z�f�����~% qeճKp��	�Z[?�h�	�̄�m䏮��Tn�ߚ�؋v�{8e}�;����q���-��x[Hƍ��2N�y��� �\r�|i'tI�����:^������{m�v��p���{�	)2��%&����c�d��E��C+�nx�t�h��0��~�_#�`����J)�a� ��i�����&M>�Q���cRI�ևB�%�(M��cI����׸  p����I����'!�vs�j7�V���_�?��@��#�g;�ݱ3%��Z"����u"YQ}��2sY��(��"���$nt&� tOe�Ӝ,� �9�<��t�s��c��4���v��f��j�&�'n��]��Y�2prJ�#h|�e�� .`L��W3z7��hF��.�j�Aj����OLQ���Rצ���P�A�͡7.3����U�I���7�&ɕ�����3�K���7q:k�x��JF{��KV0Q���u�ԟ[���)�?�������,���Y)�D|��W��}\̚Zָ��6@��|J��B��,��M��J��4Tol���y�t�����7	�ȝ � �+	4��:�N�a<$Ϊ$��)�����'@Nk�Д;�03�gDl�و��5�Dy�9���<U�2���z$�eC���@ځ���Ct�R��Yx����2����$�gY��"� ��\.���*�$&��x���i�8V���w?�D�V��8�S�^�Ld���_�;����z��H$�I���&�)"
-��v7����f����nwb���3�ψ�H��߈�d��f���~7�GZ�s�g��B��Rݟ���BI3�G��@l�`���RVZAvҒ/F_�0������[�@�������-��[Pf���1k���1cn>���M�\�N�M�k��t�)� *��h8����2# t]��\�����O��%�p k�c
-�}?$�#)��lt�tN��n	&�/Kt �$�̧�am훯�ьO��C�\;�=T�]��B�`_U%����|c�$~��?�uM"#���*T^�}^�].���e���dچ��AO���\x9o�����˕���vB�"ַa�_B�$�����	�k����aō���XqE����c�7����7M��W=��\`�Yu=�:�I�S��gRlWn�W�#�ej�QV��AZ*��� 7A�-^E�[����2F�`�;/��N�7ᓹ���Dd��
-.�p;�3�cݠj9i�_�@+a�;azCiE���׸Q_�݀}
-z/��!e��$���0�\!̵nX�ѺLE��؊@xe 5��ag��9�&'��w�ɰia9R}ԙB���kj��#�Dʔ�$�cӵ(�pq8�fqU�E�O��*"������%�"<V�2��Ǐ|su�®�(y\fK���0�;��ͅ���e
-c�g=����~bFnTn�s�K�Rs�q�3���.8�?â�_����J��I�P͍Љ���g�(�:��q��|>�r1;	�Ն�r�d�0{FS�27.vy-��TKk�Kf�e9��^Io
-��#�R��^��P�ci�9�j��XjȌ%�4�RCq��8�*YC1��bk�Pd�����=N�u:쉭��³5re{&z��T��Do��UЕ�p-<�iVT�5�/��!醷A��߹�ceY�S�2�' �ͳz.��B�zN�S\���T�VJ�B�pO:��z�N�����ƀ��6�r�M&��k���9�45�kO$Mi&g�H��z"[�2I��lEd BCFo7�{�J�G�����P��)���6��v���R2"V�W@��7�]�X�� ~=2J��q5��� |��0�Kd�6ے@�9�V���H�A�6��u&(Y;��WK�GV�y�BU�x��b�4O�ԧ�7�S�G!��dz�Acd~{ƓOwƠk�� �*khQv
-�o�%I�����)��/���X��� ~��ɂ���1�5@���U�I�9�ޅs�����C�<>���:��Hf���gȆ�Qa����J�p+�<8�.�=�K]�5�]2�����j !f+�[��6�&f����r��OH
-��	���acX��Eb����E��bbs����5���-vB�����+���SI�,0�&F^���P�0T�蓕ǭ�s��s :�l�57�)� )��4J�]Q��(gNg>��D&����Ĉ�����;�Sdk�>6\1P��J�2?� j}h�Bo��T�+\;�.[� \xW	J��q��t0S�@��mʹA9tB�c��+����È����,R�3��؇��#����3�� �d�OûҐ@7�Q����7��9�d������u�|��� �Pg�0o[��$dׅ��`���-l��>�û!�v8��Y2�5��W�eNh$�*�O��D�l�����')L�fS��(e�zEY�|e6�毐�R�{7�8E�7��$�a}a#WdxD_$[��~�#�"����������w}8u���َD��z�]��Y(�d�"|�v��@��j+A�D,��_׎��T2P�J�,���}��=��OڕQ|c��	�|	"��h����Ʋ�v#ң��sT,����Bi�lL�*��ǘ����~C�OP0�@�g#Q}�t=ޠ[�8�[3xCfo�	<E�7��A�� ��%��A(� �������e���[�4R��C)�Y����G�a%e�UFγ�*>���"9>0��A��K��s��:�7;v��tn�#_�yo�#�,Kn��N��E�V��aȷ�&'�⃷���������Vj����2�ܛ����~T;����&J���h̲���dU.k���w�P���i���8�Q峚�
-���9v�ෲo&CȤ�Z隹��vQNs��\(��'}K���dX�����m$��&�D��\�1+�5��D|A��u��r[��t ������q/qySU�7F+����[��f��."�ʪ�]���
-HSq��Up+@>2[��C�v���(��$�SV���荝�q:Z ����ޤY�U�U��Yh;Z]Ҥ�4BNn�I[�����+r!:�Й,�/�j1��?D~�oP)�b�p-*�b���qj�G���b�WZ�?0!��FA��������mU_I��JB��W���X*��@}{�r��Qdn+շ�!I��6�v�v�Tu"`��|��\}� �7DKpǒ0z���@*�ϥ@��Xm��vӻ'P�
-/�����}����>`z�����G�أ��cf��@��<��@������r2P��ɽ��m��t�z��=��E\"�M*�h�*9�����>���E,��T����������g]�4/ѫb��7��щA�^��B��%Um���$>�������@�5_��������4�z����2ٖ�.I���|�l�� [��u�.��g����
-���x�>��J���ͻ����ݯ�O�[9W�^�B_E�(��H��� �3!�^e��4���jzN��(g��"�e��c��հ~��ջE|�"Q5 2 6��"�H�X;˯����+��yD.�
-}�)兙���B/��!��W�گ�1:燚	��e��φU�����)�?����5g��d:x��t�5�}�?�D��kG�Z!��~�8��ù�8��e`hNv�́
-�Z|t^#�ʁ�K�A�kL2ZGx�&b)���9��x5�E�z^Z��jH�����-,E��W�-7�Q��<@�D��$�y	�o�r������'����� }� e�:z||�]$�*��D�|]�Y�^�[���[���7v1 �S�Sz�~�{����C���mWڴ��$Q�z? ��F�9��H��ۺҐ�I���kxhM�A|/�ԕ�"�.��'�}���zF\����g�<�!o����;N@}��*g���$�GR�/g�1x���g����sP�:x]�GI�qz*��fLO�-QPh6��D��X�b&!�a�p-�Iv�\(pY����>������˳)�_�pM[�/^*�Ǎq4�D`���������Ahm|v�:^96�K����5.3����wd��r��ꊵ��E�us����p�-�I$���@�C|�� I��b�ba{*�Z𨙢z��}����4~���\|�Tx�)��D�l{��͌�@�op�G��d�pA���.^m�<@y[<Y.�aٌh>��/�*t��Y5�ٌ�<�����O�\%vs��a�(�C����}���|v��Wb�,j�&@{#�(֙��VEt<޺���r�H�=����s2uo���L���h#g���B��t:*[O�u�	�����P����ʿ���F�iV�$�i�s�j��+��H�i��]�JКĮ��}H���G�+�Wʦ�
-n{��mC�� fݞٷy�Y%�\6��2�U�J���u��
-��$;��-�zY�݃]��^��]���c쑾?��.V |����R���-⦈5j�c���j��1�|zL�U�κ5�W��_�Z��]h?�}*y��S���36�5"�VMS4�BSDF�@��*���41�I@��_+���Y�B���I���'�m�.���g���{���Bo+�׋���S���JlH��#��:P��s�:S���F�p�V�#����M�_^_<4�4��]�gn���z�wdJ�;[�RvF���or���㈏1��ؠ�,6�?DwKFo0�#��*��eN�U5���8b^�#�yh0��V��D!۪
-�Eʙ{������;�/���n��<e'iݱܯ8��6Q�sh���~Z�����S��cϻ2=�#qР�$~��;N�GIx��"0Xe�g����P���<���wqGf��F��Ȝ����a�̑�u�.�����-�88���No���]�}O��v���z�5�e�����Q��	2FR�,��m3bo;"�������t����6ʦ���M�x�_�X��}�dq��99�Xl�+V�2�/��2�����Z� �DRM�Qu�u�e8��{�Q
-"th��T@�lu�Z���"��n2f���@P_�� �_X�)��t�	|"�W�V�-OÜI�3�D
-u�N,P���\����q<��3m�(��>7~1��j����古lZF&�aq�>XJ�w%�3�=P��l6��>�x&Gڥ���������S�I�؍@m��@�%#F_�@^�:z͍��PϾNsQ�/L/�/{t4{����'!�0�<"�*}�/2��=F��v��>:�3���%�x�ʡw\9�n4�oc�9��g�G�Q��֣*0�u1�C�݊ʑ�ӓٮHT�����D�
-�`��M�[ƽ���������Юr�F��ゞG���*�<������&I|��@�C[9��N���;E(�ʟr� �	|�(�C��o���(������Ŗ�zp����Q��:NR�Ye��M+ɢ�z;����Z���P�_�3���ȢL�\���F2T����f���í���[��Q�F���Q����[4Mk�i�2MӞ���Q����l �ס�x���'�KT�Y����Dg�l���/�����Fh����4���n39�]���^������&?�$H�~��ɓC�J=,��5�����#�#�Z�)���z�^��ǳ�cv�>�w����{v�>jw��|� ��s�'e��Zw�u�����y�ؔz�J�1��AՎ���&b���Rm��w�{�]/���~���""[E�plO���a{�n���?��~��Y&0KB�lq��*�֨�����/;�(��X1���;�f �XKU%6=� _h��2���.�"whl�"�էD|"4
-�=~FJ�^Db.Y��x�b��@�s�F"�\��0=@ǈ�eZ�G 29�4Q _$�bH��(6��Hݑ*}�f�UݝI*�&�^3FL<#+w�8�#�C&�r!�hQ�/,���C3�1����Ǧ�L���r捃]�x�,��������_k��Z��	��Gm��U=5��]����@����	�z�'������������B+���a�z�g�Er����z��}�d�������l���U��4̨�F����̸�O���d}�#!����D�N>��o	��e���&Z/� g7������*�V��YP��9��59Ơ�{��Q�83Y�S�sb��^:w�A`�p�s��@�,��$���Eķ�Re�(�R<�"ba`���$�R=�I�P�����}�X3�<߼9;��v�rW��E��Ϩ[��K�Q�_���~9u�L[�t��p�s�N�<6Q�,��JC˝R�O嘗!��hU������@�r���'���[��2���.�3�< �J��^���Q=�i�|�c��N}1����k�M�FY�"wn�O餦���!{oo��.(FhK�h�����������Y�s^Wdw7��킞5�5�Q=);!�+H�:$�q��X���9�&7�ҕ0�s�zğ�9���).ޟ��\\Rdl|n~�;RQ�����η���.PlB&eU&�A��Q'0������h��
-nQ^#yMW;i���%ٺ?N5g^B�>�}Q������WQ�)Y���X��[~��}�׳��nP�_�y�&�k�J��C'�����yNZ�[1/�Bw�O~��LQl����^3{ވRp��C�p�!��k=M���<�O&aa^��7���Z�o�b~�.���P�*@�$\�����N`�	lȝ�>&��w������)���kP~�����[ ^Up�~g�k�ܝ2��2q'��	l���ب;�� ���X�pZ�����3`���c�_�>xf�̼�NƠ���^ Ï��$�/l�?V��^l��\����DGh{zK ��J���1�
-e&�	�>���i`��##���E�O74s~#ѧ����Od��O�G�HE�H^�H�>��"�?���_�w�h������)�!mE`2mNGZ"^�ܠ�=���A�$aj3��B�fH-��P���U��f��Bra��[2��2�[ �[|
-&��I���z=$��w�3�d�7Bjq|-"hUf�+E�+
-�W���*�L�G�[�[����V^On_S5��cp�ؖ�l7��d����L�⎴��Xw�z�ļ}m'4���ˊ�ܹ߅������/��o��soŕ�fdFƒZ�N�R��eɦ���U~U�ew���iJ�mu����ʹTIWNvO�_͸�{3��<Y���f�M,��`�x�f���L$�����Ƌ���FdF
-�S05��}��{�˹�瞥!���e�ܐ/��ׅ8761G��uG�;yͿB���PاP@�T-(�� >���O���K��-��mY*1KM�����윬��%1�,�r^f�y�'f�q+��١�{_�O�)�Y?~�k�~�?��k~������?b�ub���2�=6��7�ω���[?
-Ўi���ˏ�{�5�w�?�#�����UQ��e"<�O�p�2�_L�W�9^��+��C d��ᗹ�?���=J.(�^ul�wXgl�wXW�z/L.�l�� ��Tb�j5������RR*@PhӸ0��+9E���#,��މO���ϙETU�g�b��e��|��>㍪�U�X�YD�c@�UA����\�C*G���q%����Ԧx}�?��3ZɏZ�o�0$����5����x�<~���ם�_^$\�,/��_Nw�eE���3`��������T͵�Z3">��H%�*NaU�����a��}�'�(v�)�S��a���s(��� <�� �gC��K
-k~O*J��?�y���¶���n�1Qf#:-PQ��V��,oԗ�����6=�&�����k�4c,7�7�k�k�Y���1�B��U���s�>C�	
-6����Ҽ�����a�����s�!��\�K�'qA��+L�G�N���
-�����\ޯ�wJϼ_��=��;5��Z�\�ߪ�t����]��jW���fp��B�Ԭ��6���Rbk�o%w�7㐫3s�x%��D�*���P��q埝�?��9�-��HU��s����?	��.�'m��n����ٝm��b+L�)ZRnH�M�ʜ:���0?�e��eJ~�=�e�;��V=�V-p�3������������Ŏk�k��ol�c�T�XUJ�QQC.EN����suN@⒞�gB~�u���坈��z杘���+��\��Ȼ�d�2o��rM�]�xS���ě��xS{N�]�<�V�1%��M��ى7=��]��(>:��T�'J�e~A�E(dӦ\*-g��EE�ŕK�-y��Fd��Ҕ����*�	X U�3U�!�J�̓��<$����òy��<"�G�4�~���hBf|�!��tD�齃��p�1/+2�2��U<��n/�M���m�̦�R��?�������ƚ�m�ד��"��p�tZi���d���	E�:�Q��C�:�Q��È:�Qo�QGd\ �*�VP�2�-�CsT��?1!l[�E�yw`�;0���Lq����K�~ʖהA����wGj���0t�yP�T�M�@�����q8�s��	�(�}"�Z*^�)�%��橾?�XT�FI����xZ����_��Pjȡ�`���"��)ȵ~�x�*w�����]�C>'}�+��r!b�F&���b���:m'���'h�bA�Y�&*�_���t��'h�Nǟ�0��o�+x��oz%Ȣ�o��_(9�[ ���r.���IJ,�l��畲�߬t� &��+����տ@�fē8�����?�okN�Ø٘a~�/��c�������b%\���%\PL�. �S���|{<o+ ��^�
-�� oAz����9�����B�<֕��,o��+ŋ0T�3%\�=�_苢�l!��A��k��2��ӏ��N��Ȏn;�%���	�mt���ͼ�-$���`���N%g�C���ڀQ-Ua��W�V%�o\]$��.�3�e�<�l�\�8sM�q��>>6�����|�������7�&�_��yXs�/p?�.ܻ<np��!\�ޯ���ڣP�IQ�(�?��=����a��.�}��o�6�4�����k���������N��>��뀎;�}�P%kC]���AunW�Ք��󖱕�{�4��Lg#�g����������0���Ƒf�H�c�}���W����59ߗxEks���
-�\��5����R}����ҍ�ˀ A&O(����-a��P���rU�����VR�ٳ�u��b�;t�v��Tb�RS���"Z�JnQ��kҼ�,#,nL�x�M��KF!�<A-��ݒ�6�b��۶�c�j��+�^M�ivX6ש�f�R�D�Ǖ���'�)yb��U�hx�׆�[�#�A�m�9����BI���������qhf�������ٞ&k���[x�y��'� �a�DJ)c%Ŕ{&�����1#ʪh��)%մ]Őf�l�s�eS�ȕ�%�[�m�v[����M-Z�y@x"��2e�������I¸4N������d��y����C��sM��}/[ ��lC�>D�B�=6�r��4�������R̒c;�-�ÝIE-�#&w��\WB��`S���#ޥ��W6�g �:bi/<��l����B�T�y�?v��)�Iek��+������k��71���;�	��s�#z@f��9��,{�Zdɠ�砠90VJ���7D�C��O�9�*�e��ڋ2�8�6���"�0J% (	>ΥfXDMQ�:2��)*��Ju�QjF)c-ό�i��!*��]|��°���[b��+�[�l*>E*������ 2&7^n�H-�[�}��;lW��V!��@h -XZ"t��u���$��� �6P*~�(�A��l5??����GS�΢��
-�P>�l(:�}��!�=	�U�&&WC!��ln����f/�:�@��{�dXTms"(�Ml	Mhj烣C����L��C�tL��Ѳ��]
-/�&Z bq4�=6��T��,1F�S�_)��B�٭�WyF�\�T�y�S�9IEj.�`�:,B�x+;AC�-CՕA��qz?�����q�B`[N���2��l�SƐ��*���^ē�s���Q���I(���'6��K�ж�.�03��E�34��N�3B=�.X�t����
-6+]�+w2T���M�[�Ӳ�z[�l��`NUH9�0������
-_͒<�0i�_ڞk%7)�s�j����W���	ѭ�J�V����&"ryRUٚ���/�d?��l���P���$K׷�ӷ�k�(��b�f'��*[P �ײE5�OKH�AŌy��&ME���l�=c���("]e�xrS�"����ۣ�蒼,���ǪPF7�W�6_\S�!X��Ҿ�e~��7��>Ft�`�+��=b�|&hO#R�~N�f��I�O-X�~�����g!����%���k|.�"΂-�J"�_�'b�)��K�ٗ���1�0A��9t��өܴ����Mu�a8  �N[p�2|�iǥ?�e�}��0��C�/}� �q��˄�4b��a���X^Ϙ�Ŝ�.f���bi+|ҵ�>���
-����y����+֞��e��B��إ�s)��l}]�UD��=�i��{��"z������[C�y=��L;�����~	��C|5��K���9dEC�Z�l�ÊB��ѥ�>+z��z_'�H���x��M�\�y*��@�&I�a`��JLGV��qeS!�N����X��v�d�����eX�z41]Xs�Oɏr��Q�r�q�i�cF�	;�X��2�y|!$3)|�k����b�������7p^m������~ؔW���av�CK{�T��;�7t�3�@����o�K��a��YU�=��Tv�(�&��4X���tw7xE�y�W��+IO�y�f���ŷ��-��K�}�����;��z���g�������Q��k����]akRXK��F	��/�:�n���Ml����m6�w�Pm���c	�S] ��f�~�V,sl�؈_喟�I�Z��yW����$�E7x���j	�n�;z��э-�|Vr���̹�e�d�PL4���B���HIWgM�g�}2��7���"Yۺ���?����7J�+�ɳ� mao�R�@
-�w��X$��aX���V�D�iv���N��\rH`�d�m������L�=�.�ls ����6�`	FEL��p1םJlU�$�U[^�{�^�qtn8�s�a$��|4K-��k��\�մV��E�u�k�Q䒂�9~VhWkZo�Y��5�!E�D�)R�ҕ���5�]���b�}V���GN����֬h1�W;y�zB"�xM֭�i]�VY2�>s	�%���f}� ��DМ&Xs1�#�R��������xr�y���_g��iP?�}غ�V���T;=lN�ݧ���ъEa����G
-P�z�ݺ��
-n��[%tT<�T�roi�U�X�����h�1��.�$��j�oe3��$����Kk��k,���$��yZ�$^�l�/���Xq\u9<
-�Z��p�A"�
-3tTƋ(Ӑ@�C �I��rz\g?�J\oZA4�S�E'�4?L��*���Ҵ0�!�2�h����j�m ^LYL���i!�^��.�<�5Tf��J7�(�b�I5�ƙv�!� �:��pw?�z��*���u{���7y��y��ESgDg��Q�K�_#�}��7�2�]/f�vHy��/���}����7�ģ��D(�-�=,�ӶL�x3E�P��;B�Z����{��!?w�O���h�Rq�]S���&�1AI̕����}��8�p�������e���,�]'�/�b/��X1`�m䚓~MP"��d���-�Zp�i�RfC��JtR���0��"���X��Fi �_ �^ ��8��Ud�m�4�rW�7�5{�CI-��eYY�n$���w�/���DHƹbp�W�x����N�c]�;?p,!��J<��&����^��<�=d�|9K�	��y�ד!��Z�<_�?sň��ϝ��Ʋkє�w�:�@'�'��j�����#��n�d���G�gX�c�z�=�WS��3��nlVh�f���������|���k� Rp�����9�vB�w�&�hA؛����рӥ��cc�����<l4:):(��[��p�?l��"<R���ؠ{6���c��>����E])��C���q��zx��o���l���mXY6�.'�(_�i5K'� �O�0u�ۗ!�!��!�� X��K&*5�f;�_q7}��W�Q�Z�	��r���\�G��R2]$�N�=��8��I��v@1>P����|1��9�r�/?���U(��&]�Z��>�r��a�RC�4��
-:�b��kB���\\-�'@٬�*��i��i��$1�cˋF�./�]@CN�� 	A�}����seу�����^e(�K�0CbN������� ;d�B�I3+y����z�{�*��քP�h�i�T�%W�-ʔ�D�-�D�4����(+��3
-3��i�C1��f�v���WnzpId��;T%f�	��n"����=J:{�ٯs��xZU�OA�)/|4�tR�)�iZ\��#����Mۤ	��S\�E��EX��nN���0VL�<��ɔ
-Qc�/N,
-R@��鷐~�ЯN�K�7 {�D���������B)F�_h��h#�G7���f� �~[��%���0X&���YL�x!��rm��x�H"�+}���`Q�I��,����a��1�߸�o�Uض��v� G����k�UU�E�W`9�r�;�yhMD8�A�`��pw�aP�-����I��1K��l'��(ଓ�ig�i~F:�,l{ %�����Ov��_]6O�(�%g۟�g�Q�0%7#.�24L3"��x�"����0�wU�MٲhԵa��k��PlC��PyЅ�Utۊl��bQ�r� �T%�XX�DXZ�Le��1��l�o����ϩ�Y	��z�?�d˚ѣ�y�e���)���hq=�ɌKt��QD���W۲�SԶ�#eG�,��9��՞Y�-�a���aTm�F?Ln��c'�,�8�A�2]���B	_��=
-k��t�2��6:�)/Vf�.�����q<�u+MmE2K���^%��F;e&W�>Z�ו6�.m�
-c���^g\�����T�6�xD�U��p#����+�m����nB�hfaP��o��1;U�U��.}�@��y�x*z\5��t��q��ɔ/�	���+.J���6��i��PT�+4�S�����G1DG	5�R �$��8�1�@��:���nO���\�8�i@&�_W%�P�n���M)���4<q]�1T�6����uG@�G�1�o����.��I�Ӏt�_�7��.;$���]���q1u�x�5>w��y���1�.��-TW�O�uy�o{(��Cv�O�v�w�O��.��.O��Mf1 ��9<G���t�� L��1 4�S]0���� Wc究t@YN:�E����#F���ƷK=I<�gc��3�x��p�(��46ɻ��?�����o�I˒JQz�X�8�jFa�U�q�B��CL��Bg�w��-M��h�Xx��r��G��8���/pށ�T�S]EN�I�x�)�i�S샰����Y5E�����
-
-J����l;&b�i���� ow���E_�w_�����D�z�s��)��Qߥ��R�B6��`-��3�S1��>������#m;�b�?�t*$�|-��B��(�ׂ�a�}�Ȧt�CI5p�;�za,j����Ǽ�+� �Y���*��?�����"��f�D��.�Ape�����v!�!��l�+p1ź16m<DI������i9�P�+�WɆ�*r��"$n�h~,�!��������˦}��HH���[>!.��/�%��ypÉpo�'O�iUn�#U0"�6�J��G_)�Z_);�2;t�^�׋�oz��j�����<��f#�R!��S�x��%x��)��v�`G��:�r�|F�|�z���<�C�>���L��b�er�6��.��"*$"PH�մ��J��)�O�h�9���7����enñ��z ��R�Rc�i���dtE�c+��T�/yb����a�y�J��S����GA{�~3 v����E�)��v��մ2�)IJ.�9= �� �*8�:��.�~n��U�p�m���|a��.���`gz�=���k�p�^U=D���)�ٵDֵ�b[^�����ߎ�:�f81>�!�Ka;Fv��q��g-�)�8�hʀ?tw+O}ݽ���=_w��݃�������h�����c5c���lE?�%�%�Q�:���9��6��۩.l�7`{�i.�_�[~�{��u�N��z�S���2���n�c��3����;ZUlE!lp;K���,15'�=��x���(v?֙��t�P<)I��s7��|���}���ϳ�������7�i�SM��0eG�l)O��V����V�B��a�w�jۙܦ4t���bB��̀82w*%"��`�9�w*���;�B>AF�I�S�c������T�ZK1����n�]�.��g�9�w)��λr��R@4�)��U�.%����xF�~m���=+��g�ևG/O��@�}�PU���YU�N�X��hS^-.-4�;S6昋b��0�J���};�Z�z-b�(���q	�1F���qx�R���3:+V������ʐ�e�(j�`3�������P�Oi�EPk�RԸ��cԪ�E�����(���סS���=��~�*Q	T�Jz�Ўz�z���o�j �.�s,G�N���,�2�5��ER�|������j�y������t]�z�ò밮����uL��quLQ}�¢������Y��
-ԅ��1f��{�(��?�EJ5Wщ0�H�O8�����#�42G�I�=��S��G�8ĻkC����[����Q��v���<��+���>�������N�Ea� V<z�\��V���"o�V�m3�a�f��mW�����Ą��旿mb���=�?���G���-�}v��V봗�=�YUY**�_�)4����5*�-
-�����R�P�dҦ�}�K�~��]	k	���'��,���D��|�ƞ,���2^�O��SMs5`F�=oQq0��?Z�1Z���0�iQ����5�n��/�9�CElwlm8�J����jx0@�"�*��3�:r�W^�.��>�g|�����RT�'ԋ�r���~���)��_�U�T�C��︫�]����=d�J�A��Gsu���̏�	�[Y��������X�E_{�d=E���`�_�\�0�4e�
-�C�,�����',˕0%,��(�铷V���l%�'�m���K�ք!��r��쳺���g�Uy�𱏯J�}��c�c8^�b�0��u��S���YM모��$����JG*�F�J���K�1Z
-߉g��3��4M�Zf�j��}��>��\V��M�p��/+5���d��l�岭��t�A�'��ݴ�^|'��_�ߑN���Oy񝤟]��2֘/k��隇�r���U4��4�E�膰��غPbc�~	_6��ʧݶ��i�Q��|�����>�ɯT��A��Ģ�V���ksl,Wbכ�I�ħji%?Mqt*1_s$�h5|�
-a�OUn �"��*�L��h4���˪L�ӌ<��%��u�����Al�w�܋�Y�~hg�V轭�4fyr��e3Gl�#6C.j-O�R��^V]��+t�����6ɒHfW�WE|����RF��#��y>	^�_�N~�-+U�����o�ӱS^s=�LS�w�g�j�G?��m�O_��mn��;.� �|J&Tb�X��e8�ND�L�/�R��~`q:&���á�0U�Qr�f&i�4���~��0�g�׸��OݕNU���)٢9i��C�� �X���v��Jl���+�"��V⽰h��x7��V�vZXT�-���U���H.�W�r�����S��a���x"����S)��A*��r���9_�/��|&���^}(5O�/J���s�`����V����V�û�bx��Io�2��Ѓ~�J��gr�kc�����{�E���������a�>�߇������B����0z��'���s��5'���f{E��(��){�N,8���*kM�-ofQ(�5���+U�\#r��vQ�g����|�շx������i��%�sJ�74���y@�
-��G��
-wpx��x0��SŝV����c-|��S�㊥$}>Ul�VE7���S� �1�Tӳ�_�&���d�xZ L>���r{��̗z���K�mas[�������aO��p�Ք�nd���4��58-͛*#:S͏k����5o�USIJd���'v���=G�k�����v
-s-�P�ǳQ����װ#�2���?�ݮ�·��!JX���fE�N�
-좿isg��J
-��j��F �3��W�3,�.��κ��P�]?�z]��y�q}��-xl�V?D��'�Ó�,�?܅���b ^����mcA� ������q���n��؎�Π�1վ�Zo���:I\Vg2������l4���+���-�YZ�{L�C3���k6���.5|�P^�zߣ^��z3ȧ~1����%[D+D�*8G0�U�#���m-6�gGP߶��v��>T�������H,�j'��ܑM�I	
-���,�#�nݩ�Lҁ�w�.+犡��>K�4/86t,s���@����)�ǎ�a����	{��y�U}����Ie�݌�P���� )J���L��D�=.j����no��w�m�z�7�I��Kض.y���mb�5�ͬE2NjMW%)B����Z/Yo��Z�i�"yݙ�9"��M�#�j���SyJt9���b��~�r�l�VbSl�>�n"s??���'l��
-�וvM*��f�+�9�R$w)����#Dh�~����������l/�}�}4d~�fU���-(���4�x�1���a	�͇�V��⢇(1�b`i&X~�a	�c%'V������đ�d7H�x���~3�8�{{}�p/�y��e�V*HzA#&�՜X7|�C!��	]�������x,,υ��2ٻ�7��v{�Dٖ���'r7��.�3���mq��t�Q�ɘ�	�H��������HH�|�2����<*���V��Q�u/�
-� 0%d�$��O� X��Ã��w����C;��O;�O���h|��Ƨ}�2������x'
-��w�0��#M۝��[4�����2�PXb�	%,�P�ˤ��NAj���a�LV����yGT�d@(�鸊i������]�I���Ru��_y͏éAOJ􏾏�MQr�>���d~B��$��9N����)cr�<M�y&ls�@FK�ϡK-�bj���1-d����޺36x�*���:����<������L�����_r5�P�x��������$��J�b\Qc]��ո"'ԇ%�s��)ո���R���I&�0�+��`�t��T��`qr��* �3��aA&k�_xb�í����#e^��Yt/N�U�-8e|qK�jZJ;@�2�:�۾q�TY�S��r]�۪��h���:^����Ka�%�������N�<��m��%>�Ù�=D�>葮ІZ��I�Oq�z�J�����j�����^�1���v��>w�v��ƟyZ�a��#j�Z/Q�ɅZ�C�Tb��Zz������ƿ���5r�qr�9�P�U�{h�,�S�n����%�ș��{q��S�������M�iQ�{���&0���ħa���]o��d_��B���V[q��,�瀪����-�`X���������A[�[��"m�c��T=��_t�����G�B���"�J��A>Y,����?��yF`;Fk�X��x�D��7R�����N����z�pƘ2f�����2;d���2'd��=e^Ș�{��R�}�הBƂ��2���(d<��5eq�X�{��!c[�-X2���gE�X�{ʦR�=�4":�
-�f�+�MVO�I�i�<l�
-E?K��Ja\��"(�t-�e~���O^*{2ք��U���x��֌�U��*��1�6�Ƅ*c� cm��=��Yḙ2��2��2^	���US���Bƺ2���1��x#d��2�Vo����IU��u!㭐1��x�ry�]U�jh����<���n�?1/'��X+>��F�ޣ2���Q"t�ɾ�}��@��_��Qh<_�=>����%�#4�e��6��=Jt�����#4�Wk���6�Y�e�Sw�L������X�K��KMCfkMj�Ӓ�xM��l��g$s8�<+�OԤ��9�~&{͑5�zs�<I�n1�ɣ�4}o	����dz�����g[�C�='�c)���񔰴̜����_ɜH@c$s����ɀ�B	s*Ō��i;����3E%�(PlήI��/3ہ�Ѭ���5�1�|��2_�,�_䔅�B6��)�Xd]�IK)n�d.�r����|4d����^�%�92W�ϫ��5�;��,��ϝ%���5y2d�L?�B�ZQ�+�s6d�J�j�V���d��U���or`7�-T�6��I���������}�I �ǼK� ��Qܵ��>�����\��U����P�;dn%�����ڪ�m�$��QjJ��h�	��:��1Cv�N� h'}O��.ʱY2w��(r�d��{�{)�js2�N�-�,r�'Q��x�<L�S%�豣�&��D�>F���j[�y�k8�1�t�d�������Y*dF�y�~fU����(�"��W��(�ɼ,&���Sm^�ș��)��W��q����\�j��/8�K��W����I՘ݜ�!T�p=m�q�E�w�
--�6G�ϒjs�,�6��rOER��z�9%<Mߗ}�3L�g�b>G�gI���X���l��Oq�%sJy>BK�8�{Y�?e�V�5b�,z@�z����I�t,2�h�������TsI�]T�9"Hm�#
-����q} '����M�n���(S����^{��' �q����>Ns�����v����n������S��{&]p2϶3_䈿ʮc��0��l��Z�L�'�K=k��Ϳ����y����_.�*���<�k^�m��yҠ��y'���=%"Vݸ�A��kg2$sj��ݳ[�:{�����o1���$ۅײ__d���s����"��Ġ9����S��^���"�h,��6��3xΣ#�Ԕs}pg9vgj~�=�)�j޴�\ދ���ʀ����f$�����/����g(잗�1,�YZ᳹e����N�b�R�=��jY\f��2��AI�Ɩ
-�0?�DC��=`<月32%>j�\�!UjΣ�����E���؆2sA$;fm�3ó_Oh�OV�� G�>��GzT!�fZ��56U�30J��5���e 4]��~�D�i��q�ʦw��?�	f3:�4����6m��,i,���VI��j`��?��.2i ���Q4+X�0����'5d��=���6��v�My�A��ie��g�a��Qb���;Ս#J�6z7��z�������w��{7���7��'�~�o�n��~�8~[n���~[o��n�S�~�n��7����
-�ԍ�g�~g�+��7�_�&�;�]�����	��}W�u�8~]7����
-��7�߮����w����o�M�w��o���&��]����;p�]���;x���	��|W��q���~W�+���8~�n�O�+�>�q���~�}W�}r����	�>���;y����	��}W���q���~_���㏝���go��_~�?��?w���;h��oh���h���A�/|C�/�D�����_���_����j�����t�\�����^�	۴���߀�7�����|У�e@F �(�G�xG<��{�D<J�giģJ�e�V���	��Լ��+�	�T��k 5Js�B�O؞�d�쿋�(?�zۆȰY���L5E��tby$�<r��+����AafB�ɲ�����!ԁS����V�J��Ք�����Z
-�qWD��Z���P��6�\�V!�����̗",~���-/?챋�#_����ǵ��i�(H�e|Q�J,����3Nw4������?��9���4�ׯ@x����% ������Ǣ@���\�O��#5�P���q��n��IAc_��`��q�or2kk��W�
-�������zƷ6�	Ե~%�Z�,L�Qf7j�N�1�o�2�5����V�,CZ�/Cj+��gEU[��+�6��o�՟�®�P�b�i�W"�W�ө%��Q��'p���
-��H��E;'i�g�����}����;H���R��M�~,��[41Sg����f��L�|��%��| ���C&�Y�D�|���:4���W*�Uk�F�Tb��dihc{���(l�_���bV3ߊ�q^�k^�_�� ֑j-f��z�6�;Ӊ��aYk�VzH��<M�!�OX�]����x@CClkY��*��?�?T!��`U<�[�t����P�(8c�5�i�Ahl'kG�ϡ���m��$�X��LC��{��J�ݰ���|CN%9�h��;�A�v �"#��߀�H�fXʍ�-=�P��݅�>�a!�@[8��yTʠ���!tL�h�p�^�I�cu_&lYu���@�r�j1t�[L��� ��R�G?�%����*�`�ԩ4-`>�js�ۼ�WD?(AG����Gn�5Q�¼�h���UNN	�L�-95�2-x��������n�+� c�Ws|��RM�y�^��^�*W�}��rV�2�C�5����k�z;�˹��a�+Cg6Cg.�+����+CW6CW.�k�]��+��l��9��e؉o�2��fؕ˰.�a2��ʰ;�aw.�۹��a�+Þl�=96�2�A�������-65���Þ��@W��� ���7�������0ya�f���U$VsF%��|Ԟ��ɶl������M�X: Db;5;���O����5ם��{z����I_A{[Y���)�E�Ԓ�\��� �Dj����{u�����.^���qz�N99=�2#h뛜l�����9����,�f����OH��OHR�(N�4�3��a���W�dI~�Ye�h=�~�ڒ)��<�A�.eE�E<ɋZ�v�w�i/���=����u"� ~[r � ��p
- � � `�� �� � � �l8yN#J��,�X�K_�9��Dq2B����y P$�d�`MإG�tҦ}+"��W��5�$�QY��V�};"�drg
-�����Ɵ{�r(UR���s	M�DS2��J�`a\霖��������# j�o�A.kD�8*�>]<T����v����pn�C{�r�Ϡ�Z��awT5#�S����A��! �E &N��8]\��\T�j@��w͸P��6��}���$HG@&}+���D/�3��>/�s�,��.�l;�E�V�SMV"�K�ǳ��Q[�ݪ�`�	tH%���tV���Sn;U8�Z��',���������\�D�Ok��<�*�̓�2O��<�*�$�<�_&7�85�87_d��[9�\�vFں�$�DX�X�:��#���}��ĵue(XI�el�"�B{�cn�0�m���!O:�'ȓ�B�.�g�������Z�Z5D���N�����6�4v$�f�����ب��3饓�ab9��`��J7}��+�g�Ė�KC�짍���+�hS l�y}�k��0�����^ߴ1"mT�j\�����9n��V}Ӧ�������Gw�y^[;������*{kե�PCfy�h�P���Ҟ��tt]!a����Ax:���:Ř�#;�B���h�+��Y�Ծ���x�����EČ�ů���#��EA��?t�5���n��0R��P��'.{����}�����A��k���3�8ᴓp�N8m'�h㥊@M���b�r�ǣT�� �
-`P���;�X��$����n��?�������ث8��+��EA���KS��^D�Y! �j��/�q�mH����x᭨1Μ
-8����藚�ywQa�.�튴B����Nr[���A��콋u�5�TR}�����Ct��x�m�T�W�mc.�+���2��_l�Z�T��v�53��n�l�DwSDE�c�ϙ��?��~��h��*]��"9�ŝ���%8
-g� �9��~�-D�5Y�+_���!��J¬�6+Ns�<u�M��T|Bp$ �6�	<�ƫG�<�Y��=�?���c��b�s���ݪ�#�jJl��8��0��\�Aw7.;����kq?�Nt[��{��12i`r��7�W׸,iw�w���A��،`��a��0ͷ�h>�eM��Iy[�i>?�������C%3G�vX���!�"�
-;�e��|*�t��"��"�R��Ȫ���8�f�m�>���x�e�}�_��u��/]O�(�����i�ۈ�.����Ss<ND�O~�+�+5�Qӭ�]������.&+���:K�I����|P��e[��ᱢ�=Vȶ��L+��6۪����e��F`�&%F)L���\:��;֦'f��{������p\����1,ꪏ�������Y�Z��gJ�k� Ÿ����6��(`W�ޕ*��d*ˤ���J�f�k�=�j(
-0�<��D,���l3�C�6 �썩z��#�!a��J�iM�:ܰ3��΅��Ky����|B��	E1��J5��q�9�Ѕ�jS��s��'��x�Gx������K���N|I5}�ؓ�I�
-�s��0��;&G�9�p�>�3m�WT�-������dd!�ۦ���C� Z�Qነ�T��T�p?��I.�m�'���VK%/�� m�&'G�!�㼜$]����$����o�Ė�mgU,��N̅�b.^3[��캘#t���F�GMx�WP�V�5RP�"����eO���G<R_�Eͫ��G],��guO���9��q��u��z4��yh�?b1�Z�=贀?�XQ+"�0�Fa�\�R�����x��մ���p���,��8�=�N�6\��+���z��#��4ћ�)���J�ݞ�WJC(� 4�zc��y�ĸ��v���n��ty��2��:���5'9�����XF��V'M���ap��t��/_;&��r<Q�	��T�T+�sM�|�Ԯ1�~�&A�$���=����7�ѕ�1:��4��(�&�5�tB�\j������I�{^���c��(��莈�f(,B�X=����)��)n�����
-[B�O�?��5=�k�KM!b}o���Xq~^�Z,,*6��l��Ԕ��/2mC�%��-A�ѕ1>��a�*�JL�a{�n�\z���F�u�]!�kth��A����7���z�Mz��&ݛߤ�M*s��;T�8W�vѴ.W�~�Ms�r�莃���?�مI o[��[��4���h��*�S����}i�t�<~��=r;�c0�yׯp����jתU�)�6uWln��[���R��97Hipo��T����:�v��C��<��HkuGl~�-��˜�H�OH]����P�X��@��k*輌�ҷ��Ș1�"�4n]��A<L���~�"h�N�e4P"G%���M����e��.�{�@	p�e.+���h)�F�-�H7�f ����'�@��T�r �f e��xڝ�}�{���|�DQܳ�,��"��ج��t��v�mz�7�1�:6qc�%B���y���Z��ŭ�	yy_�����e��yp�0ܤ<�Wnr�k7%�u������۴<�7pz^�:���W�[\��<��n��W|r�]	�9D?*�#����o����<�k��\;�c�Pr��\�9G�c;�̥Xr�t��Dm^l\����|�Yû��[��#i�DA/���:N�[@ᑿy�ҸC��v���/�����qb��9��Gh_Y����.y�#���aǄ�-"z`'�tڂi/nY)�?WO�'g�m��z���G}�w0"s���"�y�"��E���a\v�!�����׽�OP�]�<u/�����'��.C�����8-~*ꎭ�?[~]���k$$D�H�Uߴ]r�=�d��jH���-e$n�Ď�r٣�$U�*]v#����.�+��J�Q����J-�t*]��Q�����F8He���{��2�Ԧ������	�ː��U��K��o�^�]�\�Y�gkr�#�ޛY�n&-񃚽�5�47|}s{�e=�D��rv���܏��#ߣn�V��j��.Ӯ��%F]ɂۺ���v�Kn�d�P�cF��k2�DDz���L]�q�N{aQܿoú�*����vۥG�΃�k0}�E�?����\�As�vek�KZΗ�d(Q�y�9P���̜����]q���2�M!���c�n?cͰ�?f�ס����}r��ͷ�#�$����ů��+s�sW�7��8��^�?���{���%�b����+�ƧRr%�uz�L�[�Ob���~p~�'�����,�A4�������_
-�:�̗P�����R��%��ݘ���s��QA+P�&����;D1�:8.�B�D�J���;bH���{�N*����e�u㫂����*~C֯�zIG��P�fݑ���K� ���@�l�sPwQ�?��Jݑ��0/Q@�]}k�~U��m�ӽDmV���4Qx�_��+�R�Q��+��L����'�Q��wp;^��R��t�Rqxj��;��\x#r�w>�a?�2(t��3���̛�Bt(�j)����c�V�1.ܞJl����I>��G���=��%G�����y��ge�mU� �w\����/���-UƄ��|ؘ6&���acJؘ6����a�~ƌ���ʘ6f���acT��6愍�a�b�1/l�/��a�Ű1��X6���a��~ƒ��%6g��f�
-Y���?�����u׸׃{��1z'im��`��H���)�H�F�Θ���h���`:�ZP��0���v;�����}K�i��!~+�Y�Z�0��������4ʁc�)���c�����z\�{\�2�A:�L��:ػ�Ńs�ӓ��m��~�Ֆ
-��K����{.�q$2Lou�A�+�ȷB ���!ǥ���i�S�k��fӸ����Ԧ�_TK�9.,<��m��%K��1oX"�Oy�u��~�4}�������S�4o����c���̕���\�{��>0�ӄO��h��/�&�rqYĊ܈�'��ߞ���}~�<�&��̏uZTu�3⼄e�ΣǸ9��w��w8Ϊ�&Eߎxi��#�R��^Z��<��\Ȯ��j�a(�!��EZ���g��f�W��`�:��u�����V��mĿlY���-;r|�XI����6ٖ������Zu�6E����sM)m]%�fTæD1.Q��\��?!�)��Բ)ۯGO=&}mg�*�x,YؑX׉'���eA�O{&O�K�L��e��X�Gd �~�3=�.fcQD&q*�8A2�bݪ���g�=�]�:O����纟0����VТ<#�2Yw������t&�7�3��beә�P]��Y�8���R����a�����!zl]0-
-5$������D�F$��)����g5��C��	%��gR��` Z�sx������w�z�"��_��[���T��J��� ��e.�=b0�Sl�:�����bwfw���~���G�"��(�A/+�q��Oľ�V'�NF�j�a`��+q1b'^��QG��jK��BZͶ�=_辀��l6	۱$ܲC�±����_�OԸh[��i�C�k�"���3"+o۴�i�	m�:�T��FB*��=�ݽ���9Ą��eZD15o�%@�� 8N_�c�د�`���<X'�5���+��𹀩�����+bX��b���#V$��0�ٴ>o� �+�!��8�Y��p��x��<�K���pǗ��ո2p���G�F�k效�itj$�F���,ف�����B��A'���ЁN���=?�����M,�b�s�f���4R�%��P�
-U[�/׮	y�%hI�s���͹FMx}�µ*�e|�]���,�W�o�oE欻T��x�F�����GL�(������2�9��-ː����T1H�X��IY!^�,����`SNu;�;���@�[�E�4���ح�D5���������υ����5���^ڗ�������>,»;kZk�"�����Z8s�IṘy�n��s}~wbm�Ԃ\��В�S�mE�t�(��5,�����|�����-q\���Rr�Z�X���cW@�h�]�C�Л�u��ʆP�w"�SJ��6��W.f���~�RR�xلy~�Z�"�/"�T���d����\[�(�LM9�I��ƊF���ښ�;��e�/�v)���в͠y�J��PY�L0�֯��dv�МZ@�)��D�_"�����g�$JK��l��S�?E�S�3�O�4M�w���ە�q��f��v:�z��U�%<c�	����0;D��u#��+F��HC�?�w_Ө�x@䲝ob]���c�@����B������yc�S��Al�a�d��'%�� �x��ʉ؞~E�g���	r�P��&��_/m�6�q{�S�-�����<�twgĤ���$V� Wg�1ċ����t�Sǋ�;��$z��7�A4��[��a�K���X\>�*|�D_ʛ�#�x�sqy��n=���F����p�̵E���ĥJ�-�W�kM��`Ƥ��Q���r;X� �����Fcd��^v�@�|Y�}>vgӗe�MG|D�5��n��ݠ'�8��؏�������£2M�)^�U���_4�lz/�)�-{��ȴ�e���c6�K�wu�D^Wf5���(F,�ӑ4o��[.��č ���n���>)�Z[_Q���,13���kѹ��c����fl�>�{NY�΋u.��/���K�V6/~�G�����O�q��t
-bF5�Q�!"��W҉������G|B�$�#�.���r,���S,:�T �TߑG�׻Iu�:�y�.OrBJ�@��8R2��T:���pk��~x��u]۷��OԊ��%��� �Oy��AcB���`ˮ�1�_rW�ewИ�/�;ز'hL��l�4��K���3�%��2& �!5��+��W�f1��,�0�6ג#鯞U��@���Ps��.&�LP��v=6�66�66��q���nӡ�wT7����d��d-�>Uk>U��8 ��R��Z��t?�{�G�g����;��}���
-��؁�-��dҤ�@��ޠ���o��$�@�:�?-����� �T�`)8��|r?��B<hڇ��M(�0�$�������@q�a%3zJ�q��-{=����v��_�3�Skjr �*�D� 'bTVC:�G�S����z'nZ@���VZ�V��ti�&�ޱ��*���0M���XGul_E�HE*��Gjib�}=��V�V��[2	��
-v:������}���X%N�A��iwqŐ̧k���3�q%e>[�>���EI��#-�ء�c����ͱ��S7���.�_�?t���}W7��e�e��E�(�u�y�k�ֺ!j���u����	/���4m�*�ڈ�N��(։8%"NQ�~y8�Х����JtT';�[�����&��m�Aq;��;�[�UX�}�}-G��HE�HE�1J=V�<V�2V�c��X�e1߱��������������:����0}�N�n颯��dWu�^��[��[�r��V'V�L���k��k[��ה��ږ��5�69�֕w7}�N�n�F��j�ӰVgn�t^]O��1��Ax��ma��N��b�6�&��b���dR��@��X0��^syp�en/�˶(��y@) �sY ��d�7P@�� z����<����v hq� -qu hiP����:�<�@+�@] Z�����S$�ҙ�������cWg�)�m�]Κ����R�Y�{�����[�������+�d���s�(��3�腳�Z���)���=,�������
-���r����1acC8:&�E��Zo��`s��d�f�R�UJB�`u���������]��w����D��7�>0�"��ϏD��t�O�.)y:�r&h��<��F��N�ax��P��V���G��z��v�y�]�}:�	��~K�6�l�x�_�l��\�x�_�\��|�X�/y�_���ӝf�e) i��ù����|���#z����e��v�K�8�v��cY������ŠǼ�&� u���a�v���9��m}�����p
-b�^j�C���1^➻�����E�uq���� K\�F\Ց�>y�����9��꺓��؇��SMk���~ ��sG�f��e|��-�P��~����������x�L%��>�����$�����w���3i��D����gj�WH�&%^�TJ{�yn��n��{�����҃qo��D�>�F����x�� u�eB�l�������S��u��C�����)�s]z0�8�}]�w�>�-���g�aBE������v��)�q�h�~6��Δ3� d�CA���u~��Jz�"�.m�_ ��%�[��#�|Ŵ�^�Zw�qY�	�by��4���~�;R�*͔ &<RzO��.xҼZ��+,����=W*7x֜Ѕ�}�>!�,q��%O�H��E���_�L��:�N|1_$�y$Z�Y(�ӂ�O�PY�F�(�HFg��v��w�@��,K\~T&�����
-�6Y�W���O%.��*������^�o��Kn����~f#+Y���ms_�
-oS�L3/&&�-�ċa�m�#O����ty�%���<���u��O-A���SS�o]�`���d�od����9���?�ų=�����P���ԙ��ȒgA��O	|�~�Z�V��Z��2i�V�<1ֿʼm�	r���Z���2^Z�������l�|� x�����n'�y=���6S�v�7��0�n1b)Z�Y��gi�>��}E�=�X�W���Zϰ6G��n-m�����~��-K\�8�IrE��~�{�&�y��VD���,k������p>�����T���/G;7�=�8�m��wѮ Ӯp�˙'mrnζ����-�|䶅ʆ�y<�?�+�ǻ����Y\��x�G�~�}��J������GFa|q�#��ě|�:�KA㤔����  A�����C��d��3��?c> ��|�~,sl O�c�/M�Y�+n�� N�1\���2�l ����t�(p������,	ʐ �'�m�SYB~i�L�+:����#�q.��YV[��O��P��l���G��<rl�I�-�J0��¼���\��q�l�b˸L)p��Y��Q#��� ,fJ�7y5��)~?�|�/�Y����[��[��ׂ-_U&��|�?�e���ɯ�-_U%��t�������A���ʖ�+���W��U�I�U��4��^��D��V���-�*cW��ʖ'+�'+[����0��%CtclD%�}�duˈJ���!O��)Sl g@��)�"ۢ8fAƞ�,������5U�+�e�����J���y{Y�Y��#+-�mY�=�M���5���p�F���j����P]YdQ��w�[H`����-��.+��փ��4>���/\�
- "���;�����V�8ZY�Z-�����"s؛�[FWf�+y�=�o7G�y���G�(x
-�S�G��-pH����C�%���
-���bv毢���$�}y�7��볕�����7��������z�{[�-�r��%Z��az�7�L�aޛI�8Jf�&3CxIZ�=ӿ�&��D�{���"Ƙ�`��A�1x�6`���n���mKf�`�`����喙��d3�������k9u�TթS��V�3�tu��Dz��5��k�-�JעڕaU���}-�Aϟ�a�'�*>�W1AB֤�]���K�����r�S�����0����{`���hŝ���Ƚژ�b��f��D�����k�z_m�fp��Y����h<�t�IV�SV���Y3K��)�I��E]��6����=�s�z��L�M��Z�VW����	��T�JP��W�^Sʲ��a\�z�V���K?0��V��x�^�k���kL���8H�G�=	Ň8#.��S*%���R�Rqф�����5����<b#�;1��'�Q���c��xJbN�3��_h�򰍖�S�e�u�/��Ơ�hC��D{}��R�%�*��� ad$�ޑ
-N�s�����tCB�dM�w�{����V	�]+a⨊�d��V�)�Fg���?����2�V��1���Ub!�/tֱ����ðJ�l[ǘ:*a�_�YHl�{b�;�[gx�X?�2����.0;�$�l��ڬ4�D"�7�/�$�G�����FvvZ�4|T��6ПCn����	�K)D`u�w�C�!�-���y.�D�MAqek��΂��4:3��x+nO�K�1����;s9��
-S�!b,��fՄ�<0���Ԭ�����`QC;5&w���_h+�|f.�E��[�����9P^�-���+8hd,w���\�#�q����+�Ͻ�+�|�u�Wz��ٓ�t��~]7b_kԆQ1~��R��L)!Z�R-I�h^T��!���Z�P-�1��AM�ܠab����(�#�q�ӎIt�^q�n�Z��Ru���ң�U^Ot�<��y���8R�+\*���J�o�������������r���?ǭE{MUgM��6����	�1�����d~�4!Mx����'^m�Q4&�[�It3��Hl�ڱ� 0�AHl)��\���Y�̀;��@��s�`��0�
-��S�&�tS®gnJ�g�b=߄�y�S���=������k�8�Ѓ���G���� qZ�����z7��(�r�ܜ�ə�9AI��N7������� %d6$P*;r\ρ���}�*�.20���nC�?�&ӂ+�rZ�/Uf0S]���di����Z1'�FP����I�?�Fuu�����/#�^Zh7B�x٢�w:�����s�$Wؖ�tÌ�:\"�~���54B�:��J�͉�iXi�l��ʋ?���"K�����0B���=& .��c�SB�$�&)!�ZJ!!��'�|�/sG���/`7�wS�Զ��L��L9m=���w��H��X(�u>,Dq~3���(��<���oT�4�6)lW�v��a<	� ���r����CSL˗�rJ׹�C��N���?f>6�<e�Z�����*��_��ŉ����DϒDzǤҒD��D��I��ز�.��\�gS/a��Ĳ��P�v��������kRF$�R,��D­`�[=�H�%����+?��Y���_��YN?�A�1�`f�[�[3��t˂X��r�`o;���y�����3`�w-�#�{�1J�W�Sߑ�C�߷������?��>DL�N}�}�)�ױB�JiK=�9T���G��,ڞ��u���C�ǌ�1�+�9�ҊD��D����DϪD��I�U �g�?�?/�זҋ@���ÿX5�	�Pۅ?*mE�lե�||��� �cm�y�op���U�k�ju�6������U��V'z�L��ߙ�Y��5���Rڬ�Q1Z��ޞ���w*Ӷ��_�X�y���ȍ�Et�w;��H(�/Rz���;*�J?(�S�Ln-� 	���
-I��I����)c�Z|!U���H��"�o�/�d��CƟQ���}!~�����w�Sn= �jP���jh��7݋֋~ꮤ���2 J�Ќ��y>g���Y�u��x�0���x4I�|FG��ԽC�2��2Ք�ߖ�P���(�-�~����CTY���7�XQ�{��v��.9{����|���=0�Ѹ�Ƨ{3�S����2�
-u�oNz̋޴3�v�(W�^݄H�W��ѡP"1����
-��ȫP�RI���<��e[H���jv�xfrË�=�x}�񽞊��E|��*�D|��TnN�����ǂ��@⺏�q�����x�ge#�)Ԛa�8���;��q��]�Z��W`�?;ͨ��J�1�5��C	=��:�.��|��ޙ��:D�(��t�����34���!@,��J'v���!@,hU\k
-g�NU��CzP��Q� zI��h�#����&֧�ќ���Ĉ�}��C"VCX��¨^��lH�}������Q���0��D�S�T
-�>#q��&�y�KE�-�Yh�,4v�h�c�W��A�: �a짷��!�a?GS�3̈�[`/�|@ѦH��)I��s���9"�s"2�9�4ϪC��=�GIn�v�Q�8M��Z�Y�em�io���A�3du�����T�/�#�@��S4 1�$5*�J}�cT�NӘf��Z��F��F��G\k� �����!�X��<�������R�^6̯�`�z=$�#��X�9N¯�s�S�)���Uy��i?�wI4�HA�G=K?a�F�Q+44`Ӑ�2g�u\&^��D�\�
-�uQ[�S�|
-
-zc2?H�����Z��-��Z�U���=�GŲB��V��Uo�γ�9��Y��Yh�,L}�}�}�} ��?f�G��㶶�)�6���/h��Ɛ�$#bR�����j�V�F4<���>h�Y��w���jX����$ނ��y��[�L3����˧O��MbO�@kR�:��:�ziG:���`*c�p�����u��jq$ս#UW�f^N��_I)Y���B�I��K��S>$�q$�M�}VR���%s��0�_K���c~�s, c�e,(�ޏ��@BP&�.��}r,�5<a���w�5�� {ȆW��XX�f�yx��������Ԍ�jا�֝�g�S�e�{�=�b��Oy�
-T�Mu��R�Gy�)��E�vyK�<1c;��iPsh��IkԚ�Z;���`/�������!)B!!FD�ެ��YW\S\�g�����i�<���Z={��ؔ0j�&ȦD���X�v��Gm�@�<�/4��;��?�����<�D�$�"�o��U�B�@��M�Y�np|V������j�"8����6��}�bsKd�D�}"���+�Ɠ<M�g��-4꟫A��3�ȵ�<������Fs;�}p���лC���&�����LPUr��|?n~sy�� *<Юơ0!��5��䗡�)�O}iZ�K�X&D�֧l���!ZfW��a]gA�,D:����З�#(�������nZ��7^(#df�l!�'L8$͝��<u*��о���.6��|%��֞yU��[�D�Hݭ�\�2[���B��P�D��j;X[	/�����[	�|�,���FP��L�1�Rk)�v Ab.24 �:��U�ի��/�bM�YWi�4�K�U�w���g>$RftݸJ�?�k[�uA���2����B�Z��jD��T��'yu�$�������O,�З��ߥ�T��L�u�{c�B�&�D�D�=��3	(?�5s�i��Lׇ�4̙N7g6�9�¿����gǸ�?��C�Gώ߂������Pmv�(f����X��i���P'�A�Q��������84X�1�h����{r�/��̍���ܩ��1%N�b V��8�a
-�ݤ�l#~�OK���C���yu�]W�V��РA!�R\y�Ձ�L)��/K*����<��|�><���"�OD!����B�:���c@��b�;�0	��)x6���2�fFؖ'þ��1`���bZ�*��ɒl����%X��a��d�X��X��a3#,2��Y�`�u���C�cL��E|�����nO�W�rA$M3HU��ġy�ӆ�Qd}�zx����f�Q�lN��B=��ԫGi���m��}���R9�}�8�͂^���yMB��<��	���j���d������1���K������Z�[t�%������Y`ۯTf�F(6��¬�m%����`Kx�?.����f���p���|.d_J�Lߴ �/��V���R&�.�-}v��<��[Z��(=U��\?��]�I^ែ�����w�Y-��j�"�{�[���iu"�Ξ�i{�W�y�i>�泧�E�ߞi{ZP��i!����EZ؞��4՞��4͞i{Z�H��Ꙏ����B �,N�^|G��8R�Rd���L���U��	<:1��s�����5�V������3
-���t�t>��3O�D[�,���D���}Sӻ[a�*O�{�Z�������=w%��c�
-X��ƕ�k+q�Ub�U��Dn�N*tϺD�OɭhI���S��u������7Ѷ�z�5a>�2̽��}��}fֻ"뾄!���퇾�������M�g|�kW�(.��Q��/�`gO�x>����Dj��(��1��A�)D#�N�C��C���;��֧��q=to�b�;��R,�~�Pa]�J�/M��U°�͍��E���vн6л��s{�'�P~}"w�I�A���
-��ݵ������P�YqvpdP�u�;S
-���x�H���]"�/��^�� 
-4���6B�G�n��n�#��b��qsa���\~�f~.�-?���������&�`r���z}-T��<��˕��0��/�`�V�Z�l=,���5�p󽔶�Í#����Y�K����)q��@bq$�,À��S�=)vg�_���S�ﳸ7U�9,�eS �w�]׭������Y�_���N#b�[�(�})&�
-Z3�@���ma���`m+r�Z�}�\��UH�]�����o�NH³�8A�Y4{e�\\��A�ռn�o*�Ma�A�dI�린��0����h,a�p��D}7�6ߪ��s���$�2.3���x�9,z��+8�_>'�F���#�іí�̲�k�{�F.�f��<�q�l���^���o� ��lg�2L�&���
-e�َ;G�ŝ#�d3�t.l^U
-Z�f��	�A7h"�"p���ĥa<e��g��O˷��$��p�L^�\ �<LP�*�������p�r�{�ߗ�>s�x�id�����.4�A��h���av@r %��k歚�)���OZZJ7a�,��Y�ݚ��+�7Ii��:��<��-���s�
-�쎄�ّ`� �g�Y#U�#���9�}�	e�RMr�}�7�G��m���<$EqU��!Xt
- w��٢��t�R\��V
-�$à�g^��h`�o
-��?�!ʼ�r�\�t��ķ*h{��
-ÕصO!"���ԛN���S��V� ��� F��A�ؔ�CO`��pM�ltt|U�E6B���HB�
-��Ѓ�C){��4��o�;-)��`T�պu�ȝ=���Ov���:��Q�ch�����\�-q��l��) 8���7���������=lt�����Y/��Vw�*�H��Z<���@�?Q������V�hM�~��|[)���z�"�	�X�" nd�J�s3O��F�hŷAu=��o�&�  ��7r+���;h�~��2@+S�/��gSF&�d>�-�6�I��x�g��S�7��b>ȥ}�9FQ4��=z4ӣHB�*VX%-��� >�rWԳ��}�q�7�O����f4Se">i�+$6k&��&ʾ+̦y���"�^���୎S�}0�f~�D�K;f��F�RH�gyH���G[��d���j1=f3��>c\c�X
-�<�$[eʀdmt�`��\�ӣ�F�C��m:�˶�yhL�Ճ6��H�6�X��m��Y�w���v���S������J-Wu����߁��Y��<�SՐM�e{0���zh��a5O������v���WC�TW�]�ᔠ�+�UUp#�D���,�
-�̡�$f5���]���\�H��ꌌ���(oV�ft�8_�}�MٿB3(���lG�.���:]"���[fz�`�ܕ�2�hZJݏ��l�o��\��z���5����y���A����F$�+�b;Ve��Y��f�k"l���\O���o%�Y�d?��h�����L�&_E�ۊ��tbu�~�E�YHX���X�bz���� 8��:j��\�Y��gC��#�Vvl�ֱ$?y�4=N� �x��fbª��Ѵ�H6	��Ž={lſM�j��/>�r�+������M6W���✂�p������{Ȓz)��Y&�!�D",Q�h��/������	�և~��(.Ѽ4���1gf���r�ҒY>r@��#�=�j|I[�̤�x-�=�X�� XN�����z�*V���a��]��,�_>���� +��@��S�v>��t-�t�iN^�պ��+�b��(��2zM��{c5�eS��v�����@��^�*�lq����'L^7=J2B��M��q��j�q�Ϻ���i�6�P�j��r~�R��JZ��Č��&��`��̂u��)9�I`V2�p��R&{��X��銹�4��V���&Au�(b�[�2��~6�cT��+
-.t�`?s���Mr�C���V4Ӈ�ƽ�0�qV�KQ�;��=W�;�MLw��rU�;#�y�|���T �_n��-�xb�jf��t�郂M
-���;[\��E�Z]n.�{`�Y��R�G����jy��:�V�	�nב*��Y��j���1E��&�$,l��g�QL�L�\��GL����c@��E~�"L��=&���L�yE������ʏ��JO�My�������g���I�:@?s~g��6=0A���_{�M��s*LQ��s��0bt���ѯ�>ߕw����F.zq�"�����[T��ɜH�){�ᜯ���ב���p�j�"�(�o�l���i�yM�	5ȧ�H������#H[�����v��)75�h�coU�עp�/B�ӻ�4Q���(�c �Z��Bӱ��K�F���e���7�=���J�_GG�V�����wS�Z��\J�����=��A�U��?L�<�G)�7��8����$��Ou}�rR��R���5��^��o���H��j�9�
-~Њ�p˴:��/K���S#Fz�d����z��n��[E�I�M�Ox�%���i��u��P��
-�^�Ah�h	g���~�♋�.�������b��}��pӡD��5}s G۹T�ɔ�(��x�7�@���W3�_3ߦ�!��|�+6"���j��t(;頎��/"����!�+}�X BjJ��XdF( s������&��O@xt��I��J��/D�r&�΃[ߗ[Xi��;�r��y�E���L�1���ˉ�n�j�y9��$�6�v�n�`c�K_�0�Q�:&T�a蟱#�K8��ث�!��y,��:��]����t;ĕZͦ�*g��V�ٲ�-�;P�N>KuX-~5�^�\z5��Z"}ss�D������뉞���-ͥ���]��@siW�gw"=�\�͖O�q��.����ޫ��劰���e��a����N�.i�^��EKKi�K3�Fݣ���V��.���cXܤ\/?�{����]��J���uP�'�{�)�d�Ԭ�d{]{�c�]��[�����xD춈8���洷]�W�g���f��:je?k��K��}����"�2*�-��݆6�C��Q�%;eS�3�H�B�M���)*�T2�
-,�a��%���O� �j����z<ܪT;������4�j�g�/L�PbWm����c儉���m�=�Dys�a�[�۞ٛP�s��~z/,��r���Jf?-� �E�=�	��P���gǧ>K5�P���A�D��Z�I��)ѿ�ا2��(�����9�>�yl2���yq��>)c>�ң2Ɩ��}m"��ܦ��E0�����`it�T�S��uq:J����%��8R�+�!q�z'��ǫ^32EX����{V�n��w#K*��m�w =�m }I[ב.�s7c�ݎ^�6mkv�MjOg��2DsFXb�5tc`Έqo'�tn�
-�ڞ�4$��0���b����i.oW�@���V2o$�b�َ��GGs����*N���9�V�<�QYpF!<cdF�3������M3�L�D"��]$��3��^�E��'���H�ľ�WU��ӅC.�W�>���bu��E�'�ǖa6�z������������8;�"R�L$Jo��z��6�($�T�:'␷�ELy{���=-�aȂ��qv�'�[��aȦ�#�lݾ���(;/bں�R�(�w���犈)Ǯ�	ӿ!96�_�"�@|3�{�)�&*�*b	�7]oJ�x��誚@��W��ёD��� ����H��D4�BtuQ��
-D�Ej����؝���Y߂�Ӫ���-=���m��ȥ�Nx_�#��bM��yJG=��;�K�@r�s�Z�v��BKi'�-��2|I���G�.�YioF��߱Ww<1�9�t<��V��g��='�҉D�ۉ����=�$:���a{qN*n���VR���T3`Q�̢b?-���v4�������W+�a� �����w�;"xY-[�=���d;����	o�r�)����r��Mn�������N����ir��7�ύ+�'�� 5wI�k_�e%�/(�s
-d�?�ۿ������O�mU�Msn �������E|[m1�������m+P����6[���c�Q�}��ֺ�8�]�Gu���
-�)g����R:BD	�/o+.hok��;�Q�}v�;t�S�a�	MH�Ǉ�[��B�Y|��^~���"�G�7� 	U�G�c�7Þ�7�Gݻy��h.�kCU��q���a�@z�|r�'2�'ף��'��|C�1��H>�@H�S�1��;�S�H�8�0���O��m�Jߩ}*=*>�.h��q��7��D��&��~f��sX4M��7��M���H��\z/��~"����~��D������釛KB,l��S���"���l���᮳�N?1@�X[~AT�EE��~K�\��]���{�|�0�yncS����Q���D���q��DV�p�uV�Z��$��-�i��3D�,��y"�ߞS�|ߕ�<�3j�G0���K�,�%{f'ss���ɞ˓Y�Ku�/O�̓�y�a�$��O��g�q����d-yS-����v�N��2q/W���a����fAzm�A�& �5H�2d�� �C�R1�X�]�̢v(�oDp8��H�1�{�����8z5S����M�8��d������=��@]�v�r�b�d�9f��̙$s&�9uf�_ԳB�_������q��K��Nͳ���#0��5�b~�/F|�@��M�Y�@��*�:IOAgSKi�� ����A�p�ûh��<�}s���8�ms}I����b>�o�������uL��߽a=<P��"Q�3Sx��)�>��ծ���t��}Z�!�ת0PQ�C�x8�KqHd;gǝ��,ط�l��v���v`߉XF��U�������_e+��t��&����w[��w���8a�X�:`� �#'�^�c�^�~�=`�~�= �Ϝ�-���{�	�߂u��l_���{q��(`g;a�[��8`��f�	{��=��3��˃&�\�r���	{�;�{;`���N�I��,� �͹���f����(�z�����S�X<�S�]�8�v/�9'�;@�u�z
-�AV�$��z�_��^S�PM�$��`>7\c/�_W�Z���kl��b�e���r��`�_n�/��o���`\,�Ws%�(]����"ſ>�x��ϑP+��[�ju&�W�e*��~�2�m��r�\��8{e㌢}��F[#�Y�۳
-��ժ)�/8u/mw�I�;,g`�d�^�v̌�p���N�O
-"}R����o�x:F�������ϣ�a69��l/G�#��&��w�l��ND�z�#�	����@���|�YH�J��,�0��}Y2`v�J�j�s�#��:���}}Ϳ��oG__�����w���#�kT=�P���^���Z}}���V_}�B����$d�I�U
-�ނf���Gǫ���ytz�Ss@xt�9��9 x@� G"�C�A��� �u�6���qd"ZvnҘ�Z�ܤv�񮷍w��UלI��.��x������i��zZ��sq���U2O\}*�qV�����ɲn��å�w��m_#�ٔs̛�8	%������i��]ni���I/�8I��\eC$�BMD/��u�jê{L�����!F���R�I����������_�Ψ����Y�6��(+W�P�� �M�ްǻ�cu���Vq�o��Zd�Uή+��󭮭X]�f�7+3�*&Vմ~8X5m�&w�`w���%���(f&-�#�a`�C1�B,my�T���>nӘA�}� ��/(�[�����<	w"�Y�r��L�O6�h�H��l;�r��*4�&�bD�7?�#��dSUi�S�w>0��V9aR�ꭠ�[ �p����򽱀�Cl���&!���4��N^���E�Z���BV�E��z����[��Uϴ̫6;��:M�6��4����r���,*.|��C��^���5~�|2:���Z[��]��k�pϔ��w��c0�z��W��/" =`�.O��%a���kf�ݟ�����^�_HZ�Eo�9�;�Duv������D���8����8S���4BT+��3���&���R!����5&$�f߶�C���fٶ�C"n��b⬌�YvWm�yk9l��f���C8O���C�c�2���0W��&�W�(�\�3VZ��}$\��00�s����e�����[�^^��Đ��A.�i��r4��֠
-��:ٽJ������{�[���ZJ�±p�y��`�y���v�E���7�7� >Wo~|(�v�KS��~�o��y/�}C��T�wJ�����,n�4�mK)M[���ο"��*]����ze�UIv yU2;���ic���UIʃ�zӞ�Ո��� G��M)�K��b�׳";н �8��P�t��9���vI���ݰ=i'��� {�(�&�@g/;aX�w?�u/ۋ?��_�'=�I�ړ���ed�;�6r��z���z� @�ߵ���v��~�W���2�:\����c���;�����+���r��ǃ#�}`ý�^�p2��r� �P���>O�w��,�$�}K�;8���/$�~��t]���d�A�zq�٢�V��$���Rڎ��P��s���`y���U�a�1�U��M�ưʇ�ޓ��FO�F`�p�J۽����ӄ+A5�����K��oc����h��=ƥ�"���H�@�=��T�>�
-i�F��89
-)�7%��[�^T���OԈ<"�������+��5l��������^�kJG�Z׼�kHod�Ԑ��ڐ�eC��i��ZC���~|�%5�[��Om��.:��� ���> N� >�h��V�컥s���pF�C�t^Q�Pͣn�k��!e�Yo��:�/+!e�[Ķ!h;sLg�.b'؀^�v�#6��G0:�4o&-�M�A���p��#���ʲr�S��a�yR$&�н,{�7����u^e�����AHOfY�B�*~���@���X��hE�Ҩ�9�V3e�h;�w`'[�2���(.�ʹ���0Ǌ�^�Pt.��x7P�����҈�5��J/�H���N��݂��cS���94�-�]ז�J��o�_-B���p(wTYϗ�*�f�*J9L�.� ڽ����ρ�a5v���an���I7~���E$K�����
-�(�P� �B!zB�N!%��������L۰�mX����L����KE�$6wn��rq�&�v8�ߡ"IP�CR�CR�CR�CM�$���͂z
--�Sh���B��w���0��aR��F�I�A�A����&��3�8����!���EѾ��R��,~y�iЮ^Q3/yhB��(�����y�_�����f�`�ع�:&��Qo]X����P��xB��U~���MS���?R7�$��8z�:�f�ZŢ��#�H?�yrZ�V�Md6>W���e�ǗU���k��a�c�,��,&�� �����X�I��=[����Z�=0/�%�6�as�e#O�|�
-�S<���d��`D?�	��	�Ue���!K5�GN:&��I���p��^r'ݳ��(.1�L�=���ovП�^���r�Jf_H�y��"�_!��+j�1^U�^����*F��:�{wKv)���~�;�J�Rd�����W��R1K(t��%�U�
-����&1K>Qa�C
-�dM�s���e���������:�%�)�����|��|^H���S���LpB4!`�@�^�&�X��m,b.&&�t_6�S�A�ŏTs�2,�Aְ%ef��������:�߰��9h�aG��Feh�w��*"!�ܮ����S���?L����w->R��U�
-��}v���x��7�9�ϟ�h��J�{�b��}%v�L�^Q�=��ߕ��M��G�UQR��? �v��۠W$�6hJ�m�Z�?�1��C���?���`~{��Ϊ�6��֑�*A1r��nm�.H��M�D�zOD�q�@E��gF���
-*p�� Z�N�� *������(4�3��W�'���H���H-�W��ݗh�L�!	9�!���諂e��p�8	'*R>�o�Ž��v�����#�
-Md�:�&OL�y �>����V4��W��\�Y���KWH��D��jm:ɗ:D�)z����x-gװ��bӻW�+�iF��Q����>��
-V3+�
-goժ�[5�8-)�SO�U<1��� �����:Y�q<��SG�����ܣv_�)�<dgw��w�v(]�Uwi����?WQ��@h!��_ݎ�%�q������3�~e6��1��-�#G��Q�>U�;����]j��8>��h9�b��E�7����w_�,u#�����Fq�s�9Gq���"�x��v��2�U4@4N�&��#e�V1}ʹ�Zh(����7؈�0ss;�u,�i7�kۙQ��9*�9�����Mp�ֵ��]R�䦟���ɵ��[�>'w6��?���J����(6Mcwn�DUk�|줮Kz�{��;FKG�=�����AN�Uܪ&�̋I�W5��c;�Ċ���R+��-V���[��$��>�ճ��p����l��ҥ��.1@��M���b�:\]!O_h{����\}��
-�ۨ�>�F���n��NiL�in�x4a�	�o���h�}_��o�Ʃ`��G��e�/�p}f=�OD�]������������nJF'8[�-���a�e �G�����>|L���T�dd���� �Y���&?n�p�>ɠ+��Oq�*g�Ӝ�ڙ�'��L|��8��~����N��t�3q3'����ʣ���������p8��!��6�nH�ܘLoo.ݘ��O�G�K�ɞ����ͥ�ɞE���ͥEɞ���כK7%{nN�w5�nN�,N��4�'{�$���KK�=K��ͥ�ɞ[��Cͥ[�=�&Ӈ�K�&{��#ͥ�d�`2}��4��{��s����H�{[J7b��e�ϙ�9�P2�Vsi(ٳ,�~���,�s[2�ns�6�p�������f���QÆh�}�Q����	�7���J��V����p]�SC���L��=���̬�j�E�\�>��A'W.B�ոr�V����v$mk��G���d䷵P�G`�[	l�ly+�=�}��{<��&�H����z<�Rg�W��Ȧ�e����_�'�7N�y��ab���	p<�xpO; � �q-�p�n0[�Z�����
-g��.�s*��`+0��`+0/8���Poq��׎�|Gs�o�%[��7�%ģtk�����Á��	:���;�!`�:0?0A��9Ya�vowt�Iذ��Ob�F`a$v8��H�� {`�8�ث0��5'�������3���	�9���b0��}��L�	z��>��c�po$E"�~��k �>�W[na�y���~G��G����|�`�:g�thLu�M���x�1�eV�O�3�ڡ*cyVz?=����1�o:��@�G�2L��Z�i|�v<�/��M@����&0�	ؓ {�	�$��q���:�V�����	`�N ����~�ۀ�����}�{ `�8��B>u$=���I� �s'�g�Г�g6�{`}1;W�l�UǾ��Y�������u<G_��br0_�7�CL�91G�>�d���z`��9�����6�	�<��p�mؕN�� �����v�� �k`[ v�l��;�^�uN�v}�!Q��DY�L|�op&�9�Fg������+�z!��j������b� ��k0�z��`ov�\͋c>��7�߭�;\p�s�U-u&�3��p�I��l�nu�n�p�"17���9�s�,��#s�[a�Ã1�ѳm�MN�J�\�&�/��+ۺ^�+�v(�KSd��0R��R96E��:-��"�vZa�c�ia�
-��c�:�]����RZ���ؗ�ƹ"���WZ��%���RZ	īb��Wǰ}�����c���_���|M̱!_sl������_3w���]4���Ƕ��ț��70m�ũ���������RoMrꥀ��J]b�*"��Q�3w�#_������*t�=1��}1��:�����t'�W]�����.���Zd?�������]�{nO�?h.ݞ�#����t�gc���w��.��ާ�u_�^��/�̏���׎�����[.l� ��k]�5?�41��֎�+����'b�^�H��*��h�x��@�CL�� (z x��(�`����[$��Z���)���k�/�h0==��W&ӟ6�V֮mX9�'�?kq�+�������@�\l������>�*�9f=Wܨ�/��&W|��$[j ��E�� ����Vy��Ʒ����	��L���^�Kbx��m zB3���0<A]�����4�%!".��] )sESeE�lm��o�T�Q�g�UϦ/�瘭�J��o�������u����Nr���±7�L���N)g���*��U��V����\埉���K-7`���SU��T��V�p���P�W��ST�$*yJ��=�}���U��V�Ө�e����y<���9U�&
-n�|%��͘�������փ�r]?�4�N�`f���h�ʸ�~-�x[.�x�+��G����'�;c�[��� 4����m�����9�l7/�br<|{b�7�{c�Z��񤍃���SZJqT��Y{�9k��꽾K���Ϸ����LgJeϪ %�3[4׬a�#�)��/�����op'�7�Fܧl"���S�FW�+Z1����@�U���=T�${�J�g���T�3g�D�J{s����+��w.�i�W��2��<�>��Df�*<���T'�A@k='?쵈�X�5}{�;M�)��v��M��-�̋��' ڊPبꡁ�sux�o��EJ�R���K������� >�F�Gc��\�4ah&�|�v��dga���*��wxV��������3�=Kӏʠ��yI���r���`�x�������|�`�X�Wk$��	�� �����:n+�M�:�(����y�}��K�Av=(<\V��S�=��ᘨx��ﻅH����x���w�W�5��4�pK�L��[H��+��4�3��ЮO����Q{�UW��C?[�[s��/]�f��I=Q���r���X4�E�c�L�X�ŧ�jq�~*�p5]o�dfM+.z�S�i{Ij֓���z���r'/��Vj�	�RG����W<���G���S�J��ldW��>�Q�*J�~�%5�50EwEMn�x��=}�T�HQۊ�9q�-�=��7e����y
-���(�(�65�M���������Til�$!�����B�4��M��]7��D�],3U?dDM�M&�$gL��������
-�jգp�� �jt4�A?,�����-����6���q*qx���c\?h�*۸a?4rω~h���X���>_Պ�%���aڴz}ߥ�ͪ K��
-��
-�y��F��N�}[�X�]j� e��r��y4{	;��f����1X���9�����O��0p��Ύ�4ҋ�v�����-�Um���c���k���߅+�����D��[���DM��@x���V,��
-�[6%��*�kӹ�����PQ߯��{-uorM�M����eT�M6�>�U�4}XSQ��J{��q�T��V�G�J����mߎ���l�� Î�Ƨ�!��`�(9a��3�fc�Vш}��y�����/��m[='k-ށ�r�$���m��B)���)�8J�[5���.�״�M-�e��?n#qvܩ��i��~I���ߴ��7����8�]�-|6f�Ds��K��⎝�ܸ�T�.��KH�~/�c7��Jf[�Z\�U�4/Nz��1࿺һ=�Kø�Y�e8P� _{�^��:��\�]�����K��]�*Ji�� \����l%�-�	�oب4�A��B%����D�x�o� ��b�DL��TV,P)c���Rr��x��r�8�m���X�9:j �QC8�w5���Eh�G8hCX6��pvU�.�����6��Pi�m}�hx�jh���x�Ĩ�:��-��r�'i��˙����j�}��6,��k o�bd�(Jq���a�\�(>��Â M��n��f���-փ&� 0�9�-&�r�!�Un+��ʙ�����Q��6���J,�4?X`uXn��{T��=���s��\X�����t��K�Wt�_�N�����q��=P�
-���>��D�dY퇆k�3+��.��^�{��]�e#��QU��#al��������q�R�C���#CbH��r����-�@�8�b08n1q�@ Qb,�x���ޯ�	�w��sM�C��v���9�}s�#՘�6�q����c�X62�h����*u7�{�oix��NǓ}u;^�{�'4�]���!�ۧ¶�[���#��]����M�BS���n�/�)�)J�n�{ix�ǜ�鎖�w�'t��d���^��T�����a7�[Eb!":U$s�X��2�)�{f"��O�I��#��5��#�B��LF�x>�����hE�Pa�p;Zۺ#ԺU�u!ѺCV�cZ��.@pD$ͬ�@��պ@�u�0[���Y���jD�؛h`��M4��GjMTmM<�/���=�z}��S�����¤N�ݷ���>�Yh�,tt�u��(t�(|eF�,��_�QH�(|mF��3
-g��?�*y�Y���*y�˲��e$9�<`���2��<�߃즼ŷ�9�\|�~��]������7J���/��|@�q���~f�3h�[�/��kf �?�p�7�Q33Ђ��j�Zh���tL
-�:C?��%=����H�Gӣ���
-�z���^o����^����7J��n�;�Ӂ��x{��P 6=��p�_�=|D��d�a�n���ϊO�_����t��2��sS#m�f4���R]�����^ݖ��M�.P2�L�#V�^=IOt]=I��:0��`�r��O %�у|�W�Y�F�n<6����A~��&3j��/fY+���h1���6����Ѓ�K	���7��nrn���2c��ˢ@���=�F;��$;O2MY(�����D�#��c�����=�u��={�
-�Sn��#[p
-Mr�~z�9%��cr�9l�f��5攘ȋ�<����L���יS���!�P���A3]?�kh[���%�7⢴m�׶�щ8�kN��D0_w��'�9�	�p*Nk9�����������w��B�U��"N��O���� q�$���q�C�
-qڤ�(P-�/9m����i|h7��*�>f0����M���i������B���������)#8�ѧ��S3�Dui��
-��א4�����Ɍ��4Â��_��j���A�&3b� [m��mH铘����!i�,�P������WB�!�mh�eЬ*�@ھP�1nÙ4<��a����Q10�[��zs�l��Zޝ2o2�M����d>�J�T�i���� 4B|�3�&}
-CL�'T$DE�<�a<�Mc�k�`.Ԭ7��ݯ�q���}��J���٢7�oڽ\T�u���@g!�Yu���S�vj3˼A$��)�������f����od���
-�#g�$����k����=�z0���6ĩ\�H�EC�i���R�}���hw�=���
-!�ԏ�eR�$�w�+Zc𗰕���Ⱥ�t!�I�S*�j����g������Vx����y��{��Y�To�Rg�"�bu	���NS�މ*�7a�;+�P	�V%u?̹�/�D�I]�o�t:�
-v�Ӑ"�!�����D �=d�yYw�%wd��K?�� id�\��+[e�C��U�l���(lw�zC�5��u��Β�5�Z�>�ίi�7)F��{r����.^���nU����΂�������؛眂J�4����O8��%4�j+�M�������ȼ���,�8sD��qLF[�^6`��;�Fx[��oP�L��"NtPH�P�H�6\!����ߨ!k��rm��&6�V��'B�=-:��j��q�=:�i���4�����	��O���@���	݁��N�.�@Wo�����]Ё.j�������/�~���%���)4��$�i�E׉�j��S��8#�
-�1�Rz��LV���?��j�c����*��e�����ݞ�Fn�&a?�'�)w(?�����U�3 z�;���-��7���؍N��F�
-#��?� ��SbC�����'�lY�,��}F�TƆ%?���})���uX+6�œZ��K��*�k�Z�"tm#�Z�����LÐ�Uׯ\}�*L�($�'�?S���c�sPn�����aP�v����P���|_�~|���#F%����{��#�� �(�6{9���j���� ��8�0�	͂�Z�0���?��zƏ�8o
-�(�
-��ž�l��qrqv��Y�F3R�����K#րN.^:�6�����7��y@w�z@w�P�����bBK�p��G�~��E�G_�ޒ�ٮ����qO�׷:bS���X�G:���h'_kh��m#Vi��l���۵~뚁!cP��pT�G�Z�RJ��(�sEyZ���1ǞV���P���a��B����'�9�>�g��z�k�rk�Ѝú�^W��U-�L:��������'l�����ڦ�*jlZ(�:��1��ڎ&4�FSpPB�aDU�z��s�"�Hz��}2�`\��^�s�O�i0h�j$����A^`kG��2�NU���8;�G�����>�q`,u�����oD���(�P�c�Y>���i-�SN��9�����?*��h���b�$Lq{���Q��~FSl�e�n����A���S�=I����Y�Z��b0����z:\c*�p�a�3p��[����A;��8k��h��3��Ήإ}Q��&��mL5]�g8���tW��)��dEctt����Κ�>�a�+�i�O��;���ئE�6-�������0��<����:,d�<�hZ����ģȍ"b���b��$��F1-fҴh$��nh�
-�LF6k�Dʸ�v�x�.�s���kg���=l�80J<��MV��s���Ƣ���̩��靜~q�gP���%��K8�>d�B\��Y+0��ПaɃ��Ǻ_!����U���9�Y�J,A��Y��g����U��<��Bu���&�c�n�\�9�,d���M.pmmr}Q�b&��'W�c*�� ����z\H49y[Z�D���������΂f�,�9b�����4��~��?~�/���Z	h������-9X���4���)��1lͲ�]k�a�Af�{Pȷ'��#�3�Ȭg�������U5��z��eL5�=�OI1��,�@D�ثW���s�U�Wb�ؒ��D��c�bo�a`J�A�S��).�f�t_�^��짣��R�1J�/���b�-�8l��PbV���l� 	C[�e�,���Omg�av��ש�}��CH?C��&-m�^�&J���պ��6��Y�؊�.밊J����]l��&�Ѿ�7��l�Ṇ$\�/�8x��|IdB=R��#���B̳��Q�ΣGj<zd����߂GQ�^�G�1<z�ƣG����<:,��q<zd"=ⶠ�5�G�"�y4h�Ѡ��ّ�<��h@�h_���ّS�h`�����8/,�y����q�*�p�p�����L�\���j�3�br1x��x����{���B�å�E]��.�V�K�x�F[5
-�,��^,��^(»^$�{�I��"�D�xp��?�+��PŢ>��jK_��}7|��#�p�r�.]e�!�sJ��ɦ������30��&�`7����_�l�3ӛ�����I���ӿ��7Q����9T�W`)�3�|'�d�5���z�fev�g���A�^4���A�	~bu�'JoS8Xz���J���p�=���ާ�Z��)}�����Z꼂u�-�Vgր-kЙ5����+<��oa^��`�i��6�����A��b������U���b�9c�-�:�P�>�U��'��?�f�e�)i��8���_�D�f�m�ٿ�?�/i��O;[��,��r�n�sn|���[��ڭ~���ģ�A��WI���,�:H-^ݪ{T��G�S�ʷ��U���~�U������;H��	K�,���<W��	��D�|ʑ�^b]�v� <�d[#����S����u��ׅ� ��������+��<��ec���,rO\>(�]�[��8YZ��Y���_�K|���7pq��c^���,��n�����#e��:Ҟ�V�*U�K�(uokq_�,+�H�\�)�_�%b���h��@�])g�����]��u��ƺ����2�s��ݛ"��k,��R.n�t?��Fl=�^��s��P̰b�R��U#p�Wg�׷���d�x�/WiY?�V�l��L�E).�����s�Q��(wg2N�D���p��)���������@�6�9:����gd�lQ2�"
-�����{��+#J�-����CS��+��|���	�e���c/�-��ʝ�c��/�W���];���/'}_qcu�0<EP�AgOkF�a�X6���G���{fjd~���:I[�O�~
-O�E����"���m���rq��/�J�6N,WELg��jC�"|�L��T#f9�y0�;�����rG�(�P��(�p�v�� <RX�Gm + ���
- �� V�q�txÞYq��C@O���?e�F�e{��8��^�,v̋#U��1|+a-����Y�dj;�=Me�xw<�o\!�)�m�+n7�⪩}Ӈ+8����Z�fU�_׋�J�u��Z|f�֔+�"x����h���\`��^'K,��X⩸�Zw�~�������yɜ�T:���}-\>!��SfL�t}Ó!$bY�jhJ�4��Cw|���pk�륽'�y�Q�]7i=�y�L���-F������m�!��9�m�m��O!����l)���/���ɯ\쏠��[�U��I�@�ɟ��z�e���ĥ�3�Y���	6�6o�^� ֓���^� ����T'Yƿ+z�\4'ڻ��1@�e�E��㚤4�*�a,�7����g{��c5�o���~���Nr���<5>���k����v%��MPm�����bm�U����[i����6ĲC)\E������@T�r����e�D�HS�\o�ۍ�J��'Z]���Z�BL�N{��JdF�2�2�]J|ՙ�X|����>%�m%F�fډ������)t2ņ�R@7O�rq�X�d����Ζ"���ʖ���Y�@�^������o#�ӏ�yOd�IP�Q����48K#��3��^�6�9%�ƶ��y1�z�m	=�y��3.P�cb%�hK������н��a��$dq�e�������q��el�o��[����q���.�fz�1=�����r�'F�����`.@�Y���o�.X/��\`d.P�w�f	�?F��3h�y��7������8hf�cX�����y���&W�%�W���g�����z���<G���-���S��F%���'\�����"�i�ѿb�����3�![��8���M�~��|[)�U�� 3^|1����ܲ��+&�*����N��8<�5������/m:F��/-~����l�Q��=뤁�6�|򬑶9�G�i6U�����o`ʀ���(x�q���%S+����W$TH+�Q"��l�P��ߵi� R2AE�%YYe1d�*�
-��/���i��H$��a;�?�=�׷��G�ms
->��O+#i��Ioj+Dk�R��h�B�?�z�z��+�Q��vD3�R��(����ۗ����p�`�3q�}^�W�py �	5|J1�zΛ[D���+��B���t�z��C�kqm���<�04��b,yd�==�Nڝ/���9q��9?W�_+?W*�v�\���au}&n�ϩ�z��i�l�
-�<����mUf��}�R���zГ�z�m9ڼ��v���>nw�S�af�/M���~`�%��G��y����4�3q����K"U�s֘����~���.G#���W���t�`+y;�h)��/�~P+xg���;|!tĞ/��4!G�ǭHB(D:�]!��X�t�{2�̊K��-����xh�Fdt�tC�H�H��H��`���EjX�s��x�j�7/���-p��PR ��%��	��ӽ�O�g��c�����Cʙm�i{���+_���ԭ�W	h!!A��&8�=�|O'i�c�Yy_�y��݊���Ϟ����7�"�̎�-lX��m�1 ^�w����$̾c�x�}�����B�d��~?ݪ:uj;u�Tթsp+�5IgtW%�Ts[7��B]��Ig�@y��L#��+>0r�)�s�rߜx���w[�Z��̳�o�h�n����Wv	���+)�dqާ�ƒ(�q\&b3��!#�Ag����g��6��MrIڜ[.�m*��L��F�l���bR�-W�s�e��2���b� �C>��@zg�M��Po=��Uac�c���+�3���z7� �Hf��y4�����"���K�\��*鳻��>T(>\h����E�q]S	���"�Kd��"�4�uc�1o�3 sM�;���g-�֦�%�7�"a}�p{���خ�C ��,R�A�N�(#�"Uj����m�h��H���o/������,�{[oE1S�L���N0fΜgq{=��=]N���r�P�Uj�=Z�Ȋ*�����N[�WΧ�E\��;R��I�d���A@�z�����7Y�,���%�kUؕz����^� ,���3P��B�Co�H�������k�^{_���%?MD�~�v��R��R~+9�˳��ly�� ʟ�B@q���XmG���U �Lټ�6�pZ�o�Vj��*���0���BDe�.�խ���cԘ$�M�I��g�ͻ֫�{n��GG|�N��1�ݐJZU&�i/��]ji�mwZy�v�>>�Pf�ꢥ�̤�"MI�ۄ [�P���hF�f� ����P)�aG)���r����HŒ�'[%������������i���A�"�ăf��<a#s-��S��Y�XN�)91O��%��1��D�b~�ǚ��%��8>H7l(�n��ҴV�R�X�ۣ�����p���oUhT}U�:������w�q>�c�n���p��b�R�ҍ�<���/[S��<�r�s��k������q
-�r�u�DAD,�=X.:�����"�Dt[��,c*$i�(Yȳ�\̎Bcv�*���TA��[Ke*��C�ZR�����Ħ�ZvJ�AE���Mu$p7�n�t�G�{,��oG�Vj�-�3NZ��L̄��31����/<M��i����^�p���dZ��k/6X�-%��`9�f��L?�;�j^	p�eq�V<��;���$@�=o,�V9��0)��g��9���
-�in)���2�4��Po�"�SsA�g��R�.8(sK��&	��������6�����pr��ʒ��ơ4�bf)�mp��!	M��t�$�#�uV���/i��9���`�:�Qņ7���\V�^h!���!��.o��
-qQ?��.;���0�ʢ��"��$�s����	�X����1�J\/f��<���a���`�n�I��Y�!l�7d���+dR㈘�F�\���+�T�^_�d���Q�y��c{LM$��h޿#5<��i�'��8���xQ�����<����,38��ro>m���]�J���ځ�Vgޭ�F����g+���R�t�x/�8����dRs	���D$���c�ep$1�O�u�x����)'��d��9p�b��k�e�g��im��Jݠh��b�v�{�[���4bo/�!n����������2}��L��-n�N��j�s��7;��hZ?��]�@AW��}r�AV'�s.�����߈>U�s~��[��Y����6,�h��,�c�O1=>d?�����9�Z˕��Ma��#>@Ja��ԭF_"�a..��ӑ��jq���7uVmG(��N�P&�s�Дל��H��ru�x�$}����I\|Dv	If���wU��!���.?��ZHOsaŪ��1�aO)�dUl�^�!lI�|]�Q��s8�7�;Ќ!M��U$hԡ����\>�e�.�+sJ#k�;��^��:�^�V������yA �3�����E{�I�d��'���1��$�!��%�9X�(��=}�lύ�L�X�3�*5\�Ds(�U�9F��ڡ��:���X���f��f^�n�c`�K���:��Ř�Y��#��0e,�d��],���!��Q ��:!���i�IC}#� �����1��2-��
-mLPZ�%Z�qx����8�v� �U>;M���/٪�dʍ!PI�u�5G�ʒRaA�豇B���ť-YBY\J��`�K��n����x�L�͵HgG<��T�Ng���尙
-ua�&������=��<TAZ���T���A:��T��Bq'/��c]ۭyq��'��x��!i	� E���OoO-!�}�iЧy�4�pHh�L�+S��B��V��jG˫�.�N�R�9��V���擅n�{�@�X�Τ�r�?k�<��'��~����|����I]����r�w�`���A�uD!�l�J+�J����`�[h��B�ߖ|��|�l�u���}���is�e)bϾJE26��s5{5��9<�[��ݨ`����՗Jqr "
-v4D�(�'�F?w�㍓��v�q���i��V��2pz��r=.;���x����#;|���@뜎�`<|�(�$mՁ����XG�P��9�D� j�(��(�5��=H��khk*�=�V��@��4&5�1єi��=>ezE OɕVWka��1F�i�V!��]�Y� ��םR����j����V�"��W�/�"�����s�������0�&��`1�/����&�?+��w��s~C�inv�|Bɳ��G�O��raQ����`�]��<��ˡ�4���]���Պ�,�����K����Չ����sX'Q8c
-��n�)�{]��l
-w�uu��~ؽ��ȭ��V�����Õ����V��?��a_��o�}�ۮYT�(�~�B��<w�[�Y�P�c���}�M�[���7Gu��m�g~?�?�c�g�*�Xp�Ȏ��W����N]�˻y����8��������[��K����NC~���#*�^.+�1������GB-���!�XZY�;F����@HT&�C��tk�c�˲��v�q&-n��Z��x؝Ƀ�@�2���<�mܪ>6$��l�������k���׋M]��o�_O���>��`���%@�"��Y���F��c�}K��yw�MM�ĵ�a���9�/ a#��~sbʽ,�{)r���oj���r � �r��R�P×�e�%���/#�J������;��6�tcb���e��	8��#n��F�����Y�@CK%(+��0�lr(7f�\�.���J�FcV�j�5z�k4���y���������,.���)V�V�q�S�nh��~�}������n�1�~�e'�e����S��H�=�c#9ߍs�y, ��Q�&Y����I��k��K��c>�زh���{� �����T�,����dm�����!ḡ���5K�9�TWJ�U�R�=�B z�����sc����i�*���O����.5�����g�U��5̲C��%�k~[QQ�ֻP��=�C�V��|�P�>�=60IXq�/���J����9
-u��[�Rs�����#
-���gR&Q�_T��U�!D#b]El]�I^I��7�]M:��U�E2�R��x������$<�v�� 8V8
-��Q�_E�f|��v~��9��&��&Qs�(ͱ�/J��J�U��^�Գ�J�.+���J�(�~��Cܤ`�A9n��N��R��$"Nٲe�!��9�4����PW���D�hZY?,���놥r��a�v7��Y�&$������wXw[���M�)�[�,LQ�.8�I r������^PT|�������x_�[�]n��b"��M0����8�		�m;��4��1�a>1;�T-�,w��+*:v�ITnq�/��,|X�ƾG�Xϻ�����}?0	�Ҍ�S$��*+�^~f�J�  �@,��A��š����-�do0��W昔�޳�&�z�jD�t�r�-ox�-����	�9��)!)�e�8Cb��� ��"�͡'�N@��P�e^����u���+�4�nz�ef�o1�"����w�����;��n����[wZ<��Jr��):}SE r�9�!����r�9�!ks�*��h�Qr: ӂ�5l�o��J�6�.(��/�D�w�dU1U�w��w��0,r��ie�;�i[����E�����=ޔ����0pZ��f�J�P�
-��fl<�c��$A�D��]E��E�-������jS�"{����nJ�/w�t3K�헉��io�ڝ�c�%jt����_�I�+}K�@ByI��]E�� �cU��J��G1b�,*岱� [<ީ�W_#޷��)�eaC%�m�����t���E����rBD,�`�(�Kl�G?_�����#�c�q8~��,���%&��_%�*�q�N�t(��h�'�A��2:����|'�2�����R=�
-=����"̴�����z� �9�4��4 �������7M��d ���ȵ ���-��i5����M��ɦ��J�)��^T��O)z�l}& m��);yf�&I��sf6ϙIƜ���`�@�)�'��q^��0��Eތnx���T��T��M{�A>BL�̓N~}qI�D/��]F'�:Dƅ�e<�R--Vq�Fub2�U�1H�Ҳ�<���LV���Md�������&�|)����Y �}&u�}���+�濭���yf�L�W�t%G�&� |����"F��vȦ� �tD ����+�Ք�y0�6���pϗ���(3{x�BytYn�;$�DYxH�۫��ۊ� �n�L��9b�9���"��v�KrR޸�Ҝ�7�ɝ�`�#+獃�0~�?��ς�w�
-ʰѠ�M>��I�M~�3Y[a6d�D�����O��[aZ2������z��RE��\8�F�:Ī�h��/�I%�L: 92� Ȥ���H�'q�#���
-����` �uSQ�g�����։+��`��?x�*�C�9��d8I��d��d�¤{a��7!	2��&�WKV:+/�}2���h�ď��f紥C�O�X�,��M���L�"$m�����o<W
-&,KY�ϵ� B~�X���:��U'��a�0�0�Y��2?d����+�$D�pJ�.�C���\����f\J���"UX���n���Q�d��~�J,*�v����R47۵�ܵ���1������J#Z�J1� ����~-4�u}E`$+�p��,�	��,���dI;?��6k~���\(��e0�U�\���m��D;b+x2�gE��P�2��tg��of��F�:�Aa,�#���
-���|qnr�]XP�@�b��'ף�'��%���X�ҿ�I�r1�?C�F"\d�b��0�������g��mcB�iW���Mi|�a����@�7�}�ӝ�vl�qm�p��
-������pB�T�y���o"�PxӅ�Qn���������e��|�M�$�}��|j�x��'�<{b�l�iM���o�+^%�0���a���^YJ��4"�P��|n�������s�$�0��]۰��jD.�<O������J�rrh�=�`6�a�0vu�;�����m����=o������R|R#�B�!����Ћ�zq�85�+��n����w����u�Wn�<�'|X�ut��ؽ\,{�1����9T����BnbM��� �kN�kz���"b�"(���z��f�#kw�[���W#���~���S��:���^��H�Nз���\ۺ�\�z犳>^3ó��*\#���N�p�5�t�|�0��5�BAV�8��ޔ-�ȴ����"�NI]��r����T�,"�~	3����g���3���|���b�V��R#��n�x住�Y��=�xN��t%}k����u�UJ�l\��6�F&L�6�
-��Ԫ`cg0dIuWC���`�+��-�J0�r0r�:r�:1#_�������7������56A5A�R����ù�#�ϣ��c���n�U7��!9��y�8�Z@	�_��{��������խ*3B�B׍!TOHI2�q�ǵ>�F��;�f��T��챹�]�\I���	�<#Ds�����	�G�x�����!��!u|CGߑ��i嚻afȂ�i
-}�����l�,��=F��z�i�R�%����	��yJ{8��չl�z�C�?�>�>����H[���j?sJѿ�yl�O���7{��<Tܦ��/h��b� �r�t}�S������/
--�ǋ�T}:���A���I��VP���}�}$�[��'���Kn婒j�Ij��M�
-�'�8eq�2�	@h�ix�Ï[���*����TU㏆���c!LQ
-���>p7|@��+n��>����$�^z"$Y��)���h���ZT!��P++�/~���e���\�HO+���b�[MUcDT1�ݪ��$�'��7�Cձ���_��ƕ�;�	�*>����ޅG^vT< ͢��Q}�Uz4$َK��${�t�'�o1.g�q1cZ9CCZ���T�HW)�|�[�C/�A5 ��=F���8˂E�7����`����^�(j)0^�մ��B�]+��tpTG9�oy��N*D�(i�Ŝ\b~57Zbt�[�H�9!|��O�����S�8`7l�
-��s	�*;L`s�:>e����Q������N�=�#e�VP�VZ�g�~��z�-	��m�O�6��~�d�P���^���ub��xg01���j�_��C�:�k���t��i��*��U"���G �s�¨�b,�wT~���O��^*���|{dEut^H�񺿀R�F
-����52����iFs�a�yc�~Ve�G��u�Oܖ��a�eN�ck�0?${6_�22���;� $+τ@.Б���aʌ�Bh���b�=�!5>���T�l�z|�d�Ӭ�4�E.�1��%7�T��T��恬�~�I=vo9��y�!}��Z�B���*����Y8��W��p�-��"�g��¶ն�.W����$=fQX�qIZB��#=O��&��eҋ!��#-IN���\.iYH*�K/���_I�CR�4Yz9$�ؤ�~����@�v��:f�G�'�0�p�V/3��\f�z�p4��步�3Ofh�ь�	�m���2i5CD�ȍ�����9C�'Q{nlhu0 �KUy:T���Q��� T�\�W<�5Vn=[�3�L��\�I)������7�D��z���feei�.3��Y��C�����ko ��+c�1eZ��j�?\�M��o-5[���{C�#�l�+vG�n�*5��J�"�̀di4�4<�e�M���Y8M[R:i
-�p�� '.a���ԡ�Q/�E;�O�$8������S�x(\90g�
-��Bd[�f����!��E^��`�Ӫx1�2�%w��ú@���i�Y�=u}��؇���5�	5�xK�lt�����B�����*,�<�]�%���(ꖍE�,�����g�{�m�}�g;14�{��G1ԥ'�N��6��^�<�G+��Y��[��8����UT���.V9h�]v�"��s(�i��{�&I�s�2�Rs��k,t�Nl�%�Al�%�IlD��c1捔#��:�՝[�P�5<i��;�������� (/.�f���q=a�́����N9�Zpu��f�Ԡf�--pxRK	n>���*]�C�%���m�4�k�o� �d�y�H!"r��!^��"�]�Ӣwݹ8��2��JϣM��T/��bXt"Ts1n����e�Dy
-w�e�o����!5����,df���>�'�5���I�I�\�kh�B��j�5l��*�Z�%�5����:��[�'�-����ԊĮ��!�aC���DR��2�}��4.��Ϟ�4x|1�:I�M�F�Qh�}ҷф���^�~����-��Y$Y�6R��[��Q�ظW��#?�,(}�,���Ƭ�7�"���� �3���^�|�6��<��t��o!}��B��ګ�W�� ��4[�HSY�&�����K͊���P����&pI�� f����I�a\��.�t_��6�ӫ�Dp9�Yl��ޙt\�O�lupv���de���$&�\�Äh� �օ����� [��׍ͻn���Q�.��~�a��R����4v���G�m3�B��*o��2Y]f�>��d�[h3����4А���Вm��r�&m�4��]u��r��5�T�m\��<��6��)�Gѿ��T��w��)���y�9����r�5���E����Lk�g~;��	r�F���^���[��7V'�^u�wP��1����2���%s�n���+��v����1x'�\����nq8F�������>��;��E���!�cv��of�G�~��Q��җFĢ_�p���&��A?ч<��b�?|n`>U;2>1���~����n3�6c��c�98͓�Y�}3�$�Ѯ��Ѯ�G;�=2&}�ϫ�S��.&�<�?���nړ�q�Qp�s�v�_�-�v����#X+���?]Y��d3��&;X��0�	^F[fS��'�E��d_?<\�\�&�]ɢda_.�d��q�VT�}��g��0�;��u�@A��W1��W�/�g��5���Ⱥ��u�|�Ʌ�;���H��=-�n�C����7%L�ƾ0�Ļ$ �ER9��έ��Z�[!���Aw���9�je��Z\�^��;�}LYWq�n+����1����z���	U/����1�PM����$%4�o�&B�y( �������L�@��7�F�TQ���nD���ؒC8	�hs��U����9Ta;���Mj5�hi�ՅS��=���[]ʱ�l���0��.�2���j���A�xV���S�)=i˥3A1j����2�v��{{��MM��L�k`��c.�V�,׃',��Q��CB�a�'C��n�=Yc�ɥMi+��4��Ȭ����!_��XZ34[�L�b�&�Hݛ��qM02e`jM�qm02m`jm���`d��ԫ��ׂ�YS�_F2�����7pQ�F��M\��l|%o��d]�q}0dO�Ǔ�I���H�Ll�g�����I��R������4nk=����I+�=񀲵"�<��=�L���"kZK,����@�V%�T�X�1I�B�En����4%ఉ�}e�G���2��j��+�Qc-	'S0��אU�v��Q2����YS=x�Uj��ۭ�o�̺hz�^�L�N`�WŦ����Ѓ�V�P�XQ9X���`�z�(1>���grty6�K���j��g`t�Vc>�- *X�J�j�GS5BFMC5ψjR�Gs���Z>���W�g<r��l��B�=r=�a�X�~i����Ӌ5*RMk�a�������>9�-Q���Ѫ@��E�n�Z�(��iIǟ-WvV4,�{��� J���gc�l6^�Qs<����E^��I�B�*k�4݇�Ͱ9�u�����D��-�{Ԇy�~QԚ������jLK�!���?4����̐n-�R�C��-Z�'4��X�K����x��A��V����|��LN�eN����=$�d��|'pR�=��8e3M��x
-e�㕃���D�m����W������M9L�ez�(G(��G\يB��Z���=
-�IG�h�h\�c��U�7Op@5ݒ[q�%E���>�9��@��Kn�r"�8�_��P�dA�\0�o��=�/��d:J����&��<J��.2Jd��<J��.�l(q���s��9�������·,xy��R�S�$�G�����û��q���2�PZ�N��<T³ǹ<9�&G�>9DKy
-?ͬ��0f� Ø��D5H��V�I|\Lb`����ݱg��Qϖ��ϖ�h�A/|t�z��g�L��y��,�!n�G��a{F��ϳ�}X����ʵ����f��aD3o��y�q��q������<������]9�����y�D��P� ���.����c'{�K!��vq���O�y<V�-~�)V�4�~Ê�D��"�Sl��u����cc�.���J',{dn�2�}�Fׄ��Vb���� ��uc���U��"/��n�ߤ��n��R��_�G�[���������>$��.}D�]���)�N�El6$��h;U>Kw8c3�#+jTeQYd�OU>��Ф�r7WhT08���͑o�mL5�5��:�,��Q!��(K��oi�A�b�DN7,�H�ڤ�EB�@�6cZ�Lް~?�k�W&}4$�/p]2��}�`�,cY��MqGC!����{=��V�L�o�J���:<2f�&�{�݊=�9�jn�V�ـUXv˛������9&f�N�Bz�z&[Q���0��ˮ�ϱ�X	9�#����LO�j��EO��S9>j���fg���-��r(��r(��r(��r(��.f��y.�n8n߹ɐ��3$�L=`����7���������J�2�4���,�`��S����E�ٚ���[���y�'�����5�?��_����OeŬ���v W������ݘ���xǫ5�v�[�w�wk� ��CJbQ-E����ro$�y[e��!��@n3�r Ϟ�l�;=�Lj�U+��V�)l��Ԇ`�Fl�67a˴	[���|G1�,��es�q�l	6nE���(&?�j��,ېe[�q;�l�+��kv
-��l�aW0�i(n��|���l�m
-�6��&��#���K�k`��!cl�}@�6`w��K�`��{��bY�V��"kj��B���	�6W�|W��'t�����d��_V��<$Q��P��&4ioir�C�Q	����(����y��NgAlg0C�֢P�ی�;��LCƃֿ����A/����m*eO�M~��WF��$�6��A: ^ �8V�Y���W��ɝt�m;m�T�[l�i��M��m9B6��B���ZX��RM�6����Z��!�;~��0|l��j��%����3+
-�@q;|�S���V��*�sŸc�$�n�@I�|I]�_D ?Xk�$ɲQ�7O��+jqҝL{�U���(aS0���y��,�W=��`GӀ� (�ɢ�A�cR�ǼI��,���bD<w��w8F1aM��@�5K�� �u����j(3$�d���������l	Х>@���I����7�[�*p��JV$����,L��0DV_:�9�4��1W�%5|�o�z7iV8���v
-�6��g���'�؞`�p���,���=AK?�T��;��u�<V&=Y�S�&oқ���r_�6�
->#������[�؀�͉?85SqO�Z�*�gh�?/.����}�$r����f�ꑓ��w��wXk�������7�"�u�M�ҷ�w�wJR�`�"V�T�U�$���u��;� 0`�u��GE�G����?S�n��IGf���櫍<WQy����z
-��]�z˓�|^Y�[U�GӔz�~��{��=�{�����}?檍즿����N�_;�ޣ�B�;�~oQ	���,��ZS�Ni�)�L�ͧ��F�'��)��.�@�����~�Q�����z���7��[�[G���Ky��o.ʢ��s�~'��1����2�6�F�=O�L'��ͧ����0�=C�M���E��w��W������vt}j��|�F���7�~O��)�ͳ��#���Z��h��^�#;jF$#;kF,�#�jFtȑ�kF,�#�kF�$G�Ԍ�$G�֌X.G�Ռ��H�&�,GԚ��V3�e9���B���R�tՌxQ�t�w��J��S3�M���)GՌX-�����[�����6O:~��8PJm爽H%Bq_M�������t×!���K��)�g�ʕШ����Xt��x�$��;R�Udr��E�vy��N�9E ��T����Y�y3wx��wo�h�]�8�Iż���B݊�ԧ�#��E�V�'���ؠ�ā�A��y���!��9O]�!�l$cw<�e�	e���!��_*e����Ņ�X/lY1Af����PV�	�c�A��g�9c8(���~���v�C5E�Ez���	-`^�7sw��T�穆�o�A<~55h�5���U����~{ ��"��{<^�"�Z�Z�&��Ru�+�%��v,V:�n�N�{�#T�_l���:�5Ε�.꽀�����bʎ��oʆ~���9�����%�EwKL	����n��W(�vs3�>c��\�B�W��],.0��\v����*D�<rA#�p�B�b ��<YO��Pa�=��F�5k7�Vl���X�m\%�6P2��%@9)�cy�e��� ��r�Ј�IuB#���v-��ބ7x���8}kFI+(r���mD^ۆ�m��m�����l�0�h !�˷c�ԝE"oO~�wQ��=�xa�?�f�cKʵ��c{t;��xv��tݨ%�vB�F��JH�g��#�� 
-���q�K�G���"�sD�dq��Y�,�҈}�3܈~Ã��Y'�Z�>�`��߯Q��N\�ij�c���ɢ�Y���ֈ��Pu:��$H羟�� 9Gz�(7|9����jJ��	��'�	�סV��|H+0o�$mLW�`���3&$V���Tu�t�'ۑ �%OBg&Y�*�;�01'��N�:I|G�S��3�=&���gNI7f����/ˍ����#����^ck���I�Q�*AJ�VD��9�.iʈF�79)���UJ1f.���,����������zn� �m$MT��~�C��M��t��I�c��)��C2���P����w�0���odwD��彽Pu�.B��X�*c�J<`��=�P�o�4}�Q��%޼"K{{�l���.��߅��f5`%��_1�u�'Qb�j�U�m0q��@�/}x�| ǬI{�*�6\��wumõ��}��`�_�~�y/3�Z?,�" ���R�a����!(�/��Ϣd9{�| Og�q���1}�޺i��yٺ���N���r���ך<\=9\본�p��)�W�p��õ!��`׆��z=�!^��l���&M�;�[S�!���yX��U�!ZSo��H<�m�7$Ӄ���+r�F���0�e�<�;v�Rc%6���R�>��i�:��z�"�&K�n�X�w��(���?�h�Ca4��v!�~�`	"Cs�*���G}�.C�鏊?�t�/���@=�D�ѱ1o�2��#��z�Ϫ!eq�G~�M+q1~<��$m4
-<�^�yt�G�n��C��f������!��U�!��ǆ�|4�GC�"�5��@�e�}�x�+�n=���xK������K�h����	aܬǎxtr2`�9�Rݼ��'��9Q9Y�*����1��*kkw|b��[*�/����~\���YgO&$%>��Ee-AX&���/1c�|?�bO��wK|RX�|$�o'��0>9��OW�wz�l��t��p8��J����� �Uu��(�Z_�Pg,�ׇ�0�}ůX�L8�ǏO(4��|��=c�s�[�7R��S���~|�.~�]9W�[��5��c��B�+хxg(���?>5���xgXd�E$TYP*j�vBX�؋���%����SÒ���xrX��Aj	K�
-iZX*(�&�%�r�4=,�ʤIa��x��HX**��0�Ǳx����B�]����V{^*��k< H����z&�tz����[(��#�]�1�Rg�P��N�?�*QW��tYFˣ�hkt��U�h�\VOGy���7�m��Ǖz��1�^bm2v���d�����I�q���rL�w�\�N8&�ҡO�/T�8���>n����6�ڜ盃U|F�ts07��i�{q�=�Ya���&W�Vzb���9\�=���૞�l=�_��y�OҋM��p~A}b�G�;���>�䋜�I'�c���`9u��粇Vv>��������l��'$Ӿ�kO[���e�l�
-��6G�>��N,��N� ��.�����I���Ć�8�;��i-u��~qJ�8��P+����r�W��Y�,��U��Op�Tv�U{����JY9XY��ÍFy�@��V�Զ�H#ױ"5z�HV����u�HECP��TjHZ���{������ZY�����-U������U�cS�+�.VR�F6kT��$B})SLz��I/&��ޗ`�H��2���%�T�#冧�R��Mlw�=�۰f|WY8�p��Q����c�d�QɆ�*��}�Z-���Ϻ�"g����+���A��m��1m�G�����T�'��ە��̻�w	G^�o�Ф���l��Iǆ�J6T�~�
-�yx�}͵��p#',	]���J�mP�1�		Xl�Ez�u=&Lb/"��U������P1.�G�X�js��n��|�2}*W�W91bxa�ѷ��w2�4��a�/$RW=8�/��#�J}n�!H,��1�w��)��ޜ�{ʕ�N��$��)��1���}k����8=B��LL3�3	�"V���®iZ�����^O��-�ab�s�z���yt�Tw�����Ĭ��|����nOoFa(������4��V�Aj�n��.��#�7	����N��xXS";-��?e���م4���I�4���o�<�u�/��6����i�W�wZt������W�j�st��4��������-e�������ΓS�.Q���0�#a�:�MPc:��KJ����m&��L�Vl�D#6��*O��'ȴҏ�~(�4� ���?ɔ�w�������{�h��ݟ�ȹ"eY����Q��;�k�	r�	��Ei!9�d�K��N�&r����k���7��o�]҆#7�bg���*����.W�ij���+Ӛ�̤2�g�*�����}�z��#e�����o>�_�z�e��>4�#�h�Fƛ&�Bɷ�Aq*n�KJ(nZ��as������9Or�*k4�v,ŉ�^�~��`�'hiI���	�S��$&[f������uW�v��B>~6�*0%m��["��%9��c�M���-��K(�?$�(�ďI��e��Km���4�%%����Y�O���ԛ��O�9�t8�t�q��������F��B=�2�*E|�J�_�D�&#��TI�N+Ӽh|>��.j~w�/&�6�T���H�N�ʸҥ�l�#A�
-5�bZP�jAV�&���6@��֚�>�!hY9�*+��ʂp��'͑:xbA8랽G�\������N�p����B�Z|ca;Մ�L�?>�Q��6ӗ:�m8�L���F�o�ZƳK�Hk���=5ŋ� �)�l	O��d�s�')��l��̑$�M�
-}^
-���-?lYnYea�Q%�dMq/���{5�K����s��t���A���ϨG��+�}:.�1u�g�,�����=}�������-z{�u���r�X�4x.�/x�C��jꌛ�]�1�܉AV7����ʆ���o��S��|c������M���#� �J#]�Vi.���MZ�����������H&���d�Pp%��Ss��V���|�Z��k��Y��&n+3���߽��{|�Ѳ�F�ceV�r����f{�
-�.终��yә�^�?F��6gz�6��z�+��Zj.0�.��j�y�!~�'�r�|O"C[.+ؿ��:Ⱥ�{ˣ*$B�8�4ǔ�Ky�'��b�i�1�}&,)�aݖ:���p=j���n��i�	/?D����Ӣ�9�V�V��b�E��x��D� ���0��e8�����M��b�(/��V��2F�F�߮|20�,������U��/��yģ^��2���Q��(!i���)S*�
-i���I�g3��tbV!�&���$qr�4���-�_=�����^u6�E���W�jHf	������0�G�F�0lA�`��/�8�g�p|7��b���v��0Z����l�ګj����=��`�:��1��,K���l�]g�,+��-]���<�-zy�M����*�&���o��)����Yš�Z}�y���5�)k���T�yY`>�ݢ������¡����Yġ�}6�)4S�@Ëx���jx.��..sP��F ��]b'a��ϖ᜺4���P�5�p4\�Q�K�#����'?��|!/R�˜T�g�a��O��R��H�ǽ�T���YD��7㹗E0H�����ȗ5��+5���1�hK�ˠUY&\PMe65�D��Y֜����g��f ����8�?��)�#�|U��&r�&�q�[�ZM��&�<t�%���H������04�:42��D&#G"�TE��ю�~hc,+�z)^M5�ݣ�0H3t%_S$~~HJ�5��J���a[7���2���e���lm�C� ����JX`;�[��a��#�	&�Z�d�X�u~XI笈,/�8��ѣ[���z��/�e:��2��uNh(��/�a�I]�>@���ޒ���^����ڥ��'O�-��Y�ȵ����?U���])�8�`Yn�{�����^���Je2%:qNy͂�U\�j��
-Ҹ����,wǺ�Ď����f����p�p�M _!9�f�)R<����%d~�Yo4��~жDO8Ԣ�H4�����Bq�J�z@�ղ������}�R�֎Ǣԡ4�`m���V�M\3�)$��V7���p8ޭ�H5{������l�z=ȵ�=Fé��Ұh<܎ը���X\��mrz�0�;�؋3�\�,p��?���D/��d!|*%�t�DV:�|��)��QeauZľDQ�T�tn�㝐4���^UY�S��A-�:42mht[�%z4hi��Mv�����E���r	i�PΤ]dP����� �ʊ�x�'��+¹]`���(R���+M9V�s�y9V�r�2�Xe�a��љ��i��i�a�˱:�c�)�js�)�Vo_l�d��ۅ.�e��5ɺĺԊ�׬����u�m�������]���_	/#b{+b�r��ܒ�u��'�=����9ٴ��ۄ+Iݸ���͗�m��벱���_-�'���ʶ�i',O��#d묗k<Rz%��{k�x^�jX��!�����Òc��z�}b�#�5�xW����F�.��q���R�RRbIIZY�m� W���$�V\PO+���M�c	��2	����$��h�&G��c ��I<O�}; ƾU��W��/��~Wz���W����sW�2}uk}�H0�,�w���V�ؘ,�w���7/��;.��m��0�r�bny������2��.�^�U�pz��+���j.I�X���oar}�L����7`x����C0V��\Y0����H�,�0�Z�.�����b�v�����3�_|�Z�z&,ُ�6��������B�C\�����h4�Ev�7w����g���!��f���MWVG��+��z1��"�0����ۋ���zZmX�ܵ�	�}�$���D!	5<?��Ͱ��.�|,/���������沛�V�7�śKM�\�B�mz����zȚ�x�x�isZ*V���~��K�~���ho�
-�۲r�[,׽����v�u/@���ۿ>'�;��xOq�(q'oe�G��pļ���Q���ʍ^4����`~��*�4�2o�S9rXc��k ��&��Q�-��*��Wye�*����X���.t����Q� ����{A��[�)���o�&n�ߢ��u�Lњ��XUE ���ɯ�0f���P��L.��4��9i�G�t����21y~"( n��<��I�'.��C7��f:{8�%��g>{��ۻ�W?{P1��J�������{�dxj-�I#�� �d"+U(%N@2�P��U.U��nkj���6!�~b1N3�M`�]DN��ӽɛ��|v�6���9u���X0���:�ð1q&�9��
-�#�"�f�8����c&4ۀ�x`; N� ��d` NѼp���
-��i5�8)�#[�i"*�&�����8��3��q�F�oŽ�f���Ĩ7p-�ɫqX�>���U"��\����hV���|s���o�F��y�
-_�4������f�h.�~�u�����Vl�=�����V�,�n8S��q����K�J�g�~�����W��0�wc��%a�z+zY�[x�j����Vr���vN�$�6��3sH�Đ��!��8I��t
-�	6eC�>>�U}n ��Ge���f�&���J��k������=���;]C��A����U*mU�«�Ū��D���rY���j�fނ�trS)n���9U�?h*����ذ�A$��/��q[����H���c���䆅U�b ���3�X�G����̷��Y-C��,���½2�h�P���&)-�lx��$wxELs#U�pEM�ruB��J�S�!�"8�@ɒdI�y����UF�]���6���oK��*W���{<�S���ǀ�y$cv�0��0�����;�ق���/��Q�庍r�3�ï���*�ӧ�mX�w�M��;n����w�"�!���3��>���D�����/8HS$�Ce��K���6��ve��߽�u��}(�
-�q�)�+�\X�-�k������l�{�����H����=4w�S{�i�{⻼��u�r|��O">t)�|���&���!;Qfå*Z)�P�d���8kYG�{i��j!VcI:b�ELt���_��WUG6YBrd3�;Q��,#'+4��z@Hmo��-y8Ґ�2��me]L�����^�:aO��C��7��}���YãE*�Nm.G��Kԩ�h)q
-��C��W�(q�k�k�D��˃���!�` mO�[C��Ѵ/u$����C����Lç���0�U�7^s�1R�2 v�L_#���|`aѡb0�������_�+7��{�}�)�\�x�R�7�f�4�I�ѓt�hbgL+W�3v:�t&!IA3C2���Z��O��	�y�k*�8C�D����8~�-aF�wt���_:���U�N���=4[K� ƙ#�:�y�$�Af4�ɢ1DIf2Q�q1Qa��)�a��o�������hG�=�K�6S�nZ�[@��y��yh��#{�p$#-�Nz�> �\W�|Ȑeq�BE����.U���{��hۈI2��yX 4�eY�m��&d��7i�f-�ZӖz]���o�������i�hň��R���B1xVc�����Ϡ�i��f��l�\� g�~�������O���W��?4�\��0��/;y���D�Or�ӰL�1&#0o0��\Ö��ꑾ�U�T�,�<+���������� }�5�vX����Q(x�DZ<�@�^#h��y� ���#2���n*�tx*(8�d7oN޼9�*~����\��}�{����5�{�����sˍ�3���s��S��9��������{��]"��#}Jy?2��r������B�Kl��[R����hI����y�~)ӥF��k?��gHn�a�3q&H��C��[��R��a|���
-��ʪʴrī[@�F�*,b;6��)��e�P<�U>-����&t���U�kc����a���WM|Z�n8�ł>���L�?c�3s������	�gYԳ�A}̄�sF�h��~P3��<���r����W�p� ��v�R?���h0��wG�B�j\�Ei�+���'V��r�8�Vt��5�]n��jt����x"F���'!��|�s���5ћ���7����P����~�+\�
-_��-����;^Q۽���5ն�بm[?#w�4r_���ɍܙ~�=c����d?�ϚP_e�O�P���Y�Y�s�A}ڄ��~:��t?�O�P_ˢ���Sס��C}�ԧ�E��ԗL�{�3<�?ԥ~P_�ی��i��5:�JA.��ŵ�S���⚋Q�B.
-8������)EqD5���Z�����Sև����z��~����ke)�Y�v���A�<=�H��Ao@7�p�����\�����\�0�/�P8Jۘ%�LWl|c?��r܆�Oڨ��NN�Fۆ���cN��Q?�uˋ�V���P��nu�g>�n���N�44砗�Qqu�/�����t�'���;�Ƴ�a'Q�t�ˆ�^�j��EZb��"�0I��%���>_�tu������]����֥��z���\l�<Ŧ."vY�l�͟��/��,-�����rQwZ顱�{��8_��x���q��6�z�`�~�� ����%tAv	=d�~�Iңz���01��5P,�j"������h�$�,4�M�~IZ5�h�hiX~h����1_xm'Z֨�`��i��uZ�['�	�ܱ�3vN)N,q��3�8�6�Xb�i������{�ϊ+](u��8O\YW�9�a@X�]���������B�'�q ��O�Y]ns��ۥ4�Ɲxʧ��4n�W	��Z�u�㾣's��<��a֊�,��?���������y6y��qMv��H��{G��J�����F�y�7<�U�� Y�V�p�L��L�D�����ho؟�sa��p�dT���d�p��p��/�p�U�����>E��\�S\���]�;��wR��!���O��i�)��&��ؔ&L��0�Tt1Q{��=qʂ¹�!#�ѲD�u3�|1K�'@?��㖤��N;�j�:�Fz�2�C�4�Tݥk�w�v� �x�g���|O�~o�RèR�T�O��ޥ�Y�9T�-�?�|��Ǘ����`��`]�<�֕����w �Aݏi�B��w+q���Xy����W��Łr�\N\�W�Ï���ą`��B�����AS
-��Y�Ax��%E��A���5ɇ�CD�_�6���K��l�:�.uuX�J
-������7��M���+,]�K��o�ep��!�VI�T�b`Zi��Y<4���	���z�>���H�
-���?�� �|��M<�W�X��_���Va�ث�GY��DK�|�����"q���f�١9_����1ԟB}���	>cQ�}�U�]AZ���է���|1�x(���Q�P�S�1_ԋ��k��:_��_x���ݳڰ�Q�r��_�6�
-��UPi�h����m�@\�?�C��s�,I|IbMWa;��OJ}2��0C�_�@G���t����nS����t ��>�c�;������ |���?��=��������W����/#����U�3��[p��������eoD��M�G�VP�Ď�CR�hX&P���0)�,�r��U^Y��|���r���ɘ�ߚr&-�9�����p�Nsٮ [7g����C���C(�o:�\E�f{�����b�B1�d�M������C�����#9�_�Q���*$�I*r�E�D.�U�<�9��@�*��^�S9�^��6Ћ�� ��Y��`��݈S�U��{ȇA��'Q����~?�s94-@󮩜�Fs ��	�a \��*�{^��x�h<)�gj����-�H��>0E\Eć<Y~��W|.�10S>�<�i���`{=v�Ϻ��X��S�]C��ޡ���`I������j�I^�eSʧ\���_(ڞǗ�� ��)9��Y^)�煾�ul+:�K�X!P����LF�^�AM�W5�������D�]h������t�6HNצ.y6�u�$�j�I(�Z>���z�y@^�CrI-�hڇ��>�X	���r�p��&2};�!����Q��'2��"����&e��g�Q-���4�"����;�fX��.�<���DQ�DS��zU$�ޓB7�S�&s���o���?"�]�v �q]�ũ�傚N r�C
-R��!���e�F�pU�8����ke+6��� R8P�[�1��WZS�����&.2�T͙9L�Q�Y�~��~t������
-�e�᳊U��*�� ��U8ظ��g��&�^4�f|At�,�R��\'Q�'�)@�����V�j�
-/�V!<ж�C[�I�Ip/����&.�	��O�Z�����*�~�{"�O�؈tt�O5Bnѥ����j�t8z:,5vɴw%��t����+q����J����b��G����w��G�8�o��6���0��/ZXU�����<�ޯ�o�UYV�*g°M�VV[}%�/�Z�c���G,x�κ ��'@Y���1�$� [��X�e����6[�!�8|��]>X�hhQ�q���d׿G,�M��aT�Q����,���0����B�j����c���[�Y~=�>�I�U������
-+�P��L��'�6Ȑǭ�؂���5d+͒N(m㨋Mt��yт(���'�v�\�
-�y�w�ӑW-ذƏ)��H}��a_O��\9�Q��퓨֚�U�E�Bp��.\��B<�TAE���є#M9H��뢯4WQ�O�3�P�N��R
-�#���b���/�"�����|� �����~Wc7��E���x�BE耫�
--�w\�����h��$7k$4�ٻؘ��:�f�"<*�<ϏE
-i�
-�Y��2�O�)V�&vU� zoO�J���x΅S@V��l�)I���$�B'�؈�D	�_���*���\[⁑�\�գE��5� 򲭃-P�Rުh�ss|��hmes�Z��:�u9��p0 ;�v���"�t�j.`�U-��RӑY\��k��đ d<~O+�{�Q)�S!d*��
-�CE2��9���z�td�@8mp�� K�e�=�~����<"������Zm�uC[��r�m-���*-r�2�z�RIH��T5iK�6Q�a�V�y�9$5[a�.��i���Q@>% ��9׀<	�y�2��/�����&�Qٽ��ݷ7�$zER_	dIt{�v�8�d&3�,/i^2JfƎg�&�W3�~����L2/ߓ1���l^�̎w����H��b/xc�~��޾-	왼�����gZ��N��NU�:u�[[����R�f��&ɔS�;A�H`q0ِ�y�����Ķrx��]dU���[+=(�}CؔǴ��p�>Ɗm���-NbT��V�j��}�B�� �b��2z�藧֏WS��}�s6x�x�of���mIؠ,���/L�R}�*2g��8Eb�0C��J�u��˚Z�^n�`�W�j���.n�b�k�Iqw��g���Wt'�g�X�d��b�j��i��8""��X�ҡ��&�ϣC�(2�B�=)H���,`�n��q2[�d�����9{iH��s��Ơ,�r'<����d)��e7;a\	{Z+���jo��t���/��Xy����b��a�m#sI�e�Ļ�l�S��n�����dgӷ�Ip t���۞�&h�Ag���"�#A��t�ԅ{=o�(2���[��c�C@T�����&H��Ե,$N]4Y7+�>؄��a�ԫhDX*���I�0�"�~P��5iuuG�{��X����7&�s�Ε���P���%���=R��-!ˠh�+��ᐒ�JY�($����}GH��{���a�����Ok唦J�Vd�>��I�!�D�	 �Y0\��r�P;�<V���ys�tв�;Q�'-kl1ת�=��~c��7&(�jÓ���,&_�f����aY?xt3<�7D�e)��*�?��UCrf{�����x�φ/[�à	cM(��������5�����c~Y�����'���h153�R�jpk�&�-G��P�<���B�?9EX�j�Z���вo�Pj{�MX�z�jm������z���?�M�|S��f�7���w�{����#���_q��8�r���j���s<9�P2q�c��r�&W���
-��oР	����:��sn��\h�gLF��2?����ԏ�܃��ox����o��^[ϋ���@���_j�T<Y_�fO�q1;����ۯ-+ႎR���"|aW!�:�@���6�Ͷ.V����_�}~��=�F��-/�n��T
-�(p^n�'{��jx��@���<��J	˗-O��$t>�B>�kE�!j�|ԨW�{�<�75���U�z���`�` s�p����a�q��y>�Nw ����	.�!��~Y>Gqu�T���ց���ݨ��mP�-��@�Y��P�c��h�9o��7)c���F�� lJZ˻�Y��S~�y�m�>�t���t�e'Z���fnCG�	*{]�`���SG'8`�T�yj�m�X��4����f.\鿃7��ߩ��'�:���"�v���n�"�79Lu�o��%��ט@%9���a��7>h�^���&Sy��Q^Zg]�܄��6i�������X�1ɍ]ĝ��r$7u���.gr��"a}]�;�k��h�����&C�_k�rf���Ǜܚ�~�Ґ�>�k�ĪE'ap
-�i/	nT� ��1���Kɧ<V�vJ����7�ԉ�p3��
-<���������a�4�/�yBj������?�	����A��������b���ǊTIZ��k��ґ�)z���}���CZ ��oJ�w'|N͸s�	�|����\��nM-��^(&���j}�~��	���0�O����.v��i�q^s/}we�Q(��)�!:�mh��7B��)��|nl�]K�	��x����__jº�^7~x�?�Ǉ�D�륷$ޒ��g~�	�'��F��'rn��s{���iF�%ѣ��ӊLm���nO����jT��DOT��1���W�J��u�/��+6�~�#4�=]�	M�"�"BM"t�5rB���ҾN�FiI��@��	��k4�}F� �����@�G~���g.�B4�<Y��:D���E&vi������h�M�KK�ej�BwU�X;o�ڥv?�|��n=?֥\�8�Z��1�����N�_-F�r �y&��DY��.�ZeѶ\�2����7�g��Q~�*����4�6�7x�����G�T�yB럂�
-��r.��"���-��|��yyY�ۜ��;�G��Ɖ���Z�*������uj4v��b������6Z�ߛ��DVe�Q������H˰Er��2lin�<�r �B�����pj����U�V{$U�"�j,����8^���2��%��%�������bi�FCsT>!��Ao4Z�����Ã�a��.{�X����9�-%om�)@T��)���c����qK�1��4TY���uKuM�y�҆�LM��X]`��g\��\�=U!hufA6�� C`h_g�M�2Ƈ`����W 7������`���˱]����3�^���Y�Y1�l���+֓��^���uy1@i�'u�=���X�o�g���Gh>'�({�6e���N��* ������I?TM���X�J���&��b��Bns(��gn ��F���h�ݞ�=6���Y�RQ�l'�}�P���<<�q�,��]��X���n�`��ʳ�!!f��#bDrN���~#�c(�#��ĄBnk���ǉ	�R���q},p�d\'G���\�H\w�{�5J�>��>���J$7G2�&'F"9Q�}���旌��p쐛���1��Ǫ'�
-�rhK!�Z�D<[�����P�!B9�9ъ��P��;[�(lh���F�g
-E�hٙ#�b����O6)Dv��}:���\ҪU�2�ʄ�:W-�4iO�)��:@��G/�NQ2�fPpS�:�I�f3��'1��ɠ�Ob���.~����I�63��'1Oyd��Ob���>�IL?����ݧ���W>9^��������+ן�<u�R<Qy�d� ����W篟���ɩĳB4�E�e�~�JF���01�pF��O����;p2�ef���$��J��-�l���$��>q�TW57��m��u�Җ��:�S�GI1�3M��!K!�:��o@����)��Y��00�!D�:L�K/D9��[���1�q̴�UIs~� � B�
-�B
-
-�ISY�U��.G��"(���^6uw�TD!�1$_��5a�8Hr�B�B����r�4a���Y3��P�A<Zߏ�x��6/O�/?tp�2��?��½���:�\o���4���5"�*��eDp�2��e�g��̽���|�9�/�b˨(��]���c�&�"�X��J��e� H�-I��&w��~�������n%�E#�\�$��l�hf w���1mC]��K�<��B�a�t�F=6ޮM�k8"���}!���ナ!�*QM��u9�1D��!�l�w�&�R��C�2|��&��?{�?P��m���7�l�@\��֝��o�7����At-*L�C����p����pA��v�ڥ�F'&5�&k�u��7 �Y�4K 4�<�~��қl�?�ײ�i�����<		�{��-C1�r��P\t�S���s��mK��e۪�V3{��&�����n(&B,W����E,wS�.]_U�_��ަQ�*�k���0h]5ya��&�\S��W�En���i</",/Y�f?̳^�Zp�h�ɷڄ��E��P�~��E�
-wט��fGvFb{sČqA��h~��*C"Sk#a8���&�:D_���!�4o�D����T��D�0�XrgGrW�%��;�)W��R�2C�X���)ˋM��N�?��6e�N|��염��th�����T��O,�g�U���PJ͊+���Jg���dkP�Ŋ��b����1?怕�W��^�6�4���WI��K�+�#��J^)wU<{U<}2VJ�6�Y�]��ͯ�V6����qaI_���3������"����j���au:�ܺ^�Pq� ���'���+�-bA*f�-�|��!�J�_���_�Қ%C�kc�g0��ԷT*�m���y�Bav�Esҩ��.���(yߘdIN��g˿��I�R���h�����&�˩��v���$�b{D@��GeR�g15'���+�A�̹q��h=�*=bo����q����,���&�L*���@� �j��(w{ႇf�6�Gʵ="�e�pjr�8w.(��h��z�!s6�?���TN}�$�Z�ק�Kv���>��)�r�𔕀���\�3�g�?!��g��κ� �"����:p-���}?��t(>��um\��K>�a����2�SYp9/>J�W��9t��t�xN���'� L?Qi^Ik�.i�v��^�Jx��&�JH8<?��f��=2EڜQ��Ha#�������ȕS��%��E�1P������IP,*\`��N��w�i�����ڼ��ؐd��S:�St���O_��ܕ�:�M�����i2c��s}���A[��+!���V��Ik��ԉ�����3��@M���j��N���-�wg��'ew���8"7�Yw��a�=�G) ��/Zi/nF���U�Bq�j�O���ⳞZp��Ǚc��c!Q=Tb4v�D�2��2���^m�>~�bv�2�LWA��153y���P���M�#�T��f�A��v}f��g���Ƞ��v�ԬU�ū�����U*��>���;?��?��U*���x�q�ͪ>�:��؅�����T�G��!�8g����F��YWܚ�$�x4ei\�:��OUn�+u.���w)���ǭq�!��Wh�:�k�Z
-qŶ��_���v�����E���U*�=��8����e؇�?~���K����c��!��'���̵A^����k�jfU[���s�4O��l��a��Ņ=��Ba��N��J��:̇�	7�i_�~S�b��.��߬�3����)Z�hmV금��C(�m��oh.����.�����:�ܩ�}A���u�?"�j�
-f��wU�4�>6�T*s���̩���ݼ�%��)]���T7u�'KUb. O0a��W` �0��Y����P n��*,}�s�+tD�B�D~���߂�p_5C�Dޫ#z"f�zuF��������#�)�$��x$^���)?��	��h���jz5jeHda�9�^���x(��`���pP[�#X�@��
-�h� ̞2���c�2BF=��M�J@c��`��ɲ'���s�kb��ܟ(�~X�}]���X����X����\���Teǩ
-�EczŨO2p8���|��Ʈ]�+�ƿ.�u�y������S���U���-��!� af"��z���
-&��c��P���V����ڠ��k&��T����"������W
-D��3�K���V��1�z޾�2�ҹ��S��
-X)���!?l�K�(ТRb��\�V]���$�K1���q̦>�;�[)�u2|�!��9s��!偉�W�A�|�I�;t �j�`�AB{|��5��+aho�h�4���4�{Yp���b\k��\�=[	��Jx��/	GQ�9ڗ5�?�isG�4u:�d���Й]b�Y���`���{�ߊ�MV�C�����/b��3Cǰ�z��~�5��J���X���oh�e.a����P�5i=0^aNs��9G]�@���%=�j�}�J�w
-�x'Pj�L�S�Xx6kb��یg������o���,����!tm�+��y"q��\��O8K j!����!%��8u����O�����N��I�4:�Wu�t�qm�r8z@T������4a:�
-I��P���Nb%��
-}!��Ѥ���q(\�F�QO��H�)��rR�1����ެ�A�B�߬�(c6@��Iuxy<�ba��W�.W8f�9��u2�\S���s�E���	L��@�`����:R�ŜӸ?�ˀM���ܠ&�ao5�R)�H�VJ�܋����(O�Du���xV��9\`�X~�������b�U4�l
-�|���4d�jw�x8�1������Kns3��GJsԖ6|�F�2OF�݉����:�[�5�':QD0(���O��D(:������������ڱ�*��"j��j��5H���,\<��)O�sr�����������������uSÖ�������F�߉S�D����~3��eq�e+1�Ne1者��wM���wM���w���̼�U�{�{w)�2�~_\��`?��"���
-��P�(ʃq%�)ŕ�>eG\iR��q�YSvŕ�^��X@y�I�X��|ΆJ5�傣�Ф1<�2f�MNM����Á��������� �Rթ^�����$�?6�QE���Ǐ����m,Y3�e�.����f's�C����t�d�%s�!�!�;N��U�R��3
-���YO	���]�Qiy���C~A#�	�e��R��,� ��ܞ8J�n���Ki�a*�)/ld���u���bG�N���AJg�������u�-b���D_G���l~ß��j����-E��F��q��H�_���!ꍀg}YoԷ��
-���
-��� �@�<�?��3�u���d'k�1J7�QF8�2��Ѕ�@���o��j����&�2�y{Q�69���uKD
-1V}t��'���R�cd'�%�M͡�Yz�_��!«�u�b5\�A:�����w���?T�}8��C�k���5}�	m�������.�������u,0|��]���2a�2�E�����-���6�Wq�D^>�hO�/<�zJ��9Gū3ȴ�f�K�+�^|Tqì$Uܓ�|����*F< ���َ�(�a�����w�4�m���O�١b)�^����l���LeH��_妰�,�����_>=������i��3Z��w�ܴ��+�,�o����'�G��CO�B������>��,�@vy�g>�{*n�{�Z9��IE�C,�(�E�,���9b`Q��&1�H�,�W+�D�h��Mp[h]�|�d:�}$.�nP��;p�q�i���>\m��j�x����AXna���R�[��W�O7\�G�AX�7l7{�����#�w�r��Ȭ�q��cq33<77��r���n{���������u�bHx�n��f�Y�:M�kNiv+ή]6w�
-�V�=#�8{�V�}�]K�u�:T`[)��w��'5S� a�[��w���gԛ�PF�� ��f�� 6���h`BIX4�g�%�w�M��!i�Yh*�.�2s*��w�8�� -5�E���޹AyUA~cL试*j��a->�?�Xe��'�]T�b	��G���m�6
-��z��d�/C���.��F��ꠑ�R�h+B�
-�"������m	O!aX�Pn�v4"��7����^m�U�KH�e��^�Ae��Q�Yz�4���LDW�k�4�^m�=�KdM�1��ۆ�MaK�k���,��l|�G2�=�h��$쭶ZY�eŚd�jp[Ul�qOռ���!�i��J=���ÍY3-[�"�1�Z��_��h��&���#��A�a#2z!c��]�Q�4��G^��<��=�_4x�ܓh�Sg)�øA��Z�M�ڶ��P�yyamlN��<�#��GBp�G����݈J���P�4�<�L�f�� OtȠ��+ި���F���̧�[OU~R���,-dT����6Y�bK��.j?��FY�j���韓������tb�NZ��������F���N6ŏ���Si��
-�Y��鯇۶B�a�|���{�?�1ƫ�1T/�D�c{8�'#���#c�Պm����jFvӀ�wb���ƙN��l�q���&';Ln�͈����u�f���Jez����k�����u_���ٟ���:�&��Gt�u�&/u�&���2���l��S�y���Ң�����5�`�\�D�_���*���J�~L��W�8�v��/�%z	��op������p��d*����3qZ&ԥ��8���v��_Rmӳ�L��&��
-�"�/�m0g+�����g-��o�'�Qi'���Գ��ʒ���]n�N��>��*��V�qOQ]N�m���n�(�C�q��Ӹ���~Vk4�+�o(7��W�75�A1� 5��O�X�P�AY�g�	�6N�M��2(nO���7�>=\�h���<y���ӕ5�+a6�\����Z���Z��A��ͣh!^�\��8�&���w%}�23�\���U�}��"Rg�Rg5K{�� ���P��ʖ~us ���fm��=��4��3�ܞ��=Ay�,$�:�C��q��s�]�ɂ5	݅�1�)$OK�ZoA����5��/�u�����O^���Ka��SG9�)d�T����P������i�O#~ ����B9�����2��jѵq��%]�@qo�a��[�0?���Km��Q��F�4�g�t��c�����f��ã���Q���e«^�x����9�:�sf���Q`d�#kY#[����2��hx���,��E���X�l� �:���߼�`�pA9�t��O"zd����a�kH��0������xZ�]�]<X�=�`W��0y��x�.J�ǰ0���!��<�c"�f�͆z�m�Z��g[J�۾�k6Ս�gQ7�l�?�R�o!}���,H�4C���g��͂ mo<�-�ggYҷ�g�����x�0n0n⢆��\#�[�l�Q���x�[4<bqstl��DP���Ņ:���/"����V#�^��J��oiiu�t�u������x�*)��B��z�7M>��_�W�,��'�|U� ��8��7�,~.��iLY�L����P�g?b݈93Q�Y���{F��1ui6π�ڎ��a�P��lj�tl����X_�A�1����l�Q+�k�$�'����jpQ�M|��Mqns��H��j��WɁZ��Aw���geY��j�u�(�� 5�K�������̣6:������}�o*���F�V�ZK#�7g!��w�ß{�|�,��+#u|��x~�?em�9t~�29��k���h8?��>>����+$m�W��"��F��]d:ދ&o0E_���Ҫ���V�dxe|cUNM�E햜Gқ̠p���
-�{7��������T*�w?�\r�r�'��?���g���U��+�|�Bip�,����½��n�E
-}���B����~K(����s��O�"��e�pHr�K�M���#8�b	Ξ ﷔2:�qv��j=y](�>e��,4�g�����*��f�*�Ey��Um�?�7[���Rs~�>e������է\�'�5��[j�j!|I"�F���(Is;����r�b�Oa�l��\���a6�q��/�*Bk���@����e.���]���'�
-�}��WrAV�ﰐ��H�T���. )�*���j�v{��k���Fy_��C�w����^ XkC0P�`��`�p�0�}@���t븡�t�x �~�j~�Gk�f�[s��-�%���R�/1����:'����p�T��^�E�.��b톗a�g�"���w9�P��n�T`�n3vT��u)���@["�ܡx��w�
-�Z|:��J.CG��x� �����`2P[�����B�)��BKԞA>Z�I9\M�η�Ӄ�*V.ti�������v9J�!���[��D��#����n�o�����D@U�x�����P!sA�}�>����SN1���V	�y�6&|a]�y�v^�����]�L���n�$.�ϫ�y���G�!�_�k�i���k���I��`���ϿG��j9o�~[���U���Pk��I�������h�ۡ�',V���\�P�諐{5���U��G#�ަ�R ����� �L�|�Gԁ쩱�i�3� H�����K�-��G$�p$w��o�H��-~����3"i�Lr�H:�!��R�'Ṳ��):���.�7x4b�̦}jwȼ7�_zT5��'#ʐ3@,J�WI�~ߣ�32����*����`{;Kr����2�囉�24���C��R����
-����t��ӕ7OW\�J{���J���>T�w1�;l��.Ha'S{�x)d��})$lx��R�1`�m�p�0@ ���@S���<l��MMV� �Gm ' �׈�9��hd˧���>	֎�I�*`�s�7N-�,�b�`�=Q-�Jz��I[��.`E��҂ˇؐvkJ{��B3��:c͇*��A���� �ӶZW ����r��͡�X$���3��@�-���K-�N��ŵRon��~���\�{VX�b0�M�n�R��W�i��!.	�W�1�{ð���0%[�f����l ��9
-˝����(f��i����{(]l;�ay7�|�u���?��B�x��2�7o;�%��������x�^jvz]����zt�쵾^�>��`{���0��*���D3N��.��	;�A7t'�lq��!���rJ�}a�pA�������ԇ(Ã]�W�b���a�d��A-�pG�*��#�R���������[fC�����xx�1�\��^
-���Bn{��%|t�שh{�)���-���uig��T���مu��V(��e���P�F��$��	?QO���B�[�`�i�r(�y��u_��,�ֽ6R�}��;�P�n��b����Br������k̾f��r�;�h�*��[H���+�B)P��g�`xh5[g�Ä�*���5���P��x�����P!=OG85OW�7H�{A�Q
-}���h$�-�T�
-Wǳ�U��'{8��(XRL��J�^�x�9�YSW��Ce�C�ӡG��b>��z�i���,e_���eu̎�������/�or����+�E�$����  �}b)���W^bj������C��C2���/�k�ڬQƚPN)���_�平VmW-��U[YS�����H�7��⸣��N��}1p�(AY��9ݽ��o<-���_�,�אE.��1��5��l^�����+��G�� �Y�5�X��R ��7�3��~����?`�8���:��v��c�UJ�!��I��M(^��`�v�E	�6�\�!�ԕ�<������L�/��(X��Ɋ��˛^���e��C�\��VbCz5���#�X�s�� r[��kuj	�[j'���!��R��n�N*�袆e"�2P���c�����{Exk��0��zBS���.��W"~�h��`<�j[NJ̨k�+u}�A���:���E�Td�ho���F,���h��7헍~����F�/���L�Ց�?|���z�wE��=���+�Ro�U"	Ĩ����&�#��f�p��[1o�d5�P�J�;�r?�U�n��D��������S��H��"���G����%�f=�T`_6���AL�Wl�>���;�t����lٖ�V�T���T7�eD�Q��*|n������f|[M�J�)����9���#^Q��O�1�Ú�;���v�9޻>ɺ7T���Um��]D�1F�}��hս���c�սQ�]j��B߷јUAL-炘�H�`;X��q��lp�o�U��v�����dB��kҋ��p�:����?HQ��RԜߐ�cTx$��3��3J+d��������9�T�9�צ�߷Q#��x�i�M`���UL��⏘*5;�.�/���O�k-d9���;le��;/w�g9�`wH�r1�N�ayI+�X}f�	�H�����טQ�&�K��t�p���8ړaO���~^�h4P2\���r�ߕ/�,>U��T��&T�T�T�+�O��Hl&�Q�F��sU���Hp�S���$�|Cؑ���1�`��a�l;j��06ϡ�GX�
-Sg�Z��G�����Q��|n&�|�:��	���C��M����M:/�=?bJ:���7Sӛ�tc8{c�:�\��>n-�n6O[V��QcOX���e��Q��갱f5����K�g��R���n��nO�.���'r&w:��J���������vx��Um�4q��P"�?4壐��y�:.q�?B�K'q�>M��xF{���=��s��Sn�N�C�2�IE�!W��+����p�v�]�.�����r��-�����~��5���ymv�Cm~���a��������F�I3�M�y�Y���b��S��xJ\.lAґ��8��c��~V���G�~4��s ,ŝa!�� 	ɉ������U��F@���f6��*�& |j��Ϫ �p�� ���pU6Jׅ�{-��OB��1��R�2]��44�w+�Q�̫��L���¹��B�U��u�
-��!�H��wqY�:y�#�*\H���ŕ��0�3��[�Y�풲ʿ7���`d}]��Eлl�ڴm���ڦ-h��*�V \i�
-�U�� �l��*�] �e� WU���6��0�
-p �� ���*�� ��p/ ����y6�� 0���C�������X�4�5�F(�o���w�;��ֆ��v����i׸�w���=��d_�)ƍ��NS4L�'e{���J��W*�++�q�r?�B�k���D^O�
-���U.�|�1�|R竅�մ�iЁÜ&C�B_�ͯG2.)Z�*Z��:���G�y�7�ua�Ë� =��I�Da�D�7=����QES[pK��ZЏ�츷s'%��ti�Q�{Qȭ�m�L��xuX1ہ�e�5�Z܄�o:�F�)Dö>lV����q[u�r,�:�]���j��Tz���WEE0$����t"}��"�&<5K1�#����qym(��R�/�'�Z�i^���	5J�ͺ/�����#Ǿx���Ȩ��֥2�6c��2����Ö��ua��{B�֛6��́П��O�b��?��X|�.��;�]t-�]j�$���?�`��Z ��+�{�<��I�Z��Ʋ�km�X����#e^iƉ��Q��(U�X��--&����mzlӟ�
-�7���6&����'?��)��o�-\��2>9�3yUg��΋�N�R���� �l�.}�w�f��@/`ؖ���<.}.V����Hw������\)^UŪ��Q�a)�~8\*fO��QR�RW�84�u!?���<	�x%a�`��|��*[�:��g5gM
-ĖX:ī���2�#lz��ѯS�k�#� u�'R�a�ږ�.��[���+y�8�Wҷ4�_�S�7�-���V�+��Kw����uR�(�ѓ9�V��tX)�r�^����N�0��)�|.��������)kJ��Prv'{d̬��:i�X�D�4�|.�>���~���G+�����jjU��zّ�j����-�W�gl[�@���`ם��3ߛE0��&�1+�z�<�-��`��b��7QH�Vț(�\x {m o`_�m r�\���ʿ��*̻�yΆ�] <_x /� ���U�c x���c�y�
-�!`^�!� ��� ����
-�`x��F�\�������H�aDK��`�]����i=��o�h�ay�+O] ����-_�]�8ZB�yc1u2,��?�+��WˋBɚ�+jr���T}��u�_S��~�:̯��ug��A^o�Ud�s����a��$|�^v���Lʽ��L���)���b���a�̙�����b�j�j��L�S5��S�P�>	�A%��%�S+`|��6�����Sj�,r�Ӡ����s{ ���-�U̬��^h�w��-Ƕ�q�/�Ax� ��R���N�U
-�( !g���2pf�/�Յp:Iy*aZ��1�o�����#��a`y�׬�T�CV@��٨n	�@��bj���6��C�"$@X�lz4�w�)E8�zA�c�iH
-��e�
-�R*��K1d�Z��bf�������t�����G؂M0lN�l^ʷ��Ni�;�4?ƺM��tB}5daw�ȇ-��t��\i%��v�W�3����[&���Ȍ��pv��|,G������Ȑ\"eF�Ӿ{u,�k�� 4:�.D�� #�I4�|; ��8&�PuO�����f�W��Xҧ�&�lq����GU���`h����a��)&&�)�'��;�W�o�"����oCD��65�BnsE5�0�y�B��8�B6�bCkn(����3E���Y�F�L����R�q���\��Y����Hw3�)ƌ����������3Ԁ���KPS���)E�Yt$����Pu�}eD5���?fk��� �>�ΰ�Aĉ���i�K�w���������{���e����l�i(�)�2j��qJ���3^)���t��[��˽��������"���B�s{�΅��V�5c{���iP���(�^�4o��5�J��hK߾">�nD=sO�ف���Q�]�k�h�^u�nx�0�,,bg�bv�P�b=a<;:K�k"NT��o¼��Z�F�"P���!�<�-���ʜw���8@��~õa�b��RH�z���_��E�r�K`� *ͱ�
-(�����ʬ-.� �����nF ��G����=�~���Y�}N9�ܩ8��
-u�S�Q��К��CP���:��ػ�q!��usqe׎�fs��7q�j�x��\�ч4vˢU��hk�Y�}��50g�u�ٱ�	+켔�H�����bM{Pq�èOu�����5uL�L�~l?�"┩=|eZ�r��D��0��+D[�m��_��R3�w��՗�M�	eC�<��$�1Ƥ�T+be�""o�Ƙ�+T�9␕����<u��t*���A��2ʮb-�4��Ns7���\�-bv
-ʀ�.,���إ��� M����r��͛���܋w@��S��a!`07�[���X��u$�6�����Q��T����s���@�����6Y���0M���K5yB,�g_\	?d��G�Ul7�i��`�>�F!�l��9Q78Wl˞���W�E�?��n�WZ�E	6�v$�gc�$�=��؃�J�G�x#oе�b�~�So�v�x�77M��I齹��m� k1\f�8
-^0כ��%��{.�=7m����h7;��>�	��ƋN�vlG��8�#���I�0�����#�m��lh��n��^�r�w��Ȟ?������Ɗ`�K��75���Z�4���h� ���m��F��`�(��T�ꕪ�S��g'���ʢ�E92��`޷�� �Ґ�K���<�QEe�H��0�pvT�&&��dy���!\��e	Ưf��t��F�?��m`	�p�����C�ZG@\2��JZ\.��/���ХL�V44�Die�uM�E�H[���+�%��JK�q
-���"m��`D�s$p���`���<@|��D��{�'#O�����?mQ)r<�#�<������p��Q�)�v~�/)s���%
-:V�;�mY9]E4�#*�#zc����	�Pn7�f/��pELU����M�A
-5/��D
-���@�����+cU�݌����C3������#�.%N+�1�)斚�g)�V+�-bX��_�̕	BR��uN1w�9��L8{�L`^|Е����.�f�G��c�O��Ԑ5�����d��"�e�Á�����N�Td�]Evu��]/�a׳8�z��Dg�c ���<�����am�um�W���K��܌D�/ѥF:X-ry�~�El���A��G#�3��J�:i�/����]C19���Y�b��$��E�Tk�\S��o�Jr\�tN̒��P��Ơ�����������tb�&@3K+wRt��H�M�����R���~��]�9�{+��u��3�^s�q��a��c#�~�[��{�����ӄ���Cj(�R]��)#�l�b���X�G�a<�W6�S_(uF=�k#�b4��2�S'-^��	o�.��7����.�x�Do�T��6�ջ��9�֮r_�����E��qp��Dp�:S�� ��S@%��9�L*�v����QJk'n�?���VU�]\W�X����1�@;Ǘ�>N��W�k�����$�.H[ ��wv �D!g�;����B�0�:���:�mC���N��*�sXg����"�G�>NJه}����I��T���q���y1��	���|{\�S!"��m���u&��;���Q�����Q�����ʚ��h��q���.u�^u(3[-�D�����Ym��>l:���g�4�'ud�����b����D�m�k�PTWG��_�{=�}j�u�B�5���XH=Q��OZ���ni�q��+�rFR��+�3+#>�RJ٫��	������b��v�m;�ECɥ��9�����\�N�VAșN��Ҋ����r�VL�Zf���gd�����P��]�k,��\� �KA\Jf�%2���ݟD�,���n/^3������p�rSDx>�_��Pz���1�w��i�-dzT��7!�5�&b��o]#l?����7�J]�T�L��V���Bn%cO/����<yq�I�AeA�<y�*+��b������p����y����M�+us��)������O(΋��K(ڤ��y	��o�܄�)�\�P<QeAB�F�k�o�rmB��*�bNb�W��&�oW�o��E����P�eD���H����H�&�D2�G`|L��=n�E3��CnH�&�,L +��q�f�KФ��ک;��34)�D�?�(�� ��1�����y�(�7T�-&|V�2a�������{r+"p�[0=��WD�,�\��
-��� �_�,�	���s��(%�:�[s�]���� �'��{�-�ym���eh%O���?R�ūX����}�{zOx�a���fک"����<��6�5sT:#�Q��"P� �Z�%�4o/��7ӖV���82�dw���Nrc�z��X��+���j�;Jj����V����þ����������VP<���y\h�>)aL��=U���~��un�d]m��� l��
-Y:�'��ح1��峚=m�Ȍ]�A������=���~T��-���6Rw\])�?�����<�/��5h6op�7�}Ct�~�|K�w�#�e1g��}�܃��~#����O: �"�_���߰��Д_�B�t"5	��ԋ/Il��s�8���a"�)��"�g��gzO� �z��yX��1y���G��>�Lu&}x����L^�^?���&�gdv����J�p��{Ib��2�]Y�:*\>/���s���-8L+j)t�s�$0�vEL�����	LT,z7��8���)Cƙ��r�p1An�3o��h1̏,��X #�J�mM�:^������	��4u�����-*�%����/-ϯ�iDh��Ɨ�j���2T���\ɑ��G9{� e
- Ӫ_#1:�2��L�3j�$F���.��= ���/Й�+��'��z�1qOD)������M�Y]��#�b)u/�|�	���qG��m���g��q��r���^������$ob�P"hr����R0e�܍ழ��Zq�!���u�8]����m�[���5�� "�p�|f�z��^Zf�q�:H�	����̫���*҉���-�%ZL��w8���r�}p��kh��{���{/,9�%�jx'�]�V4� ��G9G$���Ct�+{�_�,wK��������J|f���h�1Vc�bS�R[y���1(�4�&柈����[L�N!���<O"϶�<O�y��Ā�w�[��G 1�-��-!TM��m�őt��a��I/�0��l w�L���b���g#�>��g!���(�;�Ʀ��4� iD4� ш�ö7��(F�?��C1�a
-(v�L{�ee��<��;G+l�l����(�7b��3umVH|O��U�ն'b�2���K�T�Bo&V5��T�Ƽ��1Ӽ���0�O�����36��"(X���iF�"Gko��,��g���]��A��03�EPz�r���YӖ�4�z�YM�U�7�� ����z<�@o�:�$������e:��B�Ѷ�^�Qco��^��_Ax�ޏ�P5|��-�k��KZ0Fht^�2uZ��s�����[C�J�34T?�Kk�^��p5ճj�5��o���]}���5û��]�:���]�~��|@�/ҧ,֓/4��S��ɗ��K�)K��+������������������MP��	2(�$�7Q�ᘋ��S���N:M�|�*��1(��Vv��^�j�BꝈr��z��v��e~��Hn �Z)��!q�����vb��5�.�Y� +QfKkm��Xk#�s�;�O`�c�_�;�etp��Z*ec�Zϓ�8����e����.џ���~Z�� ����ǻ�r	��|{g?���R�)�~�~7�0�a�)�LR��| �BB���΃?P�%�K�W1��坣��UȽ	���K��V���mJ �����.Mt� �5� ���7����/�w�����Opڴt��h#��!��n�Xs� �GӘ�sy�2�]P=�LǊT�[:�ԄL:.v�ߝ���ܕN0��0<\��?�%��мG��=�ο8޻������&��"�q/����x<_�������mf:6����]�H�%{�=��	�LC��F�6�{����T�[F��s8�^���bTG(�G��.�c�1`bB��P�L�	#f̑�q�Mk�{P�}EZ�������ڗ�k��0�z�>���EOߦ'��,ӻo�Y}�(�����npTfg\C1��>J��o�p{�}C��1��٢�p1�X{�P9s�����sAMΏ�Q�y���������;}kW1uk��5H_�N�FU���=M�����	(i~<D\�$5���r�cNTy�����8���%��:?T�qu���-:trJ�K�V�N��]Z���d�7�DzO��7"��߫e�޷:}���u���Ru���>����
-�b�헖�����Ee��RGƀ��S�u����ǅ#�wq|#��}M�ymA��kJW"�+%;�MDÒ�^ӄYz�n�*��.�LINoT�]�C��X�j���p�_�q[��p��r�QL���SV�ʙ�t.�/�̼(������@A+$�	H��$���=�x4�[����Q�$̛[ż�;[������|+�D�܁/�բ�BH%���4a4��7�ψ��˖�|�8y��"yJ���DzE�4yE#0�֓s��e����U��ϕQ~�H�����"\,�֕��(d��9��'�#���<s��j�Z�����#���-g�Ĺ<*�Q`$��cr,依�E����т�寊�Y��X�^u\��5��ͿP<<�����x:ž1a���7&`h���H] o�� 9�"���������L�D��~���.eM�3��gF�|_����ޜ@'��h�%*�͸G�B��|KykM��s/vr���_�^���5Q�Q���t����h�h�|��$��,��W��x���H��H]��~������k��u��� +c�p���/3���ɿz��Tc����ϵ��:^����Xp�4�5b��t�|���b_4�>�s�B?�>�-\1JW�2B+Fi��QZm�����dq�}�}�Bn�=1Y��e�����m���F������O&	��!(��+S�t�E�]��S�͉�R�P�ᯗ�����K�����,��������Ug����xM�sX�m�9&=#:y��"�b��W��8��Mlf��p3b���g���uȞ#�5ݬ(����k:��9��L�YM,P��&��L4�����������au�c�7�*oא�r�\᠑+h�������.��wa���N���0Y6�@�1�yj�"���yCd���	���ܶ�Z7�򈾽�숃֫��Mܦ��VE�kÙu�uS�bԌfEv34�2F�5~oL���X���a,7��b!wU4���
-��n�zm��]�|��>��<Mle��x�L˨�9K1�K����e1Ņ,�ڐ�ԫҶ;j��U�=}���ޟ�{��h�G��[mх��R�수=#b�510�Z݃Wa^�W��0� ��ie470�j���}}M�5���&j�6�D]���5Q�k�n]Q�o���6�.������`�VF�ai�#d~��7E��rGT�����cΌ�����H�"����Z�H�;�-9��Ő����DG�o&w�5�J�Ud���C̻E��E�!y.j��Q<��=����l�kт�k8b���g�G�Q�"��m�H��q�Ш��S�ȱ���#����}��V"�g쑃�������(�h�`�y0+�ʻtSdv�n�̊��K�W�k�~�mj��ՅRXP���G�:œ˵��_7_�S7�Ϣt�����E�� Z��.�2�7x!7-�J,'��[����R��p��e���&��ZJuU�	��xOlAq=j�.��p���Գ6
-�#�îpW��yc�֤�L*g�ي"�o��PފyV��bXe���8a|�إ�Ob{���^aQ[+������B�&Z3}�\ja;p.eK	����Ѹ9���ь��'��*�#��Jw/��� �]�F<K鏎v}L���K�Q������n�h��z���X���x?Y������b~#�Ʉf�7�i����@��D���g������.7���RM�c�W�z5��B�ng�:c/�a��[�m �1�$�cRSh���l8&�H��_d+f��A.��S��yjS4��ڇ�T{���K�	qJ��S��>gk��\J�,%����_��<Α/��i��%<`��/Հv���/s%d�S'T��+��S��K��f?�����	�q�eü�aݧU��s��Lki�TEU����~ht�^G䵚Ε]��¡X�uS�O�k/Һf��h}D��&�,���7����JY��:���TJ�}�D�	7�9JĀ���Q���A�b��C�@�Y�-�ol�ȅoL��8J/�]��{��m����0G�ē�I(��(��M]�i������U�"ٯ}U�a:�6@���W��.J-�]?6�8����T1�7���	�?�j�::s��WO���p5e� ?�O�w��*�W�s�>�-kL�䘼Dc�ɢ^�hy[��hyG7/Z�~��2_�܃��]��j�o!x~8�W��@����Z�-/G�*#�>��>�!c���z0�(SV������U�;jv�N�PB��~M��v�v�{1�{)�;�����i��:6�fi(�@i��2�B��A��G/
-�#�c&ao���O�o��{��_F�T}9��Q�$/0V[?ѵ:����AV6W��hP�b�[���bꕄҥn�W�[����*��Nd.Z��}�y���U�����j:W-��,����Մ"ճ�[`�3}���]q.���ޟP��Ѱ�N^��H�i>B��}l�h��H;�o�4ŕ{��;�^/�d:��n.�)
-�:���X�L!�v��=J�̭� ��9T(���: �|C�#a��t���Pà�c�6\V3����ZM��O�r�g��ɩڣ�i�c0yuPα�4ǮSӇd� ���]aڼ��:e��՞_�O�C��V�}�*}B��_�OYMZ~�>e}x�k�)k�.5�V�2�w9���uz�3�N��^�R���)w�]Z�N}��˕ߠO٨w���)���k�����w��&}�f=s�-�h܄���f}��|w~���Dh��|��fh�i����a�~:�Y��N�B1
-3S{���˺��݅����SOt?ò��sW�Y`)���3�,�K���%�8[	���V�Y���U�D-3��f���GP��V�hBf����ޢ�(E=h�V�������V(��/X�CV	Ք0�l%<��|�vX%�ڇa��J؁���;�0����{����d��Y�����;�lxw�t��xw[xw����gû�o�CB��W�b�gBQ�5��g�£V����֪���X��<V�eq�c���X��<^�ei���rc��8�
-����p�ʬ��OE����{��x��C[9�@5�J[�U���9�Us�q��@�d��!jE���;�A���wf������wV*�/W*�Je^�����Lm.re���}��A1\�*�}�2���@�����qjf��abP�%b����	�;n�r��r{�C����G�����QYT�|�}2�{��jT�r�'����,u������u��p�L���n�.�䧢C4������ug���g�cW]=�
-���ٳ�y`հmp�p"��t�u���H'	��l-7�D�rOu��OuX�g;J��g;L������b~�?-����#�r���$�ա?Vٝ�M���:�
-8�����pI���e���в/w2��2�QΩ[Z}t��w9Q}�����֜'��u���<bK�M�S��-y3g��[:����z���U+ Vm4���g�Ao���wX=2��bj�W!䁠�0�o����@3�\nkuQ�81�[���A4�E�>K���8J*�T��+��f}�MqDD<dE�*"v �!�`+��#��2��6�W�0<�XM�q��*j����������ԒN�.Q)HZR(Q)�Yj(Q) ^F��)���Z퉚���V�jE�S��I�)͆%~��)�
-t�Ӣ�_�<@�ot 0���>ȿ�T��wk�v�{����M�B���%7��4Bש���0���щ��h��"2�d?��I&2�0"�sV0U��jLk���0��g��7�c��*���ޓQ�� ���'��^ �m��oy��KrD2����_�۔V�8�ĿoՓ�|����mzr�/����ײ�+-<�K<�O	�wG�('�U��W����uM���u�x�߼n�)���V\��TM�<�"���0+*�c�WVz2��򇢐j,��7"��t�ȓ���æ�`�(�h�Z��{�V�h'�pQ<��[k��mo����j����Ė�u��ΰ���ro��~��Ql��������-��Vi���{Q
-�^�Ƴ���ް���2n-cBf|X��m����\�gy�������f�J�'�S��lxXq�����Z�Æ�|lC�ϗ	̚T�Cx���=8"���E!��Ǖ�A�|�����'\Õ-GaJao���Г{�A	Z֡�𮎯�N���F"�LPL!�|T8_�W!�n��D�Z�>U�e��Vy	]�틖�_=^aT&���x��9�V���������)�M��*�|�:����A%!u�:��IR�'-�=�wz��N͝k���u�}r��hͱG��F���-��T����MqCdU��NITddGdQ!���ߩ%!��������Է���}����RI�ֆK��f���D-aQS��ڜ�����һ+c4�a	"L�Jƒ�� �@�xJ`4����*y7-a������X���I겧�&)'�14<�(P�e��_���E����Ѷ�����I��@hg�4�����	��wS-h�&���l5t��i���`,C��+���r��I��/�����W���/���ǝ��O�\���.��_\���� �J gه6�hk:TV���*�R��^h�d<حZ5~L�q��0��c���"�
-ĘYZ!~�4�O�L-��
-"\�*�����Ŧ�������s���ew9y Ǝ�L��G_-vIqk��r��1�����"���k�ku<�I A��"��Ë%��~�[�4����bBeQ��ꆄ��PB�Xm�AgKv�A
-:�la�]YI�`���>�L
-��M�6p�p��.u����B3���"�=LKq���˾$񉦵2(ZE�ú*��~L�lz��7K�K��_�(�J�k�ƿQ^>R;?��5�hofC{3�ugAs�j�Ά��'h��}�)�Җ�L9����m���Ő�� U��=�+�[�(��F�f�,�rJ�}T�~I^�-p֧��d�'�8v� 'M�ς,����ô�&OK�y����]Cˁ�Q6�5\3�"����lՅVlO�h�l�ϓb�i,^�є5��<�J����x�V����=\j���nA���[��F��WlV�������[��t��ힵ0/f��q7��?�uZ6]��|r�q��Ү�.����=J�У�\���d���r[��r�������#�<˪��k�;
-�*�Z�xy/���˱���;�֊L�ñIq
-��QٞRin��Y�V�y�<^.�>7+xq_��!+��ʊ�����Ӟ�bz�L��թr�I	q�:S�������$��������[;[�;���kÇ�c��ۇ�܆��zy��j}�����������U,oR��C�k4?�֘��w�
-W?:���"�H9�	�����R�ԎЮ8x�K��q�6�^�@(����4�R��4n�U�@Z���\ٙк�	�x9ycV��%[pnT�N^���{�K�z0�Zꍋٜ)����Y�p�>��S�\�kPn�3>k��W6g2f��噳����9��1��S8���*,�u�I�E�BC��Q�V`~�c�ֿ�|�?�xQ1�����ڙ�v)NwQ18���X_<�'#�}q(-AI�����g�������Ic~�a�FYD�E�yű�A�M�4�>V#�0���	|���
-�tVT�c64������VD9��6�|�Bhe{W^Q�6>X��q>���k<4,.N���&_�(�oZ��Y�x�3�7�L5I@��)�;�+����1%'iNɉ��Q�n��@�������yٵ$��6��2��8�]+�s(کU�S�t��#ѹ��GQ�e��fh�xh�bh����C�]E��D�n=�&q޶�:''���9�g�u2f�=?������f�ۑ����\+��:���{�Tr�7�Jvv�R��G=���F5���[�6��l;�Ė�br7m0O��y�J��V-��њQ^�+j�Z2*�Ev�h˨�b�ZVɓ�[��Y�Q!5��a�<|������^d�"�uU�-��zUd+\ő3NDnCƹ���ڊ��!�`M�U�i��:7���B++$8��
-XH��Q�_�>�37u��b6�X�RA��7����f����,ޕZ�wQ��A��C��"?v�֮O�f���}�68�Z^lvy
-���gA/#�hG������V��-�3
-���KdR�-d��&�׫��=ɤ��dk�L���L�� �����&���dr��dݿ�L�Sѯ�G��J&����)g�L�� Ԝ�{�ɛ �7m2٧��L�̉6��6�=Aa��&C*)�?`w����4�%�$:��LȊf"�iՉ��<��Q��LIb=Av=��1��6"$()�m��"�8D�B�:�sʀ��4�ʦ��+�ܒ��H2�V���/�\pI���*���;����%BY[�~���2h�0��?PV?��~����*K��� ��H� �2��Pw�U�����ovS�i+�h-��Vt ��Wq��a��Ľ�OS�y�v�6�h��q��Tq��ΌX�t�Nr����gu�������-��	+b��R�&�B̓�QB�Z�w	����*xG��ٍy5�Eާ�H�XĘL����M�q`��t�T�U��m��� �+����1o�@%�gK|	tG�E�I��֔�Ǘ��J���~Ѯ�[��p�¿��_��F�r���iᮞ;��;ݫ�N�$�t�b�������H�6��^Ɇy�+:Q�����7T�+��U��J��*}E����>�m��c�/#=��i������p�ly® �3()���ս���4�<(���$�1%Ŕ~���3��$�+)����/)��d�B��t��t�|_��$s6�ϧ�_J�E��Kf3�/�������?�̅����Z~�@���)��)y�9�O�����|��n�d��y<X�F��d�>#Aw��nd��.���lRj*Ǫ�y�y�ҵ�j����Ph�qj�X��4����>g����b;<4���ޯ/t�����~}��|�ol������ѯ?�47�ej�ڃ��!vۄx��EL�"j��xǯ�h��76����M~c�__���ȓzB���<&( _"�K y���b�-~}�m���կ'Kͭ~c�_�<���7���'o3���w�����~�=����|�o젨��:U�n�|�m��86MS���<�k����Q�@��#��2b������d_�5Cu���]�״����8v�P��̟�΁�&�e�̽�	��ҟ;�	���cX	��\J��(z�+���и`d\0���ء�(z����1��D�`|+Xx���a���K����1_D�̤�����2����\��X���'������t���)��S�� �G^�)��}�e�^��mp>0����0ĵL<�,;2��4�b�j.�1�c�*9s��:�/��f�~�/��f�~6��ܞ���Po���߆���sT���0�yY�7�.�!n����؋>�u��9�z~���D%��t�q@y�R&��^����H�81w<X�?���/o���_i_�Bm��P!�ule��੺	�޲���.#�>��yA�h~V��RN�����<6ö�'�8������'g�a��aX��'�����YB|��� �Ejj�X��V�	���H�Pآf��V5{	>r;/�m<���%������${�]����^�ܲ
-?��;in�IsY���J�V�o��߭�߫�wT�;�����]U��*}O�}�����OM������jk#"/������H�T��\[���/��ƅ����A���g��w��
-]�Э�ؤ`e&� MX�[�x�b��|�(�e_l�*��	�i㱍�Z\X���>���G��ɱ��N��As�/^���ޖ�Pz�lB�jm��(����6uX�$���ck|!Tj�^J�j�YM���!�g�Ho��*���+�e��:�vSVQd4Oߗ҆��5wh#�@�qS�H���&��j.;2������|f���h��;�xl�����P�gV�����:%j"��5�(�),uE��o��G�Co��Ѷ�;�>7u���8���^������h<dS�jN�;w|�䳦OK�1�ueCY1�T)\$��*�(`%���t�~i�kݖ��W&B�e��Oh�,� �C�J�=��g]S�/��sl�������F4w��!�ᾃ�@?7һ
-Yޠ�ѽ��݀���G����X�n�Z��D����v@K�f�ɻs0��65��V|^��ʣ.6�;�Y�(���nv���kHc�n
-�|H�z
-DRR�*1@j"
-g���Λݘ����[�@t�Á��2���S���J��D��I�gW�E�^���
-Py.4s�Y��d`Es�z�7�h������S���̣H��sq�����ߎdM����	�������\��
-�9��W|��D�5`�x#y�G�&�Y�Kn�[�[�}E�i��Iq�����9Y���FBo��#����j�"�Q,vX?V |B��߰�쮁�MZV7�鸋�EC�-��-��T֤�.�&q[t$��l���?�J����p$)����!߂NS܋$�޵�m�kAc���;�n�����$��KK�5g� ��Y�k-fGkX"<_Z�!�0_��ϗ$
-Y@!����3��U��B�5I��N���--���D�N&�,�b��v�'��g[������!�h�|	�����a,ݿ�T?Xe	��X W�9����C� �&��)S#0��]@�(v�.H�&l>!+a�1��J�W�K�@"�-�$Gvyi�$�&WW�+0�ы�)A�`��҂�e��`�pGfe�'�G�-v/ ��aC���
-͡���;��1����jaפa��A�O^���ъ�V��ñF���%T�`G�3��åO����� $1�{ZpTg��jYm�D[K(9X���>[�����;T��^IE%�"
-/�� �4u��|�"����d���/���%ն+���o��ۑ�wx;�
-FOIB��䄰sA����UYYd�o.����b��HY�Ζ%\Ԋ�u��+B[TI����OJB��nN?���W��?t�]|m�6s�܆�+*���>��[a%Ċl���ӂ�	�����V��m.�}���� �Z�����
-jNOP���+�'�Y7װ�lfn0>`�8��������n�>w���o�����=�6�c��:E��z.�DTp��SA�^�	�~{���������o1���9H_�~
-��g�>䧏�{�zG���o��zg���_��Դ���j�'7o�����n��͝>ډ��c?������1���f;�/��#+oT=]��XR�/j�6��ӎ�5��ʃ�>3PA3SE|�G���Z�L�M�O�R+�/d�wz���z5���D�._h�僊쭌� J5�N_1N� h_Дe#5�S���<�?9��i���)�fx�oUX�%š�+$JcL��{���1~�$���W��#�ӡd佴7��ǎ�wbw���y?}�3۾��ZR��@x�ZB�G6����P��]�i?���~����'ڏ�{�_j�����gZ�~���ot��:��ot����M����]���i�h�V���Dg��u��O�7�����H�?���ॉ14'�мm�������4!Y���#L0̉;���M����Lh.d�ܞd�7������'j��2��l/.���:���P��6uX�
-˧D�U��}`(Q�M�=4�����x�v����i�+���Iy��S:�S�&ry�	Js�!:��Zn��I�
-�q}��5��A��QW�i��Zjc�
-��/�C���q�,��TI�U���Sv�]����K�{��;��`�O�&W�R�H#�ЊӮҴKn��/I�������Е�ʄV��I�ǫ��äv�Jq�L�z�3�i�3�iw��.N�X�K�al��Ű�E��������%X���7����1�%l����<�g��	�K�C~�P��&h��z>��bu��,݂h��vڧp&�-��r�/p�u7A�0��ї|.a%�m���J�ؐ��]�­�'�G@C+���Z%)�&����v���}�p����J������IޛЃL��H�h7�~���.h�ȱ�?XP&[��yvA�A�8l�$Q���6��:��
-�Y�?��O'���19Bl?<�`-5] ���j�Ҙj����9e�]�{gN�(�f�:���(��D��,���Ex��	"���sq�6�o� ��C�"s�IO7R&5y�p8���e��T�c��Q��a���X����ʺ�ܳqӺ���5á���7;3G���9EJ�hV4��L]�m��k���g9/�����tH9�WjN��5�ș.9ڂ��q���.w$TgN��I��YE�V0,_+��"�/��~��X~C�5��NZ�au�g��8��({*�8���ީ���?������|{�8�7L��v\��/ɗ��X�������|_�|L7�;� ��綯0-�X�E��'��E�)������P��!��	�Q:��z.�����{9���X�;x��9?{=>��!h8�7C��a�q������,p�o|����c~-�<�7��5�y�o|����O��	�V`��'�Z�y�o��kE�)�qگ�������<�7�����Y�qίy�s~�_+1�����Z���߸����~�s�6���o\�k��E�qɯ��K~�_���~��v���߸���W��U�6ȼ�7��5�y�o\�k�y�o|��T�K��_�_����Z���߸%7��M�v�y�ot���f���hU���h�9V1�)Z�9N1�+Z�9^1&(Z�9A1�-h6)�DE�Ü��m�9I1&+���Ɋ1E�ts�bLUh3U1�)���i�1]��4�+��6�|B1�T��O*�E�˜�3�̙�1K�~h�R�يv�9[1�(ڏ�9�1W��؜���O�y�Ѭh?6�c���'s�b,P�?5(�S���)�X�h?5*�"E���H1�V���O+�3����xV�泊�X!:X�-
-�A�b�*����ѦP?�)���k�b<�P�=��#����/(�Rr8ͥ��La-���Z,c99��r�h'G�ٮ+��s�b�$�_������J1V+u��j�X��=d�Q�����͗�e�.f��k���1�*�+J�i���*u���*�kJ�o���u��o������|C1�)u��N1�T�5�T�����̷c�R�[s�b�����|[16(u�����Q1�A����� �c3d�blA�lQ��h����M!�ڦۑ~�b����*�{
-��c��P��
-����B�}�إ�@ڥ�o�b�Qh �Q��
-���Wh ��Rh Y��Ph %#��@J*�>��>�� �ѩ�@�T�.�R�b|��@�@1>Th }�)4�>R��
-����B�c�8�v?����A�8����yH1+u�7+��n�yD1�*u��G��n���bS�F���R���q��T�����b�P���<�'��4O*�)���S�qZ��g�b�Q���<�g��5�*�9����s�q^�#B8��)uc%�3Ÿ�ԍ����R7^2?W��J�ɼ�����ו����g��4��Ŭ�A��·=w��ǝ����t�^��~�J�T�_�ҿ�үT�W��kU��*��*��*��*�F�~�J���h�XM���5}��7i�DM?t�>}�>I�'k�M����4}��?��Oj�M���4}�������>Oӛ5}��/���4}��/���5}R����?��5�E�[5�Mӗh�s�������K5}������5�]�%}�����U������k4�%MY��j�+�������k���N�����4}�v_�~����3V7N�q4�Ǽp�^7.)�9"��T(C��QX�:�������f�����ڶ.+9M���%%�=��{=K����Ҙy>����ʉV�'��B+osF^��Wٻ4�=��e���V��E��9���S��co{����He�we:��
-Z���AB��A*�eA*��T ˃T�A*�A��� ��cU� ���'�NS�j�r�8U3�f?BQ��^�	G頟_T#x�7����Pg�dn*�U��K�2���|B����黪�I�P��*yM����`����N2g�����<���R��qNs"B/�}p�\RSr�W�[��@n��B~��2�{����o�a��<�K;�d��2��3%��r�<��\�}��+j�����X'¬�.���|��9ܚRx
-,�
-��q�/Q}2/2΃��D<v��-Z��\�?ߦR�^����vr|͂u�GC�.T�i*Gp�5���اR�x���R�Y��1#]��<����	�SJq����/Y��'�A���0�,/�#us�a'z���A���aj�Pv�FHcFtx��.%dm��y�g՟�}y�TI�ء�&rR����/�Xv�}_-5(x���<�u}[�����l v�ǲ�<�"��.��w���wy��Z��.�$��q�{`^���c|���Qx����C��(�Cm�o� �6(yY��q;���4[�i*E���t��Rv���4�vY�tY�m=i{8�Q��!%�J�g�'����)jW>�}h�C�}�w#��Rs��J�2�ՎKV����� �CY?`��H�Tɪ���P��\����LRq�~��+~�׆hՒ*;p
-ˏ�_F}N�lˍ֐w:��V����nv�v��G�"s�7f3���:�Y�HH�����+UBc%��y����t��4�
-
-�B�#������QPԅqB�DB傄�.N"��Nj�dC��J^�.�p��'>A�V�L���g�����x���U>�O����f"o-���׬�V`�4�|�K�YN�l���D����Y!ѧ�\�Q��}CEO��a}��hnsə��<A+����X%�С�=���ǥ���Que�D\=�Eԕ�-ᔤ�j ���}�8�ul ��$;�)^���h&�����b�V�2YN�0Z�|��⭞1F�4��yX��m�ޱB_��qB�r�L�B*�V�֯V���f��@�+�p��1�vVō����^[<�6���L�N������<b��Տp��ו��R�YU_�?�Jvi�:v>*E^	���ʿ���k��9�9�����J�t��4�is�tHoγ�cB ➼~������6�%$,}�_�pv&�6
-I�/}���uA+%�sꗾ�a���)�z^|3�yq<��̧0_N�����DS"6�k����%s-$�'�k���f���*r�
-f���� ���n��m��Pd;%���]��5�������}!7�r���Mg��J�b�hc�v6v�q>Ff�#��%H� r��S
-zSA��z�����HbW�YT�t�6d*ք�u3cr��Gݫ��� �b\S��k�q]�72�� 6#pˣ.ہ���.��'KY��M��'Kx֝�Fcc�Yw"И�Ο�?zN������e?Kٺ��pY�i���Q�ʚ��-˛S\���]�㮱e�B�f���Lb�_�%f?��	(y~ �Qҽ���%Փ��Sz%��	��$��+�TN��q���{��J �hi��+���QӬ,�1W�������~�WT9��QIv�8j�t o�4'6,L)�Pr�Y�:y��5%�,����_�忚��c�*�򅒞�e��e��YH�!h����\GK���3�B�O�S�a�ן�gM�'�,�O���8wEO������Ew#�,/� ͔������acY�Fn��@�I����_��I8_���,mܘ��l	�����s�g����/����b����֪��2;@��R�-8r�;�:�~��h�OS��2���e���-!��������ѵ�e�K�CGl��Zfy$sIY<�<?�)h>'\��f[��
-�_�o-���q��ʼW߁[�!Q���2�w���T���t��eY���4���g�G��'�%�8_�F
-Y�ap��0ڲa��
-����XA�;���܌����e��p3�oK7�t9U����T�I՝imE��%3���%6�ۂ�s�9[��F.���m��[z&�Ή��P�'(�9ސ�͖5)�nP
-�K����d���4�
-�se��+���<_���D;��<�h^�Dۃ��A�In�(s/���w��P�;i��&�.�ϖ���M��Erm��`���; Z
-� ��s�</9���_��6��)��n���;=�*�!���E8U�}�.���Pop�Y�茞�f�ٶfg��l3�Jw#�������%�:E(:a	��fˉ�Q8�͑��p�u��&	���[Qr�w�̬.�)�fe1�H����Ag�&{��5�5��2Ԋ��s��f�~2��h�g7X�:�]�}}7�u��N;W������G�%���hɛ�ă٤`����0�ɑ�#��4�N����2("I�) L�E�������F�����,���<�º�a%zV�7aQ@���P�pQ�U����+�j٘��J_��Z�Im̡�Rbg�=w��o
-�ܪK�Faɞ�po��a'{�X� ���=�oN�j�\�6��7eo+��Vӕd�p���.��^�{�3O�)Y��J�K����vM:��ڳ�����t�>��.�!e���ԙ��iC��~�L"V�����̵��/�	c~��[�H�=�bs&�
-^��B���rlf�f�;�Ρ���m (���/����4�e {�f`�;ȃ6$�w$�d�?0����iH��R�go�;r�W8#�W���X4�VԚK+(t�V�q���⵬�gU1��U�Rle��Ob3�w����E�{�L^����b�e����<��TN0Xȣ��-r�[���\���������U�����*�kM���}�2ڄj��/��@NNa�df����:����{ܡ=n�}�E�!Cp��~i���ʡ�Rhi�4�#^���Y g�����'���T%��:2x��=@p"�q~Q�ȅ����Oa��k�!h�g�1?�b�]���|[hv�倷� �G8`���b�pȆT�;uAA2ꦟ<^��H�.Ds[�O˱�X�F��Es[#/V�_Ci�]9���
-Jn��1���h^��]�F�UPX4C�#ؽ\NQ��d�*4������N��Dn�w%�o"���M�� '+�t`�VI����&�����o �h��y�K�t��.�v,}�BN�Y��b Pf�օ'�,�B�J�`.��,=�`�!�7i��U.y�΃;��%��n)� �5en�}����Ⱦ�	�E��g
-�;'9'YZ7$!�v�	z! ��L&̪ƅ��E�¢J�GVEDFQ�V�����j��z��ww��%�Rfꀽ����aU��)f�_:��g%1��J�Rg%	�hq�i��i��x
-`i�#�-j��|`�3��i��1ЇB�w��].=��b]�y���2hY� �0h�� �o��0h���p�������k1	�g�cr�}�0~,��-��f,�?,%��u����Ɣ?V��q0 ��9@h�Ja����"�SN;�����w����5��{����.H0�?�"�{�B����w��L�ay���a)�Q0�H�+�*��4f�~�Z|E��}4���X���DU �d\ P���B�O��3 �d� ɹK$�N��L[<��-~(�{�;RA^p˒C �w ;_�%����!s��-2{�$h��+��cbvٞt�=ۺLϷ�����T� uK�r�.芵
-dU��!v2D�0��àC�N�q �1Tt0�p�
->:ܒ�3���q
-:��A���8t�K��AG���$�(�:�E^�񠣸��i��o�q"��O?'��"ɱ�6�9���P����� H�4|�XI���
-Kn���7��B�7�5��5����*}|�/��>-��`(�� ?��r�ָY9�.ѲLC�
-H xS�����)�J�j��z0l�9�Oi�	6������n��jNs�j�U�s�j�S5�9N5ƫ���T-ל�BV ���q�?�+�:�xc��H�N�\Ì�QW�i~3{/�*�q��ڸ��#��߂�/A�����.����G7B�7�VÔ��-�)�Rq����$	Ā�C�O����0QyIf�O���?�v��Dl��wh-��7�z�wS��Q��u*�����`���l�/7$)�*[�K>D�*�et%Ab�Yr�H8��cT�Ire��8�D���X$�
-��c��D$I�΢;�
-9<�w#�8������{*��B���9���k��D��3I:�,\�-��l�E	�&�+�ɤv\w��%)n$u���F�����d�$��1�BDDݑSA4|�R���>3.s�P@�݉��e����ƃ��s���*�d�ٽF�3 �l@���a�4�"�S~�ԯ�*S+��
-�ڏ~Wʡ���J�W	�*ٺ�Y-Ci>a:�~������N�$X~�p(�L�A5�˕Sbuw{\��F�\�/�D�`�z? [��M��p)]�?��E"����ds��!�A��b;�7��wv�� -���	r�x���x�q���*n4� ܫ�^#��t�&�e ��k2Z*�*��vD{J�
-�瘲L:����NN�";m{i��Г�v�)���։�B��DM*�H}� 7��iB���L�
-9Vq����Gw�(["�G�����C�U��\"�L�5\��H����l�b���i���YQ�7�oZEP	���fo &*;��4v	S�Ye�c��Xk�1���%��O˶ˬJ���mꀢ�#Bц��}�j4i@a�K&��A{f!B�"�p���z� ��� $AW����_ȸHe��s�
-�g�2f1��j=Jh/��X�Vf�I�-�h�dN`�W��
-7I�%�K�?��5�#M߯�k�M?��4���������������������~J�Ok�M?���4�����4�sM���4�����W��o7'��d���$*IsRYZ����<�M%j�T��G�j*W˧��*[+�ҵ"*_+&�~��֟�м��VB�h���VF�h��0�|��&V�m��6�0�n�����OS	C-@8j��Vy_�9Y5���U�i}��k���:�_R��W�o���v�S��q7���1��[�X8�Uk��x8� t��3 �8mB'�s"������d8�p�8��s*���9���Z��	8���JF�3���	f�9������9p�9?9�r�\�ΫF����̡�p�g�|8��)8�s�OWk�FЗ�g�=��Tk9#�gu'��$�b.����l�s	{�����Kٹ�e�\�w9���Ε�Z�}��9t5C_]M���:��/q�KH�2����j���U8_����|�Z+�D�78tB�do����où�l��v��q��M�V�\��l�[��|۹�Z��vn�����՚�v���佌s���;35|?�`W�V9Bߍ{����^8����y���(:�I��cg���섳����a��>�8�g�g��2e�8f��2�p�y��G�y�7���TU��*�]G}M��1"�x5�#�"$ţW?�0�����㕫�Õ*7�~��fV��iD`�212�0��p���2�!����>��AO���/�����ģJ�l&Z�_��<���ȁ�ͤ�4�_B��j��@<��/v��\�j�
-1Tx��������U5͑_�zb��%��y�\�,���BH�i��:�>cj�j���g|ʹ�h�X�	5�B�W�&�N�s�*�$x'��\5M˘Sx��_��5��E�
-�4|0�����#�g}zu�i�h��'���$\�`x��g��)B�	�G\�j��\#��a$�O3>@���,��)��E5�v�����}�g�H|Z�iŧ�FS�,�SUc�J�-��P�U,}I}���i�"��n��i�$ԉ|�}�F�Ft�t��>�9GK����)>4<M�b���_	��4,�� V_b�'�ި"�烡ς`"Irrr\5b��3�#}�G�$��J>%Ubx��**YiCeJ��G�Ȧ!%0��c{���A��|9��`s�Ou��r��wyIm�t򾆝rg ����@���R��'���V	d�Y��8sp2z�>}��f�{�v����:��F����V<��w����D�r���&��о������fv6��9�f��k1��<	Ρ'X�(�6�^l�Z��>ܳ��R�W솘A��9��x�!�RC�t���)ײ�ef��d�T�Y�˘��q�1Ş�Y��t���bgQ� �T_���{f?��~��>��oDʳ���)��~�sTc�J4o�U�y�~h�9O5�U�L�f՘O�� s�j,P�����j�j,T�,4��"Uf.R�����|U9�u�A)E���x��N�D�}Y2��i˪�q��Yƿ������<�O��RY�r�� �>]䃸Wd���rE\
-8s\�E�����M�چٿ��%i��,�"��:Lgx�����Q�|5%��s�<5%�ӟ�jJ:7%-�biY���_�����=��{Aw�s��k�l����/펚C� D�E���Q�3��gжW����ܶV�U\>��g��������}�G�.9�9ӡ���BsҡN;t��*D{�v�%�c��a)���(�M�ݙX�M��!�L��t#a^���V-�A�QmZ ���#<��z�����i.��|V�ˀz�~>����Ϣ��
-�<�H�a9�^ M���'	�敲��1����$%3��x�4w�ݠ>�\ߑ�/(ן*׿��o�\	�B�ȍ�Gb#r{�,�E*(F�Ĩ�X\�W�f��i^ƛ^�y������F��
-��WKI{[��u�_bcT�>���xbH��쐣.���'{�H<�'($������r"�sP�J��7����s\2�L�V�H��،��P��qy�G�R������s]�C����N[�h�rŇ0����uz�C�:�M6���<��a������5ղV��7�Υ![|�[|]I �0"!@��.g��އ���!|;��|�x���n�+�����V���\�t�#;!�1�˻��tag1:[-�cu�D(4��*�Zo�s�5���.	T�������U���Uϋ�Ph��v��7�B����Q7�����̐�0�lpQ����rKަf���&6u���؆��\n�<\���D�D��f&���n����%�}�¾4]�;Ad�E���¾o'�oġ!��Bh�p�ܟۭ ��2tz�=)�+i�=$�����@f����sﻓ\�\��B5.h���w��|W��]�p�������������nn�\(G�p�D�M�mB��
-�Xᤪ��Cił��H���ʏ��'ك���sM{33���7�A�A��D�x��L�),��u^B��zK�Y"�9����`�p�r�t�ϻ��{�P��j��S������Ѝ �[C�*��eyP��թPN%6�Ӹp�7L��O��ֈ�|zV8����C�pʹ��5�����{�>�0��o�z�#�X5ZT� Ң���mU�6�ڰ>Y������X�6���a�J�Z2��L���-���E����c˫�/���&o��l��v6�W�m*�bQ�Pa�jB�jT�eQ̐��	9�qF>e}�L����\(5�4�%ֈ��9V2��7�4iX4��<����qw�#q~�ׇ�}}X�td�Y��� �WT��gV`{3 b�t�:,�?��}��C8�($/��^�I��e����QǨk�ܝ�.�N���t4�62^���_���s\:��MB�m[���Gz�6��
-��-���]�͓ ��N$���R!D{T�4�L+�Y�π�j�U	��M�$W\n�*E�;;���m�>�u/1����E�i�(�!���a9!��J��%�~;�"#ӌ�܌�s��Ud���Fn���P1��Q1��i��Jv8�CB&�%
-�O��1��j�S���3���0� �c��Jh5�'�O˒�u������4��������EDn:��U,B��S_wmG���<A��19-o��<�������اr�N�Ϩ6��p\��J�D���|5�]���Khձ+w-U�F7���Ԙ�d;�z:�9�Qe���)����S�:'�'P�k�O�yoa������_$�t+��������ɩR�j;�ʥ)6�t?+ǚ�Ő�+��i�w �;��;�슌�C��C�bE>�+�����Y8�Y�En7o����ܖ'�Xs�����Y��Z�4��-������ِ�*��z*a�������Y|���T@���lNRƓ8d9e�%Pn+�P�h�f"S�2?N�㠏g+p��5�!`qEZ��誅�a+���8S��8;ةŴV��+&ޑ%� ���l?/˧$�Q�x�����GF��4���H3��ÿ�գ��#��a��+x�2Ꮂo��gh|t��G~��>����|��ݣ�����C�W�����G�bǃ�p<��cчz��\�P��G>8��c>x�С?��O~t��������ȿ}�#l��������5�~%�w���?���t����0����U�~ߒ�/F=��o7�������%�_�.��_<�7��}�+��|��G�>�xߝ������v
\ No newline at end of file
diff --git skin/adminhtml/default/default/media/uploaderSingle.swf skin/adminhtml/default/default/media/uploaderSingle.swf
deleted file mode 100644
index 3dd31ce..0000000
--- skin/adminhtml/default/default/media/uploaderSingle.swf
+++ /dev/null
@@ -1,942 +0,0 @@
-CWS�� xڤ|	`E�wWWw���$��� �Cq�]�]�@B�IP��0IfȬ�cg&{"�'�^ "�x��x x+J9����>�~��{�����/�{U��z��UU�Ӕ)���J����(����)�c��1ե��s��-�1�ihS"�6f��ٳg��}����̑ǝx�#G�9z��Hql|nK"8�ؖ��CO�����H["��RL�`}k{�OC�ڥ66$mk�Ee��#C�Ps�%y܈�PPcØpk�9�8)���4���s��7�6�3;8+tl8�7�qd*!�ID��I%m���Pqy44��$�]&�RP��T;O�F�A�[�K�HOG���룑xS(��S�N��Pak{Kc��TB����k&'e�[f�g�N
-��M���I��A0:���;��ұ�x���~c����c2l��$��w��Q����g�9� ��몏�(JM�E����]��m6�b5����P]��`���̍'B͓���-o̻�B�ñ`s�8ŧ�P�+��T������Ɲ+7;�<�<ߜ��3��������b~��F��bC�:����?ؽQ��-C�V��w��z%��x��+�����}?-9^��u�?<u��'[�߷��'�#�����~��_y����>�u�L�y��.E�mm���-ڬ�H�G�؈�D$w�Fh���Y�1o��'��h	�z��Jj���1+�`�j�<��9#Zc!Q]3�4����[d9FU�_�B/�łs��D��#-��R�X+�mU53�ڬOiE��b\S$�8)O5m�H"dV#]�&G�I`&<�љ�슌9�KK��$ܵ �r�d�8��9��������Y��i��Z���x<R�Fs������Z�B�D$�VL�����ڂ5����^+wh-r��-��.��de��[��5ʐ{rk{<dyk#͡���ֵ��P8�M*�5���=*Ұ���[�[�J��
-}���1�4UQ�ڌA�UȜ4>�m,=�C��6��b�V��U��i��J��VO���=O�VbUd��m�����5m��9���[��=6˪�[�cV˳kB��V��(#f��s*��c�F�R�*���X��)� �A��b���������&HM���1��a~0m�mU�h��F����[��F�z�f9�k�PN��J1<i%��RNV�-$�OC�f(Q��f�rv�[A,4� +/#.��Or�xZڛe jq�E��v<%	O,��:+$CYi���U��l�;v��H'X����O�!�ZL����u5X+^��>�d��l�D�5�lkckC;u��Jl����FL|J�%$"q�͜��hR堻��`�t�t�lLIk��6�PO,8���B�=Nz#'�WI&�O��M��f41}+�#-lk,ܑx��6�S!@�2��٩����D
-HӸ�k��}<-��-GRq�����rA�4EB�����Y�h���)�J[5���JZm�F#e���S16�h��b$h!d����ZM�Z�G�MV�5��YV�6C���Y�F3�n��ኵZ2��mMA}v�1�d4�"3��t(����_k[Zbl�᜙1�ܘ��h��-(�<n�ƖFLl�L8*�-�=q|,Ҙ53�Z�ֶNj/+J��u�d�ԱTl\�G�f5E��JV7�vH
-j�`�*=�9�c�6N�:�O�^i�hh�4$ڃQ�sr�HJ��o��gH�
-<C!����0,��6�և05�#G�u�4�F6��6�b-�����H�Q��D�Q�T��H\n�R�"ql�8Ʈ��u�ʷ����e.�qiQF�\4f�M�b&պ�h��W��8k��v곖�'m=��Θ��.iv�32hb;��9P��s�m�i8�*���2���G�� �u��uR�
-�zU���G}�I3��ui��|=9u�*,`��fy�$2�'͟U�j�C�jH�����Q�f]�ց9u�9Ty$a	dv�`2Z
-hVF�]�T�9u-��G�[�	ي�̠wP����Z���Z�%��{��m��Q�I��K-����K�����V�8ּ[j�W�C�g9�g��J�tz�?;�\NTx��_�����w��v�X�:_�Ly���5����3(�3g�܎����P^�0�9
-zc�$����
-��+��DFA)��7����-J�_FL��P�#�!6CF'��R���\������e�_j��7��rr�����N�&�����q�% �f��&e�.�+��U�����k���}X*ꋎ�P�q�a���7d��XJ1���\��m��9yp8��؜�L�ksS�9tEP{��6�����\���Yc��l�C��-S��`AR��%Ҫu�5a�g�YN����	��m~�%e�T�
-&��+�&s�pRpnk{�6ض�x�SQsz�my��Tc�R�__�ud�g�e26$��>�9�nH��G
-GL#�>g��UV��F�ϯ�E]cd&6s�r̺&�@�ܶ���u0'"3[B�.Ǔ��I;0ee�Hs����h����� Q�kXNVݬP,�[*+����iڑ�W���8�Oi�KK\�ZȖm�;����{�q��H%���Li�Ir"-���PE�5�tʠ]�lvJu5;�9v`��4�Lb6;Q�f��c}�8Ӳ��UFz퐵_���'���B�2G��-g�<��^N4Zs�E��&N	�u׷'$�[DC"�o��)No�b�j���j�2��2��ſj��	\H`�)YWGS��uxcR�>�cRf�}�$�0�I�}tѥ�ě��,N���k��%�
-:�u�OE2%1
-*��j,��f!m-3�l������$]�s�5�!��K��Kd�\��vڣ��ع��i�h{(��h��HQ�b�͹.�@���,y+c����5;Қ�/}L{�@z��>X=�D͹�2CT2ݰa��%�$7���|���CE&]�r�a�IXM�PKC(����'�[:g�H�lDA�]����4N^��O*��b�t0�n��+)�a��e��;(7z��~%���������
-����c�{�B�Ͷoڜy���Yz�SMK�t�F�ړ�.4�h�����G��r��7� ؽ�E�kZ�"t���$�Sj�nh��%�~37Uh�3��¹�@9��)K��]����)&)�S����ël�=������ŨӺO�t�c����Am_�9�<i�����<����m9��笴�<^���*�>�0���ݸ��:�i-�;�a�v%;"��ߍ�J��xh*��ʺ�+Jk'�UT��PV�\2-��][6��nrI�x��2�և��E�F*{H��Zs̺�`��]��gZ�M<˛C^���(�6� #3������C�s��|��V�5�G�Q��v�,:Gj2W�}1��1M�9O�9Q9u�3�N��ui��KM[�u?쨫>�6��2�)���uy��d�=Z�0zgxi�њ"���i�'��Ƀqd�P�\��q�ϥ���4������LՓ��T��>��ꩠ�CQ�����\S��] ������)��>>�Y�������[@r_�5���j���X!��%�6l}�?��cL�X���8��@��$���P�,�%Ϻ�d�����֐��F��^,FܖE�rsR�]ķrӥA����ͨ2i�Ѵ�#�&�c&��g��I�|T��Ϡ��]�N�7Dy,�9]tUA&πHVT�P8���9��:
-��&?m�O�^��d�K3Gئ��ƞny��J��.�l�T*F$N6gnYzZa���������ѥm4%�'P�j�K�`s�Ƅ' �rǒ,? �*�ſ���z��i?������`�[rMS
-w`Z�1��0��qۏ8Ӻ��p��HZ~3�d�ַ�H�l����h���8�XRj�Q��$u��B.�c�%��Pv�q��+�b��IU�LU�r<R�Ǧ�Z�3d�wc,8�jl��ʭ���x�t�*�9��޵�%�8�9�KЍ��,��'e�f<��H�G�!���&�.�sbvJ;�t��!�4����q�h��3�e�x��Y����|�s�ie�5U��ߌ8���F�ʮ(�TVW;���fBդ�,���-�>�d��6�D���9���9��]$-B�~ܤ�q���TM.;}BYuYv��95�-g7�QPZ5u,J�*���;����y���֔ՕV�^�J�wN�_�L7�괲���V,�.`��:%��g_�%��[iY6)�,W&;�)�&S��`k(Z��CO���yJ}��CI��֥�|�"�t�s��h�J����7�^���ֶ���ݖ�Ǣ�Q����m!�d	����PRo��'���^��p�Ywg"����jj[�u�ŦVWЮ#�E2���j��
-������[��M�8�k5�F1&���(
-H�s�xHI���5���'za�5'���K$�~�+)-��R]6�������%iW|^J1�j�Ie�e��C�Ie��U�.�/�N���uR�I�#2���nJIuYem]���i�ҩ��q�U�g�U��:���v`r���>ٹH�O�e9�R�{�ff���Hm$G�bqt����S�˫�M��9��d|Y5}'QN/R���L���WR%��|n�M�3��Skk����ol	V�)eg�`�Ԕ����)��ShB��qJ*ǗՕU����P��赙5�%յ�-�~�����r�\uYf�|=.�����R� �����{^�g��Z]SU�5_ZR[浞�Ja�SRg��Fк���H��!z8�H]yu��ܰsN.�(y���ѹ�2�́��P+�VQkq�МHB2�`�^Q����\T��� j]��4$"��� =]i��2/��4��j*J�4����gUT�^gH��V��Ȯ7��wSTEɤ�3�DE%~E��O����H�G��ʩ"�m�=%��Sk�J�1�4C�4Z�ڧ�䴊�%Xְ���gEf��r�&Y��L]�p�����5A:��W���
-+&�֥	unKȺfJ��C�S]��R�l���!�eY�H}�#�YҀ%]RzFA��R����c����9I���ش]����a��n+$�š�d3��d��B�ՔM*g-9�8nFC�@k�5���[i��䒏'���9�R��R�S�`Z�W�����0����ʚ���N���G��V�
-�B�z+�|V�=�NK�>g����k�&��m�IUo�[J[�}_�K1֥{�*�\Q�Wg��Id����L�D+fRUunF�Nf2���[��Fw]$^��k�����+�j9S��Yp�b;g,�g.��Ln���A_��2�O�.x'EZ���4?Vy��I���H�]�?[8}�#+2�z��$[c&��e}®�LV�rZ����d�f�":09��x�����j�X� (��P���	�LfX��Y[5�nR�ie���pl����X�q��8�R�-�dW�7�"Uk_���vj���1��
-m��:�bJIi݂�M���@���j+*K�؞� 5�� �=�rO��ѿ���m�o~o�'�f�ˑ=�s��K�@���.G�����<:wT[7�����s4ru��F��ᩇ�/+�8]�!,�U�)�2�-��@�o�*��jƕL*3��-S�D#3[\�ܔ��A
-ze��71���	�oV���Zf&��_L���*�9��b��FV�Ekk�7iq̴F��9�[;����޸W~�m�{f�I\����W^ B*+����o:S*�d|=&��W^&ߺ��������3Im&�Ԑ����P�a�����N_�}�r3�9�r�w��B@3
-E�:�����;u�q9��;e��b�p�Kw�/,��d0�J�>:����$�n<V���JN+s�.�2�7��1�5`Ra���N��imwкl��.>噯*�F�����\���!���cj/w ���Xǋf'�XS���Z�q�$`_�2�ў8�c�"	�:o�m�0u�ʲ�*{n��������R�&Q��	ň@x#�0r�!!�E�]/o `�ӥ���VȤ&��$�FC.��Eo���1�}N%Q����%,b��2"�@7��G�^�7qB�Rϫ�Eg�*C�ӌ������r�<H���V��}�[-���ɋ�1��"6N��#����~i�|����e}X�sИ
-{G�cψ̌�b�ef�N�v|ƻ瘌(�ڣ�	��b�֛�K�և·�q�CT���!��9�C�e�V�Z_�9C����Hʝ��U$Wδ#�D�=tDF�C�:N="�f�+-�(%b�� ��ew�W�cz�͑90�4Z�3��'��e��Ud6�b�u#�����ߢ��J!�Q�͡ƈ�~�)W��o�G|�΢�q�/�9���z��E��EMB^g���D\�oIԩS4R�b
-����t��M��\�a�jrí��Z�ks
-�ΉIo�ةc�N�!�nʄ��2��4������4�9#�mo����&�nl��F�脔^��>61���ٍ'�;�.y8���:�Q#=i7^�_~��a&c�p���N�:�|�œ����]���fM����������ƾ�0�����9�6Xw�o�H'<�5s5]Ak���&��㋷�Og䈓��J�)n�t��}C>�M��3rzh?�!��N�������
-S/��c8��O�0I1jx1��^�ȷ�x�#KW�۲��Ŷg�|q�7��F�������K�|�q78�J\�?�
-���妎!k��UG�2�R����e^a��蚉�zFH�+*b6���V��rL_�wt�����jy����,#>k�Yg��QY2�b���#��_8�X�"�b��Zĉ�eW��]��VW�1�/�dv�:b$1b�a�m�!��ڦ����1dg��&
-�_D0�m���&a�i9mi�d{X_|Y��x'�MhqspnqkKtnq}�8�j��yq����8zT��ǋ!���Af��5Vl�H/niMC��F�*������1=����9��_�0���E�\\?7��n�O�}W�e�D�W����AX�u�gX��a~4���l-���b�jÀ3b�\�a�(��a��%1��53���I_I{����
-�������5�5�x:�wj���_�~QhZ�Æ����h��A.���	u�ۤb�t�hpU8��I�-��>�������zy�_��J�94S,2ǾOw����9����qز~i:,�����m�9j[�`����e����8/�,�8��S+��Ɔ�����^�L	6
-�toL���$�64�lN[^dJSkKY�?ꬿ4�e��c�֛I��w��P�m޺��B��z�1��-���2�X@U�!�yg�{f�ؿ�%>��d=�����T��9�ly�Pǌq;�mI�թ�Fv�:�,��6='��Z[���
-[_jh�HTM�Qss��Z�z4�
-Q#+��%��'_���zp����p4h`&��Ⱦ�|�^4z��3(����$�s��V*h鶹S"sB�8]�D��
-X�V`�
-�������,\0������*uMq���^����jV�Pu]�^��J��*��^��A
-?�lS���;(�Z�&�类j�j�G�I-<����s�y�uw]�]�qĬ ���c��	^������-b}�?�_�y��X���i��Z�Zፚ�X���L]�SX��]n]a]i-5��Eˍ��W�Q�5�`E�xݫ��mS������"�Bћ2��]b����E�"j#|Ծ"j\ѧ��vW�f:�L�>,;'�@��کy��>�3������}=��6#ط�I�����	��dsr;�)Rs�_�ك�9�њA�2�y�m�Z3��lc���j���t;���DM��r�5#gg��Ɯ��#�\SNe5s����<��)��v��*a�����rUװ�Vv�K0U0.T]p!4S��:3�
-�%X�`9���#W�y���@�>B��~�&Xaf��
-v�p�!�=T��g�ЇϱB�l��'ܣ��x���p�Vd�N�ߋ�1������9I�'�g��_���x� |�7Q�N�I�7Y�*��J�O�j��Z�*��	���?M���3��,s43�Ts�*�E�l��"�zh�F�@Xf�@�DD�"p�DE�YZD�U�D�o"z�Lp�;K����E��;W��]��C��S��K��[��G��c"�\`>� 8X�\ \\\\,K�K�z�{�ˁ+�+���2`9�*f�U��&�W2Qp��½��UpW3!n��7k�Ⱦ	�u�����-p7��A�o�{p'�h4�)�>�SE��p�D�&8�mF�{Pֽp�C}[��.��k+X�}�C`�-��S'��y��pw�}������������I�/���B�i��YD��(�C������E~�&�߉B�����nx_ v#���C�E�/�X���ep^A�V����&��M����,�Nl�`���U$|xx��	�������*�(���0�3��*�9�5�Q��!���1�	�)��9J���
-ᯁo�o���PDL���O���/H~��5�� ����;*D�V�?�*�&�&��D�U䟧�>竢��P5χ"(�HE���nQ��Ū8�Rd���p��{%ܥp��]�*�+஄{5�k�^�:�׫��j�l��8���k���n �g����Xl n6���w www�����b��c��o���z���
-<��b���GT1�QUd?�q�	�IU�O�}xx�	<<�:P�c��w�*���Ax/�x�~	�˔x��u8o �Uq�s�[�۪���SŰ���G����'���g��9��%��*��@��1��Q$�������g�z=�}�� rq���%�"`1 	ӗp����˹�����R Z���.0'\���WW� �r��8望������17 k����M�:�f`='n�{��]��U��.�s\T=�v��~�pф1w�E3��M9�n�7����������V��A�0y'b�N�䝸�G�����b���⤧�g��y�����v@'�t/ ��=�^`�"��2�
-�*��:��x�����w Ls	���\�i.�4���~� �>@�������O������\�}����������	��8��ة���;W���] �<����½��p/���b�K�^
-�2��W��&*�W+41�j��Z�:�zM�4�Wk�56(lf뀛�_�26�܍�m��]�&��>`p?�x xx���x����QML~xxxx
-xxx�w�@��&*���`n�>MTaLً���
-�����  � �_ _� �? ?� i�u�;�8��X,.� �ˁ�������j`�X�6 �ۀ;���M�=�}��:��.�<��S�� ہ���c������S�����x�	<<�:�N��^ v{�o/���E�%��U�u]T�w?�&��xx���������G���������W�пօ���� ���`���'�g��{�g~.�����<CԜ�`��E���%�"`1����'��`�Dr�+�[	\|����{-pp=��0W¼X��5P�M����_�47b�z ��"�T$��DS7�Y� �V��w&�����
-��C�Æpm����<
-<<i�`�`��S�O��4��,�x�-�\q�J�4M��4̕��D|
-����_ __������? ???� ជ�� ��󁋁E�b`	pp9p%�X�[���˅�z�X	\`��CL���z�A�0X�l�w5��5���Za�$�n�z�9B��B��[D?7��!�ۄy��6on����������	p��5��[�c���f>�j���GE��yc�=�rw	�
-��;Qm�����ej�y��t����GT��^�|�l������)�OU���
-�K̼�搬~~s���w�,�=U5�WU�}K������$̓U�G5�_������s�aY���7��K8B�>>�>>>� ��B�Z�����~ ~��D���E�/H5�}.� ���B�|�Pa_�2��U܋��X�5�]��`�D�ȵ b#׹�G��ǹگ�|m~���Wd~��O�C5�\�����.���[��nv��!ݗԯ�o n6����<v<www����=���}.�~���,�f�j��Ƞt�k������1���tWU�|��4�e���b�b*3=�3)��T2��($+QYY��Y>I��y)Z�aw6��QF�U:SMˣ�(೚�hv-��NJ�۟�H�B�˳�eYP�~tD�z�n��j�ʳ쒨�*��o1���>F�)�_=J��6Yp��~�P���q�7�y���a���gلJ�-g4yn�RH�S�RՂ$M�cY4��gvU;K�v���Mߞ3����C c�R�Xx�)��4Ev���рܴ��z\̋�@�;���6�SX�[ʗ&ێ��߈y��$ۭ�?�{m�6�I�@���*�߯��,��+9V��D�G��Q�*�-�$�&��Y�e$נT��=�c�=�_�����m4yjdd��?�x�ǘGq	�����1L
-���Ԃ�=��_�$���^�~�x�X6�����'F~�IH٩��ZBMKl	�e���eG�����2�iJ�0�HG���~��T�S��I�Д���t���{��$��z�1�A&�:��_�������`ť{�L��@K��&��([p�zt��*�3*n��A�x���g	�כ>~\9�c��7GN�b�����z��d���+���U�Q�2:�ZW�ǔ��gO�t!� ��d�̵��c+��F�=�.j�!��MJ.ҁ�6�ZE�)J_���i-�C�ROS �$���C�E��V�j��؂U���*��.�2>
-2g�L�C������i�C�#m�<�i�LJѱi��҆x��"�Q�Ap,M��#-uNҠQ��2����HO���z�Z��A�%���yA��M���>��J��v�JQ�̌�r��Mj�Qi���R���dپ�B��[���ߡr�n@�7��xt�����"n��,*�6g<s�+�4�J�e���$�����gUdZ��Z��
-8�䠍eʸ�]��:^U��\Q�*�7\�~�*�	L1~��{��L1�`������L���)Y9�y��$U�̔����[<�?�)�L�SƔ�r��ϔ�	L闫�b�)��;IU��*œ�2�RU��R�#��2h��>UU�T���j�U�*Gתʰ��r�i�2�tU9v���8�)#�dʨ��r�_�2z:S�?�)��c�og0� S~W�ii���	��򇐪�1�*
-s夙�rr�����+%U�ʸ��J�_�Rv����Õ�QU��JE��Ll��)-�2�UU&��JeW���*S�ƕSc�R�JM\Uj�\��P��\9�]U��s�Y�r�,��5[U�2�+����s�R7WUf��J��R�w�4��)��dJ�_L	��)3��*M��#��u>S�s�3�D��|H�BD���v����&^�N���Z��5Sf_B���YD���
-,!���Qs��L��љ�JP/�K�,c�rF��U��+���p�f�5��z�%�r�,�zF��J�Ռ���e���7��Zx�~�?�Y������ο�[�`�{���yl#������n>��ۙrX؝V��B�<v����*fl�|��Ѻ���=����K��>�.b[d���bv?�/a[%�p��Y����8K�C�\���2��r��l�Ռ\�v �R�(`�"G�r�8"�bO���=��Yɞ��j�4�5��kٳ�ױ�V�C�z�<��ҁ�*������j�m�z��n��=�a{PӍl/�k�>+�Enb/"b{�������g��n`��޻���F�:���7@oc�Aogo�{�N�68w�w@�f�nb�nf@�a���> ��}��}����>��>}�}
-� ��!�9����m�K�G�W���נ;�7���oAc߁>ξ}�� �$��)����g�g�/�ϲ��;�<���\���|�]l�J�xh'[����f�4���f��a��e���c�@_d�A_bK@_f����.}�]���uv%�l)�~��M��-v��l�;l%��j�7\#���{�:��zľ�V��[���Џ����F�?fkA?a7�~�ց~�n�����m��V0l� �5ۨi�UO�U��y>�l��y���n��}�O�v���;@�T��,�	,џ1��_0����n�7O5L���@�oRi�٬bѩ�H���/T��-��O۹���T2��B�A�+�ɔ�s��M���u�̵�Ej_M.d[�cE�R�1��@�r��8�W�r�J�	���re��$��է@�R�]�>�R}�jP�A�	���\�N}��A��J}�ՠ\�A����F�t-(WnR��_ʕ��n�׫/�nPw��ʕ���o��m�^�o�������"�w�re���v��2�=�+�����ާ��E}�~��~� ��������)�[���|������l����Gb��ʣ껴|�7h���i��o��Qߡ壾G�G=@�G}����-�C���wU��t��{����e�gB�}���a~���Cَ�@?V�O,�SUn3�Y����|	g�����^���Z)귴R��h��߃��� z@��V����ϴ:�_hu�i]��8օz.��|���Æ�C�/U���|�ǩ�9����k] 酠�� ~�ގ�&~�f_�i /=F�DR���0~/��9�?�a�I��r0��yP�<N�y.�����~���F���s,Ջ9[±�K��<FY��e|�r)e�Õ+��rٺ+@���r���,u)�%�J�����j.���ZN��:�Cs%_���]�o ]���~�dVo���W��4G*�!���U����)�.l��wr�fq+[��o ���z�Y�+[���M�V���6�{����;@��wR)q�.Ε�]����c��y�}7�����o�(W���+��{��+O�{A�����4(W��[��+;����9�c�;�����Q��x5�9:��oC�N��w��>�D�������:x��E𘤏K���'�A�r��f��y�����G({�s�He/���|*�ʕy%F�����e�%g��Wx78��h:��khW^�{d[����G�
-�"���r�M��\�e����ۜ�;���]�*�{�5J����o�����~�������c��8�.�8��8~ �s�>���/���_�@���~�?��
-���{�9����2��?*�5�e�I�L�_�5�!��˵���
-�N�q���[tc��-��\�QWi߃��~ ]��z���5�Ϡ�j��^��^��1e�v.�jm>���DY�ypo���Z��ý	�p�����p/����p7���E[�Q������=!�k�F����$�\�+$�RRZ�wjK��.m���r�M�U�����h+A�ծ�O�t�v�f�c��5t�4�);4v�����LO���f��6�ԲFCפ��rn��u�s�&-��p
-Tc
-zF۠q�Y�bqc#X;��`=��ju�6���nk�v;�Ҍ;���� �S�S��tX]�]`ukw[�M`��mk���b�����j�Z���ڧ�֋�b��~�^���em��z �W��zU{�����ڱC�	ʛ�j��Xoi#�j�������=���hD|���#�e}����Q�OA������r��q������f��|�I����|��&��(c���f0d��P��Y���SS�@�y�yͯ����MBeN�%P���	�Bfϭ�@n�����s�ƺ4C�ܭ�n�0<�5��fϽۍ��5�,n�*�hP=\E�`TH܋h�ZK
-֠b�TE�J����{��X?�V_CC_P_���n��o�Q�k~�W}S���oi~�E�m��~I}G�{^V����W��4֫�͟������y]}3լ/T��~@]|NcRwi�#�b��>�.vk�T��xҋ�{q*tyʻ����*y�Ʈ���>E�L̨�_�?G���_�[���/1L�?������f~���*��}K�|Mc�Q#������-*����-��H����~���=�����}���nχ;�����^ϧ;W7�<�kl�nd{������|�����Z�~��;_7�5v�n�z~F�u#�sg�F�g��.֍�|�]�}<��l�nz^el�n��\��%�Q�Hg��F?�%:�L7�,�����s�ήЍ��uv�n�RgKu�سLg�tc��*�-׍#<+uv�n�Fg+tc��:��ԍ��U:�Z7�xn��5�1�s�ήՍ�<7��:�8�s�ή׍a(�U�q����֍�[uv�n�]gktc��N�ݨ#=w�l�n��l��M�q��^��Ӎў-:�Y7��l��F��͕�\���/p���z�P��|�n�,�#��Dܢ+��0�uZ��n�iܮ+�]�ź�.��XW���:�[e���ܣ+Y�ź�]�+9�w��?��� ���z@��?����A= �i�׹��z���m���#z�s��]xj;�@��ڣz ��1ݟs�����]��$)�O�7�cؓ��e�=�C�氧uH�k�M-)�Ϡw�#�j
-���ܚ*�Y�Cq���Л��~h��u��� ߥ̛�;P�7�w"�v�9������_@
-|7ZP����y|�n���T��5��������%j�:{GS>ԔoRy~В��2*�Q{��I��B��g9X�'�\,������#���e8�B�ᬿQ՘���5����j����)��*��4�ݩ�w�س_e���~��e�g}���4%{g�#�sg����.�l1\�"�^���.��RpWq6JSr��l�y�����_��Mp` kJ��8[�`!��Qn߇9������}T���ה�[�;6��p,�Z�{���n�mP;p�]�<Gl�&�4���4v�AOjl��PC��y[c�j��46RS���)GCw<��a�h�)�Ǭ!C�s6��S����R<Mi8��.;��5�xk�g��4��N�(�.b��Ԧ\��8q1'�B��z�✙�;F���6�&��i��g��D�3���j�����ީM�C&rܩ!C��M�B�1j�����r��y���y�������{)b�Nm~��7	r��^���{F���^�~]�|���]�o�|�":�M�g�6#�	�E�u�2��6�f��e�v	�m�\.Q<��E��o�J;�MQ��휞�U����X|o*�f�׺'0ݟ�e�ř�sz�1UiZ�vT(�5,0T���;z�]]������V�=���H��ޣ�?�)w�VM��:J�t	���
-,F��(����
-o��zէ�2�3}ְ���/���byg��:�W�^e*65��cԌ/�Al��/u(:e��J����_�U_�o�~5�8�jƚ�A�װ���AqW��Q�����9�
-Dx5��(sU����U</kR3�!�:�5l^`wg@���t�@�Z�t�R6+@CN��i��r���\�$EHR�ZUP|W �.����{�=7R{��"������ �?�I�Q�����B��iI�����)�?���=��EN������R�sY2�F
-�g�\)�����3%���i�����ۘ���Y��cf���b�Q-�V�N�����D��j������cT'1n��A�wR��3����}Ԟ��a��f���,�{B���/3����g��˿Ҕ�=�uv���Mw����AL��Rm�L��z��꾈�M�������#|/+λea��ˬ6\Em@�z�s~��˧5��k�]�]H�^�k���xu�v�����J�Bu�VPwo�KͿ8՝-�$�;[�;�R	�R��i	�R�%�R�Ke�0)�b��7��Љ��wґ�A�˖2� �z���bpP�e�8�c��	�C�é쫘y�寪J�b4c!��ڑ�^ӽ��n�Lwe��۩�K�/�=ER������M/���M/R{�%�h7Q��"��Ui��eX�t�V�J�5�g��a�'Xg�a������h�?C����&�cH��\ȧ��wW��SyW�5��
-��\�1�(�Y�a�
-b���9㠞��p�>�����{����L�R�}}���tg�u�xj���\�;�DA���~T���樂�X��]P��3�!�j9L)M������褔7�ڬ�Ѭ��z!լ�d���DAkRS���7���n{�w���E��Z��o�PQ���oJ�����
-�g��
-�C���nf4C�JWw�V�W��t��3����c{����&�uA��n{�eC'0��گ�3��_�_��p\�=�w�:}X�1*Ċ�-��F�u6��jVC����`}6k�z�bQ6c@�\c�0?vţ�����~��z��-� �g���Y:H�}T������3��x��1|��LE	��8�C�L\Ĺ��(��w�j��˃:^-x��ՃXP*ǚ���/�yD�[�;�nf_�~��������.M��H���i��h��f���;����
-=}x�����{vl^6�������vh�d�ScH=��R�s�����"eS�q��&��kZ��T쪴�D��̢��ņ=v���){#Z	��2�f<�I�i%#�m9��-���r��� �)_�v���1��Y�V�%�<c�ڥ�Q�� �����ϸ�P�G��PT�r��Ӱ�}��h8^i�W�b,�IV��㱖a��c	�J�v�N�zo�H_���8�g�K)!$K��W�uA��nH�^KJW�3�d�v�~��X�<2g�\�ۓ���r�=�0�aUhX�����'��)g �T�b-�*ģV/O�̬��T(�63vYLLr�Q��~
-�\�;E`���N`A*`�'@�f	��Im�m��l�sR�������Z�ev�E�����X���V)j�(%��x��%�
-)8��O�/��\�7�-�|�mRu�V����t�W���vm��*���	�a�u0k:p*�A�H�N*<���5Ey����Q���L'��]��?���u��ЕY%�)wp�Xe�0�C�b�&���a{P���]�T>w���_�$wK���ޒP}��˿��6�6!�x�]��doN��=ɹGr�%� K���ܫ�~T�/OR�1U�=u�C�Ww�q�2Ͻ�L��4@}����Q�Q���^�������z�<�u���7Pt]�F�2�=;����w<؅��0Uw{.�=H��x/U���2���$��*�:���9^z�����(��@�趛��g,�h�b�������Y>An�C& ��fj��T��������;$��~��4;�A���2��Fda���������d�/��U�7ʲB��%�o3ʯ2X�Dh������y���P�>���|�j��!Y&$k�2��A2q�@�H��T�Y���ՠk���CMS6�4����w5nƠ����4�Z>�n���3M%+��V���o˄n��uXFw�j�\���eLiZ
-�YJ�rh��lM����>0���e`\�b��46���Ȥ�t����I� �2��
-����{dO����Orf9�k�3:	s��m_,t[��Q�sUEJw�*�3ƌ�Ԏ���qd\��^��_�Fs7�^#9{Y�Ueŭ��&���%�ڐ]�U�]���i���������n���˭u�-�)�U8S���4-����ِ��J��J���u�W�n�(N��|T8�H&(..:t���DC���ڳ��Ai�j����`֛t}Qo�b�_MkْQ7z���܍V�3�16�n�_cP�����5䭖��Lσr�_0o���kR���ħ�g�g��R��!�_��G���y�i���u�{��Q���J��Ϊ����Ko匎QK�}��H�@*qW�~�t��k[fѷˢ�v���J��,կ�T{(��N�����R�Vܞ��-�����h��<����j��D�DO�q>��'����J�?-O����5���/;� k��;�G�i������%��I�M&|�1S6�t5�!S��,@��3�������-W'օ�;�
-�k��@?y�=��lz?�댉��}�~N���3{��sOWg����z�����F��O/���%G"��Ԭa~�6[�f!�C|!�3�nFR{�����}�alD�N�=n�2����h0��ݝ���BX*7��v���e3V�7�����eo�F�k�e�ʨ��^�
-�J�7�k���q�2�q��MOC���,���'��S��w�o������Ns���&,�<k�����_M����}Y������r�M�Np��t.�UP���:�}V�̛�YH�x�Ӽ��������.�k�i4:��.���#�̒��܎pCDg�-��9HV��P�킮�R���а"%y��k[�|<��Xb��+ݲ�]̚D�s׌C�U�*uz���8&��t@��������]�4���%���f��:H{�/�AY��l��t�	�[��R��0b���=|�j����R�h{��0��`$uȣFG�kǭ��)�Y����-�i1�`]��yìS����Fy*�N�a_h��H����N���E�ɥO�������Qu�̾Gf�K��m	��bF)�2����ؼ�{2m��{��[6����E*�/�/�J�r�E��c�;��a{�=�u�kdKk.�A���ګ�M�%�&��C����4��tg�����A��wM/F��&�����RK#���� �=��bA���\�|ט���ۘa԰Fڣ;��Ӎ]	C��ﲏ�]�ڹTg�I����#O*�'HW�>2'e���^�
-�G�{��pQ�DN�Krb�����ht�4]'�V�IK�23L�g�&�Pi�	*:���ڜ�(� �AG6r�&cr�>th��M�V��`d�vdGu;vY��~A�w�d�靽W���d�(�/�d�,ٯ�d�*ٯ�d�.�o�d��7�������u�C�F�!t�3��U�a��66΂��������ݝ�y6��4.���e��������j�*?�b:y̲6�z��-0�t��,�T�U��R�(B�EҀ�~���!q�]%�h�kNp�z�s0Q�GF�皝T���S/:Ʋ�Uټ�I�q*AGqՕ*s��+̍�J�x����c�}L��	�묺�P����gt��C:��óx xS����N�oʬ]$N�o�{g<d�6��,Ÿr�6��|,�#6C��,�v��}A���fh�)�Q���N����7�b<n3���Ř�[���G>S�j���U<h�9x���C4�U��@m�oM�;����Ȓ��	cƓF�)v�Jt�����/:7&��d�6�O���l�Xv��;����	�9�B˙O��l��K��uAx�)99��kL�r��~�kI�E�^(��v�xN��C�J��i'�a��K(S�&Ts��u��F%��ҳ����ﻯ�����f�ht�Q{��[</�^�s��#���7`c�;�v���]�.U�> �)jt���e������2+��=+p�}��6�IIL���=������+(Ҳ��y�cY(~��J��U�$�WN����������>�:[�;��^~���N��/�QTG��t)��7(�d��<�o����h�Lݮ�N��kFb�[�ѥa�7:rsQ�qHV˖N�J�݈�{�u`���В����qy�CG���~����P���t��{��^yD뮺��F�_n��X�Ln�oJ��h���x�]���Oּ����Fn�:���k�:�Y�����<������e��N����3<�:߼k�XmГϞQ!v��E;G5���#��ڊC�vz"����/�`w��~��JY�3:�{��f�-
-K_U�䚂�0%#H(3w�w��L�87	L�{���O�ly$9e���_��{����$:��^,�8��{:����|M�f����Zo���s�i��}v;b?#egOhaȡ����k��Ӷ�C̱	]�v(�.�.�;y�w?]%�{F�:w��{M��.�BT`ADT$$��@n���@��� .4!�eu�㮠���*Jc=&�0�������|�Lx�,�0�����w��f6%|�����@@�n��}Ti�jI���f��y6+�zm3�l[��&f�VJFX��IE $��oetžӃI�II�$6�a.� ���ꞹ56�����Ve�/���ŗ�Q��KK%��	�}g�.w2��f�a�/��v����h��񃄽�w�����y���(�t��Y�!4;�Sb��y�!5;^Pr��Ešx/)����p5;^Q�f���ݡ]�[��	��Hk���_���0�=D{���>&Blŷ�ǔ�&�Ar�	���4䶥K��3�b3�RL��ߥ�#H���4�ӟ���4���L'k��Ȍ�*���41<koӌ4T:�P�(�(��I@:���0�F�2��Y�m�SP�$J����_#�������@��^�����n��A�BZ�ca��F�Q�0���
-�R	�9>^�s�,�-z>pʪ�����ha�m��<�%8̶�>�� �-@�$�#W%�s�3e�Ӟ1Ā�o�A��
-*�8J/Q!8e�w�C�UeA%|	#��v�n�g�»���5 ��%?Z���[��Zvnq�o���,H=��2䵶�2��QF����'묙�P��S�z�_��Nd֙�RY� J|����Cn$��:2��� �:QĒ��K�r��j�0!���^h|P(
-��׋�!6ں�yh3Iou�+�QaA9t+�|M����k0��-:� �ާ��p4�O��t��8c�+�MyS�	������+w��<�E�Z���`v��AJ�VF�&|'�s���N Jvq*���#R.(�aJ �l_����@�us�N0㮙	Ox yYϮs�.c9��|�:���Ohff1����w�S����":1�R�����
-�&��%�K��8c��D�8��T��w܌.s��w���=�J�}���@��؊9G;?�ѐ*�ra4U0 ���Hʼ�ψj��$n��.�E'q�	s�Ð�������2��?���4����=މ�eR+���
-}���z����%^'�-��k���t�L����>��F��%����22;.!�X��v~��b&���;�PBQ��TQ�Rnw�?Sz���#C���s��JR�H!�T��z�,3��kі�S��<$ mȞG��M��;ڳ	M��D�H�F�4�l�p^/�b(6_���W�7��jx��Q=��IoV�7��[��j�6�p93:#��>��]ߡ��T��/���K߭���.�/w����8����ծ�!h���-:}��ֈ���3k7�,?:e�S���X���me�v�V�stB
-�"�btG$�/.̅�U1v3*;0 q,(�WE�GC����*-�Q���+�׳�9סmX&?���77��	��}P �����w?�����o�n���F����$���� a�ي���4�+�+@��#���*S��(�H�6u��_����3����U�W�!%de)�4���Ƭ�Fk�7N���Y#��(|��'�t���[���;v��(�,n��,.I�mΑ�v�0R��$��j�#qI�M@1���h��_Uی�w�]X局�$��e3.ʵf��g�o���f���`������ H2��N23�	3�l����)f�>���c#��E�̽Lm�t��4�^�%�
-�Qږ��� �`�<�z��))|��=%EF���6"E�Rx����HE
-�$i)2*�o��Q)��UҞ����%yW ^��G*�o�b�����~��8�J�\���䒕��?T��c���+4�Ә��Cq��rRN �)��+�� ���iȚ���W���`��b%��G�8��enX�@5��Z�q���Ml�~Z4\�����-������Y*�?aMA�Q�s`���<l�ʜj��ͣv��|��+�����X��g��������OҊ	�`���i՞��JdL:�Á�A1β�Q�^�۪��T
-϶�����j�5�����t����(�.�b/`�������f+z���\	��>A\;����~5�E4/j�7�ks��^��%^��8�93�*l��\�����`d;^�J�r�2:GX;W�,&�q��x�b�O2���J�	*0�0PO�*Jd[ _��ڭe o����U����3���
-t�c*�W�����*�R)�)��@v8�}t��R?��,�%����g�;� �X ����5��#@�ڱ�:�驴�«��gCik�A��'yE����e�!�p@}f牪PZKB�A	��}"��~��u�ٲ�0���vF��Ͼ30��B�Q���qCă5x�	' L��6�v �Ǌ�E� �{C�%@m�OR;ߐt���ر�]x��r��W�D]���)8�OVt:����*E�p��7ŀ=�n��m�?5� mA��[�T�雅����#�4���&�;_����ץx �����$#G��1=���q_�4nW�3�=����qo�`��щ�[��f�נ߼vX�!�ݎ�tu�޸L=P�H�8`Z�Є����ʕ��q�rH�(�T<\Qm븬�tr�*�nQ9�6�V�/��Z��X��.�a��QZ���	#����2���{N���y�ꄰ)j����~f�h�8�b��X�0�͎*&��8S4 �u=�d)�UX�P��[2{OSӧ��1u9)t��jhA\^ Q?�	(B���_q$����*�!g�:1��"�DN�K y�f����(>K4�n�y����3`�V�@�\=oI�η$'�:�:5�E)��Cr㎀Λ�h�X�o�Q�Ɯs���ʍf��}X���kBAwz�e�(�H�q�QC���D�a\E\zޖ`�ߖ�]�k�s� �Ȑ)�tF,�QI->�6F�z�/��aF�	��Xch�+�
-���l}o���E���EBl�yj����������V�� ��E���Z9R�������FH(qO	�H�����{�C�p���]�#m-��7��g�=��G~{���ܔ1�~Yư���g!�F��A�L��^�~T��@�Vbg��W�2½�i��
-���eA�v���,��VHm�0C���Às��b?�_5��s�y�k�����5Hq��ئ�Qp������f}'�������b�>�F7B�8��(�����z^��ϩ_����c_��d����H�G����u��[�;���"�Nz)���N'�C �u��ԅ����yՏ�^����O��ǫ�T��ֆ�}.�}T]ܿ�sQ`��-U>3>>���.�Ppj� TB&g�	��0R��/�UO]Xx���n
-�����'���2�[V@�{`��b\�>_z^q��
-K�\R!8�,�7.�nb9v3(�[X@�����m�Ct�w$v��;�-2<>:ϗ`�f����|���������(��}"��#a%�&� +�����*y��N��>��mՉ
-P����d�K�|S�g\�/�9J��(�_��_6ým�A�,QF�s��-ARݞ?�zU؂+I[��TtĿP-lE�ؕ>62�;t"B���p��L�-�,���NpH�r����x�c��H=���ԋ]�f
-��'������n����q��wQv{�Ⱦ2�2�T[*��J��>d�����Q�H�;V�Kة�*.Tc�x}�8��Ŏ��h�L1v�H�I�r�]j�V�6[}�VGa�U
-\H�߭�J��֊?	���'�N7�ڣo#��������[%f[%���������� ����K�����ȦĎ�����v{��+����pD��NI�ޘA��k�A���a�Uҗ�9$�jحw��s�n��ƥ���l4>���A�G{Q�?�ʹt|��4�1n��>qi����$Y��Q%�~̏��x�ffx�9�	����4��m� ����g9�τP~_0A_
-L����/���u�7�N��[;yf���kٛ|78�x�@�����������8\�ο������!i-�	tt����l`�!�>�}%�	�˜�?�8t��gdnR��~������z��m8���;�~d����xJZ0Kj�s).~u	(��=��-jRJ�i�st�ϏO�4��<>&dMBf��'���ͣ�9�}���Sd;\�A�?�5Uz�e~��;����_Vlʅ�`�$�=)�~J�ޗ"HᲤ} E>�£��!2,��OQ�6/�vɨe:ND-���ץ� ��1�ף��Z�����s*�,@qC��{��{!��3���i(��b0w�}��&O�r�麨��e��P�_k飾�R��t}ԉ�HE;I�NF\�D`�H;)����ʂ'aoP}#Ȳ$��R�����Ɖ��1��
-�3FlHuI.�%���[AV$����S�!���TCB�*dN�Cv�.	��N���^�����5�07�v�ף�/f���{+g�j�{���&bJ���J�vjA���E�AR���j���G���?�1��8����ˊu6
-T�$K.O�9�Lew�h����F�^>�.�Q)�>^"���'�����M�9�-t;RA@��M�F�@�u!`�u����QM\�V׊�T����0 eY�����zN���o�nAS�AB��v�\��D��:-�0K����g�����9:Aԍp'���r�mYH;�O� d��T���r�d	���m٨�^"�t>!;���D���rC	��CUn�\��/2���N������s
-v:�v�Xcן%�v������]	9[�]������b�y�v>��/Qg~��s���bŁ�|��Juᕪ�t��PGzf��,�.}����$,����A�D!>c$}���Θ!��-��Uj�j4��DlkhF� Q��[I_��^&>��9bqe���
-�4��sh�U;[AU;�<*T��si�ϥ��j��v��g��G���lJ�E8@vL�Xd��X;�=K���X�Vu��(����;_D��C�/:����L�]#��\@��y.�&�LR&�ㅄ���n����VC�����ZM�#�#)�E�>q!�:��d=���D��L�dE֋׉Ri�H����=t���a%��*.���hm�c�0G�cl�R��4��~�J�c�F+��U��(���Ȃ/pP��-��*��C�m ��w�!��+3�"�u�:
-<���r�6uİA�n��Ԫ]�X����m��"��tӫ�s�.zI����v���~o)�4�{���K��\G� �T�|.U��b�KX�Ḝ*Du\��2)]�7p�/EG�ѧ��-��=�������Vs�^s�^s�^s�^sE��sz7�*���F�},�4�r��V�
-˫h�=)Z��_����W)�~IҾ�"_K�W$�k)��]о�"�J��%�[)�~SҾ�"�K�%�{)�~W�~�"?J��%�G)2.�?��q)R��KZI�%�?������r�sI;Z�#����c�ȱr�+I;V�����H�Z9r��NҎ�#���$�x9r��M�N�#'�ᒬ�(GN��G��Ir�d9|���,GN��/:�S�ȩr�xY;U��&�O������r�dY;]��!�O��3�șr�tY;S��%�ϔ�����r�lY;[��#�ϕ�s�ȹr�|Y;W��'�/������r�bY;_�\ �/���ȅr�2 �r�"9<,kɑ���zY�X�\"����K�ȥr�*Y�T��Q�Q��(G.�����erdH_'kCrdX� k�rd��$k���z9|����#���e�r9r��U֮�#W���e�J9r��S֮��]&�׈�͸��C�7޵�n2�Ѥ-@#ڠ�㘽�8fo�cv�v%�z��|�����jg"�N#�?��!y��	K�#��=e$�'�-�������b��m�2��g'�и��Qj܂o:]/��况!���ݢ"��P>Ú{63**�����6���7ü���[x�ϊ�[{nU�
-�筤��MM?��nW�Ү�;����.U����Q�����$�n�R����b��n�i�˝<�Ozz\J_���O�Hkw�b�aHv�R��qrp�܉���
-X�G*��������Z����>�j9r�<�	�v.�-�Mi;FQ� xW�V�_�8PGj%�����@HLY�S؅���D�'p��!�h*�x��H����>).hGf�Yj�y9<�E�3qA��d�/�*��EK�
-fx���4fxْ�i��
-�z��`L,s���]ʜ�y��P�B��;}��P�c(厤?4b'A�#�������3��k��A�^73<�ްdx3�IC��c�ܣvޣ:�����xܞW齘{Մ���3-���V�'I?%�WMG`i���ƫ�#�Q��ܤ}������=�3���88��0���+��:�S��	�r�GM�<R�rڟő�� C�_<�{^I�~)4��Li�!��塙	7,���u�Sd��KAW��Ev����ܳ��ϪP޳:�,�pW5�Ֆ!����gHZ8$9JCjr�x�����Rb�`L�m��^�ݒ<���� ��ޫ��1���ʀC�6�����W���F�ݯ�@ ]��������C �=�b/��Fݯ�!�/:+���&�ǹ��~Rd��AM?�/s�"��{�ڭ�\?���|Tu��P7�";<���;��y��2m�s��D��j��>ݢ�s{�pa>(��r�){N9\(y��Rg�0������4
-��Ι��RP���g�*��iY�cK���L���8)	O�c���`<S^�w��_��A^�ȼ$ƽ0z��#�WŸ/R�=�N�Wg�>څ��v?�� w���8���-�F�v����|��0�+�ܸZ0��1K�R�T�w���$V�.��~
-T�]�D0�ʕFf�x7黢�M
-��t;���N1�1e�Sq�\�2h�ܖ� j�2̰:�|��Ar�Ar� a�=4H�N ��P���Hl4�4n7��;������`�E�F�(�����x�g�l�%��g1R�������^hϊA��.��=F�v�y�߁z^�<+�[Pϊ�xY�F�\���8����8ȹ�>�$�}"��m� �s{�q�w��ͫ
-�4��]+�C��ݞz�r��bB�������C���6�}���2�j�{ۏ_Y߄
-�2����b��H�`���o8x7�_��zF�o����Q�z��}��!�:���(U!}]�g��������)�B�@��=3H_8É���3���p�3.�H�<8��!�X�ᔹ:�{B�=���ݫ��f��p���2���������8I_�\j�u��-�qi�g� �������1���n®r\�m�늍�>�奓'���[@�P8|�.
-%�<��n<���O�@�Q��"Y
-�c �Q�Eě���"�X�}�_`jF(�OT��f� �П�hFZ�F��"�[��<�~H.�W��"ɀ'+w�.
-+w�*�Vɐ�`��I��h��?�������|9��D�u!-��hr/:�``L �aL gct��ɘ ���a�|��'�ə�|ϝ���;Eg�N��O#v�K\�_i�N%l���;k��6hc���c����D��L�H��
-V��dq,��ڣ��V��GD�w��Gҏ�A��h�O��0�Q�ι��C&�Nə.��c��[�-s�-)�B��d
-?��8�3:Y�x�;����41V��6�-v2�ߓ���= w? ;z��׿~��ހ���:^��%�
-zB���ވУ���zL5�f�[݄е��[z\5��/�hL����.�0=ʝ� ���$ʢt,]j�׎ג�h�9��3���P�YO�k��E]���wA��ur%|���mƮ�#��p���S�F9�I�q[�n��衍���&9r�<>�g�p^�F9r@N7!7ɑ� 9Äl�#7 �L�����2�y���ȭ�F�Y��[��->۵A�sC��-rd��kl�����}���a|nՃ�Tah�R-�>>�v������s��Lg�>�5�ٹUu�BY�|�S@9Y�P�مvg��I��1�KFSr�IgZ�|�q�a�Y�t���̱�.(Y��p	X|��ÿ�Z5|�+%d�;P�P;�>>�`by�ߎ%�]�,^�Ή����/u>������!z/���q�dӗ�,������l�V�S2+���˺O��?��#���e�a9�^�="G��/�ڣ8=���?ͨ�e^�N��gX��R+�� �
-Z��]���dE�$��lf�IB��+�e r������"Z"�d�\(����19�IvqQ������E�]<�l5��b1����tc�1��R8r� 7��=�l꽌�l(���;dƞ��K����z�#�į,��Yڃ�$��ԑʡ�Dtϖt���4N��em@3?�8GҵG�K���5�m���_1����e��v|V�p�v�ĔD�a�&IP$y�O�`�ϐFF�3%Է�%���li�}\;U醖Q!&)�$w�c�H���gnI�*�;V��NEs*^P���4�r��}v"(�:ph�H�B�]���w�������&±����g/Y�y%������P	>�)�@NE��͒qs�J�C����X�"|iS�m*�3$ݜr����w��c��F��4ෛIgIgQ���~���]Z�q��&X!(�8v�.IRE���ivC��_ST�d\��Q�_m��ow����gw�������6]Z~}�*�!��X��qyfBN��{��Y�F]�KF7Ȼ�e�'�,�ǧ� ���:�U�+
-������izp^&`|j����k�f�L8
-���*����kхm4�QY-���-�=��v��L�'���Б��:�X��]��Ρ���!���F����Z|C����];6J�߭�m�Kj�ȭ,p�?�|�IW��$��� �-�$�n�=~�=�ӆ/��I�=ƴ�˧�g��%���iG��S�K{J��@ ����'�	i)J_�8��Z"�F�g<bDG1z��G����݂�M��0��Qh��~IP%�vD����{B���O�����-L-�M}*��H�_$'l�r�8�i�2kkXH����C������wD�h��&����%�)3��S�+�e2%?`��|�[�Kq�Q��bEn_�U�Ȩ<cȩ�ʑ���8����yƽ��E���3^�19�Zֶ�@?d����>�-�h�.Ö�E7��~̤:W#�y��A3���4�]-�t~�~��~-f����Z#��F�'���a�����ٯ3����o��e3�F���3�&�>jf�dd�dd��~f�bf���~��}��~3f�jf���~���3����Y3��F�[��ϙ�o��ϛ�o7��nd��~'f��~���N#�K��"�ߩ(����힨�=Ѱ{�q�D��	�������'	��B�0��*���pد��C���va��*#��y��8��	W���Hp����	W��O_*$<���w�[I��R�Â~��,���`^!�ħ�I�v#��I���Aޡ�����@%��>V�Ѹk8��
-g�����*�1��x��>cm��[�lm-�����5iz�m��gS�x�5��[��t�JK�X�o�Af���C0��>P�ߔ%�8o�7��=6��x�Y�o�Af�͓�~;���h2�i�7śmÁb��s�|P-�'�cp��]TSp:g�^�4d��r:TQ=`eTT?XY*��W��|��x�K�+��:����Rѕ��C��+�5���5�3�9U�o�I�:I^����]��5��&�F��3X��!�|q04��(�y�o�c/S�:�'o�C�$G�ai�(Ӏ���4��>�,�cf����W����Kء�uR��k�c�:I*���MF9A��\z�P����]�k�w��~�*�/T�lv�}������!	��7m�J�_Ub����
-$�3�zNW�k@_c̃o�b�7�B�[L�c�� ��k��N@QІ%Z�P}O �{@z��N�z`jg��@��T49�����+��Bk��ao;�1w;kf����m����{U��m��V�@7��w_�3���l��SU���}����Fݰ9�:��(l��M�&��{y��N��
-	�D�:a��L|o���	E�7l��g����p�Ԩ�J<_1��8��k�6�)�J舼�U�yF$k�ȑg��'���yN&k�!������P�|Y�%թ�ӡ�='x#.�SA��{�h�&���{��Xҝ-ޓ�k�� ��»F�Fj�նlmT�LQ�=�%QP=����P�겻H~�M*� �Q.�:�a	�f��!l��Z��w�R'Jg�#���¦B��	�z�)���tWC� (q��$.)�h���IWu�jB�<ˡ.
-<�u�Pw�=˷�
-���(��q�0��X80�0����G�$�0�lq/��.^��WR������ +q��YC��ſ.�^^���=#V|�c�Q���Q �C�TT�EUux������Q:��
-�X���{I�"J�I���ԄpF�###ӷ!��;�B
-��P�X�"c���6 .g�x�y<��?B|�<>����?��y�3 `�`���g��@��m����6R�q�������))����x�ƾ1^G�&��4C�-�x�:��0���U!8�����	��T�&��+��J}�R?�������J�qȬ�B��_����l�����f��[p�����2���ƛ��֌k��ך�W��UyxU^��}�a�F��Fm� 6��:��[{?�e�J}��Qꟷj� �ث8	Gtp ��%S�%���T�ou�/�[���K����CX���x�c��oL@N�o������:�������!<��q���_8��p܆�C���½�oԆ��ϔ�u�}�/�Oڥm�^7�?�pN�Ƚ��v��h�rGaڛ���x�ҍ㌐"8��G����et���9N���`@m.�%�o����9i�����x����������7IcCS��o�?�����}���?ڱ땅i�f��q�F�RUˊѲlky)�U�"ǐ���:��cJ�:vJ2��[�j|������K�,Ζ���y��{vv���D�8��-4������ս�RF���u����2pQ�pq��,����<��{�_6�jW��1疵���c�tc�7���{�P��Ϯ�����%3׶�:���P��T����/<߿��Jj�g4�v��	p��&i�-.:ܶ���Y�j�^r8�z���z��q�`_�?W����c}��@,�rtf!��L�'syǜd.Q�JXę\?�5�K�
-�|f��q���x����)ǰ֘/�=X���哎�)Y(:�;�B>�$��.�*f��ق�S�������t=�l�X�Up�&:�8Ze�o�,��L���{��R�Qr8���_I���;D����
-|�����4Iy���x����|��4�����^����ӝz����ze�O������~��7^x�� ���^��ߠ �p����A�m|!_��^=�������,x�����u8�v��w1|���@�w�!����f;��[�'p|(_��Q��X!�O/���Y�o�2<=���l�=���c�:nK�T���ۅ�P>�bM��ց����Uax�<�+/'������8��S����s.�+�󨬜�U\W���rX����{����u6Sǻ~2��a�W5~z=�A��-x�Ux�� ���I/�q�D������c�8}�}�������z��ϊ���o
-��Q�y�l.??�\��;(�Y�?)�O��z���jiB��අ��F{�H��(��w��;�<��^yɂ/գ0|�~V���1	��Ƿ���Qߎ���Q�o�۱|�&��m���8��Z��m�R�D��&÷�zREUN1j�u���\|��
-�f'Y+_�ƺTى'���q�rH1\D1>���Cf���%��?�S8�$�o��rJ������@6Y��X0���HP����m��	��Yh���8��8���2���E�8���x�{�K4�x�äa�����q�qz{?�����~����.܁_��/f'^��,�h/�	���������y(���q�y	����u|t�j�E����«c[x�q�:j�%p�>n���`��Z�Wk�S���|���@<;���W���uL>&~��rlg�?e�J��_������w��Q��ɾ�ːH�Z �{��@��<�����y	��9/�V�K�&�%+/��o��yb�wF8�	X�#s^�ׇp�G἖b�-���G��(�ײ���~�xyp~����O~�2<:��Q9ςx��x/o�Ņ��,�S9o#��ށ�&�j֯r^�I�����}8��S��n\�Gp�r�yF8O<��m�g����q�Y���6�$���',���O����!�x~ޮ*�� ���$��^�8	^"ǋ�����缔���y%Q�<�����~+~NVn�)[���۸�L6w0����uX�?e�������mOǀ���2��j�j�8H&�z�l%p�.q~Kt�� �(ѥ�t��m�؏�I��������ѱ�~tl��ꌶߏ��m�~���~�x?J��G۶���.�w�D����:�Dj�w���ҝ�I���:����c�<�~ׁ�J����ˁ�$������`wm�mI.]<8�B+��ͨ���s�9U��Z� �CN�D.��:�}dƧ��"��ߋ�m���!���k�W��t[�d�^N��@I�6u��+��'����}H�S������ao_�s:Jf�E�]�a�j8\ǣ�
-n�?s\KƸ���A��Gqr�U�,���K�lF�����||�y�(Wa�9g��t��]Ux�r��\��ⶢ�ֱ�y��K���V5nƼ�/��J�5o&|¼����1�ͦ�5����h��;9��vf���mΛ�獷��ْ���˟������,�DK9��[϶I�m��f�W��C�V5nƼ�/+�z}�y3��ׯ��1o �sy�dmG0m�L�`�W��m�e<&�g�_P��W�u�Z����_r�~�r8�l�Kb��|���1|f%�<��&��Lî����a�RKCKp~��%U�8)���*���r��vJ-�[CC����׶5�ʶ4�|���-�K��K����K�ڟT�n�S���|���%�����3�ϟ�_m��?�O���$����4���]�w�j[v�Kl��f��O�?5���h�<[���;�V�U82�_�+1�/��{�,��GAG W�cZ&Qث��=�y�X��*�ez�/!xt����FA��F���
-�(�F���Z��^+h"�Q�a�_�r��(g�jj�k�V9�ìQ��NS�:�y�[��q��q�/B�9����m���|!�qh�D)��-C�ݛKR�U*��V*m��u�~��o~�����7�R)��#�'��K��(u({�.�����B��M-S�N��C�;����g��3�k����w�_��_~����ۿ��o(	PY[��T��-� D$HM�F8&��-IG���K�1%�ؒ��$W�/	'��K�I%��pJI8�$�VN/	g��3K�Y%��pNI8�$\',�A��񗕣�E����\y��Ny�:��|��_}�'�7+��?.��]��_�$�o�//���4~�p�[�9_�k�r�懤��J����r������/��߾V����5�ە'.<[y�ŷ��L}v���ç_�<M_u�E�ś+����ҵ������=����X*-�~WKGA�Ə�^�ˏ�H�~T�=�.�����Ǿ�����Q�
-t��9}導���rH|���t�Η�<���\����.>V�7VnJ���w\��H�j��p��o�f_��:��,������{� �>����p�خ�x�
-�'������_���l��W�p,/��wu�s���ie.�T��K%�ʒb>ӿB���eS�~6G"�O5�5/�7��O��s,����̦V����5��
-�@�+��e3I�=�I�:�ʡ�}�Tޓ�=��"��S�A��]��|��PM.��|?˓d�7ۚ���/�2����ɬ�?8�&�Gd����|���������B�X3��X��&�*4�[�d	����ߍ]s�+c��T�R�e3������>��c�>� �L�su�'0GSׁ��d2��T�Vd
-���/T�_�t���߇�wu���AFVs��D��Z̃<5�E���>�ެs/cx��M�!��`6���D�b�U�bE�R0�����!N�.����ƾ�(Ć��%f�[
-�y9$��(ȋr0��.�)gV�X� ����Z���I9.�tjׁ�%��F��xh�38Ծú��N��X1�87��nt�kY�u��~�
-&ۍ�d�Ө��ɭLQ�aQ>7����Ӡ*���7��]n�ؙ"Up/�ux�0��M��8�0^6V}�d&X��E|؉%������������e��T�<��0����ʽ�bscyO�<-�MK��Ʈ��,��(�|ruΙK��X�t/v!3p��^�2w�X��{q����Iq���$R��Ɗ	-�vQ͸b����М��l&A�h>l�L`I
-�"`qx�xcP��H�ҁ���%չ�M�Mg�>����؊%�QBledR�$_��R�Z
-Dnif@�@.P�5'�J���e����v�!h�mRc�9�Jg������b_l��b!����+R��Bq������c�}�|VB��DK���htΒ}�ѽV�
-���.��ec����տ����.h{�����y��T��JV94�zM�]�XU:�u!܌+R��i�t��slb	 X�L<���m�c���e��2��p�� `�z";�@ೃ}������VQ<�6�Y�0����)J�`��J�T�= (6��Ū�s�عY/�S@2@4i �\�JÀA#~��
-��h̏c�uu�������	�[�t�"$a�ܴX7tz���on���E�5{�f�R����cy	�)NMh*=�3�7b�5�k�):�Ty6˶MA��
-q���aP�v�S�˂�H�z�t�d��D0� ��#�"=�6V���W��B����^
-v!��6����{
-z��J�����\���T�m�Gi���A[�����H͋�3 �OẕW�~?����J�+fҙT��f$�z�ˀ���T;��c05�����l�A���5�b��?���KgJl�̇��ǈ߶�d���DP��B�-���']��4$}�2ɢ�#~-�"�+`5�l���<&�y�J�2ɔ/��bH�c�IU���Hz2�p�!�Cj�+�.�l�a_��M�X���:�-P�%���L�L�o-�O��X�b���] ��V�	5���4�@[��L?��IX"��0p=�f�e�Xٙ��H�jcL4��vJ��`ʗ��SY�f`��3���\>�$TY�ة��g��/�u3!ݻ2�Z���Z�",��tY_E�+�'&i�H���t=�F�u	ۢH��֡��m��`2�g�J���>�u}�E� �P�-O('RI�U��`_���؀M4W����p��Ʋ�)8��2E9�=�_̭X��S�E���,�2݁�y:~
-D��\��>�e�fl����O�J vr&΂������T���u�۠.B	؆�>#"�`&��e�Jt2�s�|<��`���=ú���vrH����,���R��(O��^�Lr�D��(��J�<'�������n#�.���b�s���<�gp�2~7�,���������`��m��O��P�����d0Ngc��*�xA�2��lr���:Xʦ�E9�KU,��xxҾ����P�
-�[�E]���E9.?Y��߶��`p�pֳy���K�JM�g� Ȱ%k�b�[]�I��LA ���9E�@&`94��i���
-hVf�.�,o)��`5T���:�0�a���������CU% R���u!hN�j�`�N"�rةj�T��e��]HU0כMx�s�`I+���dj���+3��gS2q2�!
-�?���k�IS)3m ��P�ZF����fх�_���,G�����prd��@�"�4�����R$ �R��;�1c�L�ç�p
-��t�F��Z���,2��i���nJA��G!������N -���L?��̖0U���
-,Ti�\��(�U�O"��B"��z���~��k��v���[#�A�^8&��xG�5td^Jc�5��u���7� 
-�q�jf�t/l=��Jg��l[�r�����,e����S������D�/L �4����4�Y�>+;��M[��ma��8Χ8&B�%����Z�Y���zW��� ��X>��i2�/��a��t��ڍ9h���� ί[ ����̎\�Ѯ�P���m�����%in��dfWNȍt���s�M��ks>���' �L�>$U�rI�8њaa,�����w��'�R�$��+
-q�Z�A�lK%^�5��G���
-�Y:����������tY	ՒECuٙ����	���9a���aӪ9m�$������5=S+��5kժU{�С
-:�7k�ٳ9+��շzVك�Xv�AR��BV}Q	n�֢�Ӣ���F�.�XaV .�)6�|�ϫɖ�؜"0oS�S�\aD��$���x�)x��I�#�&�Ԥ\6��,w�b"�`��B���ca�Q�Pe/C ˂�,!��-o���_�Z���T���J84��E����Y���5�� ��IS��gZ�n`�P�-FJ��6��-�f�XW ,��P;Hy뀹\a�O�)Dbq,��1��A���j,��3���V��H�Q�����/3�����|�H�߭�0Bˌ�r%J�e��Tj�}Yt9�.g�#�v��}���������DO�{㉒{!l��ҏC��' 7s����nP����Lɗ�+ʵ+*��i������:dU�%G-����j7Z�[R���
-��5J;�v66�v�M�)U���[�-�*
-&��Z�A���pM[W�H0������h��o�Y#�h�j�j�G����m Q��t0����Z,t�
-�D��5�Lw4ɥE�h0@�D��$=��!lF��4`�"�o���0�Q�����bY	��]����}V��E����h64��C}Q��.!Y���e"'�8��Sn#�W�>k�)ZK��XX��EkU7�&@��*�d]U<�K�
-@R���[�p�u$`dbҴ-Vg$����?j�Q�$��_nCy��ucnC��V+W�Հ��=kh"$Z�sV�ԯ�	�@Ԧr��buQ��5`���`��j�d�\�V�*���p�l1��p3a0iTʈf�Ϩ�������ꡂ������ʪ���U`h�3kD*9�m@��B���1:Q�{�
-ԕk���p���\a�z��ņ5Ђ��3�=׌�i�g@]U�5�`W�KfRt0�tgp�Rɮ��h��(7p؀ʿщ�Q]�.M�N*���e[ �&3�$2�)�D1�P@���� �d)����sŒI�:=0��ͧ�r+1�[�s�~(1HK�U(��.�n�{��j|햲�v[E�v[Mu��^5KY���/�I�D���s��d��	>JXL������L��|���۬�SL��B�Y0QP'�u�S��5����!+��m�Bt�ٖ�S���c>8��u��T�#�`Z#�dc-"`v��QF����E�h�)[4�PC�c�J�ŧ��~�z�Cs����U�Z7�كq�8�9��<T&�,aa� Ӓ#3��sy?s�'�G�Œ�,P���͓h½�;��1��C�����I�,�'���D��a6@�
-�����B5�ˑG����,=�`�������z+��7�(s--�X�Y�b��ʃ��2;�tպ�O�c����|	���&`�q6{i�l.�֭����p�dd񯑊?�YP�G���w�>��؄*��I�Sã)���~O:d1l	��L7!� �ݿ�����Su̢��z���Ħ�7S�MaT���̲L�l�Z��Y
-B^v>�nLQ&�د���4�t�~�1?�
-�H�m�G����u&i3
-�'d?3U&��,��/��+X�f\�����f�a�:�hNu� Ji�t���T��K.)3֚b��0eJ�L����I��{�X��Ǽ Xf��"�5��7ʬ�|t��x�<�zMq�~x��x���xp OF���2�*
-��eJ#�7W!�2u�(4[�t��&��c���T�J�Z�����w�E�4#���Rw� ��]�[�AF��p�A�M����}G���ϭ���� z� ����=�g{:�<��h��n"���<��l��h�r��
-}(�:� ��ӜbD�s ��h��4��VC�lE�1�����ȴV	�Qf!�E��c�&�(q�fh�{��o��d�F�ts�%�#��g\���M���
-��_'������e�|���Π;�=W�L���t���.�3]!��r_!e��<�FSn#45���?`�M2K����������@�f����S�-�\X�e������*��a\����8�b�*��b3�������ntq��B��^idߩ�=����㰂	�)"�����-wݰj���)7�dz�uf��w/��ª؀�9`��)6���'�M�o
-k*��ѰC���r6'�q�����̬@/�`�ϪSdr�����jdc���o�x�4O��t�V� �Iu`~���Z��N­�\��[4�¦���c ���d?��ԏT_��J��%�C���6X�]��e!����[������׍��I���f�z���� ��^HH|TOgE26��#�-��=e��cD��]�8D��xz��<!}j��i�Z[e���P����lc�8�y�������L
-vj�ь����(�=
-�I�,�g�>�+kt۵
-Bjnn��D���	3���Q&��+?
-��Ot��7G��:�Z�����B��BN���c,Q��.A��~$Y���nYi���Lf�z��Q�v��Z"^҄����A?k�/�P��s�A.X��r������/��f��x-�z6cH.�%�� 	Du�CK�o��۩ҡP$�Qr9��g�h:�/XUU���\#�L�`-bw`�2YBc�z͍�j��F'[n-���͵�r)�%�:����;�����K�S��� �,S�7���XHR�%���"�aj���m�6����6�>jߩ0ڡ	��h������X�Z(n�52�?�{�TD� w���j��4p��
-kl���'��D�&&'X����
-ɽ#�͉ �V�ۓѫ�Z>9^訙�hY	Q]w�\8��b[ԙS'��)�*2O�i���ğZ+�
-k�M{�VUf¹o��`�t�e����S284��l'�7>�֪�n4�y�b>�f.;,����X�������Y�]��2ND����x,_�J�vQ_��8���Vpb֩U(�9�X߀}/�ނ@��:�d(�XA�@�30N�:��r���]p�tr�-���VK�t����]�o��*��5��]��i����%�n]7�1٢�UUp�J�=Z�/;+�{�I��V[��6����~�*2R�"j�*R+�>:���.jw�V��K �Ž����d�����U�_��9,����cx���vM6Oa�+����;����1e�,�$de�t�~1,@� 숥�bB�e�F#�v&)��Z��g�2�:�[T��A����W��h@�s�5L�D�˹u/:� *xnz� �2U\�
-I��|V�_ j����m1_2\��jsP��Rn�����4g��d�PH5n�^�6`� �l��̻��2��EnF�]6-sS�z��߶*���t�k��&�-Z���sj���S�`�wCt�ٿ���~��������yX����/~���}��/��K����W���/f��ެ����iQ�O���4�7�X���$ ���O�d4�su��*,�E�F�`���T]��Azӟ�6y�ۨ�mT���͵KM�Нlj5V5ݔ'�V��uot���<�ӵ��T\3�rs�J�Z�OҬ[�*c?s�5�d<���4j��>Xհ+T�T[ANd�vo�i=4��VWu���cy$�O:J��b8fV�H�G&�i5`ƥ8=i�`5٣��0��T-��0�n1���`��՞���f���#�7�Bt�]#D��D���(xL�����Q:/��n�5�?Phx���"+;�u ��t��Oe�uE�,��'���R���E�:]z�� q#�=����4�ר�A�v\\TH&�8�$Vœ)��z�fn1�(���Lb��QR#cnL+��\�ب�cPٯ'L�a��J��� s��;�6�5�����.1����s�ٜ��csb��fX�2A�������s��;�E��K7�t��CΔ��5�������	v��_Y\��F��d*5@��
-Z,�ͭ�H�k��9�&�q�ũ�`����fA�f_�C������� �[b!^,�;(U��j�-�F�%{KrX�W�#��sֻЖ�V��I�
-V��4sҬ�WgM S����D������w~ a�=�`�R�L�cM��&��J{���W�4P�9�@fu*�5Z$ݮ�>dY�ư�����=�������o��r:wz��Ŗm�&��	m`��bAJ�����xWg5�q�">�o�If�fX̧�l�]�1��7������3�]�ă���qB>�W)4�'Jg>3ƓM@�~�qi>u�q��ַh��_��F���+�f��\U�Fɥ!��������)�7��}ؒv�q�$��Dˎө�=���<fyfc[����%S;���~������}�h�`���c�!	 X��0�G�
-Ɣ�k)I�a�F�s�x���9�L������]h�
-8$:3E�����PpaI�!�]��J�֠6'`�'e[������v�9Ǻ����X�|��\� ��^u oǥ���f��co=X����
-Ѕ\?�#Y�J�ql��{����jn#��P��)=G�z�!�!7�$��w���u��������$T\��-^�D�)B�K	�(����L��p ��O�%�d]Jf�B>�P�?E�@g,����e����:,6u�͚o�f��U�cG��=;�ù�8���A�WG��|��֗�~ rJ ���U�V�A��]S'��6ڔ��_w?���V�$�?��D�3�F"�����s�)=8�zj>��z��&���j.��OґP)�Uh\�,��J���ﲾ�3�r��YhM�KS�$waRX�`��9 ����0�>tA�R�$j,��o$��5��yx>l�5fc���� ��IS���P�`y}b/��{��-*���/Ā�H蹊Ow�쭢�N���j�a�y����G$gl�����_H1d6l�9�W?N���voO��M1�=�m�c��ɑ6�l�[�����Z�)8��]@��f
-fV|�	�0�
-�D�x3�����dȃė��^����cf�5�����!F�^��3�ecg���$��%|��K)�ZX��E��]q4@�3�w�ݜ�ɟt�� �E�i5<����=��"͜�j�Ď�g����a>�cQ��S���#o� 9ϼ;�c�>X��]]��dp` ���>L���$�
-4}.-�xnR��ؚ� �L��W�Ѭ�f7Oܠuf���7]����	�C?ܓ ������S?��3E�%�ǁ��xR�h���b_S�l�EQ��,0���C�ռ�n1��|T�A�h�[�[�"�����]y4rdE�����pS1`M}��~c&�;��;����$�,n����`���� ��]��oa��)PKrJ&U,O���Wh�jaN�P-��ٽ1d�-W̋��歷º�X��AӨx�+��D&_xyq#}��+�׽�h���u"��g��0��>h�j�~s�w�h��\�Ih��!3@�@�3+�a�rKY�?�D*�[j.:SY�e�y\��� 	�Ks�${������ Y&�x]��u�,�dU��6S �ua���>kD��,]���3%�;[@��=7VO���r%�?GLmW������q1<S�'��ij����]�ӌ�<��a>���W�l�	������`�����=�a/�m�Vp@��lM���Z	r��N�b1�)
-t��q�;�������O�����s+4s�!98�������-�mU9�� �i��.�>�.z0�GW���&��N1ܴ�gU���Or�<��	��^=��f����;��Ě�y1�O�L�'����g�)&�k��o2׋ZW���6ư*g��e�mhi��63� ��n��U]B����.���D^�V�7m��u��r���1�6h�1�U���˲��z ��&�@qQeU�ɪ1���2]�'t��B�<�]�Q��Ӳ15Uf3^ƿ���/��K�,�X7_TŗWŏ�Fs�.�5��ѳ1:�a��¾�㭸k�X���;�`�j;Tsk��
-�E����:�N�N�ґ/j��'�g��FY��Q�{Fh��	��`T�|����$�~���-կ�j0D�Gm{�˾�y6�oYLE���&�~a�
-��K�L�
-2�
-1Ox&�� �j}ĖR[2������7o�*��WW�W�d��y&Q6&��23!,��Χ��XĶ�%��R}�%�˒�+ό�@��}'��C�,-JKh�_J[Z
-�|�P����]ι�$�������g��{����5����7��c��>�[�K-l,뵲��eJ��g!��e�#�2���;b�p�M�ja�@����4�۝Oy��K[���y�>��x�Bh�Ys�+(Yu��[)��Oz����4�Rk %�]IS[k������)����n��4wH�W�������ܔw���C�����*S6Ҥ{1���}@HCx���'�F�\ƻ�.�(���E8��|;6�O�rK�n� {��`�w�K�0焾nl�����z�ꄃuiF T���<�,��!��-J��a?�f]`F���\I��RT�����m����h���\Zq��-���V��O'F����;�Ҙ7�F8�Tݾ7���c4�`gowG��B�(~�nƝ���f2g��\o4^�J�Ǽ��?�{t�4�B֜��Rb��E/�(�#"F��v�q��3�!��19#`����; �Sg}�۬�!����#��@v�,8�h���t�:3:A<;V�V�;4���j�*n�o[r��B�8d�4H��Ə�O'�+�&����Oi3v5^�+�^�MO��aT�Є�Nkp�e�ǎ���T���PoP�iXۉ^�qǮK(5d���1��ɣn��Q��LbQ��̗Πm�S'>0�ؖ�[�a�e	�_DĘҘl0>ǁWr�b?ѳ#io9^n`�����2K��m4��Se�F�zʺ�m#I��^A^<�F$|�x�4I67��5c�Ґ{�&&zB�9�U�皿��w�&M9�/�8{n	c�cs�ቹi��ϵ��R���u�\�h������	�����ln;[P)!�ʦ��I�N��Ē��ąN��0ǈj����ιm� ����oN���b�'���a:G�
-#����z�N��"s.��.�&WN�:N�ڣn^|�ש���8�7�K�q��K�^���kV�
-�I)t7�z|O���HhV#��'ym�$Ô0�0�0�G3�.o�v�.t�(�@ƹ�U��l� �ԝ��`WMS#U�.�3L��K�*�8����HIȭT}�=�,m�\a�[ꅍZ{$�(Y}���ֆ����ǘ<o�`�M?K��'6e���m�x��Uՠ� ,L��6 blm�(u]�`�\s�I��������E8$��� �xKXv
-�1��&�u�+�}�<��c���ID�iw��]�	��ݝ�^�;���{�EvܠC���G�|��dm��4�B!�.c��N�/Vo-�k�S��r�t�l�v���Ś�x�����C奒`��PD��"*�$�<@�Zކ���i�w���Ħ��&�oR6�y]Pr���4BgSqR�v��{��O�'H4[�,�0]�$��GM�������D�C16D.��Mrq;�	RV^���J����g�j8nH�Bʖg��L�%���sxjO6� F�G�T&�9o�v�'e�X��n�C.^�|ĬV����O�U�����(J��:i�b(mR�z0� �Hy3RE�.'�q<Cfc�dґK�ޜ%"թ��ѵԨ�a�I�0Jf�0k�.8�8�v���R��c���D("�ti�{������V��C|z��7��, ��yj�;�3IdgG�^h���żv۳��tϠ���x�@ئ��mt�h�+�.H@�:1�P�\�0��
-9A�.�����8;!�h� )[|��V��8}BH�>��Y:�v�}>@,x$�d���^���W��$�:1�}6yaQO4�����5av�E� 5�\�Y���	��J����p%+��w�m�R�CQ��=)7O�n+"�i�7:����p��o�T�1�IK�e��LG>Vî/&���x}�1�.X��"ŧEP����O�IU*f�����ѕ����^�N�0�d���.��
-�v��Pi�\��k�;j��}�~��'������7W�>O�0�D���mH"q&r"��&��0�� ށ��"���#A��� 5I��2��)7ı��1����@PG�s���6�[�bT3�t�pm`�a�HF�̈a'��MA����)�3T<��v�2%��*�H�!#�s�P�eHeJ���]^����2Zq�31
-�s]mH�M0Ҧ���	k���"� ��2B`Ce� �q\ �c^�g d��(�3 c�$pl d�����!����RZE���"	9�pݙ4I'(�Mս~�b�h�.n��%[�n?B��"R+��4d lKԠ�6`2��#lmh~�>�� �B�J�{�R;�Z�{g��X��A*�8�e ��aC�u����G���,��eS��,o[,�vAc[���نL��9�Z�\�7���#�ql�
-���:Xi_.�s��6�9�G���=��Gh�3D/�*_5��և�K���ډ9$Z�~YOH���U�_j��l| E�@�''fƱ O�5`)� �(׻�PF�\�����{��=7�da��[EjXu��ɧr��݀��?S�ȉm�6\wW�8��ޥ���K��,"�EI?֒��g�����^ 3��2���`��B��뻀t� C	t0@D�ͤ���.gsb��� �2I}��j[����ݪ�#�^��Bu
- VK�R핻�j������޶]o܆����x��gñ�G|�BU� g~ܦL��:�[ise3����(M��� ��%�$1*�DN�������h�iRtm5��Uq��q<*���F��:���'��HjHl:x�z3:	!�8'y�0������uü�9�������j��̽��N��$3[߀�f���z=��Ï?���Ku�buGe�~��G=�a��|Kȁ�uS&�v��]�c[�]ڊ�i��I��QSZ��Q�7�i���%�GT�f[���|m����VB֓Pcu�̨Q�ρ����wX7gEU�<`�r�c�r�F\���eZZ,�HNd�KJ�0�Xu���F�B�u��O�0ц;�L"˷�<�d���+��HY"70� Ӄ�?2e���Ry��a� ߴk �v���fRY%���-���.4/�H��
-H�2�`O��=f�P��"7%�����*��)�4Q'V�kܔg�h���N��N�k��41O��U�ĥ��$5�ߺdjTH�r�g�y=iQ�b�-��i���%/6~K��;5Msz��Q7�L�~ԉI��;�Sf�$��C���`16%��ю3�×}����3$�箑��qN�M�#n��n˹�^%3�  Tt��L^�%�~�ᒀ��5��.�d'�cn���l{?q:+cM�v��������J�6$�I�5��2&����Y�KжB��+�v��4;kv��F����;�������T}L��h[kDʺ��$GjvT��y� X�/�g���Fi�7�	w�l�s���\�$=���F�?7�V�my�C�=pG �>}�\2�6��7���sN����R�&��Պn�*��.�-�r�=6H�ٺv4Ӊ	��-7�Aj�"޽C=@�y��4���=��n?��G�_�˥Kly��
-�ioN��pxL�q.1/��!;�uJ���!�y����XÙ�7��X��p�O3����Z�|��sg��)r�2�*�2l���Oe���b��®���$<�{p������M{�W%�Mn�FP��ج��B��B������Q+Ƣ.��ǡ�W{N��l���Dq�7
-S��L��ؔ˵�(��m"$ʗє+���I����&�A�df�z�����`_uY�f̑p_���|{�$F�;B����1i%pe	�x������3��F�{��u�A���*c�S{p��q�+���>8j�^uE��ͪ���� �\�XY%�,PdH��VE:���aG�q�`*�Đ3���G���u�Q�l�Vp��p��.C�ed�FX�KX�`=*�=��OVzD���i����á���������~�-�`]*�Oˀt#�٫���؈r<�|�ʦ.<$���y۹}�d}T=-U�O�׽
-j��`cE�nM�hݭ�O��l�4n��F����J
-!I����>G�vZ�;!�(J�Z��L�<e��xy���D	��i��t�i��Z4
- )HIr��j���v��O�.�J�BKG���Y��\�N�ƷW�xĉ�zQ��u��v��;0�V䠆�H;%Ji��4OP��i z��pJTD�`0M����`�#�z���Sdcl]���Ō�9 g~�>�8"u�e!�/"��6���e�3L��}�rO�<��\��YN�K�6�_�̈́PE�ָ�n�5@�?�:�-]�Eg��ȃKϓs4�$�%������}<*���T��g"�l�C�qP�xw��dDط���JLZ�qǔS2����Ң��d�e���)o��Y���L��ѧ�nP��NAɀ%Z:�i��4J���x�;*��=,�3.�30��=2�34Ѻ{l�ę([��0ۖ��a�"����Ν�E���ǽ�ԧ�:{��\�4��7��(
-41$:t'���'p�j����>��Σ��y,�~b�ǝ���6w�����s�B��ϙ,6#diD!�ۼ ��	�g�	v��=	<<��=#<�+&��\26S��%�Zq�&I8v�؉��!�VxR�eo�!� �)�&иi+�	U�.gc
-3�.ѕ�����Ԧ��-�Y	6/Vl�y��ٖ�R����:�r[��r���l�<�[d�=�
-_AH˯��`����z��l��Ҭ��$Oca�	Gi�iڢ��)-�~�4k�y�IF�]�M��90)�B3�
-9���,�M�bOnv��fɾ)��|
-3��!��mΩ�
-�1����'!A�,\��dd���/m�;�A�$��ֆ��O���袕&����53[N�����H?����N��)�`���8̳���@�&�ƶ-]�7�A5J��(��o�tL�.���W;Ǖ.]�I�H�����_[ȋ��	SI�ٔ�ZW8oa���yGO)e��В�Q�T�5)�b�T�"��Jn�g\6��7�cȪ��Ĵm����zr緵�����u@�4�	��P ���@�@t��!�ކ���?��4�rtVm��n��E����-�K�q�4�v��q=WR|�e�'�A�7X�����m��i�=@��w���M��D�D�Kr�I�(�Y��7���>�`L�c�O�T�d��~b��"�!H�� �zw�Ӷ��\�-L/j�$$=1���@p8��c�\�s��=f�E�;.z������4��y'̝Y�\�J�]�ca,��_�� �h��/�L�@�Q� � ��e[��n�W�Vc�oe�xk\�1"��Q�xFXA�/��j� ;n����a-��+'��k�B��t�=w�v�k.?�Gkcٟ�l��Z����U� �N��'�cOn�H/�B�㶀.������^�(^oH���]�y?g:� kH�@���D���j���æ��-)n>贈tiz"|v�����.Sjv�����2����y����s����� {� �ve�+��7��.����"#�cJ�uۿ�YW��+�8�Φ��ui�9�S��Y���5<ʶ��;8�?�9,��.O0�p��x��|�ǚ�Ĥn~�#���Å�!�)�9@#i����X5��5�@y�qH��!���u[6���9�i)Q���4�Y���degm~I�.���	�-2z)L3��g��2`z�Ylmɗk؂�c�w	��a�&�׾>b`z�>���T����1��;R��v2�D��)I<: lO���p`ut�q�5@�8�F�; �Qm�)[O��:� Leؙ��U�I�B��iw�qIG�D�o��#ϡݹUDK�H/DJ�S��*b�Yi�Zfr������P���Op�L'F2�HJ6S����.u�LyT��s@�\�فs�F�����*W�̳��4J�hɏ%���a���~��[���u:�0�0宓AiR��Q�a�e4����uG1�)O��>���	%�P�'֠T a����!�v�~*h�~QH��7H͖5�=V�u��ɇ��C�����\&���A"�↔�o��Vύ+�x3�H��3�	N�ct�&H�qB����t@i/k��6E�4��D�PD�X���9��f�|QҒ%�a���s��d�D�x�������L��7+3fR�	;�hY3¶ew�K�H~��p�������^��qd��7dP�v�yZ�օ��pg�ę3� ���y�qt���>5�m����;/���/]�#&�v����L"7[{�-�!Ab�* b��R�g�15�n�lL�0�����E^����f�ɅW�1�����,��`�o�ԏ�r�ч�穣MgHf�ǎ��cǎ>�[��ل�����Xĝ��מ���:�va��l%�]��
-9�pi�E}	D� �C/�~^(s�M�pA_+Q�0aO#0
-tt�$W�)΁�}dR�[�G�3%�ƈ��m���� �eE��D��x0r�JJ��Iaκ��4Χ�d�b�"�hL��Y'�%�Fe"��4DL�t
-�!�$�����K�taft�D�|S��OVw�n�&@C�b~m�Ao���X@jUdQ�jsI�w���%��_f��&,���o}�)��5�k6�9�bDK~�}�0!3��fM�DF��6r\�����Y���.�{��%!+u�dr˗\�o�ܹB8/،�<���Y�=�u[��Ϲ(kFV�eK`���H�M��-'�\�����q3M}!�GP��d�������jI��<T��.`�:��a��*t߄����D�N^��,&��y�)�"��]�a�ց�LcȄL�G�p��i��8,+Dp::���P&���3�����h����T�:ڨ�l&�o�'_���u���o�����2�[�YQ�a�۟@	io��o��*RXIi�Ce&��܏�(�>���J��fdy,m�s���U�^�e�(t�Sw���_y米��Nf�hx��¹��X>�_��~iv�Dp]� �)~D�,�v���{��l�Z�(����h�k9�@dj���OV�4o�6"��i���Q�l` {���=�Nx���{�B�F�C��9(Fd�ϒ����5���h���*�e��a�e;>m62^q^��4�(KǏ�peH�
-diE3�9�^o�����a< !)���Δ���$�`����u��U/Æ�c7'�)�j򔎢�[�6��f�Ŷ�Z�G@��#� qG��|	�d�#��Ѣ�.�V˕e�a�c7��f�����b��T*T�VK���r���/��9if,i�T�u�6;��%��Y�e��L�*k�z��Z��A#�s���R}m�Z�]�'�e�j�ݞ��eM��وϒ�$`�}�L�f
-	A>��"$������ba���t\��!��m�6�-��8�ϥ�`8�+����je��Z+����!��ڲu��P�`[�eQ�6o��`����>J[�Ī�u��3��mr����]����U=_���O�E]��~��9\��o.Ɨn.���V뜳�R-/V��˕Z�P��,VVc���Ziu��B�2]'@�� �$��(�a�L��=0!�a#Km�7��[(���n�����'�֚pYqi	X��]�D�LV�";b��,9
-8�__Bw��[(,�ZҖ*�K3��������d2����`/⌄�"����a�t>�~7��,�!'��p0}�t(�EaO]nx1�Yfh���	�QO��5�4�G�UQX<�������m�=+��G��4? �b�%w�/F/3qS������#V`��m���	���:��N�8s%]q�q��l���ABm*��.��+����ܣ�ԇ�a�.�.�B��$�D%�P|���1D���[aY,�vP+���yy=RRV��`T���'�0�Y��Jg�5ʇN�3q�@H���Za�FE麑�G�b��0ɮ��sk���v��V���L ��o��#|�ɳ����B��(�q@-���p��^U���٧�����K���h^�KE�!,|�TO��s?���9��$f��ׄ�8�#�o�a�c7�#�ݑc��Ѱy�+�HW���-��S���Ѩ���b).,��
-�su8|�Y,t�K��:Fs��7�*�̒���MC%���I��bW���V�'�aғ����A�X^hn�SK��j�^��Y��R-K������j7��Cy�,�J��4�r@�I�r����D��L�<�K��}���A�C	�vם9���5.�e�A"�(�N'�Kx�\�ʋ�z�X4�=��VKx��]�D�� �W���R+c�PD�u>�7nU>����01m�#�I	�4�',s��/|m4�u:b�"���������.��}����%h��Z�W����67�ʲ��V�ra�Z��_/�n]-��S���m'��"l-�s�$����+�� [�	D�p=lO	��N!g�^�]h#P�#�{�1 _��k
-�V� I�����{�֦HPt����Kw&1'�e�Vx>�7[�xْk]\�x�AS�k�k�B{�u'r�[�U?Ш�
-2#o�x�E�앙c�6`i�a�h�o��m���k�&�8��Ch T�c��I=�O*�%k(�J7�OV���O���{s1L�L1͞�G�Q��y����2�|�T�vnoC��r���J�뼎1 �p)��J�>��e�Ixݦw���]*�y9	a��VKF԰�S0C���$�>g�[u��������I'���*��:�{�N�� l��N��Zھ�Sچ/�6	H$vR��32I�1O�rĕ�u�!a�!��w�I��ބ��%���cY��}��X�&:l�S<X��A`�T���[���Vk������ZY��b�pki	��Ty���.��qyo�C�{I�4?����	�*Ta��*+!G�*b��Wa�VVT$��V`��u���d��J��Hb�f1ҵ�����Y��͌@�Gpm�:]ßU����'��j_�X��>J��$��D��=X�;����ֱ���?^�#�#��]r�^�Bgi�{a눒���Eპb7�X��뚐�]�!,���+u�����J�\h��Z~\e�VXm�6ٍ�xß+,k�ۖK�j�P����j�%�{Z���X��C��1 ����1\%/ ���o����by���G#:� ��@XG�@TK�LNc=:�VY�W`�qM�Q�j"Մ ��@\¸&BMY��jkK��+�jO�(��]�pb���B�BF�|��Ek�Ǯ��J��H�kj˕�օ��P�F���*�v�)�<���@��ܭ˞md0U8����Z�!�l�joչ���Q8E�w�h��n�Wd�W+K�ڵ��Ji�<_.��K��M+6֍�2l�˥3�n�b�"p- ��Z5�(��5ΐ S�_[\�Ӣ���N]fQ���je5N�uZ7���8�P��,Wb��`.�k�"Z]����֘W_�1S���6�%֓,	=tv�;I6��l��[)���2l+������2]�8�;�t���N�[l`��d��p9Of���I���I��#�¶��ْ�� ��yBL�HfEOUVq&�PT����iIb��.ꂦ���6�J����b ;?N���m�"hQ�j���#C8�E�[t�'���2Ad�H�I>o5,�B|A|h��؁���M˂N�؀�12��rb���ڋ�[�f]*�˦����Wf��[,T�0��+L��	�~�h�ҋ�	,��r�卙�� Ad�#���:���U��������6N�ia1Ii0.����4O�����!�!�y����S�B.�)��IpA�j�j[2(mr�ڎ5i	�]�(�Y��	x���ra��n�c��9s���u�����z�K�p'��n�:ʲo+>��n%6��o�'��\�TKk�J��ڄ�T�+U���o�m *R8�X�=)�����z�4�a����2�+KK��m��|�2~�i�r�*d��`���,���J��J18���(Q�$K$�t�#ӶQGW6��ܑ̺W%D�A,UJ tt��.-����2��sb^�&�����ꜛ�.��n.���ct��g�%�)3��՘��7���F3�آ���M���YT,	ߝ��v*ߜF��v2\]�I�Md���wɒʠ���#P�6-�I?T�*L۹Z��+�D��ٲ�@JD'�$���� d�y`LJC��O8�:�!N���_i Ե�(��K��p__��m�"'L��S��⭥)�@�Y4%Z�Β"�N�4_�x��15n��OT5�TTjmy�R(��#ĐLW
-XTW)��Z�P]����vKDw�M����J��Qt#h['�-���Ȇ�Wu�����a��R�z�Z+-����X:UXM�����l�c�
-�	7����Jғ���\�rC��d�+��jH.@5O�3�EU�xkZ,�v3=�ҕ���JzZ���Sx�+���++���#㩠X�[�����+�咷𥼍.VU��b�$����
-���-�V���X�ǾD�P[��Ә�禧y��.-3��`�r��S���#=# v����m�](-����[�,O�UN�Ց��Zz0��*k5���L����;��g��i�F�}|nl�o]-��E.3:��9DS=�G�'��Zu��lW�3�ޗ�n� G�c��i�X:U9U9띓������^;�.q"z?L�v[��u���
-�Ki��Y��ܨ�H�04K�,,���WO�k�z�Ո���;3������K�NS��:� _��R���1p���u�2睫U���;-�
-��z`�l/��\Y]*,���r�t����rړ��a���@�aé�W��@�K���T>[*z߃�Ney�܌
-Ӏ.飵
-Z����Y��b�� 8
-�nB��Z�������E/t���ص�hky"��
-��r�C�W���4*��GF���G9m��_a�t�<�ˌ�?3�!���qm50��JŃކ���SOvd�kN��::닕3&��J����̄���2#өR�����B�NP�"�3�ôX��Pפ��
-��h���n>��	�>Zj���k<3�\6<*�Ԏ)�gxQ��<��WVKx�.38n3D/M�����c@*p`r���Vjk�t��̤(��օ]��KẺIP搷��2?x�R���R�ކ2��Nx�L�2#	��P�̄���clVׄ�����R=S��-Lx'��[��}�M$� 'TN=��̇H{`�k�V+� ��dFx����� imd�u�y}`2����)�.�I�QY(/��D\�|��$��G�2��xҖK���3�S��.X�k���c��BlқpF2��ț�YrcR3����V@�8������.|�X��T�ґ1�5�\��X*kg`� ��
-��0�hz����~��L�	���	�,��Vl������e���5�8����u�$�4/)8El�+�p>���/B?� ��o����F�.N�MD`#D:-GNV��u�U�Tc��N��*j2�������W=Q:�rx���:W/���,~�Mp�Ec�"{�(�A(;�`�� 
-ޟ�C�y��J�������К�l	! mӄ4<|t��`M"J#U����[��\A~m-�?0���vW��ܒ�������r���6�zV�_�b�-�@xn�	�����7B%!���=bm!-�'S^E�=�a.!�M��0�E��"lݗ��w.�%Zg����﹠=zWH!���	\���@� ��$ZW	�1�B�f6(�L�a����d�i2/�F�ˋk������-;z�7�-vA�~��L%9M� �ًwk�z��ͽT�y#���ej,�[K�̓���w5��0��d=׻�#/OҙVf
--Q�B�'`�<2��3�T�.��ף�X��A�pӱ�cX[��m��vw�DY��x��(\�YEA� ��7���z�Q�<�b�_6��D[�A
-�����4��z�Cr#��B�|�օ�2�:���C����E۟��'�V7%!'C��Z[�RŶ:"����0�M�!N"i��� �m˶��5���Q�h��0 �!?a��mk����vgRv[����Mh}�ou�-���9�6�)��64{�ֵ�/Ė�4����!�Byb�,��Jt7C
-�DM��cQP[j��x���I0�3���b!I��NեG�l���\�q��GY����WE�v(��Gҷ�t��o�ciSv��a��
-օ�(+X��+�҅paW�u�f�BY����nE잣%�S�U�_�B�	�r73=qG¢�WЩ�%u��\T�"��� 	�-&�a��ʄ�v�@Ca5H	@Qދh& ˓=������u}��(ƴJ[M�QY��Iz>H��=�1
-֠�m�k��U�����Y>λ�����q[ko��4��)��lK煜3�3��t�����
-�GC(�̈��M���[[���+�I[kC��հG1��&Wǡ}T���E��'�D��{��z���@EXty*]��2S�@� �u8TBh\mVBgO9B��
-�)u�����K��?%*=�*�rY�B�a�M�+���u�	��!�@�����a�"��93"2�d{I�ld��b��"��Y�w�2����������5�4�t�R[�A'��ie/�ke���U�'�Ί�r��;ԅ4��lt�϶'@��O��FiW	�A��Jv�rj�Y�f���z,n��l[�ͮ��PpCn�$�8�e�]��;������P�����r��i�w����!�r�p��ai���U�#��9�V~���Uj���sgi�׭�^Ʈ �PHL�Z�AN��-��n�+k�P�#!G6Z�A�A�E����]2�l뷺�ε��<j�̵�\�7�m�Εkws�-��'�52]��lM�s���0[��:N4Ѐ�K�ǧSѽ��r�Ux�����S��w�}3,�xttd�l�>��f5�P�w<���e�\�]'n�q/��au�L\��lw_y� '�3:l�5�I#f�'���tF\L���������K�blvz$;!n^p��u�j�qi�V��PY*��i<'8��!��1�^��c�!&P`��#)z���h�~T�/5�b������������slN#��n��*�W�_e��r�S��� ,��c�A$�/�l) "8O��98��HG��8~���v�lO!rZz�w�
-t�aw:R��e�*첎�@cЧ�zU�<�YwE�p��H߬��w��q�A�@yK?��;�=4��B�[�^�Sr�C���?�\���^chH)��ڃh�q�}��÷	�#L(��Fw�t��D�h�Zb�4ŷ��CJ="����r2�C�ك G/�t&TβI�U��E��Α�V�B���ѵnD���!��Í� W������ 	9�d�v����BxƲ8��nW(;�k@n�hZܔ �Kf�h��#�"��j5�'��߁Y�v�P\�? D��h���蒔��1A�U���|2[����T������BǱdr�f2_&m�g�a�C�؂��¿�S8l��;�7��F
-fF����MF}"m)�I�џОL��F�]��������z��ݷ���E_�`ж"��_G�=~�� "G)'~��&Z���ñB'����q��]"�DY�A�� $8�wz�����h1�6Q�S~�D�?պ�=.�&���Ț��!j2��)����m+�ծD��ގ�j��k�[�&la��H��������Dy�L�pW��
-fmD4)����`�;_�gʄ���'�#3#~$����+»8���a'7��;��A���K�4b�98�r����	���7��J�݂��C���dO�1�ѵ7��\F��I՗C��{����A|K���?c�f�J�BR^&*��ȈM�M̮�F��|&��~�K��S��]9��5��aO�k툎E�g��A��Q`��xd#"�Ɓ��qčX�\�e߿��ɫ��pt]��>��w`��ltH"�l�m�Ɋ�H�)��(�����p����p���Gx/�-̐fhc��α�|Z̸FE�gj���fƚ�� '�ozt5�u�v�Ⱂcuĭ�C�m�;o�l�gh��s?��,x̚����a��)B6h��	��,��ƻe͢�:�U�j�W4��o�'`��R��������Ǻu��;�Zt&"�c��Iv#��ۤW��1{E��c>K#�0@2r������ѵcG�^����ӢټņIWA�q!p�����EC۱hx�o��C���c�EZ��fٟ`^���<��0H���12?����^��{�i��[+�n��:�O����)��p�	G.�Z�E��ݱ�E�$��$�bv�.λcI��]5���c����p���¼7���`0t�O�G!�ʸ�C�x�:��7*�Nr��yo<&FZ8���G�ܶ]�J�G a�� 6J�ɻ"�~����O��������� .�����ٽ�|��_&qf(b���J3�O�]`a�#	�x;Kn�[y�A�A+����r���J�lέ~_��y�=w���}������ӓk9=^�Ȱ�6��Կ�J�b�<��d|1��O����m���(w��.b��Wv�YCF�B:'�x�Bk��.b!��]�c�B�[��Yp;�/�E,&���;�L�H��.c��^���tʖ�'0���`I����]2��[NSoPϸ8%.��8N_�]_'��$M�o`c�1(��9@�a�{o�����w��t�P�K>]�u���n^.&�#&Cd���;�8@n�m>
-� ��$��d �VdD��4F6D�����:w�1B0�D��q���8�a���C�?��f�B��mtr���j\�2p��,V�m5���l�b��O�5m2d��v�H���}�4�t����8TV�t$a�%S��85��f	���E��|H�� B��\m��#�X�IG����4�@4r8� ��u[����������O�CM�����C(�{ұ�`��V>+�� G���0 >�Т���7�;xs˹�.�s�\���/��Q��S�e�^�F̗?�N��b�mopW1�����"���7Y}ob��	�z�����s�/�v�s�@W�� i��&Ϋ�����X{��k�� .��[�\�������C��a}x��#E�Yf���h�Ѭ��Qq�[Lڶ�g�;c>|�ݺ��,`���kd�x�|�;�k�ZR7~\\9ܯpv^�F^��y}��L�V�b�K0�����#~�w�\֙���Ӧ�;��Ⱜ���C�t��36��Ԟ�8��<LT�Ûu�\��ޞ]\��u�'��VS\&��*N�$#'.���1t`�4:C�c�ƍq�v����:r+�~��y#F$��ã�6Z�N�(a��K�5ԅx�!�Q2�g�
-�q��x�7y�㮨g#�p��Z���_'r�1Rغ��\�H�N%�u�QJ/� t,]�O�Y�<�r��Ғ�elS�lT�����Ƅ?D8����/)�JS�m��ޤ[�u� P!8�k���a_lu�Ý���\��p#YN=��#Y޺�(���F�>h\���';�ϻ��Ty����@�浲m�%>�Ax����e��Ȃ�����a�MātX9|�a8+)"6�F77*�s�q��Go8�c�����sׯ�j����K}����'N ��G�d��{�ε��=���:�[��Gjgo�]`gYn��=D��^c����BO�!%�j�7:���Ri�<`s!JP�*�So���]������K}�'<E9B�E
-�
-Ή(z�g��k������M����A�T���0r�QN�M�D��H���D�5	���E3�x�\��DB`��Z�hF�؉��X�c��C�f�e�"&K˸,��qWaV:!flܦGp}I;.kt ��i⮕��GD�{�1Y��H,%W��㗤/�v��$'�^�,��,�VKSM�ɽ�%�l�ke�0~�$ +�g�Ϲǭ�,6]h6�x�B�Ĝ��o����K(���3�����A�"D��v��c8�4��l�PU��J� �(�ђI�no�w��ʉP����Tי�vv�.XV��h= �*t�Oz~�tV�3�Q��kȸS�%	CɲdB(e݀��=�Tj��	�[���R��r"A4eEb�._�(�w���H�\�I���z��.CI��"t�;����#�����ٶ���sC�.w������n�Q�2_�p
-��nm���_
-�х%b��F�ODa���}ġ�ţ<'�p�J8LE6���T��@O#S���X��k+��k3��(Ta�+l�#&-sp4��;��f�]��{�l�7q�D�4�}5��j��
-o�-���"�k���(��7��E���+�V`�͑���2 *��J�%|�c�Ɲ�Aɬ�!:�SV�v��*9�tU����y#�WCl)�D[o1>���\ � ��1i�!A�gC�Z�Eh�	�ao�w�
-V+a	J�ܚI9ɔ�~Dq��#�u�� (V�-Gѕ#>[N���6a෎����WR�J����	���M8G��~�c
-|�a)S#Ѓ(:�B�r�(��}�^-f�(U��r�P���zۭB�'bBFmOw��c����J "M	���5��B�4i�a����|3?!>�����ǌ���E��,4c���\FCte��J��˖��C�u���a4�2���A��!�@ac���<U�2s�-+!���Cằ)�o�# fy���0��@�=@�w����y��&�XmW�^N]}�pfys��y�=�&�]����u����c�����D�
-Zh�"$�Y.�5_��UDJ�`�;��k~�rѐ�N��C#�� VU.j�'Ľ�,~2Φ\����o5��Ԉ<��6sq9��F����e��J�9�"��-�	�rO�
-zdg��Kk�6l����[�T�I�rDD�E� ��%��W2L��!������Z�m�҅�K
-�Iܶ���ʨ�~�`�ھh01)�$?�z�am+��ah70ȓ'V������c9�1!�a��x�E,�S�AJ��&6(q,7������Է0���F��kÁ�KȺ��P �y�����Ȇ�A�-����&^�WO܅ײ���;�{p���!�J�Z'��͖r�rCn�hR	��V��=�Ky������QN�����.�t4�"�])�ǥ���.���B���T4ZѶ�օ��#!^G�;"s��P��P��am[J^�A�s��SLorcG�SR���������r� �*-i9��fC��H�kcC�b
-mؤƈ���y�#´m�J_��w`=��pV,��ÿA�g��༐_��Rl�H����$���k�d8�a�ڱS�N�b�hK�S��I2��G^\�e�&x�a±��'-��e��8ڡ*�{+,oJ.��d�0]�!d����Yf!��'	s���A��<@<�=�Kg�3R�!��@H?3�rs��w({J�����í�9��y��V����A>=��S5��Z�@+z���?�"�@w ��[p%���ز���reY�ҡm�5�A�ܤw�W�;�1(ȯ�H�WI�����ve�.K��Z���@e�7?v�T��G/)GH�q��̤�0m���M/mٮ���5�u��1� ��b��d�\��f���hy�����̘ 3y4�Px�7�hI�l=�G�ډ�/������]���x?l���
-[�N_P��A	�1���ƻ�X�_ȇ"q���w�ȸ��E��R33��~`��̂l�O�6�l��cyYǨ7(��a�ǲ#t��4Aa�������eE�!G����/L�LZϸ����k�o��7��i�]\�tmȷG%�&o�-�q`go��u�W�p��[�Λ�FӨЕ�lS��~�L쌘�Ӭ��zВ�f�w�Oh�!ȍͰ`zȹEd:F�<��]��_���LҔA�m�6��,�t��Z���������9��-S�q��������(+�<��Y�7�1��7�.��� ����K[Ăta���L�������E�����d	�����a �eC*7G7r�Ҷ��%9F�r������3��=;L<2Y6Qq��E������z����:��׎PX���7��es3�8'�>~��M����- o[�-m�tː!V���]k�ݻ���`^>أa8<CTw�
-<��c��؅�n�x�J��0U�}�O�"ν����A���Ho�혋) 
-���:E�x����(x���:�5[�扛n2$�D:�f��R�V�P�q�|R�a�&�,���9ꭢ8���y��I_��L,���VKgU�f��2p(����{��
-b�6�ł��6�ےt~-�@�$1	��c,o�we��+�.�r.�-�aY�!ozҐ+��@ٖ��_5Z�X��Ġ��E�]� 6���)�xl$~�ʑuE�����N��WX.�0�v�W�T}��[*�:8�gm�Δ�u��Z���~@tv/��|�wG�R����{x�Fr��n�<�NgW�A��7!�����Ӱ�>x�rS�F�ڹQ�iw�q�F�F_�ߞ���Oh>!�ć�p}��䍝'7�O��ܿ���ͭu��pm͡l=Ms��<������Z�ϗ���Y����� �m�v�^��<J���<M��"�nԘ`ta5�Cw�&�ﶛ���K���SʜRTJʼ�9e�A�r ��v[�!׷E�\y�k��W/��r�!�g<�n�z+D���'�G�3���^��s�H��:��zo���r��e�U]��.z��˻;L��B��c9R!$c��RNy�3e`4[��ቛƟ��D����*��^�Y:R;r��#UQ�z�!J�H��ثl�i��c��"��n!ե��u0b'��B�g��3�;�r�)��|�\"Q���-�Y+;�m�D�v�2� r6�����q����e,�8Onc� �����ҷ�  V�ϡ�<'&H?+���Ý�_o��1���.������6��5��U��k'�'Nt�ۺ�'�5`Aׯ�18��(z�ᙜ9�q�G��i�5�ж�=���G�ڛ9��H�f�,Tj3	5ry �l��$|�38��o��E��4���b�-�Su�Y����!с�!G�=������p9h$���Z��9�=�!O�5�a�U��pD6'��k7|:F��PJpӍ�#9�4��FN�I�I�S�`�n@ '`���i�A����ρ�H�q�L�_�EH�j�Kf��KY��`�e�wT�D��lof��+�ڛf��	��&�ސI�Vf�,� �s�S���U���y�G��W#b��z|�5d�}�K;Gҋ��@�a���QCWfS�;��m��R��$�U�]o��(��A^����^�k5U��x1O��I��z�>�n<Ʋ����;$y%ʲ�� �k�d,��o�]w�uׅ�L̾εSl��_��	P��y�K���\��$����b��Ď�G$wI������R	���%;=�9'���r��h�uOXP��~�|r�sYOv5��ob����k7��."2q��{���|��d�+Y��6%�(L����r>
-~o�s��}O.L�g�=�K�۷���<���L�QE�R���	aH���������`q�&�d'ǀ��ٝh, hx���;�\�.!j
-v��Ju{+���zB���X�r1ؑ!��A���oT�uî�n�5����:Lymco��`�ڰ�>�`��������@k�.4 �NW����j�[�����?p�Ҷ{�T��i;��mgz��T0��`�li��T����;�Zw2�K��K?CmV�f�6����FCmY�[���U7,u�N��P��j��>v~��Z�f[��[-��Q�vն����������S�j��v��nO�w�AO�[��V�;�FG�.�VKn��������u��������Pm����3T7j{�^h���֞��Qw��]ug[ml�w6��z��n�ԭ��c�;{����}����uQ�n��w�áڇ��갡[�vW݁&5ԝ�z����m�`TkOm^Pw.�ݮjԍ=�����V�w�;C�P�zOv�K[Ꝼ����Y;��Ӏǂ���[�zCm����ڰ�ƞ���6��=u�v��`�nB��x�uk����u{G�4�κ�骝��s^��Rw:�NO�6�nS��.����Q{0t�zǮ:誃��=��ZCu�V��HK��R/�Խ�o���5�ux��;o]�mAx����~��6-_�}�����`�����pg�7�}�ߝ���-h�V�wPə|�?�d�L(�$3��L&�9��*sm�H�h��Geʙ�L5��9�yBf'��3{������<GɼXɼBɼZɼVɼI��O	�/�S���bܥOS�g���ƋT������j��j��j��j��j|C5�M5�]5���d��3���?�x�����xZ�xA�xi�xE��` �߭��'�'���F~��?��c�u�n�x�a�c@����:���a~��	�����k��[��2����|�0�m��1�������yWR�	��	��a��A�EA��|C�|S�|Kм?h� ��/��
-4�#h~7h�g��a��q��I����yw�|Z�|z
-�2�2�2_2_2^2^2�2�7&~5d�s��������Ð���_!�P2l>3l>;l�6�6���/
-/�/C�W��+��k�� h|4l|1l~%l~-l�K��F��&�x]�|}��1b�9b�������1?1�0b�i��<�|��~2�1�)b~�?��wE�{�拢�K��ˢ櫢���ޯDͯ�_�Q�y1�1��1�1 ���z��G�g�7�7?7���������ſ_�"_��ߍ�ߋ�?��?B�O��g����;a>;aޛ0��0�K@�7$�7�_�	�]o�|;��O&�O'�/a��$�o$2�L��B�w�&��'�b�5I�I��$?�4?��$�?H����'ͻ�������c�{�|?F>8e|x��Ĕ�{S�'1Ꮷ��O��i_�2�n�����M���yj�|F
-g�܇?/J��J��I��K��O�oJ�oF�R�S�0������7)�oS�/�̯��H_K��2��2��2�����̟�̟�̟���N�L����M��������i���{ә��������͏���p�ci������_��/a���Ͽ��������]�����Ӧ!��i�i�9��}��K��W ���曧qG0�=m�g��!��9���3{#q�x�l���=��{g�ϙ�>w6{�l�y���g���o�5�;k�o�����Y���g�_���?(��I��z���eFɼ�P�U�2�>�y͡�ke���1�?��}����)<��md�y% p�����N��m&��L����~�Ⱦ2�\��M%����ó��d_�~
-K�&��.��<*��D�K��;B����tX�Y\�Y\�Y\�3��o�g~�d��~12sU��ײߤ@�y��f�dq��T���f�g����U�߻
-b�g?ϾP�_����g��?�
-_�q\z�,~�?���?�gq�ͼ!��u��E6��D����W���Gٯ_m|�j�_1��D����TWS�R�/�٧Oo���2�_��y����T��SY\Y\��E���!�}s*���F�?8��8�����В~��(�����~)��^:��t�.�{Y����O�|,��Y�}���%����JH�+W(7(a%�P�T�Q��+������>���?����O}�����?�)�N̟Tԯ�0���>ojr���?���?�FS�sRU��J��yB��K_�)��ٯ�������h�C����o:zە��K���M*��٧��K.��/��2�]�]Y�O�����j���}����|?�X�Ǿ��_𴢮���ؽ@�q'�g����/ ���'�|��9_��}��~�Sҡ�I%�9�]���߸[���x�Oџ�a���4Mi���ӵ�3���Nn<S{��lwN*�gk�{ v�|������hXI�Z���w(�� ��<ZtGpWU��a�/�^��tRy����w�X3��ƼD�ޭ�TS"�{���˴�ˡ�{�W`��|'�Wj>	e^��J�D9�bEI�Z�Z^�}r�/S_K�~��:��m����O�^��A��M��
-�My	�C�_Q��-y��.����Rަ��@�CPG��۵��q��FfVR�S%��r��oB��wj��)�!���('C��_+����GS��{��z��~�B��^QR���>D��?)'��(��E>����.�5E�m꣐�g�c�?����o*׾�|������I�Z�E����~_��}[������E��z���g5�{b?P`��!}��+�}N�c�S�?����x��?�Ԙ��r��4x!�����5or������T�W��1�n_ď�3�KZ���꿤V�\���J�R����R�kw>����Jݭ���TXy��߫�ĉr��e834@�>���i�sԯ@%�U����0�@��|��ЋՓ���_��	r���5-�R��KT�_4��/W_�~]��z�z��4ȉ�^�~K�?Q^��ޢ��������ÛC�C������!�; 1ީ|?�o����ޣ�)��pB�[�>Q��~P=�������*3ƧU�G<�?��X3~ϧ�	5�3�i����S��)����3M�^�G��?���s���S�)ׅ��*/S_��7/�ϫ���w���*����Ƨ����|���J}�_yp�oU��~�4�F}��4���I%t��U��W�g�����g�o��>����?������ʷU��P�r�?�w����\�0:����������-�U9p�y~|����cu�P����~j�/��CO����ȏ�|��Ő)��2�R�����=��r?�� x%��{ "ρ:^�AȽ���_����{����|��������Љ���{���������r}�%�7��<'^�{����soƾ�����:��}��}o�����6?���Bo�&|�{;��}�C�_z������MW���UCW��/�+]��Z\��JWSz`Z�{�n��ݘՃ�t�
-]�R�����z�=|��?Xֵ�u���]}��Q��u�&=zL׎���u�az�=���H=~B�?ZW���5]�u=vR��O=X�}�tߜ�u��k�z��_��ѣ��ꢮ.�Ɋ����c��>U�S���]?����O?Q��]������=���6t���-=������k�����:z���z���:У�n�z����zQW/����'�'��St�������KѳOU�٧��tx��3��,E=[���U�Cυ�>E>����x^ϋ����ߗ��rE���J�s�Q��^��^��7��7*��oV��[ �[!���y��_�H�ME���R�k���V��:�i�S����(��??���>�@ݿ�G��S�����O(�?S����Vt����лU]�������3����SU>S.���φ�x��9�<���y<�W��U����x^
-�^��G_�+�y<���5�����zx� ��y<o��-�����vx����&<���y<��=�����~x> ���<������x>�_���CW��O����<������<���3��<���U��������	<��1��Y]���s�}�G=h��G ���4q�8uS��8���I�8�q�I��雦N3��%��b�!@l��F �Ğbo�)�b���w��G��o������θ�{�g��`����M�]���]�n׎ya�6/�}��A8����@m��Q����cpN�Im������e5WpF���9�����Em>��U��pn�M���܅{p�Cm��+�~w���ӱA��[m�P?9����|6淋=��Ʊ�����8�%m��rL�ސ}�/��0�1Yy��9u�e.u�e(.������pAڑ0
-
-`4Ǎ��P�`<L��0	&�(��3w:���	�0f��K�<����sr�����[�`/��P
-K`���4@{�Z�K�*å�0P�.+��]-i�{-�ÿ?�Jm�ވM��	{T��
-۰(�؉�w7�\�^�^���� �Cp*��B��='�O��=��ոg�����s��9�q�_�O�κ���u�*�נ����i���M�[p��]���<$�+�I7����g�K\��.=qy�d��J�����[�����n��q�����;wn>�p��#qG�҇t)��Q�q��X(���q�;w"�$�ɸSp�8~*�4��3pgzM�b�Y�铲f�҇����Þ���"�Œw	,�e��0��.+8W�r�+qW�j�5R>��`�l��ÿw.}J�F�ji;���]6��w+.�@�m������vlz����]�2J�'wك��4��Lu�'p �!8L9+��*8ǉ;�{N�i�&l�2��PW5�gq��y� ���/��_��װk	�7�o��"�6��w��P�f�Y����} ׬M燸�����LV7����󗞐�?/荝����dO��Ѯ` q���ww�ågU���1J1F)�(U m�cS>���0ȇ�0F�((�ќo�X�Q�8�x�@8���I�M�)��T��a̄b��a̅y�5��(�[�$�Ƙ�O:/�f�Q�5]J�o��.�R`��ZB�b/�k�x����W^�k%�*X��w-�:ү�݀�6ao�-�WH��s ������;��	��{`/�����pC%��PE�cR�\�q�'�Or�S���_g�k���i/�(Ǵ���u黀Q1"*FD�P�7ǜ�p�|.��e�B�W�v-qׁ9@��7���Z(���60�Pw��.��ýOs�F1�Q�as�F1�Q�as�F1�Q�as5G�`���s(�0����˿�5�|�~�ݘ�w�3_�	ِ��7�B���? ��8�r�!���فqڼ�g^g^	�� x�_�;�B!�O�J?�*�ī���#�����`"L��0�`*P�W��t�3�fc߫\ӫ�a̅y����g*m�mo���]�mwJ��J��k���닡��Ѥq���8���q�WFx9a+a��5���z�@���	{3l���
-¶����6��{'�.�����݋�~�p�?�{�*���TT��Gp�X�~��U���?�{�$�)�ӸոTG���gq�M���喩�p�E�\���W��W	����u��7qo��ƽ�{�jκ�{�\����RNC������'.�Xq��8);���N��MO��MO��MO���N��^c(x���5����f_[!]4y�w/荝��Xc^�KX?�` �<C`(3�|�1#���0�ܱP���'��0	�d�9�0��׋�
-�`:̀���bc�x���<7ǘ/ͅyƼ1�B(�E����Ÿ,��(�]JZ��/q�_��z�1orܛ+�c���79��2(���
-V������`3l!U����؆�v`���E�q��e��/S�_�_�_�K�2eys/���;�{�a�$�#�G����*�9�}��'�1_=���@�g��y��}.��e��}�A-\�p˘�o�ށ�pO�rS�,�QY2���"z@OȎgo��%��os��S�o1��&ӓo��7ߒ�w�x��~�2��=�c� ȃ��条0�i�;L���=F�((�7Y�T�;~g4�1�滅��#����L��;�D�&�NƝ�[�;w�t����	�س`6�ܹ0��X%�sl)��{i���
-(�rܕ��`5��7���u�6�1ޤn�7�n���V�R��n%n�v�o~ iwb���o̞x���x�:�N}*�:G�
-��q8'�͏Nឆ�x��L���9�ds�
-��S��~Vo~vn�M���܅{p��x;CYfy�&`Ϳ���?7ǚ�EXo�\k~���ǚ����� �Y�����0��༬6�G�(��Z)�c��lr�5�BkƓ�D�'��"�i0�2̄b��a�5��K�<��/$\VR%��`1����2XN��ePn�oW⮂Մ���C����B�p=�`��!��7bo�Ͱ*`+�m��v�nk~�ǚ?��|�*���|t �!8�p�B��G�qO�I8%aPg���98o�{�ї�鮮�\��j	�aM�,�eU�-K�lY�eKO�-��l�*�;�+rO����d��o�t��>��������7Y�>�z������7����O$.�J�0�7��H�Q~;ܯM��Ghyj�XcE
-E��qb�� 2Qd��d�Qr���D��L�.2Cd�H��,��"sD���/�@�@�[(V��"��"�"�%�N2O-�R�e"�EV������Y%�Zd��Z�u"�E6�W)�Id����r�3E�Ef�0W�S�Wjm��>��v@�mbmwK�Cvp�v�M�n���o�H�?D��>��~1�	�������a�J�#~c�rێ��s�o��oF�"y�:-�x�:(R-�Cb��F��9�u^�����^�$rY�D�v�s��9+rE�\�F#��T7�f���G�~����-�)�%k��+G��~��}�"E�& �D��0i�#�8�	̲�
-�^��^.��	f��o����`&�Ay	f��`R�%؅*�II�N��,��s�'�i7Uj���4I5URM���&�=�M?���5Fd�H��8�E�X�Td��M�(2Id���"�E3d3CM�4��"3D�I��[� ��3S��#��)nn�)V�D
-d�&(���X͗j� E�H��rz9���X-Y�o�%��X�1CFs)���8���3K�,�T�e"�EV������Y%�Zd��Z�u"�E6�l�$�Yd�H��V�m"�Ev$���̖���jW�[d��^�}"�E�9�uЋ�JܣP���8M�T����p.��:�{.¥�P]N0Wĸ*rM����b�H0�M|�඄�!��b����E�&�6Hd� =	�I@�9��荑�H�}��W��x�s� (�#�%�2�΃�0Qf�r�P�a"�"�EF��%R 2:�$�I4%�]�b�X6|Tg\���s��25�r�T��a̄b��a̅y0�B(!�E��4Ѭ�s饉�L�zy�]��M�*KD�EV&g���@���� a�m�d\�D�Vm'�nd�b��VM�"�D���a��v$�u��1���(�T�s��F�����>���`�٬�l��E���"����2�K4[TO4��I�S"�E�EΈԈ�9'r^��E�K"�E��\�&R+r�k�	��6ܑk�{p�Ci`-�6�=!r��>��A a�0�ia��Z�=j����"̞�(�O����I4����3�Uaf�0&�D�'��DN!�H��"�D�4fB1阪�W�$�2�M�:	��E�h���ØO�z�Z !����E��Dd��b�1�S����n�+�R�]"�Td��r�"���e��VJ�*��"kD֊�YO��e��QB6�l9 %:(�E�"[E��lw�� ;��)�Kd�������}���R� U~��9�*E�{�"�D����-�!u����I1N�0)��ia����Y1Ή�� rQ��.��
-נ���	��6܁�r�=��"D�tm�tkIk���)�-�#�K��H�H��"�D��4�j��Qy"��H~�i7��9������_|v@��?���oi���4Uj�Ȗ���(��0FƊ��/2Ad")&�d�E0��L�s`,�XK`,�2X	�a-����YN�IQ�
-���l�Z��q$�d�c'!\��]��sqH%��]���=C��K��� $��a�J77���Tr�8�T,A�^j��9��"t�U�V�B����N����j85r�Y�sp.�E���$�/Y��#rU®��~�T�Xץp7Dn����ҜPwE��y �P�k�M��H�$z5�OF/���G䊃���H��� �*��0���1F�gF��Eƈ�)'2^d���$c&%�Sj�HQ�9��%==��b�tF8H��
-��"�D����5�r'��d��E���(�jf2�G��I欚�d�I��j^�9/�^��&�I�\T����"��*k���s��.�,��J�˒��B�L�\d��*�]k��jS�f8��u�	�U���0�%x�X�k݁�Ş��diV��z�m"��t�m�C�K�T�M�B�7c�c�w,I�H�]�{I�=�"�y��Jր�R��PSd��M�[��n�]��8��v��>d�d�C���$�����;	�#�W�������j?���R�7�|+%���<$rX�ܤ�$sKM2��1*�%s�q�pN��$sSU��[�Bj�,���p.ʭ��d�H�6W�w-�����I恜��s?v3�tշ��Ð�N�馱��{I��~ �0	o� 4�c�qsD�����:��� E��"2Td�H��p�"Ւ�H��y���	|=��-����#���+d�/s|��˼^f�}�"Yo�l_���`m`d�!kYrȊC�ސ冬6d�!kYj�JC�ΐe�,d��G�%�CbL_=>`'|������4�SpZ�4ä �E���La��_o0f��@f������ =+����("��܀����@d��B	�oڔLƢ�-$��zI Y*�Ldy��+D�&_�k�X�3��zM Y+�Nd����"�D6�[(Ll�m��v)َ�yjg����лE��`/��p@�������X����H��r$`F��U�18.EH䜠͝
-�1�Q5S��a��T�ŀy�2\��ڀ�K��3I���
-��������G�}x �k+��b�%F�VF6E&鞄d��o��`���K���W-ir11s�{F�bԈ���1�ѧ!�Q��c�� "�K���� |���@ҋp����������@���&�\�k\��V��� _<�EF���ʴ,�1��d�~�KH!!�aL�I0�@Q+3��6�짵2S�t��?�[�"=c6̑��"sErDrE��'�J��@|EJD��ؚ*�Npi'���}^��-��D.ie��^����Z!�EV^�V��Vf�~� �0�z]+d��� �F�M"�E��T�l�&��=Bdg+�������w�6Y{(�^��aUs����rnN�uw�0��և�m_%�F1�`l�(�f1�0��q�r(���I�q�"'EN����pj�,�� J�u.�E�D�(�e�W%�k�pn�M���&�u�������A+��y�k�����08̓�!�G�}ƚ:;��%�[$W��H�d��_<D�"(�
-�$"_d8�0FA��10
-a��	0&�d�"�L�&2]���I��dS��Y$ۚEzv22'٤�M��TS��'#t��(E�Z%�f�^,R*�Ddi�yo�H6ez%�V��c�k1։�cC�Iژl���lv-���ے�j�Cd��.R�c��^�}"��M��f��bM�G*�:"rTd�A��:&r\�D��p2�<s:�l�gȿ�&�M�<�ĸ�l|�ĸ,r���b\�8,F-F��1��q�3����Ub�"�6�
-�8����><���5Ũn�#�<�3ŎU-M��IAz����нSL���!F�m����x���z c�H�!0�A>�Q���S�)潑P c��S�=4&�/��AV����"�D&��E���L%�ibH��"c��N��)&i&�a�M1�y)6�g*��d�HI��Z$�b�R�%"KE��,YA2��L<�xV�cm��Z�{w5�N}n��x�!����U�%p�d�Nd=�~(�$d��&��[����ܱV)�Jo�!�Sd��n��co�9�eM�9�}d~ �����>��W��S��HU����x�9�O��9MPu�=��M��IA�rعsF_a=�r1��H�PW��j�9�7y�y]+��bo��&�w��~�����H�T��Hw�"=E�ErDz��N5&7���C
-�+V?�	�Ȥxs]HE�eL57�ڲ�RM��TsK*2L$?ը�b�)2J�@d����"�"�DƋL�Љ0	&K��"|SaL��TsW�J5��Ts_�K5m�2�*!jq������P���,I5=�e�X�EF:�
-��DF��\��"�]%�j�5"kE�K�:��s���*�Md�GZ�k��lĳIRo�'�w̓[^�L��C��V<�SM���I=�N5��B�����>B�Ku�Ѓ���C���S)rD�H��1��"'DN��9-R-�:gĪ9+r.�$�O�������\LE.��~NEK�y(�݇�b�9z�eI5ܘ�+�f�S+r]��M�["�E�ܥ��`�<��R͟<L5���if��3�a�V��f:��;��;<��>i�~D��0�`p�q���|�f
-��$d�X�*��0F�b���0!͌u&�L�BPL�i0f φ�)	�řB�XR����F�!sE��Y�f��Q"�Hd�H����"��h�����NpVR�d�VI�j��Y��6�F��aK��RA�V�m�{�;�w�n�{	߇�����a��#p�Hs�c�����	��p
-���;5pΥ�p���p��\�&R+r��d�6k�LqY�f�n�bI:ٹI�[p���43���Q9�*��̿>���>�`��)r�?a�:=��|���f��#�K��H�H"��q�AXa�~�s����Ax�`0��8#��g��H��h�L�a�(��0&?a>�F|�����A��O��R7ӥn�K�dm�y&0q�!Q3�A�]L�P�a.��B�f�[G��,�RXKa,�P�V�jX�0����bl�,���
-��ɶ�n����	3KN8��,�Ed��>��"D�z��q�Tr����dyN�i��3PC��'�\���'�<��.���0�$���.rC��-��"wD������ B�'i5�z@OȆ����\�>��B?��� a��a�!��1���'�g8�0R<�D
-DF���1X��%E!��	0	��T���Y�^�L<�0f�q��ę�1�I�HR-v�Η"@	,��P
-K`),�2X	��4�j��:��"D6�lz��߫D��Xm��-""[E��l'��S<�Dv���)�6\*ͻ�m��6���D�pA%�cpNA5��9� ��
-\��pn�]��kk�*�hm����f���׫��ꍛ}�?�<C`(�|��#a��10
-[�3�vzF�ܖ�����\T�E&p��֦VM,�}��.KMim�:E�3��g:��	�0Kg���K�<�$`�H��"��"�"KD򓐥b-km�I�I񖋵\,�m�U�rXeP+[�%]�*1V������Y'������%n���z�f��wl����]�I�[d��^���~8����������\�T�fy>H�H��.��vΎ��8���pζ6e�9���.��֦ܹ$!�[��Ε�f�t�YW[��&R+r]���>+ބ[z[��]�{"�Ex.h�>���[��j�چ��C�	ِ� �@?�a��`�`x�ڝ�,��H��62O�(�1P�aLlc�&�Nnc�8SD�D��L#|:̀�P�$b6���`>,��P�`1��X
-�`9��2(���
-V�X�`=l���	6��������	�`7쁽���8��0T�8
-Up��	8	��4T����p�����2\��pj�:܀�pn����><����)n7t���!zAoȅ>��A a��`Ca��p#a�hc���x� aL�)PSaL�0�a̆90��|X ��b(�%���rXeP+a��5O����`-���6?e�:[D*D�����	�`7�y��^�}O�u�~�"E�&���Q��cpN�I8�P���SL�/�\�*rM��)�޹��ɺ�3�["�����=|��x�i��)�����&�?�W0�dv8�|�U�|"*�
-� ?hv:�7�H4i����1�c���.gb�N"{5��)P��ƙ�ε8��/21�{�љG��0HyJ�f�,L��	)�U�૎=�$��Z���1:�1��n^n.��~��EȊ ���2hڬ�]-���N�W�Am&pTm7o�8�5�V9�e''��6�ҝ��N��v���|/r�AJ�*�ڃd�͐1Ż�M�9�FgW��v�8��op�idw�#�Wd��~�"E�����b��#}�زx�.(�� ǃ�w���:��85rk���`�=٭��jJ����w.�%�W���A{���pn�]�I�-�-��z��#��{@�� �a>j���!�|�[���s`�t:�J��I�!܀j+����y��o��C�^�;��IO�Gm�=U�;��f��t�u`��½��I�CI���dZ���v$�Y{aje+H����n�q�X�Ǧ�Bq��8qǧ�	�NH�ŝ�n'������T�i0f�HJ�#W0;�Γꙓn�v�����,L��S�f�U�<)�f.b~��(�B(��E�v0���^g����t��$�JH�)K�w�_w�܇p��C��r2[�n�h��	��U�d�ϋ�/V��6�&�[��¶�`+�T�iqvW\+{���P�G�DI����8g��p���Β�N�D�Y%�Zd��J	�P�ɡ�@M���&�b�M�s���p)�|�}4��^��J:�|Ax5��ťؕ:Ů�)^#m-s]����y�΅��)�܆�)j�AI����ښ�to�X=!r�W[ۗ��C�)66q�N���p�T�>yj�M�kk���fs[�fmk����vD�T;��Siu��{rz*�2�^�O���Oh�j�9t�jrۤ+�9�N�b�Igr|R/�t�آ�iv*�MO��p����4;w&����l1�,�3��ŝ`!��"XG�b�R��^�;w)�2��w$�
-�;�_�[����]k�2����N�Ǳ�a��<�iv�F�[`+l��0v�.�{a쇡�b�2aW���R��4[�{L��4L�>�[��.e?�{.�%)3\���^�kPץ�q�ܖ�	�ܓ���P��@����l7�=`:a=qs� vo�\�����i�����J|��=F�&w����0����c��Q0��Ѹc`,%�{rmO�8��0f>��rOƝE�/��I^��cFHђ0��],��l�sۥ%͈��V�Cj�d�x�I�!�<��\�.)�	��A;ӶkF�	B�g ���'y�zdй<Ɉ��}[�xlm��[��ɚ6�n?�&�	>eS�M��F����OF�ǰo�=��m%|Ж�\+b�g�֎]J^���v�Q�g0��f�3L2�ϰ����5���n#G�`{�)>#���w����`G�zО�O��⟶�3m�}�M�;SY� �Y�0��೶2�,ٕd��Y[}lF��d;1�wb<�d8��N6'�s�NvUz'{:��]��ɖft�{��ǒ�-��=Α�8r��D�vܱ�N�3[u��9lY��~;��	�j9��2(ϰy����Ζ�$�#�sv�h	9�����[ka��V;����V~��a�[k'�e�m���T�6�"+��dƷO�]�������e�W��=�i{�fry�M�O�%��}�Ip��%�6�f��P��p�p��e@"2Yd��0�"�i"3���_����������Rml_��3�@��g��˅��p �!8��+q�d?��
-�I����{
-�4T��X���N��y[��=��<w����v�?#�Z�g�Cث?�B����3��g����u/�vN
-q#�d�$�[���=y��9�ŻG#wĺ+29�'��Ƴk{��֞!�3vf�g�Q�c�q�'�ml-�~�Ou��I�O��oo{$$��6�WB�ͅ~	��Ay�_��K�~�OȰ/�����')8���<10����i�ן��|�-mO%�Ꝉq�S��7�t<3�3������,��I�l�9���^�c?i��i;.��������"rSEƊ�-2^bǉl��q�Ge��	�p��Dd��4�2iG$�E�%Ң�%l����-a[E�K��V,2Kd����"���$�I��vQ���~_���1�vqU��<���3/�<S��37�������8�=�_۞�90�E��B�M�����̸�x�ۛ����
-(���
-�`5l�{���)�Ґ����~Q��%�"��󳶔����d�%���vL��U��;N��=ܾ���w��LӶ�Gڛ�G��*��B�'���S��i«����d�����Ş��_�.��,ǝv�q���f����\/�[]jO�	b�;�{L�Y�U���a�o������M���V�x&��Ip�}��Fݕk���{fj�?|٨�f�w�H��`ↈ�Ju���Ԍ'�^�á��2��˴���jdf�/����/������^�HVOK��%����>ɍq�w�{���X�
-EƉ�� 2�C��$L��vwp9{M��)�{�)��tI>Cd�H�{>�9"s;��yb��`�-_��"��"�"=d�XK;0rI��^�q���QE�NJrl��
-K�WX����l���{���
-������{�NKz�Ü�ׂ����ە0ߗ��$��u��u첤׌Z����]-��gi~�����`�����N��B�
-�L\)�:�{����7�Z�N�I�]��/�>_f�lw&�|�ځ����M��&�}���ɵ��u�I�ߤ�or]orM��"�cpN�I8�;�J��+�������lO���c�
-�E��뀜� �|��8�;p3߲�;�e�e]]�IG�v@��y�z�P�;bu�D��ta�^Κ<ie���-��[�g�[���Zf�������-Z�[-{aO����V���=2�2j�dB�)w��'�W��'BK-wK��k�3T�>"�D�E��KG�5R�V����iGs��0�$%�j�f~��8(��U�W�5*��I��z�kpc����fڛT��8�kv
-By��q���R~���mU��<{o3�m�da������n�f��6S��mn�۶���ڿ�@�3���1*�edP̔��)�H��W%v�D�o���{/��k���B��׃ߐu"u����7YB���|+)ϑL{4�[t����;�m�o�p2ڿm��g;�3ޚ4�oے@B�J���w��wh(����w��w��;�y��='�n�;��^&�@dK�P���n�ߠGG�#�V���w�@{*��3��ڋm/2�U�d�gK��g�Y�=&�߳٭�g���={�J��}���{�}�-h巅�x�v4�:2��>��}{��}��������H@M�h�z`����V�0]�s��vW+�q�u�k�;����f����>h������p�r���f�z��o�p�r�ܬ\/7+���ʱ����]sݛc��"=�K��|JG�=�]J���m�C�5���X���Mΰ�x����.Kδ+�ߵݘ�)[��|���}���mQ���q����>m�}�E�b�Y"������cpN��4}3eJۑ'�������m�������ٚ��Ѥ��͇�����?fJ�lԢ��drK{:�'v������3�'67�e�h]�d�`���~�#S2m��Ҏ?�K:���riGJ�S����������3�����yBG;7!hg�|*�sn�Ϲke�W�)�Egݑ��s���?��R|�D���HyўOx1�쾔x{(����c�����Ŕ,+��fmʿۛ)���S>�����<׿�7��݌��;��g���{+�My��'���?���T�f��0%���S���� i��W<���������avj;/�?�Ct�ڨˤ�W�Tȯmm�_�����5�k{z�_Sc7:"7Ej;��	�$�;�������7v���]��'f%��y�v�K�/�[�%���������t
-����Ю���C��y��������8<㡛��V<�a�C;��!�v{܇v��Ab��gZl}ڞO�$m~�����̖'a����?�\���x�)�K��=�{Hd�x���u#D��9(r���Gt������������*��+��.Wݔ}�*���+;�
-�Iki{�i�'�g���3Q�Ikc�('�C�R���.K�V�8-G{){09 R�G�)q�G���*ֈ�s$�i�@���?�}�T�8�������������f_wP|s���6���_��J��&*!�����c�Ѷ���{<Z�}��xė��C$3�1�d����B"Z��Ɨ�DM<�h)�I#)\�ؿh�1�!QC���F��ܥ�M����l%���k��С��F�jS�̓,����aitMM����=�鈖�S:O��q�7�E���p
-'EM%Y���/�~�ړ����D��~�߀�F�����5ۆ������n]Ѩث��!_�����F�*��Q�ϗK����x�S�t	H>>�N4ڈ�ޝƝx��v��O�5J~bd|̖�4Ѭ���>�S/�q�o\��6�>�$�C�Ox�Q�1o�'h\^{S23	���M%�֢n���h�>��!�Q��#�D#��������
-RJ,�;\E�܄�H���]C�N���s�H�U/i�э��8[��]�z��ްD����{�������o��-�ß����蜘:{��<�H<φK��2��p��GL��N�wHs�n�
-_���I����D��T�O�
-�FԽ��^o�a���#�er�Ҙ���>#r|h��f��?k0�Ӻӧ�7�џ��ZH]��|XBq�	75��O"� P���1rǄ��n�J�ID|n-�yTR��$����q��Ac��M{�y}2?�r9/��R��i�}� �v:M��2����f�#�\�ܔ�I1�#L���E���l�HG�䰄�'+����&����3+v����8i�@*��ޟt�/��"��b�t������s��t ���N7=E��� ��OI�r��po���0�y1>�L����~=�όl-�K��3M�p|�����&'�Ѿ�� ��h�KM�m�$|A*�s�ᄴ^�k8��Zg�/�����x���=�����4y!]����Pn��/ĆD.!zJ!+|�?*�B��7�'��F����}j��t{�6�ؖ�>��!��#�&��&����\�]hȩ[����Dl'��H<*r�@xR���=���|�m�q�=DMVJ��Ɍ\@��V���J2���|�'^��ێÃ���g�;V�g��&����1fm�u��6C���b[�����l|��w֍��I
-VWס���'�fh�ʑG*"<��P�ΒCg_�[��t�un'�u�)t����J�2��_��*�Wc7�+M������Lk]ۅ��#��;1�O�̰�~��;Ը��4;nbS�x�f]�U_ �X�Dr\�j�/�<u����{Y���o���qH�^㵆���śϝ��g��m"��Nhߴ�8���ޑ��>۰;P��=�����nU9�K��u	z=rW���u�%�s;�|;�T�f��y��@A��>�(�2h�uW�|ѹtQ]J�x��8�S$����M�K4�7�L�MH5��ڧ�i�'<s�o���\�aÝA&H�W0���5#�G����������h����R�ڵ�?�Ǻ��x�v"���dJ��d�8�T�M%7��`x! �Ӥ$�hè�F�ڹ�/xߐh�}��@dK5���4�q5y��r�l_�ㄜ����&��*���>W�p��O�W匎�_��pxq�'�^��N�*Y�ʚ\g����J�MXb'��#�G��T~�ye����B!��W�F�F��J7��u_V��S�"�ٿ�v�~:�����Q�c�������o��&�ٿ��lѨ���љ^o�qs�}C�'��7>t�ؿ��^;��cGjl��w�Q�9r���&GʳQ7��>��N��z*OK���ߌ�&|����[rطb+%�p��.���nbL���"�Yj�8��P��^l�Κ����f�ս�Ě/zܽ��1���=���m�Xh`4�)l<z��E>�ru�zS�FO�a��Ku\���7��w��"O��<���z�&��=�V���@��.�>Q#/N���ދ���}���v~�h���8����Ƹͦ��ta7���"���יa�si�;�����c��h���q͙���TH}dM7����d�������mk���#�E���qH�u�ۑ��7|f<M�`4����-�p3��b|?��h�mB7���#�V��w��o����X�m4^+�R�nx#�o'66��܅?v?�q���ȶyh�S���K��sFR���w[ܝ����቏W��/�Z<����iW�k�ۺ��ۆ��H�^q�	͟۶M�����	�$��z�y_|�W߶�غD&���02Fh�L2㞉$�~w/�Uǟ�p�g��v�n��*|=f�����v�#էޕ��n�ʻ���{�~(����B�=i�dQ�Z8���	M��#Ky�UP�c����y|��Σ��#)ˏb�{t�k�j]�&_K�*'����K���|�y�@Y�4^5?�"A=flT��O��ؿl��8M>f�$Z���q.��5�V���z�"������T���£��f£o�����u�<��TL�n��ه!�UU�3�6��l��Z��z�X�O��bQ��_��ʍ���XbBb}e��tZ�����C��$5|=���4\^�sg<�D^=��bb��o-�l+4���`�+����*�����%k'��lܯ����ߵ��zBC�7����c��k0]rb��z���{��nk1�ճ��1{u��*|�����[�u��������Ȫ��ƟD��u������/�Bxܟ�,w�ӹ�� ���G|�c���1B�S��I�!��q4��cc��
-]j44潄��$������c?����~�U���׶��)�w�41/��f���O�;��Bx������/�B/�}�>+�R��}�0�q���۩n�6=���lb�a�E��������ܗ0�c���k��.M���Y�{r�����G��k� �K��c{��ӳp�/�q%ZgM~z-r���1�\�#���\��]gY�`wM�����st���$��9ӿv�~����E(ߖ:<e���}x��6�FwU��j ���ߢ���������3��s��m�H�u[t�9t$��_�4�����L�[dF^��P���m��ucKfLǥ}����Bs�?�ln�����:��G/zb��Q�Ib����L_�eo�oX�.�O�-y���V�ҿ��Ѕ�"惹z߫^�l���ݑ7�:+:b7�m
-�ԡ��T̴���O��6��n���(���������e�������^�?�� Z;���ว�O�_7�=��Ѩ��0lr�7��&�����ibh��DWR�����7Z%�����+�𗁑�z�	��^�	�>�j<���Q��Ii�K���2bwn��&�������t��:Y,z�r١ț&���>�2)4�v�\8��Vin���_q:�J�l�h3Bn���k$�	=��H-Gڱ�B#��Y�F*��#Ѩ!49'�8�s���z���D���OO"��-N��w�>�m������J�[g55o�7w�vN݋�&4���}��裫�S�hr�'��g����%`��ytf~<;5�iw�/<�_���%�ws��觚[#<z�]׽5�C��<�.���u���z_��n��|G>ss7�c?�����Q�k��j�Ѧ��e���Aol7��5Nt���>��_���AO��(��z��f�]֣��K�OF�2NG7�]���I��hn	>�Sp�_R+���\��j�7N��!:�����g������>��������)kx�����צ����t�n�z�IH踻��7CYG"}���u�����C��86xh��z|�U�2��_�5Ѻ�;�ǗHy>�c����fn��=fA�J��&?��Ԕ�۰�!�;]6�+<�Þ�'O���_O ����'?�U#3���?��Vo�.|��*�~�5�)ix"��>��g"O|��"_��u=�r�=CO%�pn��m�Qn�}Z�&�Z��'�<@�&�Q�vϝ�����3��ۓ�D�&*��sV��S:�ͣ�j���o�Z�f~��`�lM^�+W_�_
-�O;i��hJ�����p'z��^�;�c��]����׍p�W�����8+��[㕉�DG����_�ӡwp�D(�c���j����)'��a���TxR️�R��2��~�����prU�9��O�O[�哛h��Է7u��}��8Y2�J�t��_�m�Ӌ��}���(�}�z��e֓�~P������4u5�����63����B��Q�D���F��F�yݠ��.�z��G���ވL�B�Pʉ�%>��u�pvn��#��U�T���E���O�"Gx���WT��D	vl�
-D�NQ��^�Z}܃c~L�i�7|�T��7�%��-��8���E�����]�������#�;p���f��G�����
-o�ɯ����wQw�#�ݹ��F<��2@5�j�n�خ�+j)�W����3�F7�c~aP�tI��s�Pn�]7<���)͜V�7~���v�����d�jn=�<y�cT�{�G�CW���
-�P�m���cͳ��Ż������c����~���s�������8Q'<��1�U���#�>�Q�G�C�7�u<��Z�����#��CFfy�\�S �@�c���TtzhZ�G��ׁaj���"mz�P�M�� p�A��I���9�������.�C�W��M(�F�Q��z{b���@�/�<�M}3��6���ٯ��o���>���ޑ��C�A$�� 	B��q^Rk��>m����<�N ��{�:�9�S��P*'�YT�VZ����Rx&.ϗ��v=Oݖ�ۓD^T���������n;s5�U�6�7�>ّ�(�~��^�U��&t��nN��f�]N�_v�o�;u�~~����4���Z\8�'�W���'b����������}�W�}x�U��Mbkk�z�k��/o~��45�z!�Ko��6��<�U�E����~���@�V�Ope�/�C�f�P1�`G��!����6�nc�Wbͽ�
-Խ��m�n��%+�����������ۍ�b���h�H?ل�~��pA�i*H5������O,��3���t<�q/��CFF�|�~�,IU`�j��C�R���/b������p=���lj�.P��{���񸍈�N�W����/�Ec�#�Fd�i�}�?|��k.S�宮tu���]]��ZW׹����ntu���]��j��[]���vWw����]��vu��{]���~W�zP��:�z*]=��QW�\=��qWO�z��S��v���3�ֈ�U�\�yW/�z��K�^v���W]��j���]���MWC��r����(n��;���+w��)��(�O@�x�	H�	h1����Г���)�TSU�i�I����x[��j3�bN����F��A�͕l;��(s�:��zz>�3�v�d=Y}��?QB��.���"�?[����X�.�z��3K��|	�_,���R��a}n�_.�zq�W+�~��˰^*��\��e%��Z�|a5��5��k�W�!��G^ۀ����&��ȗ� oV _ي����v�ov���vb��.�������U��KԷ�r�o�#��������'���D��!�F�=����X�Ub���`��(�?��q�O�����?���q�����X�z��'���$��9���_�U�U%����i�U����X�>���3X����]ևg)���!8�|tA�&G9I�C]$EOu��l�.9_V�U�+D媫h���Uװ����Z�����s� uC�z�&:X�R����Uw�a�.�O��{j�2�9|�z���C�Q]Y��U��B��zh�驧(���l��f��r��`{�f��NW�6G�>�����n�J!h�J�K�|՗���B���؋� t�����g���T���`t���PC�25LK�w��w��w��w��w+Ў}��L��2��~���v�qz���{�z�����"=UO���T5C��[�*o����,������sB���@��su~(h�x:ja�[rQ�mj׳]-��C��S-	-%h�ZJ�n�{��o.�އ:�ob�obTe؇P�sX���XrV���!g���ڐ�.�9��ltu���]��F�U�������KLܮ�Kڡ�ϝZ��B?�٭e¸hg������m�[�$F9)v�:��5�a�#�0�pTU�!G�{V���}�|� ݑ^�
-�	F�*|'�1�9�:��Ǳ�Q�~�v�xΪ��r�H�
-�ڑ��4�%�#�5��#���pM)}_��q}�0'�,a7�97�<a<V���R��`�.�j��w�%y��.�/xO]!�R�
-��N�<DS<]�5�nh������u��:�^'uO}�F��o���E\�V�[D�ҷ��mv��;�����z�{�����}Ў���A�>�/{�i��z꯻:=t7����N�g��N� �Ñ�h�t�'O�d�2Xg;ɞ!h�g�����x�u/t��M����DS<�t�4�3Z����x��~؅h�g��=M�L�8�D=�����Þ��8�=�Hq�_D�=U%|���&p��g�V��yU;��z�#_�r܋. h�.��b=�Q<�c��z���B���B���q�,��2O�'d�� <���,�	Y�'�i&R�����S��H�XO�.���k���D��dK�L7���ez!��lʽB�sp�p�W��92៏�R�'�Uz�[�����	Y�KܐE��ՋY�;��UJ�z]J��DJ��UK	ۨ��I/]�r<��
-G>})#z�.#�B�;n\I�V���mzU�WS��Z�\M��&�n-�v����BA�I�[��������H��z#A���P�f���͎�
-[BA��[CA�:��T��K�g��*����z����*�vvL��w\�V���{��*y�Sz/����c�̓�������==ӳw�>�����'ɲ%G~N��Uz?�rR%K�ǥ(�ryK�;�*�R�	v� ���;@ A\@�	w  @,�J�;�=�]�r%�|�ӷo��ܭ���o�k�0�_��3�_��(t�q�(t��w\��%��}ݲa��ơ[AH�Э>p�tko�/�I���n� ����0|�i�6��-Ì�����mì��s�cs�k���l��x�3,@�o����ȫ��C��G�e�ǆ�_�|bX�>Z\�#~��uȱ�:�q�����[�÷�v�xQ��[���=���Dq�$q�u M�x �y��_gG\}�x��r�-�E1Lc%��g�t1NY��ߔ$@�)&@�%&҄�%I?�lQ%A�#&s�y���CsIL��'^�(Ʃ�/�����q�4h
-�4h
-�t��fˀ�H̀�X̄\"fI<���Q*f�B���O�su�_)��,���G��E!��b�$�y(�+B0Ub��b�t�Ո%`�X
-։e`�X6�`�X)��I���j��X^k��!���`�� ^��b�.6�7�+�M�*xKD%A�
-���;�5�x�'�����x| ����x|$��Ż�c��D�{��`�� |*v�}�C�_|�������������/�>����7� �V��g���_��ė����+�c�kp\|��-�	q�G�)q�(����r�A3-��3��8Ί���8�p�AX���g�.NC^a����-~��ª�Y�� �Y���	�y��-.�;�gpW\��%p_\��TV�Cq<�$2�/���FK`��	�J[`���K;`��&J{`��&K�y�L����1�*���h����K�`�fJ�`�� fK�`���J��%��$���A�t�),�.�ERX,��%RX*e�eR���\"��B�+�\�J�dd�6[~TK��)��
-�:������l�J�&�l���+R9xU� [�J�U��_N������ȭ��n�j�kR������R���]joH��M�
-xK�
-vH-�m��#��w�k�=�:�)������&�%�J�#�6�-�Kw�'�=�G�{���S��'u���Cp@zJ����|&=�K=��|)=_I}�k�|#�o�ApXG�g��|'� �K/�1�8.�?Ho�5�[pR���4
-NK���=|~���Yi�x��I��ؼ4.H�����E�#�$M����"}B��,|��߱/�4� E��c?6�\ؒ>�miܑ��]iܓV�g_Z��Pd���G��XZ��Dڀm�c�[`�q�3���]0��&��$��l<����1x�x��e؋1L3Ƃ��8��2��`�1�,c"�m��|�_d��p�1IY�1�e�b<���υ�2���5�R�E�ʌi`�1�0f���L�ʘ%SM�k�9`�1�3^�y2_j5J�V��2�uŘ�kW�д��P$7n��u6�.jm�?�7/�^;�e�mPdw��⮱�g����X�E��X�� �X��������'�z��� ����&������ƫ�w��[�yfl��A���x�+3_c;��1� �o���[�:b�h��� �x��ѡ�� F�ƻ�'A��� 14vB�14އ<k| ΁�>� /��>B^4>B���r�o�6�!W�����̏�}"�Ƚr���'o��~Du�8 � `P�7YC2X<�y��;/d>y��z��l_����P���[8gl�a�ÈƨL��;��2��θ�|Н	��')6%��G���`n�cLw�����&�����8-��s��x�#�5��8#c�j��4+�c���yD<F�G�c��q�g�:([�//qyr��?��~�*TI�*T�������hR�u��l@uAހ*U�Գa���Ti�6O�4��4�.Y��'SW��js:��+���Cxȑ�(�d�>`^?9��K�qѦX�,��6��c���ƚ,_���@�3qo��V(�}m��`�gX�P��/%B["'A�3�-�RY�J��L>o�c�(av�)PV���J9��/�x���ZN��9r����&��ur6X/�xJrl粒��(_ң�%���l�/���+r>4W��[!��PJ
-�m��~LI1�0��&����S)�.�q�r�\a:�nȕ&��r�[r5����e�ޑi�{W��=�~:�Z�\>�i�%�C~(7 �Gr#B薛��r3�D���W�^�|*��}r�/_���|����||.wA�B�	�����<��oA�F^��V^��UpD^G�n𝜏�｜���?.�C� ��upRn����(7��r8#7���ۦ��YY��;�ݜ\
-[���B^��NY�}pI~`"K�W���\��Md��u�	�!���r/�%?��>pG�w�pO��!�@~���#�x,�O�W`��5czƚނq�a0�4&�F�D�;���=�B�i�d�8�����x�4	�������`�iL7͘���O�,�g�̙�<�[��l�v�h"�]2��BW����٦U<9Ǵ�5_��5}��i�j�m��AVk~u��֔m:�������B�6Xd�A\�����~wW�9l�?��~�_8�u���۪݉6�K1pb�,�LMp��Z�3�h�E�$3�T2�z��`Բ���M߱
-S-Z�JS
-�*�+Ԇj��Ɣb��՚���X����7]0��T3�E��4��5��u�0MM��&S�E&.7�_1eqM64WM�f�����ZM9泬�DVr͔����n�o����4Q��e�z�a* o�.��S>x�D6}�D6�i*0c,l*���.S1��T>2��ݦ2�|b� {L�`��
-|j��L5`��0ՙwL��7&_���0�`�	7r6��[��fZs���uO�<A#��`���3���Mm���8n�~0�����	�M����n"��L�����n�״��f��>�n�E��l�@�C���Q�#��R�������k#��܉�O7�7�{�f��4��0w�əf�w�?f9f�!��{������	��9�k6{���.��^��7�������s��Y>���͎A����!s�����uA��L����fZ��@�l�/��������r��՘�H��5�Sg~O���W�Q�̻��h��&�.7�G!_1��|��l1�4`bf��fv"B����2n�(�3�;��H��|ԝi�ڌ�|ҝY2/�8g�W���<A/���o�Ԛ'�Eh@A��\f�E�y�@%2G/�̟ ? 1�5/C~��1�B�(�/����c�G�z�T_͟���U$�Oؐ���_�%3[,��
-��U3-@��b�� ����"=7�s�4/�м4o���+�4���f�f�4o�;м5��܃fؼ͈y�� |g>��n>��n>��n>��n�¬f�L��Is�"�)3��?�c O�c�s��Κ�9s"8oN���g�yET��!]�'*�#RcO�'�.p�Ү7vQ�V/���Ũ��tț�p˜	n���s6�k��̹����{��Ď��<���.� �ʧ.r)���b�/�c�x�Yvl.O�e*F)c�
-0N�D��!�QX��W��WX��_*��5)Z����N���+߱f�^A�4�W�F�Ei��<�ڔf���s�rr;x��P��7��>sܪ�:*�
-��҆��V�!&��=Pp*���)B;�ح�@��֣����s֧7^�ˣ�6����'���`�CJ ɞT����6��R�����܅�D�Q���J'8��G��;�|�<�Ą�+���18�\D�_	O���Ë�A~R��"�<��s� �9e�*�2D�Ey���Ö�9����@��-�VG$�߱�)*�˲6�������+���Z�oy���Q#
-u���_��ſ��+�8�)�:�=�;�9�c�����L�,�ʤ�2��o�sJ/jZ,,��ba��#�^f��-3���ݵ Ţ��$ף���E����sR��-����"~��E=�p�������Kx���edՠe�2dY�U�5�Z�/\^���>��-�m�����{\�ϟy�y��!	�,��s�	��m�KK����āo,��[K8l	�E��hASbI�`:mI�<b:mI���t�r�%�E��r�L[R��E�%����s�pޒ	.X��ϖ��Q�[�����I�c���r^�̳|��5�e�ݷi�q��7���]�c)wA��Y� ��Y�!��K	�cPd'�R���R�1�2ȱ�����A�%X+ '��Z+!'�";o����삵r*��Z9Y��Q̰ց��z0�� f[�k�km/Y��y֫�ek�om���h��V�f���Z�Y$��j���`����s%=�U��i���m��fe� �X-7�֛��M�-ȷ@�uX; ߶��X�wA�ݳ�E���{�}�A<�ʝ���z�> [��'և`���k�F$�УX�c�hMFa[�_�ٜG![�O,��zx��rn���)�<|Uk?�h ���ƃV��Zd>�������,�0�r��U[T�0��J�y�/8_��P�I~���cBcC�}46�-�g�BQȶȌ�vx�	��c��/Gq��m�Sl� _ E�j{�"�q�mr:(��8�LPdY���ALNl�sATe�$�<�x���EV`��\�7��@.EVb��Y�mr9(�
-��J�<X��ڶ �����-�u���mK�@��lː�l+`3(�+�U�WALlk�[A��پ@���mr;���m�M�&�"��b`eۦZb`eہ|��ʶ�>���mr�m|h; �X�!?1��A�E�k;F=xj;�l�VLl1��-�ŁC�x�-|nK_ؒ���d��<�ږ��] ��R�a�EpĖ��ҭh�@4o��c �7[&� �7[�I�[6� ���3 &�\ȳ���l� σ"[��A��l�v�(�e[>�[�j+�lE�[1�n+7l�Vњ�����YO�F�aw�[�!�଴R�_Ed�/�^c�:�ɱ�Z1I��!�K�z0�� ^�7���&��N#�B{�UTr1`��+�.a�nG{�Q�Ќ�I�2$�n��x�p��~B�u��}+�{���Q��k��(�u��A���r�����G ��~�c�-�	(�{�^PdO�!��"�߁< �l�~�(�g�{���"{a���+�}*�*{���!����������|g����c�^p���`�'���}��W�џ�٠�o̬3,ٍCxޜ}ϛ�?�� ���9�Y���O��nxI�lE�l�	T1�kx޴��@�m��Bޱ���pپ}�(�C�;�G�Ȏ��܉}�v����1��$W"�4�8a���Qb�c
-I(E5r������8ش��rT�0�����ZW!�"��FV�0�ᡥ�9<��1��U�r�ڔX��Z�g��AX�6:LK�v.���&��f�
-¿�X����5���wա�9��V�
-o�;7y��:��:��ݱ��o8vp�M�.x˱v8��v��Gi�=���M��N�%a��+��|���=tA~X���c��q��h|�6T>���D�s�BQ�q����|�x�/@T>G�W���v��ao@{�H�<؈#�(���q�{��#�8���q�p���������#�4(�G:�O��f����㯊J� dپ8��l�zW�|
-�C�GD�.�y6tE���|�F �uG�pB�QEE��ATQG��U���\�s�^�}�;p�^�C�;r�^�c�;q��g��w�8� ǂ臝��AKpV@N,�Y	9D7쬂��vVCN�;�e`�n�I��2�5�g:�b���0f;kml9��l���\g=���l��U�F��P]v6�f���P8���B�Uh��-`���C�8[�/uқ�2g}l������k���yr5(�g;�ZPdu����ylp��`��6��^q��:�-�N��yls> �9���·`��x���t>o9������|
-�u����a4���A�m Q�r�AX�sr���Dw�|�[z�/�^�K����|�;߀�_�t�N�[}`�>A��*�������~���V4�N��E�3�q��Ƙ���9-���1�h�����~�7��[q�|�F+~8'8'�)ze�g��1�3�\���2�d�D��QY�񭛜�k�I�k�E��d<����8��0�yٺs�,��n:W���zYÏm��i���,�����~�97pa߹	����_�ƏC�6.9w ;w��~y?�]���:�U�Pź��s�c��]�P%�N '���0W��ϻ��W<x��`?�R]��EW��J�cH�:f�R�L�0˕
-f�.�9�40ו^re�y�L�+�we���Е�.�[�sp�ǔ�X��x���ހ��9V�؜cU�<Ġ�u���βZW�ITn
-B���e˷�7Hgaƍ.Z,jr��ͮR�����1�&\�`��ls�Ӯ'W�q�UM���.Z;`
-.V�6L�Ŋ�rG�r����u���h��m��r��͇�Z�s���n�4m�t��'�	�6�{]�i��k�sM��.ڻ7�}��.�'9䚃��E��h��m;{�����-��E;߸h��[m�v��䛁�"�9�h��{ms��f��a��zy��q�t���)�]��-��.�;�}_�\�7l�E���\�oj�Eۅ\�q䳋�O.�hc咋�#-�h?Ҋ��g�U��z1*��\�F��*�~ٖ���]�8�㢅�]-��h�u�E��.ZH=tѢꑋR�]��z���:Z� c��cATv�V��UZQNP?CN1�V� '���Ѵ���[�@|RA̿�J�i ��j,�d�"�Tqo(�luO�E��V��%Pdyj5�r��j�ZK�\��Z���O�� �XmK�&hJA���
-Ժru�v5�͸Z�VAS�^�\�Ҿ����ժ��_�Ү�z���5��#�Q��zz�\�����NTn�H�Ԧ�%]Sɒ�����v����fG�v[0@g�u���]�t��7�N�&���-���a�(]�����vj��p��v:G���=�{��^5vr�����ؿ%��]��#��*F��w��~d����˿�����c��������K��9�R{xh����*�:�}��r��}�
-����_����FT�j������u��;U�9�^���;�
-�,c\��	��A�ˁ	��AL�ȕ)u��tH�<h�m�C��5�O*��Ϊ��oN}Ϋ/�s&�ݑj����
-c	�ϲe�%<����U�5�����o�uu�����iK��1�F���6aN��m��o�F�u�4�vy��_O���U:Y �R�ٿn>T���G���L>�|��q_��9Z~��1�h�\G۞c5�/Ӷ�8���6�xM�/��I�&�nOM���P��K�&��������R5��2f�杦�E�$�E�O�?6�9g�5�y=ݭ�ڙ�]�Fy��-P��}�nG[�nG[�nG[&��V� �U2Hm�R�Bݎ�N�m�Aj�`��/D�9�Qs��#�-��q�>���9.��L������<�<�<�����֭Y�����oc�hW�8�=6VW�9��!�A�N��+Qy��As$�簝%9��2YW�w|�r������T]u��-1������B�����)��O�S�9�9g9�/��k�K�@�Ҩ�;��\����]�2"��e:�kY`���i9�5�߉�[C5f�hU.9h�G��ᲣC��|�\�X��o��"�bep	�K9��_��*Og%�WqVs���:��5��m�Q���;������F���i�����Sk���Z����u�]�};�*�<Ԯ��#��A��n��[k�����v���h�n�F[t�jס����~�8���[���>�n�ϵ;��.�R���:���}��� |�u���CpD{�j��;�1�^{�i=��~О�Z8���S� �Q��!pF{~Ҟ���pN{	�k�NyA{���\�ހK�[pYW�pU״w��=�����8��} ��	p[�w�)pW��i��6h��Cm<��|e)�m�G�F���1�\�u�܋`�{	Lp/���0���D��.�-�z;���S�_x�Y�|�MoD�����{�t7��p���L7�v�roR-��9��k��{����g����]��ǹ�y࠭��i�4^r!Ry�c���wG;�l�c�Bw,X����N���G��)s'B.w'A�p'���Į�}r�;�q_ kݩ`��"X�N�鸷ѝ6�3�ivg�W���Uw���[ݗ�6wx�}��������n:�qʈ�X�d��c��v9ϲ;���o}�6�A��b$Ά7>p�B�b�.s"�z݆r螸ˡ�q���P&�[�pV:{�*g����g5�'7��~�:.�s����m�N>�irr�m�_�|E�u�~azLl�l���;y�Ю;7t��܂#�;�r�mr��r�:���:�{���;ɅI�'���\�r�0�����#ra�����}B.��\m/�0ا��X�ȅ���w���Cx߱A�����0��hА{H��Y���Y�����u_����������W�W�������'�s�V�E[������0]�7#�ب[�����=�o����=���1�{�bLfw����]5�n�_�����IԘ)���ot��{��_l�?�?�Yݙӝy�1���<�̸P?�?���Epνλ��7mX��^���^u�cK�5<rٍy=[q����pͽ	~qo���m���]pӽn���m���>w�G�����O�w��,;tǸИ�c�cwx��=	`�'��$�q�d0�sL�����#�\���S\4N����y�3�3�3���"�E�Y.�;�.��=�.��xr\��\��%<�'L�\/z�]�kpR���)���"\���Y�0�S
-�x��\O9x�S�y*�˞*0�Sxj�BO-X��=�`��,�4��&���Vy��՞�`������6��sl�\w���0���'(�^Vy�9o����T�[=Ԝ�y�!����R�c<?��&t�nx~���w\�(�����[��.}jq�ux��mM��xh:|�s�uz2���Nfwz:]��A�{�4��}��a�.�~�y��-�~���ݞ.}��N�=���'�l�xh����OO=t��CG��=t\j�CS�A�C�Ɛ�&��<4�|�I�m�y�y��{�醟מ�������n��s�w��a��<u���E<� Z�	������Oy���F��Y~q�3���AZ�Er��eAz�7��G�ϯ>w������y�9�ꡃ�k�y:B�C��I�:���L�♾�yyZ0;�`v=t{�C���=t��C��=tP��C��=t���C���ːc�t�:ֻ
-9�K���_ 'x�Hu������$/��L���O�B?�}�e*�/��/�bK�RA]�RA�y�"Sӽ�d(�0�;�r)�0/{Gٲ��߻�N�1�'s�~ s�N��x']�3�
-4�*�N�&]ʆ`*5|{��U���]����J}ҝYo9��|/��.��.p�����E���"��RqTy)���K��X���9�Z�24u��޻��z&��Kg"�k<T:��#��^:y�K'��z�P��N�z�P��Ԯy�$�u���S��^Z\��]G]����A+m�������t�Y��4������^Zo����N/����n���?��^��wyi���KC�G�m=�<�ۻ���wWϫ=��x�����~<Bk`�^Z�{�=p}=?�������o�?�%��!�!/��=��j�s/����j�K/բW^Z�{�5�7^~���5{�^�x�ʞ���y�]_w$��Ҏ�1�ɷ�e�K��o������NqOzip�K3�^Z���Rǌ7F剢v蓗ڡYo������7N�z|v�KЂ�V?{i�p��ؒ7A=ǖ�_��؊�ծziMq�Kk�_����(ֽԶmx�Գlӛnyσ�^Zx��Ғ㮗������9ҁ7EŸ���7�c/�d'^ڐ�����>j��|�?ޗ
-&�.��>j�|�:&��E<�K�>ŗ^�e���L�9�|Y��/I��h)5×���>:ϖ�sq�>:��sq�>:w�G���|t.������o�����rT��[�����\�x��T7/s�d�*u����R_�Jk"Ő�|Ū��}%Ȭ
-_)�R�+�|�`����U���*��W���:E�V�`jUVǟX�RY5p��J�5�7s��6�/��X��FD;�x�_¼�k[|m`����^��}7�v�M�Ǿ�n�xw���������PE� ݎ�ݦ�8�,U�6ʽ��݁�����#�7>�==����݇�)�zډ 
-3>WO�$�|d��>��9�¼�la�G�2��o,�"�%_��,[�QMZ�Ѧ�UC]��i�/>:����G��������F0��Ǵ�7���|�'Ȉc_x��E�,�/=U�ug?8��A8���D��g��,�ϞCJF��g1�2/ԋ��~�rs��/��E���-�0��(/�w\~�9�9���W�	.O�ԬLqӧ��4�GT�t��?���@�韁&��I���e�)�s��\3?��9����h���\�F~���)�/A.�/�E��ؿ
-����R��̿��7�
-�&Ux�Ux�6Ux�Ux�.Ux�Ux�>X�? ��`��l������?ZC5�ǀ-�X��������?��O;���m�yMTRB�vϯ]�h�h*�����}���v���<�S�y�π�۟	>�g�O�ٚ���"���@~
-��ϟ�ـ��APdC�?��h~Cn~����#*��@�K���8�qu�_��K��d�����{�_���WpVj�M�*���Z�f�1j�Ì�L.�Y�Fנ�଑�i˚4�44s�D������?f�-�뜿U���y?}Ea�ߦaB�.���K�vp�\��W���5���Z��7�w�M?�$��Ӌ�m?�*��ӫ�]?�$��߃�}'x࿯=Д���w�>�h��"x1Ѝ������0#�fzqkV�)��s�`n` ��T���kJ���g�9Vx�[K/���K�,�
-,�+o4�Zh`��R���ذ6�)%�Gy~�C���������2����`�ژ��c0`H�0�6��t��A3Pi&���ߝ�x��Qw����4��A`F���sf��s�3��,h����=,r�K�����+�½�"؇�U�(��b��A��Jw`W64���&4O����tOۼB��Bo`�v�{P������jv �@�P��#2��@��G��g�h��ݤ�qc�q��e �$ƹy��;	�_`|��2����$��&��;��������w�h6��<
-)�4H��w�n����c���x �H'�d �
-d���t �	䂟���@8�����@�9P.���@1�(W��j�\��_T�f@�D4�6[�ç@5.nj�n����J-���QRX=gg#gg3���� ի� \u�F��/���Ѧ;?��5=g��i�}���7t�Md�I��Pt�W�)1A�)��7m�xK�w�oi�N��k�IR�I��q������8��H	��Wq�BpWS������s1�	?i��z�b�J�B�|�����A���Z[Ѕ��	>�� Un0�K�Gnj���]v�V�� U���cda�	X��P��P��P��P��P��P�+��`U�)X�k��`mp�}AP�1�
-
-�(����J&OA���3��*�@L�_⾖�+�5�l���_v��o��Fp�	��V���[	�G����^pr'(���w���(�C~��A�a��q�O@�{��^&���¶���@L��S��P�#�,8>΀/�����Y7*��0���^z��;����6e�W�7��W9���5��5�м�C�>��>�<�i�8ܤ�i���Cp�&��n���h&�;�LwɓM܃�cp���^���	@�)x��;�f6x�\����C3<�f!����=0�`����q�J0\&�k�D�K0	\&����f0�
-^ ����N�"�L����~0<f���,�(�s��`.�Ƅ����e0.�Ƈ
-��P!�*�B�`r�<*SBeQi���~ʖ{h��h+ WzX�%�
-��ո'#Tf�j��P]�f�=��_i��bnԝ&b�=|��yU��B�cf��j�`�jCX�C����u� ��n�E��`Y�X� +B�����*t��kB�`m�>Xz և����C�1�l
-u{~ΚC����O�^���n/�V�O���{n?��pJ{h�o����B���P� *��r'���P�y��G<���둩��^4>�Btd�3D�����Cɴ��q���=
-��C�(�[a���F=t������44���Q��^6$���dܣ�s|^����'�uH����I�Eh
-|��
-M{0>���3�fH�k�?�NTH���1�R���t�C�-p�3��"���c�&�ӡem��+x�lh����/�.[
-�u$����"l�G~�s�l(�C6�%
-���ɆB����B�����B�v�ǟ�Q���G�c��`l��G{,>&�c��p�����	��p"�N��t/a��E%�A��{�R��CN��Τ��St'ᳩ�x����{Y���G�^��e�Q���^n 9���C��\]u	��p���2~����Q.K�Eޯ�K��xzY�,���2�2\V�+��p%X�k��`]��ׂ�:�1��&T�z���>�P� __D���5,�a<J��H���&ʑ���v]�.���m��o��z��A��)�7xro�)����0��v�Rs���.O�=��N����V�A�͋Z�(��&7C�¶k��kv�?�~z�7��0MP��i���	J�&(a���i�2�	ʳ0MP�����<G�ex>s�v�z���<�����^�3�<����Y0�ph$Ls��0͕߅i5�}�V#�´1�ՈaZh��B�d���L��Y��ɬ�0�n̈́i��S��*fôV1����0�8�4������0}Bm)L�ZӇ�V������?���6��R�}���=�NJ��v��~ n�����C/���#_È¬��7vfYh���V"�qCB�01"�aK�`y6Q��-�/�x����S�������3�;���!�y�;�u��ԝW^ڟ��K���xi}[|K�]��[����bmFJ����t�;#��vgF���:ڝAG�s"�hwn�AG��"h��ڑ�A�"hGba�.��������$�6��FЦ����^A��+"hS{emj��&{�!{�%{�hB�^��>��[D34��Ț"�{E�;��"X.r����E�c�m�{�Wa>�/Q,�_'�0�{��66��1����>��3�����9l�xiC�'/��fuӜӝy�YНϺ��;Kp"l�e8�f[����Z#3�X�e܌����:Ys�:T�j��:b�;[d��d�;d��d�{d��`W��0�|qvG��#N�'�>�vD�>���"����p "�H�"��g�}������`S��� ��DXR||vę�y�3���y���H����HD��,�Ȃ�."�'*S0����X���}�r�a6�oDSfl�CT�\�0\��[��ǽ�tv�K+$w'B,µ͈bp+�܎(���|Gb9~�G��DvQ��#*��H�
-W�#�p%&�r,(����GY��*R��}mv�#��=��&�,5�T���b�_K1��ᯍ~����?�|�:��b���h�'-�����2l)Rh��w5#WW,'�]��
-�dW�3k�"Y�/ݫ|A��_e�E�߼?n���"���mHOU�5�:�:X��F� �"o��������1�6�yǧ*�i�룯������0�O�x�9��������<�k�܀�F���w�Vd6}�$2���G�@��O���|De���Q�Ѝ�}�G=�&B���y�>���E����<՝>��*9@U4r��h�U��gTE#�S�|AU4�%�<��"�5�2��*�-���A�D���^<�>�0�|��^��Θ��~`�#�_G�x��������<��r��}�������)��EJ<�I��UtW��c2r��gʡ�MGt�����?6��H6�u9�͠:D�l'�}�,�A5�f�������0�;�<;�p|��,�Y��;˺rE���;k���k]w6tg�g��r�ۼHv��������b���b���Pl�-����E�Q��섨01�L�:���M���c�)Q'���h��R�b��Q�`ZT��+?ң��DI@geH��Av��,ˎJ�:}M�ἮN�:/�<�"	]M�!��k �Q��$��$JM��_��/	�E�;V��>����XyT.Ҧ���"*�����r��\�&*ѫ�� �2���,�!*l���_�+)��EE����%�<�˜�����E�Ŝ%��z|��4��_�z�(^�� [����:�ڢz��U�(^�� ۣ*�QU�ͨj�o(����_���_���c�E{��F�^�{Qu~���~� ���*j�%��Q~�CՈ�<�j�����QW�GQ���;�*��8�|E{{z�Z!�F��E%MdϣXz�t���r\��=S�u�]wn��@�[~*�.��3�N3����0�F�F�ᨻ�G�Q�໨�xV��&�h�md�Q���cT���o��f��]<�~>Wz��K�޹(��Gu#�\�-F��~��D��!�D��Ek��֣X/|\�+J�7
-�8t��]����"���;d��!�G��nԏ�jx����l���n`/���~T>��@dGQ�K�+����D�8���D��}fs�2(���3�q���G�|0�Nw��ݐ�oH>��v�Xd���x��u/t�� s>3I�|f����G��3�`�:a�yfr֙O`��Y0����|�0ϣL��l�[�ȊϜ��p�|�4�E^��K˺���Vy.�q~񓙯snpn��������<�Nq��v��Cf����=�
-j�ZA-;s�H���t����!��3G`ՙc���	Xs&:����b֝����3���p�V7ϐi���z�Y����?e�b���6���E������>��	�؀lP\b\@U�Ȓ��	�'1 ˊUL
-�&8��L�~q>�/K	0��]0���4�_Hp�Ҁp1��� �������0��Xf�9�#+�\^�`j��a�\#+1�&#�fd��l�/��ksA�W�`��X^�I?c���3�`2Ͷ��n�4��Q`�KL��)B<KMC&6g2��3V�{���	)�f��-���<�i@��Y�P���B�����u�X߻�
-\��#VRn��Y�zc]��j�o�+� ^�d6�"�����e�ڷG~��~��@�1(r�fMHS�Ҍ��P�$�j@3&�n����L)��|AihJ*�\T��5t�ҕk՞�,��#SYSUg�����leCU��z@�r�-Uu_R�UՓ�쨪������|eOU�ʾ�
-�U)��*V�T5\��jD�r���eJ��F�+1�z�B��ԟT*q�z�JI��s�J�"��iT�]�4�n _�)7��N�*�}��Q]��'�p���T9ͬ�ܡ������>~�.j���!�։Ч�E��*���C��<��(�Fո�tTyCyPM�ʣ ��mw@5o)��O���8@���ҋ7��x/��JTPj����p�{J@���� 3�� 
-�@B���3��<G��ʋ���(/�%��*�Zc,��-��gyP���L��TW�e4��I�w(�dK�[u������X@�^�{T_�eF��!��/Z&j �2P��L˱����Y�O�Hմ�'L�9��|��	ӛOh0�f�"H5>�E�z���G���d��3r��"\`����z\��Y7[��?f+�YeYskR5�6�X�ݚ\�Mu��f��J�e˭YA��ɲ��l͠�~Ų��WA���r��\��[m��5��v_���5O;��ް�T�M�2��2�Ò�Q��-Y5t��i9�)�g��m �!��jq���r�lQN��6�T�Oxbw����K�Z|�]����]��� �~˨�-�rH7-
-���X�-l���1�����;�&�+FeNLP�����A���_����1>(���	A��}HL���a1)([�������H�|P�}%�e��g�A���O�Ԡ����A�%���� S�,=��e���[*�f���f��Z� ����f��f�r�5'���@��ښT�k��]���� R��T�/a&u�0�j�
-�AJi��=��~����}O!n�ST�kqP��%A�8d-��3kYP5=��U��QU^Z����uۨZ_[w���uר��Z���cغoT�#����U���Ȩj��F�=f=1��qk��z?Xcd�7a�h5~�P�0m�2�OْQ�f��h&>Y筧��ʷWQ�'|B5%x�'�P��}�:��H��!$�u�L��d�/�� ��)Ȼ�f����i�d&��*d���*�|ۺgZx�~��ɷ�R%��"���Q���XK��m�/}�x�2�$�#�Y��x�������BD�Kw��?c����3v'���2��T�Yq�3�lp�#vlPD��.ў�!�h��Et`�F��jٞU˱�'�ZOl�A�mT�1���ꈵ�Ug�} ����AUM�U-��,����σ�'��"�z��_U_��UP�_����T����hTCi�L�i��կ�p�1ݨ�%�ĵ�>�����!�����k�=ۨ�+�ݒ�T�SQ���c�k�}q��@\���k�}qm�O!�����k���]�F����~ڸ�PQ`����Y*�j�0�j��<�W���_��/ܰ�;���y���ي�mЩ���j��XB�H@�c	Hr�"Ɏ5d�y�dv���c\�x<�L���C�q�\�s�BǷ&���H�6ŷ�/�8X�㴽��U�Yq]6qiA��GR\������X�`���o�&���!=3�#zfSǔ)��	e�C�B�t����PcBeIbl��(ƅ�hc�!&�XB�m,1��Ka�j�χd���)!��؅�xYjH�C���H��GzH�W!մ��1��e����*�쁓=s�F���t̜��#�9x����"v)�����'���5�f|���u�f���WSFA��s˫Z�;���m̹�U���=��������	�WuM:��:����G���v�:O�1�����
-B�%�����IX��(D�-��NSS�M��r�Z1��� >���J3��J��r*̵*���Y��ai�/T�dE���C�EZ�5!�*���ڐl���B]H�K�~�>$;�M��BW��n���iC�H���M��}��L�ƌ�K����t5����[�z��[*���G��頎�ǫ�̫Z�91�G=ͭVʅiA��vW���y[@w!���=i�������M���g�*M;}��3D�2�6
-Vi�Fc��i����[�i��SM4���r�I��Bc)n��܄�H)�=-5 t����m�|F@�CY;�	wQ��$�#��N��_�H���P��,�r�{n����ܧ��<��e]x�b��<��x���a"ӣ
-�c<
-�O����A���؋}�S����=��=E�-�/D��Q�i�ǿ���<����@}��|���oWq�gl���e����}˼�-he�,>C|]?�#%�m	�Ccbd�B��c�a���b�i��{�#s�۵{��W�m�f�Tq}#hu���̪�o�N��Z����!���7R�n�xH�<�u�U�߇�j��M�T{�o2�:���B����1���}�!U�͠m�}��{覮ka��{��5� �d�J8Աu��tH�)
-�i���i�>InT���m�B���g�a&f`�!`� �RlC��9@ 	�����WW6��z�Z���^�:����3��9���a[ף%���]��x���/�tջ�(�tKw=Y��e��*!�t	.OZ�f+�q�p��u�U�C���|����ŮW�J�ݤ�n�<�;P�kR�aMr>��X�_�E��n�%�����iR���iI>��gPY#�]���HW�ip����D��L�6l#���/�wN�e�Mu���e��䟐���mW�쨩�{��n�AV��6����v��t�[V��k�j�Xء~��:����{`������F�=����~�c����Y������F�=�u�1~O�0�X���p�8���H���~����kE���0��e�0vv���臤]>�,&��Y=&����}�/��+|,�_�I�ZD'A^��&C!^�}d�~��?vѫV��K��!PA�k.�V�T���$$�l�3%��iB��� b�4��i]��N��D���K$ ;K��%Y��������u�s~/�Sr�D���AIV�����c��6��l?ȳ#>��yv����a�:�cs�0K�pv�B�Gm:ߏ+�P5�JB�|R���Ӓ�}?+�V"��g����G�Gt�(c�� 5�?�/�����
-���/m�Ki�H�-�%���_�ꗪ�,�Ő�xQo��%��`�N�Fh��BK��|-T�_���
-�r(X����r��xd�J(�����+������j?,�n�/�ay������W�RA�U��	����jg��.��ױS�t�7��9�r-�r�����/��Wj�v���=��n-�ۭ�
-ޣ��R���A���ނ
-ޯ��t@;�I�-�S�tN�>ҤO5�M���6 �0k��l�,����b�[f�M��#��fl�-^�.���b62�%:��Nd5�-Hp�̶"��2ۆ��l;�
-�,����N,f:���4��vbS,����pH�����Y�6�eV赀�6 m(-~\�&�qx�ہ���;������b��~����Y�*f{��5kf�@M�B��^�����`����Ս�2�*��
-�dgD�����X��v�r<��KH����N��a���g��'g.k?f� �������qO�0���#P3gG���Np>p:��� E?
-\�[�� �����ie�����8T~G@���p?�#��G��G8*��8��/�ՂЗ�E����P��_u����UO(��W����e�Z��_�E�{�U��%t/��W������j���Wk�/�U�jq�>^��%������}��T-�^����7�PM���u��=�->LSKC��z����#�m>RS��FS�B��4�����hM-}����P�A>VS{��|�������+����_��5�"����~)ԏ�k�C=�$M��!���}B�)�zg�G|����1���w�"|����	�����~ʟ�ԯ�~�gj�WC��gi�}���ٚ���/x��~=����������o���4��Я�|M�V��|��>�_����3_�������~R��~�q��~�q��>�TS��T�4�!��4�/T�rM����~ �4���J�6�� �^����[��?��55z����?	E�˚��P����?�����O�*����<�[����"�8CS	%��������M}4��k5�W���4�ס��4�7���5��C�|��V��mM�z��������55�ߤ����fM��:�w5�
-��ES�ܪ��C1�ij��]S�Lij��k�@�5�� �����4�	��͚�$ �h��_�j��_���?A�ީ�O��5��Яwi��ЯA����M �z���~�OS�
-�z���������AM��ׇ4�?�_�ԿA�>����������1M�o���5��A�>��AU����?���Y�)~ZS��П�M�e����:�����jj��4u��5u8����#X���G�:������ϰ���:����_���,�7~ISǰ��O4u,�����X��g�:������Xh�W4u"�0~US�e���_��z����j ;/��!O�յ��`V�<ky��°: ��mPG 7��� ��%l����̪L-\���of'����([���m[ph��n�AG]���a�w�Hy���Ȁj�u�3U�UȨ�����@+�2�]A�X�gҸ ���6�& 2�&.�����z ���JG��� ��i&?�LP:oz�`c�`c�`�c����bN��9R®�3����0�x	��5v����;]�f+�%0���s��́�8dun ��.u^ ��C������vg���6���Dݥ��fha ��EX[V���r4??�1 �L]%��}	�xj��P�iݗAUO�>XV��H�����Y8r!�/e�Qz����~�^G�5k'�iv�"�1��"9�;��Ɍ=�H�Ƽ�������",fl(���36���0V�H�6��"y�A�g���Q�
-ml��HE+ll�]V��4p�������9{���y,�H�3���<E*ٚ�.�)�4�-�+Lfg��x��^78�ξ�H����K�ٙ]�n�ig�ۣ��:)�޵�ΊTv��<�t�Y;�P���vV����`�6�;�w����z����ŵ�n�[	�6:�*p����}Y�zow�����)ҝ�E�������P�ݗL�{&8�4��f��+���ܯ68ٗ�ם�0���Ɏ���Nv�olr��~s��=�H��v�bE��y'�G���d�����i.�G���-��w��
-p����nS��/w�!��J[nx���R���b]��[�?8�b��w�ž�H?<�bP��?q�����.��_s���F����I]>k���YT�~6���t)�?M/`�������_,/`K�}����_�T�~�H�,`w(ү��-��3l+��������sM'V�H��tb{ �l'���&tb���wb��M����щ�pUC'v����Ď����Nl"4Gby'v¿{�;n��N��"���N�2?�3��"�뛝ي|Ezb[g�W�'�άB��p�3��<љ}S��t�3���f�ٷ��ݬ�@��^�f㠻��e7�����tp.����u��-��V{��������X�a+��Ϸ=�ep����^���z�Zp�~���(�Ox�1�_�>�0�^�
-)5l�����l��v<C������"eO(R{R����^6��p�����v�+O�3�O�4�/d� 4�M(d*�h���}c�k��{�4��/d�(�8���͂�4�-b�W�	lq������t+ҳlG[�z���m�$v��m�dv����)�t�
-��l|�<�س]�N�¦�i]��3��5<ϱ�]���d����0�g�U]�<��f�ue���������3����^�\v�+{<���]���g����������vEZ�6@p!����6�}�m��F����l{76��R�^7�EZ���Ʀ@��`76ӫ��ҍ��~_Z��W'�؛������6�d�}�</�E>��Ul����g5[�c���[�c{��2[�c{��
-{�����U����H�^c�`)B�uv��������X��d��ٖB��a+�YD�ֲW��?)�:�^1��"��F�������-Q)�;l�n`s��m���F3�0�lbV��̶��_+һ����J���%�$le�J�a�lc�K�oi;�9�D�ؙv<:�P�>O�])a���aWK�U��e�3~�ߊ�[��uQ�f6~[�8Ⱦ����~w��~�<��J��i;�gU���]���*�������슟��}���փg?����6~�%�#�{Ac� �0Ki�>�e�����p����.� ����&@�	vLc�*�$;��z�9��5�fjl*xΰO46<�k�	���6���`��s��	�W��� k���س�<�N���`��st�x.���wE���`�BħlM�m�~�[`o[�َ �e��v@(�Uv ���s�	����N`$��/�!��?	��ੑ���3XdSk�<1�j����'�0����pH���H�&�d�3\�d��3B��+�3R����o��|8��@���O�h�#����4V>d�3N�(���x�b�m��r�m�DyHw6����wg��S/O�.� �'�� `���;��S�L�zgI������Sy$��Q)9���D���^-}�%ga\���6��G�d�y$�(�)�&ʥ���\�+������Ll�D%� �n3��4!і\�qw�dn&�<�����f�NH�K6c�oĻ1�����=yD��L���y��H>q5�$[�L�瀮3y#�1yr�
-$���=D���f�Ԇl�" ���Bܜl�,��!� 9X�ȅٜg�gCr��PL^�M^�M^ɝ��1yE6��l�3!ٝ,����1��T�ob2Wl�T������.���Hb3����R}��U��%9�׿�w�,�����+���?�W�59�׿�Z_������89�׿�<u���|cxr���_(6��8�|�'�*kYty�b��_-�c|�'�Q5"j��x�)����T�_�j����AG����{�HR���ʮ���!���>��b#}�n������ԫ�W�/>�����F�v(�e�/ݹ�� �,s��k�Ot��Wsba�=[Xl��Xq[��8��J�)�֚ ʤNaIB��mMg�]#�(�+�eRbU ���� �����vIBO䥀9lc*s�F�P��H�er*z�Ő���Tt�+�Z�\������^�߹��/��<���A��9J���J �eSr���d��
-%G�ʆ�hQ��@*�-Ґ'��k~#'�:�ߤ0�~[�0����j�ě~-�X�r�k!���i�I�D=�/�R�wl�2�<�.`K���r��i9y
-{�v�NWTKb���q��*���\%�^[�T�c�<rQ�S�wF�L��w'���[�/!z��5B	�;:!��A�XH� �{L$;!��L5 ���^4��Ć ��(�|�����w�~@< �qA���)�� b��؆@tc ���@+��֎�Fg�[��
-tw�/�tc�ٝ7 �9`�}�'�9��]7 �n���8�ws��!�G��w�0��\�/����?�{��)�b�?��kެ{`D�ʤ�N9�WoH^�`XF�����v�^'��[]�Vѷ| �/��wa���~S���H{L$��ܝPҀ�i&9��ҾL�w� �r ��@��\Z�@�}� 721��� ׃�9��P�d�+̂�m�dw���cS�S�5�2F^S�k�,@��F{7y��7½Y�SX.)�x���0LJUA�_���݀��9�M'��$�t�3B��r7D�"�@�"�m�s�K#X!����i�ʚV�+~��<I*�,F���Qj���@�jj��9��"o(ع�}.��D��E���?x�'>��!"�"�s���SDP�+��	��;�8��rߜ�;��x���NS�z��J��6y)O悔R�3]z��b@&E=6;�z��X2�0��rF�aAgo�Ɏ��9��<��F����d3;�Ѿ�A��o�鱜LgQ�Z��e��n��G7��xN��(ӏ��~���x�`��?�kۍ��9#��P'��.	M\/DѦ'�T�u�섬��h��M�� �4��u0��`�_�.�u9�_��?��B����C6�Cf�� ��7����ټ�.��r����C%�A��r&�a�a>#97����li��F[��d�/`��SACPMt�:�%}���|&gX5t�YX��9��|�B�kW��9�ϡB]��B��
-u���@��:�S�97*Ԇ�B]��h9���\���OZ����&+zl��Sd��6ڲ��dX-g�4��,�Y��8� �� ���p  覘G-��hȗֶBU�f��1��aT;hT����T�jN%F�lی�iϗA�E�T��l��Kjk[a@dh8�H��X��P�gE��s���۫冰��3ج�q ~پ���K2���t���0��k9�ۦ�zf��S,�p*�@�O�>��a.�z�Bc/-�*Y��-o��]ly�Xޥ�w���@�3�i��V+]EvFʲ����큖���*��*,e�@���S��z�%� pCT>�
-?� P&��5Ir�3�L�E��;��
-.�豫�:�I'�t���9?cU�5�y�kw� �ɩ�dZ*psN��
-+�~T�S:�/c�E����1rVaą�9�W3�{րr++��u�w����V?EE�o	���nOS�zB�0"k��Cu�rc��+� �h�4�x]�mm�� ��TͪlD��;��%8����� ���中r�ӄOv���i	0T��63c��I�K�f��:g��`�/�P��LD�ii0�h�l���<���`N���q�ِkOL�`����ӻm"b v}�� <;Z�h(� )�7�ꆟ`g��#,>Aa�p�s � ����� n*Y{c�އ�9���4�8L�8� 3,���\�I�i�F�Y9 �`�pr . ����� `�އ�yVx,6�|�@r,V�U�q��Zhy֣���G�o�)�7��惨n��Z�}u�{�kk���ǝ ������Iv���$[Bd�؄C��z��,Q�Z�����E4�����<ؑ�y�U�g�H�$|���=���㥉���Xr�h [Ls�6�%��\Z] ���V\��y�JL��@��, L���)<�30ЫH�{ԃ���]S=VLJ�ju�)��[�<�W�N���I��y�H�k.[���ԋ�_dh(e��2(��tTk"�i�i�����4��ʑ+�������k
-����T�wb�L�3�l*��.�ƻ,�1��o���Wz�,��$�qO9���)ƫh�AH?������\"��/<�`5�sX��2�;]�R=Ue+��V�z���e�R������s��.ģ$�Z/��
-i��WU����<{ ��_������l�tk�T����MW�(O�!?q�۸M�cؕ��h2W�����Z��ty�f�V!ga!�r�,���@�h���UJ��*jd��r~^�:��[v�r��Ğ ������.u%7��� ��K4�4`Ϋ���bΫ��|����|DxYFM���j�W,�E��j�"Dy�X� �� ,F�7H��Oݭ;kbo ��RE����@b��RK�!i��%���#(�}S6�Pi0�����b�Q}5�(�t��G0� ,�q0�}K�
-�xr�Ff�&�1z���ā@u@� ��V�V �:Yv8]-�}��;1xUPN&�lS>�۔um4�mԘ��В.ђ��A��v|�1Qo+-��1Uy����=����6�>�OZ>���WۑW��]�<�+mmv�=i��6��޲ʻ˻>�)WbSn� V!��9 ���%ؘ�l� ^A��$ž/�z�}4��}ϙXQLK�P�Bwh�kq��}��x���x�A��1�^^\���] �W���3��8�1�����c&���ʍ�6"�����{+�[�>��y��P��>��zilN���Jl��#3�nilvt�7��6��$�=��� @�X� :�L�:Fz���ђbk�F����#Z&��z����64��}ۤ�6�ݖC��Bۈh�9t7"��fؙ�޷ � ���-��؆ {r �!�^ � �����^��>`�<����QwMqs�m�E"�$X$�7#qI��$��>% �;9��:�աMH����>��݉�8�}W�.DяX�,�]�~�л�{:�0��� f�C}��?f��c�؃$��#�/��>�D�8a��g�؇$NZո>E��΂�0v�̝�TN:mQx)��(�oQx�=����H�Ea�Eaw
-�
-�rl�pޢ�ע���L�-
-���GD�"|������[D"�у7#�F�;m�!z���'0'过��@�TF�ɶ�b&�
-�ĳaܾ�T��i[�0'�ļ|Hv�d#����K�G��Od�w��k�8���$^�r��cu�Ƽґ��9 �[s�"��J9:�W��s��e9<�ƒ+e��}G*�m �J�p�  �������1���D�6�C��"���8�Ú|(�O��An��8	�n	j�	4p��\�S�pp\���xp����#��R���6s,�[�f�P𓫔I5�2� 3ĳ�8o�<���QÙ�G��$d ��`pN�1�!��[+���K��c^+���Z@���qp�^ZHۗ�O���^��`u�X��\ �t.�:ʺ�����b�QlI��.�v��9l~�l�� �"�����W �~[�P���7U��ޡ��2��2YO��*�g��
-w�NS����9��n�� ��)*�+�'z
-�X��-F���|��Qp���)¢>k�Td���5�n��59�珳A㩺�a�ĐNC�T�E.L���XKE�ڠۧ��z�=�-�L��?��:�N�
-���E��(U����9�#-`g�h|�j�a���J���k�Rr��Q�c5@l���1�M�x-V7�f0�p�a�?]��>`�*��ϚUK*�d�ɑHsJN��D�S-�Q0��ƅ �º�(��N0=f�"�+�( �F+t�n�@_:m��C�>G�]7�l��#�2��}<�>+}<�϶ &"@7V�:F�fB_�YP&*��NV�f;T��9>�+��GqKiu����%�<(�S�(���
-dv�R/�� ��<M��2���V�rb%#��"��@��v�B�B���2AWl���b��zWb"��(�*{��#�R���!�\`9]SH�;҉N�� �#��u	t׏��k�UgӰ���T�4���T	�Dc��$ӥ�iA�%M��<���ȍ��i=(�IN���M~����~�T��K�D�*2A���p����]k��.��.s��|�]�}��-�m��Y�}f��]�c1�G��������64���qiYݣ%�&�4A�2��s ���x[%�*�g�2���l�؍4���ď�#�\���g��y���AX��y߉1��Sp~^�4�����̢�r�^�/�hgz�L�2[��ũȩNP�k�E�Ĩ5�N`�4���j���@D�	���5��`�_&�(Y&6�R��r�7�	Sx���y6�h�݈�Њ(O.��tx$��a�
-*d:m^�&��hK3��{���&��5���b��r"P�`�C��dVGɑZ��.�������,�'P��@
-�V�8��a��ĆQ5��	�у�털A�<`�k��M0I�p1S0"v(��� &P�`��Z=V�N���Mc�0�"3:g7�G�3�}"��ѣ�&s+�wS���QPI��X��*5#��c.�dϨ����G�j¹��)=����eln���£M$��z8�M�d��t
-�W�,���<vU�6�|�Ï���g��o��� R�z�@�҂yYDDv'g�088����J#g#��&���ȧL�S��u4K���C�[���\q��14�l��8+��xR~��O2 K�=0�gO0D��1 �xrZ��,U$���_�x?���"�{��<��FC�V2�z�U^Tl��� ��`�	�q�	� /��>	D�qE>���?�_Ė04=�?H��t9 �ҋ���5�*n�Q�Ȏ'd'!B�0v@[M�L�V�^����yH���@��*���?˨)^"�g����8T_��"P{'��JA�D{�"�}��+��#�\�i�z5PSc���kc��=�Øj��h��S�f����ܶ �	��
-��U�q=�V�t4Ek�iWj�#��,/"��qn��*�渑��T)n�hd\�|�R�h�:��K��mmvŎ9�Ε�k�ON�Tܫ,����VS��R'\@,�鵦>��^�w%ܾ4�h��8 az�R��%x
-�ǝQV^���K��X�妽h�uŴ-
-���"%n�)���w�m�UHU��-������$ ��V�.�lw ��+.��q����q'D�ˋ���.=��:����E7(�͋CGe#�)�7�\v�s�k��ﵵA�O�9nK���pfp0�Ȫ���^�p=���.ZR�]�&Q�A��7� vEj�hop��tݍ��U)i<����j�Tr��T�6��J���m\�*+or��r/v��RH���d:�I��Lz�A�N��}��8����|�\@Q�0���L��q�Fٗy�.ȟTg(�'mDHu/Q$����ך���TiXa���Cs䯇|�d�=�ݘ�z}4�~���0O䗖Q�P\�tp8����4��#�ƀ/��`��kG0��(;��G�,���o�\��H��?a��j�%���-������l�ͱ�� 8�Ň�Q#�A���)ip��(p����mA�0�x{�I��D�;���Z��7�����>������	�����������L�e[s�l��l���&�	BW�NxC�$S��� P��Y(�q .������bZ'o���d�*���1(N���ݎr'���*��8�m]��eQ���|����yX��GF%ns�F%?!��Ҩ�����A|�tLP�silPr��qA���%�"MJP��A��K��N�T�:3iWN�c��T���[b�W�@��8P���h�&a.���p�s��E�sӌqn
-sJ�X��|p5:��c�G�|�ʤԅ�t�5-�_���L4�0� ����Eܸ*ԜT<Ϛ��H�QM5�H{�H��Y���"f缸�%�%��;D��ʷ"h�	%�C���~��ց���Q�Q/28���y�Q���$��M��7�7��R���z��A��NN�[��C�� ��㏡W?\�����V�J#���^���aW	'7�>�Y�p*n�v��.zꪻ�ݶ.�юvѠ���Q��n�U\,	O
-�ZA
-�}i�PoMX{�n��{؆��+�F�i�-n�t�^[[
-tBO-�J�Q���=��}*U��O�J�����ƁW��sE��]��0�
-��h��U��5�!�4�8���U>
-��	�;C��0�<���*/F`�wA�� �a|��Ň!��g觠[鈖��AE��Z���~��ِ� ��B�G܃�����CV��4�A��r-��T��UVI��P�x�x�r���J�i�Ub/�H���ARN�FN*���:�l���PÎL�eX�"�Âte�#�-�A��~�֝{�ܾ����+W�vqW�w��qw��.� M�^���V�YV�g�"��I�(��f�:��;��tɔ7Z9���.U�eR��ʹ%�W�X�1��.����Fxe�����^�Щ�b/�/okS�z���j�O����ֶ�q/2��#�L����@5��;��:txo���*�z8�b��x3�S� 2�]K��u͐L�HZ�^n���z:�@���2RGs)��!�5�����ȸ�h�ɋ����ms�����'	��T*��Xܸa�7���]�Sv��ne���h�-2:Em"̟�K'�� YL�5z�*����&�#���V�0�0O����f.;��u4�6�fR��G����Zu�U8��rP�Y¥'xm�NW.-,�X�[1�#�ąbl��VК�sQ> @G�����tr�eb��;^�J%�șpZ\�T��?��4RM�G��X��Ϩb>Q� �G%<
-R��x�QrP�G���2	5�S��6���@�N���@��{�0�?���D�E���,�73�%fﲁ��wi7�$��d��*�G�ҡ��T�޼���D��Rzd�"�=�g��@���E7c�w���4�Ûd���7������@���r��,U���+q�qu�N�b 5�j��t��T���=�`�4RyK��w��sR.�{y���i��V*��(�R�ͩ��hEN+2��������2�r����M�e��N�
-���3��a7Y*{n�N��<(s�a�� �X�@:7�oL�S#'����9�6�n���u+'�Bt���$�?��.B���Od����k��3����'�����,��]fs3���Jl����
-���� Мk��M�\oH��p 7� &�6j"a&��� 'd��k�K�*[r���m�32^�K%�Z\���%�lN�����]"�C�	�0��5s	�0arqJ�)��q�Upq�8G��a�Қ*M~�S��%�<#�)��8h#��d_-�S���y*ҦH����!�\L�Лb�1{Q�	D���̃QZv��'8��s 2e��E��2^/7f���Cx��%9	Qo瀜��;Y�Od���:�;Y��q�!a\��}�I%���(�s>(�T�pY�V2�p�&{�F+���ߧ���Ttj01-�Q�x�r���r�������W9��rP�C�m�~�D:��W�-.
-�'�U�~�D�
-�u��+�u
-t�;(��R����^���bl�O�*[�R�fh$$�b�d��A��K>o��G�b3��AFT,3�6��XbU��f0/���I���m�?��t�Z[۵��mm���z��=��ik{���t-�����x��	���� �*E�~�o��.�2�b�h��ɧ%�Su�S����0�tى��ke4I��*�@<����c|��oZ�ӛI��fX����#�:4l���i^���ڳJ�YeË�kI��}S�-�D6q!Tkʤ�F������L��32t�N:k�l�d�7�^��
-�08� !�,F/�ڲ��!02H�Y1z�A�ݦrdZ���l����~Зܚ+�ځ����=Y�]���s�2������ؾ,�}v�7X%n���V����a�����?W�;��qgo��(�re�C�( ��&�@�`+ l6 � 2���ry��5�.�f�h� �x�
-�w#�|.[���d�ߌI�l�o6�o�2��k�#�h���ͧ+�+o��.�n���d���^�D�Jwܛ�Rx�NnLj7K�?LS�n;�X)^s���l��ഋ��kη�ou���4���CN
-� k�m����Sk�V��9�fpN�.�5'�M�i������v���jǗs�ެ�� ����ps�.���sDƜ����X�di4%�Cj�OA����~g�����P�y�4�Nw��N����	7g�#��5���b�Y�KֶZ��kid�`{�p��`x�M���_����bq��W]?l��Pc}�u]��,9���62�B��@�K��l����L��E���rlzo<P�F�ἀ�O��N��6"��լ{��5�� (A݄�4��l4L�{�FÆ�}�����[�;XQ����$�� ޕ�ł�S2��3��s��TT��bj� �+��)z���/�&; y��}�.�P:٫�p�+ (v)0۬��9�ጛ����-�Zx}#��0\?n�*&��}�p'ȸ�/� ���p�D���Io��w�r3���T7�fxXx�L��޴�ᝳ�x�-��7���a�}d�͸���s&�﹛�]䪍l�q��X��iY�Fz.hx�@n������Q����8]3��
-p��Si���y�;:+X������
-��� )�����&�q:�[t$h�>/������U�2��6FN�!n����������S�?�`?�$�����w�RT: ��Dan_Ɍ����� �4�����?�wD��E����P�#�J73i�uIE�٫�=8y�D�G3�����i�.�T�?�C;�J�� �LnPU` ��������X[bI~���2�y!Yt�]�?A[$�Fʽ��;�2 @Q]PT���?PfFw�ȍ��1_7��6�6�-��Ȋ 
-�OI�N�!Ԫ㺯𫹯���fv�y��y���5�����i|1��OǦ��#H��<��a.�(���B܉W��*�<s�}���o��Ғ��2���e�u
-.d˓o���N��=<� ���l�<��GqWimi��@�ι`k�Ҿ8h�/�)B����N���`_��S��Vϟ������E��j;B�bMA�+�=_����M����YC�Lxxf$�(���b�K���ٍ��0'��S�����1�����)�2���(��d]������%{��v�)ڞC�Y'r@��.��Wwo�l���3)C���D2�?�u�c�LԄ���JXc���A7��BM3_
-�@����<Xc#�R��" ��3ڣ@fA$ �i��t��D�1�4Z�C�[��&��bI���c��� �`F�O�S��1�D��|��M��n*��W9�N��Ɔ�����ν�ćũ�[D6�����D�<v�_ e�B�Q�/��fLbӸљ�u<�"OssX�����88�ێ��1&��@��LJ��隖]ҫ�����	{��g�S��)��|�u�]��2����1TsP_��f}ֈn]�6��6S�(v� ����ť�M�IΣ���Go8|̤Ͻ�W�ж����T0aZKl�@R,�;.�T��騕�3��+.��T��k�)�1aY�LA�1 ����&�t��7��'�*(��*l��r��:��Yy����s��3�:Ȅ� ��0[1~��Y�A��֩���`H7vXvㆾA�@� X&^9H�aU�w��>yV�0���!x\�St�S� 9̕¢��h��E=�W��و��5�@y�9�y"�<ey��hLȆ0c�W�i���CTwA��b����!
-����$��X��"z��\�)�m�Z��P����4D��n
-���A��{���:��^v�t����H�ǝ��rr]q$�?A�{]D����R�^�����/�˱�.wbc�\Y�'���H���|	�)ց�0���1���j�/���x�u�Ou��i���F����[� ��^�2ӊr��>�6�uCtJ�3n�>	R�J���?�[��5����#b�f����1��*���6����o[[U[[][�3xT���0Fk��
-# |M���\��������;�9�1�����1O��[]M�q�B�����������6,��}��4��鑞P�Ɔkg��J���8`��)�WU�Qd�AN���\\?Oh]�d$�x=H�*�K����t���^v��J�m�^@Q��tA�ͅ�s�nx�M���rEuE��0�&׶`H\B����V))����U6����1�z�a�?�W��M�����24M�?�Wyo6rM���e��0�\��c���hɏ�J\�Yf�8���;H{?�☣� 7@�-^yl-,�XƸ�������Io�I~g~�z���7��2��{w�r�������Uv410�p�o�چ��n#]����!h���Ia�FHi�
-����٘.B���E��T4H���D�6zԑ�(d�=x��!"�u0lZX�Ď;2HкvM-;�HeY�7:6]�"7�-7fYD�t��&�I�	��}��#�l<����07u(�&���i��td��,̅���p}a��n����e9�n����Ď���(�p=њO�9��!Ό#�;���EI.����
-��c�9�%Tc=t"�]��#J��[.����؆ϧ\�N"n�a���4�ҍ��{Å�]QK�;������hE�s�ޠ7A��:�T�[��|�
-e�q0��ci�5��f����X닎�e_%�#3�L�����:0<��b�C_I�=�-Aq�_z�J�؛��jE�*�g��Y�*�����0+��ЂJǐt�۠��o]b�S�R�' �ꍳz!��B�|N�3B���Tg��eG[[�������Z�3��or�_�
-ƕ~� ����u�A2M$�ZSiC�)��(�YOe�8�AD�(��Y����aM"�j�#�qoAJ�(�"��ۀ�z����~�|PBF�6�U��-|-� 0P\�̅R��dr�>�_�#L �PY:��ö$�x�����{R}�x��`iJG��Ւ�Q�w�=;��y��gx	�Z��f�S�_d�2�`��1��=�.�;cЇ��T$dq�ZZ���rI�+��Cy=f"eW���}��ď�9Y�v62�|3A2M%����#�:q�~��%d����&��)���z�%�	���Wd�G82W�n��׸��=�U���%�_�X<�b�Z�+����	�;� Y�+el��(�>��0���na���Eb���s�e��d`����16��思���o����*�;�p[s��PR[�0�F;^wP~����F��<n�����1�/`�`o��֖1
-��N����IJ�t�>&2��5'=$G�u��b�1�������6��i$-�S}Ȏ*�������	�p�b> p��(9�ˍ��c��
-�o��)��	������I��w�ֻ��r�H-�.R2�Ha~6N7o8p�ɫ�]iH�Ψz�g����~��|ݏ��:�x���G�#n�-�uX���D��,0���6�~������fw��PK��k���LӜPO�U����0٦�q�e���[��u�Rz��4c��2�Z�H��{n�g�l��^��=X\/��'���/v�Vr��гC�U"�O�(hp�GP7jN��p�����:�����c����9�
-�=�P�	
-%b�Ԃ��V�ud���f�g��d��� �>iW
-D��{�t�u$����]��WKk[�h�&O�k������4�W6&Cb�8��[y���d��t4y�S�kL���:�q��ޜ��f��V��34{��T��b��۲*=��$?�~U���u|���z&�k7P��h4�C�\���VG�q�7@�C���H�|ѵך]���v�M��ٍϊn�3ۍ*��t���e��7F���˽��r�3!3��2D����ܢ0|�;Sx]C�4ڍj��x��k2g�%�xh��Ź���|V������Ť�=g�G�����<T8��ͳ2��%x�B&��:��E���RZ(e����r$�#�4$�W��h!�4��'�%��������:�Ze�ۉK;r�^���#�x�/qy]U����L�w���D3U��;��3�
-�V8��* =Ł3T�� �X�n��L��E�xn��L���F���"���+�轢
-�lV*zXa�f���)š����6h�c'(k��Ct�ɑ.�+�ڇG����TCF�4N�+��y���U��jQ�i��Kͺ�wL��q�M�+��§��ږ�/��ӹ���%���>�8A�k[3/z�F[tn*ն�I�⤃��v�f��LlgP'���뼍��El�M����W�m��c)A��{�}��~�{ X��.����!LY����#��h0v̀?��0bOc�����ش."�L�b����H9��r�`l��=��3�/�o�I�5c��
-o���s��'8h	K�c�̏��-|�RƓ�F���M��֋����@Q/�z!ˆ8�����H�c^)��/ )6�@�k>=����0Z�i�N/Կ����B�%�I��;=� � �C�����HC�B/�NZ��ӧ�+@��;ں{ONU���[Jfd��X��6:�W�[�A#�m��,����rN`�o���jx�(c�fW2�^��fy��J�Y�G/R���!1��<�H��`�+/%��V���$�\��m�է����/�I��F�d�~_�U�UO�)?�L�,"�t�yX3)��>X�������er���2 ���hG�1��=aDo�j���^�%>�\�34�7��2�@�����2*j��y�4*>.U
-U�o1)h�1J�J�'�b��+G��</�4)9�K���057��DQ=1�~Ӆ+T�.��t7	`����"4~D�ۄf���o��|��_ ��sN�L�Ʌ�T�x[�EE5��{^�M��b#)zg�R�����Z'���a�nF��δe1זF든�NN�]NQ]M���慆,M���\#KAg���k1��l���piu<g�c���#*�:��'<��>yc-�G����G��
-v�^�J~$E�2���)�z6.;�����=0;U�]�ua������j$��E]��q@�Ӡ���`R�&$>vY�j�.�HQ����;�la�w�����._�pmK�^)��mqh<���41�*	�-��C����u�2l�y6C_�K\F�݋��(��骦�k}�4D��.ha��q�K,.�$����@�C|�H'I��d�Zak&ʚ𠙢�zU�m���n�4q�T�[|�x�)�}D�,{��͈n���@BloL@���nA��.^l��Cy�<�.�a��x>���)*t�]95�݊�>�#��{�O^_%Av}��b��X�*�����"ǡ��
-fCo�@Y�lM��Fq�3a��:��s�Ճ���z@Q56��ޢ��$�6M�F�ZTcˤn����� \'�� ���vE����G+١�F%�Fb�8g��(�"��Tֆ߻KS	���US�i�����z�Q��a����o*���.�웼s٢bc.[T�sʪe��b�6Fd����<p�纖k7{�+u�[]f�ks�}�=��az��jPbEҵ =ߵV�yN����&W��OŊ�4�i��$�)�Ձ����r��>�R��nC����S�ߞ�f�⋱�����r�����&3���t�~gȑ��,��U�W�s6����'y�⻟�;������[���zb�#܃�_�1o/aM�i��+� ݲOdF��Rwʑ�,��l�6M8h�؞��;�_A_<2���=Qӽ0{/�q���ɐ�q�xC�������C�/r����1Ͻ_���E����MY�����f��~�1UN��7�{�Y���Q��6ZF�,�*��doE^�";Fl%.<�r�^W��{)�H+��^�H�ZD��M�m^c����hK{��p�NLtf{�����-i�:=u�N��x��$0Xe�G��A� �$k��A<s�6���;������;^.e�����2�������&jk��ֶ�:l����p��Zi�v��񞘤����-���W0�zؐ���=���'f��@R���
-��w�b(�D}֋���4|�79E��y�s�Y>�T1��t�83�tZ������H5���Nչ�.���:��Q��td�&<�ւ}��4��1{�W�������HA���HIm��Vs���9��g���X�\gfs�^U��+N�E����bn�|2x���M�ݏ�b�E���aI�:XF�W%��=O��l5�>�8�;��.��7��$���g��B&�W�x���c��[QO�׸���Tc��U�go��(��З=8��g��`�A�a�%��=Ů����#|��1����+��ѹ��Τp/�K\	�u�U��D����Zt��E����U�����m2�VTL����vE�b
-EԶ�*����?�t���;�R+�w��û3:��xU�G�qA/"khj������{�S�4�JD ���6%�z�v���e(�*r�"�)|�(�͆��8�i?P4tz��!��#{-{lD��o�Q��*NR�Y�k�0�${R����px�k�B�����o��ߡ�
-��=���(�txdw<@�c��J^��*�m�G�*%��{�JM%���o�4�٦i�6Mk�ZƆ���c���=F�c�l?�^�R͂F��M�9�+����^�S����������nF��HN�Gu�)}7�w�>����=7&?� �W�}��!��c�K��O��[���-C��)��C���z�Z��Ɠ��V�>�w�
-�a���O��1��o���Q���
-�;z���vho��Rl�@�J1��AՎO�7�Ì�����ٯ�� �^U���xiY*�}ck:#�[+澊��sZ�P0�fIȘ-�4q[֞5nC�U�ٛB�f��b�I#��KU[bN=#@��f;e�91���]\E���REc�e|"�,�{����<v�� +qɂ�H��(�}�	���>=�S��{��@�� @f
-���������3�H�Q���V�+��=�T&AM��f�>�xB�݊����ˤl�I���x�z�L�hf:e�����J��������*M�P�:C}�[���ʯ���.}�V�K^��|�s��{^��E�����196��rlv>]��MEZa����ttO�{ :�H7p��W���y��iM%t9:�Q�B1,�-w�FTk�2)�J:}�;;n����vN��';t����>�s���s��a<{ӱ��+�M�wh�䄜]0|������� /X��G]@m[�  =�ȁ0:��C�o�:ƙ����̘�X���������ҥ�����GN�d|�(SZ��-#"O�d,���Ŗ�1�M(�o*�������X3ڼи7�8f��,f��x��d�_P���w����(��n�:��8�&�1���5��>xl<��b�*-w�f~(Ǹ
-YJ&;��a�JX^�9��\<��{��CD��ܕ{O&1/���v�|�`DC)9_�6��c�����6љ�������ָ���4�ұQ.�IM���C�ޞ���|`���b�4�&[o���l�����2��Dq���-�Y��Y��Ӄ��| �\!�z�>y@���*�U��Δq��#��![��)�ӣ�kKXP�LL�/�xC*�2>4_���S�^JLϦ�ɦ���>� ��Y�{A>
-�-rƆ[�������4H�b���3�����>k�O�+��WQ��r>x߾���n�]�s$R���!]�<�"��[M���^��NB��cK�`7c��Cw�~��Ql��ef/K��C�p��}�p&�:!4���)���IX��|qmI�9�ٌo�E�C��"�J�+�g�c2����|+��6�V`���V`���[�}J`u6���@`�� ?���?�ր�	p��2�B���Uy+�k�̭��l�-�V�0�o8� ��d�uI�ܙ�m3�n;��� ��7z�?i�X_���S�X�v�����>? I���@� �m�3[��>�Qf�4���SLG�B!��Y)��(
-~�	���k�>��ݣ�Ot��O�G�hy�hA�h�>��d���ޕ��?�	$�soŕ�fdFƒR
-m�$�R�%�
-�.W�Uu��ڮn���U�k��͔�IwNvOUW��ᛙ�7#�`lc��#�c��x�`�1�Hb1�j6�Y��9����B�LM�}��q�˹˹��{��F��df�D^^�G~�T�(K��h��!��c)v#Ŗ'�+��hEA����)�r
-�Wd�Wg�7Q��D���>�-���)�� �ƞ�&�@���{H|�i��GBƇ�����'������B��B���~Z���
-����t����cW���m�}��]�IJIp�=gi���L����+���>痥��{�w�4�QY�|��y��>���<Q�ON����{B�D��~��N�G���`)(�)lh����4 ����+���YִM�y-��iY*1KM�g��m욬���1�,�r]f�z�f�|��RĹ�K���<��_���� ����/(��!�K�:ڝX�o�����ub�"��֍��>�2���e�NfM^���v��C�����V�2�=�����Mo�l|1�G���ޣ@{���	��Wr- -O�L.(�Vul�wtWl�wtw�:/.6�����T�y�j�������D� ���aܗPrj�]
-_GX��p��|��s���g�`,����+|��>����5��=YD��@�E�w��Y���fT)�#J�#HԪx}�?��3Z�#�����e�izW��5�-n��x)?����ם�_wV��W�oE��n��ݝ�6��n����Cm��O��1%7+N`V������V{jO�R�zS�'r	N#���O#��9�/��K <�r��SX���`bɠaM���/lK5�Oig6�� �%,�pN���c����9�i"R�E:I���3��U���,W�W�{B�6��=�p
-�5X3��%��&* \՜�k�i����3�6�7�./�^F�I��o�=�3��oa��Qt��{]������ ���i{���s���K�t����� fp�g�*.G�
-Q�G��E.���ɣj�e�*��M���2��ܞ_���j��Uc,r|�s��V�`N?V�KЕ~V.�8�o��71�T��ߞ��]�O��� ��3"���&��*.��#�.���on8,��%�f'����3J�۝d^�VO�V�]��4:c�;Г6�9	[{>�T>�<���95��*%�UQC�EN���/��|�����~��t.�v2�.�vr~�î����NEڥ.\��eyo�k������D�sozn�M�=�v|��{5W�����{1;�^�G�+�J�G�����\i����7h7	ul"�%B�r�[L��nI� =��NS�
-l8�"�_RYL��V5��
-� Z�}��O��es��z@6دe����� ȭ�6J�ɋ:(����5�*E&
-�:#ڦ⢟5{	n�5uo�`6-�E_xmS��m�5��p�'٦"��p=��4�*��T��P���4�ڏ���t A9h�tP��5E�
-
-W�Ҳ�P�����}�ö-[|�t������hs��?f�?�;J�e�k�Т%C�׻-5d�B�0s��O�T��@��TE'�Z�[xEQ�)W{����h�����PbQ%�����Z������R}�z�5�L�� Wsxe�	Ȋ�)�<E���7r��m�@��˅�Q�X�g"���w�.B��O�͊��f�d/�̕-,��6�G���7Aa4c�o4�W�iU׸6Ģ�o��_(9;p+�@Za��\ Y����l��g���gV:w0o��(��ܰ5�@�fĕ8o����o��U�zT�1ژa��'��b�6�o.���J8}'�qA6; K�e������`��q[D(��/ ��U�����U	��?ܝ��,wl���a(<��p�d~�E��LX%v��S
-Wr�wg)�'��ݖ��v�K�f�v$���)����y1�GB���e��r�؋�>�3�X*�~�7�	��K5�	J-k��������7��3��jWx����Qײ��W����{��t��{�����s���O�	��\�CaǭT�e�+ڢP�IQ�8n?��C����Ƀ�)��n���-�������u~%f9Yot���n�@����:��Nh����2U��u�a/�0���������v&���u����s��l`Ӽ0� /�� P��<�>�i@���O9�L�i��wl��1Ұ�;��>���|�w�V�b��h8A�1�-���-UP��V�n�V
-2yLI�O	[���/��N/7��
-Ϯ����z͢�ة�R�O��r�����[�18&-�2����
-��T�;��!d�M�'��R[-Y�k�#&{�mm�4���J��R8�U��ea���#�L>UJ��T�RϜ���%O�{��O��\t�)�߁t���S��2��*T���1���og����<3��gET��_���3Yc��.���^�G�=Bp8̺',��U-%6)�a{�񋐱e���⟥�S*�4��e��˦��+��S�-�z[����Mj��_�!��2�d������*	��X1���4m�ai�o��3wq����%��n��	�X��u�r+��{�2���]l�9%,-��r�Sn�Du�3�hZ����+�~��j$�T��p�oS��C����X��g1['$f��Г
-6��K�l�`�T��i���Z�OXY�&��&F������5�X/�������éFi��vd�S�t�+����to��vJ6�
-n%��"�v'����!W�@� %�V�5��"h�j���NS�.���(Y�\�*���U�8�t�/ʏ�]������~�SB���#���l,^E,:����}��mL���*�Z�����
-��*��x��A�B 4�)):pM:�`]ztExV@ (e?t� E����V��u�h���]���{��EC�����]����
-�D[��צz*�^��a�����V/��VٜȽ
-������ѩ�h�_���6�>jii�����4�4A�䨧sl*ѭ��'X��Z)�y�P����BQ�!���r,^�pl=�`�:,B�x�.����;��;����~&����~��GwN���2��d�SƐ(�
-���ē�u��7�	Z	I�y?�'6��B�6�,���m��FhZp���}F�5�ܠ4�e���o(X�t����PU�6�oEO�R�-�.��ׂ9E �8��<6�z�00T��;�¤mc|1h{�](���9'/�*:�|�E|@�n�Q�5��ߣ�&"�f{E��Y��kw��k*`U�F�����/K�֋㷸K�A��#7; [U��8Xt�[T�餄(�S̘�\�kvR?�8$^�GgQ)��Ya�xr�8ڎ���S��!yIV5��U��nڷ"�6���,�g0���J�2�����ߐ��T�й��\��w�	�9)d�N���}�B����R�n��	��{��8���=��´��D��ȸ��2-!�,Xb��$��+bS��ظ��u	ٱ.�=�T��b��*7�g>�nES~��	Δ@���2Q\�9 ��'�a�Nė^�'-�q��˄�4-b6�=]@,�wȱkBN\�Z�ٰ�>���
-��P�T~�O�V���ǋ?O�k���Uv��h��\��vc����*"V�g�h{��{� �)�}����Jq�^�Rٕvn���~	��}|4��C����ҊVJ����.��F��C�=V���.��eYʿtbru�������i�fM�&Ðn
-���)��+*.�Qe2�B�{����������G�#{��a��s�-�A�������L��M	�lŌ
-z9�dc������!��[�\�ߊ�)��+?Ll��p�`�ֆ˟�_���ʇEyE���3̎���F}�EM��;�A�8ȵ�|�M��M��̪"�Qu��4���h�j�����������$=U�ilƋo:�$���L�y�m�W��F*)y��aj^�,�OP��J�^��R[���`7l�%X�s���-\/9�M��lBm���q(��o@��?"�o� 6Ո+|��X�A�_�΃�f�:�3U����$�F'x>��j	��N�z��ь�s}Vr��Ҧ�9�mc�(4���#d:>;��tt��}&�'S�|)jJ ���K�?	Z[r�+8ɳ� ���U)k »�x,�D�0+I�j�}�34���H�]H.9D0W2�V�r����;Cd'�����,���.�@���Zo-�S��J{r�ڼ�΍k���hG8�s�a$�/�h�Z<�W˱9>�q��-�x�0�<�����~VhW�[n�Q���ӎl�-�"�(��>PXR"�:@69�Vm۲�ɰNu��	$��Lb�&l[��Ӳ���d|�bZ8�����6:�Osq�`�ڎ`H��
-��?��B��q�1j�Z���A���c�BpcZ5V\�R�ܰ97|g�"�-�O+�d3K��*@	�yw�
-*���n��P� b�o*��f�����������	�a�àI3��겛��9	��񂦒j��5�x�s�<�eoi�ї�YY�(����q-^H8P'F�Z*�A��aH �)��$�ò���������)̢�j\��&��\i\�ĮJ�2�h���UI���i nLYL���I_¹8�.�<MՔg��J7�,��⤚j�w�)� �9��qs�0�^%�T���o?�b2	y�H�ECglW��Q�K�_)����5hgh;^��vGy�C�t3]�;�~�΁h��t�:�� 	b���e�ĝ�ȲY.��!d*�I]�J�YO����g,�ŪD�c���X�.�uL�$��V��^r{�EXYN3m�?��Cz��}:�Ӯ�ږ�����X1`�6rى�,v"�se�{�]η���J���*�J��~���/�nl���6��&�i>a5��Jca�[�%���l�]�^�W�!�N�C\p�%�Y$ֹ���4��=�yg�P�;U�d�+d��w��+�<�<�m�s��A�m��r���P1q�w�����!�\௰�� _�~�6�+W�����+D�||��>�1��Z*�ik=C`��Կ�Ua;{��g$[ٍ�l���~�zF�>,��۲:p�e1l���Q����
-Qh���G<��O��H������A����8�A����GK�ޜ��eF.��ʏM�ym�j�2�TD��$sr�y
-��SB�S�{���
-��:sZȊM9��ؔ���PG	OY���f��1��+m\�	�.j���A���b��ѥ�����"�O�^<9�p}���+&_������A���Tjl˶��p3m����n��G��r{�Ҭ\�^G�o�R<CD�L�~���ד�m�blR��^��\Φ�F)�����%��.Y�D�<��&NX5T����q9�z�>��5��^m����l�i�l��U��)I���ถ�A�4������7�Pͯ6_>`? H(�RFasIf�C������n`��)C�=ͬ�Q�+z@�]�(�XS�, E���R��@�\�(SI��-6�!�!����ߠ�*;��sJa�S4�z(���V�;u����37=���w���N�G�Y`B&��6�T��gJ:{�٣�v��xZT�_A�q/<4�tR�	b5-���ꄉg���A�E�6i��il�`<�i����$��a�b��PΤX�#�xQ����\A�Bz���N�U��� m[�A���'��BO(���VL n6�z�����:�,�w�o��DS?���xAˁ��/��#r��ȑ�0����z��ј��e��Z�<@�s?��e�Ø�¶}j��p`oy��YU�,(<��
-�Aʣ�i �-h'���@�}�� >FC�W�,v�[+��	�,a�]�!�/�8���"�g����m�����w����]��[��S���Lf���5
-.���f��eo�F�iF��}��Pd��v\�/��b`�)���6ڶo�;/��m(�*����f[��B�-M�r9O�uP�e,�!,��A�2k�h�-]f��E}۹���� 3V�'�l^3{��+M6�^e8y^B-��_�q���6
-hu�p�ښ}�����(;bg�e�:���2���!#GS��=4��@D�N�iQ~��y��A���N34
-k;�t�0���Ô��.5����	[D�8��Z��ǃ2K���.%�	#J��嶛��5�M�s����f&�o��+7r���!�@4\�
-
-׳���#�t��-�1�M��,tJ�~fl�٭z�Ҍ�u�,������$��ZU�0H����L�b{�#�qŵӡ :�z��5e�6�ĠTb�*��Q��K)�rNe����@T���&���/g#�|ꐉ��*�Jݵ��S���#uꞸ���ģj��5dk=��r��c���/dy^����?�	p}�_=�@�t��ڒN4��`�2jrquk\r�ܹ����.1�&��-TW�O�5y�w{��n��v�O�6�4w�O��&o��S,�G�Yt�"{����HWLsu��l|&:�Fwb���w�^O�*;W��Js���V��o�;�7�^�I�Z|�b�#v�[q'@���q�hl*���s��QEkc�w+o-���s�խ�fu��Uq�Y��N1�AX�Y���4��"��c��16E��L\-�_��?�����rz6Kj��SN�O�c/�Ev�$Dj'K����g�1�O+(�+���x[��(���7�-᮴�V�%����u�]��XOgN[;eH)_��SV���M�h��j:�3s*��8�ϱ?Ҷ�,f��Ӎ�*%����[��b�Zp2��oѶ)��RR�\�.�N��*jA�!�}K+��,���*��?F���h��ɼ�G�6!�S(o��l�fm�"����t"ޱ~�{o<RI�������
-r\���_0\q0���"�u@|�S����Έ��~��l�i�/�����]��}חӒB�������w_�/O��� NƏ�`D@m��#o����`gY�g:�^̵A�M���a��|��)�6a�
-��{���Z��At�̎ڡ�U\������p饂�s?�{�c3���і�q�p���(5DTH�A] IV�R[�*��'T?��̓���m���=#{p���V�Zj���cM;�jAq5}=�5�i�̕<��
-3�<��J�W�??�ׂ�$=3���Pc3���A��U�j\�'%`{/��.�?�N�p�p��w��\�'E��\(����0v�7�L�,]��S��U#�יb�]Kd=�)�鵿!�!^��<'���C{#l�Ȏ?���|�Yn
-ߎ(�2�w==�W{^�ڳ�j���3���o{z~��M�5���Wc�WM�d+zI�h�W���5�'��؎alg����܀m� � D��:�Q6��*� N�{t��zz��������'U��$���x��^0�Csr��|#AY#Þ����N�;%�a8�fw��q���Y1��<�j}qyvz6(1�q$��:���!;��Ky����f�x�
-�Xo/ӿ{T�����˭�
-l�fĚ�]).a�k�"�]�k	ޮ�&��}$/��Z7���vŭ�jK��v���Px�֜z����#W��&^�w��ۡ����O���%�H�o��}�í�'h���8V��}{ZU��&�-��+ĩ��qW��cQ�pXfQ�z[Q"܉w����3�"�&��iD\��3�$�x�Ù�ꕤ��b�ַ���N#V:j�	hj��3���g�����|��
-��k����S���G�a����:�������z&5TX�&�� a���xa�/�z .�cLG�>����L��pt}PJ�y�8*&��� �2N���הq��2��2��)���eLɕ�%ʘ�����Œ���X�K����*�(!6�.�xuFJ5Uш��H��3c����H��Rli��$�>�����}݇|��b���nT�]-�5Og�)|��2�ָ�7 3�^�����q^8�Z��T�۴Y�l���0!�ꍥ�rr 310᡺���	�1�2;8���׸��9�k�-c)z����,�_�*4/�D㚎�^�4�WDυ��"�$����	K� ~�<0��M�&�kb�]�?Wc�h�7O���T����q%Xʪ���Do��,�0̦I,��s�`ѝЃ_�sL���L�ػ���0,�u]x@�#��f�Y	�:r�WV��3>:h|��$�滠,������B��"�/������[���=������iۇ�!
-�C֨d%D�yxPpW�k���x-��0���șv$���x-�>����K�,:�`�v0�Šv¨�5����_��#��rx9���QD�'o.,́=�e��P�}�p�s �b��[��Z�g�=ò���2�]T����,�Ǆ�p\�W��_x�{D�S����YA�*XtJVA�n�3{?l%>G?K�g�������8C���|��6_l��y���b��N��y����A�l����5��u��<�����l8����Iz��G��҉�v�	/ޓ������(a����j|Q�Z���&��\|+�)��?�ae��p]�>	әO�峂�OX�{��P����� �A���a������Ճ�_N.�G͒�M�0�<To�&�Ւ�|7����<���pQ�PUl�@���"�*�-� i�5��*U��i��~N��l��k��!�9������Gu5o�a��ٗ�(On�5o䀍v�FF��C�D���讦�'X���{_��D2���]+��ON3j����I���9ϣF~.+U�����ӱ^s#=f�����[����f��Xs۴�m+�-M��NȄJl+t4���m��g�I�q§LN������Uتت��њ��y�4�V�%3ƽ���H��MB�lј�h��@��D*l��2����	p1V"� ��������y��-�&lˁ��z�`�T���
-n��}�����3�fw�ʚ�3.U������X���}ɟ��wy_j�9Mb'H�}:Qj��n�:A��u�`�W�P�#Z)o��l9��,�gnŚ��*:�E��z/�<��]��Ng��-w�&�������~������ ��M����m��!��p�1� A�|�����x͉; C���y�6{���ȼ${%,M�
-ke�-pf�W�3�����\)<r�׆tS�g��n�|h�wx�������i;�9� sJ��7���_(��K��w�x��x��3E]V�+��X���)E��)ER�^�)�����'�R��"	�M�qb��Ǻ|�ϰ��uL���ϱG��2���	�K�G�Xw��?д-ܰ-�i�����י;q���gi�Pەjj��u��7��&�������r��.��]a�B6��;l%��v
-s5�P�ǳ^������IF���� ����*�k��T������a���b�{�7m�|A�B�W�P$������?����z���)��Z���þ_Dh\_l�ՍT�9(�Sv�Iy�wf�"!���'�~[_/������'���صbI: ��8��[���㯨��a�%�l�ǻ�Al5������hܴ�&�,�qoqާVTv���w�OL�W���/|V}�U���\��E-Dܫ�p���cU�^�;���bs|v �m�=��h�܃�`WR��	|Dˢ�C�9�e�rb��k=!����Sw*��@v;y�����Du��y*5/86�,s���@�yZ��eǁ�G�y�=�{<�>����;�l@��q�GB�P E��Te��x��-.jm�~�nk��g�O��!�ɒM%lc�L�4��AN�r�L��N2�h�_IR���J|��r��Gқ��z/H^w�:�?�mQqK��uQ�4ݎ����ҿ`�M6q_#�-6\�A3��������'l��7��J�&�M#����l.�;�T5�s�"D���ꆠ�~���.;D]v��0u���*S���6дa<�>����l�� ��t,l�z(,z�"K���c��vS�*9�����'N�''[������v��������=%71��a�V*��b��h�rr�p��|'tTl:n:�D��TX2�T6��m�'L�W���N�T�ζt�<mw-��?���0M'�)l-�0���������-
-��-�+�ٵ?������lJ�ťB-LI|�t���G�'X���ă�a/�T>sm�OxGue+�q*��9ߢ�k+�������3
-G� ���]�4>q��������l�,��Y�B�m';aq�j&�Yvb�'d��f09`Y�<���8�������+�(>�s�8oQ}RQрT�4�^�pj�����i��)����?��>!�g(r�d~)gé�B�\8e�U����c^��|E OJ�G����R65�dŘSi���J�:om���[[n������C�N;%����K�甘Q�(�:�8�.��bQ�(�]o�C`�mUK����X�\5�(M�qE���1�k|�U�d�R���ޔj\V�ԇ���<� ~a�0# �}|�NU�����;9�W* �0�V�!A&�h�=���-��M���%e^&��錜�-�q�J�US�ˉ4�ʴ����[��[��~%M.?&Lb�������%�B�_	;{�fł+a��Ƈ�{�T�fW��n��&���C{�<�U"�U�mD����Y�=�!�6lOn�5�%Ǻ�v�E��@�Vk|LK����;�quv��Yh'Q�~���Y��<-?�R�A�q��v��EZ���J,�X��%�)����=-��kD�s�bM6�.��E��[��o���&^�o�6������Q}JQ���f��S8����[V�lw?��D˴T���R-4�����A��B���fpQ?����>U���S|��b��|YK�)Tа#��8E�8m��ͨݟ˪Y�eՑ�UǵY����`.����P.��yY-�6�s�Y����Ѹ��DE���-��z�r�Ʌ�;�g�bۋ͙��U��,oWS��J���Ч$��:Uo>J�OK�zL�̱�)�1�|�S���T��8~���+7�O���z�ޗV�OW�$M���}�3�x��|�2{F2����y O��U��<�~%s2=+�S��dN�4���)�yɜ��/��L�}I2�>�̶�Tlm��f�j͡�9�a�Q��Js�@d���cQ�2�|���k�H����P�D�|��Y���Q��Js9=�{�W鱹�\A�u�͕թۃ������_��*
-LU���ê4W�l_���Jsex��Fu�K��&��l�4��w�z����־bsEVi�����6��?����/H�
-�_i~D_�$s#粉�U�3�'�q���L �%�S�:Vin��)��B���SZ��!�Jj=D2���)����>U2�Q��$s�H���I�N��`E]�4w#�ഗ벏�.���5�~
-��>]2�;D_3$��$?��?���Ǹ��r�@_�̓�q�~����2[e��Ǹ*�)2>K�'��s�h�d���=�W�_Q�K�y��&T�_s��DE.S����F {U�_Ou��l� �����r���#��F����)U�8zL�2�ǌ*�!�d$u��7���S�~�g>��@�����%��F�}��0��<�-��)�M2_@.�"�$�y/��Ѹ/�1��1߆��FgR�Z��0���3���������f�NQg�L&���_���4;�	�ͦ�q8e���~�k�	{ P��s��Tj0<e�;:�_��:���3�c����Qg��mv�s�g�y,H�N���6 ����P�v�qr�8߻��R��8| z}������rVio#�C��W�:W:���}>ާE���	�w�Mr�D�dN�8�=KZ߱�Ԙ�Z
-��`�Q�	�d߾ɾ]�S�v�3"��̐�"R�p�D��<Et7�X�5��Ub��1��CSε��e�(��l���9e�\�D;��-�.nb��7�f&��ÿ��#���NW�-/��[��"4�۸f����N��������dq���g^(	��<��ds��6��x���gI�}T�9���bs.=�+1�E��c~$��bo��"�>�9�06�����deɏr�_K~��!�F_�ͭ�>�x�
-,���q-��� ���ſ���7~�Î�G��ƥ
-�\+��>��%�?���Jo;Ԫ;J|�F�Vg�j|���G�� ��@m��4�@����bk���pFC�h� o�h���%(���X.�ࣾqu��w�a��XYl�+�V{m��2g���[Yu��}�}����{��;�}����{��;�}����{��;�}��������w�������������߻׏������u׏��������{׏��7�ߙ����o �/�/�6\?~� ~g�/�6^?~�n �s�~_?~�� ~�/�6_?~�� ~�/��\?~����?���K� ~�/�2׏���������ǯ���}��}��m��._�m�~�v� ~W�/�v^?~�� ~���������n��W�������ﾁ��|���-��s�o�����[������P�}�R�}7P���������o���j�����7�����з x����x�EH��x{:"��Y��+�=K"���W"�ĳ4�Q%ϲ�G+��$I�+�v4�$��߈���y��|��{R�U������!���~#5=Q�렆'J%ª��jxD� K�C��Z/�d�cU�����i��1'���}ǜ�2��;�t�q�%�GR�1_Vg�Ns��8�w̅*c��Ϙ����}������w.U��Ns�����OJ�vnV&6T�u�OK[{b����j�詊��b�JˠǱ�Ѹ"�e��;�9��y���s��*ca��q�1M7Ӎ�*��
-�*cV���`��
-c�`cb�q`�1���0&W/�o�1��XTa̮0�T�{+�yƾJcz�1��h't�*�W�*�G���Ƙ*cÊ_֋�X���1���S1�2��x]��x��<M�����i�o��M��e�,Xų�5�Ş����)��|r���2���V��j;Ok�$���
-�pM���;X��r�s�H:��������N��$WG�}%G{z`	
-�O���'DڤN���J��	7�ok�R�w��bV�WK�
-��)���Pw	�Ěۓ�q�K������D�?���f���Y�0����f�ۘ��q@A�cL8�X��3��
-��fD�J�2y/t��Ws�@M�W �f=�k�I�W���pLd8�����勵�DW�y
-gZ�V �2�O�
-5������m(f�&+~��p����6h�4�hL���+1�(gŁ���)�Q�6�OY�`��I�I��!i�2���Rk�L��+Z��vZY�w#�2�zaI~��v	-���"�u��TJѠ�	bF���l9�����狚G���ѯ����T�Q���m<:�m�v,��iM��� ;��9�_�nAss ) �c�������5Z�MJK5~�A���R����I_�D�ָMC��2� ��� �m��J}i�rZ()k^�_�� ݙj)�b��i�-�J'�{Gg��!pt�>Ѳ�4���avuC3��Ɗ��������(^l�&���*�����4���E(U�rG��Y�M#�ak���C��5���aV�����e��wi����n�H7J�T�É&�E��Q���l2K�_|2Ok4º݈���e��]8�b^a�C�{��-��iӚ�m\s�X����CLV�g���D�\�0[WČ-�T�\ ���检������Z�0����>p�9�u^�3��l��G,u�6�f�EP'fPI�=tK��l5Ϧ-9;�<'t�����������cv@s&�R���s���u�t���	���%8�o��&8����o�B��\	ve��%x;�`��J�;�`w.�����`�+��l�=9���A���{�	����K�	�w%ؗM�/���\�}H�+��l��96��G�����F�a-6;����n�A/���Ċ�y����c'��0yXK��
-�g��kB9�4�g�m�.[�$�S�~m"L��愖)�}6Bwiv`�-G�sk��6�����b'����h[i�S���"�jq0��uwA$􎲳��쨥��ZG<;�������rrn�y^�8�?9/�<?t�f͜�i�9+���F��WP�������Ǳ��Qk�x�
-7X\�6,�/4�t(��������qɯ4����O�k-c�	�Á�-��=��M�֣����|	���K dr � ��p �9� �b ������>�"��yX1����A)���=�N�8@��L�ix5�F�,�"�����ʇ��[q��4��`�V�~��saW
-���/����T8�G)�j�_BU,Q��\ၢ��-qI�������K@T��j�\�h7�(c���E�a+��]0̎VM�wrj֞��R�{�����Þ���BOC�R��N��) �Q &N	����eQ�_�r�F��4�t�q��ö��~����8D@&}3������N��9�3���.�l=�D�V��&�.������S����oU���:���ie:���[�)��G��v����s}Ň������sM96��<~��<���;�3�<ϸ�<����<��'W�U�W_$�#l�p��(�nW��H�"�����Mg �1;Z��O�aNXkw�>R~�������a[���B�q �8�g��DY�^��+�����b��\��p�X�g'4���f��y�ب؎3�œ�f9��`��J7���<�!����U�-쒎UΕ�����?ؐ��*׌�;E�z]��i�W�J���Nq�w���?�x�$��]٧��1�k�!�r��9�>He�g�t�4������V���HG�/���?67��qk��8�GW����@�ux^+�On�5����1�& 1bt��icD������ǌθ:���Mߚz�q�]��z�N��m'�=�x�0]�)p-��r�G�u"��g��^*{郚\�W�s����[lGӇ?�9+�/��<-�F`��-�Ia�`��:�=��h����GA��v�Sи%"Ѩ�q�d+��¸�:2��z</�%ƙ5_�qB?}T�Q%��l'j�
-�bL;��l;���G���i[5ШQ�H�s����F�(�CQ�8d�D�'W�mM/�*���4��/��-O.���{��Bc7�5���)���0v��Pw��d�_i�g�@��Ҩ�����vr~�}gx�1����"�Ú����lc����0*B}����%����߁|& ��F� ��0yfJ���^��~� pQ�x.��SU�TMɀO������ݞ=h)�e�����4�n���v5�޸p��L����$����5.�����[E�Q��tl^(C��s���[�4�ײFs��<� � ����&Pʙ�Y�50Â63�� #�D�vL�~��	�݄�_$U��I���
-+Ӽ�6S50�m㩖�����v��/YK�(3��S��-��.�ʑ��}�6->y�W��W�[~9RM��uӿ��*��LV��UM��I:��I�P�bv�[��ᜣ��sȶ��LϱV�~���������o���
-o��S\.���{BO,	���܀��m��q��gX�U�G�$Q�����Oi�0N�qa:Wl��u\�'[*��)/��V�*Ś�`��WT5C�*����K��-��XW�|�&O��R=C㑹��Mi%�����uxag9��(��K���RJ���xBA��R�t�|�1t����V!���������Ў�����1S�D:�j�D�~���]�N�,̈�ɧ�ܮ�)}RWژ.�S${yJ��a,|��6m<s-L���z6\^iC9���®�+�>�>�\��sI5�TIūz1����ɧ�J�3�%]��Q^;����[#��R1	�MuB�\��5!���!K�	9@�h|��
-�
-�Cݥ����uE��1|[���m���sQ�*��7.g�QA��D���i��'u̫4^��#�I�Z�zY���Waw:M�tĊ�HȌ�(��q�zz@5��1NGӦhC�K���Sǎ)���ўԳ\�r��I=��S���Ɲ��G�0���Yf�g�L��LF�$����K+�m4���������}���$����O����L�U�/a]eR;�XtL�޵]�����E�\�_�i@!"�ئc��A��^���TL�JIP!��zm9So��+-�u^�[t��(�f��e�B�Xj��Ǧ�љ���Ǧ鱩z�FdtW�K�;,B�=�;�Lӳz�\�Gt�W�J�դ���{[���y���
-m��c��@W5�יT��E�>��t4��q��~�
-�#�Ń�)A�۝1���`�+�J��ae�N�\����F�/��*�BT��3��;�6�vީ�f�}ViµU�;�J5��T�T�>v� qq [HDպ]U�ɷV͝ʩ�;*�:��?�хA *�b��׭�Z�z�q�qL��A�c��O�e��(��������cuP�r7k�X�0��e��I����|sG�ip�(,�!��a6N��>y!�w�����qf��$�FZ�:cKBphټ$$X_�Y����Lu9m_�[��"eOY���i��-ѻHD�H�1�F2iڲ���g�M�lS��D0�`�{�b��]l�.%VR�4�}r�C,se!���@+ 4>h��rm��y@[ 4��
-@���г$�l�Ϲ�}�t�s���'
-��˲O��t�f���|��sh��8Nr���˘��W����+�.ej^؛6-/�[�vz��7#��{1�]������^ʃ[�p��q[ϸ���ǀ�ya�s��B>�B���}�psu�Ⓥ�B�"���V����>_��j-Н��>{��29�n�� �B�]��*L�E:��`�6�
-5�
-y�������ϙ�D#��읋�:�ܵ�b��M�A���Si�T<-5����=XxN,�S����ZɇUz��ā����w"8��a���M"xH�tڂ�/�W)˿HO�%�n�0>�]^I���w��ƌ ��o�� ��hm�@��yȋtܼ��e���m�!������e���m�!w���N�+ʎ���^�U��M�$DDWI�Uט��N[�� �\����y�27�2b�Q���-��
-]�BW\O��l�K�B��(t��[�i.t	
-]��2���W�����W��k������Ձ���/���l;y)�~�g	_�-�r'��E���k�e�|���X��jtW���͞��:�������U�}3K�2��	����y��[z�ҷu��2l
-����o������Y�Q�W�Z��hv���>#����yq�V��(�_�;a�G�n�f��v[����V�F/�w����mlF/[�٣���Ϧ-��_<���y�9P��g�==�mTw\����p�/����ʌ]ƚa���n����wu��c4n��i'N��X5-�Z&�̦�9�u\�\B\��6q\�]ً�Q�\�._�]ׄ��Rr��==_��}�'�h��jv_4������n��PR+�������v��o �����P����Qvl�-�D���6�}�7ю��!x�q�A�P������*�o����2����ކ�2&��o�ݱ~����:2^��?�ɧ�$� �Fo�$��d��<'�t�#�D�ɧ} ���io��?L���}M���v�U��;M;�*���Vtm��k�fp?��3�j?�In��c��7�Tt��P���P@��7��H��c|�o?n1��s�g��/�7�Q�X,�:4m+5���6cz�-��Hok�V*���?�|���wger<��kCu���Uƌ�1��A��N��4�1u����x1l���KacV�h�ac6�����acW�1/l��Ƴ�°�(l�6.Wacq�X6^	K��SƲ��<l�6>`�?Tl��O�6�THB���?�G�{[�x_\{�{/���|u��O�YODp�(�D�'#Kg�S�r2Ҵ>���Iu����%j�2_R7\���-5�o�����K+�E���%&�s�Xb�F~�T)���yR����c��a�ʗ:���U�ӓ���m7��O��{Ŗ��+�����.�q"2Z�u�A��.�ħB ���.ǟ��lRi�(�;��f+�8�y��Ѧ�c����x~[�cHI����QJ��P.�C��LD���\�M��������yX`��7�H����E�&|�DK��4a��"t#f~ɜ��,g������a4�(G$~�ˢ|��;��%��f�=����K�m�0����(���6��T�^Ȳ�����l>k��W&-̍�4�e����A��P�#��7�!���?
-5o�z̍��]�b���T�OkJ�&'|S(�	5:�]"�Ȳ@�V�)���Xc��*,C �����e����OBD͟�b��蹐Ǥ�O�O�´W$CC:C�u�"%�yYx�����^���w8m�x��]�w3�2�s�����+��V9�k4N*�d�ugj=�n��=��0����!dQ����afh�N�]�t&�7�1�������j	��*�n��ǏR��sH.�p[<l��0�����F����D��H�{S��aq9v�
-,���]r�+��$��+���q��5�R�o �M蝋�Xp|	��������%��Ul��e.'�0��)6�`{��b�g���4�~��D/E<Fk��cu8.��j؟��Ъ(jM������#v�H.e��@�z�����
-���y$���ǘ�&�K��<�( 0�����_Q���<�L�/��A`Cnp*v@��L���i�	�?��,7����������GC*0��րLӁvKM�h
-�5n����;��	�[o��̓uB(�����.�&`�(��x���F�7�rs�7��u �q��ĕ�J��8�Y���Z���~�ٹ
-oi����l\2RM\�<G�F�k�Ո�i�b$z"��`���ӂ��:s�T����'2j������������ ����l՛-5�WP�?a�	W�ز�zM̫�55�GM��.k�Uj�k��PM�;��f�8Y���m�m+g��r3��)����jz�X?�Ǆ\��ú���Ds�+NZ�!��%�T>T�U�"�,wT��G����X�j=v�wl��H�ET�+-����1�uL�pym��a�S"�'�R��0I/�ϓ������i>L�;��[j�����V�tYL]!�Ua)�<v'u�`��7�3�n%-���w*;J���ӊ�)Q���q�ɫY�t>��5X��}ˆu8�\�|E�s-O�Ui�U@ͨ�]�oU����\�a+I�ߎ���Rb���E�r!�������Z8��F��3iM<Z�S#rEJ�̹������åՌ�f�T�Q���no,8���V���.T%P)�l�h�fP=���3�W�P��_ʍdv^Ѵ3d�Ɲ!lΟ��e��~8T�vY:�@:�S�� ~��F�kJ�0�։�Cޖ�wg�3��e+�����Q��P���!�G5��×�:5�8^$��ԗ�5Zw�F�"��]<�]��r��8%�abK��+��� 5Z5� q���� ����=R� /��8����/��l�_ȁ�j�5���PA�Uq�V�s3^WA��m��D������'#�`�P�d�����2�\Ɠ� @<��G��Hh�x�p�򏢑D����
-=�
-qM�1"Z�/���+�F�OEoTD�ۦ���k��~�抲x?lc��(��+6A|����e��Ć$�ľef9��4ʘ�}�1�0X������l4F�!�{�x�-�-3�t>v{��2���&��D��OC�tl���Fc?{�BK�"���L�3��Ti+�M[B�[B�qٲ�S�hг������T�rG�����L�J�,��	z>�f��o���!��N�B���&_:�O�ԕW�(4O�L;��4.BiY������,�)M�i1�ż�[���T��͓�n��"���a�h��&q���q��*R���͊�*��܀��O���O|B�$�+9.&���
-��L=�ߪ��۪׹����<��ny.�Mz>�=x�#sVK��[�sk '�[�㟪qq��#{Zoz�FR�Se2�`=��}H�2^��j�2^��j>2�$������C͇B���C���!c���aS&dZ����DۘO����X�`BM*�%��_=�ln����O���]$J��t�.=6�&�LM�ٚ�N]o�ԡ�w\7���|��|����ט�׀]1�����Xc�?��N <5��lZ@��%	bGC�xr�H��&�GCMp�<f0�<�̣�k<5	ՙGB�pSä����== S���>&�����~��օ9�_H���2P�O\AX�zJ8���M{= BYHԬ�� n/9% ��fr
-���K�I��U�����'cV.��	kh�_��f�U��cg=ڎ�F�cw�sj4��8LC��PlwU�py�Dy*����ib�]P[�Z�x�uL��������
-�Ǝ��+:���X���|b[��rW�|�Ԉ_'�ĕ�9��}�M�AN%�".�ة�S�إ���e�nN痽�9����n�ȡ����v�?eT�"�PF�'�-�#���*�L��WǼ��f�f�]W��FhtVu��	8!NP �}�;>�CS��*+��*���yF+1�rF��]��*����p��8\�<\�|��N�'O�7���SU�SU��iV�9-��ּ��X��z�v��^��^�|�ގT%�T5���U��U�{�moUroU�!z;T�<T��9�}^�������J��$�j��魽&�^�<��f�$g׸���U�U�s(vNMr����ɝ˳��o�Oif�v_knv���d��o0�7���7�y2Dq����Q�S�Ķ2
-��4�!�����n�� Z��@��@; �r� u��vhq�N -q}�W�>�R7�. -����n�� z5h7�V��� he� �r��ky@{��1A��4�+�	��^��9tMv����e`�P�_�@2��`��o�����p��V�2�v����^����A��	���7�����«o�$.��>
-G?.��,5��45llG����h�_�m>jd�b@�̳��Q��>JI��.�^Xް��CP6L����J��_��{�����!� 
-\��~>dl���C�B���|e����(/�G���E�j5v/z�8�7����럅5�k�?�6<��H�j|2^��*�|1d,��j�:d�: �5�,��;���R@2�M��n�\��|�K�1�<�g�X�[f�(W�������/���R��r(z9�1/�
-�Clk}X�(���5�-�����	�n�����|�ŋ,�x�[�2�꿦&�J+K*qUX�b6�I�' {
-?_�猞��I~��,݊˩�w��9���9�%�Sڥ����-�0��ع% �������Q���J%.�->q����$^�1>f&�����vqy�|R4�|�ڄp�*%�!W�{�����F@��i����Fz .�~`b��ѧ�Ң����"V�DdB�XT]�%��o*qR��8d���  ͞ [������:�g�ɭY���}N-����=:�}F�T�t�#��w���}b�lC֡+�w���ր���� r�RȖ�%��]"��=`�8"�wPH+�E�Kp��5�@(�;|0�鞞��IӤ����>�6�OZ\�|��iެ��J�c�J�֫�X����؎;�~��:�:��޽�	�t�dC����;m�b#�H�J�n���ͧ�)/�b+���E���3#���O�۽c�N��odB�.�	��`�$�S�|*�^W���̯��a�� ��X��U��,d%+���]���5t�{w�Jb��Ġ��t1��T�)x�UjJq���Pr2���ӝ�^wm��2��<\0�~��U��:�W�&�u�	�䷎8�CƿCų-�����R��Ѱ���Ȓgi����t��z88=4���Ͽug�x��1��|m��q�8�Z<y�^\�����:�A&	ǽ.�K��aJ'&�Wz�5���R��O*��6�K����V?O3w<F�=�4��b�^ѣ�k<�[��+�����n�+�Њ�|XLo�;�RD	�q4.�h��:�CPc��j|=��8�/g���]P��kc���l�J|�;��jc�c���vmzQ�(��.G�D�V0�����Ld&�9�0����?�3���*��߳���-�l8��+�����_Ac;�(͟8�	S��G���@�����2�K�+X�N�� ��ؕ�Ϥ���'��0'���9) ލ�=,sJ WՓ闆�Y�+���� V���'p�~!���(ٜ贛���Ǯ�%IP��'81%��c跟�n�W���?���Ǹ8���!��j�Gܛ���.d�g8-���z�}I�$^,pN WC���U4�̂�l��P�U[��gS��&+��3��r3� �����m{BC�'{B�-��2����C$��:p�M�ց͏J>:�y����c6�8tPr�����|l`�C+��6?>phe�����7����ħsO�`f ��@@ H��Ȓ���$��1Hbĉ#k�<�㝝�%gwm0���.D�uR��$�:y�"�������C��C4E������� )3�O~���#b�x��իWU����Kt/H�;�� �}e���╉���Jt_�H==�xu���D��I�k���ɹ����3r�'���"H@�1�3f�M`��7���M�k1���S��T(���¸��@��6(����'����u]���,��dSW���:!<{g^����7s] Ԯ���S��f�R�p)j�!Z4�Z�}Zwj.��ܐh��W�~=���y��a
-�{F��í.|�/#ЏP�C�q5�/��w�!e��B1z�5=4U��G3��p�mŽ�7$*�qI,zg����� ��� ^8�B �;�P��	�j��r*����{æ䯲$�1?(�o5����%RƤb_���D�2�xs���DjhR�T�&��>¼��<���0L�U���*Fi����[��Z���gb��[�Oh�Baܿ��_�_�ïh���5��[��Ĭ���[��&�]o��'�#4��g@��b�f��j[.���쑬���'�Y3���!�A��Aݖ������ݷs�v��R�M��[���mͮ�a�Wa5ɧ���.(A�qrM)�zz�q�j[����KoWz�U�e���%|�-��|8��[Z{���^���VΈK<��JI==��S�TD\0�8�3>���2���m�<m'���<c��b�=%1��L���C���l�<�*�1ߖ8�6c�>kC�����ęR[�a
-��ޑ0�w$���2N��KÕ�bJZ�P��g5����5X�J��j	GE�8(K�j�XB�K�u,���c��J�l[ǘ:������c����1b��ٶ:$�1u���5��I�tO�eg}�L/���Z���&L��1Q���_H�{��œ�贱�����L�梀��ӽ�\qӼ��z6A)�|}���!� |#���x�`�Ҧ��@s�ȗ����;�u͸5m/u�X!��,�K"�{�La���$�M'5�&�f�8j6۩y`bj6��f�E�hlԘ��Vo�����g�,����>�N�����-��;�+$h�X"6���R�#�~�6�/�˙�^��Oz��J�p%3�I�����FpZ��Tv�֨�b��'�2��xue�r�D+V�5�9��S� U�E-R-�:��AM٠nb��WL�8�a�$�\����ۖ���T�����t���.�����^7dG
-��J�|��_��+0�0��?��?86�3������h���	Q܄�0U�5!:&�3������.�c�K{�8E��oߖA���4�~F���n�G'`��L�DHl)��\Ǌ�Y�ɀ���@�Ƴ�o/M��iyM�)EHLؕ��`�?k���&l���z�E�衟����۸�c=h/�u�������Ӫ���Ga��{Y�gnY��л��nt� q����AJHoJ(�T2r�@����^w�����Q����s�ӄ��VZ�/Uf�S]���di����Z1&�F�Q����I�?�Fuu�����/"�^Zh���e&���q�Q���	H.���	�����D*�Zmi�����l+y��Ӱ�V��O�*_�E�T䫥n
-&]3_�� �TBp{�!X3ċr��l*>��`x�O��a���Elӆ�>:�m�Z�/�:m;
-�u�wټH��L(�5>&Dq~+�9Z/,�Ԛ>Z�t�[�ڢ��7\��7����_�e�^x~jz����.��)�_7 q?7�9�Ѱi
-g��Kݟ�6�8�b�8���������w&RoO*ޙ�+��3�x�lǘe�����l�%�U�cX时����_�5��y �r�@�ω�_�@�'��p�D����7ѽ"�	u�\���������t��fV��}�`fe� @�nY���� �GN����W���ESq��Kx�Od����G�O�{�����=�g֞�T�S��Z�2}>�:�Ew駘_�ʡR�X	��F�T)�P�E�!i�j*���QF������<Oqm���D�ؤ���u���I�u �Wu4�2�D\������*�V��|�<'|-�r�CȾ��}>>FT���і�����)�ZCT�����	ڔ�N��^YV\��ސ8/�ې�~�&����C�5*z�B����>e�K'GGkW�1-�k�r#a��U	��Ej�q�X�^�/J�Wb�}�D�&��e�M�g&��*��`��jky��Rj� ��0�����Z�e��CƟS�!��!~�[��v�����Qߠ���UW#o��|�z�U�ѯ����L˨�p��V�y_G�߁���2��ǒDQO�g����K�;H+�o�?�V����Z�&��$Qܓ��Bӯ�����o'���`�mw�	\p������_Hx��BF���M�hug�'�@E�#|k�c^���@�����&DSxe���
-E0�#��]&n��2�BH�/T��X��^(�D�1@��@g�g&7����N}"��Sq����T�cۀ������	0��Ú���XP��\���E� �����s����[��w�&F��~�EG�&8N8�塊u#�����iFY��TZ�I��2[z�u,��|�	�L�_�H��sHb���z�a�͡ei��;[J'q���!@,hU\i
-���V���=L1��!�C�n���7(�D�ZGc��"�#:�X5�D���V�%�Q�VPِ(���գ�����Ч�D�j*%�h:U}�j<�"J����u��;���1H�ː� �A �0��C�Č�2��h�x&�0b��o(�	0%�B"Ua��p<GsNDF8���Yep@��z��,��=J���_-%+ޮ���1�M=>���v��
-�2N1�W8UGbC1MRS�b��G�1=F��4�i��1���j�7k�G�?�Z���`����Z��(��8U� zP��b���~U����!�y'Uo}��]��*<�<b�
-�0_�����x�DC��Aq�Y�	�G-S�@LC�ʒ�5H�x�O=dJ�*(�Em�۪���d~�Ɖ%����q[��j�U���=�GĲB��X+ɨ�M�x^pc�i��O��7v�'x|�~��|�1o8��M鯶�Tm�}I�6��$!�R����o��[����3yP���>�ă�!jX�؞�$ނ��y�ٓ�L#Sg#ɗO�L�Ş���6�8uRuu�ռ�#]PY�c*c�p��$�u�B�T�v��ZS��w�����*���B�I��S��U�>$�v$�M��VR���&�{[1������c~�s, c�e,(و���Mf��	���q�/����'l�t󮾊� `���`_k���3o7�]`�3T���B�L�Z�{9$��e}{�n��SD^E/�pC�爜գ�㏜��E�vyC�<1c˫�iPsh��Ikԃ	�z���,��19A�C���4"�f]}κ���ʔ���w�i��~P�Gc���F��y1b� �|��>P1���uz]vCb��3�^�����^bT4雨�@�Pa��T����,i)8>+N[�j�����h�+�q޾G��%�C"��>���Ό���I���3O���˵�Z�T�Zny���l|\#��O>���
-��P��D@��0>��gF�?&�"��Q����<�khW�P�և�*�:�Lh��u�Ӻm,�cQ�UZ��h���h���'�:�ZG>ґ���G��$�A���W�WI x^�*���C!3#d�a?a��!i�e�S�O��/p����+�ױ�̫g��b&�D�n-�j���2��jpX����y�T{����2�z�^��u aħ��WP�H����#��Cj-�^ h���Å���
-ɪ��Uc��X�N�U�>MG��hU���A����T�]3�R�g_u��S56�Lj|>��x����g0z�I^]3�%u����K:�J'Ry<�3�ֹV썱�������2�$���ȩ���+	\��c��Ӎ��3�������������_=:~b����Put��1�/�5o�6n��	u�	4eYv)[򌏎�e��@�X�'��r���h��˝�(�P��*b��C���y��V�����I�2�[�0��Q�ܵp5�JY"����c���/dJA��)� ��N�*M��.���\8���r���x�H�X�b�;Ɛ�1�i�	�O�6��|������e���a�@�X�%r�b�Y����ɚ�U,aK��%d�R��}c���ē�
-63�"#��u� XPW!Y���e�aR%@���=��P��)�jQ."��aC`�j84�y��dY�C�^�w8Sa`��t%�
-�l�S��a�z�GL�U�^J9������G6
-zQd�j�_L_�k��Ӹ���0ADg:�Z��;Y�& k��V�!��+�k�o�.L4\��7�s �_)�6PTZ�¬�m%�ba�%��l	#�X3l	C�8�_a>2
-���Lߴ�'������J��.�-}���{駴L�Q.���p��,~V�;|Qn%�2��=����by��b���+"M���E�۞V#�j�i�汧yE�מ�i>{�_���i���EZОi!{ZX���i�HS�i�H��i���Պ4����茫4\�s�i؋�(u G��`:u���<5|�=3������_cO�n�^�y��^tnS�?#��JN3iw,?�y��%Z�g�\ݏ%�3OLMl�}�EK�k"�Θ��~$����*�_�W␭ģV�CV�Gه�vR��Nd�*ٵM��k:�*��É����ݘhY�G{�M�Ͻ�1�}B��z_d=�0�;���>VC�`�t^>�����/z��
-�e���2	v�4���M��I�R�y���	=��'�T=d�8=�}<���a}Jͫ�C�����JQ���G��
-�bTz�4������%�E��c;�!������z(�x"��I�A�u���ՔG�,��P�Yqvid߉���
-���x�H~Ʌ�"�/��^�� 
-ԣ���A��|�x�[�ΠGt_쒓�:n.\�9>�/���������T\����k\0Y���^_���ώ��R�8Ʒ�e�+ޅ�7h����8��Q���{�|/������Ra <�|�5���L��a��h�\F��n(�����K܀��íŁ�0�M��Ļ�����{���Y�ߓ��Y=b黧(�#�LP��?�W 	"�+�
-����ڑf����6�g4s��J�]�֕+�'��������(NPc�,
-�
-+���M����M���0P� vU�,�������@�棾��¹��n��U�S��� �2N2��z��sX<��Wp��t~�7��?L���o�/�������s������g���K�[48��&wr�ڦ!v#����7"q��(SV��!�9zG�9BKne��΅ͫJA�Ԍ� �� ����4�{	$�������a<c��/��3˷��,�Rw�L^�R ��<LP�*��»�H�sb��u���_:��~S������R���.Ա1�jo�ˑ�0�y�U��C3o�k�\�����؏�Xg�v$�7��n�,�<�5��y0a[ZcY��#��F���)lSg�Tx����@o��+�+s�j����罙�8�MoO���)
-�����S �����.<�.6������eF�a���8��W�P����!Jou�\�tᅹ�oU�����h%v�S�ȝ�z�M�L���S�~6�_aM
-�;>��v|�#�'��6c�hwM�7::�*�"�E������6[�s�iձ�_�yh���iE�Ƣ�h���#{�����>�>?;r���w�$[�1va�[�ԃ��S@p�+��_gn!�?]����Ua����r!�x�	���]�
-��OW��g ��]�)JK�O�[Ȣ5%�#�����|��.!+\čt\)�4�t-��D�VxT��N}U�0�`c ����>а.�N��ԧgIǓZ��|��6�j�[�����<�Ҙt�
-W{f�J>��t��e�A.��>���8��M�T���U��HZ8��	|NeVԲ	����q�7����6��X�HN��<�4��M�d�&Ӽ�dn�^���v�Vǌ�:� ���s�6�����"�p��ߚz���J�6��G'� {m�q��[�ͣBs�L闢�
-��L�==:j�?V\_ҦδM,Cc��������@�!�:�/C�&��fR�ю�O-j{kr�)�\ՑK��;�ٳ_�k<�Րm���#����4R٨��R8�""��MA���v�B����VA�W���F�͂>�`�*�3�ƚ1+�<�š
-��e�H��ʌ�	���f�t^)�,m�y؞�߉I3(�L��FI����W�.�t~�-3�c�Ӽk�?d�hXL��1��[�����w@x^���7Z�9��u��pK��}H
-Ԗ�b;Va���|�~�����
-r=e���x+��i�g� ��(�w�)�l��|[3l�:���{��[�唌�Y��P�0�b����|/��9I������r�b?���G��dl��X�?y�4l"B��긻��$��+Cє�*K1	���܊�7��ߦJ��y�v�̕����h���&�+N�\qNA�_p�ŝ����Kj�l��sR�H�	��(Z4���m�t�w��2�o}��^��楱��-��9� f�іsOSz�d�ba�x*�h�e�a"5�k����*&�`(ÖV:�RE�D���Al�@i<�r��/#"'dE���<e*a�#�Oג��L3�2��R�`�ˣ���>j�VF�9���Xu������*���x��X���[)>��	s�i�нh��Cc\�eiܞ�
-|r��,�T�%����U.̖IA|c��R`�1�˘�'�GUe�꿧ș��&�r��\)��,�-�L�E�t��9�pJ+W�=]�A� ��>U���f��k?��1�]��>Q��Y����,&��ǡ��K��C^c�0b���R�x�{����b��]����ڼ�>�^q*� ���7�c��8^��FYa*�w���Q����Fׁ&kuQ�V����AvV�$�F�Q�#os5�����`��k�~�`�@���W[� )��aaߎ�8�b�e"��p%��T�=P�=���P��-�cb64�I?/�|z�\P�1��D�'x�ͦ�<lzh�>�L�ԏ��K�3���8sD��	"��\�6�
-��0ID<���{u1���R�W\�w�.�����E�lPD=��[�`�*3��'�lƞv83�2�o6q���A�%|+dG\�p�VX� �`Q�|ډD�3�_�;�l����Ͱ�i���M4�q���*iR�ї�	��]6P�3��R�� 8���M� //��W4�<MofG��w$����eZ�����M��[�5�hu)?u�lu���F[]5�p�����.ksyu��6�o���6��kN�+@��6W�㺇����Yލ��V𱳬��f܆�W��Y�u���~j�H�,v�#��z��Un���f�u~ҟf��>pi�J����� [����`l��h B��FK�O%���g�]Vaϙ���b���YY��iW"��d�¼���mn�pE��v&,c�U�����ixH|_犍g'{����NFډ�џ�"�+��b����7���*Td,2#�9$�U ���s��͘<�]�����y�a��"e��z����&V�h���n2һ����4��Ԟٝ��Rӻ�Ll�l�k�? ,�?f;JRǄ
-9�3v�t	ge{6d��Ǣ��c�+�ı��4WaA\�U���,��*t�,tQSq5
-=�g���{�����D��DjYcq_�{"ugcq��@"uwc�@��`"uoc�`���DjEc��|��{�6�C�kx��k¶k�=�k�8��`�8]�f�X�ISSq|P3�F=������\|q�ǰ�I�^~|����o���az�uP|(��Ґ;2�j�c�C��C�1�>��kڬ�dKD�"�[D��Z׶�\�w�m�~W3�o�ge?m����OXٳ#&��Q�L��6"<T��#��e�lFx&\�S(�ŝ9� E�ٳ��ф�x-p������W���0rX��[�J�ҟ~��=3�������[(��6����1�r�D�HŶ��Ď����a�[Xؖ>�Pr��~z7,��r���r�(-� ϋ�{�f�P���gǧ>K5�P���a҉�3�vv��)�_R�rsG�{�,������<���+c^���ɘ{��|c+��+d, ��M��#�`�=���������l�k~:J�����%����됸�C��*��׌�GVk=�s�2��V�z72��/hѽ��+[�SW�t�ߊ���f,�C�r��U1c]q���Q:.���1���?wDLq�I�U:wUyam�G��{�Rdi�q���4׷)T s�v����[�>�q���h�SX��R�	6�;G�j�g�"*�ȇg���{f������4��N$"��"Q��u���f(����=��$D�'�m��r.�FL�d�^��H�gk������([����CT�a(��Wء6VK�׃��|�0�H�2�Pp(�^&�AJۂ��@CQ0���c��:bη7������s�5�qv��K�^Q��an�62���0l��D��"������ 
-;Ý;�xճ0b�c7V'ӟ�<����E�	�D"��!w�.�X�D�	9!�`!��:!f	��@t����D�����@tS�����%�>Q_Q����#U'}�D�N��"���LӪ���%u]��(r�}[d"Wz:����Gƙ�� ���S� ��a"����!H���o��~�Y�[�����D�9|0bN��k[.�Yq?oF��o٫�(1�9��Q���D�ϊ'�?I����$�?M��\�4��Y����gl/�Iŝ�H*�}S� ��ˢ�^��ô�7����FWD�]\-�ѣ@�2b}=�"xY[�=��d;������e)����R�3n���[ۊG�ϝ�{�Ȟnp��c����,�š0h�^�<�ܲ�s.�9��ڎ���Ўp��mm���v�Mc. ���]��h�"������6�� A;�
-�D<_�7�F�c��}�?F��B��� ���Q��(�B_8R�|�H�&"��pjaKᎶ��?5�C�����U�C��9���Є�Rv|X������j��'&���u��A�����;��=���G݇x���X��U�o���`?��S�N�'ׇ#|r=�[~r}$�o�����,R�T�>s���T*҉���G#_���ۧ�O��JO�O�w�I�x���U�(�`G?΂����������_$RO4�Ht�L�65O&�G�-���Dwo2�Tc�7	��q
-����D�4 q�m�4�y��'#��%��?U�P�M�rȚ@�-���0&�5��l*4ٮ/Kv�N�����ݗ'3j��s:՚����9��d�\D��잗�.m˪�|ߕ���"i�GpE�{A�`qA���d��d�d��T�Su�Ov/��E�,a�<	��9Vh.�`�#�#%�����QqG���Sq�A����0�wqX�p?n�Y�^d��	Hw�g�� #�lW:Ut�QVt�DW9=�e����#Rg�d�i*h&ɇ^�T�n:+=؆�XO�P3߰�oK��P��H��d�s3�%s�7s�f�$�3�̩1s~R�
-y��q����\�$��Jb�=�Ʌsъ��e��7�e�H�Y�@��*�:IOAgSK��� ����A�p�ûh嘗�Z֦`3�c��$^u�l1�����F|���K�,�a=�_��~"Q��3Sx��!�>27��7��b��}Z��1��T�(u�V1=��8$2������-��l��C'�.�#�.�~��/Va��6����*[���c�j��ԉ�m�g�o��N����݀=��c��:`� ����߂��������,��� ;�	�ς����yNأ�|�Q�^�=f�.p��͊��{��8��t®���8`W�ǵN�U�u�U�]X��.���,� �͹��f��s|�������[Ԗ��[T�?W*ܭv-��9'w @�u�z
-�AV�$��ZK^o���X�PM�$n���>n�� ����*�}����*��Yb�k~%�o�����WZ���Q0.�
-���˒7�S�U��"ſ6�xi\�/����n�ՙ�|�T*ܫ���W����Ra"q��$�E{CCFK=<Y��s��⍪)�/8u��撃�gX���)�=P�X{���ŝ�?9��'���| t�MO�� �RQ�X`��x�x�=,&Gݜ���1D���D�}�~�[9����H@��O��㋝�BV��uI����������-���z���H^�6y}ӿ�׫���ް��pg�x)ޤ�@�2���{,^�x}���q����y����>	Y}��D�{O^�z�˽��òw��;=ȩ���!�;f�G����!z�#	�j'��p�úZ�DU�8�-�0iL��kaR;E����]��k�$�w���<ޝ��D���ip=-��2�����^�8�v�j��dILn��å/t�*-u��a ���^��|��_Ŵ���.�4[�W�\���	t.��!h�&��Q	�z�jê{L�����!F���R�I�����!�w��_�Ψޅ��Y�6�V)+��P�� ��Zo�������*.�MV��l���ڰ�^h��l��[I?ި̨��X���@Ŵy8 ;�̔���jx��6�Ȥ��dd9:�1c(�ҖLeٛ��6����d��S���o��J�f�$�D6�h�HK��O6�h�H��l;�r��*ԫ&��Gě��n�)��4˩�;v`��0)`q+hq ��qi>��I��`b;^N㠡�qP������Y,
-UY$sL�,�E��֫z�k|��V�yճ-�c�Nө�2�*r������2��_a�e�kr�_"��	='~ք�V�k���0\3ej;k]����ֲ�ꕠ�KH���EI�D���}�g8�J2��3-���9N`&#�� f�ʌ]��Kd�8���Ԕ@�"Δ=�*�����t?��IF(�TH+�x�e
-!��6����<�m�m�94��s�M��18����:o5�-����Vs�q7¶���~�312����	�5�0�!Ì�V�_�G�@����R�a�%eX,����J�b���z@9��=�E9m�[.��|a�ԩB0�Nv�U�1s��tos�<��ES��8�5OV��5OV^T[.��� ��M��ėk�o�F���K�S��v�o�%�`ߐ}���qJ�U��H~�TLQF�v������8M��z(�#oJ��ț�������¾�&+����#���=�>D�8�h�QlS�k��OJ1r��";�c z���^�=�7@��MI]���-{�����kEA�5�'�8{���"�k�����wٓ�p�������ہ�)F�Ǒ�4��u��5���M�7!�k}
-����Э���]��oEG�u)}�S*�xJ��n� �B�z���T�wK�(@��{=��ޱd�>I�j*~�~����$S�5oKvߞL=�/�";[t�j�
-��?7�B��RN(쐹;������.a	��c�c��c�o��a�7���̓��'=�9�Ex�w۽�h?V��&������qIp�OQ:�M�'�4T$�ia���
-fL*ܞ\�4{�VX������\��4�U�e�a��c �#n�p|\��4�W�-el�T��l�VYS|O���� �"]�H?�"� H��!�����i��SEz#=�U��7jQ�	(�,Ze�'`��*�g ��� �T� �ܨ�V+컥c���pF��tv��ǩ����6� e�9yoncܗ��W��¶!h;sBg�ـ^����#p�7�˦����J�^����J�˴�l0��C���eyS+��y�~�s�b�����6��v�@������hE�Ҩp9�ۮ��h;�� '[��2���(��ʱ�p�-#zu�C������z��'�J?�����SE����h~S������--�GE�֖�c"t[K�q��%��C٣�:�bTA4}TQJ�w��b�]�=���<خ��[lW�0#7�����+�"��K����;Z,Ƞ�A��
-2(t� �BJn�x�<m��eʶKʶ��<�vgk�ywn�Ȑ�f�^X�V*\����v�w�H��PS�v
-
-�)�L�N��v
-���0i�aҾä}�������#�I�I���k�vYF}$
-���h]׋R���<�4�U��t�CC��GDq�Z"Q��-���w��ݍ���8A.��0�6�	����5�8҃<����wx�4��q�ƚE1�Ł�.b�F�jŢ��#�H��#HHڤF�qQ�rM ��;M`Vw�lkDW��V�Yl�YLZ2�Օ
-���"��Ԯ+4�œ��uQ/Ml�6D]2r��`6�Ӄ�IFM��3n��t���c;!� 5|��&FN:!�^I���Z#�dGݳ�(.1�L��v�73���QaIs�p=���S�:[|���`إ�~�������*�RE/m���6e��D����L�ǯt-�pA��QKfw��;�(��]b�P�n1J(tOKn����W�	9U'��=���_�AL�=8x��D=T�.��s���d}��d2���B����m52�M�1�W��.��v<U�������u�$OI-N��e.U$3����,3C�����0�FkH�~�΋Z��T�~������
-�����j��=UP�
-����'�:�eqR�JV!*0;�7/T~�[*���~�Px������+��?��N�)�#�}���N	��$��q-�����!�iٍZam�s���n�F*�ܓ#�m��@�	��
-��
-��Y�z�����PD���S�6�O�P�&I��I�'�J�R�}�O��:�UP��S�h�:�*��,t\�3�Y7:���K2qHewD�m�Z<���G�h�@�K!	�ǐ������Tx8L���9?�	?���R���]���S#�
-�:�6��`�� vK�C���V4�xP��^�^���m.��2H���t�_j]Jћ�蚶�����ȳ�޵�M�L3
-׷�E�|�7��*��
-g��*�;5K8')����U<0���������:Y��`p���g��(y@�RS��X
-��~��� t�v�s��.�S���o�uԀE� LZH���ַ!�]�ͮ����(�E��?@��UzLjK�wԈ�9���� �QUα�i�,ߧf�ᓋ���&;-.��h���?���F�۹�	�˧����^\����܋3Ћ�˒�m.Sd�D������L0�GJȭ`������+�ɏ��7�|�0Ks[t,<�fjcA&�(�.��p�^`���!<Iz�����z~v��Y��l���%�������&�_�{�4�vi̱�RJT����궤��`�Qw�h�{�����^�S�Qŭjb�<@ڻ�A{߃�Рݍ�2+ʺ�r+ʚ��\a��<�ս��p��t�RC�����]����tx�h'�>�����J2����!�F�_����u���߶)��p�.|����WÙZ�M}_�S��S�:����?�Z�ř{�������q�{��ſj��ߧ�dt�S����|6OWn�����V����W2�*���??� 	��XNo��.�j'�S�ƙ�4'��L|��:������q�:g�]ϳ���	��np&�ȉF-����M�����!�ԕы�������K����%���Ԯ���dw2���؟�H��6�݃�����`�{Y2u���,ٽ<�:�X\��3�:�X�3�}W2�nc�d����o�w'��I��k,ޓ�7�z��xo���d����}8;z8�8�z�"�1I|OS�v�ޣL����Y�L}�X\��^�L}�X\��^�L}�X\�s��U�㲆YM�;P��h�e�Q�����`~���,÷��ɺw����,�c�U0W�Y�.�։`��}t͓N�\�Z7U�r�V��F`�Iۛ(i�U�����&*�������r��n&����)��`Ϸ��I�ͭ0�8H���z��yB�U�4�(G�e=���Q�Y�g'����)b����	p����2��M �Ҹn:E7�-|-��`�ps�d�8�w��EO��`k���	tu�	�D���y�m<K^u@lj��!�3�u��;��dāy��~�̙��_w`�<A��p���~����艷�,����� ۊ���ۊ��� {
-`��`O�m����`o`��q��k��G'�<�a�ɴ������DOp]����̍�H�����8� �R�����r����mXn9*L?��[;��t�9'蠣c�Z�%������Y?��X"k�*��Y������ϣ#�HzI�I+!<�9;h%���#�������g�!(:�^�GN�� ��l=���	�t|ꜜ �٘�	`�;�6��/�`� v'`�6���ޘl�p�#�e$�v$����cd���s`%��u�� 6/f����K���O9�7W80�k/�bg<M��+M�;�r6���f��8�p�ZX`�9�� [� � �z'X`�`��'ث ��6���`C �s��f'�0�n�9f��Qnu&�Ɖ�9_��۝�op����DՋ���}��X�x103�B�1ե��o�`���@�@���x��dŷ�����|҄��9?����\�B�5Ԅ�؝N��ܠ�8�l����f��yn���#=߭���c�GϳA68!�]W��06�y-�Z���Z\A���p�`�,��r\*���vT����+�}��&>V��ѩ�Y3��R�Ǧ�b(ƫbg�su̡篱�kSq��`��6��s��_��u���U���b����c��!6v��܁�;��U-�mm��S�����To�LN-Y��-��$�^	�+��;�TE�Z;�b�zח������z8f^ry,f^r٠�\�ߊ ��y�e��}S����^\�쭱qp���X)>2�{M25�X\��?��lr�~�Ϟ�y^��N�x��V�}�G鯿�80?(^_N	4�O�R�`Yx\�|D�cO3_m�]}����G���ظ��k��=Jq-(zn<EOj�hS�V=<�[m�SD��-d�	�s#S�E��*E��(�L/�����9��T/lXW8�%��o��}�����T��/�&x��J/�ҥ��P�)�H5bx�+>�?$�*�3 �� ���1�l����j|o�O���!���?���$����g5��	óĪ��8�\>�a��_�D�Տ����\�TY�s�����o�T�H���z���z޵��Z������uF����]c�V.�� ר��{��4�#.��rFq�T��V��*����*�\��^j9 #���<_Ш�翤�![%oU+y�l�J�"~�J�G%/hܺ�3h�1[�;����wr�-���E�ͩ�5Q�I[�]1�l�h,��&�r[O	��>~c0�(�>�D)z���q��s�*�����-��'6���ޘ��,�/����m����������E\����@����`�P��;<h�e9h{�����h�v��#��Z�o��/���L7J%�� %��e�5k�����x�ǋ?>����+��������_�)@�����Xz`s>}�/�ǄS;ɞ|��{�+5���,0��ޜ�����#�t���=��V{��m��Ld6.���ޮ�He��F�#p�C�^��1�1��[�G8Ҕ>b}l������ђHW4�?(�*Ba����s���]d�?�b'Rʶ��^ڏ�|gy}+�� %��,?�i@�L�x!��':�Ɏ��K#��� �����{+����=�JS�Ƞ����d���o�R8�������Q��m�Rx���$v&�r��vas�^꘭Ԑ(u�Qj���s����3�v= |[���S�
-=������0����|�R���x�Z��W��5�ԳpH�H�֓O��'��4�3��ԦOn�;�Q{�UW�Ƀ�?[�Su��o\�F!�I=QŲYby�MOH,����1X�H,,�SP�8���
-1\J��3�~�W��)ഁ�#5�I}
-bz-�FW�ɋ��5Zam�/�Qj�/��N�4���b=��V�����x?�Nj�������E�&EuL�#DQ���A<@|O-�*)
-3[1'n�3T��]~%}�������ؖ�A�4l��0�B��nУ�4	l�Rӓ�����I|��c��Jٹ2S�C�>� �dANr2`���%��Ͱܥ�Qp]����:ِ�FG��᳦�>�&���/ロO͇�ɇ8M*q���S�8>h�*[�)�s��U>���թZy��m�p[��,�M���=�ڬ�l4\��^�1O��Ѯ���^ V3V`�Z!H�S��܁C6Fs��B����o��eaZ�r����%����o�	��΋�4R��l��,���_��h��ow��`u ׬��:|��_��B``����j�aU�yZ�GU�5K}�K��ؔ���_�Ol:����*�a���UU�=�������zX����DE�j���j�o��/�*���w@{|�K*�Ur�Zɛ�d���7��޸}��m�c�qY�ꂷ�.x�K(9n�dvܾ��n�h�}�qy���V=ۿ���l�̉[-ށύ��?�S���u�P�w�vJ9�R�5�DM��U-|����Z�f�WĝZ���^qj��~�����ӕq��1Z�l�� �*�[�a�:��	_7���R����귁��8�q��d���ɕ[L��Io�u�<W�{����1����~�k[�Y�q����\�}���J�����J��\���'�:[�Z߰Q���*��r����R�=��؝;!bB9��byj-WxujU������R�}�RS�I}���F��mT"6�1�a���AآxM��{�-�-PP���[z�hx�:��r�Aâ��0
-KY��.O�6�#3I�w��s=�
-mXb� o�b�+Ja	�qez��UcG
-�w�fy4�I?9!��փ&� 0�i����uTs�Z�{�R����m�M���(+����M�V��Y�����COb=8�a΅�sa�9v������������5t?�m���u�L�=ߋ8�H[,����cux�`�/��r�����3وtyT�}�gH���a/X9��=�Z*�K�U22$����!�a�D8�
-��6q�Eg8p,5qpG Qb,�x���:���w��sc�C��<�\E3����{�G*1yiN���N�~�d���"N���*���=�4�����T�Cl�+}O�C~D+�p���*��-a)Tc�Zy������_f�~��[��K�I�h�����^F�n1�v��E���'<�7������e��?w�C�V�XȄ�N�\2cc�c
-�������l�?�E�úF�Jo��%U2�F�ќ�7GG�z�
-�_��u���;B�['Z�;h�.0�uA[�GD��
-��X�T[�uA{��'<�FD���#�dqG��G�MTmM<���7�=_���kY��;��I��o���}kG��#�ޑ�֑�>#�1#���sx�uF>5#���f���~E�$� KeEʠ��Ȟ�e���� O/�=/�`�~!�a�=��^�[�H��ǅ��^Y>��Z���~�����������/�nF>9�v��}Һ�f"}��g�q3513PG M`�T�'ߌ@K�'�cP���Y�����Wh���hz��>cV�C�أ_�k��s����C�h�z��Nf���4����k���1��C�
-��#"/&���u3��~N|*���:�8D��$�iԝ[�ic5��gt���]�mZj]Kj}��]��_�ZC��雤':�&)5T�&2�9N��	`��^:8�xe�-�v�cKجO��C�9�:��b�5����ZIh�X)li��_J�~W�M��pӐ�T[�ϖ��]*�Mm�=����4I�48�B)M9XDr��tJ�٣��q{�kz�=z���,���h�l!)4�y��)���~�))糭����,)1��y�g��i �_cI��:�8B�[%�v��y\C��hj8OJѿ#)J�z��=:���넉M�5'L|"��0u����SH�CK��z������]���%ie=8��H�&�*��R�6��M�$m�MҶB��$i�J�@�𤔴I��S���ݤ����?P֦7��ק�ӓo�����2�l_#�`���>��q"��Hٗ�fL)xI��?@8�����M3,�����L�6��04�� `�jC�lC�>�	����ɲe+�L��}%D�܆Zͪ���5��6�M�C8!��`�	E�]�5����پ�ռ2o2�M���d>�J��S��߈�e4`�'�����O�/K��>y �. ����$!\�Yo�'ɛ_�5ռ��X��`�-yC���˥y_G�ߑt��PG>�O{5a�j�6���C�����b.�ˍ�Am�{���Fƪ}��p;�.pV��&����j�����nv9	RMv��T�C��"����c���^{ٽ���~���D�!�co�T��Мw)�k�c��2ͺ^�"��c�-ĜMʅR!V#���wN���lad��	))�7ۑ��L�UM��kE�l~>DQ�.A���4왨��V�L*�캤������ ����NG��`�;R�6�X��`jYc^V����(x�R ���2��f��-q]3��!
-�]��!�|�l�F,_Yrl�J����� ���(7xO����\7�k[���j�|~Jߑ�v؄���{�W�F�"����	Ǔ���Ym%������ ��w�_u��%��k�� �h�ÆK�a�R/�A�Pb�*���Rĉ
-)�)�ن+$p�6�Uduc�Qn�[��F��ra�D輧E�u�S-t�N�'@�;-:��f��p>:�i���":?��?��i��j-tBw`"t�Ӣ:�E-tA��b|1��E�/\���v�;����?���qB`S���a�>gWc1&]J՟͊���IM���F�?'6���g���L���p�4	��O�2��ە~�����?�����F��@#�-q=>v�����������͡���&*��XW���8���-��Y~�����ڕ��^��'�BA��iÚ���+̉�
-�4fV�H���ЌW� Y��U���O: [+���K:/q�^���^H�O���Y\�.g�,���)AoA�l�v�ix&F�wKn^�~|�����`��a.3p���+ ��-``��I��[����` w�~
-��Y�Q�j s�8��b���(ΛB܋���{qra^d���8�pu�9�z3R͘�U)&�WF��\�Zv��j�N֓zb\�N����?�C	v2:4��	-@�y���y����&}zS�@����=^ߊ�uL�Ӿ�s~�#_ۑ�v����1���Ňݭ�Y���g�?֪WR2�.(��ӊr�9��r���������_�:�gn>1����<�ķ]+5��B7�{c�=�kT�T2��4��>V�C0��9�k�s[�-5��p�8�l�z�b;�ШK�M�Ae��UA�r�%�*E.��Z��6�=��:�|�M�A#n�&� �r�/���Z�c�9͊�vX�I�vR��`�l�L��q�x��b������	��j,�Q���"V�ek�9�����?*��h���«4��k���h�K�bcj��Ց6���q��o+iF���s>F�j�#���C���iw���Ň���jO>,?��vv2�iAq���:ZgyÍ�K��EM	ۄj���pV���..B�S,�)�����a!=!�A�5,��1|�)T��"bw�a���mX��9,�c�ň9,�9L�a���D���3En����尠�I��b&�z��Y�G�r�c� ����!e\� �z<X'��s����`W��#��F�4zx���5b� �a,�o�U���Dz��#(��~�cA5m�ٻ�U��11�b%��3"e��X�.��j��QUO��cUA1��4G���<�~O����]�1�3�U�5���p��1���6�b�����/kX̔4��jv��u^S�눦$��ߖn�{"^�m^\���AG^3h.�9b�d���1�����5��� ��^1��870Kr�VMV���
-�k�5��*b����A�,7��saЂ���ۈQȎ����yWdֲEc���G��媘�n=}p�2���=�O�i�3Y؁�4�W�ȹ~�hW��]L�$�<�ODn�=,��D�<���a��B7�iVH�Ej���~:�_)E�$���? �����&����y�e��0��Y��p�_����l0�.ԃ�:5���p�gH?�Մ��ث�D���՚��6�IX�ز�.鰆J����]l�ϩ&��y�o��+�;��Η2:�)�d�Ȅ2z�*�G~]J³ה������q2z�&�G~E5{L#�Gl2zd��/�#B�v���#���m��2:/2^F�6
-�b�d4 dt^Ē�+N%��q2jJ�j�����12jJs�&ͪ�!�Cw�B�R<TS��Y�w�R�=^�����E�O���R���K]���Tʩ%n<~���o��!���E��F�Vލ�m"���"�߃��w�qA�|�X�g�s��-��Z���xb.[�ԥ�L�3�[N����V�p88����0Ĵ	!�=m�(�����t)߯�a<){�x�w"�*7�ʐ�2,��aޓ���L�j�b ����ew�z��3���9�^�3}����D�#
-���P��.~J��g�W+~N#�/Pנ��e�X�mYw:��e��̺�/��%q����ۭeޕw��*Mşg���<��"��O�K2�e�
-�]�ǌ|�o�y���*_��}���l��:"%���F����!(,in���l�ls��p#�v���'x򺵚;��>��G�2ټ����ͻ�-�x��#�>�
-i\���W@���u�*���p&�����"�u����KJ��~~�h��,����s�a��j�2a��b_���ߏO9�+��D�#K�=��.^��m��ꌛo7 ޭ������T��!�A��<�����9i����d����d����q���\Vc;Ÿ.��b���GJӋwDJp��~[�QXǪT�+.���ͅ#ͳ����R��4�W\1J��>F�#�r"��w����dM��dMj�'�\�D�y�s���k*^�tmir#�8ņd��W(6b�J{�{=G~5F걖R�),�e�lZ?�V�̛M���lR
-wL������[�蛌(�!�m"��K83�FAJ�-������@�4�\�ToS��&%}]Da��^,����>�dVi����*MaC�|��%�.'P�ػ����7|*+�G��ݯ��5��^:�;Bs�cq8�;Wč}��ڻ#�⹠����뢏W��,y��5͘�{f.2�)�A'i齨�"x��/"�>������-�-��{E�\�/�H�p�tR�0
-� 1qo������T ���Ĭ 1O���|GyE�^�!
-l�X����Kͫ �[� ���� OU���6����tx��^q��C@����?㉍旡Ra ��^�v��
-ID�C|+a-����Y�`j۞���E�3�� dM���PS�2�º��Ӈ�8�w��ZL�q���e�H.v���;+5�TN?�����U��z<�L��u��ުL��Q�ֺ�p��w(D-��k�t�����o�h��	Q��2cz���4!�jFC[Ҥ��7E��Rh.�����IsO,�У��m�:>�0�*��WX�A)�2��D�F}�y�6h�hsv(�.>��
-!�
-)�h�8��+���m6�I�@�)���Z6e���$�ѳ��Yv��r�'M�! <8�^�����1<,����2S��y0�=����L�I[�׹P/EhI�4��`RZ��?�n,��l).F��{��cU쟚��|���
-L�����<5>���k��]�f%�s'��*�P���:X{*�8c#�D��H��'a��~��7�@�a�� ��	9CB��>����i����=kȈ�K��/4��c��P	�gm�®Ȍvdze����3���%>86�$%>d%F��ۉtK��pb�:�b�E)��Y��^,]2�IJ�`K����eK�k�(l�B{� "a�\�-Dv�)Z$�L7	J=M�G�8uβȄ��}�B��gZ�3�3-ՙ��P=�f=�f���/��}b%��%�!!�{?tA%�0	UB�1YvH����q|���q|���q|�K�Q>;����8�*�W0xb���(ٟ̇= ��?/��W��O��=?1�?Q
-�f	_?Fv�$��g�
-���;�֛�GGq�̚ǰT<�-3�w��rӍ�a�ᾊ�p1?�6wF��XMF� ݩ�TN�kVf���l<q���Ьh���p������V7�$��c��1��Q
-{�<��^��h��,�&��%�b������a9-W��M���_����	���F�~5g��3J��g���ق�O�U�4g�hY%ʹ��o����W�d�{�k�������������	eR���2�<�y,ėm�ŉG&��tP�pf	VVYt������w�h�}tT�o�t����ڄy}������en�G��)e$��=�Z�њ��|P��B�蟁Z=H����Dh����í��<�"kl���~I��vv��8�������|���b�Ps��o��>�����~K����%K�Z"N2�$�$����΢�oǄ�7�t���,�拱��If�A��؀�#c��m0`��]�H�a���m�ycޠ=�s��K�LHv��[u�=��׹�{��L����Ư'j��\Ve����t��*����ǖ�������Δ<c�#������K$��#g���|����e�\�l�r��l��8���P�/O��|��4A2O�	<�fg�H�l�9��)��x�3�x��6�B����Ir�4O�<S�]LL�-��GK��EKQ%�C?�]�Â��{��ǢX	WD���aS�V�rv�3�$X�h�G��?�;?a#y/��R�}KB�96��]�v��;]l����įhB#&�HfB�D2��0DH�x lՓ��SQyn���J_5q�CS4jQoZ��D�ܳ�6�7X��H�����D�J�7��t����X�v�sCY��\�KDi��eN�}��\`�b�ڿ����Z
-�k`堉����[�b��G�zP�55T����O�>ʹ:��)�͉L��3�e��=7z���T<C�%��J8�VR�����b����J%�@�U��P�`1ժ��Zvɫ���񭂛�����2-5f*��L��%*ۼ|eZL��i3�2-#_�j�J��H�&<Ģg����������*�d��wV&2W;xu���Nf��ց4��(ln����eR��L�b>�%~>U(>Bhޑ�o��ڻ�)5jW�Hj6��6�����[a��Q�
-2�X}�f�����#U[q�����HX_(ܧ�V���f
-��H��ȝ�QFE�Bwm����L�D�lGb�|�x!w�w<�l=`��Պ:���V/�A0fΜgq{+ލ�J�\���4�z�Q�vaשGr�yQ���۟�.��[�|���oIN�u8dϚvd����m�Ǒ=��%g���)N��2�p�(�����L�����0���u*������i�>��1���&��?��v��Ҹ�R~,9{P}��l����?�OY#�.E�J�M�Ƒ�5}ėk!�%�=\�۶G����T�)v���T\�[[W�jט$�G��Mˋn�r��P��>�ؗ�
-x��D���XvTʦq%1��Ѽ���j�l,�*��cq�-+Ƶ�_�)	�Y!�6Z�nok������@V���)T
-� �|6�s��\��[52���h\Ϙ�l�Oַ��֛:���m��q��:�Aץe����tKn���4��[� '�i��S�>��`�( ��k�����X��A��(v�K��J�Qoϯ�������TNT}�]�mT��Q�.W�*V��=�����
-���U,R�c���d���Ԅ62O�Z��`�ؚW!��Τ~K��8�`��:�� "6�"���ӇpK�7�3݆q@�0�0I�=̳#-fG؞0��*M$0�LT����<�u!�'��;����'	�E@����$p�W�1���j]>֋`�W3~%��
-�'-łs����L������/,%�W{��wr��G���Rcv2���7Wl�0�O׏�OӐci�Oͬ�>�k� �Ѕ6g��Թ##0S�:���h��e�+�/Ԥ��N�D>�
-��/J,�l�M�DP)QDKw����p�vg���z>�q"!��>�}~��\9�qf/|\m�$.�q*�X�Y
-Ej�bxY���&�F�P_�Ï�&/
-�b�+�ɢ?'��,���nf��?��(xO3����D�#6�H��6{���uD�� vL��y}�ǒ�!D��I
-��F� ml�rU�S��J�/V�;�x>��w��
-,m��~]B$�"la��!�����I�3b>�%�Z��_q�����<N�U=;J4��h����$������Qã>�F}aԚţ�*���T�ֹ����?&�5���r�h�*w�bv��~*��I��̻���;8"ùl���C�;A��8�=놷~~O=�/N�O$Y�g�.T�]P��#��|Bnax�7[� N�0:��s�e�}�Nt���,t%�m�T����[BL�N׽�\+`0`���;{Aqt�EC�VO\05X{=�a�0O ��i��H�vN8��`��-[���(�bm�BV��	��K8�~A7��Ã�}ѧ��N2i��z�s=� �B	�D*m�<p`�O1=>d?����s���+-չ��G|�t��By���7E��\\��ަs��nq�o�7�V[��+����|����9B�X.��
-x@$�c^�qN��#W����WZX����.@�[HP}0d5�,��Y�R]l����Z�0(�3v�N��o�@{���؅Vm�j�XI2vV׷�������0�Dw�hnSK?�Wh��^-��;��80bn�qK�R��T�㥪��$�D ��_�v���������Y����1}6x�>��m,L��T�M�&�.�j]���cnW�H]ԁ���7n7[�7+������]�T��1B�0�2U�$��fU�cX���b�X�Q�U!��e �v!�φu�+�&N����cr��DeZ��Uڞ��FK�F� ����G8�w� V	M��6�l�ɤ�!&�c�)��k���c�j����5�[|�|#�h�Qv���7����O��ew-�Έ�+Q�;�3�7�n*�V1o�]�8��0�Z�P�|�\xA���a/�`.Tk��{Ѻ���W��=z�ۆ*q� �1�$^}ZIZG�S@���%k����e�����Ъ�.Z�\�2��Mݿ�BG�e�K��r��t�YW��Q�K�5�˒�M(��i#��n�\�~��'��o���Z�]�$������V�4i0�r�l|��G0�ܧ�� :;'�P�Ͷ����-�il���h��C�_�� |f��4�7{��?42T�$~�CY"�����H�ra�f�fW&=D�x?� F��bt�{Q������Q>J���/��\�8��/��*��ڇL�K8�sU����{db^ g���O�N�Z�,||
-��	���+-��##�[G�P�~�9�D`!f�.��)�*��%z���Okh�*�3�l��A�ޥkLZ]cR1��C	cqc
-ʍ�C��X�1Fϋ1�x\�hB�;Ș��Mݑ��r��Ъ>����(⛣JO��d�,(�`��EI�p��dX@�᧰���	��6fr�N�ޘ�u_&w����2����L�?3�L�ʉ�df=���Jt?���PF����z8�y���z$�y���ڔє�M�Y�3��{3t��M�6�t1�
-Eg|��?��gJݟ�����	棬y�9���Ŕ�dcٸ*f).NB�K�������1��=N�(?(�G�R�,�;r�,�]��+��X6>���_W���Z�o6�3~�)-Р�ġ�_`�=T�gȄc�;�c���ѿ�~�ĆN~���K����ǘcK����|8/&�[v*�X���ZT��P�d��U1J,�z ���vr�����@�&��I\�M�8֜'���ͽDM�D+�h�4T�5QM�`�j�	j���:�˹<&���
-]N�'�V�����ɧn�"�r9�~qߊ$��w��io�Y�j�ZiM*Zu��?LټAO��:m<�ع ��[�]q��)���+�>mî����+���7�V��eT���X�?�3�Hr�0F�?H�|���_��e��`V����dT|��8�A�J��_�J�G�)��q�6�)r�[S�*ū5c�V��S)\�͸��O�s����ͨ8^�l�fBF���ʉ�"���zI0,�������=������i]ͳ�Z�c\���EV(el��k��\�zJ��
-�Ƹ�B7X��K(�$&�"�B��eJ5;bZ��X�]����TC����Z���9��^������g�-=^\���LI�᛽�M>�A�*�f�t�x�˴�2�}O���gؾ�]>�4��d��J}� [�Q��F.�Jˏ��R+]yL�
-���ȕZi�1����*��0��h�5ϭI&�m���J�&i� ���l)����E�L�j�R-}�����}S%1��d�k��YD����fo߳9�=�'��Ƨъ�`fء&�1�����e綰:m�XMr���p�%����Z��E��23{8��m!���9��n��g��1��Ϗ33��8��Q��g���&�cb���j-c��}�W`�t�s�Nsm�S5�w$�~�5.Zm?׋�"z��1!s�~5�h�ާ��e^6�d8�c,m��f�l��"ڶs�MA���Rdw�B)��'��l��Wٗ�d*ܢ-_nW�`i4H�hѤ�^�R��lCZ��A{���m��r�� =�l	��O
-����������o�;���Od���ϖ��$�OZ�I�O"��)Һ$�C�u�#����WP���i���{��4�r���^�顩��>�X���O�'���z���~^Æv=`��B���2�Jq�DaV�$�K��f��4�˝��$wu������f/H��]ǭ��ܯW1Вѽqg�<}����
-sV���\�ir��F�ك���(���HEŹv��������Qٸ2&���c��EM�pjzW�|s�Lӟw��N�1�QuBD�C�Nv�f&_Q��"1�W8K� K�M������h=k�}�_�,aM�3Z���W��UZe�-�:�*��e�Cβ�!gY吳��b�.����_5.��M�>���^.���-��ƣ��,���>ls1q6`�S��I������B��?���>�Q��~�?����ra���R��X�X�v7�;��?0�E�����Ht����ɠ��(;ܼ���v�K	3�o#T���!�'�v3n�4���pWT0h���Tq�g����.�g/Ύ-@�.����Qĝ�vE�9ߣ��<��v���~���L�������XQ��0>
-�:c�A�κ�߳�%|'%��G�mMھ�n���u��}&<V%��.O9*+(�j����Nz�pdԓ�-��^��B�Ⱦ�l�!�H�F�W��{[����6j���@�G�}DX竬(���)<�����0��_�
-�H�^�"��I8H#�*<��P$
-+���Q6�ǌ{��O�x�#	���UF<�u���ۺ��R:R��&�Ԡ��� C�7_1y��ֽ#�����Q�It�>ubp�K��;A�ԉ���+�i�ur��1UߎN5ky��[!���C$�:o�u�0�(�����ȿ+��웞BQ���l�M�d
-&z96:�x@�7������T��w�(co���h\ H�H�G��P�ZǄ�]�Ŝ�R���~%F�qW�:
-b� p�\�4@�1[�v锚�|��r-�;<Žfƨ�+�.d`x��K�!���$�l��k���y���5�@�f�����P��7�V	Bx����5��@�"#d=���qs���R-�Ƚ�V��0�k /���u���r�K��Բ���{�f1n�]���ֹ���^Z$"u�I���ӹ�/�}Z6Ŝ�c�{����'ZͰ��A�6f�r5빬Wc�؀���� j��k4�s �98fz����a��,��/�ĸdbK*�?)w^2��
-%~�
-�Bͷ���Ĕ*����?��E�{{I��[r�&��c�_��ψ&��|�8Q8�i��N_~�Or����	_?,s�^��X����G��|�[_��a�G������,�m�G<�uħ�Ĝ���9Z� [@��h�a�c-/
-<	R�.kZ�4���bR��U>q�W����v(�D"u�)8'ӺB�3�U������4�'������澋[2}su����I��r������ga-�ym�Xq�8�Ҳ�|�xG����/N��g����<�7���sq���W�,�-Hf��������Q������w��O� ��ނd*"n��v��+�V�W���O8IO:IԜ[]���X�zf�a;�CX����]��流����ӄ\sZ�iи�⭻�W��W�T�އ���S��"�����?�j��A��[@�N�^�O�н!�ʇ{:6и>�xs!q�7���ѳ�������Ӻ���7wS�3�!��SD>�z����;� �4���
-m�*1q��I�\!2^�]�7�_�A�YO|}�Ϭ�h����;���2+ecw��.m��;?��xg�\?-���Qd��1�^��ڟ�bs���	�@iF���R���8�#�� �l �s��گ�Lg���0���0��$󌭊lZŚ����kny�1��Db��:��H�rk��X#�2�DQ$]緒P'��V� 1'Ʋ�A�Ǆ�ǚ_����=S�8��3q,Q`p~�y���1���p�x%&Nm��z���ñ��A�_��wz�15
-������9r�� C�� ˍ��n��6�C�,V��.�{o%�Di����|Kϛ2Q�4YML���rϩ���n`0c|w�Ĳq�IǙ�{_-�jcs]y]P��*��{b|�L���c�l\d.��
-��%A�D�E32`+�*�K<|��}OLdו�4����Bq�SEE^�1K+���eڳ��B�pk���j?������p�ؒ�,�P�)��"���ʱ�}����Q�X�(K�r)�SN)���2Q7B)�R�TƝ�h�+�!3"wV#����,�֘x,yk����X��5�>v�ЉǢ�Et��Y�%�R���]n�)AT����p��ᢋF��5�D���FQ�����N�Z1���t_���b���8�i����C�I�?4��ِ[���zʆ|���y�k;|὘�k?�.���1<B{��U'�lv�s���^_��v�d	�w)c&�P%�O��y�6yH��h͙Gy��kϙ��i*�W��J��	�1&�V-�1���L��jKjm�Z�7�F��P�y0���ߔ��7��m�jx;�UJ�u^�jR-V�Iub27#U��)�y���Pu�:��D��*-�UZ�1o��m����5���x�/��ڽ&�>�����E�k��%2ݯq���ݻ���a(�}�W��1'w�4�ᕎ��_��j��-���7�6G����(��ze���ie�œ ���˴�|w� �R]?H��#u�#B�M��|�_G��e?A����O?�া&�����9]���k���7v���ۜ�$��+(Ø�%(w%�&)w%!�tns��P�?V��P�b.�>r�$R4���In�,U{8'�>�XsNׄʜ���d�I�$�I'� �N�L
-�D�އ��1�T��FÃ�Kᡯ�"K5�F��P�c9	��XE������&v����u���r=�\O�;�&AF��C�zS��t��e"�&����PK���i>N�B}z�'U�¸p����o��iR�]Yn[� Mc�R�ue)��f��z���'ub�U����a?a�^����8�Q���D�7&.��D�.S�����R^��N/����N/R�E=��Z�ؕ�뗏�WbQ�{�(�W�h�ӵa�ڰ�}�k�-�=�4�QT�a&0<Ǐ�װݯ;S'�� W�E7���,���}l��B�� ��{�`���'���O�>�6�d����]ac�$�^<)��5����ݩ~=#�J���s@oQ��@��M��	S���Q�;l�k�wd�<}2O�����Y��L)�b��,���pą]����,a�/��[�;(�/�\�x�	m����ݝ�ݝug>��
-������Ia���
-m�p��e��XG���^�ـ�����g(���ި�����>�����-�6`�?�I��Ϭ���y����W�Q3��3�·q;/��0���O@D�_���Xz��:w�Xәϭ~Y�^\�ͯ;A���/R�:W�v����{�*���SCk%X�8����:õ��X?e���Z�xu���$6��	�R�l��B/������Z���>����y+��q� w~s���i�����с�b��b���[�5���
-k"BT `��M���K��b5�� p�	S6v��EjEPƤ�����"��+嵘8E]�Q�\�D)#|�xz�c���4�}�x�$6�ڶ��Ԋ�:W�������q�x�GP���Wb�;��d~^
-�+O/�	8OF�d����0;�\H�t��e|�T����/��"2��1�����I���I�\��(�bSY�L���܁M�^l�^��^�2�x�gz�d���E����B�槼2+q�z4S���Jݏff=f}>���5�[:�{kf��Ж|<3�	hK>���$�%����m�m�⣙܅�����f��X&wQkn�l}Ϸ��6�[�Q�~7�wR����q��q��q�����X�B���z�rI���Fq.MA�u+�oP˝72�e)��6����YkϠ(��JB0�����<���)\3��OҜ�ɿ��)�hv-��z�\Ѥu|∄ެ�t�L|�o���W�`	o�������}�.n-w��[4B�R��	]F��N�r
-�wBWPh�Z@�;��&Z��BJ��	ͧ=�b't1�����r�^eq���%j�X��$�9��]���Z[�Ԗ?�\��L�g����)�Ϟ
-��ն����j�p�.�M�AOρ�AӚ7�0-�*�U�_�%�$t�$�\��T5�շ$ϔ�Y�jm�G��%g��7��m׭7��\S�[|T�+��cYܪaVR��p��y3�Nn���>�x\�<�I�JO�J��)(���ܺ�U;j�şu�F��`�Q�=���FW�v�^��o�yܻ����/��i��KS��J	��(\ih5�����Q�o������	�0�/̩�^���&)꤭��k�����k�qqcٸ����Y������|�5�H��m�V�A?׶"�L9���ĵ*_v��9��5S��&��#��1��y�=M�����������Ia$�<7�?W���qr�۠�L�ѝ�=S*=��3����R	�-|�2 ,l"��[!;�PS�Lu�i烅��J����8^H���3%�al�u�h�-�/
-�#+�-S=%�T6�-��V�|FkxrdD�[q� Vf�)>�)m��1���m�b���{��%S�N�%S䜂�M�͆g�T��B	��W.���@e��͚�s�-��ad����|�.EO�����גV�gc��	PJ�N�ܗ?���h!���8��p���G�=h��=�B���v��Oiۆ�Ν��>v�ќB��;_�d��@.PH���<a���vB���-_�$j|a��*w�S���廅���"��0Ջ���T�`j
-*BRnϯV=s,R/쇙�,e�J�X� m������T�ޔ�gx.�� �s�*["�g��Ay\yJ������!0�px���$=O�B�^`��5�� ��IUڥIAEڭI����&�}�+��)�Ѥ�+di�&�+ҵ)(��-�9�=3f�*�'�0�p�h����jZk���5�C�7�.�5�b4�h��F\*ղY%����X�٧M��h�tC�ޮ�=�I�M�i����kT�QK}"��o�����-)�	�gR1+[�U�\�Z�m��PJ��O��	�iD��z]J��[��q�%3��J[�xUA�e3��ko��ckue��.�]�7����BOy:�Ї�@��)?�sf�:�`��b��H����l]�VA�4��
-�g3��i�|��k�k4�p���!DHx+�2-h���Y��3����_}@�
-�"TCWG��(D�Cl6��~]cc��P���N��6"d��j�We��T�č�j��e��L��֚[��3[ƶ`�j�C,� �9��X�e�'rHZ�R��Ȑl/z'bi8���?�(�`��wy�C3�T�L�
-A]z���9�*VA�F�G`�@?��>�ˇ�p:��<�՗�,3���CN<��)�ԇ2�d4S=nO(����"��Y�8L��Jo��q��HHz��HHz�؈$��b:L��ۄ{S���c9>l��W`���� š����)/��6k�2gX����G���(G�<�=]ڛ53��D2A���Ej)a����47Cѻxh�<"�M��f]k�m��kE��f����_�EB�Dש�8���1��JϣM��Tw��`X,"4k������ɉ��K��=�0�&��Q�eԠ@�-Y��,^�W9���h�����-W/��$�DM�xW���J	T�mK(k�v��:�*L���͔&����4jE�:�I�;��<�II�ːG��U,6i!��?_����k�!]��"�n��泥o�	�������M:G�����#ɲ�>��,��+��½�S��L�cM�+�YkmE���R� �3���CV�u
-�˻<��tX�����z �q}-��p֖� �b&bCğM�?c�y,S�m(�v؉���x*O�v^W���O�B��-�f�����
-M�P0�`3mn���`Ë����o�R�����p<k�ĄX�}t�M�St�ʖ��ycѢ����t�)ܘ��N�!h<����8��Ɵy�~Q��k���1��Q�i�0o�>b�Z�,�2n`�b�Pq�����4Ж�����4O�z�t]q=��:U��Ln��t��c�� O���Vk�G~c��QU��Y��,�N��KV�%t�Nk8�����U�?u���[R>��ʣ7�����E�o�R�5�~�G�b�kχ���c�'��������ݟ�M?���>�}ʻ}!F=� �N�<~�I��xX+~���}j�S9�_h��?��3R~��~�g,��E� >6pT�kO٦���3W�`��ܧ*bG�'?\��|`p���P�%�!�Zs��']�C��U��7_���zNJ�!c���[���d�)O=A��,L|I{�4�0'ig~[�S���ʪ�Â����3�p�.��Z�|`e���xm�]���j%?�ɉqx.�d\2�o!=���r�.�k�>%��O�3�f�A.&xL1�I��*\z��5�,����ĺ�<�}��4���x'�EJ!����딞S�ܮqHk;�tm�H �1��*�<΄l�)��S�e y�~��~�J��z���T��,hj-�Еt�D&׋�k���������XG���Tۤ�=j��}/�i}ʱQq�)�&�.���M�kS�l��;�v"��!��EU���'�B�wP����[rQ��k����y��a�¤��!�Є>6X�Kr�(�T���O���7'�sY�A��<W���ҙ�5�^8�3{Ư�FF�;\M�:_� �w70��=�Z=�T8@��7�z��4��1ڽ&$��g�6n�=�j�M��-i���iP��Y��n�7Q�^��6$��������CI�����2����Tz
-�{��`(-��l��v?��ߝ���}#�S0��� ��>jP0$�#T����kP��Cԃ����<4*�p����c�+FE6� �fW�8El�Amԣ.4����f lul��5�- x"�%�I"lB�l9�{�S�4i���^�+�C�cؖ�(��ɰ��N1�l��zN5T+�P�r3qlOq�b:>��=��3)/�7�ՠ0B�I�?��|T�S�fXhv�~�~@]l�AX�%'���P�;�ƭ�ʝo�gS��.l��e׷�ߪ�*j����p76�^�>�[���<v~[�QOVS
-e>�<��t�%E��YOg
-����{}J��)`���iR�*0 .e{�lGqe�%�n"4�K�}�ưMWM�?��`�L��[�C$�CS�Ч2쑺�N���yE�ny�Y鼹�G	0��
-��P�~j�[z�(���X����{]u՚��%\#���I�J=8Ã�P]�]�������!���f���<��	F��{�6��gzz��>��a/G��#2�hi���	垯G�b��f��@�[��Fv�7+�>O�
-��죒5�
-�	 �^��<��U�|ŵ�v�ϸ0K?���?�w6���5�8���1`>�1�\�	��,�\����sy�)��VA��Pn��Pn�.�:��u�w5���C�l�Y׵�z�>��Z,�{�7bҾ��>��ڋD�����%�)�f܀!߅2�ߤ2�W�F�w�uֽr�6����c
-z�0�#NA�p��c���M5
-���As��w�Q�<\|L�v>^'B��F�v$�q��.�b��^!Qf��f������sK[��qrO<�T5i�Y��G�w�G�1��U����X�ܒ{̣ɹ��9�hj��7+��;Q�f�:�T#�#OC4�J���(�J"�淪
-�ګ���t��<^n�g]o��w?�N�ǝ�r/Q�dfJ�g�>�O���-x����D����$��xe���{&�������߂ƛ�j�`�L�����:�A���a�ы�C���p�:0�!��~��I�?iװ��;o��-�{,o���Ch�����~�?�߶�Y���F��,l��A��3�L�����g����GU{�1�+b	jE(��UW|�S<s ��p&}�ϔ��bs)^����"�ZA�3G�,�SW(R�&3x��#g%��D1���ʘ+l�q� �|�[
-��1��D������Q���2.����=L�y4ύ���g������� 2�1��yV��o�c��s�Q#�~f*'͗����q�(�J����P��_т��Z��-�M�����TuP�(��c��#{�(��j1x^{���[gP���8�|"���-�َ����?���z��z�y��	2��������o�?��N��Ę�<�y�%ע6=��ON���==~�h7��Ӛ�-�5!wOT���*�Іi��U��w�A,����A/��ܝvP�eL�~;��Cn���F
->h0' M!-�W'4�jd$X�t��?峑�����������b#ӯ;��?�|��,��`�<��M<I�&v�-g-��w ���d��R�'�-�ՎA��;����∧�9�dXG��2��=ښ��,'�$�� ��#��FiG��-�:��ۑ6���c3>6�~�rH:d�xx�j���Sw��+�9�`���G�^��W�#9@�b�wp�M�+q?i�f��H��yV�zwԇ\��`���P�!�/�z�������=���B����h��G�#���`)�=�g3-I���̴�܅�S+\�H�lT����6�#o�C9M�]ieG�>�]l8�v�S����5NS�I�&Y�JwxW�WJ����8>�'U��]�#\ᏹ���q*|�6������;k����|����3r\#wA���6r�)��k�.pP6�.�2��k��������/�A��u/������qP��B����cP�48����z����o8��.�1�y���qP���D������ @��f�tjw�8Ž�*n>w!�6<Nqo{��ZGTS+k�w��*�w���u�u1�uQ�����w]�v��k������*V��Ʉ�t�i��*Ue��\R��5�k�A�/kP8OۘU�-P���i6�*�ݧ���^^U��M�9f'��13NS��^���l*��ՠz{����9U��c�\6���9���+��\�,LfS�X��U��E�������R{���3\�nS��+|x��Y��^�ࡪ�=�[P��>L��G��A������++�b�l��,2T6�4��^�#[:��bm�.�`�x�`�֖�gy	��,��fi�d��*��
-&�~KDY5�T����T�I�YT07i�U�H�:X��F�V��00}�^�+8�7!\Ŵ�-�t1��euܱ���+����v̕u��!�u$��Hܸ6{<���=g-uĕgQ�"&Sq�xM�eH�į���7c�=���Y7ִ�_ ����8�5(�p��+�+@e�8a�O{i�v7��:�'>Tɭ�0�W,	G,�6>�+����Mn/m�R����Z��s�|����3�S��hzI�=�+v�2��0 ����7�x�F���Y�5Y������뼮����x�<Nɨ*(����U�EUإ�6�*���*(c��ayL����.��x		o�c�K8�ٖ��g��2��Gi��i78i�\i���N˲Y%�b�v����߃¹�!#���:Dy�W�MQ�����$c��&*8icꜵ-\|����!+wo;^_-ǃ��d_r����g�b��_�ű�2T* �AK�T�B�κ�:�܃��1�F�d�|�[2�v�U���,3�^2q<��:^-��Ռ�`�X�,�M�Y�L!]��)wac���r>-�����l�Uɴ�*����0t�������O�
-o���B�_�>���wD��Iݟ9_=q�r��Mu��M���7ͺHk�H�� �h*�0�Y7fۺo�˙8�f���Rs�M��4%���S*g]�?�l,�[4�{��l\/��V�Uq��3,P�2
-g�������u;qY|eU�~��X���7_aq�Z�B�<����C,��S�9~�������?��3.�������)GT���O�ԗ�7ei�SܜEt7�!�V�a-"��V����s+W�/Vv;2����ߡ(X�`b�����UXlW�M�
-$S��D[�FBv^G�n�b����4B���I��~d��aئ�;��(qw�@1�e;r��;� q����X����3�a}��]�7��/#|g-<��]�Y�(�����?a+��b,����~ˌzns#�HayV��˳2�V�D���1��M01x7�-��>҄��S+�]�Ͻ�����������`qE�X����i-���v?g���)f��)pc��s�;����j� �AW1����vS�$����GF7�n�!?
-�[\ȏ�� cb���E��X���r~���s�(���H̪�5�������Q���� x���[���f��wy���bi>�W0*����`����π�W9����5�����9 ���
-�B,���k����f�}�t�1�W�E���d�)DH�_ž��Bۿ�*+�-����L_������ �ܽqӨN]a�SWb�� ������]5�2�Jy�k��� ��o�Ũ
-Pܘ�p�/�*��Q��j�%:vw�����ǥ�k��e�:���&����G�M-�c�:���R�|i���l���8��\�؃���&�W]=�ot�~W�k5������`�� �Jd̋���L"d��B��&"�D5< �:�&�f�ڿ])��ic��f�a� �f߾Ceᣝ���줗h��%/6���*���j�.������s2.�-n2�3(X�ف��1��������&GUxS$�(�7�5��aU��j���·!��'�p/���)���r��|{"�Ľ��"ﺪ��j��/B�Р(��Њi�`����^�
-?�Z��6�|��d������ �����e���x�.���N�~3Sh!�&��z�dO߽^!<����'� �� �ـ;�S^a��(���8'�Y�566�K�x��=���o�r~Q\�q��sҠ	�+x�­���Y�s_H6�/�J/���vӟWB�W�ϞPiOC�;�:D�g���]b�Cֆ�K�x���q񈇕Uf�_�E������u�q[����=�W�{���g�_��󿔅6H�0U���x|@I�I�^{0�O��CƉ���ݞ�&��c���f�&E�D�3��7N/{����)l��5���SY#f���BA%�f#P^��W.�+�k� ��A��eT������j�if񂟯��d�e�G��N<����^M�:$�3Jeu��n��G<���Aι��C�k*�1 ��,�s�{�e-�1>���}X��8ڜ�H���e�޹<.Q�+��͉Ā*��ֺ�m���L�8��GRe��`{~K8��L���*[���{U{!
-�s��}7�`��Fʹ���^�.��Y/���B�vSh���z�B���+�Y{(�/B{B��l����Lrs��f1{��go���N�[i��g���i��C,�C���g�5��Ru��� �{_ip*��fim瀬 G�*H��J��< *��7��1�
-;�o�W��Z֜�ʹؒH�pV�Z�qc�ҏ���;ᱎeөw�n*0�4����@��2iQ��3��Z�Cf��B�I�s=r�&�KR���*-[ƚ�x)hB�d��1=L$㻎ӖL�҈�Dʹk�k'�L�^F7
-�=�~"��ۨ<"��͜4(���~�����Msm��zv����M�Է��潝RM])��e������HEfM���Y��z����\! _r�� o�K�{�h׭��Ko5��
-vyQ��)�*���-��O{��Ǳ0�06�tm�4��·[.��^���ML;�
-�2V,�D7���A�s�nd����%�UO��O�!�`��jE��*���S���M�^�9.��u���y���M��'[e���~x0�:���X9�&)��c0�w*|J�t�Z u�T���_�X�e��X�|�!\�z����뾆-���;��Y�����ei[�nF+8"e��I���i��nZ�ēh5ΙB�x�:J���|&��Q�q����´�Ͼ:.��Wǭ}�a�L���!�\�Ϗ_�|�-d��㐙���r�d�i��g2\�1�������=+���!%Y"�5�
-Z�k9���3!~/v�]�v�Yק�b�v��,I�D���<7������R�Q��e�:�^t�M�q�]oNå@������NWŭS�ei@�kI\l����%ƍ
-��q	�m�l�����f��	�\K:�1^3��"����ٍ�]
-|��Zz6�e��lW��a�h/�W�r�1�&��ecq<9E&)�sU\.W�ǫsm���Ο��3O��b?ϛK���z���cRH�ϖ0��RP�yE�T\��v���C��	�1�G�p��g���W���Yˇ�J�D#���p�,��'���쌵Y�[�
-|k1�C.]ݠ�oY��4=�yS�-�߆��-���TϔiBy��
-�'� ?"Ǡ	��f���E�u��EZIkc8�+9v/��Ņ�<^.,l0�d�!�����9��>�f����ON1قg�-x���Y�UJo��k3I�K�8g4��&٨4���_81��=���>d��������ZK��x���$
-W;o�"W���S��]J%��s_��)����8LL��p�ʀ0D|bW�Į��P�^W�(�eų��?�̟-��=�aP|�ӋC �}b��?�]��oD��%��h6��B;�{����Q*Drc������㒰����[Tb�� ~�*�?yҊ9]Q=�++��u�0|�}�� �7Pz�۪KoC���|�]G	+�����9]!�C>=�D����>�)ԫ�A?�����_����d��6�;=du�f?5/����� ��b%����Be��*�#y�p0���t`��n��`<��x�zYِ��E��1�>걓��|��z�^5lJ�˷�%�+��[|�i� [��^��d{J`-��[��2�2I�`��V�볞|H��i\H
-~}kw�N;4�qM-t��n�ؐ�\�W�;xV��l�J��������8}��/����XCٹ���Ak�,�kҶ�ҝ@�Ϲ{�oOǉ�����>'� 7Ԫɹ�͚'7�J?Ϸj���z	/���`i� �i����]M��?ݤyKweqL��+��;=8i饹�Np-�ہ�y���+Be��TR¹1��v��]��Z��4y�4������3̡��M��|G���i�TXe�������CMb�P�lJ�6 �{���ŉ9�U��%�F����~����_�9OꛊqW�Ԍ;G��H�X܏�� ������ʽ���d���'m�,���0���0���|DbZ.�¥AE�3��wθ9�)���ĥ��ⴛ돗i�w��÷N[����#N�����gws��S#u�	��>M:�������q^W�F��몃��x�`?*~��I�C��ە:�+}bׄ�&"4����Į�������)'v��hx�ֶ��� �d��F5qjDR�1,��\Dr��S��О��i�$BD�D�X6n��6�$ۮ�>)'�e��$��	zZ�X铈����ygܯ�����O���/�4�$��[E���mF�iJ�@<h���oԔ���*�W���I��&w>�� ���zrF���G�v��R~���^�_+F�<���jQ���˰NY�,��ൎ�7�ǩ�^wr�)���Ҍ�-�^C��$QRyԃ��K�{ʩΤ�JY&���Q/�l�V�����y�e�x�ޘ�M�t/]x�[�zT��c��ϥh��[��9��rk3d�\VK@�4�Ѫeyޡ/�a'��Bv6�K��R����L��IU�H��Э�3��F�����&@���J�{�Rn�����5٬,��Hbh�6��РG��cITt6�qL5�t�7H4��EK ��筌;�jx8݌B��±h�ꉁ-��8�X�k������G=~iBh!��vE
-��.�v"��r���=U!�tf�j0b��@��в�>7yLe�OԉW����ެ���D��t\ͳ]����3�j���?����pr�ť/9�Vj����.4�� mR�N�x�r� ]���)c���9�E���(�%uR�2/>���CTM��j�!ͳ�����މz�L�ղ���F��@뻞»��[hq'����AK`�a���z�<��;�)xl$�8�pdqim|l�1Ѣ�A8��o����*(E��Ƭ �e�!�ߔqo���w�Ȗ�;�e}<�%��p-��A��!���8�>��.G:���*����H-���d�X$ck���H�}��A��2�k�w�=�x[���Te��NK
-��
-�8�#�قF,
-Il��!d�>0D+Q!ぬ[�@���=�3�"�R�ՙ�D�L��,W�M!V�A�G�x"lW�X�V���1U&���� �I��]DW+m��V���"I�]����ģ�
-z�U��v�˯b�n��
-��y�NecW����~~��+�W1��Ԑ�*&̯b�����l$|�O?��ё��O��\�����F̏F��d� �9
-G8'�G#At[�/(kd$dn�S{�d�	�rIƳ܎ 顊j����J�کzp�8ɺb�O/�Wˍrǁ�;�{��i�r���T�Q�1Ý�:�˶\K�i8��^��>�
-9��p's[�$���lOrD9eqM3W��@��1s�e���q1�#$���7.�ѿ8i�Z۸`���%�<��Z6g���hM�zk��]���(�t��_ao
-4�tf�����_%>�U<X�:�O�'�7ƀ�?��%�U�8��9�H+ׇ��ܝ&��y�BDV�Է�NT&з��ꊽV�����,q|Mk�E�=��U��<��j�2�r�X^�v.�A"~�D�J��#u8����M�������\��^i����, n[�Kb�XC����y��q�a�tuz^����=�z8w�C�����cD�%j��4�A�Wǡ�].��qk\�^G�*m��G���?P��&��'G�l�@|�-�_zT|K���@i+]�
-�g�T:��x#u?/O����$I��l'�D͸����t����Gx�a 4�$�����'���^�/`}ӻ���v��`��AӺe0�uS'�DwN�y:��l[�-1�
-�b-c���i�o��~h&�X.|*\)ձ�5q�;kyM����lL�cX��(�
-�;wMA�~z0]�d���'�C>�z���y�ͣ��;�u%>C4�%�������P[bU@�8��k���=�'�8�1�r�G�T_'2��$����\��Dl�
-+���谇�^٫Lsfer[s�Z����2�� ���Ff�X88���G�ū4P1{2�M�����{20`�)�T(�~�丹�U�Χ�2��6�W�Og%\YA�3��z�s��3�|$Sx!C�/d<0]�%�z���0� �Z��J�BO��V��͊�L��L��7S��Xc�W��Y�!��e���'���Bh�K9]qp�<����04��0P�Y(�~)7�������Z��#d�ͱ�,t�� 
-�-�R�dBs��Kx�+�k�䶨UK�����%�mQ�FF��+GF`�I����U��}8�}8�F�sd���a'sp�ì��Q�w�[��Wѩ��e�~�ْ��1�QŲi��J���3D$�3�)��:h6�t)h�<��[�P��.��fYf����W�O�B��j }E�&Z�<�-��2�G��{D�[]��D�O����W�#��L�<lO���8�i�T�/3�?����6����V��¼Zd�Z~;l�΃�sM��|�D��<[��e�}�J(l�빷Zq��k{���y؊��7�RG(�v���N#,�q\%;N�x	�{��e|�/�!:[�Ie����om�}�����h^�H6"�=+�JH8\�2���m��-B�l��w�m96ъوn8'ڒ�l���n-�Ra4��}}�ªbԉ��u?_D�:6��W`z.�ݕ�.$�72���J6
-.��J;��72��x#����$o���@a9�����0n�bG��lFO=Q� ^A�����+�b������`���U����%���I�9�G���@&qDi0�ܶ��́�u(z�HwqW4�8�*��!�Sk�$��+,�����f{(d{(,T��z6�\�/t�qhB�S_�؝��;��U�sL�L=A{��!� ��,v���B;(�~n���~n�j������
-*��1���GF|}>B�?�����P�g�g����������Wt0{�CYɣz��Y�����糒"�ս��|��Ŭ�W���R@�ve��Wڝ�B��r�M�g��Oړ��{�R�*����omc.�%&�[��&�	��!��-h��{�J�;##X5�J�S^e�JWc?\�{�v����]1ī��}KW����-	f�[f���\�����c����+�2&qȼ��_��.a�X�n�H��0�R�2�^�B���2��]Au�H2����gG�ѻ(Z�he~~������X�ue�ll�te�l��c���x��8���#)�V�s�%,�ڈ�&����c@��B��e�W����� �>Hu��n�|�J�?���4 ��L�>�w�����HS��w����	��	��-�����{���!�=�~~��@�	>W�AU�[���m��ZE�3g�O��mt�z4q�Wj���4hTq`50���`HH�	D�:=�
-3���Ԋ�'�PW�xU��Ӟ��M�	���ΑU��O0��cٕ�tOZ��{b�'��>ML��5��tOG�J6�A�_�����=_�l�b����b�;t��O�a%�.�XNp�J;/�~�����w8b%�`~���7��sZ�8f"�򹓸��1� ->�o^:oI�ã&�R�Օ�kun�]0�m�W���~v�ۙ��3L�G^ǫ�00M9��H����	l7�rn,�H�o5��R�t�l<:�j.�$��Y̠^w�8d��V�u�L�k�5g:ʃ��_���-	�ř9�Ǵ���ABӺB��G�����=��Ҍn��sH�U!��>8�!\of��ҿ����+ᒩ|xl��F�����2�^Dy���x�x�G2,��c��b������Ea�&ˡީX��ЧlH�]��z;t�
-�e�Xf`�4��2�c�?�TdmZg��j���&�>^�}�+!�apd�&-�5i)Nq�ȶ\��p�3�q�����!���W��u+wE}�љϯe�y��k�%��,j���}F����s�z��{�})P�s�hÌ^ك҅ĵIs��8���omC(q��A�B\h�M�/��t�G���\�SU(��θz��
-�,L���{���+n3�a�W1�ƴ�ݬ�堄�>���Y?q�O���<|++���<�p�{&{�7Xᷭ��QUK������w������~�&���܂����\�3pBK�n��G�y �I��R?̒�8�����XL���$�Vj� #�1���	vpnF������s2�U4�n
-I}���4�8��zs�z c5��©�y"+���]����&D�sE�x�9�
-\t�}����GC�őmW!�4&B�)��݊IM�\���73���?�"j碆���J�u<hͅ~>B<��x'؜��:�D��T"����m��V��%�w��[���{,��O;	���;��+��pD���^�c��e�,\i}J�"}F������J�s�}�,���b^�*�q���d%b�=m���mR�"�k��!�6i�,]�&MT��6iR��@F��I+A>|��ƒ瑱8M�\T�4z�R�l��؞�*J�[c�)���\v��a���C��3��A���q�s5�%�ćh��??Е*EXEp��lڛ��o�
-�)�x��>�|�@uq����"����z���ے!b�9�+��,��uv�i�sQ8Q�L��1�%P��Ҥ(S�mv�_-�О���T���J�CXГz�� 0
-)m����5��Ô-���u5��yHo�S�-�Grw�ֲ���l̟�7k�0s\�G��SR�Gh}h� 2�����Z�߅�`����|�
-�ug��8����cz3Z�!+Y=�H�);�H&�'P�`┸�ˑ`<��t�Uk�����Wz��r�δ�Ϋ��mKϐ�B�U�(O><���0 �C�Ó%{�&?f�q��;���c��!ڞ�$�+w�
-	'Y.���D�*wM/�;[�|$�������a�������?�U������T7�/�~�ŷu��W�ɢ_���4�3�ǖϜf`����N���e8�&Jؑ���u�N����S�w�bSw:�; � �D7bS �����
-pfZ����q�+�WIѤ�v8�ɸ����a�+V�+܈��Ͳ�p�����*�5 ���RpP�φ�8+����^��K����t��������� ���D?��N��uc:+ ���
-�>���p۫ĭ�J�x��Sb��5*U�=n{�ѿ8����&9��*f��z.'�E�`��"pI��"�Rn��C�cL4���7q�1��C���&�u%�\����+���}ƥmq��7�4J���`����&��iBaŸtY�����|z����n#�/:�0����ሙ@�������{���,_XW�%/�u%Ŷ���HtF4酙�f�~43-2���|��0�#�$w멻g޼~4���zf��H����g%�ٝ�d!YIЕ�MB !�$��@ �w���C�{�������g�ު:Uu��ܪS�N�c��,Ζ��5�G���Ek�"E��k.�g��e6���I�_;M;�(���F��3;�*|V=Y?�.�����S��n �6s��+ @�q���$K�Ա-Cὃ����Ռ;�@��h���B��c'�u�h&��"�Y��'kPQ� r��#K�h+�a>�����Z��V6zjf�6k7�"4�*�iEg��s�w����Q��htP�J	5Z�P�s���ZK��AS�v$�����a�~�O�U�8i7�!\d�Q�Z�ؔ�t�_��n5�n�]h�>��B{�	\#����4�l[X�
-�.�>�ݰ%�ه����՜�R�I�ך�2J���+*�@�r���H�4Z��t�������j�e#�ϰZ]L��C�����A�qoa�D�M��dh���&��|����?�g���7^Y�	4��A���0��l��>���<U*�_aT�kN��E��W
-��w-�����_���B�EzЊ+�������C��ZP�-.���Ӽ�~��"����2K�+���TBgvn���F�u��B�u��/��1x��:�]�K~��_�[`\�[�6���w_�)Ê�洕���ǓvIKz���w�^�Q������I-҆�ơZ��П�A��(����^0<���@�d^CVph���BV�`��cksYq0b��|�-���ǩ#n����~ϸ@g�,�W脋p���+l�j��:j�C��y�c�{�l��S-�i�a�J�x����J���5���l�Iw�i^��y��uՆ�'/g.~���� J��m�+���ƛ�
-�C�"6)H��-�i���#�ƃ���^En�iUBZ~��&��*��^ac٠56���i���6�o�z�`5IZMDUj�S�)����L�6k0n� ������C�`�uyh.n�57B����ʋ��V��6����NCM8Xt��X�S"�T��P	w�ׂ� p^����`��@�����;��_���ε����^�����k�T��ut7����kx�X��}=�d(L�qНo��&c���ɺ�	s��~hJ=9L3��Pz���S����*ew���ϖ��RqSː�Z���RyS�G�Cf«�뻙p�p]�9���}��#tf�_h�%��q��MF�)Ⓕ�~�(�K��{��~|��-K��;�����5���2�~]�f�
-9be��r����!��XI�-���W9,CQ|%���sq�օ.�����}�B%�������u��,ǿ!�W�C�_���P��t4�˓C�FIV� 6�O�P���p?�D��Ǘ P�J�N|3�OF��1��Qe�LQ}����j��8�������}��-�Uj�>�Џ6��Gr�Rz���'ݿbF���+,Ɛ���'����
-�۩͌V���RS[<m�����ˆ�`��R �+�lz&��9��% ��H:�k;�=�s&�u�MS���EC�xj��Jŋt��ͨ�R��ǐ�}��e����:ҷ�!@���N��ǆ�mڠ�7����,���eQC?)�}:Lw����l����oĕa�a�e�x�H�B;�����U$t�3>Ԉ�����5t�K�DZi�,���y�?M���#g5Q�W��'�c��n�Sqw��;Ӆܠ��*�3�81�Ia�[_�\aK����,���7���#֍�3���-��"��.�4��R����]���P��Dq�B\�I����m忽�x"LMb�6�(�b3j���XEeQ�I|U�ۖY9��qD��Uӄ�J�!�*4O_/k<~F6��V<�}D�Ef�i.j�L�Q�]�8��_���]��
-��_i��]�j�b�k19���B��GYjZ9[���+#�~�/��w27z�o薪��gDo}�Ɋ[����@��ΐ� ~�/��"H�v��a���������9�?S���.񼂜����r2lI��A�ao�����������?���Y��+�W��"����k��v-Oi�,n�ʸ�>��n�
-�;��B�0��Qxנ��"̩F>��\���!����=�%�����6�~_����sZ�0�]j�UJmW2��3�z��v��c\f�9�߆R̰���(���|���rCӻ�l���ɪ�������':��C��f1,O<1רeޥP&�K2�VI�ͮ�m�����p/���z������ү�qmUV�T��=h��������@�@�5}��UE��Y."��@�%d�h��,����8�Ü�KY>A�O͟"˧ W�H����7sڟ������;,���WM����| ���[����������p~�=�D�;�U�ݱ�U.�z5;��f6�Y�%��!5'�ޓ��� j��Ȟ:)��4�9��CB@���x6�d;�I{��J(:P�q��t�JP2�*�3|�#}�U������$v~��ϣ^z>���+[.z��>V娵;8��ZG̮{ K ��X����j�®���59�� /�o]S	ͥﷸ�RK��Y;��{��%|9���9���x����_�G��*4�G�'�ҝIaz_�����<�sߟ�ѳy�}-H"�bߧi�$�n���S�����qB��l�p���g���#�E{>�Ǆ����Ғ�*|�AlM%ͳ��5�Vn4���Q9��>��H��B��5\�~)!~_˰�����@gKU�
-n��dY�GB��<I�
-sIMF��V�|��K���F��� �/|B�H(BU�I��ι�}��[���pN0q�UI�'�\
-�Ѕ>@\�1�E��h���HV��(�J��'2��}M�:Y�ju[�tN�#����`pE\�&:7(}S	�P�HVi���8�(�F~��0S0���Ҧs.���?r-`m�J(�J����=6&=�0��Q/n�@-ο�*���N�c%����8}�Wat�Ş8Q�����������#i΀9�]v��cr�`�ٞ�v��$r��'�wC[��5Zޑ�j�7��h�OT�;z]p���Sm�?xn�X�?Ĕ�������:�<�#�%m�(R�  }�1Aݡ%Q��WM��������i�^o����J0<�ޟ��.
-"�.I��Ʉ��mÃ�.z�Գ��L�(n=7��iz�@���7�����[L�S��<�r^Bυ��A5t�s��4�;�}N�O��0��,�ϡ�U
-ϣ�>zv��9��M�Nʳ�~���0շ��+跒~�跓�t�o>��Fʳ�~;������ �Vl���:�܋�����w����5�~�ޯ�����oů���w�IwS/=k����l�M���ͤ�3V�cϗB�ċ�{���~��Ƽ^�ps2����RxC��ˤ�Ɔ��K�Wn^!�75���p�J)���柇�6��*��5���7����n^-�w4��%�w6ܼD
-�����}w��k���7O��{n^+��6���twU�-O�nK�m����F�s��v���c~ǓI��!z�D��j���Sb��D)5?�4Q�@r�5� 1��MMpǇ�#���3%W ���T޻����םD��mR� �=��&��	Z�N���.��$&���}9�KS�k����rbCc�� �5�þY\��wjo9k�N���UJ<A>��b�߅��DX?
-�f2�0�?
-���ͤ�h'�G<T���V;��o�*�*z�b>��'��'����@)Ms9�h��p@�T�L�Na4F2��L�OlY��Ȳ
-IXk~Xf_��l����ofc��{�iqS���E�
-�'
-�'<��	��gT��J�/����S�_Wjź֭��jF��Ris[�ǐif����0/S�I�X���)�����c��Q��,{J�t�-Zw�+��ș��l�Y<��!e�Gfm.�-J���-L
-������Q�l��G�Q�S�R�W�d˅U�g��n�s����ob>��of�!,�����ˁȾF��?�Le�ԑ]7H�� /��\�-S.q�!F��'�?9x��l"�c����x��q��m�E-b5J#��`��lb�߰FB-z��{��<3:������uXe�-�����m���Vkj[O�Z��Y�ap4 &�h�v��L�������ó7��>ɍ�G���~X6'��k�j�~1�o�P��a8����*{m l<,]n�f!J����DB�ь쨖��i�f0����i���U�� 6��Gg=�N|��Vg�ϳ��]�Ă�?���<���M|��`|_E���50b}rBG��QB�t�}�|�>\&|1��PG���ІZ>q����"����`;�dhW��J"����u��֖	�����H���I��{x$`�bE}�V�}CD�����&��/\�v�O�������I�1���TL���G6f����.�Vf^����f�����PK�NJ�3�~�F	gQ~��Q-.
-mi���Ƙ�]bd~>'�5� �X��CFF#�CŰ�w������Į6���t��I�g.�|��t�Y��P'!���tlA�4Z����3i��ÑJ���)яԐ�G3?�$�F���G�A��#�$�O��3Gh��Zh�g��0��F���0���'XQ��Y՞ֽ^֏�@�3�0�>�c��#b���EAI{�F�Z��rY�.V=XPe�g��y���<@3���yZ�;����.�\H��<�1��'0���0�[=�����O�A��/��c_ή�°�^(�{в6��|����%��z-kSQY���z�������-Ee-�u��ނێFKV�����j	�ߩ��mE�������6-�7���֫°�v1%.c|�����4��R�� M�n���v���z��W��X(�c ��۬�b���S:�EJX`��bD��Ѡ��x8�X���9��KZR�^ƘX(G���a����9�aD�.��s���0C2Dܢ�a��l[e�&��h�K�i�Cz�?�U<���j�ؙ;���A_5;�����d\3�av:��=D{=�k������l�xz�(���Al	�xn&�
-�6?6������ �b=�$���aw:�K}��z�=�\C��5udX|y�+;'鉯BH�C�,���a�a���#��E�ĊF����	*eE0��.��ޒ��ᄪ][�:�7�W��=�52�*���>��W�]���`}�O�A��2�P�t:]mV6}�����Va�h�G�2:^.l�q�}@�E�q~�0�/�22��ۻ�(�_�շ>?�b�qg�Ѵ��\Tv�dp�v �[ϐI�����"�i��F���卖���`	�o_[%p��R��k�� si���W]c,e˃�nY�Xee]A�mLy�����g�嫃�X:��bY���-+��v�兠��ZJ��[V-e~ˋL�I�����A����[�O��^�D���^ ��h��V+�7��nO���*�;(��������� a���6m[
-�s�p��n��M�����SCt�����̕�x`Q<>MJ��N�<.&6M��i�$Qt��'�5��0|�� e�.}s�+N���z�l�j�	Ѿk��=R�謧-�d�!��qư�u�2��.��{����=����^�Ku�]��:-����<��Z���oxb��R
-f�_����>*{�W�����=���ކLbc0�U#�Rz��I��i�g� ��U�h"���a+z%��L�����	K�|���ιz�fe.��.>U�e.�K)��Dl�}=8*�	��g>�ɦ����m|�4v��MBi�u���qt�P�TXy* ��%�{u]j�թ����Ѻ�N6x�Ep�G	�xY�f�qj�=��25r��P,�ri��2AſT�!���2�� �� 0���A)u�'�XP�@0q�����(�*�B�^���If�l��3uE��K���K���ǒ ,����L�ro��nQ#�HљK��m�sk�7�x|#�d��P���������R��ev⼙�֋���⬻-+n�����D���z�F�ٴ;�3��8B=<n�So��',Aa��"��H�N��x@�֣�ω�&k�%�A�<%K�m����9���|���6EF�~L���c�r�mU��c���3�k*I�J�|n��(�D\:� �T1.��b,��ӌZq�[�t����>��!G%B\0<{W�v���m\n&vV�ۤQ-��Brz#��Ӿ�H�r�}#��b'ɴ�X��KMty�M��{�⯎`��#";FH��.��"RO����G��a%V��� ��Ӥ=UB��r.�)�a�QWD'�����_�;�F��Nӫ���S�����Wz*o���x��X"IH�<����xV f==�>� �G�wRI�z*S�Y�{�~�w�|iwT���sH��]L�C�X�&J*�"����"��:��E���xO�n���xW� �W��D~�J��Y�������LI�*�d��������L���R��p�x�ա�#��?��T��%s�%�Bax1�e�n����!,�dbނ�����M�l:pk�{�ئ�C��,�u:<�������4��߾�p���Y2`�8��!ɂ`X�{s�F)�%�(������0P��mv�Q&�f�v�4̎�}��%k� �ٚ����x쯲�0� Kϒ��ٲ8�>`�6m�V������D�gtrd|���N<��CLe��!%��	�a���`L vk|�~�X�.[�!��.�s��M��n�S�+�Gk�-�s����JT�喊]���azE���|��VR�NE�hE�؊B��K6��	���A�.ux@z^Z&|�m�õĮ+,̧q]Z!���:����T��j��ӯ�����`Z{�U
-4�w�j�������w�i������]�_��VgR�e4>�4�aj�8�(�����"2�d�
-�l�'�*աb*j�AE��I@a�ݩ�NP$c�M�<�r�ۄlJ��L�6�}Ê#5��� 왂��:�̈́G;���a�,�霊��l|Wia�匃�:��:�����b�(O�Ҋ6[�o�����h�:-kGz���@�se��E5�0j0g�A��������[ Û&�;��˭�ٺ��*'1��)�
-�U
-��H��;����{�ף��FcӠk�3�6��.��y���=��%��0E��ϛ]�Z��4)%�0V�C���;��B�~� �Bg#4X�-*������:cоs��S��jЮ�懲�Vgas�_��\�s��}�+JU?�@1LXuz���!��F^��r j�[	F��6��fW/��n��	�K�	k]��ʚlV�Mٓ�[�~-�Z~��V��:�)~j��3��w�os0��*(��]��y\�.��Kd>���t�l�L���Ke�ʟ��b�+Ӵ�%��b�M�B��N7����Bx����V �	>d�ɫ�� d[��"��8\�2e�ZN�<�o2�oh���yY��
-ZR�Gaz��֓��<�Z*������'9Э�g�ld�lm�C�S\�O4�����;�����c|��[ ��EK�@��h��ƿ���:��(y�������z��� �X,34o[n�i��l�����x����$&���"1���O��LbZ)�&�ܰ������Xm��5��R�v��dt���1�5X����Wdxq�ćP�T����I�W�Q�(��fsW,������5��^�p6�Z�O�9T����,s�|X۵-g;m9�%)�z��;��.�Zm8轂�4U�Ό��P������`k����$,�R/(g�c.�'�U:�[[��FDs�AMX>��A��A�ʢ/eh�"�B�6X�}A`{��I}*���|�2�J	�YZ=�H�.(����������H�?\�)�\ΑW�"�>���EU�G���)�O�oP�ﱤ;�?z���ȝ�Ǳ+��۬��Ģ�\���=��l�f5|��IX-O�������d��\$�w�j�Tp�j�TkV�lW����!|�!|�!���{�����g?n�m���������E�k_j�G
-G��_�����v�[^c]���f!	��J�j���-d����S#��K`�m�pi<��h;�W����{?��+*�_�-�Rz���CJґ-�L�Ԥ�������0��Zmuj�ګ���c�|Ⱥ�r]2[����BQ>P��%uae6�?��%��Y3F<�!�u�m��)~KW[�v�q�T}�U5�9�S=��y��V^����#
-���c̹��VK�肘2oE�C�|S<�и���*���)4��s��?�a3��A �U;h��� )����9d�XSh�з�-�&*��D~w��G���p��:Ctg��Us;�������h�5e��mg?͏V;��es��٩�sշ�E�[[�q��t�Z����l�����'M��K�)N��rA��g�.t�"�K��p�;�qh��[p�E%�(�M��R�T�,�����$�ߓRoY�d�R�,_��P@��J\�tmv�����j�7�"�'�l.�YC�JC���ȓ���',�8T�%�T,zT.�2�A9��AM�ԶxM�
-�#�J�v�e�v�LM(�8`�q��C*��v!�ۦo�sX�r,�8h�qМ�V��P!�!S�C�vS���|�V��.t[/Z?�q�E�%l_�e�[���v����	;o+��	��Ɔ'~8���m|5��%�%�n%le[�c$���B���U�*�T�V�ɦ�4�ƶ\&L���.�d*d���/���o��Տ#*"e�<�FK�g'�0��a��5��<�H�X-V�坠�v��ݠ�~�彠��Z��X&T��'���Y�w�[��c�P��!'Qc?k��%��"��&���i���s+�)i
-Ϥ���M�p?`��j;1���h�҉5�»�{��=As���n�d5nS�`��U��q.26���m|��h�K{������ĞP2�-�no�j��-�N���D�)�EY���$���HS�j}SH�m��7Z�Q�^�8{�����n�"��an�L���_q�T-Q��n�)�Lx�0���1�c�RKj������V��ܣ��*ĵ3G��j�-�U�v�>����k	ϛJ1^"���%�����e �6���[4�R7��]�h?˲zS��ş���uER��ŕ�����,�XcB�a��?�ϣ�����Q�{e�]Ә@�����˭C�`x�6�~Цo��M>U��`���E�0dK��\��fM���KY���R��i��o�ê����w�������I��J�8�W�|�q��6�����n�������$��HH�Ԑ$Ϊ�NƐ$~ ��l�Ag	v'�I�[e�tJmz+
-~��&�4�69|Y
-��F�� ���j��Y"�^#F�5Y"R��8�J�#C�X��"Vg	,����R!g�b��������%��)~Sjs]�MEg���66&�' �N��-�M&��r��ޯ#�X� _XM�G$�,y�Խ2�Q��������P4��>��te;�P�eMb�Ce�;XY�01�_����1�:��1��w��QK��-��<���J	ϔ�O)͓�����d�����Y-����jr�R]�>g8���S�槕�xk�i�y�>\�����Q�I������z Aw'�%���Tm�8�c�_��f�Ӵe�/#��#�-��)��-�{_�wы�WT�J���{2�
-9ͅ�����8�"V3��n��)X�\��SK9?�s���e�Cȿ֔����/���ɿ��F�����u �V����{�K�#H_?P7T��'�f��	gV��A��L�A��_��,����Y	�f8�d˻��y�O��d�<t���q�4P������B�7y�'�Թ`��ovE�� 6[��
-�Z<j���s�'�EƔ�t����U�R��k�W����������??,�� 6+6[�Y�կ�Lʂ>�z2���J�b	��� ���L|t�
-��z��a��V�q\_ ��@���2��0�[�I�T]&r����B�3ȴ�3Up�32����UΉ��s�T]���<Vܮ�HN���dRgQ�v��`�J8�v� ��&�. `W�2 ^c�ܙ�ǲg��v^�+��ɷG����r��I��#�TIj8��L<ZU9CH{US� i � �)u&��� ?i�	 ��f�j�ǚ����~�[��Z��K<5<x��x�_yC��O�$g���GjI�,}���I$�St����l�.��W��h�#�+��M܀��8V��ӎ�v3��)��A�p�V����GFf�k��7�B.^q�B��?[�{��ҟ_�������Z~���kyG>_���Q>�D�#�)F�u)|
-R���V�ڿ�q�������co��/P�>S	_��7������5"��x/�ތ	���By�^�7�z	 Wm���2CX�����B_8���䏸V�4Z�ӇK�l@������5=��z�!���0P �N����n��S�q�S�	-���9V��	���To��GP�[&��~��1swc#�F'�T06%��z(2ZJ�)�UR�N��	������ߏ2��y�� �L�N�Z��M�����"?���c^��Mk
-z�����omIV�Jĥ���-N2�q�V�һU�ޯ�:���Ųy�+!O�	�$=S�K����gRW�ʔM:y١%)��F�Oo� Gy���r8ϋ�<,���^�n�u2=��?��.q�I��AzŻ�굎ea�r�Y��,Q�R�L6��WJ:`m�|�ˇ$֍�d	V��A�G�����(�����ߛ�������.)>*u�&���Ŧ�y�";�F~A�s���}��edR* ���%�\���f��K|���Jc65b�0�'.�Lbv)�\������x�6ob.�z��|�K=M�vobA)�2��>إ㾀�T�q/��p_ p7ԣ��|6���DX���1�T�vV�U�?�'W&�>-ӿ�L6}J��JU'e\�Z��ˬ>S�t/��NQ�d�y�C��^k����MW�LW$�R���Z���Kq�mjR����.$\&��ɒą�V�`�b���y3>�����F&�K�9�߀?��"�Ή����ْ.�l�r0�..�h*e��»���O|��l��~ O�+xA��6
- ���@����*���qq�Y��\R��j9'�׭��ߘ�Y	���䢝��얞,�ros)GEm,��rԖ�v��#s�����2���>����S{"JP�]�W�F���5N�fyF��(/g�&x1�#�6��ťg�/6'dH����/�䷍aØ,�0�	��2�A�8��� �K|��m�C�e�J�_�
-2CS�n�w����ؔ�J�(�miSr��0Z�E'��g�]��!<ߔ�܂���䆶�r�s�0�Э!�./z�"���釒>O�������4/n0D4MA 	���4��Y��Ԥ�¶�e������c�Th��9ܬ��X�@HOs�݈{��/p8 �U�_1�̴�
-����nl�h�\)Y
-��|�7 cZT����-2�k%�`ki�4��(��gn�^S��r�7]�,�]�5zgq�W�ƍ�5N�?�Y���j=Pf�o�(3� f��$(I ��B/�j���E:U�C[/|���w�;�1T$4 ����&{a�f����ۙ��@zp�D�!�*����?��>�Cٳ��z8;����t���S��q�N[���-/�,9SV�[��:Fr�	7����df�P�K�'� r���7��:�S�y�.��ѻ��SK$&�5�AsL�Y�]Ý���	�x�z���^Q���QR�]DMV��}hr����b܇��}��]3ړ�2ј�� ���@LF�Q�,�iЊ�\������ޠ2�5̼1!M���,�#���u�)��)j�oIQ0*<�_��ꙊL��H#d���G=+{�)�9�7��?0QR	�SQ����)&�cP�w�*�Tۜ��S�/1>�O,�%]�$x�������E?�����n�`sj� �򔖣	p ��;%��~̌:�\�	���B�ɧ�&����f��)yl1��͋����>�a�	>��|��+�O���?�[F�s,1Z����"N���3^k���c��E��Jz���?m�N��yM<���*j�U�u����%L�t�q��(*�3�+r||U�
-J�D�eg�پ?��b����*�ͧ���؛<*��ˤ�-#�m��V#*C\w� ~¢[��b׌F�%�ݻ�%��G���Dr��r�Jx�-��&$W��ʙ�q�g�Nk���&NA�?�C��漬��<�M�{�<:�
-��K\����h�Nkn���6N��NY@�2�:eJ���C.�&�z�̛X��ob	���D'�����x>�M<��s��sh�h��js���y^��}�����@2�k�w`���"s������=%.W�'x^Fhv�x�<��Վ�������P􁚁ĝk���s�W�;_��������%`�`�!�yP�d3/�� � � �`\`= 1���56M��%
-[��|���>�혇�Kp�ES�{���A%=V���%J^�ոF��ZCc��Jot�Ho��!��/ǻ:�Qj:^nM��fb�"�,�U^����L�uM�@��,�3���Z/K�`��Цh�S�6�M� 6�	�F <Y ���&�M �T ���L �0� � SL [ �t`+ �� �`Z` �� �`F�U �4�
-�Y5؏�Z^4n��n�"��˕���V���h[�J���E0���4ܻ��C�ʻq8�W����#u�0{����i�l���;<ِ�����oZ>��w��k���"��;=\-q�t��ܑ[�L�yZo�4há&����U �ߌd�h��5о���hT7���5�X�uY]Xb�X�
-e�F�y�#�������x�����g�ۉ�O ���o�P�8F����~����8>���@���j��'���81G�O������կ��U���N���?p.+�<������`H<�Z3�s�3�j��	�)ξ��:��S)��sM�]�*O�u�i���|�z�|��{�s�H���I�H5Fx��8�>�w�>˭����((�sZ&������_���b���-�X��.X�U/����F)M}I������v0��U;���ϽS�2�.o�S�R�.�Z4���^<�3�p1<
-�m@��ژ���l��!۴	l�p�^S����� ���Y#���?C=����3���G���82<i�ݬ�J��R�xq�a��߽�Q��̲�n.��:�C��-�}^���83^q½���Y5�Yue�q73��d���Y51.���R�0RW�@���H�G9.�kz��C���{����E(�=����<]�5,
-6��2��o�`Ua@���'�yX�X��y���[��tG�5���#���墪�{�J�p"_c��4�?��߻MJ�5��j`�z8w2g�;�3�N�L�¸�ɋ�?��ª�5�1%����S#�bF|m ���a�Fa{���ԣ����X(z:��-���k���}n��׼�*,�c����ďA��(e���k��p`���缨d������B%�\@%�L�\@%� p�p � .��MŉP��q�ˀy� �)`��
-� �
- W �	�
- � � �ŵ|��k���T�5 ��	� ��S/��F�6Q}�E�6;����d��^Dkp�5�S^��>p��4��@��j ��nX����ʣq�{����4.���.JT#m>��z��v�T	Gښv�o��r/(ʽ�O�}�Ӄ�0����!3�p�y=>�)p-0�T�	\��BS��k�RU�r#�� ����ۦ`��㒞3�=�;j�;R�P!�DO)Q#%Rj�H-��{�'i7h������
-n�hJ�j�O��o���Kֱ�\�/[E{:��j�͖_^�:ZӉ[H5��C=ԝ��{=-�Ͻ�?�|����FW��G��/z��U3-}�G��Y"�3^/�G}�6�z�gP���� ꩜Iv|��%�@��$5�J�R���i/[���eң����� F���$Ic!�8�eE>���B�ϐJ`ς�?�ީ��r��؃V�m��j�Ru\�׀1,nl4t��{�t���)r��/�nӊ2ڡ��z�A�]jA���y�h�o\i&쒃4׭(��(K�iZQ&!3j��qv�c9N�`M��x���)R�(fI� �c�_埡4ڇ!�*�Ш 0B�D�˧��N�m"���cTTt<�=�O���0�|�cI�7y���rЊU�_-�v6���y/�7e2My/1L^48��3�{�-�x��DF[��<�0샸 ��gu���:,('ł2L_PNzB�&�׶qr����kǵ��dS�O=b,�Eg� I_f�%f6Ř���]\�]�9�K��k0��ca���E������G/K�b��E0��za̱ �ǃ8�O}�'�5�D�U��#���+�FW��,z@Ŵوo<!��$T��X7ܢ���#,jd��v@Uc�t8W��m��zo�p��-�ױ����қ`��V��W�z#D�4(����n��#����H��M���ԥ��n/�k:{�g�Ǜ:i��=-p�
-�{ԕ򏬢%��8�=Y����P�j�T�R�DM�Hɒh�$�.絑��T��f�_�+����N�"7ޣ@������Q�dh� *�yW�X�6��@Gұb,fʏHH�ZJ�Y�Q��C6*�ڬs����P(��,
--��=i)��ݨ�@��%��@��d�s��ϟ��>���`�����nmx^�������ڃػģ!!��Ms1�]#����U���B<�m������{(Xh�S3�{��1п �(�#�K-�Rნo�����,����lG��XցQ++�	��ɴ�C[���[*��4�h-�C�B%{p����Ɖ��]���'�t$�C\��4��1��7�h��ՓYT!�GZD�B��:BU��UC�_�O�3^H�g�=�L�� ��1�Ӈ��p�v}���3�9�NA��E=Yb��%v�Y�PPL����7��+�܋W@�����p��nu71��q$�Vĸx��p��͟h8Na?������R���b3M��x&�Ť<��J�C&j�TKXn��y��j}��B��\���&np�@]bBH���8KH�pX�i,�Ih`.G3GH�m`�$�=��X�OiH�/�ŉb���Si�nq�V5-���.��i�Z��Z�/�z"�1���$��b�s�R�t�m���;�%�N��0BtBo�pE��&��A�ti'I�I����+�N:�58i�D'����+��%��W5�Qe&�Č�tfs�Sv��̫5�!�S���^�(��%8��!ʪ�^�0>Y�\�b�ԛX����܂y���DC��}�����K����r&l�.�a:��Ĥ^�XN\���y��z]��+��޿���?��,��-�Q� �K���QI��p8��غ-��DeW�vm������=i�II��|n�5K�b����8��9Y���W���H<0�� Q���ă����:��"�.x�@�pٍMğe�i n�0�m7F.���[ظcYjv)� 1�4�AAǈ���3M+�
-������/�L4�^���8�GL��1��9bz"P��=pjV-5/S;�Lj����O-��s<����ab ��z�B�I!��I![�P?RY�sMf�%5)�{��l��BL��
-`�YkdޥP&	�L@�HĦt��,!���Y
-�qK�ig�$d��|����۵N����Y���S���P��k`��N�[�3��"t�6_tJȊ��C�b�σ�TՎ�𴑑�7Hc�Ufߵ��Z�u@�&�E�Ŀ��J����Z:5`��V��i��T�s��Jt���h�Uۈ�����F��2_��� ¿#��#;X�M���f>ﲻl��&&���P�s)_�m)m����K�I-�e����,�Cp��L��ZJr�ʙ�X9��oX�M��
-��+��qLyFM�&�i���ٹ�d�2����Q��*8[MV$�
-��l�?(�s>���K�����zbF�^�p��2֎�i�_�gKD�;4�a�>�Hk��"%6BD��»��T?-R$]c���7�����N��F���H�;�5Sj���)�)����%a^��h$l܃a� *�=R�>�mQ`0g��u�g��0il��4A��N`�Ab�U=�,=��=�dY.���sS��C̣�J��Xf�R�}�~�ܣZᇽ4DI��,.x������5�%�l.B�9�ƐDT�S���
-8J�_�Ró#��V�7>^ʱP������m�v�`ֈĆjv@(�Zm�sDn�%I�~�j"	��U>�헋���>?x:�W���Ld��R�<XgO���Б���f��붞�r�n���P61-�b3�|��l�nw:\OsQox����PG{O|�6O櫯3q`�zfh@��sh�r:�B�|�����b��τ�φ�sB���
-:0]}Q�o�z�Oخ>^+ҰY]�UmV�����E1�?�|���"�Ud��U0V���ƪ;|&cծ���(���jB��9��?�ucե&c�n�X5�s��UO���gCl�zN��U?���!�s������!��o�����[f�,��?�P2��0{�*���כcAQ.5�'G1���6Wi^��ym�Od�
-�N�"�Bp��P*{���B�?��g�NE�Sw��ϟ
-�g1����MA��v�ꨩ��^5��ʳcn�Q�B����PIY�[l-��њ�ɥ>���|W&2B�k��"�&���x>/�|p�av�lA�V�p���A�O"��M��X?��GҞ��������
-w6��fi���w���R
-)nh��&�]���7�u�'H]��34��.a�$E6}���c�8���R�g5�h�.we������ٝFv^H�+[���֞�x){�%2^�Z�K�95�ǝx�M�]��Nw�^�>L��l��Y���xwI�Q#[}��[����]�y5E.@��c%������C��V"�o�9\�i3�
-���&��~Z,�8�]p�3����G�����w������DC��2�fs}�2��Ҁ���|Y[����vK +M=/���R�.�H�V��qYh���{[ �f>ړ���j���,�hU�ث�]�9[���N#Y��R.��<Y�*�o���f�*-"�R3y��<Ju�p1u��1u��ʘ�J�����^bdO�4�p��{Qh��c�&6a�i�����=��G�g'��P�,
-�"��{	ۡg�:0�������<NB�����39Sc��(��+�����R�
-� P"~�6rb�v��>6�TY-�纸
-��#�j$�I����qj�pe ��n����WIqCgo�
-��׋��L����V�����;�8ӷ��@'(����pޯ}��L:�B@���� ��{}�\�qN��#��1	��0���C�H��;�d>��W��s��M�V�F�����Iu~�'�z,Y6���=��!��g�]&�J/��4�������B�a`L� %��)�z>t�A��K\��#�x��f�ΟZ�v�(-�ِ��4Ksi����4����6�v��&�e;'̲a�yE�8���}��	��>�q�����Fͨ^���\�����Y+���\O�wlYޱAyô7_(�e�!`��%��f
-{ZՓ���.+&�WL3�����M��\��M=���.��,2�	��b_l��k�]�Kw�b��0; ��[���"�	lq?�k���6"�������~�;(��
-�&{�.��q���k��ʆ7��8����(ew ��D�Ѝ}�Ԑ�M��"���*��eV���Ӭ)t�gR�ЕmVi�N����utm�ա�{�H鿃�L�`^�7Pd^㭀n^�+Tl^c/+i��M���ȿ�O�}�������ǲ��\|���3�Tq� >[�
-���g�ذ���CJ�b�&%�Qp�A�	n��%���J01[�sY��1R������i�"�
-�Gk�r;�G
-��>��B���-�?D��B��G�Xײ��}4]����|��ğUh��VjM��3j�6Po�@�,��:i�4P)�r�2������������=}��pO�aV����_��s��%|�:ݡ4�U��W��*�����yJ�|%�auz�Ҽ@	����j�1S�GP�%�/����CW��nwcg�h�Ί�[��%���^
-���h��D>�Y�D�м�)�׺@�^�_h�����z�v�%��Q-%��u���P'��*u&^
-��cNL�4��m�_QZ�h,�E6�,�	cr��~�,��JR��Ë�g�:�Ϗ���u���4�KЂ�|ҐF�D�4/فz8Go�M!�[�S�U�N�	S<�X�y'�%�t[i#x�e�+-���k�$��L���/���E_���B,Jf�c��좻z*5�Q-N�W��he���,��.�[p�4o��h���vj�� }:�v��5�i�wtaW���m����~�C�?���uG����!v	;�����*�����Q '�`�3Z˿z�;~G�����P��.ϻ-��x^�M�����$g{�w/�l�nP��A�t�v� Cl�;��9}���iO���K8�:2(p�ȾT
-����}*Tzp=>��D��qټRsT6�h�����%c�ۣM}Y���cڸL�;��k�i�B���J�"<)��J�Ԉ�%�Xa��d�s��bH���,y�Q���$�.g{/�tb��PaA���o�RB��\|��>=s���?��3�)��R[w᪚S���e�H�QbbOHMOH���Z��۪P$}{��#��믾h��|J<�͎�8�5K�8�&�f�3�E�X�E
-4r��r��I.�v�
-M�6;-d���Z�t�f��bN����i���N��~� %�XP���c�c��\�2��oJ���ы2�*���ωu*�NŢF����3?���ܫU��u0�Ho�G�M��-��u"��&<�Nv&+T�<�@S���iF��['15������>��ؿ�dR����H�P`A+�D[�I⃙��M���)?���"h�N�C-���mǤ�K�7H]p��W��j��>���˿�7�
-�����
-�VL!v?C��}�"��e���m'Ij�$IB:�dՄ�-�g�����SM�8M)�L6ۏ3E��L��Ezr�����((�Y�d?����j.��k�B���gv!<�g
-�?����r��N�v�K�������v�UT�� ��g���$�5(�\�Y��N��)��5�3#�t���gF�v�MKo��.�C˧T*u܉��=d��uL�)��VφR���I;(��Mt�2�'�MO�-�'����Բis�C��"�P:��v)��⢸_���sEqcS�3��g���Ԍ�8�E�aY�\�h-��Ҟ�#s<���-��������J��[|�7�?�?��,����N�PSl� L?�4�JB��x�0̡�����A��@*�Yd<Ϗib�b�:�_���~��`����F.���4|� ��v���x�3��XH��%\�ᖦ[[m$���h��R��Z�Ք�.��������[��Vi����JǤ�fYȣq�/s�_6��o���az�-��,F���y9&����q�2*������x�(.�W@ࠁ@!n� qoq*+V͝ƨ��D?߬����:�9q���������)�y���Ǽ���L1��Ƈ��f��)�͎ mI��X�dC�Y>���X6��H�6A��׏d
-1�Rj~0�zޯ��-��fu���)��>����#C ���6i� �%��ؠ�A��\_���3�>XfWQ��[�R.�6��LT�zUM}TY���L_�Lj�?12��Lwq�����8�����o�T�
-.�n�����@1E�V�JjD�	*�FK��M��T
-��U���jХ�\��:�ܯ�AϤVDc���z�Ԏ�Q���`�r��ʽV)\�Y�)��;Q���)�y�(���_*��
-�����#j]Q�LD�/����6(�q�@t�=�Q�W��+������p���l����¯���̍og���T>.�	O�~�u�9��4�a��hnc4��Hj�����߃p53��W��ˎ\�9����07�B�ۨA��f�㰉W���^�j�g�<�j%b���y�_̎~1���NU���؂��=Nq��K7�\��co�e�=��>�4G�"ru���-���?v��0K�ԭ�.x{U�oGB���ҫ������`D�Yf�K�Ə{�]�ߩ�#�ep޻� ��	H�e-~M�l;	�k�j����A�b�~�xf#����u�(?.$���N��1���	�a���5鸯Ŏ��V��.?L��q���f�	ڮ�݄�M���i�^��*��.�:�
-�R�`\f��7�s���Od�(6�F)$s�5챉��Q8�x'd8?rs�6,��Be����Z��~����ɍ���$�g����8?�~�O�:&�TIB���!C /b�{
- /�W��Ja�������� ��
-��9P�����:��	�VL$M	���]D�Ì�E?[�":��_� �H�U IO�pL��4��oj���b ����D65qE�˕��l��1[�O]�
-��cE��� �I����p�QS3�q-�Z-��%T�~q�%�<��4�B������4�	{+>�Hh�G>�@�g�|&�[:Y�]8;>U\��\�i.ӫ5�%�K,}�-m�H���*���H��� �@>.�\��"mV�qVя�j��A��Zp�p �>�X5ߪ��fz=OP��FMhrA��E=�[���h���rd��:��k����rQ��ؿc%��^��"\���]�9��5ϩ�=�$ԯ�=�r�I�����1����X��!�19 R�ml���f�U���,j���>������!��_�D�Rڼ߀�S����BJ�Ω³�v^�6��	�,.�_6��}mLј�J�p\�Rt\���s\s��k�b��b��yq�/������oC����׊���'�������������eFǗ*bJ��*��d�i�d�_]����^�,�ۣ�Bm)�a(u2��kȿ뽿�t�
-J)[�3�bS��4E�t�s�9�����[�|-}EXqx�S����V�?���1�T�"�-�br1Z�^k/�;�|1?.J8����Ks~9�4J+�3~.���-\����țIڳ��v��n�>v�\�Sh"}����%��B��QȢ�v��x��L�,SD���gBRN�t�t���>Ջ� �r��C��n$E���8~�H!����t�\)�+z8�h(���`�!�qZ��� �=n�8A�4Nl��\6��o�4�C!���dn5}Z���A���t-�zY?XG��&��Y�k\ma��Hm�>��Z|X0�uV��ޥ�))vN�G�ɘ�c�\G-m^�4֧�+�+����+��ʍ�Rz�Ҽ�^��UJ�jzq�W+�]J���R��(����y��hK�U�_P-����F{�E��%�ё~Ii~Yit�_V��)���.�Kb�Ҽ^���K�~�i~z�ҼA�řޠ��Q1�F���A7~B�����1/���+��!!�8�����~��A�׹��Q��~[&��������Z����͎,�1���u*اU�(TE����}�ab�c�&�a�0�Cs�
-�Z���T�T�M4!>�L�l��`�l��v꽕��7�0y�v��)_��]F��jxz�v���_��׌^�a�`5���s7_gv��.*w�`��f����n��zQ��+�u>��=F�{�z������g
-ѠA�V�B�� BQ��~��B�@!S�BGm�R*�;h)�Q�ZTʼB)*J�?h)Y��lQ)
-�dQ��Z�yy8����T�KIw�3Z�ϧ{���ʴ�F`�T��k
-9��r�(G�X[ȱ�z9�
-a��]��q�V�>�o�X�/)��i���_�B���ٔ-������X>�d>�.��Mm��h�����Pw}ks���,���,������Ȍ�R|��b�G�bw��ȎOX4Z�m�9}���z�z���ݕk�.�r9om����7F�Fk�B��u��l��O��'\��T�ҩ��Э? s���A7�욢�];HϾB={�Z�����|��\���*�ʊB�4��9��Z��:�3+Ҍ���b������Ku7���#�VC�#�V�N�pn��ڥv����}�lGz����:�o�5B[,�)Jպ�Ic9~�)T���W�G���s#kҞ8ސ����Џ�7���M�ӾD���h���[K��z��J�J-�z�g]V���45�h�%��<��SǬ��6��F���_�H����[�W鯇댌��P��J�S�~� e��g�%�j�t�a\�迼�Ac�H�g����QRFm��CRG����|��Z�	�ˈxGD���Ȃ�D��b���X1iS{�
-�%jQ(�!H>�M���;YS�-2w���T���T`��T��A`KJu[4���� a��Vz��F������9eě	RD���3̯Q�wt J"~�������h3���n��n�n�;�
-q�{��`�����$iD�B'�7&�7��e��5����d"+�Cd�R��G����a0c���D��):1Pa��ټ�wX9�����Co���B �F���^6�oY���rIc��?��,�����Q	�t�7*ͯ(���W�k���5^i�sY+���6�o�@;���ٻj�*��V�*�I\���We7)�E-��t�����r�����)�Y�R���(�
-�>��q��~�23���'![lt���iF�r�F�`Y�4[)}��`W��Gj!��Qؕ��*�EW������]��
-���)�9�}�O�K���
-�/�y�)��}�O�˦�j5��1M�v�L\�"�'}2~bʸq��!-�}2~j��J���)�M����t�:5�4AIBuuNIFGRA�b��I�v&'�Մ��z����{ߧ㪒]9Nۉ�;�Nw3�`f��x d6`�cl�x�ԩB�m�y2�d@o�k�$d�����ǇN�q��^{^k�"�w'�=Ӥ���"���O��W_7d����x>��M.ĝJ�D*d����q���O���;����Jm�4͖�̖�g��S���F�TBdo%d��9)�Àu�����͉��|Z;��K\��강��&���˕��5)�x���Y�+�����[����ot�x�m�������q�PM�����}وW���%�?��������"��t�J��	 P�0�,��q�m˪&lQ�k�}����_��ڠ�����/�14��(0�e��׺e��-{tY!h��<���	E�ixY��/Efx��A�!M�mrb��T���o0�Q��n�\�	��+��	�u���rD�R��I|S��<��"rѴۇ����~q �2}p�ri����`��HEك�n�"��$�ۙd<���8�L9�,r:���)�����"�g�T��蓸R/���V�}������~x�,z����z�#^���۝����G���Z�R����a�t+��b]q�2Z��Ѯ�'R'	$(�T��rx�$�:�y����w����T۴[E@d�*���}Ζ��}xs���&9:�"��4Gc�י�8؛&1,(�<�މ�K���k�����p���t-0�5���.�&�@$ Hk�P����-5��������%o���`���Qb��3���?6P=R��Էqi�ж�Cۚ��{�yz���c�%�&�iZba�u���:_�؈��oUl�d�Nd��`����|��ȢD�kJ^�Rel|��u�7�ph�σS��j��e��`��J�ceKo�4���:��u4��,fCګF��Qs\�m��JtT=���9R��ő]HYg�L��S�䩯M�Kj"1��!!���@��&�@��XT܄�^��M�\�b��}��q�4�-?�÷�Y�hݸ@��z�eߍ�}B�N����_Zg��:�K���Rڍ.������O_
-+���M��
-�f��|ח	�[V�� ��\R�Ω�n��OUb�g���w:kO�&v��}�){�I��֌1t{�X͖�����Ƌ���C�5�
-'�Y��j�Ć����)%�����X��Ę���-�^9P��B)1Y�LdG::ZZ;k��Dg}timbYm���[}K^k[iKNGޒ����c�aYq�r��r7�@�K�xq�~G+a��e��p|��?V�&����p"E��,	�'�*˿�r�:Ӟ��)�*��7U�V��⪎�'�P������>��>U�@^�5~���
-�5j�'�����E�5N��ƍg߇���QA:a_eӈ����m�l�fPnz���~����d?c~?��s~?5t�褳���6��pB U\�m�F�%�¸��ۥ��]���u���q �%��>��Zo�y����))���H�b��tlr I��)(�C��,)�	!��^g�'��Y��%��8V�_�XѯqR)���j.X��G�bP��!�g%�?�7jF��0���I���ߜ��R���.()}�wքibR@�~w�MO�f;�����a��4����jgb`XDiҀ��V�wXG1��uTOc�+mNt�݄�fN��'�Db`�R�eײ�s5�Z��$ͳ%��V
-:5���f%�����,�P�nP�tP�jPt�sP��Aѿ����we�����Oz�&�Q��]4�]�y�;E���pƤi���z��#��إe�E�����M?�i��*E~,!{ܗx�fXs1��A�%�7��د��/�\r�/O���R#~_���h���V�0?k�,��_6,���k/ÚK�IQ�g%O��eW��dkI�DLO�vy�v��5��{��dIl���/\�kb;�*��p" 6�l�������(����$��.��6w�>`�+�R�G)�mu�)����Ǹaআ��%�f7m*��t�3�)�C���`�5ü��A7%��������a�>�ѽlr��Z�j����
-'�Y�� �9a6J�:;��Z��7��8�a����&�_�&[m6�\/��&�_�&;�lR�UlR���d�dK�M^ϲɱ�`���)6)�4D�nlR�u3�����&ǜ96,ӅMPs
-��&o�Mް�d��!6��J
-7{��;�x ��&�*3Aq*�x�RVIu&d�3�-֎y�|���a����Ķ���zǋ�j�K��`�$�\#�� �S��S�n�@*�r�F�����H3�%�G/�]"Z���&E�[B�0T3������e�{��v����x��BY��z���խ,�ʂe�bbM�e���롞�K�s�6�褖��W�h-q�4 ���w����x!�ƱÏ3����v�7���p�,Hs����Xjt�N֐���)d;�E����ˉ�����f��s�Ԧ������a�[/^w�g��BUH�����K��pG�\���.�g��q`�1��T�׬£�=�> �/Vŋ4��;b�L�J��V�%tK�l�)���f�+��~Ѯ��P�K��H���La�[���?���<��c�s�B0��JNn�������j~���խ�A��j��}C���F�Z�^����ߩ��m��sX��u�cX��BQGz�V8���� !�:(c�c���w�q@�(Ǖ��JF}\������O+A�����R2�D��l��l|K���S�9�W��od�'P�/$s1�;��Ǩ���Z2�!~��Z�[A}�-�[A���I��v�����5���A}�-����NP���|'h���/7��QT_�=��Sa��P��%������³"�5��,J����i��������'�=4�d�n�h�L,H��	�d���	���U�ˑ}J���(~j^�+��q5#T>9�v�	�b��ݜ�z���T����Px g��'0�d����{��0[�f���������A}��|?h��s�掠�AP��4?;���Ns'�;K��Kf��^2��%穗�Bs����"�A}V_34��>��i�TP��e� �����f!?nC�@���y�O>�4��� �
-%q(\�t�I~�r�����3pR�+��û��1�mJ�Ĵ�m�l�.��1�� 6-/��"�kS����nqƦ�m�z���x�w��ޑ�%�q�ퟝI}7{�d�?b���a���f�ya�Vb�Ä3�T83�T,��T ��Ts�TO�	:s��ya��	��}a��O�d�Hd_�/�(_a7F\����%ub{������W+�ۋn�0�;�S!���UX�y'��Z4���@%Ͽy��x%��d�9�5@h��v�W3�аrY2��=u�5���[p��\�$���l�6+��҅G$ԕ6r���|�����0N�p+�C�p�1G��G1�$��FO�9E"��pl!��b!_�Ygg��$f;��cy�����f��
-k�v��.����d���Q���o���Udr%���r1��'��	I�l�W�S��M�p�i��fL����`������W��.N30��]2�)?2�l����|=�0������yv]O���G�\O���G�\��]QߜA}sO���:���P_�����x)�����O��t���v��C�5��|����^�)�q	�>mvEP^,��Ќ���thK��knxhAZ�/o�������@7	�B�+���.`	h�ڏ����&����2R��d=���^Ϋ�FUreܯФ�-�g�^��WPY�,Dئl�F�Nc���A���
-OcC��f����4\���a�}��[�mU�Wj���R{�g�޴R��_�Ys�d���T{Z�}�9���ZJ�o���=�'kt�FO���}W��V����5��5�G5��5���v�NogF�h$@����+��Z�#h�:�p�
-��Y������j#��,	;̎�U����ߡ�I,WW���� ��*|�lR��"�ۈC�Tq#�NX��L�
-��T3��X��a�)r|H��ರ�H6����vio@�QX�o�a�stO�c�c�,]�7&o,B��������ƴ[0��e���?�f/;�¹�|x��{(�(2^���X�`�'��V	����21��W���ێL�"��΃]m�	sK��� ;��������L�G|m��uJ�Ŗ��S�S�/lr�o2^�����Ym�����n� o�u��6*;ot�x-�wUW��;���S�lG����ʆ�a	�)�ΑR��5|���;�P��=�`�b�7{X���'kB����(_dhV;����}�ܻP�bkf��w;0�@Mk�,j �A'@��b�G�k�l��_�	Y�8#E|mF��z�8������ڇ�ԭn���쭬��������G�>��Px<���գLl3)S+dv�U@���ET����,�ǎȾb_Q�XJ�z��(�u����7:1����(�\�nt6�UϬZo�ㅙ\+{3������"Q`O_~��Q-����{��]��B4��ob7�P&��i3��/�~w��yĎd�]�E�a�V_ч�*י��*(de&䝀�6җ��#.��Pg%6�ؾ�7�ζ��*���@�0iz-a��#�l�Xx�E���PX��s�5G	炦u;��+>��7�sot��S��-|�����a;9��4s�Tu�4�iі�򋁖~�&ӧ:+���$�1mM�L���,��eS�~q-��[m ���&��g�[Z­9�@����bt���s���2Ms%k�\I��y�'\/�������$a!=�#�j�VH-�;�}�E5OJ,Q[�4eG�~��=0'0�&�6�
-T',�̓\�!����5�x� ��%lXX�`�@0B�o
-������"v�Σ�y;/���ɬ�-e�be���;J�;!n�,9���S(j�1,0��sM�^�V�<v FLAЖL.G�m�_� �2/��xe��b��@�\u�7j0	���KmZx�W��&�E���\%t�}�iA2W��J|�֣"U^F�����8��<\>5;'�C_G��	k��V-ki*��%�I	��m�z~V2�'�h��B�J�LT*��+�p-�@KS�:�=�SY�^����Oq�`L0)�~�(���%�#�m�H�0�5O�x�P�B��ܶ �۬�غ���h0,��po�gK�DEd�{��U��UI���KB?���NN����W�5.;E�>�ە;���6��b����<��O�X��I����Cm��KҘ��"�oqۗ��9P��#jwP�o��+����݊���kXg>���S�C������A㣠����Q��8���5?Ʋ�cf�ޙ�/�E]��bW��!�FJ�;��[�[nM&�z���p��I�le��:�	4�03�0��]��nwP�[n���}��'AcOP�������^����@�w���}Z���bI�����1�ħ!��i`p����t�����ov}25��֢����I�(2\*�E]�8��L]�����}�p��3�O�f�o��s�m]��i�Z@�Qi���!���~0��s]��d���!>֪�Gj��:6�{4
-��w�(4�W�-�(L�E߬�+J#oWI�Ƙ�/1���3�ٳ/��P�Ůc
-��z�br,띆��]�Nd�V�BÝ��>��Q�_�#�iP�}G�]���=�������~�ݩ�\���7��j�{��AcPk0��ςM�6���gA��PD�}�O���=ڙyY=�Y��\�K���g���&?����Ϳ�����p�($K�U~���OSs��AD���o��Lind�Or���uȿ:"�Zǣ4��#/�����k�!�� ����Y<�G@�����ϡ��S��&�/�[Ud��(�R����J¿&�y1L���4/e�&r��Js�&v%Ӛ7��e]E�8>��ي�;h&p��kOK�5��6��P��r;$=�����L`e��t����:�;�a�����������L���.�E,��f]�Y�܊�_�P�=蠥�A�2���V����4�ڝ���35�����UN��!f�34���3���ߘ`X��N���t���CA��aZЀo�T���E��*a!D,�CɎm"G�� a�/�0o����������,�@��VZ�p류~gU��]8ד��=����{��s��<��c��T��8�o�/���c�hZ�"K%)�L��խBrn{�����A���Ʀ��I���M���l���x����D�����e
-�mD�c��v�պ�~Ν-��C�7��O�����.a�!:�����"
-��F��SF����짺ٷ�?��9�Ka�`;���CP�!�Q�)�3$�� �]�k|9���eX�C�>A?���[N�\L�\j����p�؆��L�Ã)AװWX�� {8+[B�aW�f-{o�K��R9s�vf�^V}.l9EƠ� +�@�(s��-wҽˍ���γ����%�\�K����j��"96�n��x��S�8�:].�T�� �V4�P+���+��^��{paS�5��vY�a��kR���3D�����p:�|W�8�"�>��\�?������|v��%ߗv������؎+���I�f����'ߘ��b�ѯ�qE8��oؾ⬺k	������uv�h�������������)��q��$|!;	�fO�#h���E^5l-̟���ű�q6(���Aq"h��퉓A�lO�
-_���A�tP+0O�3A�g�	g�Z�y6h�jE湠q>���ƅ�Vb^�Z�y1h\
-j��KA�rP�m^W��߼4��2�j��2���_�kA�¼4��>���q#�U�7�FgP��Ac����p��h��#c���5G*�(E�g�R�ъ4G+�ES�1�1V�Ts�b�S��9N1�+Z�9^1&(Z�9A1&*ڭ�DŘ�h��I�1Y�j�Ɋ1E�4s�bLU�Zs�b<�hu��1M���i�1]���tŘ�h��1S��3c��}˜��M7g+��V/s�	E����b�U��̹�1O����IE����b�W������@Ѿk.P����=s�b,R�;�E��XѾo.V�E��٢K��%��T�~h.U�e����e������b<�h?2�V�g���3����|V1�+�O�励B�~f�P����0W*F�B|Ъ�)��)�*���b<�P;?��j�Պ�t[�/ ����&/*�Zr8͵��N���u��^������9��K������x�?3_V������!n��Q�Ϳ(ƫJ��櫊�Iix�ܤ�)	�5�x]i����blVLs�blQ4�(�V��7�V�xCi�'��xSi�6�T����|K1�V2�V�mJ���6�خ4��ܮ�(�3�Q�w��^滊��b����;@����b�Av*FI*���#��)�H#}Z1v)ԑv)F�)F�B�]1:�H��B�C���>R���H+�nrϊ�B��أPGڣ{�H{c�Bi�b|�PG�T1�����B�3��\����bP�#P��
-u���qH��tH1+ԑ+�t�#�qt?�ǔ�G�c�q\i��y\1N(0O(�I�a�yR1N)�����a���b�V3O+����3�qVi��yV1�)2�)�y��_��qAi�W�b\T�l^T�KJÿ�������eŸ�4��yE1�*�W�K�a�d~�ה���yM1�+�$�b�PFK�����z�������7�F�,q�w�s����q���:=�˴��;k��>B�Gj�(M��c4}������>A�'j�$M���S4}��?���4}�������n�ׯ��gi�lM���Oh�\M���Oj�|M_��5}��/��M_��K5}��?��Ok�3����/���Z_�魚�������5}�����4�EM_���4}�����4�eM������E�_����&MM�_��͚�Eӷj��������ok�6M߮��hw��+�k=^a�r�v� Hx�'��jFc�Sa��N˝
-�	f'��NX�?r4�0���c9�ɜ󴸴�(&o�Q��P��2QF�\n����ݎ0�"�C�2m�/�$��S0�`AI(�J�����#�Q>������o2��wR�_���Z�12�ü�Ώ���x����q���P�$�G�xV&`%K��H��8�ҸO����<��S��Jq����Y��+�~����0��)�%��r�Nw=�A��:��Q��g�#�{i����?�&��	q˼���z+qT*�j�H�U;*u`�0:(;� ��
-��"O"�~]�ǿ��| v�'�<�"��y�jy⛊<}s-O�yE��"?����,��( � ��l�p0'�U����jP
-���lV䔝���4�e�T����d��4�g���ey�e��=������,\r*�<C�U��QùrW�9 ���y��9)�#�c(��vH���I\
-E��"�������H#�Uo��H��\��	��\RqF:!�#���A�ZV��Vׅ���Ϲ��أ5ps�v���|�;1�����p����R`��Y���_�j�@ԟ�*���/��������V�sYb$���?S���z�Mw��P �P�`���Ӏ�����+����uyݥ��.�9lnE����s����r����|�(4/�/K�\>a��y=���i��"�*�'���J�{D�������\�Q�N~EEOwo��=��wN�����+��q>\�,��f�H��;Q�CR�܂^w���]�Eܝ�݈��pJ!���uH�a_яiB����@$���^.��h.`��R�Pβ�*gyY�0Z�|�/�[]3�;��B��U��A��muǊ����B�r���B*�V�6��b>;����[�J�=�vA�I����Q�X��~o�+��
-�� ��<=b���^8~����邪����Jvi9p>$Ŷ��L�����@��p�b�_G���h���i���V�!�q�v8/���C����{"7�p�1�����%Aqk՞�( t�G���S�ma�#���(�np&���\mϿ2�uݓ/��zX��`�)b��V�;��W�S=3I�m7�"nض��N8�".dS`֖ PD21Vn��Ե���Y��Eһ������1@n�yថ���MY�`�FH7c�lc�^>v�~>Af�#X�%H� ͽ3�x3AswIa���%�]�9�bs�{?W����xTl^見���v?s�j�P�����1R���g�T!��颎߆��\�Mȿ��\8d_�-Ȣ�#wQ7hL@�/� �fPoAN_`1�Y��s�<��*�7Se+vV�ZB��cMs�+q�+r�=�¶���a�]�X��o�X��2��*KC����^��/���xO'�`F�38�S�3�%��	�f\aj��Y��=^>�Õz�6i^��3_�������4��q�W�����6���!��=����!�%���l�':AJ��ag��R�d7��?�XVQ]Q(��,��-�H&��BASdЏr/�v�盗�\�t��cgi�ګ7/ϦR��Yj�!�#��]�8X�Ib�r|=�9�f�Q2���H�l���M�+�3E�e/?Ȏ0w��{�;qW9	dY����g�SA���f??}�[�� ~�N"��G���xUm���@^�R�7pp�4j��%��� ��
-h=f+�#d�M!+o
-i!���i[d<���u�6se����*��
-;��*�J���
-&x�\6|e��������+�_�?VnC����2�w���L�d8[�ʊ���tAG���
-�R҄S�ʍ���I�����0�vY��0V����o�[����DTn�O��l9?�`���Y�ϖ3�ϑEu-T�	՝g�4�������2�tXs.3�˶���T�ly)p�]���2�WP�9�x��l*L&��iK�B��sЂ������P _(��\	u�
-.�t�u��E"Ѣ�v�c���T��q�[	��	"�P�8��G���Q���t"2ޙxYK&���?�D���0O`@�?���^�=i4U���-60O�^����zU1!���
-E8U�#�.�.i���lOʢ1�f�kgK�g{��"=�!~���[�;�h�e��E(a$��˩�ðY[ ���I"(�^[�%(&�Y��[�����5�<�d^c�Tn�vFi����T�.6Y�A1c�\gN�A����{F�-�퀘V{�#����֠���`ʱvT/�I�1a�Dx{���Z�b{���`����0ɱ�o�����H:S��k+`�$Ӧ 0[4���zB����j����/X����;c}ڝ�( y�6�(օ�D�wh��o�V1��Y�$�VR�]Դ�#j_���ǮbQ��a[�aE�G0�da��VU` ����|e��L���k���+�y�[+0��u��=9��ⴋ������Y*K_]�>|�����֮I���bVv-fW8�,����d�aHyi�:��ruz=SX�L&�����f߾���Q��>�l4[��ؕI�̥����/aN�&xp�- �X��9t��� ����b��m���`1�z+h[6��_�L��w�'���Bʍ����2��}�k�p�JjJ�FcMU����B�¡x�/��]W��m��+�7��TJ�-�Qb^?��E����J���%����%��[�^�x>�^.Ú"'��ڞ�e��
-��Uw�nG�&w�&�y�����i3��Ǚ�z�M�h�u6��5ޖ��U\2��gڪ��C{�w)�NOd��a~g�PF@�//�ݷ�r��Y^ mK6�!x��%324���1Wɑ	�����!|����}^�_�(v���d(�5���l���]�ĳ���Y����E�-���s��v u��8`���8d[&ē��a� ��O
-��]g$W��ޖ��r�݅��&|q�؋U��QZc����XE��.c�𯭊��;�To��E�%�K��k��)�Б�V�fw�[�=���W� �v�M�����d���L�!���m�}KR��%��aǐ�x���e�n��S�Vq�c�*�ވU�
-�t e���n481l�M�U����C�L��,�r������`�d��Q;Ѧ�<����{)���̴�,����.�0�X���?[��8��)��:!�޴Нe@X\��¬�En��m���T<�*"2����m�u���XۙHM8��/��2S|�+�mVu�_c����@�>)��}RbJ��$`l�Ť��+G�w0���H_g�{':������z�����֣�V�`x��Z�����v ��'<����a<e�>-��ރ,����c1	RE��]{ �.�A����w��Ґj��!����B�+.}@�� ��9@h��4�hU���L��(jo�ǪB.���.fw�K,�M�^$�?U?1���[��!�W�;;��G��ү ������{�j�	����JbcQ@ #��� Y� ������, {w�;��@���LB�J����a������S�	�C���������(�����z��췓���M��mb~پl�]i]1֛A��
-P�_�X�����@�Vb�By�z���3��?vH��X�����C%'�����P�����q2�(�;N�>�㋰�Pr�;�$Ǚ����8v����J�����Ѱ�B�ћ~.���c-\]�� ֘�"Vh4�Q�4�1Fhymu	ALj�w}@����G��x@��H�>���N�-r�?���A��(�t�W�Y�[�hZ��N� |L���U�)�J����.��!Mc�8Us��Tc��I�x՘�jNs�jLT5�9Q5&��ۜ��U�cNV�)��5���1ry\�0��v�X���j,�R��%kX�4�<�wf鐻��^������ߢ������q������G(�AY�k[`*�����T\�2d�}i��P���pbm����"�F�O���Uo*�X+�{���Zٟ��}�F�S��a����B�Ss��ma�BJ��Ҕ�y��K!ԡ�a_�%����b5)H�F' lHr�ɕ��f9�T�['G'"ɗ7��$e"Ifv%ة���IH��'!��l�Fo�Zc+:�/�ry�,�`�.�^-�5�>�Q�?��)�l2�ǝ���"����(�=A��dx��P����4�R���'v)§)uo�2�2�
-�ߺљj���@���G߸���a�$�A������(vnᵎ����޴@B����{�ԮxT&*��z��G�/ɑ�nu�^�{�po�����e��'LG�qw:4�!)�ɂ�<λvP�nw�ʬ�N���"�ȍ ��L,����.��hB�K���-�S�1m���۱�"�O\���� �1^h�$����Ľ���s&���5&W�pon"�D�`�!}]�"sT�\gG�f����<�T��!,2[ur���i���v�y�Ү�ڥ�j�h(D�C���4U�i��7��I67�0&�>���D��#����\ʖ��m�|h����@a��K̝K��˰0	�/�2O�b���iţ�̯���_���JX�4��"�N�=���eʼ��f
-�u��W�j%��W����y�tQ���	������U�5�Oq�N���=�!fy	�i�;u��P �Dt0������I2�/t��^�~��5G���l��.%���E��/�I�-�h�Fmwh:&�u�i���꒾O�?���������4�����Ú~Dӏj�1M?��'4������/4��������~N��k�M���4���_�������_���~C��Vs�jLW�M��4'����4�M�i*Q�R�Z����\��J֊�l��J�J�|��0�zZo�B�Za��.Za��!|�J�HN�LXi�^Z_�L�G�iA�NS?M%��U�Z����t՘�Ꝅ�#��[҇�j�#��Zr���B��j5�}t��N}ǍE�8v��s;'�9�V�=�O�sj����9��S8;���x�V�>��:���Lv΄sV�V��>�9�Z�#�p��s���'����p���� 9p��.�E�¹�C������la�8��s�O�j��/9�zp���\��� t�����|��X���\	g+{�U�|���\�v�����"�k9t��k��G����������9�o�Ѝp�¡���Z��#�&8_����|�V+~D?ҏ��9tB�2�7�|��o��6'��vvn��(��U߭�6��j�B��~�v���Q�����j~۹3�I2����\ӹ�j��G�6���j�G�8?�1�G��p� Տ9`7�>a�8��s/����)��s��,��<�<�s.˕y0�<�s�u�#9�Qv#���`�P���~��妣��q�1�~��ƑSKq�տ@�s�O���U����	���������~�̌�>�u�]�s��M������E|��%|���e�П���W�W�A�f���A��}[����̚�s����VKc8�{�~a7�����P���]GQG������Qu4F����<�MK|M��D`����5���`a~�F��xDL�g">��h�G���O�#
-a\ѧ v*>[xT��w>��Ұ�1�{�>���.��f�����<������@�,��Fb�;��0��أ?/�}.\`R}^�s���3��,�g>�@�bT��%�>��h� S�O��4>�p��,�g>+�4���9S5f�4k�dAS�]���[��C���C��U��P�{��LB��!@����UvcHw;�v���������-9(:K��°�_{�48�� 6IaE��M��j���a��	�\.w��i�hOuI��|/��3J>#Sbt��)*]m+��F��G��1������ᾮ�Oq���)�[�`�S5_��:m�d�.����)�}+�������������4���q�PNK�PF2;�-���pV4XHo�Gٞ��-Z5E��c%#+�Α�������΂��NXT�K��my3;L�͊���Z<S��{���T6"ʧE���V�梅�w%ӉPFc�M�iD�7A��YB��bb��|�g��-3g�T�I�e<��q�1Ş�Z�l�c�bgP�� �|O���f���>��>��oG�K�q�rY�@��3 ��!���sZ3�`�3)C�ߢoA9.��lRM2w�P!5uQ�Ϭԓ���J��J�Z�>�J_��U"�@��j�'�k[M�y�^TP��IP!���d�5�2+�5a@V�k��z���?�6i1m.T�E*�`s�j,V�c��ŪѢ��h���U?��\�KU�t?s�j,C{,S���ۊͧT�iUl>�Ϩ�-��(r=�WN�e����d�L�v5�P��]@�F(�Bl���9
-��UY�.�GT��?j���2Y�v9����FV�u�"k���x|Rn��QUN�x�
-օ�����Ϩ˲���O��߲�ۣ�Ԍ����-Q3:��-V3:�x´E��ft:ݬ���9�k:;ݣ;;'wv���|��sD�����2l7�f���v��nU�k�U����gA۱U8v�L[+��*��l)iM�#���HL �����̆Jv���ʆ:���h�qU���z~Dt�H���<�3^�O2�1y?��
-o6v7yw�b�7c���xn�ZQڍj�0p��n�5�,�&�t�Ct���W�л'U��8Z��F'W��n��
-�^�2{��;����ns�w���ٯ��E�j<E!��#�>��DN%�~X�H�[4����s\:6e@���U������q��y|n��NA`���l�W&��u��P�����v�:d�r������[����.����[lp{\��ĞՃ�e�sn>�>���e�;:)B��U�^��H��ߧ#�� �q�ۙys�#���!|=8���ݱx���nS���<Wl*����){��P�����==�@XY<�o�ʱ�|,�TR�>U��[�%ܚ~oQ]R��5�����5�^���^��Ph��v �$��[��RS����d�c,���{
-���=�o/�m"����-�� f+~=u`��)T�CSPH$J��<xa"���y�������fFؓ�=v#�L��a��WF�����8ta�=��Ӫ�n��
-�P*s@�?ٕ:Ҷ�C�n�Q����`���'������N�S=4��{㻳���ӼM�4o���`0v�{�(^��Q8M*K�B�Q���W9���� ���Hj(������'݅�K��cM�zg�o���XO���ؐ�B!RM@َ!����N��c�6\��*'MP?B���ÊZ�0�f�V�R�DJ��t*2�
-F�J�B���Ԋ�J�Ȋ�z����*��9\
-$���<��Z:���	� �3՞���h��q�;�����\���ߖ��8b�Uc���V��JZˮT�VA�b��W���!��\%
-Ŏ���>e�Z6��LM�J�+�!�J$�M��I����V!�M��=}�R��t@���,�E�B�5�����wP��E1�c����X?�,�� �|��-��q.�Fl_,ͱ�����8/�!â1'���NLp���EKͶ�Q�h�z�d2�N� �����r��:�f�ܸJ���Qp�Q�]@ҽ���1��Ƶ�ݥ�q�L��rG;�T���ƽ��{�c�帷�LnȞc���l�-oy���ȣg��ZX%�Řۓ�N�<6����TTZ[.Th����i��U�y��RG�{N­uR'������{8�m�G
-�e�1^��2�<'ø _�P'9*'�" ��(-C����EU9�f� ��W�o����
-"/���P)�Q1��9V��Kv�8��B#��	�L����6"��r(о�6z��0+ $��jةL��ɒ��=^�S��P�Q�����vËZAݢ
-
-7m,�*��	������-I\`��!ᤜ�6;!?V��������a����6��p\��I>!ӹ _]�Q%�2�s�ʍ�T����rm�̋�?2��1e���Y���Ƴ�:�gP���|��t����.g���1t+�di�<�%THΖ[K`��\��bG[�rb� [	�6a�0i!��i �v�!K�����شB��]��"V䃰�y���p\�#��0~����$���A��X���e��/Yy9$iR�����V�d D{)�hj�����r�'�g��˫���=~FRƅ849e�%p��$A�9Ħ~�b~�<��+�p��7O"`eUV��������-O�I�*�p�v��S/�y�*sZ1k@���<lv磳����F�BG���?~���=b>�<��C�����ņ}`�{�Wp߯rᎊ���l~h��������|���C�������_�T���2����q_3�=�p����k&ם��ѡ����}��>h��o�����������O�v�}���0�w���Æ���y�?��������o������S�{}M����������S�|M�_�.���?�k���U~]�أ��{�������� 0d^
\ No newline at end of file
diff --git skin/adminhtml/default/default/xmlconnect/boxes.css skin/adminhtml/default/default/xmlconnect/boxes.css
index 0a4cf30..d46a85d 100644
--- skin/adminhtml/default/default/xmlconnect/boxes.css
+++ skin/adminhtml/default/default/xmlconnect/boxes.css
@@ -88,6 +88,7 @@
 .image-item-upload .uploader .progress,
 .image-item-upload .uploader .complete,
 .image-item-upload .uploader .error { display:block; height:100px; text-align:center; }
+.image-item-upload .uploader .progress,
 .image-item-upload .uploader .complete { text-align:center; line-height:95px; }
 .image-item-upload .uploader .file-row-info img { vertical-align:bottom; }
 .image-item-upload .uploader .file-row-narrow { margin:0; width:140px; }
