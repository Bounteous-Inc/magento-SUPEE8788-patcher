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


SUPEE-8788 | EE_1.12.0.0 | v2 | 1c7a5137fcd6294137128bdcc3bda4506b17d41c | Thu Oct 13 16:01:57 2016 -0700 | daf3645908de2610a45f79f1c07d23f7b95a7055

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php
index 44cfc17..6554a66 100644
--- app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php
+++ app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php
@@ -105,7 +105,7 @@ class Enterprise_CatalogEvent_Block_Adminhtml_Event_Edit_Category extends Mage_A
                                     $node->getId(),
                                     $this->helper('enterprise_catalogevent/adminhtml_event')->getInEventCategoryIds()
                                 )),
-            'name'           => $node->getName(),
+            'name'           => $this->escapeHtml($node->getName()),
             'level'          => (int)$node->getLevel(),
             'product_count'  => (int)$node->getProductCount(),
         );
diff --git app/code/core/Enterprise/Checkout/controllers/CartController.php app/code/core/Enterprise/Checkout/controllers/CartController.php
index 8e95ee3..28eae79 100644
--- app/code/core/Enterprise/Checkout/controllers/CartController.php
+++ app/code/core/Enterprise/Checkout/controllers/CartController.php
@@ -91,6 +91,9 @@ class Enterprise_Checkout_CartController extends Mage_Core_Controller_Front_Acti
      */
     public function advancedAddAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         // check empty data
         /** @var $helper Enterprise_Checkout_Helper_Data */
         $helper = Mage::helper('enterprise_checkout');
@@ -131,6 +134,9 @@ class Enterprise_Checkout_CartController extends Mage_Core_Controller_Front_Acti
      */
     public function addFailedItemsAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $failedItemsCart = $this->_getFailedItemsCart()->removeAllAffectedItems();
         $failedItems = $this->getRequest()->getParam('failed', array());
         foreach ($failedItems as $data) {
@@ -232,7 +238,7 @@ class Enterprise_Checkout_CartController extends Mage_Core_Controller_Front_Acti
             $this->_getFailedItemsCart()->removeAffectedItem($this->getRequest()->getParam('sku'));
 
             if (!$this->_getSession()->getNoCartRedirect(true)) {
-                if (!$cart->getQuote()->getHasError()){
+                if (!$cart->getQuote()->getHasError()) {
                     $productName = Mage::helper('core')->escapeHtml($product->getName());
                     $message = $this->__('%s was added to your shopping cart.', $productName);
                     $this->_getSession()->addSuccess($message);
diff --git app/code/core/Enterprise/GiftRegistry/controllers/ViewController.php app/code/core/Enterprise/GiftRegistry/controllers/ViewController.php
index 9878c3e..cbf1304 100644
--- app/code/core/Enterprise/GiftRegistry/controllers/ViewController.php
+++ app/code/core/Enterprise/GiftRegistry/controllers/ViewController.php
@@ -75,7 +75,8 @@ class Enterprise_GiftRegistry_ViewController extends Mage_Core_Controller_Front_
     public function addToCartAction()
     {
         $items = $this->getRequest()->getParam('items');
-        if (!$items) {
+
+        if (!$items || !$this->_validateFormKey()) {
             $this->_redirect('*/*', array('_current' => true));
             return;
         }
diff --git app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
index 3185cef..30e59d9 100644
--- app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
+++ app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
@@ -136,12 +136,24 @@ class Enterprise_ImportExport_Model_Scheduled_Operation extends Mage_Core_Model_
     {
         $fileInfo = $this->getFileInfo();
         if (trim($fileInfo)) {
-            $this->setFileInfo(unserialize($fileInfo));
+            try {
+                $fileInfo = Mage::helper('core/unserializeArray')
+                    ->unserialize($fileInfo);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $this->setFileInfo($fileInfo);
         }
 
         $attrsInfo = $this->getEntityAttributes();
         if (trim($attrsInfo)) {
-            $this->setEntityAttributes(unserialize($attrsInfo));
+            try {
+                $attrsInfo = Mage::helper('core/unserializeArray')
+                    ->unserialize($attrsInfo);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $this->setEntityAttributes($attrsInfo);
         }
 
         return parent::_afterLoad();
diff --git app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
index 05aafa7..14417a2 100644
--- app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
+++ app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
@@ -76,7 +76,8 @@ class Enterprise_Invitation_Block_Adminhtml_Invitation_Grid extends Mage_Adminht
         $this->addColumn('email', array(
             'header' => Mage::helper('enterprise_invitation')->__('Email'),
             'index' => 'invitation_email',
-            'type'  => 'text'
+            'type'  => 'text',
+            'escape' => true
         ));
 
         $renderer = (Mage::getSingleton('admin/session')->isAllowed('customer/manage'))
diff --git app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php
index c065db9..716af4a 100644
--- app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php
+++ app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php
@@ -40,7 +40,7 @@ class Enterprise_Invitation_Block_Adminhtml_Invitation_View extends Mage_Adminht
     protected function _prepareLayout()
     {
         $invitation = $this->getInvitation();
-        $this->_headerText = Mage::helper('enterprise_invitation')->__('View Invitation for %s (ID: %s)', $invitation->getEmail(), $invitation->getId());
+        $this->_headerText = Mage::helper('enterprise_invitation')->__('View Invitation for %s (ID: %s)', Mage::helper('core')->escapeHtml($invitation->getEmail()), $invitation->getId());
         $this->_addButton('back', array(
             'label' => Mage::helper('enterprise_invitation')->__('Back'),
             'onclick' => "setLocation('{$this->getUrl('*/*/')}')",
diff --git app/code/core/Enterprise/Invitation/controllers/IndexController.php app/code/core/Enterprise/Invitation/controllers/IndexController.php
index 30174c9..895ea09 100644
--- app/code/core/Enterprise/Invitation/controllers/IndexController.php
+++ app/code/core/Enterprise/Invitation/controllers/IndexController.php
@@ -80,7 +80,9 @@ class Enterprise_Invitation_IndexController extends Mage_Core_Controller_Front_A
                         'message'  => (isset($data['message']) ? $data['message'] : ''),
                     ))->save();
                     if ($invitation->sendInvitationEmail()) {
-                        Mage::getSingleton('customer/session')->addSuccess(Mage::helper('enterprise_invitation')->__('Invitation for %s has been sent.', $email));
+                        Mage::getSingleton('customer/session')->addSuccess(
+                            Mage::helper('enterprise_invitation')->__('Invitation for %s has been sent.', Mage::helper('core')->escapeHtml($email))
+                        );
                         $sent++;
                     }
                     else {
@@ -97,7 +99,9 @@ class Enterprise_Invitation_IndexController extends Mage_Core_Controller_Front_A
                     }
                 }
                 catch (Exception $e) {
-                    Mage::getSingleton('customer/session')->addError(Mage::helper('enterprise_invitation')->__('Failed to send email to %s.', $email));
+                    Mage::getSingleton('customer/session')->addError(
+                        Mage::helper('enterprise_invitation')->__('Failed to send email to %s.', Mage::helper('core')->escapeHtml($email))
+                    );
                 }
             }
             if ($customerExists) {
diff --git app/code/core/Enterprise/PageCache/Helper/Data.php app/code/core/Enterprise/PageCache/Helper/Data.php
index d6036d5..6da350e 100644
--- app/code/core/Enterprise/PageCache/Helper/Data.php
+++ app/code/core/Enterprise/PageCache/Helper/Data.php
@@ -23,7 +23,66 @@
  * @copyright   Copyright (c) 2012 Magento Inc. (http://www.magentocommerce.com)
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
-
+/**
+ * PageCache Data helper
+ *
+ * @category    Enterprise
+ * @package     Enterprise_PageCache
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
 class Enterprise_PageCache_Helper_Data extends Mage_Core_Helper_Abstract
 {
+    /**
+     * Character sets
+     */
+    const CHARS_LOWERS                          = 'abcdefghijklmnopqrstuvwxyz';
+    const CHARS_UPPERS                          = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
+    const CHARS_DIGITS                          = '0123456789';
+
+    /**
+     * Get random generated string
+     *
+     * @param int $len
+     * @param string|null $chars
+     * @return string
+     */
+    public static function getRandomString($len, $chars = null)
+    {
+        if (is_null($chars)) {
+            $chars = self::CHARS_LOWERS . self::CHARS_UPPERS . self::CHARS_DIGITS;
+        }
+        mt_srand(10000000*(double)microtime());
+        for ($i = 0, $str = '', $lc = strlen($chars)-1; $i < $len; $i++) {
+            $str .= $chars[mt_rand(0, $lc)];
+        }
+        return $str;
+    }
+
+    /**
+     * Wrap string with placeholder wrapper
+     *
+     * @param string $string
+     * @return string
+     */
+    public static function wrapPlaceholderString($string)
+    {
+        return '{{' . chr(1) . chr(2) . chr(3) . $string . chr(3) . chr(2) . chr(1) . '}}';
+    }
+
+    /**
+     * Prepare content for saving
+     *
+     * @param string $content
+     */
+    public static function prepareContentPlaceholders(&$content)
+    {
+        /**
+         * Replace all occurrences of session_id with unique marker
+         */
+        Enterprise_PageCache_Helper_Url::replaceSid($content);
+        /**
+         * Replace all occurrences of form_key with unique marker
+         */
+        Enterprise_PageCache_Helper_Form_Key::replaceFormKey($content);
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Helper/Form/Key.php app/code/core/Enterprise/PageCache/Helper/Form/Key.php
new file mode 100644
index 0000000..58983d6
--- /dev/null
+++ app/code/core/Enterprise/PageCache/Helper/Form/Key.php
@@ -0,0 +1,79 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Enterprise
+ * @package     Enterprise_PageCache
+ * @copyright   Copyright (c) 2012 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+/**
+ * PageCache Form Key helper
+ *
+ * @category    Enterprise
+ * @package     Enterprise_PageCache
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Enterprise_PageCache_Helper_Form_Key extends Mage_Core_Helper_Abstract
+{
+    /**
+     * Retrieve unique marker value
+     *
+     * @return string
+     */
+    protected static function _getFormKeyMarker()
+    {
+        return Enterprise_PageCache_Helper_Data::wrapPlaceholderString('_FORM_KEY_MARKER_');
+    }
+
+    /**
+     * Replace form key with placeholder string
+     *
+     * @param string $content
+     * @return bool
+     */
+    public static function replaceFormKey(&$content)
+    {
+        if (!$content) {
+            return $content;
+        }
+        /** @var $session Mage_Core_Model_Session */
+        $session = Mage::getSingleton('core/session');
+        $replacementCount = 0;
+        $content = str_replace($session->getFormKey(), self::_getFormKeyMarker(), $content, $replacementCount);
+        return ($replacementCount > 0);
+    }
+
+    /**
+     * Restore user form key in form key placeholders
+     *
+     * @param string $content
+     * @param string $formKey
+     * @return bool
+     */
+    public static function restoreFormKey(&$content, $formKey)
+    {
+        if (!$content) {
+            return false;
+        }
+        $replacementCount = 0;
+        $content = str_replace(self::_getFormKeyMarker(), $formKey, $content, $replacementCount);
+        return ($replacementCount > 0);
+    }
+}
diff --git app/code/core/Enterprise/PageCache/Helper/Url.php app/code/core/Enterprise/PageCache/Helper/Url.php
index 5730b00..0a833bf 100644
--- app/code/core/Enterprise/PageCache/Helper/Url.php
+++ app/code/core/Enterprise/PageCache/Helper/Url.php
@@ -26,6 +26,10 @@
 
 /**
  * Url processing helper
+ *
+ * @category    Enterprise
+ * @package     Enterprise_PageCache
+ * @author      Magento Core Team <core@magentocommerce.com>
  */
 class Enterprise_PageCache_Helper_Url
 {
@@ -36,7 +40,7 @@ class Enterprise_PageCache_Helper_Url
      */
     protected static function _getSidMarker()
     {
-        return '{{' . chr(1) . chr(2) . chr(3) . '_SID_MARKER_' . chr(3) . chr(2) . chr(1) . '}}';
+        return Enterprise_PageCache_Helper_Data::wrapPlaceholderString('_SID_MARKER_');
     }
 
     /**
@@ -63,7 +67,8 @@ class Enterprise_PageCache_Helper_Url
     /**
      * Restore session_id from marker value
      *
-     * @param  string $content
+     * @param string $content
+     * @param string $sidValue
      * @return bool
      */
     public static function restoreSid(&$content, $sidValue)
diff --git app/code/core/Enterprise/PageCache/Model/Container/Abstract.php app/code/core/Enterprise/PageCache/Model/Container/Abstract.php
index 70866b9..022a160 100644
--- app/code/core/Enterprise/PageCache/Model/Container/Abstract.php
+++ app/code/core/Enterprise/PageCache/Model/Container/Abstract.php
@@ -185,7 +185,7 @@ abstract class Enterprise_PageCache_Model_Container_Abstract
          * Replace all occurrences of session_id with unique marker
          */
         Enterprise_PageCache_Helper_Url::replaceSid($data);
-
+        Enterprise_PageCache_Helper_Data::prepareContentPlaceholders($data);
         Enterprise_PageCache_Model_Cache::getCacheInstance()->save($data, $id, $tags, $lifetime);
         return $this;
     }
diff --git app/code/core/Enterprise/PageCache/Model/Container/Advanced/Abstract.php app/code/core/Enterprise/PageCache/Model/Container/Advanced/Abstract.php
index 23614c4..4b46eb4 100644
--- app/code/core/Enterprise/PageCache/Model/Container/Advanced/Abstract.php
+++ app/code/core/Enterprise/PageCache/Model/Container/Advanced/Abstract.php
@@ -82,10 +82,7 @@ abstract class Enterprise_PageCache_Model_Container_Advanced_Abstract
                 $this->_placeholder->getAttribute('cache_lifetime') : false;
         }
 
-        /**
-         * Replace all occurrences of session_id with unique marker
-         */
-        Enterprise_PageCache_Helper_Url::replaceSid($data);
+        Enterprise_PageCache_Helper_Data::prepareContentPlaceholders($data);
 
         $result = array();
 
diff --git app/code/core/Enterprise/PageCache/Model/Cookie.php app/code/core/Enterprise/PageCache/Model/Cookie.php
index f263388..41b875b 100644
--- app/code/core/Enterprise/PageCache/Model/Cookie.php
+++ app/code/core/Enterprise/PageCache/Model/Cookie.php
@@ -49,6 +49,8 @@ class Enterprise_PageCache_Model_Cookie extends Mage_Core_Model_Cookie
 
     const COOKIE_CUSTOMER_LOGGED_IN = 'CUSTOMER_AUTH';
 
+    const COOKIE_FORM_KEY           = 'CACHED_FRONT_FORM_KEY';
+
     /**
      * Subprocessors cookie names
      */
@@ -210,4 +212,24 @@ class Enterprise_PageCache_Model_Cookie extends Mage_Core_Model_Cookie
     {
         setcookie(self::COOKIE_CATEGORY_ID, $id, 0, '/');
     }
+
+    /**
+     * Set cookie with form key for cached front
+     *
+     * @param string $formKey
+     */
+    public static function setFormKeyCookieValue($formKey)
+    {
+        setcookie(self::COOKIE_FORM_KEY, $formKey, 0, '/');
+    }
+
+    /**
+     * Get form key cookie value
+     *
+     * @return string|bool
+     */
+    public static function getFormKeyCookieValue()
+    {
+        return (isset($_COOKIE[self::COOKIE_FORM_KEY])) ? $_COOKIE[self::COOKIE_FORM_KEY] : false;
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Model/Observer.php app/code/core/Enterprise/PageCache/Model/Observer.php
index 9e03664..f0555be 100755
--- app/code/core/Enterprise/PageCache/Model/Observer.php
+++ app/code/core/Enterprise/PageCache/Model/Observer.php
@@ -678,4 +678,23 @@ class Enterprise_PageCache_Model_Observer
         $segmentsIdsString= implode(',', $segmentIds);
         $this->_getCookie()->set(Enterprise_PageCache_Model_Cookie::CUSTOMER_SEGMENT_IDS, $segmentsIdsString);
     }
+
+    /**
+     * Register form key in session from cookie value
+     *
+     * @param Varien_Event_Observer $observer
+     */
+    public function registerCachedFormKey(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return;
+        }
+
+        /** @var $session Mage_Core_Model_Session  */
+        $session = Mage::getSingleton('core/session');
+        $cachedFrontFormKey = Enterprise_PageCache_Model_Cookie::getFormKeyCookieValue();
+        if ($cachedFrontFormKey) {
+            $session->setData('_form_key', $cachedFrontFormKey);
+        }
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Model/Processor.php app/code/core/Enterprise/PageCache/Model/Processor.php
index c7c3ac8..f9e63d0 100644
--- app/code/core/Enterprise/PageCache/Model/Processor.php
+++ app/code/core/Enterprise/PageCache/Model/Processor.php
@@ -388,6 +388,15 @@ class Enterprise_PageCache_Model_Processor
             $isProcessed = false;
         }
 
+        if (isset($_COOKIE[Enterprise_PageCache_Model_Cookie::COOKIE_FORM_KEY])) {
+            $formKey = $_COOKIE[Enterprise_PageCache_Model_Cookie::COOKIE_FORM_KEY];
+        } else {
+            $formKey = Enterprise_PageCache_Helper_Data::getRandomString(16);
+            Enterprise_PageCache_Model_Cookie::setFormKeyCookieValue($formKey);
+        }
+
+        Enterprise_PageCache_Helper_Form_Key::restoreFormKey($content, $formKey);
+
         /**
          * restore session_id in content whether content is completely processed or not
          */
@@ -507,6 +516,7 @@ class Enterprise_PageCache_Model_Processor
                  * Replace all occurrences of session_id with unique marker
                  */
                 Enterprise_PageCache_Helper_Url::replaceSid($content);
+                Enterprise_PageCache_Helper_Form_Key::replaceFormKey($content);
 
                 if (function_exists('gzcompress')) {
                     $content = gzcompress($content);
@@ -685,7 +695,13 @@ class Enterprise_PageCache_Model_Processor
          * Define request URI
          */
         if ($uri) {
-            if (isset($_SERVER['REQUEST_URI'])) {
+            if (isset($_SERVER['HTTP_X_ORIGINAL_URL'])) {
+                // IIS with Microsoft Rewrite Module
+                $uri.= $_SERVER['HTTP_X_ORIGINAL_URL'];
+            } elseif (isset($_SERVER['HTTP_X_REWRITE_URL'])) {
+                // IIS with ISAPI_Rewrite
+                $uri.= $_SERVER['HTTP_X_REWRITE_URL'];
+            } elseif (isset($_SERVER['REQUEST_URI'])) {
                 $uri.= $_SERVER['REQUEST_URI'];
             } elseif (!empty($_SERVER['IIS_WasUrlRewritten']) && !empty($_SERVER['UNENCODED_URL'])) {
                 $uri.= $_SERVER['UNENCODED_URL'];
diff --git app/code/core/Enterprise/PageCache/etc/config.xml app/code/core/Enterprise/PageCache/etc/config.xml
index 3920644..3ac4eb5 100644
--- app/code/core/Enterprise/PageCache/etc/config.xml
+++ app/code/core/Enterprise/PageCache/etc/config.xml
@@ -245,6 +245,12 @@
                         <method>processPreDispatch</method>
                     </enterprise_pagecache>
                 </observers>
+                <observers>
+                    <enterprise_pagecache>
+                        <class>enterprise_pagecache/observer</class>
+                        <method>registerCachedFormKey</method>
+                    </enterprise_pagecache>
+                </observers>
             </controller_action_predispatch>
             <controller_action_postdispatch_catalog_product_view>
                 <observers>
diff --git app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php
index 9270163..12c2587 100644
--- app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php
+++ app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php
@@ -55,6 +55,13 @@ class Enterprise_Pbridge_Model_Pbridge_Api_Abstract extends Varien_Object
         try {
             $http = new Varien_Http_Adapter_Curl();
             $config = array('timeout' => 60);
+            if (Mage::getStoreConfigFlag('payment/pbridge/verifyssl')) {
+                $config['verifypeer'] = true;
+                $config['verifyhost'] = 2;
+            } else {
+                $config['verifypeer'] = false;
+                $config['verifyhost'] = 0;
+            }
             $http->setConfig($config);
             $http->write(
                 Zend_Http_Client::POST,
diff --git app/code/core/Enterprise/Pbridge/etc/config.xml app/code/core/Enterprise/Pbridge/etc/config.xml
index c8b0a9e..9256cda 100644
--- app/code/core/Enterprise/Pbridge/etc/config.xml
+++ app/code/core/Enterprise/Pbridge/etc/config.xml
@@ -132,6 +132,7 @@
                 <model>enterprise_pbridge/payment_method_pbridge</model>
                 <title>Payment Bridge</title>
                 <debug>0</debug>
+                <verifyssl>0</verifyssl>
             </pbridge>
             <pbridge_paypal_direct>
                 <model>enterprise_pbridge/payment_method_paypal</model>
diff --git app/code/core/Enterprise/Pbridge/etc/system.xml app/code/core/Enterprise/Pbridge/etc/system.xml
index 35fafb4..b970f93 100644
--- app/code/core/Enterprise/Pbridge/etc/system.xml
+++ app/code/core/Enterprise/Pbridge/etc/system.xml
@@ -70,6 +70,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gatewayurl>
+                        <verifyssl translate="label" module="enterprise_pbridge">
+                            <label>Verify SSL Connection</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>50</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verifyssl>
                         <transferkey translate="label" module="enterprise_pbridge">
                             <label>Data Transfer Key</label>
                             <frontend_type>text</frontend_type>
diff --git app/code/core/Enterprise/Pci/Model/Encryption.php app/code/core/Enterprise/Pci/Model/Encryption.php
index b349ec2..cd84d00 100644
--- app/code/core/Enterprise/Pci/Model/Encryption.php
+++ app/code/core/Enterprise/Pci/Model/Encryption.php
@@ -116,10 +116,10 @@ class Enterprise_Pci_Model_Encryption extends Mage_Core_Model_Encryption
         // look for salt
         $hashArr = explode(':', $hash, 2);
         if (1 === count($hashArr)) {
-            return $this->hash($password, $version) === $hash;
+            return hash_equals($this->hash($password, $version), $hash);
         }
         list($hash, $salt) = $hashArr;
-        return $this->hash($salt . $password, $version) === $hash;
+        return hash_equals($this->hash($salt . $password, $version), $hash);
     }
 
     /**
diff --git app/code/core/Enterprise/Wishlist/controllers/SearchController.php app/code/core/Enterprise/Wishlist/controllers/SearchController.php
index e8f4f9f..14491ea 100644
--- app/code/core/Enterprise/Wishlist/controllers/SearchController.php
+++ app/code/core/Enterprise/Wishlist/controllers/SearchController.php
@@ -179,6 +179,9 @@ class Enterprise_Wishlist_SearchController extends Mage_Core_Controller_Front_Ac
      */
     public function addtocartAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $messages   = array();
         $addedItems = array();
         $notSalable = array();
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
index f5a71f6..c44746c 100644
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
index 4e32e97..adbb8d7 100644
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
 
diff --git app/code/core/Mage/Adminhtml/Block/Dashboard/Graph.php app/code/core/Mage/Adminhtml/Block/Dashboard/Graph.php
index c698108..6e256bb 100644
--- app/code/core/Mage/Adminhtml/Block/Dashboard/Graph.php
+++ app/code/core/Mage/Adminhtml/Block/Dashboard/Graph.php
@@ -444,7 +444,7 @@ class Mage_Adminhtml_Block_Dashboard_Graph extends Mage_Adminhtml_Block_Dashboar
             }
             return self::API_URL . '?' . implode('&', $p);
         } else {
-            $gaData = urlencode(base64_encode(serialize($params)));
+            $gaData = urlencode(base64_encode(json_encode($params)));
             $gaHash = Mage::helper('adminhtml/dashboard_data')->getChartDataHash($gaData);
             $params = array('ga' => $gaData, 'h' => $gaHash);
             return $this->getUrl('*/*/tunnel', array('_query' => $params));
diff --git app/code/core/Mage/Adminhtml/Block/Media/Uploader.php app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
index 01be54c..455cdde 100644
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
index 2abbd4c..3809e44 100644
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
index 0695670..ba0565d 100644
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
index eebb471..6eef583 100644
--- app/code/core/Mage/Adminhtml/controllers/DashboardController.php
+++ app/code/core/Mage/Adminhtml/controllers/DashboardController.php
@@ -91,8 +91,9 @@ class Mage_Adminhtml_DashboardController extends Mage_Adminhtml_Controller_Actio
         $gaHash = $this->getRequest()->getParam('h');
         if ($gaData && $gaHash) {
             $newHash = Mage::helper('adminhtml/dashboard_data')->getChartDataHash($gaData);
-            if ($newHash == $gaHash) {
-                if ($params = unserialize(base64_decode(urldecode($gaData)))) {
+            if (hash_equals($newHash, $gaHash)) {
+                $params = json_decode(base64_decode(urldecode($gaData)), true);
+                if ($params) {
                     $response = $httpClient->setUri(Mage_Adminhtml_Block_Dashboard_Graph::API_URL)
                             ->setParameterGet($params)
                             ->setConfig(array('timeout' => 5))
diff --git app/code/core/Mage/Adminhtml/controllers/IndexController.php app/code/core/Mage/Adminhtml/controllers/IndexController.php
index 9acadab..f10af88 100644
--- app/code/core/Mage/Adminhtml/controllers/IndexController.php
+++ app/code/core/Mage/Adminhtml/controllers/IndexController.php
@@ -392,7 +392,7 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
         }
 
         $userToken = $user->getRpToken();
-        if (strcmp($userToken, $resetPasswordLinkToken) != 0 || $user->isResetPasswordLinkTokenExpired()) {
+        if (!hash_equals($userToken, $resetPasswordLinkToken) || $user->isResetPasswordLinkTokenExpired()) {
             throw Mage::exception('Mage_Core', Mage::helper('adminhtml')->__('Your password reset link has expired.'));
         }
     }
diff --git app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
index 1305800..2358839 100644
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
diff --git app/code/core/Mage/Catalog/Block/Product/Abstract.php app/code/core/Mage/Catalog/Block/Product/Abstract.php
index 65efc78..2a61ae5 100644
--- app/code/core/Mage/Catalog/Block/Product/Abstract.php
+++ app/code/core/Mage/Catalog/Block/Product/Abstract.php
@@ -34,6 +34,11 @@
  */
 abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Template
 {
+    /**
+     * Price block array
+     *
+     * @var array
+     */
     protected $_priceBlock = array();
 
     /**
@@ -43,10 +48,25 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     protected $_block = 'catalog/product_price';
 
+    /**
+     * Price template
+     *
+     * @var string
+     */
     protected $_priceBlockDefaultTemplate = 'catalog/product/price.phtml';
 
+    /**
+     * Tier price template
+     *
+     * @var string
+     */
     protected $_tierPriceDefaultTemplate  = 'catalog/product/view/tierprices.phtml';
 
+    /**
+     * Price types
+     *
+     * @var array
+     */
     protected $_priceBlockTypes = array();
 
     /**
@@ -56,6 +76,11 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     protected $_useLinkForAsLowAs = true;
 
+    /**
+     * Review block instance
+     *
+     * @var null|Mage_Review_Block_Helper
+     */
     protected $_reviewsHelperBlock;
 
     /**
@@ -89,18 +114,33 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getAddToCartUrl($product, $additional = array())
     {
-        if ($product->getTypeInstance(true)->hasRequiredOptions($product)) {
-            if (!isset($additional['_escape'])) {
-                $additional['_escape'] = true;
-            }
-            if (!isset($additional['_query'])) {
-                $additional['_query'] = array();
-            }
-            $additional['_query']['options'] = 'cart';
-
-            return $this->getProductUrl($product, $additional);
+        if (!$product->getTypeInstance(true)->hasRequiredOptions($product)) {
+            return $this->helper('checkout/cart')->getAddUrl($product, $additional);
         }
-        return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+        $additional = array_merge(
+            $additional,
+            array(Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey())
+        );
+        if (!isset($additional['_escape'])) {
+            $additional['_escape'] = true;
+        }
+        if (!isset($additional['_query'])) {
+            $additional['_query'] = array();
+        }
+        $additional['_query']['options'] = 'cart';
+        return $this->getProductUrl($product, $additional);
+    }
+
+    /**
+     * Return model instance
+     *
+     * @param string $className
+     * @param array $arguments
+     * @return Mage_Core_Model_Abstract
+     */
+    protected function _getSingletonModel($className, $arguments = array())
+    {
+        return Mage::getSingleton($className, $arguments);
     }
 
     /**
@@ -126,7 +166,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
     }
 
     /**
-     * Enter description here...
+     * Return link to Add to Wishlist
      *
      * @param Mage_Catalog_Model_Product $product
      * @return string
@@ -155,6 +195,12 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
         return null;
     }
 
+    /**
+     * Return price block
+     *
+     * @param string $productTypeId
+     * @return mixed
+     */
     protected function _getPriceBlock($productTypeId)
     {
         if (!isset($this->_priceBlock[$productTypeId])) {
@@ -169,6 +215,12 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
         return $this->_priceBlock[$productTypeId];
     }
 
+    /**
+     * Return Block template
+     *
+     * @param string $productTypeId
+     * @return string
+     */
     protected function _getPriceBlockTemplate($productTypeId)
     {
         if (isset($this->_priceBlockTypes[$productTypeId])) {
@@ -304,6 +356,11 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
         return $this->getData('product');
     }
 
+    /**
+     * Return tier price template
+     *
+     * @return mixed|string
+     */
     public function getTierPriceTemplate()
     {
         if (!$this->hasData('tier_price_template')) {
@@ -419,13 +476,13 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      *
      * @return string
      */
-    public function getImageLabel($product=null, $mediaAttributeCode='image')
+    public function getImageLabel($product = null, $mediaAttributeCode = 'image')
     {
         if (is_null($product)) {
             $product = $this->getProduct();
         }
 
-        $label = $product->getData($mediaAttributeCode.'_label');
+        $label = $product->getData($mediaAttributeCode . '_label');
         if (empty($label)) {
             $label = $product->getName();
         }
diff --git app/code/core/Mage/Catalog/Block/Product/View.php app/code/core/Mage/Catalog/Block/Product/View.php
index 0a9e39c..0064add 100644
--- app/code/core/Mage/Catalog/Block/Product/View.php
+++ app/code/core/Mage/Catalog/Block/Product/View.php
@@ -61,7 +61,7 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
             $currentCategory = Mage::registry('current_category');
             if ($keyword) {
                 $headBlock->setKeywords($keyword);
-            } elseif($currentCategory) {
+            } elseif ($currentCategory) {
                 $headBlock->setKeywords($product->getName());
             }
             $description = $product->getMetaDescription();
@@ -71,7 +71,7 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
                 $headBlock->setDescription(Mage::helper('core/string')->substr($product->getDescription(), 0, 255));
             }
             if ($this->helper('catalog/product')->canUseCanonicalTag()) {
-                $params = array('_ignore_category'=>true);
+                $params = array('_ignore_category' => true);
                 $headBlock->addLinkRel('canonical', $product->getUrlModel()->getUrl($product, $params));
             }
         }
@@ -117,7 +117,7 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
             return $this->getCustomAddToCartUrl();
         }
 
-        if ($this->getRequest()->getParam('wishlist_next')){
+        if ($this->getRequest()->getParam('wishlist_next')) {
             $additional['wishlist_next'] = 1;
         }
 
@@ -191,9 +191,9 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
         );
 
         $responseObject = new Varien_Object();
-        Mage::dispatchEvent('catalog_product_view_config', array('response_object'=>$responseObject));
+        Mage::dispatchEvent('catalog_product_view_config', array('response_object' => $responseObject));
         if (is_array($responseObject->getAdditionalOptions())) {
-            foreach ($responseObject->getAdditionalOptions() as $option=>$value) {
+            foreach ($responseObject->getAdditionalOptions() as $option => $value) {
                 $config[$option] = $value;
             }
         }
diff --git app/code/core/Mage/Catalog/Helper/Image.php app/code/core/Mage/Catalog/Helper/Image.php
index c7f957d..8532dc1 100644
--- app/code/core/Mage/Catalog/Helper/Image.php
+++ app/code/core/Mage/Catalog/Helper/Image.php
@@ -31,6 +31,8 @@
  */
 class Mage_Catalog_Helper_Image extends Mage_Core_Helper_Abstract
 {
+    const XML_NODE_PRODUCT_MAX_DIMENSION = 'catalog/product_image/max_dimension';
+
     /**
      * Current model
      *
@@ -631,10 +633,16 @@ class Mage_Catalog_Helper_Image extends Mage_Core_Helper_Abstract
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
diff --git app/code/core/Mage/Catalog/Helper/Product/Compare.php app/code/core/Mage/Catalog/Helper/Product/Compare.php
index e445dc8..5cfc660 100644
--- app/code/core/Mage/Catalog/Helper/Product/Compare.php
+++ app/code/core/Mage/Catalog/Helper/Product/Compare.php
@@ -79,17 +79,17 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getListUrl()
     {
-         $itemIds = array();
-         foreach ($this->getItemCollection() as $item) {
-             $itemIds[] = $item->getId();
-         }
+        $itemIds = array();
+        foreach ($this->getItemCollection() as $item) {
+            $itemIds[] = $item->getId();
+        }
 
-         $params = array(
-            'items'=>implode(',', $itemIds),
+        $params = array(
+            'items' => implode(',', $itemIds),
             Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl()
-         );
+        );
 
-         return $this->_getUrl('catalog/product_compare', $params);
+        return $this->_getUrl('catalog/product_compare', $params);
     }
 
     /**
@@ -102,7 +102,8 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
     {
         return array(
             'product' => $product->getId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl()
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl(),
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
     }
 
@@ -128,7 +129,8 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
         $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
 
         $params = array(
-            'product'=>$product->getId(),
+            'product' => $product->getId(),
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey(),
             Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl)
         );
 
@@ -143,10 +145,11 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getAddToCartUrl($product)
     {
-        $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
+        $beforeCompareUrl = $this->_getSingletonModel('catalog/session')->getBeforeCompareUrl();
         $params = array(
-            'product'=>$product->getId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl)
+            'product' => $product->getId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl),
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
 
         return $this->_getUrl('checkout/cart/add', $params);
@@ -161,7 +164,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
     public function getRemoveUrl($item)
     {
         $params = array(
-            'product'=>$item->getId(),
+            'product' => $item->getId(),
             Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl()
         );
         return $this->_getUrl('catalog/product_compare/remove', $params);
diff --git app/code/core/Mage/Catalog/Model/Resource/Layer/Filter/Price.php app/code/core/Mage/Catalog/Model/Resource/Layer/Filter/Price.php
index 7e3919c..75f5fdd 100755
--- app/code/core/Mage/Catalog/Model/Resource/Layer/Filter/Price.php
+++ app/code/core/Mage/Catalog/Model/Resource/Layer/Filter/Price.php
@@ -269,7 +269,7 @@ class Mage_Catalog_Model_Resource_Layer_Filter_Price extends Mage_Core_Model_Res
             'range' => $rangeExpr,
             'count' => $countExpr
         ));
-        $select->group($rangeExpr)->order("$rangeExpr ASC");
+        $select->group('range')->order('range ' . Varien_Data_Collection::SORT_ORDER_ASC);
 
         return $this->_getReadAdapter()->fetchPairs($select);
     }
diff --git app/code/core/Mage/Catalog/controllers/Product/CompareController.php app/code/core/Mage/Catalog/controllers/Product/CompareController.php
index ca6101c..54aea41 100644
--- app/code/core/Mage/Catalog/controllers/Product/CompareController.php
+++ app/code/core/Mage/Catalog/controllers/Product/CompareController.php
@@ -74,6 +74,11 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
      */
     public function addAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_redirectReferer();
+            return;
+        }
+
         $productId = (int) $this->getRequest()->getParam('product');
         if ($productId
             && (Mage::getSingleton('log/visitor')->getId() || Mage::getSingleton('customer/session')->isLoggedIn())
diff --git app/code/core/Mage/Catalog/etc/config.xml app/code/core/Mage/Catalog/etc/config.xml
index 3610e60..8099322 100644
--- app/code/core/Mage/Catalog/etc/config.xml
+++ app/code/core/Mage/Catalog/etc/config.xml
@@ -771,6 +771,9 @@
             <product>
                 <default_tax_group>2</default_tax_group>
             </product>
+            <product_image>
+                <max_dimension>5000</max_dimension>
+            </product_image>
             <seo>
                 <product_url_suffix>.html</product_url_suffix>
                 <category_url_suffix>.html</category_url_suffix>
diff --git app/code/core/Mage/Catalog/etc/system.xml app/code/core/Mage/Catalog/etc/system.xml
index 2cfad3d..fc2ca8e 100644
--- app/code/core/Mage/Catalog/etc/system.xml
+++ app/code/core/Mage/Catalog/etc/system.xml
@@ -185,6 +185,24 @@
                         </lines_perpage>
                     </fields>
                 </sitemap>
+                <product_image translate="label">
+                    <label>Product Image</label>
+                    <sort_order>200</sort_order>
+                    <show_in_default>1</show_in_default>
+                    <show_in_website>1</show_in_website>
+                    <show_in_store>1</show_in_store>
+                    <fields>
+                        <max_dimension translate="label comment">
+                            <label>Maximum resolution for upload image</label>
+                            <comment>Maximum width and height resolutions for upload image</comment>
+                            <frontend_type>text</frontend_type>
+                            <sort_order>10</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>1</show_in_store>
+                        </max_dimension>
+                    </fields>
+                </product_image>
                 <placeholder translate="label">
                     <label>Product Image Placeholders</label>
                     <clone_fields>1</clone_fields>
diff --git app/code/core/Mage/Centinel/Model/Api.php app/code/core/Mage/Centinel/Model/Api.php
index d32afce..de05f2d 100644
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
index 0000000..ae8dcaf
--- /dev/null
+++ app/code/core/Mage/Centinel/Model/Api/Client.php
@@ -0,0 +1,79 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Centinel
+ * @copyright Copyright (c) 2006-2014 X.commerce, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
diff --git app/code/core/Mage/Checkout/Helper/Cart.php app/code/core/Mage/Checkout/Helper/Cart.php
index 6e824a1..1617aef 100644
--- app/code/core/Mage/Checkout/Helper/Cart.php
+++ app/code/core/Mage/Checkout/Helper/Cart.php
@@ -31,6 +31,9 @@
  */
 class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
 {
+    /**
+     * Redirect to Cart path
+     */
     const XML_PATH_REDIRECT_TO_CART         = 'checkout/cart/redirect_to_cart';
 
     /**
@@ -47,16 +50,16 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
      * Retrieve url for add product to cart
      *
      * @param   Mage_Catalog_Model_Product $product
+     * @param array $additional
      * @return  string
      */
     public function getAddUrl($product, $additional = array())
     {
-        $continueUrl    = Mage::helper('core')->urlEncode($this->getCurrentUrl());
-        $urlParamName   = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
-
         $routeParams = array(
-            $urlParamName   => $continueUrl,
-            'product'       => $product->getEntityId()
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->_getHelperInstance('core')
+                ->urlEncode($this->getCurrentUrl()),
+            'product' => $product->getEntityId(),
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
 
         if (!empty($additional)) {
@@ -77,6 +80,17 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
     }
 
     /**
+     * Return helper instance
+     *
+     * @param  string $helperName
+     * @return Mage_Core_Helper_Abstract
+     */
+    protected function _getHelperInstance($helperName)
+    {
+        return Mage::helper($helperName);
+    }
+
+    /**
      * Retrieve url for remove product from cart
      *
      * @param   Mage_Sales_Quote_Item $item
@@ -85,7 +99,7 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
     public function getRemoveUrl($item)
     {
         $params = array(
-            'id'=>$item->getId(),
+            'id' => $item->getId(),
             Mage_Core_Controller_Front_Action::PARAM_NAME_BASE64_URL => $this->getCurrentBase64Url()
         );
         return $this->_getUrl('checkout/cart/delete', $params);
diff --git app/code/core/Mage/Checkout/controllers/CartController.php app/code/core/Mage/Checkout/controllers/CartController.php
index 3e4a7c7..36a7f35 100644
--- app/code/core/Mage/Checkout/controllers/CartController.php
+++ app/code/core/Mage/Checkout/controllers/CartController.php
@@ -70,6 +70,7 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
      * Set back redirect url to response
      *
      * @return Mage_Checkout_CartController
+     * @throws Mage_Exception
      */
     protected function _goBack()
     {
@@ -166,9 +167,15 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
 
     /**
      * Add product to shopping cart action
+     *
+     * @return void
      */
     public function addAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_goBack();
+            return;
+        }
         $cart   = $this->_getCart();
         $params = $this->getRequest()->getParams();
         try {
@@ -207,7 +214,7 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
             );
 
             if (!$this->_getSession()->getNoCartRedirect(true)) {
-                if (!$cart->getQuote()->getHasError()){
+                if (!$cart->getQuote()->getHasError()) {
                     $message = $this->__('%s was added to your shopping cart.', Mage::helper('core')->escapeHtml($product->getName()));
                     $this->_getSession()->addSuccess($message);
                 }
@@ -236,34 +243,41 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
         }
     }
 
+    /**
+     * Add products in group to shopping cart action
+     */
     public function addgroupAction()
     {
         $orderItemIds = $this->getRequest()->getParam('order_items', array());
-        if (is_array($orderItemIds)) {
-            $itemsCollection = Mage::getModel('sales/order_item')
-                ->getCollection()
-                ->addIdFilter($orderItemIds)
-                ->load();
-            /* @var $itemsCollection Mage_Sales_Model_Mysql4_Order_Item_Collection */
-            $cart = $this->_getCart();
-            foreach ($itemsCollection as $item) {
-                try {
-                    $cart->addOrderItem($item, 1);
-                } catch (Mage_Core_Exception $e) {
-                    if ($this->_getSession()->getUseNotice(true)) {
-                        $this->_getSession()->addNotice($e->getMessage());
-                    } else {
-                        $this->_getSession()->addError($e->getMessage());
-                    }
-                } catch (Exception $e) {
-                    $this->_getSession()->addException($e, $this->__('Cannot add the item to shopping cart.'));
-                    Mage::logException($e);
-                    $this->_goBack();
+
+        if (!is_array($orderItemIds) || !$this->_validateFormKey()) {
+            $this->_goBack();
+            return;
+        }
+
+        $itemsCollection = Mage::getModel('sales/order_item')
+            ->getCollection()
+            ->addIdFilter($orderItemIds)
+            ->load();
+        /* @var $itemsCollection Mage_Sales_Model_Mysql4_Order_Item_Collection */
+        $cart = $this->_getCart();
+        foreach ($itemsCollection as $item) {
+            try {
+                $cart->addOrderItem($item, 1);
+            } catch (Mage_Core_Exception $e) {
+                if ($this->_getSession()->getUseNotice(true)) {
+                    $this->_getSession()->addNotice($e->getMessage());
+                } else {
+                    $this->_getSession()->addError($e->getMessage());
                 }
+            } catch (Exception $e) {
+                $this->_getSession()->addException($e, $this->__('Cannot add the item to shopping cart.'));
+                Mage::logException($e);
+                $this->_goBack();
             }
-            $cart->save();
-            $this->_getSession()->setCartWasUpdated(true);
         }
+        $cart->save();
+        $this->_getSession()->setCartWasUpdated(true);
         $this->_goBack();
     }
 
@@ -347,8 +361,8 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
                 array('item' => $item, 'request' => $this->getRequest(), 'response' => $this->getResponse())
             );
             if (!$this->_getSession()->getNoCartRedirect(true)) {
-                if (!$cart->getQuote()->getHasError()){
-                    $message = $this->__('%s was updated in your shopping cart.', Mage::helper('core')->htmlEscape($item->getProduct()->getName()));
+                if (!$cart->getQuote()->getHasError()) {
+                    $message = $this->__('%s was updated in your shopping cart.', Mage::helper('core')->escapeHtml($item->getProduct()->getName()));
                     $this->_getSession()->addSuccess($message);
                 }
                 $this->_goBack();
@@ -382,6 +396,11 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
      */
     public function updatePostAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_redirect('*/*/');
+            return;
+        }
+
         $updateAction = (string)$this->getRequest()->getParam('update_cart_action');
 
         switch ($updateAction) {
@@ -492,6 +511,11 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
         $this->_goBack();
     }
 
+    /**
+     * Estimate update action
+     *
+     * @return null
+     */
     public function estimateUpdatePostAction()
     {
         $code = (string) $this->getRequest()->getParam('estimate_method');
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index d56d263..2b8eec7 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -24,16 +24,27 @@
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 
-
+/**
+ * Class Onepage controller
+ */
 class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
 {
+    /**
+     * Functions for concrete method
+     *
+     * @var array
+     */
     protected $_sectionUpdateFunctions = array(
         'payment-method'  => '_getPaymentMethodsHtml',
         'shipping-method' => '_getShippingMethodsHtml',
         'review'          => '_getReviewHtml',
     );
 
-    /** @var Mage_Sales_Model_Order */
+    /**
+     * Order instance
+     *
+     * @var Mage_Sales_Model_Order
+     */
     protected $_order;
 
     /**
@@ -50,7 +61,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             $checkoutSessionQuote->removeAllAddresses();
         }
 
-        if(!$this->_canShowForUnregisteredUsers()){
+        if (!$this->_canShowForUnregisteredUsers()) {
             $this->norouteAction();
             $this->setFlag('',self::FLAG_NO_DISPATCH,true);
             return;
@@ -59,6 +70,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         return $this;
     }
 
+    /**
+     * Send headers in case if session is expired
+     *
+     * @return Mage_Checkout_OnepageController
+     */
     protected function _ajaxRedirectResponse()
     {
         $this->getResponse()
@@ -123,6 +139,12 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         return $output;
     }
 
+    /**
+     * Return block content from the 'checkout_onepage_additional'
+     * This is the additional content for shipping method
+     *
+     * @return string
+     */
     protected function _getAdditionalHtml()
     {
         $layout = $this->getLayout();
@@ -180,7 +202,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             return;
         }
         Mage::getSingleton('checkout/session')->setCartWasUpdated(false);
-        Mage::getSingleton('customer/session')->setBeforeAuthUrl(Mage::getUrl('*/*/*', array('_secure'=>true)));
+        Mage::getSingleton('customer/session')->setBeforeAuthUrl(Mage::getUrl('*/*/*', array('_secure' => true)));
         $this->getOnepage()->initCheckout();
         $this->loadLayout();
         $this->_initLayoutMessages('customer/session');
@@ -200,6 +222,9 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         $this->renderLayout();
     }
 
+    /**
+     * Shipping action
+     */
     public function shippingMethodAction()
     {
         if ($this->_expireAjax()) {
@@ -209,6 +234,9 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         $this->renderLayout();
     }
 
+    /**
+     * Review action
+     */
     public function reviewAction()
     {
         if ($this->_expireAjax()) {
@@ -244,6 +272,9 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         $this->renderLayout();
     }
 
+    /**
+     * Failure action
+     */
     public function failureAction()
     {
         $lastQuoteId = $this->getOnepage()->getCheckout()->getLastQuoteId();
@@ -259,6 +290,9 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
     }
 
 
+    /**
+     * Additional action
+     */
     public function getAdditionalAction()
     {
         $this->getResponse()->setBody($this->_getAdditionalHtml());
@@ -383,10 +417,10 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             /*
             $result will have erro data if shipping method is empty
             */
-            if(!$result) {
+            if (!$result) {
                 Mage::dispatchEvent('checkout_controller_onepage_save_shipping_method',
-                        array('request'=>$this->getRequest(),
-                            'quote'=>$this->getOnepage()->getQuote()));
+                    array('request' => $this->getRequest(),
+                        'quote' => $this->getOnepage()->getQuote()));
                 $this->getOnepage()->getQuote()->collectTotals();
                 $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
 
@@ -452,7 +486,8 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
     /**
      * Get Order by quoteId
      *
-     * @return Mage_Sales_Model_Order
+     * @return Mage_Core_Model_Abstract|Mage_Sales_Model_Order
+     * @throws Mage_Payment_Model_Info_Exception
      */
     protected function _getOrder()
     {
@@ -489,15 +524,21 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
      */
     public function saveOrderAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
+
         if ($this->_expireAjax()) {
             return;
         }
 
         $result = array();
         try {
-            if ($requiredAgreements = Mage::helper('checkout')->getRequiredAgreementIds()) {
+            $requiredAgreements = Mage::helper('checkout')->getRequiredAgreementIds();
+            if ($requiredAgreements) {
                 $postedAgreements = array_keys($this->getRequest()->getPost('agreement', array()));
-                if ($diff = array_diff($requiredAgreements, $postedAgreements)) {
+                $diff = array_diff($requiredAgreements, $postedAgreements);
+                if ($diff) {
                     $result['success'] = false;
                     $result['error'] = true;
                     $result['error_messages'] = $this->__('Please agree to all the terms and conditions before placing the order.');
@@ -515,7 +556,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             $result['error']   = false;
         } catch (Mage_Payment_Model_Info_Exception $e) {
             $message = $e->getMessage();
-            if( !empty($message) ) {
+            if ( !empty($message) ) {
                 $result['error_messages'] = $message;
             }
             $result['goto_section'] = 'payment';
@@ -530,12 +571,13 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             $result['error'] = true;
             $result['error_messages'] = $e->getMessage();
 
-            if ($gotoSection = $this->getOnepage()->getCheckout()->getGotoSection()) {
+            $gotoSection = $this->getOnepage()->getCheckout()->getGotoSection();
+            if ($gotoSection) {
                 $result['goto_section'] = $gotoSection;
                 $this->getOnepage()->getCheckout()->setGotoSection(null);
             }
-
-            if ($updateSection = $this->getOnepage()->getCheckout()->getUpdateSection()) {
+            $updateSection = $this->getOnepage()->getCheckout()->getUpdateSection();
+            if ($updateSection) {
                 if (isset($this->_sectionUpdateFunctions[$updateSection])) {
                     $updateSectionFunction = $this->_sectionUpdateFunctions[$updateSection];
                     $result['update_section'] = array(
diff --git app/code/core/Mage/Core/Block/Abstract.php app/code/core/Mage/Core/Block/Abstract.php
index 93fff12..17b135f 100644
--- app/code/core/Mage/Core/Block/Abstract.php
+++ app/code/core/Mage/Core/Block/Abstract.php
@@ -38,6 +38,10 @@
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
@@ -1233,7 +1237,13 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
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
index 358115a..88cdbb2 100644
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
 
@@ -65,7 +65,13 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
         return $this->urlEncode($this->getCurrentUrl());
     }
 
-    public function getEncodedUrl($url=null)
+    /**
+     * Return encoded url
+     *
+     * @param null|string $url
+     * @return string
+     */
+    public function getEncodedUrl($url = null)
     {
         if (!$url) {
             $url = $this->getCurrentUrl();
@@ -83,6 +89,12 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
         return Mage::getBaseUrl();
     }
 
+    /**
+     * Formatting string
+     *
+     * @param string $string
+     * @return string
+     */
     protected function _prepareString($string)
     {
         $string = preg_replace('#[^0-9a-z]+#i', '-', $string);
@@ -104,7 +116,7 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
         $startDelimiter = (false === strpos($url,'?'))? '?' : '&';
 
         $arrQueryParams = array();
-        foreach($param as $key=>$value) {
+        foreach ($param as $key => $value) {
             if (is_numeric($key) || is_object($value)) {
                 continue;
             }
@@ -128,6 +140,7 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
      *
      * @param string $url
      * @param string $paramKey
+     * @param boolean $caseSensitive
      * @return string
      */
     public function removeRequestParam($url, $paramKey, $caseSensitive = false)
@@ -143,4 +156,16 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
         }
         return $url;
     }
+
+    /**
+     * Return singleton model instance
+     *
+     * @param string $name
+     * @param array $arguments
+     * @return Mage_Core_Model_Abstract
+     */
+    protected function _getSingletonModel($name, $arguments = array())
+    {
+        return Mage::getSingleton($name, $arguments);
+    }
 }
diff --git app/code/core/Mage/Core/Model/Encryption.php app/code/core/Mage/Core/Model/Encryption.php
index 8d0167b..4c8da11 100644
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
index d740759..51c7a9f 100644
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
diff --git app/code/core/Mage/Core/Model/Url.php app/code/core/Mage/Core/Model/Url.php
index 354d0fe..ab111cc 100644
--- app/code/core/Mage/Core/Model/Url.php
+++ app/code/core/Mage/Core/Model/Url.php
@@ -89,14 +89,31 @@ class Mage_Core_Model_Url extends Varien_Object
     const DEFAULT_ACTION_NAME       = 'index';
 
     /**
-     * Configuration paths
+     * XML base url path unsecure
      */
     const XML_PATH_UNSECURE_URL     = 'web/unsecure/base_url';
+
+    /**
+     * XML base url path secure
+     */
     const XML_PATH_SECURE_URL       = 'web/secure/base_url';
+
+    /**
+     * XML path for using in adminhtml
+     */
     const XML_PATH_SECURE_IN_ADMIN  = 'default/web/secure/use_in_adminhtml';
+
+    /**
+     * XML path for using in frontend
+     */
     const XML_PATH_SECURE_IN_FRONT  = 'web/secure/use_in_frontend';
 
     /**
+     * Param name for form key functionality
+     */
+    const FORM_KEY = 'form_key';
+
+    /**
      * Configuration data cache
      *
      * @var array
@@ -483,7 +500,7 @@ class Mage_Core_Model_Url extends Varien_Object
             }
             $routePath = $this->getActionPath();
             if ($this->getRouteParams()) {
-                foreach ($this->getRouteParams() as $key=>$value) {
+                foreach ($this->getRouteParams() as $key => $value) {
                     if (is_null($value) || false === $value || '' === $value || !is_scalar($value)) {
                         continue;
                     }
@@ -939,8 +956,8 @@ class Mage_Core_Model_Url extends Varien_Object
     /**
      * Build url by requested path and parameters
      *
-     * @param   string|null $routePath
-     * @param   array|null $routeParams
+     * @param string|null $routePath
+     * @param array|null $routeParams
      * @return  string
      */
     public function getUrl($routePath = null, $routeParams = null)
@@ -974,6 +991,7 @@ class Mage_Core_Model_Url extends Varien_Object
             $noSid = (bool)$routeParams['_nosid'];
             unset($routeParams['_nosid']);
         }
+
         $url = $this->getRouteUrl($routePath, $routeParams);
         /**
          * Apply query params, need call after getRouteUrl for rewrite _current values
@@ -1007,6 +1025,18 @@ class Mage_Core_Model_Url extends Varien_Object
     }
 
     /**
+     * Return singleton model instance
+     *
+     * @param string $name
+     * @param array $arguments
+     * @return Mage_Core_Model_Abstract
+     */
+    protected function _getSingletonModel($name, $arguments = array())
+    {
+        return Mage::getSingleton($name, $arguments);
+    }
+
+    /**
      * Check and add session id to URL
      *
      * @param string $url
diff --git app/code/core/Mage/Core/functions.php app/code/core/Mage/Core/functions.php
index 493d0d5..b41a457 100644
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
index 20a507c..a27d073 100644
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
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 4ce08af..65653c9 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -140,6 +140,11 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     public function loginPostAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_redirect('*/*/');
+            return;
+        }
+
         if ($this->_getSession()->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
@@ -157,8 +162,8 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 } catch (Mage_Core_Exception $e) {
                     switch ($e->getCode()) {
                         case Mage_Customer_Model_Customer::EXCEPTION_EMAIL_NOT_CONFIRMED:
-                            $value = Mage::helper('customer')->getEmailConfirmationUrl($login['username']);
-                            $message = Mage::helper('customer')->__('This account is not confirmed. <a href="%s">Click here</a> to resend confirmation email.', $value);
+                            $value = $this->_getHelper('customer')->getEmailConfirmationUrl($login['username']);
+                            $message = $this->_getHelper('customer')->__('This account is not confirmed. <a href="%s">Click here</a> to resend confirmation email.', $value);
                             break;
                         case Mage_Customer_Model_Customer::EXCEPTION_INVALID_EMAIL_OR_PASSWORD:
                             $message = $e->getMessage();
@@ -188,7 +193,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 
         if (!$session->getBeforeAuthUrl() || $session->getBeforeAuthUrl() == Mage::getBaseUrl()) {
             // Set default URL to redirect customer to
-            $session->setBeforeAuthUrl(Mage::helper('customer')->getAccountUrl());
+            $session->setBeforeAuthUrl($this->_getHelper('customer')->getAccountUrl());
             // Redirect customer to the last page visited after logging in
             if ($session->isLoggedIn()) {
                 if (!Mage::getStoreConfigFlag(
@@ -197,8 +202,8 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $referer = $this->getRequest()->getParam(Mage_Customer_Helper_Data::REFERER_QUERY_PARAM_NAME);
                     if ($referer) {
                         // Rebuild referer URL to handle the case when SID was changed
-                        $referer = Mage::getModel('core/url')
-                            ->getRebuiltUrl(Mage::helper('core')->urlDecode($referer));
+                        $referer = $this->_getModel('core/url')
+                            ->getRebuiltUrl($this->_getHelper('core')->urlDecode($referer));
                         if ($this->_isUrlInternal($referer)) {
                             $session->setBeforeAuthUrl($referer);
                         }
@@ -207,10 +212,10 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $session->setBeforeAuthUrl($session->getAfterAuthUrl(true));
                 }
             } else {
-                $session->setBeforeAuthUrl(Mage::helper('customer')->getLoginUrl());
+                $session->setBeforeAuthUrl($this->_getHelper('customer')->getLoginUrl());
             }
-        } else if ($session->getBeforeAuthUrl() == Mage::helper('customer')->getLogoutUrl()) {
-            $session->setBeforeAuthUrl(Mage::helper('customer')->getDashboardUrl());
+        } else if ($session->getBeforeAuthUrl() == $this->_getHelper('customer')->getLogoutUrl()) {
+            $session->setBeforeAuthUrl($this->_getHelper('customer')->getDashboardUrl());
         } else {
             if (!$session->getAfterAuthUrl()) {
                 $session->setAfterAuthUrl($session->getBeforeAuthUrl());
@@ -267,125 +272,254 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             return;
         }
 
+        /** @var $session Mage_Customer_Model_Session */
         $session = $this->_getSession();
         if ($session->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
         }
 
-        if ($this->getRequest()->isPost()) {
-            $errors = array();
+        if (!$this->getRequest()->isPost()) {
+            $errUrl = $this->_getUrl('*/*/create', array('_secure' => true));
+            $this->_redirectError($errUrl);
+            return;
+        }
 
-            if (!$customer = Mage::registry('current_customer')) {
-                $customer = Mage::getModel('customer/customer')->setId(null);
+        $customer = $this->_getCustomer();
+
+        try {
+            $errors = $this->_getCustomerErrors($customer);
+
+            if (empty($errors)) {
+                $customer->save();
+                $this->_dispatchRegisterSuccess($customer);
+                $this->_successProcessRegistration($customer);
+                return;
+            } else {
+                $this->_addSessionError($errors);
+            }
+        } catch (Mage_Core_Exception $e) {
+            $session->setCustomerFormData($this->getRequest()->getPost());
+            if ($e->getCode() === Mage_Customer_Model_Customer::EXCEPTION_EMAIL_EXISTS) {
+                $url = $this->_getUrl('customer/account/forgotpassword');
+                $message = $this->__('There is already an account with this email address. If you are sure that it is your email address, <a href="%s">click here</a> to get your password and access your account.', $url);
+            } else {
+                $message = Mage::helper('core')->escapeHtml($e->getMessage());
             }
+            $session->addError($message);
+        } catch (Exception $e) {
+            $session->setCustomerFormData($this->getRequest()->getPost())
+                ->addException($e, $this->__('Cannot save the customer.'));
+        }
+        $url = $this->_getUrl('*/*/create', array('_secure' => true));
+        $this->_redirectError($url);
+    }
 
-            /* @var $customerForm Mage_Customer_Model_Form */
-            $customerForm = Mage::getModel('customer/form');
-            $customerForm->setFormCode('customer_account_create')
-                ->setEntity($customer);
+    /**
+     * Success Registration
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @return Mage_Customer_AccountController
+     */
+    protected function _successProcessRegistration(Mage_Customer_Model_Customer $customer)
+    {
+        $session = $this->_getSession();
+        if ($customer->isConfirmationRequired()) {
+            /** @var $app Mage_Core_Model_App */
+            $app = $this->_getApp();
+            /** @var $store  Mage_Core_Model_Store*/
+            $store = $app->getStore();
+            $customer->sendNewAccountEmail(
+                'confirmation',
+                $session->getBeforeAuthUrl(),
+                $store->getId()
+            );
+            $customerHelper = $this->_getHelper('customer');
+            $session->addSuccess($this->__('Account confirmation is required. Please, check your email for the confirmation link. To resend the confirmation email please <a href="%s">click here</a>.',
+                $customerHelper->getEmailConfirmationUrl($customer->getEmail())));
+            $url = $this->_getUrl('*/*/index', array('_secure' => true));
+        } else {
+            $session->setCustomerAsLoggedIn($customer);
+            $session->renewSession();
+            $url = $this->_welcomeCustomer($customer);
+        }
+        $this->_redirectSuccess($url);
+        return $this;
+    }
 
-            $customerData = $customerForm->extractData($this->getRequest());
+    /**
+     * Get Customer Model
+     *
+     * @return Mage_Customer_Model_Customer
+     */
+    protected function _getCustomer()
+    {
+        $customer = $this->_getFromRegistry('current_customer');
+        if (!$customer) {
+            $customer = $this->_getModel('customer/customer')->setId(null);
+        }
+        if ($this->getRequest()->getParam('is_subscribed', false)) {
+            $customer->setIsSubscribed(1);
+        }
+        /**
+         * Initialize customer group id
+         */
+        $customer->getGroupId();
+
+        return $customer;
+    }
 
-            if ($this->getRequest()->getParam('is_subscribed', false)) {
-                $customer->setIsSubscribed(1);
+    /**
+     * Add session error method
+     *
+     * @param string|array $errors
+     */
+    protected function _addSessionError($errors)
+    {
+        $session = $this->_getSession();
+        $session->setCustomerFormData($this->getRequest()->getPost());
+        if (is_array($errors)) {
+            foreach ($errors as $errorMessage) {
+                $session->addError(Mage::helper('core')->escapeHtml($errorMessage));
             }
+        } else {
+            $session->addError($this->__('Invalid customer data'));
+        }
+    }
 
-            /**
-             * Initialize customer group id
-             */
-            $customer->getGroupId();
-
-            if ($this->getRequest()->getPost('create_address')) {
-                /* @var $address Mage_Customer_Model_Address */
-                $address = Mage::getModel('customer/address');
-                /* @var $addressForm Mage_Customer_Model_Form */
-                $addressForm = Mage::getModel('customer/form');
-                $addressForm->setFormCode('customer_register_address')
-                    ->setEntity($address);
-
-                $addressData    = $addressForm->extractData($this->getRequest(), 'address', false);
-                $addressErrors  = $addressForm->validateData($addressData);
-                if ($addressErrors === true) {
-                    $address->setId(null)
-                        ->setIsDefaultBilling($this->getRequest()->getParam('default_billing', false))
-                        ->setIsDefaultShipping($this->getRequest()->getParam('default_shipping', false));
-                    $addressForm->compactData($addressData);
-                    $customer->addAddress($address);
-
-                    $addressErrors = $address->validate();
-                    if (is_array($addressErrors)) {
-                        $errors = array_merge($errors, $addressErrors);
-                    }
-                } else {
-                    $errors = array_merge($errors, $addressErrors);
-                }
+    /**
+     * Validate customer data and return errors if they are
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @return array|string
+     */
+    protected function _getCustomerErrors($customer)
+    {
+        $errors = array();
+        $request = $this->getRequest();
+        if ($request->getPost('create_address')) {
+            $errors = $this->_getErrorsOnCustomerAddress($customer);
+        }
+        $customerForm = $this->_getCustomerForm($customer);
+        $customerData = $customerForm->extractData($request);
+        $customerErrors = $customerForm->validateData($customerData);
+        if ($customerErrors !== true) {
+            $errors = array_merge($customerErrors, $errors);
+        } else {
+            $customerForm->compactData($customerData);
+            $customer->setPassword($request->getPost('password'));
+            $customer->setConfirmation($request->getPost('confirmation'));
+            $customerErrors = $customer->validate();
+            if (is_array($customerErrors)) {
+                $errors = array_merge($customerErrors, $errors);
             }
+        }
+        return $errors;
+    }
 
-            try {
-                $customerErrors = $customerForm->validateData($customerData);
-                if ($customerErrors !== true) {
-                    $errors = array_merge($customerErrors, $errors);
-                } else {
-                    $customerForm->compactData($customerData);
-                    $customer->setPassword($this->getRequest()->getPost('password'));
-                    $customer->setConfirmation($this->getRequest()->getPost('confirmation'));
-                    $customerErrors = $customer->validate();
-                    if (is_array($customerErrors)) {
-                        $errors = array_merge($customerErrors, $errors);
-                    }
-                }
+    /**
+     * Get Customer Form Initalized Model
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @return Mage_Customer_Model_Form
+     */
+    protected function _getCustomerForm($customer)
+    {
+        /* @var $customerForm Mage_Customer_Model_Form */
+        $customerForm = $this->_getModel('customer/form');
+        $customerForm->setFormCode('customer_account_create');
+        $customerForm->setEntity($customer);
+        return $customerForm;
+    }
 
-                $validationResult = count($errors) == 0;
+    /**
+     * Get Helper
+     *
+     * @param string $path
+     * @return Mage_Core_Helper_Abstract
+     */
+    protected function _getHelper($path)
+    {
+        return Mage::helper($path);
+    }
 
-                if (true === $validationResult) {
-                    $customer->save();
+    /**
+     * Get App
+     *
+     * @return Mage_Core_Model_App
+     */
+    protected function _getApp()
+    {
+        return Mage::app();
+    }
 
-                    Mage::dispatchEvent('customer_register_success',
-                        array('account_controller' => $this, 'customer' => $customer)
-                    );
-
-                    if ($customer->isConfirmationRequired()) {
-                        $customer->sendNewAccountEmail(
-                            'confirmation',
-                            $session->getBeforeAuthUrl(),
-                            Mage::app()->getStore()->getId()
-                        );
-                        $session->addSuccess($this->__('Account confirmation is required. Please, check your email for the confirmation link. To resend the confirmation email please <a href="%s">click here</a>.', Mage::helper('customer')->getEmailConfirmationUrl($customer->getEmail())));
-                        $this->_redirectSuccess(Mage::getUrl('*/*/index', array('_secure'=>true)));
-                        return;
-                    } else {
-                        $session->setCustomerAsLoggedIn($customer);
-                        $url = $this->_welcomeCustomer($customer);
-                        $this->_redirectSuccess($url);
-                        return;
-                    }
-                } else {
-                    $session->setCustomerFormData($this->getRequest()->getPost());
-                    if (is_array($errors)) {
-                        foreach ($errors as $errorMessage) {
-                            $session->addError(Mage::helper('core')->escapeHtml($errorMessage));
-                        }
-                    } else {
-                        $session->addError($this->__('Invalid customer data'));
-                    }
-                }
-            } catch (Mage_Core_Exception $e) {
-                $session->setCustomerFormData($this->getRequest()->getPost());
-                if ($e->getCode() === Mage_Customer_Model_Customer::EXCEPTION_EMAIL_EXISTS) {
-                    $url = Mage::getUrl('customer/account/forgotpassword');
-                    $message = $this->__('There is already an account with this email address. If you are sure that it is your email address, <a href="%s">click here</a> to get your password and access your account.', $url);
-                } else {
-                    $message = Mage::helper('core')->escapeHtml($e->getMessage());
-                }
-                $session->addError($message);
-            } catch (Exception $e) {
-                $session->setCustomerFormData($this->getRequest()->getPost())
-                    ->addException($e, $this->__('Cannot save the customer.'));
-            }
+    /**
+     * Dispatch Event
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     */
+    protected function _dispatchRegisterSuccess($customer)
+    {
+        Mage::dispatchEvent('customer_register_success',
+            array('account_controller' => $this, 'customer' => $customer)
+        );
+    }
+
+    /**
+     * Get errors on provided customer address
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @return array $errors
+     */
+    protected function _getErrorsOnCustomerAddress($customer)
+    {
+        $errors = array();
+        /* @var $address Mage_Customer_Model_Address */
+        $address = $this->_getModel('customer/address');
+        /* @var $addressForm Mage_Customer_Model_Form */
+        $addressForm = $this->_getModel('customer/form');
+        $addressForm->setFormCode('customer_register_address')
+            ->setEntity($address);
+
+        $addressData = $addressForm->extractData($this->getRequest(), 'address', false);
+        $addressErrors = $addressForm->validateData($addressData);
+        if (is_array($addressErrors)) {
+            $errors = $addressErrors;
         }
+        $address->setId(null)
+            ->setIsDefaultBilling($this->getRequest()->getParam('default_billing', false))
+            ->setIsDefaultShipping($this->getRequest()->getParam('default_shipping', false));
+        $addressForm->compactData($addressData);
+        $customer->addAddress($address);
+
+        $addressErrors = $address->validate();
+        if (is_array($addressErrors)) {
+            $errors = array_merge($errors, $addressErrors);
+        }
+        return $errors;
+    }
 
-        $this->_redirectError(Mage::getUrl('*/*/create', array('_secure' => true)));
+    /**
+     * Get model by path
+     *
+     * @param string $path
+     * @param array|null $arguments
+     * @return false|Mage_Core_Model_Abstract
+     */
+    public function _getModel($path, $arguments = array())
+    {
+        return Mage::getModel($path, $arguments);
+    }
+
+    /**
+     * Get model from registry by path
+     *
+     * @param string $path
+     * @return mixed
+     */
+    protected function _getFromRegistry($path)
+    {
+        return Mage::registry($path);
     }
 
     /**
@@ -403,14 +537,16 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
         );
         if ($this->_isVatValidationEnabled()) {
             // Show corresponding VAT message to customer
-            $configAddressType = Mage::helper('customer/address')->getTaxCalculationAddressType();
+            $configAddressType = $this->_getHelper('customer/address')->getTaxCalculationAddressType();
             $userPrompt = '';
             switch ($configAddressType) {
                 case Mage_Customer_Model_Address_Abstract::TYPE_SHIPPING:
-                    $userPrompt = $this->__('If you are a registered VAT customer, please click <a href="%s">here</a> to enter you shipping address for proper VAT calculation', Mage::getUrl('customer/address/edit'));
+                    $userPrompt = $this->__('If you are a registered VAT customer, please click <a href="%s">here</a> to enter you shipping address for proper VAT calculation',
+                        $this->_getUrl('customer/address/edit'));
                     break;
                 default:
-                    $userPrompt = $this->__('If you are a registered VAT customer, please click <a href="%s">here</a> to enter you billing address for proper VAT calculation', Mage::getUrl('customer/address/edit'));
+                    $userPrompt = $this->__('If you are a registered VAT customer, please click <a href="%s">here</a> to enter you billing address for proper VAT calculation',
+                        $this->_getUrl('customer/address/edit'));
             }
             $this->_getSession()->addSuccess($userPrompt);
         }
@@ -421,7 +557,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             Mage::app()->getStore()->getId()
         );
 
-        $successUrl = Mage::getUrl('*/*/index', array('_secure'=>true));
+        $successUrl = $this->_getUrl('*/*/index', array('_secure' => true));
         if ($this->_getSession()->getBeforeAuthUrl()) {
             $successUrl = $this->_getSession()->getBeforeAuthUrl(true);
         }
@@ -433,7 +569,8 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     public function confirmAction()
     {
-        if ($this->_getSession()->isLoggedIn()) {
+        $session = $this->_getSession();
+        if ($session->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
         }
@@ -447,7 +584,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 
             // load customer by id (try/catch in case if it throws exceptions)
             try {
-                $customer = Mage::getModel('customer/customer')->load($id);
+                $customer = $this->_getModel('customer/customer')->load($id);
                 if ((!$customer) || (!$customer->getId())) {
                     throw new Exception('Failed to load customer by id.');
                 }
@@ -471,21 +608,22 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     throw new Exception($this->__('Failed to confirm customer account.'));
                 }
 
+                $session->renewSession();
                 // log in and send greeting email, then die happy
-                $this->_getSession()->setCustomerAsLoggedIn($customer);
+                $session->setCustomerAsLoggedIn($customer);
                 $successUrl = $this->_welcomeCustomer($customer, true);
                 $this->_redirectSuccess($backUrl ? $backUrl : $successUrl);
                 return;
             }
 
             // die happy
-            $this->_redirectSuccess(Mage::getUrl('*/*/index', array('_secure'=>true)));
+            $this->_redirectSuccess($this->_getUrl('*/*/index', array('_secure' => true)));
             return;
         }
         catch (Exception $e) {
             // die unhappy
             $this->_getSession()->addError($e->getMessage());
-            $this->_redirectError(Mage::getUrl('*/*/index', array('_secure'=>true)));
+            $this->_redirectError($this->_getUrl('*/*/index', array('_secure' => true)));
             return;
         }
     }
@@ -495,7 +633,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     public function confirmationAction()
     {
-        $customer = Mage::getModel('customer/customer');
+        $customer = $this->_getModel('customer/customer');
         if ($this->_getSession()->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
@@ -516,10 +654,10 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $this->_getSession()->addSuccess($this->__('This email does not require confirmation.'));
                 }
                 $this->_getSession()->setUsername($email);
-                $this->_redirectSuccess(Mage::getUrl('*/*/index', array('_secure' => true)));
+                $this->_redirectSuccess($this->_getUrl('*/*/index', array('_secure' => true)));
             } catch (Exception $e) {
                 $this->_getSession()->addException($e, $this->__('Wrong email.'));
-                $this->_redirectError(Mage::getUrl('*/*/*', array('email' => $email, '_secure' => true)));
+                $this->_redirectError($this->_getUrl('*/*/*', array('email' => $email, '_secure' => true)));
             }
             return;
         }
@@ -535,6 +673,18 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
     }
 
     /**
+     * Get Url method
+     *
+     * @param string $url
+     * @param array $params
+     * @return string
+     */
+    protected function _getUrl($url, $params = array())
+    {
+        return Mage::getUrl($url, $params);
+    }
+
+    /**
      * Forgot customer password page
      */
     public function forgotPasswordAction()
@@ -565,13 +715,13 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             }
 
             /** @var $customer Mage_Customer_Model_Customer */
-            $customer = Mage::getModel('customer/customer')
+            $customer = $this->_getModel('customer/customer')
                 ->setWebsiteId(Mage::app()->getStore()->getWebsiteId())
                 ->loadByEmail($email);
 
             if ($customer->getId()) {
                 try {
-                    $newResetPasswordLinkToken = Mage::helper('customer')->generateResetPasswordLinkToken();
+                    $newResetPasswordLinkToken = $this->_getHelper('customer')->generateResetPasswordLinkToken();
                     $customer->changeResetPasswordLinkToken($newResetPasswordLinkToken);
                     $customer->sendPasswordResetConfirmationEmail();
                 } catch (Exception $exception) {
@@ -581,7 +731,9 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 }
             }
             $this->_getSession()
-                ->addSuccess(Mage::helper('customer')->__('If there is an account associated with %s you will receive an email with a link to reset your password.', Mage::helper('customer')->htmlEscape($email)));
+                ->addSuccess($this->_getHelper('customer')
+                    ->__('If there is an account associated with %s you will receive an email with a link to reset your password.',
+                        $this->_getHelper('customer')->escapeHtml($email)));
             $this->_redirect('*/*/');
             return;
         } else {
@@ -626,16 +778,14 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 ->_redirect('*/*/changeforgotten');
 
         } catch (Exception $exception) {
-            $this->_getSession()->addError(Mage::helper('customer')->__('Your password reset link has expired.'));
+            $this->_getSession()->addError($this->_getHelper('customer')->__('Your password reset link has expired.'));
             $this->_redirect('*/*/forgotpassword');
         }
     }
 
     /**
      * Reset forgotten password
-     *
      * Used to handle data recieved from reset forgotten password form
-     *
      */
     public function resetPasswordPostAction()
     {
@@ -646,17 +796,17 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
         try {
             $this->_validateResetPasswordLinkToken($customerId, $resetPasswordLinkToken);
         } catch (Exception $exception) {
-            $this->_getSession()->addError(Mage::helper('customer')->__('Your password reset link has expired.'));
+            $this->_getSession()->addError($this->_getHelper('customer')->__('Your password reset link has expired.'));
             $this->_redirect('*/*/');
             return;
         }
 
         $errorMessages = array();
         if (iconv_strlen($password) <= 0) {
-            array_push($errorMessages, Mage::helper('customer')->__('New password field cannot be empty.'));
+            array_push($errorMessages, $this->_getHelper('customer')->__('New password field cannot be empty.'));
         }
         /** @var $customer Mage_Customer_Model_Customer */
-        $customer = Mage::getModel('customer/customer')->load($customerId);
+        $customer = $this->_getModel('customer/customer')->load($customerId);
 
         $customer->setPassword($password);
         $customer->setConfirmation($passwordConfirmation);
@@ -684,7 +834,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $this->_getSession()->unsetData(self::TOKEN_SESSION_NAME);
             $this->_getSession()->unsetData(self::CUSTOMER_ID_SESSION_NAME);
 
-            $this->_getSession()->addSuccess(Mage::helper('customer')->__('Your password has been updated.'));
+            $this->_getSession()->addSuccess($this->_getHelper('customer')->__('Your password has been updated.'));
             $this->_redirect('*/*/login');
         } catch (Exception $exception) {
             $this->_getSession()->addException($exception, $this->__('Cannot save a new password.'));
@@ -708,18 +858,18 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             || empty($customerId)
             || $customerId < 0
         ) {
-            throw Mage::exception('Mage_Core', Mage::helper('customer')->__('Invalid password reset token.'));
+            throw Mage::exception('Mage_Core', $this->_getHelper('customer')->__('Invalid password reset token.'));
         }
 
         /** @var $customer Mage_Customer_Model_Customer */
-        $customer = Mage::getModel('customer/customer')->load($customerId);
+        $customer = $this->_getModel('customer/customer')->load($customerId);
         if (!$customer || !$customer->getId()) {
-            throw Mage::exception('Mage_Core', Mage::helper('customer')->__('Wrong customer account specified.'));
+            throw Mage::exception('Mage_Core', $this->_getHelper('customer')->__('Wrong customer account specified.'));
         }
 
         $customerToken = $customer->getRpToken();
         if (strcmp($customerToken, $resetPasswordLinkToken) != 0 || $customer->isResetPasswordLinkTokenExpired()) {
-            throw Mage::exception('Mage_Core', Mage::helper('customer')->__('Your password reset link has expired.'));
+            throw Mage::exception('Mage_Core', $this->_getHelper('customer')->__('Your password reset link has expired.'));
         }
     }
 
@@ -741,7 +891,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
         if (!empty($data)) {
             $customer->addData($data);
         }
-        if ($this->getRequest()->getParam('changepass')==1){
+        if ($this->getRequest()->getParam('changepass') == 1) {
             $customer->setChangePassword(1);
         }
 
@@ -764,7 +914,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $customer = $this->_getSession()->getCustomer();
 
             /** @var $customerForm Mage_Customer_Model_Form */
-            $customerForm = Mage::getModel('customer/form');
+            $customerForm = $this->_getModel('customer/form');
             $customerForm->setFormCode('customer_account_edit')
                 ->setEntity($customer);
 
@@ -785,7 +935,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $confPass   = $this->getRequest()->getPost('confirmation');
 
                     $oldPass = $this->_getSession()->getCustomer()->getPasswordHash();
-                    if (Mage::helper('core/string')->strpos($oldPass, ':')) {
+                    if ($this->_getHelper('core/string')->strpos($oldPass, ':')) {
                         list($_salt, $salt) = explode(':', $oldPass);
                     } else {
                         $salt = false;
@@ -863,7 +1013,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     protected function _isVatValidationEnabled($store = null)
     {
-        return Mage::helper('customer/address')->isVatValidationEnabled($store);
+        return $this->_getHelper('customer/address')->isVatValidationEnabled($store);
     }
 
     /**
diff --git app/code/core/Mage/Customer/controllers/AddressController.php app/code/core/Mage/Customer/controllers/AddressController.php
index 24ddc57..394b7cc 100644
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
index 48edf85..d885bd9 100644
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
index 4f01025..f2e7698 100644
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
@@ -245,6 +245,7 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
      */
      protected function _prepareLayout()
     {
+        parent::_prepareLayout();
         $this->setChild(
             'upload_button',
             $this->getLayout()->createBlock('adminhtml/widget_button')->addData(array(
@@ -254,6 +255,10 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
                 'onclick' => 'Downloadable.massUploadByType(\'links\');Downloadable.massUploadByType(\'linkssample\')'
             ))
         );
+        $this->_addElementIdsMapping(array(
+            'container' => $this->getHtmlId() . '-new',
+            'delete'    => $this->getHtmlId() . '-delete'
+        ));
     }
 
     /**
@@ -273,33 +278,56 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
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
index 43937f2..c21af62 100644
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
index eb7a190..2d2ce84 100644
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
index 0f233fc..91472b9 100644
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
@@ -541,7 +541,7 @@ class Mage_Oauth_Model_Server
             $this->_request->getScheme() . '://' . $this->_request->getHttpHost() . $this->_request->getRequestUri()
         );
 
-        if ($calculatedSign != $this->_protocolParams['oauth_signature']) {
+        if (!hash_equals($calculatedSign, $this->_protocolParams['oauth_signature'])) {
             $this->_throwException($calculatedSign, self::ERR_SIGNATURE_INVALID);
         }
     }
diff --git app/code/core/Mage/Paygate/Model/Authorizenet.php app/code/core/Mage/Paygate/Model/Authorizenet.php
index 37c2441..86e99d4 100644
--- app/code/core/Mage/Paygate/Model/Authorizenet.php
+++ app/code/core/Mage/Paygate/Model/Authorizenet.php
@@ -1261,8 +1261,10 @@ class Mage_Paygate_Model_Authorizenet extends Mage_Payment_Model_Method_Cc
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
@@ -1529,8 +1531,13 @@ class Mage_Paygate_Model_Authorizenet extends Mage_Payment_Model_Method_Cc
 
         $client = new Varien_Http_Client();
         $uri = $this->getConfigData('cgi_url_td');
-        $client->setUri($uri ? $uri : self::CGI_URL_TD);
-        $client->setConfig(array('timeout'=>45));
+        $uri = $uri ? $uri : self::CGI_URL_TD;
+        $client->setUri($uri);
+        $client->setConfig(array(
+            'timeout' => 45,
+            'verifyhost' => 2,
+            'verifypeer' => true,
+        ));
         $client->setHeaders(array('Content-Type: text/xml'));
         $client->setMethod(Zend_Http_Client::POST);
         $client->setRawData($requestBody);
diff --git app/code/core/Mage/Payment/Block/Info/Checkmo.php app/code/core/Mage/Payment/Block/Info/Checkmo.php
index 268605a..5306b52 100644
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
diff --git app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
index 0a76f3c..7e02e92 100644
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
diff --git app/code/core/Mage/Review/controllers/ProductController.php app/code/core/Mage/Review/controllers/ProductController.php
index 29483e6..6590c79 100644
--- app/code/core/Mage/Review/controllers/ProductController.php
+++ app/code/core/Mage/Review/controllers/ProductController.php
@@ -155,6 +155,12 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
      */
     public function postAction()
     {
+        if (!$this->_validateFormKey()) {
+            // returns to the product item page
+            $this->_redirectReferer();
+            return;
+        }
+
         if ($data = Mage::getSingleton('review/session')->getFormData(true)) {
             $rating = array();
             if (isset($data['ratings']) && is_array($data['ratings'])) {
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Payment.php app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
index 3e3572c..2a31cae 100755
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
index 67f0cee..4ea1f37 100755
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
index 5fd2bea..a2a8548 100755
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
index cd7d1b3..325c911 100755
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
index 0000000..0cba674
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Abstract.php
@@ -0,0 +1,247 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..923f045
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Multiple.php
@@ -0,0 +1,71 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..4ce4663
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Single.php
@@ -0,0 +1,52 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..c260604
--- /dev/null
+++ app/code/core/Mage/Uploader/Helper/Data.php
@@ -0,0 +1,30 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+class Mage_Uploader_Helper_Data extends Mage_Core_Helper_Abstract
+{
+
+}
diff --git app/code/core/Mage/Uploader/Helper/File.php app/code/core/Mage/Uploader/Helper/File.php
new file mode 100644
index 0000000..9685a03
--- /dev/null
+++ app/code/core/Mage/Uploader/Helper/File.php
@@ -0,0 +1,750 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..da2ea63
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Abstract.php
@@ -0,0 +1,69 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..eaa5d64
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Browsebutton.php
@@ -0,0 +1,63 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..3c70ad3
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Misc.php
@@ -0,0 +1,46 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..0fc6f0c
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Uploader.php
@@ -0,0 +1,122 @@
+<?php
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..78584d5
--- /dev/null
+++ app/code/core/Mage/Uploader/etc/config.xml
@@ -0,0 +1,51 @@
+<?xml version="1.0"?>
+<!--
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 0000000..8b1fe0a
--- /dev/null
+++ app/code/core/Mage/Uploader/etc/jstranslator.xml
@@ -0,0 +1,44 @@
+<?xml version="1.0"?>
+<!--
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
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 1612648..541e7f6 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
@@ -566,8 +566,8 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl
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
@@ -1070,8 +1070,8 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl
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
index 26e7771..caa6d6f 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
@@ -841,7 +841,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
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
@@ -1362,7 +1367,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
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
@@ -1554,7 +1564,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
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
index 39e5af8..2f34f3f 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
@@ -563,6 +563,7 @@ class Mage_Usa_Model_Shipping_Carrier_Fedex
     /**
      * Get xml quotes
      *
+     * @deprecated
      * @return Mage_Shipping_Model_Rate_Result
      */
     protected function _getXmlQuotes()
@@ -622,8 +623,8 @@ class Mage_Usa_Model_Shipping_Carrier_Fedex
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
index c324af8..c203e06 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
@@ -932,7 +932,7 @@ XMLRequest;
                 curl_setopt($ch, CURLOPT_POST, 1);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $xmlRequest);
                 curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
                 $xmlResponse = curl_exec ($ch);
 
                 $debugData['result'] = $xmlResponse;
@@ -1567,7 +1567,7 @@ XMLAuth;
             curl_setopt($ch, CURLOPT_POST, 1);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $this->_xmlAccessRequest . $xmlRequest->asXML());
             curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
             $xmlResponse = curl_exec ($ch);
 
             $debugData['result'] = $xmlResponse;
@@ -1625,7 +1625,7 @@ XMLAuth;
             curl_setopt($ch, CURLOPT_POST, 1);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $xmlRequest);
             curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
             $xmlResponse = curl_exec($ch);
             if ($xmlResponse === false) {
                 throw new Exception(curl_error($ch));
diff --git app/code/core/Mage/Usa/etc/config.xml app/code/core/Mage/Usa/etc/config.xml
index 5eaa96c..ef4f566 100644
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
@@ -181,6 +182,7 @@
                 <negotiated_active>0</negotiated_active>
                 <mode_xml>1</mode_xml>
                 <type>UPS</type>
+                <verify_peer>0</verify_peer>
             </ups>
             <usps>
                 <active>0</active>
@@ -216,6 +218,7 @@
                 <doc_methods>2,5,6,7,9,B,C,D,U,K,L,G,W,I,N,O,R,S,T,X</doc_methods>
                 <free_method>G</free_method>
                 <gateway_url>https://xmlpi-ea.dhl.com/XMLShippingServlet</gateway_url>
+                <verify_peer>0</verify_peer>
                 <id backend_model="adminhtml/system_config_backend_encrypted"/>
                 <password backend_model="adminhtml/system_config_backend_encrypted"/>
                 <shipment_type>N</shipment_type>
diff --git app/code/core/Mage/Usa/etc/system.xml app/code/core/Mage/Usa/etc/system.xml
index 8c642a1..3342f7f 100644
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
@@ -735,6 +744,15 @@
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
@@ -1239,6 +1257,15 @@
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
diff --git app/code/core/Mage/Wishlist/Controller/Abstract.php app/code/core/Mage/Wishlist/Controller/Abstract.php
index 7d193a2..f2124b9 100644
--- app/code/core/Mage/Wishlist/Controller/Abstract.php
+++ app/code/core/Mage/Wishlist/Controller/Abstract.php
@@ -73,10 +73,15 @@ abstract class Mage_Wishlist_Controller_Abstract extends Mage_Core_Controller_Fr
      */
     public function allcartAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_forward('noRoute');
+            return;
+        }
+
         $wishlist   = $this->_getWishlist();
         if (!$wishlist) {
             $this->_forward('noRoute');
-            return ;
+            return;
         }
         $isOwner    = $wishlist->isOwner(Mage::getSingleton('customer/session')->getCustomerId());
 
@@ -89,7 +94,9 @@ abstract class Mage_Wishlist_Controller_Abstract extends Mage_Core_Controller_Fr
         $collection = $wishlist->getItemCollection()
                 ->setVisibilityFilter();
 
-        $qtys = $this->getRequest()->getParam('qty');
+        $qtysString = $this->getRequest()->getParam('qty');
+        $qtys =  array_filter(json_decode($qtysString), 'strlen');
+
         foreach ($collection as $item) {
             /** @var Mage_Wishlist_Model_Item */
             try {
diff --git app/code/core/Mage/Wishlist/Helper/Data.php app/code/core/Mage/Wishlist/Helper/Data.php
index d79ac4c..288d570 100644
--- app/code/core/Mage/Wishlist/Helper/Data.php
+++ app/code/core/Mage/Wishlist/Helper/Data.php
@@ -135,11 +135,9 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
         if (is_null($this->_wishlist)) {
             if (Mage::registry('shared_wishlist')) {
                 $this->_wishlist = Mage::registry('shared_wishlist');
-            }
-            elseif (Mage::registry('wishlist')) {
+            } else if (Mage::registry('wishlist')) {
                 $this->_wishlist = Mage::registry('wishlist');
-            }
-            else {
+            } else {
                 $this->_wishlist = Mage::getModel('wishlist/wishlist');
                 if ($this->getCustomer()) {
                     $this->_wishlist->loadByCustomer($this->getCustomer());
@@ -260,8 +258,7 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
         if ($product) {
             if ($product->isVisibleInSiteVisibility()) {
                 $storeId = $product->getStoreId();
-            }
-            else if ($product->hasUrlDataObject()) {
+            } else if ($product->hasUrlDataObject()) {
                 $storeId = $product->getUrlDataObject()->getStoreId();
             }
         }
@@ -277,7 +274,10 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
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
 
@@ -360,40 +360,62 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
             $productId = $item->getProductId();
         }
 
-        if ($productId) {
-            $params['product'] = $productId;
-            return $this->_getUrlStore($item)->getUrl('wishlist/index/add', $params);
+        if (!$productId) {
+            return false;
         }
-
-        return false;
+        $params['product'] = $productId;
+        $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+        return $this->_getUrlStore($item)->getUrl('wishlist/index/add', $params);
     }
 
     /**
-     * Retrieve URL for adding item to shoping cart
+     * Retrieve URL for adding item to shopping cart
      *
      * @param string|Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
      * @return  string
      */
     public function getAddToCartUrl($item)
     {
-        $urlParamName = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
-        $continueUrl  = Mage::helper('core')->urlEncode(
-            Mage::getUrl('*/*/*', array(
+        $continueUrl  = $this->_getHelperInstance('core')->urlEncode(
+            $this->_getUrl('*/*/*', array(
                 '_current'      => true,
                 '_use_rewrite'  => true,
                 '_store_to_url' => true,
             ))
         );
-
-        $urlParamName = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
         $params = array(
             'item' => is_string($item) ? $item : $item->getWishlistItemId(),
-            $urlParamName => $continueUrl
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl,
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
+
         return $this->_getUrlStore($item)->getUrl('wishlist/index/cart', $params);
     }
 
     /**
+     * Return helper instance
+     *
+     * @param string $helperName
+     * @return Mage_Core_Helper_Abstract
+     */
+    protected function _getHelperInstance($helperName)
+    {
+        return Mage::helper($helperName);
+    }
+
+    /**
+     * Return model instance
+     *
+     * @param string $className
+     * @param array $arguments
+     * @return Mage_Core_Model_Abstract
+     */
+    protected function _getSingletonModel($className, $arguments = array())
+    {
+        return Mage::getSingleton($className, $arguments);
+    }
+
+    /**
      * Retrieve URL for adding item to shoping cart from shared wishlist
      *
      * @param string|Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
@@ -407,10 +429,10 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
             '_store_to_url' => true,
         )));
 
-        $urlParamName = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
         $params = array(
             'item' => is_string($item) ? $item : $item->getWishlistItemId(),
-            $urlParamName => $continueUrl
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl,
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
         return $this->_getUrlStore($item)->getUrl('wishlist/shared/cart', $params);
     }
diff --git app/code/core/Mage/Wishlist/controllers/IndexController.php app/code/core/Mage/Wishlist/controllers/IndexController.php
index 4018eb0..beaf174 100644
--- app/code/core/Mage/Wishlist/controllers/IndexController.php
+++ app/code/core/Mage/Wishlist/controllers/IndexController.php
@@ -48,6 +48,11 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
      */
     protected $_skipAuthentication = false;
 
+    /**
+     * Extend preDispatch
+     *
+     * @return Mage_Core_Controller_Front_Action|void
+     */
     public function preDispatch()
     {
         parent::preDispatch();
@@ -152,9 +157,24 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
 
     /**
      * Adding new item
+     *
+     * @return Mage_Core_Controller_Varien_Action|void
      */
     public function addAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
+        $this->_addItemToWishList();
+    }
+
+    /**
+     * Add the item to wish list
+     *
+     * @return Mage_Core_Controller_Varien_Action|void
+     */
+    protected function _addItemToWishList()
+    {
         $wishlist = $this->_getWishlist();
         if (!$wishlist) {
             return $this->norouteAction();
@@ -162,7 +182,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
 
         $session = Mage::getSingleton('customer/session');
 
-        $productId = (int) $this->getRequest()->getParam('product');
+        $productId = (int)$this->getRequest()->getParam('product');
         if (!$productId) {
             $this->_redirect('*/');
             return;
@@ -192,9 +212,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
             Mage::dispatchEvent(
                 'wishlist_add_product',
                 array(
-                    'wishlist'  => $wishlist,
-                    'product'   => $product,
-                    'item'      => $result
+                    'wishlist' => $wishlist,
+                    'product' => $product,
+                    'item' => $result
                 )
             );
 
@@ -212,10 +232,10 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
 
             Mage::helper('wishlist')->calculate();
 
-            $message = $this->__('%1$s has been added to your wishlist. Click <a href="%2$s">here</a> to continue shopping.', $product->getName(), Mage::helper('core')->escapeUrl($referer));
+            $message = $this->__('%1$s has been added to your wishlist. Click <a href="%2$s">here</a> to continue shopping.',
+                $product->getName(), Mage::helper('core')->escapeUrl($referer));
             $session->addSuccess($message);
-        }
-        catch (Mage_Core_Exception $e) {
+        } catch (Mage_Core_Exception $e) {
             $session->addError($this->__('An error occurred while adding item to wishlist: %s', $e->getMessage()));
         }
         catch (Exception $e) {
@@ -337,7 +357,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
         }
 
         $post = $this->getRequest()->getPost();
-        if($post && isset($post['description']) && is_array($post['description'])) {
+        if ($post && isset($post['description']) && is_array($post['description'])) {
             $updatedItems = 0;
 
             foreach ($post['description'] as $itemId => $description) {
@@ -393,8 +413,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
                 try {
                     $wishlist->save();
                     Mage::helper('wishlist')->calculate();
-                }
-                catch (Exception $e) {
+                } catch (Exception $e) {
                     Mage::getSingleton('customer/session')->addError($this->__('Can\'t update wishlist'));
                 }
             }
@@ -412,6 +431,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
      */
     public function removeAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $id = (int) $this->getRequest()->getParam('item');
         $item = Mage::getModel('wishlist/item')->load($id);
         if (!$item->getId()) {
@@ -428,7 +450,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
             Mage::getSingleton('customer/session')->addError(
                 $this->__('An error occurred while deleting the item from wishlist: %s', $e->getMessage())
             );
-        } catch(Exception $e) {
+        } catch (Exception $e) {
             Mage::getSingleton('customer/session')->addError(
                 $this->__('An error occurred while deleting the item from wishlist.')
             );
@@ -447,6 +469,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
      */
     public function cartAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $itemId = (int) $this->getRequest()->getParam('item');
 
         /* @var $item Mage_Wishlist_Model_Item */
@@ -536,7 +561,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
         $cart = Mage::getSingleton('checkout/cart');
         $session = Mage::getSingleton('checkout/session');
 
-        try{
+        try {
             $item = $cart->getQuote()->getItemById($itemId);
             if (!$item) {
                 Mage::throwException(
@@ -632,7 +657,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
                     ->createBlock('wishlist/share_email_rss')
                     ->setWishlistId($wishlist->getId())
                     ->toHtml();
-                $message .=$rss_url;
+                $message .= $rss_url;
             }
             $wishlistBlock = $this->getLayout()->createBlock('wishlist/share_email_items')->toHtml();
 
@@ -641,19 +666,19 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
             $emailModel = Mage::getModel('core/email_template');
 
             $sharingCode = $wishlist->getSharingCode();
-            foreach($emails as $email) {
+            foreach ($emails as $email) {
                 $emailModel->sendTransactional(
                     Mage::getStoreConfig('wishlist/email/email_template'),
                     Mage::getStoreConfig('wishlist/email/email_identity'),
                     $email,
                     null,
                     array(
-                        'customer'      => $customer,
-                        'salable'       => $wishlist->isSalable() ? 'yes' : '',
-                        'items'         => $wishlistBlock,
-                        'addAllLink'    => Mage::getUrl('*/shared/allcart', array('code' => $sharingCode)),
-                        'viewOnSiteLink'=> Mage::getUrl('*/shared/index', array('code' => $sharingCode)),
-                        'message'       => $message
+                        'customer'       => $customer,
+                        'salable'        => $wishlist->isSalable() ? 'yes' : '',
+                        'items'          => $wishlistBlock,
+                        'addAllLink'     => Mage::getUrl('*/shared/allcart', array('code' => $sharingCode)),
+                        'viewOnSiteLink' => Mage::getUrl('*/shared/index', array('code' => $sharingCode)),
+                        'message'        => $message
                     )
                 );
             }
@@ -663,7 +688,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
 
             $translate->setTranslateInline(true);
 
-            Mage::dispatchEvent('wishlist_share', array('wishlist'=>$wishlist));
+            Mage::dispatchEvent('wishlist_share', array('wishlist' => $wishlist));
             Mage::getSingleton('customer/session')->addSuccess(
                 $this->__('Your Wishlist has been shared.')
             );
@@ -719,7 +744,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
                 ));
             }
 
-        } catch(Exception $e) {
+        } catch (Exception $e) {
             $this->_forward('noRoute');
         }
         exit(0);
diff --git app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
index 196ce8d..34179f4 100644
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
diff --git app/design/adminhtml/default/default/layout/cms.xml app/design/adminhtml/default/default/layout/cms.xml
index 501cd3d..555f0ef 100644
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
index 26e9ace..01f8bb1 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -170,9 +170,10 @@ Layout for editor element
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
index 05f0e0d..d859266 100644
--- app/design/adminhtml/default/default/layout/xmlconnect.xml
+++ app/design/adminhtml/default/default/layout/xmlconnect.xml
@@ -74,9 +74,10 @@
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
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index 170c422..8b67075 100644
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
 <input type="hidden" id="<?php echo $_block->getHtmlId() ?>_save_image" name="<?php echo $_block->getElement()->getName() ?>[values]" value="<?php echo $_block->htmlEscape($_block->getImagesValuesJson()) ?>" />
 <script type="text/javascript">
 //<![CDATA[
-var <?php echo $_block->getJsObjectName(); ?> = new Product.Gallery('<?php echo $_block->getHtmlId() ?>', <?php if ($_block->getElement()->getReadonly()):?>null<?php else:?><?php echo $_block->getUploader()->getJsObjectName() ?><?php endif;?>, <?php echo $_block->getImageTypesJson() ?>);
+var <?php echo $_block->getJsObjectName(); ?> = new Product.Gallery('<?php echo $_block->getHtmlId() ?>', <?php echo $_block->getImageTypesJson() ?>);
 //]]>
 </script>
diff --git app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
index 41dfcfe..e2b3800 100644
--- app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
+++ app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
@@ -24,48 +24,8 @@
  * @license     http://www.magentocommerce.com/license/enterprise-edition
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
-<?php echo $this->getJsObjectName() ?> = new Flex.Uploader('<?php echo $this->getHtmlId() ?>', '<?php echo $this->getSkinUrl('media/uploader.swf') ?>', <?php echo $this->getConfigJson() ?>);
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
index 17b32d3..b57ec35 100644
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
index cd4cd81..55fdfe4 100644
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
index e84f73f..750f824 100644
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
diff --git app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
index 9e99f72..ca22715 100644
--- app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
+++ app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
@@ -66,7 +66,7 @@
                 <td class="label"><label><?php  echo $this->helper('enterprise_invitation')->__('Email'); ?><?php if ($this->canEditMessage()): ?><span class="required">*</span><?php endif; ?></label></td>
                 <td>
                 <?php if ($this->canEditMessage()): ?>
-                    <input type="text" class="required-entry input-text validate-email" name="email" value="<?php echo $this->getInvitation()->getEmail() ?>" />
+                    <input type="text" class="required-entry input-text validate-email" name="email" value="<?php echo $this->escapeHtml($this->getInvitation()->getEmail()) ?>" />
                 <?php else: ?>
                     <strong><?php echo $this->htmlEscape($this->getInvitation()->getEmail()) ?></strong>
                 <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/media/uploader.phtml app/design/adminhtml/default/default/template/media/uploader.phtml
index 6f601e0..0617c16 100644
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
diff --git app/design/frontend/base/default/template/catalog/product/view.phtml app/design/frontend/base/default/template/catalog/product/view.phtml
index b0efa7c..4c018c3 100644
--- app/design/frontend/base/default/template/catalog/product/view.phtml
+++ app/design/frontend/base/default/template/catalog/product/view.phtml
@@ -40,6 +40,7 @@
 <div class="product-view">
     <div class="product-essential">
     <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
+        <?php echo $this->getBlockHtml('formkey') ?>
         <div class="no-display">
             <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
             <input type="hidden" name="related_product" id="related-products-field" value="" />
diff --git app/design/frontend/base/default/template/checkout/cart.phtml app/design/frontend/base/default/template/checkout/cart.phtml
index a622cbf..8ffcd7b 100644
--- app/design/frontend/base/default/template/checkout/cart.phtml
+++ app/design/frontend/base/default/template/checkout/cart.phtml
@@ -47,6 +47,7 @@
     <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
     <?php echo $this->getChildHtml('form_before') ?>
     <form action="<?php echo $this->getUrl('checkout/cart/updatePost') ?>" method="post">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <fieldset>
             <table id="shopping-cart-table" class="data-table cart-table">
                 <col width="1" />
diff --git app/design/frontend/base/default/template/checkout/onepage/review/info.phtml app/design/frontend/base/default/template/checkout/onepage/review/info.phtml
index da8ee98..5cc7170 100644
--- app/design/frontend/base/default/template/checkout/onepage/review/info.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/review/info.phtml
@@ -78,7 +78,7 @@
     </div>
     <script type="text/javascript">
     //<![CDATA[
-        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder') ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
+        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder', array('form_key' => Mage::getSingleton('core/session')->getFormKey())) ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
     //]]>
     </script>
 </div>
diff --git app/design/frontend/base/default/template/customer/form/login.phtml app/design/frontend/base/default/template/customer/form/login.phtml
index e7f2e64..2d5435d 100644
--- app/design/frontend/base/default/template/customer/form/login.phtml
+++ app/design/frontend/base/default/template/customer/form/login.phtml
@@ -39,6 +39,7 @@
     <?php /* Extensions placeholder */ ?>
     <?php echo $this->getChildHtml('customer.form.login.extra')?>
     <form action="<?php echo $this->getPostActionUrl() ?>" method="post" id="login-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="col2-set">
             <div class="col-1 new-users">
                 <div class="content">
diff --git app/design/frontend/base/default/template/persistent/customer/form/login.phtml app/design/frontend/base/default/template/persistent/customer/form/login.phtml
index 7a21f7b..71d4321 100644
--- app/design/frontend/base/default/template/persistent/customer/form/login.phtml
+++ app/design/frontend/base/default/template/persistent/customer/form/login.phtml
@@ -38,6 +38,7 @@
     </div>
     <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
     <form action="<?php echo $this->getPostActionUrl() ?>" method="post" id="login-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="col2-set">
             <div class="col-1 new-users">
                 <div class="content">
diff --git app/design/frontend/base/default/template/review/form.phtml app/design/frontend/base/default/template/review/form.phtml
index aaab6e5..34378ee 100644
--- app/design/frontend/base/default/template/review/form.phtml
+++ app/design/frontend/base/default/template/review/form.phtml
@@ -28,6 +28,7 @@
     <h2><?php echo $this->__('Write Your Own Review') ?></h2>
     <?php if ($this->getAllowWriteReviewFlag()): ?>
     <form action="<?php echo $this->getAction() ?>" method="post" id="review-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <fieldset>
             <?php echo $this->getChildHtml('form_fields_before')?>
             <h3><?php echo $this->__("You're reviewing:"); ?> <span><?php echo $this->htmlEscape($this->getProductInfo()->getName()) ?></span></h3>
diff --git app/design/frontend/base/default/template/sales/reorder/sidebar.phtml app/design/frontend/base/default/template/sales/reorder/sidebar.phtml
index b1167fc..f762336 100644
--- app/design/frontend/base/default/template/sales/reorder/sidebar.phtml
+++ app/design/frontend/base/default/template/sales/reorder/sidebar.phtml
@@ -38,6 +38,7 @@
         <strong><span><?php echo $this->__('My Orders') ?></span></strong>
     </div>
     <form method="post" action="<?php echo $this->getFormActionUrl() ?>" id="reorder-validate-detail">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="block-content">
             <p class="block-subtitle"><?php echo $this->__('Last Ordered Items') ?></p>
             <ol id="cart-sidebar-reorder">
diff --git app/design/frontend/base/default/template/tag/customer/view.phtml app/design/frontend/base/default/template/tag/customer/view.phtml
index 8d49562..4024717 100644
--- app/design/frontend/base/default/template/tag/customer/view.phtml
+++ app/design/frontend/base/default/template/tag/customer/view.phtml
@@ -52,7 +52,9 @@
             </td>
             <td>
                 <?php if($_product->isSaleable()): ?>
-                    <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getUrl('checkout/cart/add',array('product'=>$_product->getId())) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                    <?php $params[Mage_Core_Model_Url::FORM_KEY] = Mage::getSingleton('core/session')->getFormKey() ?>
+                    <?php $params['product'] = $_product->getId(); ?>
+                    <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getUrl('checkout/cart/add', $params) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
                 <?php endif; ?>
                 <?php if ($this->helper('wishlist')->isAllow()) : ?>
                 <ul class="add-to-links">
diff --git app/design/frontend/base/default/template/wishlist/view.phtml app/design/frontend/base/default/template/wishlist/view.phtml
index 7fbff55..fbb93f8 100644
--- app/design/frontend/base/default/template/wishlist/view.phtml
+++ app/design/frontend/base/default/template/wishlist/view.phtml
@@ -52,20 +52,36 @@
             </fieldset>
         </form>
 
+        <form id="wishlist-allcart-form" action="<?php echo $this->getUrl('*/*/allcart') ?>" method="post">
+            <?php echo $this->getBlockHtml('formkey') ?>
+            <div class="no-display">
+                <input type="hidden" name="wishlist_id" id="wishlist_id" value="<?php echo $this->getWishlistInstance()->getId() ?>" />
+                <input type="hidden" name="qty" id="qty" value="" />
+            </div>
+        </form>
+
         <script type="text/javascript">
         //<![CDATA[
-        var wishlistForm = new Validation($('wishlist-view-form'));
-        function addAllWItemsToCart() {
-            var url = '<?php echo $this->getUrl('*/*/allcart', array('wishlist_id' => $this->getWishlistInstance()->getId())) ?>';
-            var separator = (url.indexOf('?') >= 0) ? '&' : '?';
-            $$('#wishlist-view-form .qty').each(
-                function (input, index) {
-                    url += separator + input.name + '=' + encodeURIComponent(input.value);
-                    separator = '&';
-                }
-            );
-            setLocation(url);
-        }
+            var wishlistForm = new Validation($('wishlist-view-form'));
+            var wishlistAllCartForm = new Validation($('wishlist-allcart-form'));
+
+            function calculateQty() {
+                var itemQtys = new Array();
+                $$('#wishlist-view-form .qty').each(
+                    function (input, index) {
+                        var idxStr = input.name;
+                        var idx = idxStr.replace( /[^\d.]/g, '' );
+                        itemQtys[idx] = input.value;
+                    }
+                );
+
+                $$('#qty')[0].value = JSON.stringify(itemQtys);
+            }
+
+            function addAllWItemsToCart() {
+                calculateQty();
+                wishlistAllCartForm.form.submit();
+            }
         //]]>
         </script>
     </div>
diff --git app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml
index eaf7789..e3c8e44 100644
--- app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml
+++ app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml
@@ -116,24 +116,25 @@ $_product = $this->getProduct();
             <?php echo $this->getChildHtml('product_additional_data') ?>
         </div>
         <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
-        <div class="no-display">
-            <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
-            <input type="hidden" name="related_product" id="related-products-field" value="" />
-        </div>
-        <?php if ($_product->isSaleable() && $this->hasOptions()): ?>
-        <div id="options-container" style="display:none">
-            <div id="customizeTitle" class="page-title title-buttons">
-                <h1><?php echo $this->__('Customize %s', $_helper->productAttribute($_product, $_product->getName(), 'name')) ?></h1>
-                <a href="#" onclick="Enterprise.Bundle.end(); return false;"><small>&lsaquo;</small> Go back to product detail</a>
+            <?php echo $this->getBlockHtml('formkey') ?>
+            <div class="no-display">
+                <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
+                <input type="hidden" name="related_product" id="related-products-field" value="" />
+            </div>
+            <?php if ($_product->isSaleable() && $this->hasOptions()): ?>
+            <div id="options-container" style="display:none">
+                <div id="customizeTitle" class="page-title title-buttons">
+                    <h1><?php echo $this->__('Customize %s', $_helper->productAttribute($_product, $_product->getName(), 'name')) ?></h1>
+                    <a href="#" onclick="Enterprise.Bundle.end(); return false;"><small>&lsaquo;</small> Go back to product detail</a>
+                </div>
+                <?php echo $this->getChildHtml('bundleSummary') ?>
+                <?php if ($this->getChildChildHtml('container1')):?>
+                    <?php echo $this->getChildChildHtml('container1', '', true, true) ?>
+                <?php elseif ($this->getChildChildHtml('container2')):?>
+                    <?php echo $this->getChildChildHtml('container2', '', true, true) ?>
+                <?php endif;?>
             </div>
-            <?php echo $this->getChildHtml('bundleSummary') ?>
-            <?php if ($this->getChildChildHtml('container1')):?>
-                <?php echo $this->getChildChildHtml('container1', '', true, true) ?>
-            <?php elseif ($this->getChildChildHtml('container2')):?>
-                <?php echo $this->getChildChildHtml('container2', '', true, true) ?>
             <?php endif;?>
-        </div>
-        <?php endif;?>
         </form>
     </div>
 </div>
diff --git app/design/frontend/enterprise/default/template/catalog/product/view.phtml app/design/frontend/enterprise/default/template/catalog/product/view.phtml
index 0ce7d88..70fb1d0 100644
--- app/design/frontend/enterprise/default/template/catalog/product/view.phtml
+++ app/design/frontend/enterprise/default/template/catalog/product/view.phtml
@@ -39,6 +39,7 @@
 <div id="messages_product_view"><?php echo $this->getMessagesBlock()->setEscapeMessageFlag(true)->toHtml() ?></div>
 <div class="product-view">
     <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
+        <?php echo $this->getBlockHtml('formkey') ?>
         <div class="no-display">
             <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
             <input type="hidden" name="related_product" id="related-products-field" value="" />
diff --git app/design/frontend/enterprise/default/template/checkout/cart.phtml app/design/frontend/enterprise/default/template/checkout/cart.phtml
index cac1a71..4c914dc 100644
--- app/design/frontend/enterprise/default/template/checkout/cart.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart.phtml
@@ -47,6 +47,7 @@
     <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
     <?php echo $this->getChildHtml('form_before') ?>
     <form action="<?php echo $this->getUrl('checkout/cart/updatePost') ?>" method="post">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <fieldset>
             <table id="shopping-cart-table" class="data-table cart-table">
                 <col width="1" />
diff --git app/design/frontend/enterprise/default/template/checkout/cart/sku/failed.phtml app/design/frontend/enterprise/default/template/checkout/cart/sku/failed.phtml
index 3359ccd..695b6d9 100644
--- app/design/frontend/enterprise/default/template/checkout/cart/sku/failed.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart/sku/failed.phtml
@@ -33,6 +33,7 @@
 <div class="failed-products">
     <h2 class="sub-title"><?php echo $this->__('Products Requiring Attention') ?></h2>
     <form action="<?php echo $this->getFormActionUrl() ?>" method="post">
+        <?php echo $this->getBlockHtml('formkey') ?>
         <fieldset>
             <table id="failed-products-table" class="data-table cart-table">
                 <col width="1" />
diff --git app/design/frontend/enterprise/default/template/checkout/widget/sku.phtml app/design/frontend/enterprise/default/template/checkout/widget/sku.phtml
index 0d5929b..6695448 100644
--- app/design/frontend/enterprise/default/template/checkout/widget/sku.phtml
+++ app/design/frontend/enterprise/default/template/checkout/widget/sku.phtml
@@ -43,6 +43,7 @@ $qtyValidationClasses = 'required-entry validate-number validate-greater-than-ze
         </div>
         <?php endif ?>
         <form id="<?php echo $skuFormId; ?>" action="<?php echo $this->getFormAction(); ?>" method="post" <?php if ($this->getIsMultipart()): ?> enctype="multipart/form-data"<?php endif; ?>>
+            <?php echo $this->getBlockHtml('formkey'); ?>
             <div class="block-content">
                 <table id="items-table<?php echo $uniqueSuffix; ?>" class="sku-table data-table" cellspacing="0" cellpadding="0">
                     <colgroup>
diff --git app/design/frontend/enterprise/default/template/customer/form/login.phtml app/design/frontend/enterprise/default/template/customer/form/login.phtml
index 812cc28..c543f46 100644
--- app/design/frontend/enterprise/default/template/customer/form/login.phtml
+++ app/design/frontend/enterprise/default/template/customer/form/login.phtml
@@ -43,6 +43,7 @@
     <?php /* Extensions placeholder */ ?>
     <?php echo $this->getChildHtml('customer.form.login.extra')?>
     <form action="<?php echo $this->getPostActionUrl() ?>" method="post" id="login-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="fieldset">
             <div class="col2-set">
                 <div class="col-1 registered-users">
diff --git app/design/frontend/enterprise/default/template/giftregistry/view/items.phtml app/design/frontend/enterprise/default/template/giftregistry/view/items.phtml
index 4fbb5ac..20b6efb 100644
--- app/design/frontend/enterprise/default/template/giftregistry/view/items.phtml
+++ app/design/frontend/enterprise/default/template/giftregistry/view/items.phtml
@@ -36,6 +36,7 @@
 ?>
 <h2 class="subtitle"><?php echo $this->__('Gift Registry Items') ?></h2>
 <form action="<?php echo $this->getActionUrl() ?>" method="post">
+    <?php echo $this->getBlockHtml('formkey') ?>
     <fieldset>
         <table id="shopping-cart-table" class="data-table cart-table">
             <col width="1" />
diff --git app/design/frontend/enterprise/default/template/persistent/customer/form/login.phtml app/design/frontend/enterprise/default/template/persistent/customer/form/login.phtml
index f60a518..50006e4 100644
--- app/design/frontend/enterprise/default/template/persistent/customer/form/login.phtml
+++ app/design/frontend/enterprise/default/template/persistent/customer/form/login.phtml
@@ -42,6 +42,7 @@
     </div>
     <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
     <form action="<?php echo $this->getPostActionUrl() ?>" method="post" id="login-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="fieldset">
             <div class="col2-set">
                 <div class="col-1 registered-users">
diff --git app/design/frontend/enterprise/default/template/review/form.phtml app/design/frontend/enterprise/default/template/review/form.phtml
index e616da8..0df4c46 100644
--- app/design/frontend/enterprise/default/template/review/form.phtml
+++ app/design/frontend/enterprise/default/template/review/form.phtml
@@ -29,6 +29,7 @@
 </div>
 <?php if ($this->getAllowWriteReviewFlag()): ?>
 <form action="<?php echo $this->getAction() ?>" method="post" id="review-form">
+    <?php echo $this->getBlockHtml('formkey'); ?>
     <?php echo $this->getChildHtml('form_fields_before')?>
     <div class="box-content">
         <h3 class="product-name"><?php echo $this->__("You're reviewing:"); ?> <span><?php echo $this->htmlEscape($this->getProductInfo()->getName()) ?></span></h3>
diff --git app/design/frontend/enterprise/default/template/wishlist/info.phtml app/design/frontend/enterprise/default/template/wishlist/info.phtml
index 7293b52..08619c7 100644
--- app/design/frontend/enterprise/default/template/wishlist/info.phtml
+++ app/design/frontend/enterprise/default/template/wishlist/info.phtml
@@ -59,6 +59,7 @@
 
 <h2 class="subtitle"><?php echo $this->__('Wishlist Items') ?></h2>
 <form method="post" action="<?php echo $this->getToCartUrl();?>" id="wishlist-info-form">
+    <?php echo $this->getBlockHtml('formkey') ?>
     <?php $this->getChild('items')->setItems($this->getWishlistItems()); ?>
     <?php echo $this->getChildHtml('items');?>
     <?php if (count($wishlistItems) && $this->isSaleable()): ?>
diff --git app/design/frontend/enterprise/iphone/template/catalog/product/view.phtml app/design/frontend/enterprise/iphone/template/catalog/product/view.phtml
index 44b677f..0faf416 100644
--- app/design/frontend/enterprise/iphone/template/catalog/product/view.phtml
+++ app/design/frontend/enterprise/iphone/template/catalog/product/view.phtml
@@ -39,6 +39,7 @@
 <div id="messages_product_view"><?php echo $this->getMessagesBlock()->setEscapeMessageFlag(true)->toHtml() ?></div>
 <div class="product-view">
     <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
+        <?php echo $this->getBlockHtml('formkey') ?>
         <div class="no-display">
             <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
             <input type="hidden" name="related_product" id="related-products-field" value="" />
diff --git app/design/frontend/enterprise/iphone/template/checkout/cart.phtml app/design/frontend/enterprise/iphone/template/checkout/cart.phtml
index 3bc2190..7a9113d 100644
--- app/design/frontend/enterprise/iphone/template/checkout/cart.phtml
+++ app/design/frontend/enterprise/iphone/template/checkout/cart.phtml
@@ -45,6 +45,7 @@
         </ul>
     <?php endif; ?>
     <form action="<?php echo $this->getUrl('checkout/cart/updatePost') ?>" method="post">
+        <?php echo $this->getBlockHtml('formkey') ?>
         <fieldset>
             <table id="shopping-cart-table" class="data-table cart-table">
                 <tfoot>
diff --git app/design/frontend/enterprise/iphone/template/checkout/onepage/review/info.phtml app/design/frontend/enterprise/iphone/template/checkout/onepage/review/info.phtml
index 1092c70..a4b9be1 100644
--- app/design/frontend/enterprise/iphone/template/checkout/onepage/review/info.phtml
+++ app/design/frontend/enterprise/iphone/template/checkout/onepage/review/info.phtml
@@ -56,7 +56,7 @@
     </div>
     <script type="text/javascript">
     //<![CDATA[
-        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder') ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
+        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder', array('form_key' => Mage::getSingleton('core/session')->getFormKey())) ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
     //]]>
     </script>
 </div>
diff --git app/design/frontend/enterprise/iphone/template/giftregistry/view/items.phtml app/design/frontend/enterprise/iphone/template/giftregistry/view/items.phtml
index d57bb88..aae0092 100644
--- app/design/frontend/enterprise/iphone/template/giftregistry/view/items.phtml
+++ app/design/frontend/enterprise/iphone/template/giftregistry/view/items.phtml
@@ -36,6 +36,7 @@
 ?>
 <!--<h2 class="subtitle"><?php echo $this->__('Gift Registry Items') ?></h2>-->
 <form action="<?php echo $this->getActionUrl() ?>" method="post">
+    <?php echo $this->getBlockHtml('formkey') ?>
     <fieldset>
         <ul class="list">
             <?php foreach($this->getItems() as $_item): ?>
diff --git app/design/frontend/enterprise/iphone/template/wishlist/view.phtml app/design/frontend/enterprise/iphone/template/wishlist/view.phtml
index cdbf474..0c35dd4 100644
--- app/design/frontend/enterprise/iphone/template/wishlist/view.phtml
+++ app/design/frontend/enterprise/iphone/template/wishlist/view.phtml
@@ -48,21 +48,37 @@
             </fieldset>
         </form>
 
+        <form id="wishlist-allcart-form" action="<?php echo $this->getUrl('*/*/allcart') ?>" method="post">
+            <?php echo $this->getBlockHtml('formkey') ?>
+            <div class="no-display">
+                <input type="hidden" name="wishlist_id" id="wishlist_id" value="<?php echo $this->getWishlistInstance()->getId() ?>" />
+                <input type="hidden" name="qty" id="qty" value="" />
+            </div>
+        </form>
+
         <script type="text/javascript">
-        //<![CDATA[
-        var wishlistForm = new Validation($('wishlist-view-form'));
-        function addAllWItemsToCart() {
-            var url = '<?php echo $this->getUrl('*/*/allcart', array('wishlist_id' => $this->getWishlistInstance()->getId())) ?>';
-            var separator = (url.indexOf('?') >= 0) ? '&' : '?';
-            $$('#wishlist-view-form .qty').each(
-                function (input, index) {
-                    url += separator + input.name + '=' + encodeURIComponent(input.value);
-                    separator = '&';
-                }
-            );
-            setLocation(url);
-        }
-        //]]>
+            //<![CDATA[
+            var wishlistForm = new Validation($('wishlist-view-form'));
+            var wishlistAllCartForm = new Validation($('wishlist-allcart-form'));
+
+            function calculateQty() {
+                var itemQtys = new Array();
+                $$('#wishlist-view-form .qty').each(
+                    function (input, index) {
+                        var idxStr = input.name;
+                        var idx = idxStr.replace( /[^\d.]/g, '' );
+                        itemQtys[idx] = input.value;
+                    }
+                );
+
+                $$('#qty')[0].value = JSON.stringify(itemQtys);
+            }
+
+            function addAllWItemsToCart() {
+                calculateQty();
+                wishlistAllCartForm.form.submit();
+            }
+            //]]>
         </script>
     </div>
     <?php echo $this->getChildHtml('bottom'); ?>
diff --git app/etc/modules/Mage_All.xml app/etc/modules/Mage_All.xml
index 6469942..5471e89 100644
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
diff --git downloader/Maged/Controller.php downloader/Maged/Controller.php
index 46131ae..a1b7c91 100755
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -367,6 +367,11 @@ final class Maged_Controller
      */
     public function connectInstallPackageUploadAction()
     {
+        if (!$this->_validateFormKey()) {
+            echo "No file was uploaded";
+            return;
+        }
+
         if (!$_FILES) {
             echo "No file was uploaded";
             return;
@@ -1090,4 +1095,27 @@ final class Maged_Controller
 
         return $messagesMap[$type];
     }
+
+    /**
+     * Validate Form Key
+     *
+     * @return bool
+     */
+    protected function _validateFormKey()
+    {
+        if (!($formKey = $_REQUEST['form_key']) || $formKey != $this->session()->getFormKey()) {
+            return false;
+        }
+        return true;
+    }
+
+    /**
+     * Retrieve Session Form Key
+     *
+     * @return string
+     */
+    public function getFormKey()
+    {
+        return $this->session()->getFormKey();
+    }
 }
diff --git downloader/Maged/Model/Session.php downloader/Maged/Model/Session.php
index ea0cfb7..4b59568 100644
--- downloader/Maged/Model/Session.php
+++ downloader/Maged/Model/Session.php
@@ -221,4 +221,17 @@ class Maged_Model_Session extends Maged_Model
         }
         return Mage::getSingleton('adminhtml/url')->getUrl('adminhtml');
     }
+
+    /**
+     * Retrieve Session Form Key
+     *
+     * @return string A 16 bit unique key for forms
+     */
+    public function getFormKey()
+    {
+        if (!$this->get('_form_key')) {
+            $this->set('_form_key', Mage::helper('core')->getRandomString(16));
+        }
+        return $this->get('_form_key');
+    }
 }
diff --git downloader/Maged/View.php downloader/Maged/View.php
index d707f18..59a98c3 100755
--- downloader/Maged/View.php
+++ downloader/Maged/View.php
@@ -154,6 +154,16 @@ class Maged_View
     }
 
     /**
+     * Retrieve Session Form Key
+     *
+     * @return string
+     */
+    public function getFormKey()
+    {
+        return $this->controller()->getFormKey();
+    }
+
+    /**
      * Escape html entities
      *
      * @param   mixed $data
diff --git downloader/lib/Mage/HTTP/Client/Curl.php downloader/lib/Mage/HTTP/Client/Curl.php
index 0f513d0..971e339 100644
--- downloader/lib/Mage/HTTP/Client/Curl.php
+++ downloader/lib/Mage/HTTP/Client/Curl.php
@@ -372,8 +372,8 @@ implements Mage_HTTP_IClient
         $uriModified = $this->getSecureRequest($uri, $isAuthorizationRequired);
         $this->_ch = curl_init();
         $this->curlOption(CURLOPT_URL, $uriModified);
-        $this->curlOption(CURLOPT_SSL_VERIFYPEER, false);
-        $this->curlOption(CURLOPT_SSL_VERIFYHOST, 2);
+        $this->curlOption(CURLOPT_SSL_VERIFYPEER, true);
+        $this->curlOption(CURLOPT_SSL_VERIFYHOST, 'TLSv1');
         $this->getCurlMethodSettings($method, $params, $isAuthorizationRequired);
 
         if(count($this->_headers)) {
diff --git downloader/template/connect/packages.phtml downloader/template/connect/packages.phtml
index 94c09dd..25ffe8e 100644
--- downloader/template/connect/packages.phtml
+++ downloader/template/connect/packages.phtml
@@ -143,6 +143,7 @@ function connectPrepare(form) {
     <h4>Direct package file upload</h4>
 </div>
 <form action="<?php echo $this->url('connectInstallPackageUpload')?>" method="post" target="connect_iframe" onsubmit="onSubmit(this)" enctype="multipart/form-data">
+    <input name="form_key" type="hidden" value="<?php echo $this->getFormKey() ?>" />
     <ul class="bare-list">
         <li><span class="step-count">1</span> &nbsp; Download or build package file.</li>
         <li>
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
index 3bbc741..9be1ef1 100644
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
index 0000000..f382b65
--- /dev/null
+++ lib/Unserialize/Reader/Null.php
@@ -0,0 +1,64 @@
+<?php
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
+ * @category    Unserialize
+ * @package     Unserialize_Reader_Null
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
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
index 22fc845..76f6361 100644
--- skin/adminhtml/default/default/boxes.css
+++ skin/adminhtml/default/default/boxes.css
@@ -78,7 +78,7 @@
     z-index:501;
     }
 #loading-mask {
-    background:background:url(../images/blank.gif) repeat;
+    background:url(images/blank.gif) repeat;
     position:absolute;
     color:#d85909;
     font-size:1.1em;
@@ -1310,8 +1310,6 @@ ul.super-product-attributes { padding-left:15px; }
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
index 9d176a7..0000000
--- skin/adminhtml/default/default/media/uploader.swf
+++ /dev/null
@@ -1,756 +0,0 @@
-CWS	�� x�Ľ|E�7�U�=5=3�ђ�a,؄eY�,F�d��rXI�p7̎4-k�hFL�l˻{q"�d�1��䜣	&�L���|�S�=�=�{����ɜSU��S�N���&E�,T��V5JQ�Ckb��w6�7��mJ���Tښ�����r�Ə�7o޸y���dg��u�����n�w�mg���N���wN[c��#h3��lr0�̤[(����0v�Sj�7_��P6%�L�7S怙�Y�w�+
-J�N��d�}⃃�do��?g�?�;g^|��s_*n��=����䒹��Ok"�c�LI��[voi-䗩�$�8Qh�>�n�)�������l&1ԋ6��(�ٛ���I%�~3��PzN:3Ϯ�@�4�Y3���S�4�O�ӳ���}ڧɸ|X�1�3�i3{[v��N-�����fu��E�v(�}��ʍ���d~���wH� *�[�ȿ���l�+Le�	3���Qq֊u[9s`�Tn���*� �җ���*��8e'�g�U�P�ÿTk#{o�G�t&�����.�\�pa#��wf��&��ݟ�?{VG"�p!_�h��~ђ�ԅk"�Bm��Mb�"���ϋ6��V�i���:��ß��ӕ*ّ�S��{T��+���������uw���D�}j������;�z�	0�N��k�]��������|��,u�M<��~�mON�-�7&�W���l���d:W&�q\"i���em�k��r�dz�67�L��l|8d��mf�d�2��O������N�O�I��ɜ��M�e*�]��L�&������A��@jR�ޕÈ�Q�;��Q�X�G�dz�,'49���L�Y�=9s~.�4EN��M5��Ĭ���K��z!ܺ��z�/00mh�����xڢ	Zc���5-+ٓL%s���Ќlf��撦�2��%��DgF'g3iԤ�O�<]gɞMF��i�;́LΜ��9�N�Y�>��$-453d��[��V惝�!C����qM�?\�O'z2��T�)�&1Le>>S#��pʴj&wuu�s:�J�Alִ2CYp�2��x����_��L$�Ĕ�G]�
-�2��{�H�����lNv�͙��-����l��J$:�(wk�4�N�Lg�m�Vy�g[f c[+�`�g�Me��`ִ5�U�=G~��I�,���l|�?�kUvfP��ȋm�����w�>l�U�7�L�s8�[�op�?M�r2��&�T�*��:L�IC�\&]<	���sfI�sM[�C$m��V8j��_�����-�!��D�$��a�̅fvv8L
-�����5� u����S�)˘4�3mQ�0ؑ�����L'�=)3��ΙM���0R"r�1�$�W��J8=4 Y3�b��5e�|����I���2OTk�̍�b��≄Q��e�LDe�N+�|�ݼ����1�k���3�'�5��Gc5#�6+rБ��A��̿�īNZ$���΄ꄉ�mX�Ӯ~�+���s���2�P)_u�	G����䫰�7����dr�ּ>���Y��:���O�`I��	��*��MiX�����Q�*�0�)�MZ>�M��	ό-$m�v8 K�4�M��d�
--�A�mf_2��ܶ儀$���-�$�2Y��Jӣ{H�* \�xj�53�
-%-�7�/�X�~{9�[���B;HbaH��ސ��U����I��@|�cKS�?'|I�\��`6�����՝�/�鉧�4���K&r��f�ʚ��������L��d�,��{�^��@�9���1��7�K/mȞͤRԕ��8��V�n}�lل�~Ym`0��5�D*Ӫ�ơK&�{�����Xkon(��J.0�xj�?�O溡o�$��h;iqk�@q� #�.�	���x�9ym~��lX�%S�TV��#��^9�S)�����Qew���cLE.�oл�O���[F}K�GVMkǒ;��Jc}����I���x*��%�Ĥ|m��ݙ�9�3�X�I�7Ҍ����(k��)��4K��Nd����jM�	�3��К��}>Iv27=;�'k��O��/�9��%���28Y.Ѵ;[<�-VJ!���NA�0�%m����)���LJ��7b�@an�c~�jϴu�L��e	�I�7j��y���-��+9�:I��U�\��J��mE��l��"fϽjbPGܢ�$��hJ�n�yK���=���R��7��W��.���d4��yQ��[2srI�,;V$n� �Xs|��`����r�X���fΕ��f���`��d"#�.Y�#���6�T̀zX����N���8����Oگ-)��xv�����s4
-EҟSGZc1��蝃�Fb޵��zg�BCS+��7��K-U$e1��Y���"�e�3Q�F����j�,���7�+H�<{���.�m��#�8-��D��R+2�����=M�@L��f	+ߕ_ϑ�l�Vf��eҷD��FJ�S�HT��a��0S���U�WD�D(���{��Vg���rE�mu�H5�_?*��y�l�&��OD�v�pҒ�E�I�W�z�7���|.��̬`֒=���3�u�CU��63	`a�V%h:a�L�}��֛ӵ��m1���i�Ȑ���S�v���.q=q|�`�iS_����-�tru|����3ݞ�f���$�42��.�������o�Q.��A'aȶK�2匷G��>֔Xw�
-�r�#�6#�9Z�����>����{�Jǘ� �M�hW���Z�~~��3�s��jِ׸��l���yV���5	b���^�*�oj��dѿ艘m:�Z�c�Q�%�t RP*�����X�ޠ��L�[�Q�jMυ�HXW��əT&��@s6;�ɴƸ�Sf^_����0�tkj�3;a�O�E-�&Y$�*�T_zx}s��c4_D�i��D�]螃Y����ң�l�!�D�Pc�<�by_b��5��n��~��-�u�˝����+���ɯ��Ĭ���V*1���U��u����:�L�Tk�1]ai��f��Ml=������y����'�[�c����ѳ[��Q�ZҮ٢0�u�p�)�)�Qi�K :�H�U��k�<���[��Y[J�s>6��nF���R�����ad�c���kT�Ó���w
-Trs��P�|�Nu�+I�^J������넑���!=�
-۩D$�IS�-�����d)k�7eƳ2�-�Ym���U�LC��4�]�)p�$�Ob%��J�(p�S���f����vv�ю�pf�݅�mk�1�D�Q��w��3M��)���jW��+j\���ф���s3�^>e��p��Ә?t��?_א"��� ���*���=ٟP��L��ݩL9�������c�	E�5����$F�2�*W��-�R_ꜝ63����M����F�1��X˽AXr��R��v�,I���g��H��KΎ�7D�e��D�	�eC�:o��W楆�7��S��@�Yh_l5�N�'�7�t\L���SЖ*�{5�H�i��HWM^e��m�<��WNr]���ش�U���V#\T~��q���dE�@Ĺ��2W���iYr���,���(�"��fo9Eu�E���g��v�Ѵ̼�d�;��
-A�l,PӶn��Ԇ��UA�K����}&j�l���I��gE76�4>jȃV3�#��9�KNO'W�N�9����5�6$��cQymZ�'ʫ�p�P��?	ňh�P6�PUK���f�[���2`Z�&�z�b�fyM��b�!K�4C��7�����P��[�g����[�a�"�s���K���LZ˞����{|�8����Aۮĕ޸���{�>��*����)��X�y]���������������b3���z`lV��{�Xt���ۻ*���%l��|���"Kt�̩��h׌�փb�ѩ�t�6ÄL��y�(��ĳ�R�s�H�ãp���Hl��%��!��]$�a/���A}��!WՔ�VC-�U�\�@\e!���S�N��0�mn�k9��aeLf)p"���S"ԓ��Mno��gn��(���p�"&9�=�\���W����%`Jjd��X�)�T!��R\���⊘_��-��`,�%�U�,��vre1�B��hbsi�	ŤR�*cE"�%8ҢI!
-��[�N�3Ҷx�]-�N���U��f��F�Z iE�Q�6}ִ��m�흓ۧu���^�)�Ju�Yc��}r<���-��B\�6S �Ўy٨�����@|~r`h���(]掸UӮ)`�*l,�<߃����\��A�c��[*љ�V��	y����ȧ��4ih]��������=z���v|���ƅ�{�d:��(�,�N�۲��t�
-{&�Z��L���R���G4��S	P���^G�[�g������~�RWش{2m�y�s�'wz{^Q��g�͗Q��+�Y�?�rW�ڼ!�y�#�4]�&DҒ�V�[ةɴ�s#�|�JWǤ�����=q�La�7#c�i�� Tf	$��S�/ډ���������<�Lc:��*��6ߴJOce�ƀ[RE2ݛJ�Ѵ��
-Y�ۺ2{���#+=��2j��G��a�E6"V�ڬ�e�󶤹�F�L�Oe��1�Ѐ��	Ýz'=��s��c ��ʡ),ä4���*m�X+�T)E�BCٔ�;�Z)��yfg�
-�,��,w{I��.�-�Ԉ�M�g��%o�Y#�~�U8c�4l�xQ�n��Ԣ{����D-���̬����5C��Ŵ ��YU��.��c��B�mM���y�x*�GsX��)�A�?�G�Q��Z�4��^������n��P�%X��7�O��(%O&Fm����&#\�0��C����K���M'hc���8h�=_a+�|��WN���J\�;�,B'���y&I�42���� SH���^^Δ*&Df����{�f�ji6`	�����Fʋ����>rY�{�V����cd_N'��H�,� ��z�3���G��:���κ��|u�L�<Y�)�l�{��Ea^�xA)L�@�F��3����\}ܐW)r���}�[^8�k�岵�T( /Jd��NI�X�Lʋ9+�/���b@�oY����^y�Td�D��h�׮F&.��H���v8bz�mMN�:v _F��uba����7�(GS��X�U�����K�6��D�-�tXG	*�ܰ���c�Lˤ��=/���:8��/ީ��75>X���5Dz�1�,h�L6WT��y�E:��'S�%gՖ:�3�Yʚ}�,�ع�P,[�o����b��Z�G�E�c>ά��nHU���VC�E��pN�I�N�)I)�#B���sA8����G�^MY�vFua-s���չ�e����}�Ck_Ma���F{^O(~UA����!��!Ag�������ڗ�T�`O�. �㔤��.1�2�rv������9�C����At��vb�1rn5�Ʊvaخa������,ٝv$�Ҟ5`9�m�ϩ7���UFz2X��θ����q�����������Vġ����A�(�����Q<���N���MZt%���_sÃf��t�3���[˱�k�{OܶI�?hFҢ3����u Qd@eo�W2}D�U:lh��}#��ʼ����iPqG����D�Ll���g}�Fn�)[WX=j����ݲ�#�޸1��p�O��d�w����h'o�.{M(���N�_���b�B���f��ٹ����4��pP*�����mUŊ��s�!��+X�wr�ì��IϮۜw{F�Iiyn����̜*��N�����j"d@��|�NES����l]�Y^�:V�AjQ&��=1�s��*�xc�'}�g��&��/3&x��Х�!��V�2uiu�s<�ah0`O�2;���S�/���A��G!)��F���ǜ�˕75�[B��r���OM�L��F�ئ����옰c��S
-~=���`�-Z�{st�"O��pNJ�}V��=#��	ls�,=4��YU��/���.z�v-��| &9�U�zꡆ�վ��q����̑i��)�m�<xe�6'�
-R��t��
-�	n�k]���m���ƌ��-����Ü�`�~|�5�
-���Ŋ��ә4XEs-`ߔ�Ƴ�8t2X��0	MϞ��R5��@�>�ʿ�ǆF*� ��L�\&�H�(�Un7ý�f�-�^.�:e��Y��i��p��ʏ�`d���U��b��xJa��@{�W5�L��L�fvmk礝��!EA��zE
-D��8W�[mn�;�uve�OU�Ѷ��X����]�O�h��gѾ3����O�e�����Z;j1f��W睓��ŶBH�A���j�L��;����)L����>-������2n�����pf���mۯ=6e��]����Z�kN�����d�zu��B���8+:�m��|�1��F�M��O����&�n��{:��i�(xƌ����n4�){�9�s??�I�I�)oF���s��I>ӽj.��m֨�ܞ��� y0Ն���KiX�l���֦BAVvw�N�2�sjl�����k���S��� Ħt�Nm��sߗ��	��H�E�E�c��O������^:ۧN?�=`������]��D��n��0�'an��U�;��~��U�=wD�3�&`/���pX��im��Vv�;U������5=����v���E!y(�����𥍎{�<䔈�c�=�������]�P>���Z�rۦOk/�Y,�<��kzgl�6T��_Δ�4e�Whe+�9":s1�&���Q���钮Kje�:�ђb���+K.�k<k���ʚ�NI�F����Q�\���|�r��+[ftN���+��Ԡof�[�������O�2�C"��8�'�Z���TR���p��D1�]+���RI�a��m�SZgvt�I�ᐘ
-'����@��)퓻��A���T��օ!�G3�;���]�V�#��]_��WrJW���t���z��˅��!nE ��W��;�ҞC�#>eE��M�>��c����O3����_4�*h�،�3 ������]�ݤ�f�vĈ+n��R�DT��w����2��>|��N��&w�)�J~5�4��R����`��~6��g������ⷱ�/��"��R�� �hl)�6l�+�jOs��n�$�� /+��ݹc��;K�L�?(�Ϗ�����{�ߗ���H��~���V�Aq�fī��pE�b΂7y�hG[>�ﵺ��yrka-,*}K��q'���%Xj����Վ¥���U��g-$r�lN����-�h4䌸��w�ֽҭj�u��v��E�I^�b�Z�I�~ ԙT[��<���#�̓ ���P�5���*�P�Z�W1>R$���ĐEbu��Y�7ߴ\x��c�`C�����y���"��X.9过��:}�Z���ُ��V.gE)��ʺ��:[��.���.�۷���1�qk�i��쐕�dʻ~{�Ԛ�_��1��4B�iӡ��.wL���� u	�7;��Wۦ2g����V��ɰ	��>�}�����XY�te�yX��j{�C��)*�O��i�ۦ�$%^TR-�#ߙ{ʫ��C���B�Y�~�����NI�b!au����tRʋ�ї��t��0��+H���9C���ʧD;`�Mm�A̌�}�hf�bc����E:�:�N��Bנ�����A��L�ZJa�3]1IZ����4b�	YC=V.��L������H��&���yPe_k��I!5(�74j�z��M��xZc�퉲Uo�� �v0����	�wk��KD.n�t*�� zs挀���w���7`N�o���{2
-�g&&� -P�v�NV)Y�NLs���<�+:��6�ᙘy��پD����M���|��JOmN��l]�;�3�C}�	��Q�6����h���|��<u�5]�d�0�����:����E�b��	�ҵ�k��-t�c�U��+�
-�8e!e�������k��\v�v��#j�E۵�ҩf��������o��V|�Ρ�̓��Q�n�����v��۵9�Kj?�u��-UJ�&�ۘSL�-n��.M�/+쩵.V��Z7Ek�����vdkJ�v5�n��5�E@���%t���RPɕ�qs~Z�����z���Y��OB�v�n�,D��Q2�Y�d,�	�D�/i&&����~�D��a&T{S�	�id��P֚�-O�e2=I�8F�{�����G+��0�lHp�t�akG�a���LњJ�N�a�t�O�������\�|�I��΄n���؄��h������m��ҿҵ�?ш�?j��BF{lB�o�Ƀ4��fϽ�S����/}�f����qp˼��BWf��O��ov� �k�2C�@�!Q�j�5�%�i��ݲ�n{�����id���{8�׊�����F��E�ފw��A�}�l-T�WC��2���2t��PasP�$��N���kt�N��\#�&��*�0t�H��i�g X�ظ0?�c��}l�!A��rX,�@o��2R��f�Tu��lƲ쭯�b <���1<Rf	:��r�Nm��t,=���wR<�A����/7���_�۩�����9y����͞�⋷Q�˴�I�'s���$`���Gr��8�S��D�$s���II@�Ly�Ze�-<I)����0N`���u��)�U� ��׬r>|)s�9�?�p���4b�Fg@�fZ)��X"k��Zv�$�B�7D���ݷ��f2z��4�!������f����&���#V?�#{�cU忭�q/I�����C�������	�I��<+�,v+_�?�ƽٟy�w��{�9�EY���?I�����W�^�7��_6��QQ�+�-|Q�����Õqk���;29>��*]��B7���D�í��/���%�]�N����=��E�MMP��4�2u����@r~2mi$�ͽ%�sIS=`�ww���f]�tyڤb�L���=}�&����~�w�n�_��r%�8~��� K�Y��a�X2`2hS�~u >_�?�T6X8	�&�����fV�sϾ\D�*�)�-c��!vd����E��ؕ	�@t�#��_���'{�j��FA>GSݓ���b�y��#�?�ғ�?94%���/)��o�ps��e��<<P��>͚����C{�B�%\����}8�~��X�xg�l<��?5F�B�u�.;� ��D����?�i۳}��);�8���z]���Hu4%ml��w�%��38w��Յ/��ҒV������X�>��۱.��o���5�1����m��ԭ0�������c�l��ܐ�ޓ��j�I�SI޶+*����R����Fb�O��@u��^�nv��"��~:�����r�����c�do?M��D2gL@m+d���4��=|,�y5\HTK7�����j$1üK�	��}�6Vż�If'�7��t���齧�/�LŢ�a����͟��5��6Iɫ.�O�9����&�F�E�x����.�#Mj�3��#�$�2E�ǘi�y'��^�\��,5K�O�X>v���	ؤ��h��&M�h�E�[;����?�A�e >ܒI��[z�k��{����!3�%���N�Б�Ղꜷ�;�@ŵ�dr�����q�!52�4��6�=ѩ�~���K|��ƅ�C�~O���C��j$�l۰��~�ə�TB����^��Upv�)�dz#�OYt�4dj4�[��{���:"��n4�ʏw�P.C���!)��]
-��d�`�
-Z��y�^8R2�_�i�U�i]������o3��2�bʬl�2�YC �O69�ψ:�\�����q���:���[;����F�e���d�`)2R�ݙ �3e�� ^�Iᛞ�w󴙑Y�+,Kyө0yE�ި�mJ�=x$L�xv�Ek���� ~-r�Ԣ��Ј�d4�9���m��n�!�>�<h��'L���	iͱ�3�럵�3�4�k��Go��D*�c���a���1HO.i[�˯����fe���MK��$�̎22Tc��{�%�́�ܰ�X���'����&�P$���3Bǖ��s�~��26d_.ӯyl;S�Uh[L�R�j��i�ø��l����y�n4
-Z����(�R_2n�CKҞ6�f�E��
-���q�J�9V�->mm�'ﭠ��7ζ�t�6C�����X$�}a��A�����iki�f2�s�yn�B��������Uv�'L+Ϻ�HJpN:�;�y��;d6�f�F�UX_����a;V�����|3e�������:5:�����ǍWǍ �������^Ll7�[sҦeU�~�5�K���qK�@���dj�����MI��[&? O)��`��$�K��g�W����b?�k)y�TV�s�,})���9C��[�o�ճ��l&8!i�:�N�#N�;3��~�cKo@��m�7��T6��t�Ӕ�BC*͚l?q#�`��4,�����zD`�֓2�٤C5�i�V2��Z
-�SϤ`����� 0l���������a�508���b)��D�Po���kX��>�F����x�菧2�� ���y2Y:��^��rRmX����۞bc�.��.�!9-�~�Z�������HL?>�꼰���ʜ�'�ۛ�ԙ�-'�;��2i���M�b�ČK5 U�����f}��c���9p`L[S�*��y�|*m}S?T�NA@_�;5a����lKU�p�g;���,����Q��yi�J��CK�si���'�x6ޣ�����lJ����Z.ٓ�`�s��Cg�~�'�%̹��@Z;x0Q03YmN� P:����G���6����G�!fN����x35Du$��$����!q�r�@Ͱ����g6�s����<ޛ��]�q���&7S|v��i>d�$���~�CW��œ9~p�<��d��,O�x���3|0�s�'˳���Yn���!<���\n�<��|(���!��=&��$�����Ssy*���<��s�|n���� �/�����}|A�ω��&����$O�������9|�>��ܚ��|h��� �\��L>�Ѱ8H��)uNf�
-�pk�'��<��V����=| ���@N=��dx.����Cj�ʨ����8��y��{�<���Y�x|�����<��gx��j_6��P.�����O��)>g���<��Si�����|����@���<��i����a��p���l�g�q=�p��V��<����\������;h�	��[�lk��?VC���NXj:����d�*&����Rs�jn0����=�9�����d^��,������j����.��aB�?v�׸m�99����]fΊɳ��t�}�8w����B4�Us��P<����:t|.�h/�yO��<?�u;[�/x�Fi�"�Ǒ;������d��D�߸4N����\Ud�1�v�]��8�@h+6�]��d����z�Yz���ZmZ6�,�XU%�0.47	�X�9��m���'N��f-��D�tف]θr+'�87�y_��hy;���!���q�zV�����������-�����~|�����ߧ~������芮����c�+Y�u�X�<�&n��y�S��7.RSu��(��h�q�<Vm<I�?Ym<Um<]m<Cm<��+�������Mj㭔�~��A�x�/z����"-x�ָNk�]C�Z�sZ��6~�5~�5~B�/	}�5~���-Ճ���S���)t&P�,��l=�Vo<W�.5^�7�H�����#�#����������6�����x� tf�q�������U������wR���^4�L���
-4�M������o���?4�h\(��%�U�/x��P�+Mױ�5F�Z����\��<��|��7�1�����5����WM�ԦwB�E����M'5��D|oص����Co�@k��k�Dn"V������&�_���s�&�S�c�wM���/��o�޴&�0�i}���@ӽ���Mo��@w�~���g:�+g��ͣ�5��e簦s�y�|v��]�.f�0O\qԥ��rƮ`W�5l��FD��f���c�c׃�̀a��n`L���o�T+�h��ٍl�u���廰[X�� ���W��[��v�1wP�;�ˮ`ϻe��=6�w�2��~o���}l��Am}�(���ك�x���킧���q��(�c�����	YJ��|�Q�������N�����,{�m �9��,���0�)���e΋T�K�}_f���+���x�(�SK�o�"��FS��oR�!c�a�o����J��K�b����J���l)[��e��8��e�5�h�1�V&XƎa﹁��X�>c���T�����CD���
-�LjH����/�Bh�B��Z�B��!F	�$x�`����n%X�жlal+�v"4V��Eh�Q�������ǉ�."��`��7B�Ch�bO!~'�^"2A��-B�EE�Me�E�M�ۅ>E��D`�E��_B����r�M�B�����[h3E�,Qs��=H��U��M��]��E}����	Qo��>Q?[������?�Ō2n��ECJ4���hȈ�A�p�hȊK4�DÐh�+扆��aX4,����#�hXXXX
-8p8����� G�aB[ƌc����h<p"`9�$�ɀS �N�X8�p&`�,�j�ـ5���s ���� p!�"�ŀa��h�p�r� 4k�U���0��e�2ƍZ�ؙ���}#�7n�C���n�5����	������^�,���~x�����_�<�0x5������_4?���:D4?��
-��O�;W4?��ԑh� x��*��G���"�%�_f����^C��o��&�o��1��msJ4�x��	S��}���D�pzD�G�~/F��S���)�?�&6�ob��p0,�_ �D_!�!k��~�[�w����M��80K4���O��1� �K0W�G4/��0��#@���Gr1�(x��h>>k�1p��y�oB�>��x�9�|���lѼ�N��E�)pOR6�4$9��3�_	z�}&u�*��B�j�g���k��}�x!��\��b�y �� p!�"�ŀK��R��.\�������j�� 0�ص��q�ý��U�oB�f���Q8� ���
-�p;H�[������!����{����!���x ���0����� ��@�'�>�$�L��<� x�	(j����P��"�%��\��}U�xi��b˷ �[�g���8�r��{����\�|����'�� �{k�֟>|���k�7�o��[ǅ�=�l@����\ &�6?�]�B: KTa,�{�*�;B�#U����8p"h�U�h7�$C��OA�i��T�.� gV���`�v9�*Di1(�χ{��~�*�/�{	ʺ�e���B�^�p�ZU��S�~�*~s3`��h�ѷ�ⷷ�b��(���T�.Tq7�{/\da� �<�����0�G�>
-x��O���*&<x�,` :f�sp���A{���/��� ^�x]5�#�ϛ���-UL|��]�FАg�{p�| ���� (g�ǀO@��9�_����&~	�
-���~�[������� `���&�q�����P�,���ŀ%��8\}�xhG�B�C�'��1H������x�' �0�D��NB��x2\�i�)Hw*�4ĝX�pW����j���A>�v�Z���\����ľjb�% ��K�^�p�J�U��� �`�']�z �}�a�Ф�p�f ��-��VM����D;&ߔ��r�&���p�^�}�� 0�S�� �ɔ��>x0_L�B9�1x��<�	���� O�<�
-55�6������K�MD_����^�����	x��x����n}���G�Ǆ��g���9�ML�
-�5 ����}��	�&:ք�P7��
-o�b]K`0��R�#�`�<�H�G�X8p�x�	 �=�w9�$]h'�b���S�?M7*Q4 ��c�}���Ag V�6��?���*]����F�5���9:��|]�.@2�:v!܋ Ї:��#�����t���W�����Hw�."���p�z]�o�E�&�̀u��E7v����M}�#�z$� ���� |��w'?��.����EB�wU?�A�A����^�A �ݯ��~�C��ú8�Q]��	��ԓp!��@{~�D�����m�� ��&1y�K �ž/�}M��}��m]�.��p7R:���� � >|
-:��C>��s��/_��5�oh8 ����.��A�ua�X�"�b��R�a��G ��YG�=
-p4��2���� �N �X8	p2���񣮋�i�;= �V�<�<�<��J��*�Y^8;`��b�ڀXp�hC��) 4���΅��0T��<�QC��/8.�����,� .����.1t����g�C����4�f34�����p1�������\������ 0��u-�� �ġ7��d?�f����z\L�C1ʇ�
-�mQy{@�܁��
-���nx�	���>x� 7[G����]����ad~��K٣�<��b'�BO�����*�x�l �s��J���A{؋(�1-(�`��^%�7�kq{# "o�2�Ҿ�H���O��>$�G�>F��|J賀��< �c_ľ_��-��]@�Hk�����8��(��,¶w���y���p�p$�(Ў�2��"�x�	�倓�N�!�i�LB�:��p�<��� .\�p5�Z��� 7�n�X�p7�^���<x�4�Y!Ng�y�+��H���"�2�W����W��u��7o��x���}�����G��1�,�O@���+�7�� ? ~�X��� 8p,�x���� � N� �����g�]g�s�9�<��s>�B�ŀK���ј��1wGc.�dW���<W�0F�i*^g�k��:��� 7�n��#(�i<��n�=A�wd��}A�G�@{��1��' O�<�<� @���}q/ ^��ث�x�FP��ބ�-�M���l�x��C�G����j�)��}�������5<߀����;�'��l��	�3`���Et`)�0"ϑ�Ў2�v�!���p,�8��X�N t"!lKֲ��;���Hq
-yN%t���W�|`%�g�]8��h�p���_x/\�p%�*�!�r�Jڇ�S,���Z�u��7 n�D5�LV�Z2�ײ#�#�-��T��E�J��y֓�NBw�{y�!�q���a�h���e�+H�c13�%��!¸E3�[e���%J�:�MCނ�6��F�{��%�1ޥt >|��	��S�b�� �W��&�H0Q��?p`yMx
-�9	��� N�X8#��gQ���;��*I#��X�V���q�a�j� �ڐqڹ=='d��!�l�<�NW�悐�X5����,F�,gF�0�q	�_"��*{�s���*�*��c0��a�HŮ3����f��9f�CoF�f|�u�{�댈�n(bl,V#�5H�1d�P��m�q�0Ɩ5WǨ\>@܇�� >	5W�Un��V��]�T�Ps5l�P��jŅj�X�F�o ߆���j�%�+LW �uj�q��U�S+>��w�ƦP��Q�\cL���ha-ZXk<�֢��Ǝe ׁ\r��Zg<	x�(�e"�8�	X
-8p8�����¢��� ����'��?	�ɀS �N�XA~����3P�"&n%���V���$��|+[��g�W:��Da���C���x~ظPk4�-oe��ˍZ� �B�Ea�O�� �i��k����^q�8�W��+N���x�]��Dn|�4�t	UwEX�Ϯ"���]M�k]6�Aq�,�5�s��&����#�{�Neͣ��:Ǿ���'�y�4�W�+^��{L3V!z��k�%�E�8�oi�ɶ�a�	�D�fBg��֑�n��|��-l�7oU�^7�ַ�ٝa �b���`�=:G��6��LZ�k)H����ϛB���V�q�������[���J�Ÿ�n<��nm��mm\
-��T�LS�G���`�!�a�e��hS�?x�`�*^e/��2������^�x3l���i���Aol��8_������x8���`Sh;��v�<67��ؚ���������������qv@7V~e����q㏚1�̸+0ָ'0V�@�j���`������Z�9�h�^P1e�`f�8/Ҽ��f�QXsQĸ=4��h����� ���݋#Ϳ�s���Х�.#t9�+]I�*B�P���w�k	����.Ҽz�)�����ɸ%B�["�1��Լ3�w6��������d��_�o���+�KN*ool��@��H�1�c���q�U���^f�$Ҁ8E�2@A��C��0��%D %�Ԡs'AP(w���r$b�\	R�U�GQm�z55S�VM�������G����.�meeeJ�E"L5\uZA�ԩ�Z��tթZf�#Oݿ�(u�a�|�y����x O�ۤz��{�0!\T�:�-�����V4P��B��^�Ǿ�j��E�az#��� ���L��F�St��uT�x�>�ɒ��0/�7@1MNJ�/VLwe�Ww�7`�����A%��BL��G%�bD�Owr��f�6�擔�b��d֕J)I��`~�0�O]�E��USLs>aa|G�<{����{Ù^c#���fw�ƙt��[ؾ�$oI�]�4/
-nE-m	�ۄ�+${g���}
-��y���W���z$ʏp�*���&)f�>T7��kZ5s����H�lQ�V��-���F$8\Q:�l�1��Lֶ�����^�,�}CWƸ}S�(�`uQ�m)ɶ��4���iE1Z�R�=ۑg;�M4��5P�#�y����yJޣ��ue�ۊ��hAL�#�U������}�rta~=�h̸\�<����:Vs�wַ�!�w ��mGdӶڞ��5�F�:_	�Ov)Eàh�/������TǴ�� � w�ϖmg�l��u^�v��坋�}�O/���O+�>N/���C���j�/�Tr}8��h��,��oTXK��Ŕ��F�P$
-�  (�&g] 
-�i��eđ>�բ޾�W�&�4ye_���P�5��UU�wW��Ҽ��������<�/<�r[�-9��#���:_�\�\
-�_K��r[[�v�mw?r�"-�s�<(��]�K�ւ���O#	��]y���38�mݙ�G��ZC��p��+�j�%�uy����`�76���%TW����x��yG��1���\�����E+WB-jK&�����'�m�m�<b!��Q��t��=�e����b���K�1E��ے�P��5�N���vy[�n;�D0��_�![�Klb�,	�'%O���eϯ�+�y�o]����\�e����s�����݁m�]���������F�T��ɶqU)�IUZ���ܽ�W�	%������{���2�o���7y��8���@ȱ��&����٥�V�#��?6����������nύͯ�L'��0��Z�`y�0V`��hCh��Z���*��$�܇"'z�c:�կ���ؚ6��6:��C���������BA�A����GX��)��٬x�վި�'J�`�g�����ua��'�]A�>\���0_$�d�m���W�u��u���''#��w����H��O�+��օ�֕�K��T���T�Zm���J���:Ҁ�7��,�L�)���F�.��p�)%��| ���m�Q�\o�+Q�-����+�=�����I�IX���3����+�9�7�r�-G.o�k�}�_;��"��et~z+�7S/U'�Ƿ�V^hA�9�ܥh�UjKϔ)�A�e����Bi�a�>��l�����m�ti�,B,B\�j+�W��y��R&�s�{
-�h���*�m�h[�8��6��Ӷ�9�,�
-[�Rf�����df�͔?�}�E��3�E!:BU���J��L1:����uSʦ����OL)�dJ��)��)����<`֞cT�Qqe��럙��_��ۿre˿qeL�)���);ǹ�US��e�n	��ȕF�+M}L7�);�3e|�)�9�+[��JK�)�0e�4S~�a��A��&T���4dUe�ŔrL�u�+�CL�v.W��ǔ=�+:�9��\i�W���)�qe��Q��C��Zȸ��E@���cQ�	�-i�0��G𿏀o����_�B��v4|����Y�@�9��q��8h��p�Oǃ�<�#�~K���t�O�8
-��ˁ�=	���m����ӧ"8�4�	�#ؿ.P�I�A����3����`l%|Y��3��W���2�Lx~?C:W]o�, k5�Оg3�I?`�EH��Fv.*���|;;��i��_�/��]DL��������߲ˀe�/�W ?ɮ~�]��]��_��]˶Vֱ��_¯^�o ~���h�����f��:��-�D�V4v��;���|=�ǰ;P���NFf�]���lv�l`����>�ߏ�����=�{�+�0����:�=ʶQN叁�%{�����IĞÞ���4j�1����=�GlH�1�yb���9�E�8��|{�W��*Ҿ�^C�������{����m$}�)�2�Km�L��X�޷�:q�Pv�#Y�ǈ>�}��k���+�gHs��/����}	��+���נ�Ǿ��q�-�[�����=��,g�ÿ���6���#S~���,�\șr=_�p����ΕK�R�/���?G p;�~��9���1��eȶ���8N�O�Z$�"�q;���O�[+ײ刿��ī�����w.;�[ة\��4������@ Y�W�38�J��ٙ���V�� ;�)��KV����|𡷁'G���>��A���zP�f�r���g�#�XD.D�{v*]�.��y	H��K�O���.�NcW����3(�Bv%�O��8����1����]���Z��u�����o�8��F�s�M(�
-v3���u�o�[����VЯc��r/���x���X�	�,��Kٻ���=�w�{��/B�AT�|v�=f��0��/��M�CHt{���#�b��kg���_��Kz���'��aO!�L�4���gd�r:$� ��9�?g���_�3�����%�c�������'�WA:��|7{�V��Z�&��-o�m^�\���9�+��w10K�FN��=��������j�!����?eۜ��nƣȽ�}��W�g�������b__ʿB����_Ŀ��|����;�����g���盀c?�Y'��P���gP>`U��A:�-RiR-^�*K�{]���������l�M��B�Ŀ"���&���#��N~��hl�o����~U��/Sȉ��x����s�8�<��C�������?QE�Oru9��'��_����Ɉa��o��SA}���3�t��h��P��+��y~&(/�U�� �*/�Ε�F��ؗ�j�����o�5T���xx-�}��"�G��w��H�1?�S~>b7�Εw����U���=PT��U�1F����$B�X�Z��_�2c[�{�/E��e*W���+�gX5�Xp�Q�%� o��*;�'�ڕ�r�z�2�j�c�k��W�E��u�*U��3���Po^���B�IvR֪�:��wV�S�[Ԑ1NA�oE]�ϱ�1^�T���PoG��#��ܨ�Aҡ�	���]�שwߠޣJa����@�F��2����/W�Z}����(��0� ^�>|��$����B��Oߢ>|��,�:u���W�C'vWP���>�?��@B��H��c��%�q��e�l�W$�_E1O��oP_G�'�7�F}�9�-��m��W�~A}i�R7?��ʳjK��'
-S�'�(��|Uݥ����j|@�Kʇ��������~B�~*���d�砿�>"��;��̇� ~�~���5(�� �~�'�w���_ �����p�#�W�o�FU>EE�F����[�QlB�M� �����wU~V�/�� ��-"'��2�a����_���ob�RzI;L���Á�z9A�H���Q��v4R]����2MU�ҎE�^�q�_�|�v�ډ���Teˑ�l�$�X����u�)��k�_������t��PW ���v�V"�eڙ�۫4)ug�t����l��5�ik�����j���gg8����)�]H�ԋ쨋u�v	Zw�v)�]f��rjS���Z�B��J]�
-i�׮�}�B��F�����(�Z�:*��I�v7"�R��܌�Gk��b��K�[e�n�p�vPn����v�W�S��L��J�w�t�v�͙KP�)�= ݬ�|>��1�ɡ�����%n��0��9ec��{w)
-?Q{�h����*�G�?���=f��q��'@:C{��+�1�R�)�c"ViOk�hU�kʯH�_��A��h�j�ʳ�m���s�����^ ~T{���^B<�P^<��ܭ���*�>�5����u�#���ko��8|o�}�۲�w����~X��������H�|�̘���r ?�x���f�)�i�cY�'��З5�x�ן�A�k������F�s௵/@�H�x��9�W�W�?k_/ҿ~K��|��=(�j? ��m��G�?�~� �Te��3�?�L���BzC��ϴE:V}�ї �-�^;i>���ڠ*�#��{��P�Vݺ��޶��<,�X����`2ìI 3m��Gg&!�t��N��2~83I^"˖�}�Wly�,/x��}Ww[���1�W�
-ƛ�9u�n	�L�?���U��SU�N��:���7�@�5L�`��ʗl0��eC���@�u������y6��C�r��B�0-�詌���h	QFh�7F{�%J�����6J�,:����$돕I�[-��	��m"���I2~2��(S f�����*�i3Q�шQ�1���g�zMy�%�ϕMZJ';���6m*��i�k��fB�����^m#�[�Y��>��]�y�i�R�ߩ� ��Zb6C�SJJ������>�l��m�l��h�"�1^%�7k�7��rT��1mJ��������hs�{�h si3�=����6O�ׂ�� �h�Pq�&���͇f��rVS��7~�\Դ:����%m��/��"�� V�+Yx��y��,�njt)D�ЖiR�\�)�49�]��%�� ����b��2��W�;H_�ܢ} n��ܾ��F}-r�����z�uOۀ��o����R��U�fp�[���r_�
-��6p���5o3�8]���N�.��.���[���{ �=��)�^H��i�~�s�n�^�;Io�}���d=@S�3�_�"����a�ґγu��:�K��=X�c�ӱ�f�i�;؏st��:��B{j����b��� ��ި_TY�+M�J�̀�
-�W�O�$�w�Z��!5����a9������G�{b6���^?�v�p7�'�ݦ�Ԥ�pJC�i��g e�~(Wv��Ğה���ҽ�)�5��\٣��B�}�g��ׁq���UL{�\�Rz�u@:�_�d�����Y���i��!K�~��@�:�ߒ _���6��w�=����~܏�Ӑ�4丯����o�^�+����ܓz%�'�� w|}u$W?�׫���K:24} �M�@pO� 傎����~J��#���g����u��a�և���;Ha�H���l��rK����>E{B�R? r�W���1��>�>|����i�^1��x3Ab:q�d�dĕO����_ɧ�[���@&L��*��s�;� ����gH�f"�)��u������(���g�Oe,'su��σ����煵ТY|��*sy��� �PWـ���y�};0���%�N�Ke��̆^`�������&�����vAk�O@L�k��-��'�u����m��QT��7�ߤK�k#DM����+ a"�w6������+[tP{y����V��M|;��� \�wB�z�b�����{���������%|?�w��n��n�\��O�O���g�����r��R(�*�x#���M�n���n���]�?w?�Z~���0�}��8=
-�c��?�a`�Vr�8�,��f~�F~���C�r��)��ip��8�ߒs�G���} ��.�����
-��i�)`|�������
-1��5��ɯ˘��o�p㟃{�����-8�Kp��ې��F�O���.�_������{����9��0��U�����]^	���PU��~�?ɫ�����{� �,�AB�?�� � ��A1�}��W�� ��T�'�AL_paI?2�Ä:���H"F�P�#(q�� j�Q�b���( )Ƃ;F�w��w����W&	�Co�����$;_�3�pg��P�1	ܹb2�Ԉ)�N�AL��
-��l-����w�����N�
-����>��u$-���C��E����$
-�Bx��E��a.^-j!f��1+E�s�QHX%@�n��`�,��6�>�p`_`g���k?6�0m��P��]�
-H�(V��C�w�Xm'���.�����Q=�t�X�W����O\ĥCl�H���Vl�so��b	4�
-�p�n�K��Y:��iџ�m<%���&�ʏd+��2��F��:,jA��H�%^G��?&vdXA�>X��.	��@T��?~�+�`v��8�NA��������!���#D���\���L�R3Z��!��q�OI7��DF"}�j����4K�C��Rn	\�5� �w�a�����qc$�"����3���7� G���1 M�����1��9ΟP��O�s�X��ʓ��' ~HM���j����O7p�/��_+�1Os�vl����΀�o縮v�S����x����\a�p���^��/�r����L���*;@��^�U*>���
-��7�u��0��u��q�f��u����T�&��f��ɜ|	�$e�s�^�`�QԮ���|��Q�|��5���z'6oB��1u����������>�p����X'�\������U�Ѓl	ޜ�;�e���#�oQ�~����B7�J�Q�wf�9(���l	�����Bl޸��&N�
-h��}��m�z�����z���H�?���l�	p�h48�7��.,��X�?�2x[[�������(;��*U/`()D@�hTA�T��6P�*�Uc����$	�T�N1A�"l���P�nU���6N�&z�:M�fI��5 �ڵsa�˒f��Z��R��Bg0�g�4O�T���9�h�A�+tJ�nsU�ZuY�jU٤�y��рZ9ս��GUu���Bte�P(<�SZB١*�Tm1��zG����0˪ݕ%�#����
-^F>���r|q�C?|��ҁn��t�����w�:��}@��B�5�������'�:��_����ـ�?X���6T�M���ٌ�:R�-�O�ي�=V�m�Ղl���s�k���I�|���X������*<*^P�;�Ң���1̍�-�Y��0pe�^H^�%�}�_�v �k�)3�$Úހ��$�ԩ$�ԫ$��,� ��8��8��NѨ�m}T�'n�o-׾��EZ��ݼY�Y�!�P����Kz�z�C����\s &���>�����ꁇ?��遂�Z%tZ���\�tY�]����*x���h�t�Et^�}m;4t�֗���"`��nꁎ˴�<����@�m �_���C~d��z���=|_�����6fڔ���<�~��qq8��	�v^'�^+�N���D��Rs� ��'�r��1KճH��֔k��;^��A=? �K������׽\ӳ�ź�Lg��i�\@$fQ/�"V�]��d��%��1q� ;ue���[Uߠ
-�wU�e��"뽛���3�}� W�����]El�2�k׀L��u��Fp7�LF#�M �p>&;�Vg�u�~�/ h!�g?W`>ĕ�\�����R(��I��#��
-�����2H(#�2Qx�y�<"H6� 4b�N`�\����,}� LHs`m\$`��0���z��W阝b����,-����t�� �X�ChUP�y��7�Y1���@#�ΉK 6:V�Ӡ:ʦ�:����0@���p�wY���i@i�j�!FA�M12e��+c�� �\TCID|!&@VI����!w��4H;e��d�Q�dC1Af�e?Z���!V���pc�hGu�Ԇ5P��l�1*y�[�LC1 n��@��m䋑�$I�L7��n��� a�5�e��;�l�A�
-!��M3��y�`�`
-����O�7LQ��<���������d�ʈ���vL��(�3Ed(�2�8E�X���(�_�uJj��(�vw)�wLɫP�"��戮�L�0X%�!���nL	LU�rg��$2%�J���`�J�·�*�"L��F��!���4�����G���;Ly�J�gJ��*)d�c�U҃)�o�d�<���;���L)���AƔ'�0ҕ)Oc�S�:�H_�(��G���X�Ә�u�F^fJ�4��@���g5�S����=@�s�ѡ�y�)߾��0���5�>�v�R#���c�N����:��jt��/.��(���$������]��˔�v�x��{�̞���������� �g��;:�3���-A�݆p�"S�t�9�' n�����s2���ķ���kb�O@l�.S~z��C0|�����%�'L���?dJ),�?bʟ�2�'L�sX��)��c�m�L��Lp"a�������䏙�_
-�'S^;Q����9��U���U9߿d�3P�����f�A>���d�|��T���ol�ANB��m���w�d|J5zD���%�lO�띤���z�$i��#N�1L�&� i)|�&;���#'�ܴ鐦&Q�v��g7m&���S���s=b���p����N����i;ǋ�L�㱋<z�t-=FH�EY~����RC�"��@��:ë�BO�T�ԔNT�ASQRo�_&��AYI'N�Td��H���)z�,���E�W��k�,@��$����R�N��Ss�SZz�Y&q��8u���A/{6���\?�\b����kI1�oL7;� =��[S�����o��0�tG�O�;�[$�y�D댷��$\g��wh��m�,g��WH���� �Q��b �o%�q��h1D��m^`�p1����eA�(��R�����#��WJ�r�[���!���S�[Zja	��qd"Yh,2��^��P�be����RCa�e��uW��ܨ���~�mm��4(�}��8H��*SI�U���� #1`WB��\�z�W� ��
-(�PV���JM�"
-,s���$O��Zߵ$������BcG	��e�(i��b�����X���j�l����Fb�Q�ް��:��`)��%W���ة���89�B0���I��4��d�d���Pv�Go��M��j��F�Bo��O�UwC�?���ǌ�"ҫ�@��\�l����T�n2"���m�6E��:��(хFh�5�:��t�ATk���m1[���  %�V~b�a-!������JL߫0j��k��^;�����;��NC�?��C�siћ�s)IΡ�{,�˰.S,��݆�V��P��އP�����Ga��d�!AX&�S���ӊ�����E�T�J����ϒ��2	��ސ���� �#�0\I�+�����%|:1�:���@��O��D�����Z}�t��'�pz�:L X���*�`B���JSɫH=|����@̧�>��Ub��"@�(��#��Y�F�)�����[z��ɣ@��^E�18H�+�s�v:�WSl;Է��F�x��il(���7� �IcaU|����` `4���$GP�sdF�X���Te��/�	%����UM�'�JCz�F��N���k�;/�m�'��<���
-���5�6f�טKИKؘD Fz}�T��
-�<�AX�h	�c�\: :f�����*�c���H��3b����(�3�Q�FFQ��	����j=^S�̱2����A{���>��F���H��wj���,�M	U���;@��v�g��?�>��Fb5�tM��0A��=�Y�4�+���<�4@����e?���U���"a��&4cBec��o �ӵ�1Q�T��c��׶�CNQS�&|�$L{�������9Cb2���oHTS �bjNL����$�c�4��!�g`�>M `�KJ<&��S�-��ikm��29�g�6?c�l��u���%vU�%��_"���H�'!C��٣�H�Q`��5!���ֿ.���ֻ$��#���k�]�P�l�G/`pN�+.���[O����˹2O�Y W4�@�y�W�4İ6[�4�aӀI��������˚/�!�y�+|�UI�:���?��wc�㾴����9��s��:����󹲠m���3�B�����y��(�ԩ(�V��sE�Jq��M\C��mbuN�u�е�:�;�.�L
-4vjA{���WT�C����!����;�~QA�C�UM�?�?(�UL|ץ��e�{��:���졊�I����X9e�㉔�۠��6�L�p~�`�p�Q��,5�66Z'��:�H�f[�'�Ź�ů-,P�:��~��u���݆��о�N�I���y�Bx�Y�a�T�r(W�ѾjCi_�$+1� K���>��o�`3�54��*������:E�Zk��\�IW�7:�ZO&Ί6)è�����^�sIR�m�ېq^ �b�R6�n��Y�kh��*�l��аħ�-ox�P���a����:�ȓa �([Y����oW�A��;m��l�j�ӆ�����rjO�k)��4�x;@���*�x���
-x�@�O��va��A�~X9�5S>ɾNU���)��D�gO�2�D��&G/sG/��W��������Ĉ��ʈ������*D���L�rt��0�����a��=�ސ�ce,� o3\ �J�	Rk���q��j�J�#[�<&G���}���#�l=��q����.3V���^$��ek$�32����ܑY\8�䌧Ȭ>,ƼY�/��6�)&G?6db�c�T{��w0 ��G!���*�r?��	J�Ǡ�ۖݓ��hR-�~ =K/R�i����nܝ����O�B@t�֔XD76�3e��P��)PƄ�S\b��o}O۠�
-rp�!0h��M�8�K��ZC*�ӫ��I	��������/'j<[����G�Tx��'jk$s�֣f��	���T�a�6�؟n"�"��2f��ɓ1S(q��U���1V��ՙ��Մr���R�+�
-+�r�u�BoᵗT��U�!ΰ�
-��*X��m� ��H*���
-�|4ˤ�z����,�2������5�y��BS�4)�X���-��C
-�/�Ք��i'�&���tV��'"�qq`VF[���(�FA���3����82�#V$�6�(�㒖�������U�����
-�P˯jJt���O�*�:���0H�r�9����q�aa��4hUS�8����+�m�iΠv�ytj�
-�:��#y~�7_G�����+���FaEqy���/�x��Ȭ��`ei�I3��%[Hl��/a�-WHL�ꉓ&H�5��!Rz�(�fb5��'�[ϗ�!�:o�S�=dF�̥�6�↷�᦮�n��%�tJn\o�(NjV� h=ˀ�ŤɭZ*��Ȗ�Zڱ��{K���4<r��aj/���AF</G=�F������������EC(:[E�N��=ڄ6�8��g��|��C��,@X#�rJ��8�W�2����:�w���Z���v�����L�Z��oq��k�@�LC+HH9	�	�& 63D�}��ޭܔ��O3��)X�����i��aN�&���C�N��W�6���Y�O`�2�:@�}��� 7�����X�$,a�zya!P�]d����r
-�!�V7Zw���>,4h���DE>c( �z��e�,�e�<t����@T��NP,� �=iʱ��!��?�����0��,����˂�צ�0�LWIb�
-�W���8�ZZb�$��%)�e8'FI�!eC5�����ڌ0�.aC%*�j��ʐ���Uh)Yw@֝ª�ZU��QS֏e�u֐�8�1�Zv֐U���#�4�f,�rEt,�2VɳZ��QN�(�����Ձm��-���RwT�2��t�f�e9g(�?/m�e����͗��3�\0��&�%C�M8��s�!i�\Ҿ�*pn�
-�e��E&?
-��l���*ސz�z���S���v�\�;傤_��;f�W�6��F��QP�I��A�K��Srm��Q���u6������Y��z�W��]91S�*�;G�p��=9@�%�ޜ�岠}Җ�p�hX�h��A0%��]?�U>%h�ڟu�xPG�uLZ�(�=������ �,6){�I�cm&�(�I�ݤ�I����#���%�4���Qu���8�Ƃ�Q�dm%�RG��!�ڭF�/��  A'���B>�^�QW���S{)w��� h8���_���A�/����e)�FZ�����^�lc/���8�h���r��S84��Ʊ`#��"䕴YC�i��--�6(ui������ٷh��0��}P��d���ɺO�D�OR8W�X�Z�h
-u\��̉4���P*|�� �����T�Ϣ~��(5��FVjJ���	��E�t�F�B��ǅ���o�SPfw��.��Q�_4'n�Q����f��7Ʉ��=b�[󶈗�B�}+LM�k��@�۠�m� �Xdׯd](�.l��S9%5K�;�Ț{5��1���ݱ�ג�k��~���P'*|��‣��d65g���w�����ѡ�ױ�:5V6{��8��M�B�0�Y�Yi����t�I&rŀ�kՒ�9P���C����\f/V9���
-�$�>��j1���]yX�2��v����2�'@��0����s����È��ߐ���������Z�=Wڔ8")��Y
-� �w^��R����F
-�]m���� ��>���
-�j�2���u��!�t��r��H�D������e]5$��0TA@&�2��ܐ���V���~���a�tJ�@7�����f��4�=�	�c�w7���eH$�K9�X��=bd�O@��D������'r$�=%�H2|"п��HͶ�#l�Z�m�i�Px'����eF��+���2{��+�7�S����;��������,��Q>)���\,z;��;hoH9%�����2)�~u�~����-��/�r2�J�����	Ҝn��G>����|�`�Stb��.�o�:k`�۸u�K�����]���8o�6d�9�ȓڧ�]:q=1L�s�7%WC�t"W�=�@��wŪ��8�As���(�k |�Eŋ�gTWv<.�o��m�r@��˺K�]b�Zl�<�y�jV���E�éi�F��M��k�Ѣ��h�+��{�`T��6�D�a�Xi�ih|�T�ҐW�t��1������=��F*M&a��ʃ�z�No&��E�g*4O�2��9g>��{l���ZS�j���Ý�Oq���懮�]K��0Hr�~��A�:��f�Nպ������f9�N��	��	J9O�����]I�'@Z�7��e���9k	�ܻX]�yib#��j�@Y�㑆2 6p+���6���a�)��۶�YôDZX�I����労CzJX�Z�3��N�p膑@���5�f�;�Ր���dW
-�K/�%q�[��l������s�K�U�\%��,
-g;,�:Zj�0�H�w${�!v�Oh��H�W�x�D`*je �D�2��*祔��-x���ze@�a5�}�J2~�]v�4\�/xE|�mHyUz��uNGt�)z�,:��FVK!�,�("�^��id���$���DnW<ҔkIA,m�nF7��d3�m&ѵj�ZUIn��:@�Fh446@r�"ՒY42��Y��_���e��`|���3G�4,E�
-5Z�
-�
-y6�/�ܕ*N��kM8����'��c��m����;m�:	��&�wZ�&T�vB�MB��зU�31��7~
-4�������*�<�nP.���1a��0$7�9��P�&+Tw�jJ�WsƱNeC�+ ,HC��^<������}c� X�r���9�,w��}--�M4��*��0rTL�?��D��@D��4���<,_){}��{�=�Ԝ
-�[R�<c�}i��iX�H�,9/�~&-�B&*�ly#d!�	�u��d�z�q�uND��-��d��l?�6�����7�0�:{'�r�/��C#�M�u���f��# �4Vt(g���+H� �����3iV�S��^D�C��ZE@�;�T#�A0�aE�� ;'�;��0���Q�P��nP��3�u��tA�3k������[[׼%m���2�)o[H���km3�6�X5�Ht��
-�X1�4[�&} �����"�i�S`"��!aRk���<}�Z�앷F8��l���`���۲��I�C,H�B"��#��q�Hh[1fX��5�td7hѳ�=��a'ZO�@=�(/l$���k�z�ki�kk��Q�כ�ݠ��VTv�$�i(.�T��FU陶��h��ɏ�����/�iIK&�R�/�_s�gp����h�;�-]�M,o�"�<]	�\�M���1����𴥟� �@�<�X%����mj���,��YG�C�r@��K�{a>�h��cWN?֮ʺ��i:���|���ө���:�3�,�!&��WP��F�AL��a�q�K����wd�d3�`��l�:��5�M]=4ެ=��~�k�B᥷*��Y�qX.�niݲ`�f�c_�-%�)�&�+�S�Mb�B���������YM�@�h�{�����B`;[z�]�i��㤜�>�CLO�Bɟ㩝�H2Vn�Rk�n���L� �YGe�����$S�:*�M��S����Qy�TxGe������v0}h��eo�ۻh����#���r���(�!D���<�h;L���a�@S�i��o��"(W�8,?��R�ԓ�l�!7��I�³�$4���~N#��8��C�OS�ڞe�F&�*���g��	�+�1Ѵo�ްR���X���ĳ���" 2��
-뜴19��Zg�Fl���^�(x�/��ӄ���~ T�'��8�F����D�RXM INc��bc9��Kh�d8�]��J��K"wT�R��&���}��*�խ�3�$p�mN[{w+�>k7O���24����U,v,.un��y�b@��:ۅ/p
-�����`<Ì����&,P0�0���+���̷!���Y�E��/ZZ�f�X�lj�8�b��f���f=�g:�|��ޝQ��̳�[r�EQn��!���}!�4�i�=������6�uO�̰N���K��#rD�[�N�S��t녺s�Bݔn��S���LK��6��&Xl�)�K�@���M�i���0_܌#䜧p�5d��PW���قNa*�'Ҳ��O�#�ѠA�J�j��nD�A���۱��h�"����_P�Ƥ%b�D���e�0� �le�j�煴�ɘ٦;��R'�w�f�[��sQ��钥q��� !�{�j ��%��9&��O����~P����e��0��vr2���N�1��5��eG����B����e�(.�,���)�5"�.0�!l��rQ	�l�	��N?�!D�Ґ_؜��4e]ZAE��g$/"�g�imE�H��a6�A�����@�D��&2�>�$�;$Y�:i���-w(���8���:+:5����phtMw��4�	mѲ书�a�h�tL���J>X�/�f�l�XJ�,������z�Ȟ��=�9U�uC�>�%\���C��q��6�ϕ������6��j�;�۶Bǎה����)�/]6��4��vIIJ�n��!�^���u���68�MF�Y0�Z��[j��ȗ��K�Ei!�Sۡ9����e<<��A}��B�
-��^P�( ���nhU�\�LZJ��g�9H�a��p"7�3]�� v�Z���:���ր�%��a��D�=U�w� �Έ]l���N����,w_	g�۝0܉$.�S@]��Kv�<;M�]�[Q�NX���^U���=*����'��h�VRj�;h���뙕� �/��G�����$�-|�P{f�Ƙ�-����3\�Q�0}�%�e���`�xP�y�p8�T�dx��U�������/\�ۼ�		��]����}�b;��ڮ��M��p?.�µ&�`t��ufx>����=��ҷ� �9��W�ZPc��d�4�f���DH���c��([hB�(n��5�=��z�{P�>y8[>� l+�g�+UyL��Z\�á����'kx��5�Bg��2�}.v��װ�v���\�qM9�8��
-%>�<)�J�riav)l]:Hr����E�)��w��Xd��b3�7�j�}�҅L���S�J�c�5j�a������5d�N(1=�<�/Y Q�i�8u��n]��Su�k�7*��C�5<&XX�z�i���7�TyH2���uܛ��MJOd�O�:���yx)`(Ĺ{Nȍ�8���,��a�ʀ"!�3����fM�����A:�`����s(=H��iB^8,]h(x�j�$���1	1��!!f!~� B�B�B<����C�arj~!g�̲�W�#�n�L���/I��Ié�3}Ǩ-�I"�HD�DHD�M3[ � �1Jj�4�do��M����$�-�MJ���璔x�4��<�g���h&Cy� ���F����u:�Lu0��ć�WR_ ��C}��J��F��w{��<���ǥ"jwC�&aJ�L�~x	m�q�J�E8��Д�lLy�ŭ���+`{�h
-��u�?:���=��Sl�e�'�*�x١�C�Mx�"eo�B|x�aڜk��c@�&��^�� (B�V�Q+�(��1&�K^�1е �C�%�p\��%q��Y呫�\��̕k�h�2���]� �'a������a�2�>���h� �U�����$��I	�Q{��}�x��(�G�fôfo�=��㯑%&�sY��0TЪ:L�w&K�i�dR�y ���2���&����4��Wh���U�R��݃j���Z��vP�8�A-uƮM��|� �8>d�J���+�h�tӂ6�s�B&zv�����(�VN�\�7��ek1��Ʌy�u�����0�m01�4��Yo����?s��b�Q�u���A;�)'
-�e��7��8Q���1��1��S?ʜ3��|���̤������1�Zhf�7x�+Jh�"�AZ섨�_!��R��@h�bx (��	ihV���q��fQ;��߅�@b���qB�Z�b��ɏ>��u�	��/ZZ|��oI�o���-C�L��������[R�[��o�~�Eoi���Ϫ)�U���Z��G�>����^/uw6�8����	T}s�-7�~��]�<e�1�P�"m^��ͺI�ZZ�� ��K`:��<	�*^YE�Y�e7)�{.d7�pGCqq�?`D0YI*�$��6:\�w7�H�n�^vnr�[I�+�{Ʋ3ni���-�|0"���O�\�s�$��\u��c=���L{KC�{�6�&��w a�IS��'`>p��p8�؁�ɭ��]ª��O�05���:�0�]X�^ks[rk���58�T���4@ /`S�u��;�p��s�P�K��\"���>���D��!�ؙ����m|}n��s_��������6�^6~�l|�W��m<����I���ʣ�a�y$�(����e���6	�#ڪ����l �k��#7�����~Lo?��\L�s1��Ŵ>���)6�����4�*�����тTb��0�:G��V����R�-pNr�P��2i��w PN&�K�[��t�G�Q����}꫁�!��]XBt_<���P�\�*�(jN��.o�x"���5�g�;������k����JE�J��"�!*ͤґ��>�x�1�)��Rz�(�O1.���+���Ye�T�z��W��(�����t*�N�%G�bIx�2z���2�⹷eĹ�>�:V�������_)%�Aޗ�_m�����si�SP_(��{Lm��=�f_^{ ��vJ�I!NJq��MO������:�L��2Sv�T�=���>ǧ�,~@�k�#�&��~��۱�i4��nsvr)f��7)��H>ГM�}^��i����kة�@2Tn%�+LEU�� f����̒=�H�M�Ž�b�M��~��)6�M�I%�X����a���B�<�m�r��ٚ��E\�{�4d���M�n��Z�/�/3i�O�����`�b����]}���崵B-!�f�9��X��6�W�
-[ĕզ���ΘMu��xboF��.��
- �GkM�,mn��DhS�[3�"%��c���+��B1��f�6�5�2�M��"�J�XSv�·�����9�8&ղPd�^f�IH�V^\s��xg�aZ�
-ӂ-eP:Za�@>�@>jj�K��Oe���ӊ��]��8�.��}e-(-��Z�30 z]�j��6ӡ�0��fn�M��|-�&���hi�e��=pP�:�� 2������_�L�4x� q���u84��i��J��K�� �0�Oq����덩"���y����W�����B)μ�^MΡ�T�#--�"���r7%mo�����b���:,V��#�I�.K�:v_�L ��.���J�k*�v����G�!W�[H�^rIC��A�5y��W�+��tv��[n�k��>iM�3�hA�e��--��rC��(3L�Y�����9�>��R��WL�`jl%�kɕ�%}�r�9��Ӱu��
-��{8� �{wC�{ҳ`��-��\�������k����W$Z��M�F�����{��a�i����
-��S���M�;ox�#X�s��!���Tsi^�Cb�f
-�蜈���<�f�Jˁ�}�]��X�c�F�t2��}q��㾜<�M<�H�oi���x�6�Oޡ{��{�\��q�ı���i��A��Y�}�@O�3 ͩ94��)\z�Y~��sy�s��K�xg8x-�x����{h��`8�HZ� ��q���'�B]�`�����$sd�AVױ��En6,@��Rʸ����}�&�x��(-�X^��ؤ��$o��e�]#��Ba�vg�<TFk��:����l��9�
-)i�Y�%���|�)5�'�V�!s��m&k�6 *�V����$�6��m0�M(紌܉.Z�ָ8�m����;D������O\.��\��l�q?��>��I�)�o���ҩ�AK.Vi��外=�Q/��ڤ�t6f�����MP~Z��
-@V���̮&�jc7�d�q����jV�I�&Ph��z�U�h�d��\@�� �e�L�3�~3!x0{���oz��w<��%Z{i�L⒚I|��F��"SoeS[�����z�#�@ʨs�Ӧ�WR�����'�+]>5�aI�5
-�C���|Z���yW�m���,�<<_���l��'�Г�(�
-J	1��h�iX�XK�a���U��2{X5���:��%_�<+)�޲�������У�gx.j5U5_�� �s�͔��HIl�݊j6�q�!�b�J>�Z+sQf��z�{� ��1�9�&;�ބöI#e��×C��V-L)�ufh��`�6��#4�x�����Mfh����������Z�auOl5CSIh��n�v@.�
-5C;��.3���1C{��>3��0Cf(e��f(c���F3�d����!3��:l�������Q3t�}l����O��	3t��2_�CB���L|T{�|���[��u�K�������Q�)���}Kw�V�O��;���>/u�Y��H��(�����Rǩ�o�QX�A/�)/y;d6�c1���|�K�ɾ�tL�q��\r ��J7yh2O��<4�'o��œWx�:����<v�����U��C�x�>�{tB�=
-VA�҉�f:��v������)�4���
-����g�Z���M/ 4�X0���>ӪUA�L���ˁ���hT�G� Mev[n�@�4����Tr!�|G��;8R��&҅j*�PR�.�����l�F^�df��o��v9��#@ a3��c�����/��hW����-N�]I���VZB]�J�j
-��
-�KHޓ]�2��`5o�V�.RR�;'!R}T�I4��������F���-b�y�6K��
-Zȓ"6T����P%B�xr���<9X����,���c�Eh%O�����$B��� !B�xr����9<y��ƉP#O��*�L�U"6\�v��p��%<Y)b�DhO�!"��'��X_ZƓ}E����{<�G��d(Bkyr����z��'b�"tTMV��m����yl�exr����<9@�F���)bcD(œcPf�T��py�Ψ��������vi?�e�T��: ku��"*r@A.�ǋה���
-\ǀ٭�"�H�r
-�L��������'ee�?��Ք�ǂϛ����~*8ݭ94�D�eE ���V,2�c���"������!�;s�R�y�f�@��L~�M��M��Mcd"��=���cW������Uٞv8�F��0�_XU����DJŨG���u�L4��i��پ@>��=��L4�g���a���m�fخ��������Q�j���-���� `�l��P���e��M����UR�<����E٘�k�U�zq9/.�n��>r^�F*��j�*�M�L��A�y��@L�����k����0�o�=��v�@q�Ҏ��:k�kW�7> ꂌ�ZλBԓ2��P�͋�y�uK�L��(������$HG���v�@eK�h'|/�F�u��	�:?A����9��2Moij��S�,�d�M�'����%UҪ=QU5���s�H��R�lM��p%� ����"��Yهf���|�I*5���RԐ��הV��Ǩ���C�Y�Y0g�@�vHgP��#����.C���q���X��-$���$���U����$������Y�q���SE:<UHk>�~�~�m]STU0�%�6�@vg��L�;�"�z��̖.A�-S	�i[9�G1K��P���.t��{��D1՛(;E�sr9N��h�ϝ
-jDaY�5*���
-�t�ӽ`g��b�W�������X�,Y�wr��+��I�sEl�(z39K�f�"%9S�f�����"6GMI�A$f��f�W�GN5��k����"�6K�<UU�!g��gJl�&�~"Hr������C��z\��;P�qVh�|�^�����q󍎎�V����h�az-Z��ac���>\a�(��7�ٮ�4�/xI���$X1����x9�ۉc��E^���)Ii:�k��v�B���5�L�eW��$_3������җ�|���<b�>�>���hKK��[h;�P~��-�q,g���,h�N������������j�Wz t��jC�l�ۦ�#��|gu�j�?y�A����j*�&,K{��+Jr/(`����/���y�N�Q�ã�)_��s��Y��je��W/�R~y�M�e7���*�i(�B�����tV��`دZ�F�q3��i{�'zq=ѓn���+&2E����j��vd�E*�j�w���u��h慎nd�7=�}os� 7`��0R�|����טJ�2{5�[x�fh��������,���S��~|�i�N���^M�lx���CP�--��,��e^��K���WX�m���c_�&UZ'Rja$%Xc4��`X�,����**^n��h���L��H*^솇�O�e���-�lL�鲙x��n@�,_�������Vs Ka�6���*�zUd�a�
-������J��,1K���m��2�U^�,Rd������,z�L%Θ��&)�Ѫ��U�!��m��z5�^U�iĳf��t�	=���\�E���9�s`mǻ)1l��}�.J;�<��:��J(����V���̾<�!���W%vľ/����x���pSq��/�'�\��sͪ^%�U�v������ t��7񍎜��pgC�p�*_ ܠ:�	�!p#7p3'��*�6�����ܐ�VH��Gw6���*��+%��Q�ۘU�
-r�kV�o9+�!_�	�UW�� J�C�4��&��宭���&kEl�(b�y"6_��|\J7�^J�xK�Eg)}�s�K�*Kśru�u��3ok�y�������3��0�����h�;h�P�P�WW�<h[ՌU8"t���zZ�Sh�����L��݉��Ҭ��Y�],2��bA�����ˣ��YU��j{_٩�S��O����U���dk|�+�렰&���l�f=/do�FK�����\��(�uE9 �������ڹ�5ɇU�$� ��^�S_S��T����4Re�/z��ˮ��!���X�\��$�xF�5l�
-*�i��c�+e� �5$>C������Fh	Ӑ�Ϩ������
-��{f�<ʑ	�7�'���[#��s�Qk����0ᐪi�n4>^z�$�w��e��Yst���n��	Rvݴ��N�/�:F$�$|iMR��5�p��+��_-��W�j�s����ir� �7�1ҩs�y|�L-Mr��F*�El����"�L����2�@�n��"�I����&�*BcEr��m��"�AĖ���\*b�D�>O��u"�_$׉�z(��E�^�>��z�.BDr����~"�VĶ��h��"b�E�B$W���$�;Dl����"�R����J[#B�"�FĖ���\.b�D�Z$��<qTՁJ�{���f:�9�}���K�hs�M�k� �f[?Vu���W�<K�������g�����<sf!>����x.qw��T��%b;Eh�H�DDO�B����w ���w���_�U�҉>�W8���2��g��⟩�+ P&���� %���� P&/��� P&/c#N��G�E)���U��W0x�^��9U@��%�g�uM�.�֧ji��<�A{�*}
-��r����Ꚁo{�G%+|���>i�J�a/�wU���. ((�F�M�:=��+�e��̲yu�{�3���r�:H!���S����s w���TE~��w���/��R�}� ��K�6����kY�t�Kw ��]�l |Seg@J�f�V�O��H[-j�1���ݤvj��
-��&�yIEJ2L��Zj��"TZ���>�v�4�� ��hW�T�:�r��.�� U0�v�ԇ�0J��?��G�l�J����Y)�\�bI��b;�5�%w�X�ưd��b�,9��l_�h��{h��ǐ�?��j�ޒ�-U�,2��W �1Ť䯠E���t���c��{m����gb�1�L,>�����_V�MXY�a����@� �b��!{Kb)B� �"�Pb.@�E�a%����� 
-���j�a���l�n�@��Z��
-��\�8' �����rks~Wm��O�g��O��?�3҃��<� 1 !F3 P�y��}�3OO"E���tH�wR�1E/RJ_�yk�L�4�����a6L�U9
-K���U��*�{b��x7�^&��; �Xt�L�/Odm���zА�$ۂ�T`(z��_��UL�t�) 4�W�����aJN9o��'�r��0_����X�]l!`�0�i�*�� W������X�E���C|J|3���YKXd&Î���j��4N)k�;��C}$�f�	����l���LƠ�aN{��Z���V�x�#ڏY�����a\Z�ٌ�7g���Ȼ�xĶ-@ћ 2a�[����\�w�L����AÜgc�n^%eY�[q�	HD���,�Oh��3La��u�7^���3|�d�u�#�^�b��.�2�bL[U��7�_��/G6ZYw��^l�Ȭ��L��&�V3y~1:�4�u,j��Jr�Mq��H�j����"}�o?�]�EF�0��#����Z�k��2bw��9���a��<��>=���V�1�QD�ۥ8�Op��������`�_W8�A��	
-�_��R1j@�li�l�31����W���%Ld�O��m�/1���G���봈tGy���N�Zd,�}�V�U����!lN��W�6��m|����)	���䪟��!�^�b��/D��Q6~�J��gL�<g
-��q>��@<@��!9*6̩b�b`n�ds�&�v�߮b�]D�t�f��<�t��T���\r��E�*[��Z�
-Ѳ�x�J�os@�r^6_�s��W���I_� �=�@d����ȷ;u�#�>�u.���V�#�}�AP��R� O��9��v�yt�g�}0X%�6����ow�v�ש��)�̲1p�,,5�ݻH :��r���l���Q���n����r�/�5x�?.�<�l���<ӝw���f�4&���0�d�5mr�"�:Bx�"5�"○4����1��^�� et7��T��1�s߄���� ��@����j[��{�6e�@���Q���0֡OZEI`�Q����[�����2��_!��$
-�31���_HQ9���� ?�NP�ON��<�{!]@
-[ĢS�$���v�?���9��\���߆֜B�j��^�<������{�`_�������	J�E#�9��ED���=��K`)ɠ���=)E��A�ͺ&g��`���>O�ڇ���r���gޯo�n��e#&ȈRT�))-`Oא��P}Ą��,D�Zl���$'�b��;�珀P�WTؠOW���M��,2��eC̴�f�B�n#���Ja9܃ǝ4�gx�����nhX{6�8z�����EE��"yz]��ŧ�3��>����x�e���強��&�q�o�8�����7�n����D61�o�H�yNVfc˂�\�)��|zD���[.c��N�-(��kRe=�8wXJq��\�^�U�m�~�َ�F�NTt��t2�瓝k.����Zڝ���1,���c�+�1���ڛ�IU$��U�u�:��w6mE-���8sg�{�Ֆ��p�׵Wqj��UU��������θ��� 
-�"���۸CUI�������ʋ�̳uμ��|t�<���[ddddD��ߩ��Wx�!'�&�<TnV���Ut]�S=����G ܛ�B@	��ʸ�4.)�����p��W�K)��ȋ�.�7_����*�1�ב��`2K��?r�R��^� ���HJ	(fe�r1!Ł`r|�
-u|�J	i劕$�ÒE�w��	ي�	=]"	�S~��%���:��W���'��Yl�
-��J��~�ƛoQ�sg��h���aO�y��^�C�.w��(�f4�:�+�9+�W��ح ��m@Ǵ-�'@Ї�����P�}�����?�?��o���3�>�3t\�[��m�f�}~r�#|�a� 
-}�Z��"��+վbf��񸅚�	�[���M9����-����ze[s�m����=�^�_o��!��:Ʈ���PaIrU�mն�������K��J��G:|���8�q1�	��JT�!	�:��m�����ק-��G�oE��'���R�8�ٞ�ë�����Q׭���v�nd-�`-� �����R����)�
-d������в0�܋��YU{	�F�@'t�ع�t��jK+���}>�Qfgl}4��xXN,���E>H,UUm*�	�z3���q�����r���~<��ynS+�X��'V'��>��b?���+�=
-;�*�Kr���Z��$�k��̻r��5�Ve���v�}�L7,[���d`m�����z����0�J��Jߊ�o��
-�* �VV0U�z/+T뽨P���BU��שT��?�w��m�gk�UvnpD��
-N�'��>��y��7a��#�1x�෭`w�BGg$LM��[��Q��7%6p�G5��Ν*�r�%^-%�^���_�:�+��a��{�(�ی'�� �ڎD���e���lT���B)��6��:aƑ����G��E��be�����"�O�s�@)�"���
-�)�����J��m�D�F�Q~�TϾ"�w��+r�,�d�,GJ��N6Jr�(�ke�(G���j�؆
-�+�!��	x
-q�����裃t°��	�K�H��j����mR�È1Є� �k�
-�~�������:��p�-@�"�
-%�Z!r�P6�"�W2."WPɫ{�O��ʝ�"˄�)�'��MB�f��[�k��a�'6~�@6B�%,wD�Hp�#�N5s�j�H$�< [\�)� ��\/���X����@ƕB�
-�!�
-!�T]��'hV�R�����1�UB�Zr-~�@�
-xҷ
-��:�aa\'�LPV��J��B�f5v�кY��?6d���]#���0\\#xkZ��������.�#9.a&���������.̩u7�Zc���x�B%�I@CZ���b�V���]l}�f��񕧛�X.��^Ҹ&�	�Ob���|��x�}����#�;2�\F^��~�> IƩ���_�!���%
-��!g�*B�-�i���\����UN���V�Kt��YZ�z���j�.b�:���|�S>��k~C�}�:$�ŕ`��o��V㱭��H��e<Geltbl}F$�GW)�P)�\q�Sܝ���R޻\p/�f� ����Jp����&�{]p/�}��S��w>E���Q܃�BJT�C.��	�aA��5�����Q%����"����:���^N��4+�:���Aa����ڑ�;rp�ۄ��1��mlm�U@�1�'�f��g�6!sT�I@�j�, �ċ��,[Ȟ��d��<BSU-@�����+�U��c ��of:w~�x���v/�f���9Q�؁�S!
-E����(�Z[W���Ɍ��M�V���U5���g�	=K�RFPU��n~>���89�a`�K9~u�Oh;
-�p�����N_9�f��os��#��ǲ,{YP�	�	ś��	���%�Z���@�5p���-����A�ux���k�6'�!��������7�	n�R����ۆ�A��"�Cm���@�ɻ/[�/
-���>�g}���|����"Vb��4�K�Z\�W���$�W�*/9(��
-�5B�~�1��~M@Ö��|,���<����d�1�������+�~������}���u��~a*�3`�)��J}�����A�[B%�".A��������B�׃�k�W��튅q#s�(Yu�Pw2��\Q�!�^U��7�	���>�lBV /d�ydh��f�_8ڍ��l�*���-���G�Q�Av�NGc�#%{H�o'�_8��X��@�Rُ�e�Ke�'�#0?��#�6�^��u��*E��d;> ����^�7LKH�e��'8��E��#�'�JޖÞ��(��'��_7�Q�=ڶN)6�S�KХ��R��tKC9��k^�bZt]�����<��O��W�C%}���_j{[ƻK��q�Aeʢ,��r���g[�ĩ�[��}���C�],s�XF����:�֘���<v}W�b����\&����4�A3�m����Ӽ��$Vb��v���}���F��)�ۧoR����+i|�ס��ॽ�E�ä�%K��@U�:����I�}4Cu�ӽG��֋H	O�o�����{��z��WL>G*���k���?��^o2nG���0ķ�]Y�_6ޕ#�e�a��-G���㲱G��/�O���rd��?(���{���l����L\2 �&[/��̋����[�o����ǂ_�#�����[���~%c��A�
-"�[io�6��Bl���+��T0��J�Fo<0�#�]�i����U������Ғ�`z�}�<�> O�dx���$�p��U����f�O�U�t<j���-N��n��G�H��ۄ���^�G��I�P�΁H���I蔅�Y���ߣ6O�r8��0���2�>Wet�*�Xv�ȹ���
-��f�56���H�N
-�7����l�>�zx�@
-
-X� �;�v��&�n���ϗ�f?����h�Q% �
-�kE��m RO2���Xa�qd��6�?�!��i��2J�K	�q^��b��,�p�	t��V���l� q�R�Uw��f�~����Zn�EW�x n1�KE�1�+���B|鏯�Ǡ��.�=��F��#X��a��e^UA�½"��KV�����e�@�=�>�=ӖS�Sx]_�nB�u��۸j����.b��a��O4G�5>��l2�þ[Qi V�.���""���֖�,���U������{=��R�v�m"��#X�S*M�����J���������R�CX��R��v�:��Hwcd"��J"��J�[�����G��&cm�Es��e͢0�~e�qL6���ur�d}���H�|,�����r�CY_�5>D�}��Z*��}����&c;"��*�A�ܷ��2�1�!��&g���n�9�?+�bi�~� ��޳y�{ț���Fv��#��x�-��媃GD�A�z�G,�?b�@�u��Ex��d3;����z\��9�G-(��Hr��F��wvs<�wԶ�g1R�|�C��!�f�Y��ݶX�b?��HµAn{�Go��fخ�v	�L3���ߤ�����˥�����-`9�ڃ��=<����U+ξfH �?1A�^X����lة�s�<��]�������� ��A0�1��T�E7�>F���Ǿp}��qܭk8
-ʶ����)xO-��)���F��ؖP�уVV���~�vkq?����k��5vvi�!��u�H'�:��c[��T�b�A�G�;U�\�������M{�p���ʹ�c�	��;�cy1�Q*��T8!b5F�k�v'����J�"tp~�98�Z�A�����ǭo�BwEOC��)vY-�iѦRL��v��3�CM� :�Tqey�H��'��S�_�?�Q O��.��=?;C�_��7��\/�T[Fiv,����Ih���+��^��Ta����m����S����0fL���{��Ƣ&=!�ڶK|�b�G!p��6�v$��_�BE�KF�0� �A���b�ۀ8t ����9j�&��]k�:mғ"�v��j)T-�v5��g���D>�i�q�B�&[̚ $kr�ȑ>l$0?�����w�O�����n�x�^M�{��ꑽ�T���Cգ��|��W?V=���#��|
-���i��@Ї���#�wN4t[�"i`���Ͳ�d~���D�ň�O,I쯸H��������7�#8��mi�9�%�~���Ǩ����E����~K����L��\��ƞ�g7��"+��V�E� ��5)6	�3/���3&U�N�E�|iKܕ��̙W�yo�K�������_}�q���<c�28 ��
->H��F����m�>�m�g�N�Et���>�}B�+|~�w%�;AD9�\<#()����b�8Wl;Ol=�t����*�t�v�<�R9�YN��-��3�]��B~cbf���׌��'d�QLo9�ؤ�0�&EXٔ�U���yÄ��tɞ��ZUA�����%���cj4�<�&��0�t����6��ж�B�ܼ_`�-�7dB wH�ق� �HH}KPXKF1�D�_&�/�fj��
-������Rf��<�p���Z�ӷ�}%�j����O�q��Έ{	.�?��($���l���~)�^��m�����c��W�ƗH�@}��y������ Až�u�cT������g�E���-�g��4�?�ƾT��@.�&N�ת/��4��N�er�.�`A.��5���5JxVQQǾQ�mƷ*Y�|��nQ<�}j�;5���z��K��"����K��Y���}L�S�-��}�w�&��-ᕴ5���,sۧ�P��)�ͤs�����erH}Se�ڋ���
-=�����wp�<�}�*���վ�/o������jڮP�q�0?R��h��K� ��ݏ�|��dM���j��b�����
-�����o�Ȫ�%�~�>`���|����q� Z6(�_U�>�&�#�ǣ���UK���7����	%��6�{����E��p��hh������PL即 Jܫ��'���'��K�DL@�[U8�v�U��3n���j�)�4/�'�/���Z��8�����wE�J/�zAj�Nh�N�fjkE�(��D>׈��>�Ț�8)0U����d�Dd<I�@`��ݢO��Ķ�x����a�M�}n��;�/�J�Iԩ���o?EA��H�[y��;Uw�%!�Y��>f񞈗��U�Ь��P��+���[2�L�����3��6�7�M��*À�ZäX�à�m����d޽�k��� �yC�$,V��y��r^Q��S����M�\Y'S	�|��^�_���*��S�Wn�J�]b#�H��R.}h.f���L>����E�Q�if��2��b����?��� Z�~By��ݾ�m��P�J��X��+������zt��/��������O�P,��/��|F$��X-���Zc|-�	AS4D��z��E�9W3v��Xz5׳�R��+�2�9>\"�ȭ��U�$����f�	�s��.	�ϫ�\�H����ꟴ��6Ȇ�s�
-&}D�~��8i���N�	|"Im��R�}��Z7�>�KJ0C�N(ټj� ^��
-'�clҢj�$V.�����@b�Bh;Oc��6�mK� �Sl��*)�$]աL�z)�]�������U0��d�q9�x|e)T/E���z�_�Mۙ�y-����:�J"�>�g	5�-��d�>����m�j�'yz���D��~�yZ"a�.���$ne��$~��?O�=�~4O6F3�{{�3��������7�Բ_4M�.�VM��s���
-�*�古�����׋l�p=f�	X�_ ��N�#7�%�F1r�X6�#׀Pi\#F��f�X*F���h,ۮ[�"a瀈�hT����S�_�[.�=�\|��rQ����r1v=2,w�׋�P����k��
-1�L�-[/Ґz%���=����"˼��-�[�PCi���8���&bΕp���q�����b7��>�F��z��۵D�}���\ ב��|+��v�]CiH�&�bNt�o2���v������YY6��#�������+����^T:^$�Q:�6�h�#�[D<bZ��q+�*�Jǋ��W�p���}ܴ;{R��"�V��[��Jq�/�S.�L�K4~���?w"Z�?�(U���Hh��萏߮ӽ�Þ~4�P��})����m�R��Ѐ��W�j����2��e+V�r�84��|�u���Jh"�%^g}���{�>��\3�ck��K|�h�$�
-�_�T��R�_+�.,� ��<<�\BL�2�WU�����Ze�te���(�_Y-�Ϙ�7Ƕ�7/}sl��7Ǌ����9V�o~�c���w�-}8�C��s��w]����ٿ��,��������hWL����/���j��J����h<�o�L�_Qq��]�ӿPf\������o�v�r�+0b�.���WZ�|��IM�mHmWI8��0z�Of���s��~�d�r^I����d ���T��]����<���4G�k/���Ӹ_�l�[�ĥV��0�2+�]<<��n�2<�n�2<�3��xؑ�f+�=�a������=�}V���a��a#� Oc�#�J+�&2��2l��ilrdXeex�'���4rd���� QZ��i<�ȰF����%������������l�l��"�g��[�=�s,䌭��|���I�s<nb�E���z1��R���{Y���h)��Eo3k�h9�(�~��ҰԗG˄O�-T��T�	`����4���oP�|��
-:�=&p"H�b�j��%4S�����Z"TN�+��h��b"�z��+b�&�5����u��a�<�,������a9~Թ v�q�%P���[���˵���]�Zg��<�.���>�:+��W����hX��O4Tj/�;��{���Fc�;� �����7Z��"ј�l^�j7(�!�WMj�2��Y-r�����sb��Y�R���ԭ���X6s,��5���uIT3D��HM��]���Gc�ˣ.,�}�#&�z�	���R��/� ��'�;m¾����>F�0>ׇ~i��`��6L?�ݸ����7�o�����6��ú5���?���%\��-�^���Ea��m`6&왱A��n���2����i���5�B�N1�N��'θ^��^�� >&~�F��,��K��C�	�y��7���26�˴=�0�̍D݈o܄i7i�,gnƴ��M�< B� �k���A�|�"�"�o��%y���^���`�~,}�
-�MpF�1J�6����J"d2�>�F��P�_달����Y/��'��}Z��^	�  ��HٔIV0܏�p��%���^伃q����U��XS �@��#R��H*"݌H�^�D�Y��t3 J׬
-�u"e�;��p�����F����~p?��������/S��5��N��Q�K>v�z1s�����US�	k%�26H�������pUZ2P����;�GeIR���f�<��n4���8_��U�E��'N�7��!��I�o;�������h����>����@��im)\�b8ބ�*@�C$<ȱ�]@�}>	a~�c���D��5�s?��T_��ݧ��-��a��-�W�6O`�n�LS��$���Mq��iƓ���d�Q�$���H>��5ZUK�y�+Ґ�w�A�U;�A�U��7���H�w$�������9��'$'[H�VA��< �n�P+�O2d�b&Ы:|Mr��]�y�K��w]�g�^�oV����{�aX��g�1s���r�GY��>��������>�����,���_�����K��
-����o��[��������~����'�; �ژ9#�?ʑ}����I��ϋ�o'�-��s5��>9��߃�A�|'��i�	��|��^�m������&�"m�a������K���?k�����?B�T�~�vt�W�\�~�6>�_��?Z�J?F�Z?V�C�b�:m�8�zm�1���c����_��7�oH��~vx�����������>�x�������\�|+r5���#�#��_d�g�%p��[�i�!��,yۂ�!vZ_ė��!޵ ��~��%��̞�-X���S4�|֗��L��*�}�R�{oď|/�>���*m�gt������|oЁ�G�?p`��b̟n��-
-�F�I�A vR0��r�]�:��]��̿npw	�s��]�O\)�J�|���X�C���֟H�z-�K}*�?��G��	�Y3�'����!��kJn�HxG���i�D�:O�0�;�2T��T4��6͛��ӺZ�=QU.����*f��B,���2��� ��glE~/[��X���ܟZ�?ڀ�Y��,���>�s����o4�h7��\D�{�i��x<d@K�k��XB5�c���oE4�ZK�L� �����6�f��6�Հ
-�=��%��[!dޒ�t>��<�[����}jF4vg
-E,��ՍE����v��L�FI&���Qe<�hUd_�৐�I�}�������}�!~�
-F�{V��BK,b��-�}�S�7@�K�*�H�>"�o�G�����b���D*���Hhm���Wm{D���y���?��hS��J�uZl��&��$h��9֤�ط��T@��p�m���5��W�X�Qc�'�[��d=�pv�Q�xv�=�� �cwh��z�Fg�whtv}��K�m����~�������"���o�]O�'��<��궷)e��Џ��I�I?��\���]"?���z�X#Z���{�9���{wkxv�Y���;4:��G�#<�5:��SÃꍚGz[�ܥ�y���7ix��Ql����>'�һ�ںߡ1�{b�	�����=���@��)g>��rz�׏�Q��fb�?�r������&�}��>�aOsS���v?�8���E���x�lʄh���P.�V}�Z�B��ww�l��J}R���g����h���7d�'9ҫ��F�9 �;d� .�KeQ����vҭ/�%�(�"�A����I�
-�(�*��]*��P�>	M�eS�]g��ii�ܙ��q"WЁn�щ�m۟��?)�b�#���C���;�h���J�5
-�@��i�-�'�Fa��z,�$�;e[����-�w:I���*1�Ͳ_�g��EF^v�Q3�h:�Mʱ8�h��Shҡ�U�E�[%z�i��|�@.K�0<���=��t�O)�Đ�H}?�<>�)Lƌ���&�����Z~HI�;"	(���D��ӽWy�x7(�K�c0��z��	iL��=O��k�<	���yJC»�*參~�U*f�֨���Z���^xäR�i��)�4�)����z������1�h<�|uvo����o��'�6I�t�{<��_F��z����I�k�x*��<��v��0DǠ��`D�ڈ�������-v�#T�#�T@exR�zY45�M����1�Jċac�`'��Jc�{��fi��Y*�����>X ��R�[bR*M��S��S�~��
-�"r�"� �Y7N��wL��3Z	Moq���U�<���s >�#�'�m�h���� �6H�f����]}<ƌ�I��w��u9c����G��"'nv����&.��f�h��3�o��w�(ChL���v��n-K��42�:^�<ɶ� �þ��d�~.`�r�� (�I*��.06I�DV�#�*�������?���Ka:O�1����Q��9@c�>��c�yJ�u�X���	��&�!�4ߪӵ�Q �؞eR�
-{��6fV��'��'$��L{1����q�T�>ԍz���!�WQ�q��cR�c��c�3�z�
-/~c!�1��#V�أ���צ�����/j���@m��|v��S�r7z��E��}���J�׼;(�y�:�4 ��R�j��C�������e��/<�b��9��5l���f�	d�	��!��b<��Y�s����A�M4�Qu�6�K�n�<,����1��6%�����ɱ�%�KHFk�ֵDF�ʂ_~�X:'��
-���ְ��s���3-c����;�E� ��d�Uy���qx�_��Fc�-|������x���}g����䵫�{}H?��;����R��n�>M4�{	�z�˰�N�<'���l4������j�S�	����r��(^ ��/�@�HXW�DX��+�An���D�'FovW��ج�D\/���lsb���.�&�/O,6O�t�PegP��L^�5�[���6�R�Q�3���JE��_%s�ի�Ń!zG��@���?��|��TR=��38�_!��yV�܎@۝1;�C��s%�8c��\�:cǘל1��t��lZ�B�[��3-��l"쏞�Z�F���7���'���s�!����5G��?*G�T���6�5#X}�sQ6�x,�Y#�W�x���]�2���L���n��$��N���x�栗����ʑX�j;r}x�cN+
-�҈ۯ�ݩ�����W����Yǧ���
-�m�۽ӛ��R�6熰�E�HmEg���V���ɸSj+;����Q;�ծkچl�"��m�b%r��?"�*���Q�8?9��,o���ZW=�e�e�Rt��9e>/M�-�~����d�c*�n	c���w[��W\��Y�+���TT����>�_�m׊�~��.ҙ��ث����pŷ?�kh��>����~��Dd�2/���d��L�
-��NE�S;��>��G��J{Q���P�]ȶx�aY�fF�xD��|���(>V:e+\M���Z��8{<����4-��_�l�v��Y{Ć��@��^�;� ��K�XjF{(刟�=ƌ�n~���CTGRp��A�����	�B�y:6�������\��Zf*��n^ �}����;���	��зKkz��� ��M��C
-?��3f����v��կ��Y^��]���y�O��	�g����<�����z��<����ҏ�5�����<����Q|�w5O��yDѳK�~�n�=�ht8~�	ܝ`�<�KmKP�
-#�D���>QUFe����e���tQ�L����/�)>}��foh�.���U�d}����u0۠�"_2P,�S^��i��`�}�^b?�i�"�EJ�c\�D.Q�^�%�%�3��D.V�U��J�2%�7.S"V�g%r��ˑ!}*��*�j?3�o=�O����)��S�c)���������hZL��[@͋^<�I�����=��Eڋ��o:����(�C1��]ʼ"��i}�WH������K�������c�荂ʚ8F���n�p`7��s���p+S����BC��?8�X�z������K	9�U�]� �A���F�9H ����8t���_B��z2}�V�_��nD���]������X�rȃ�&�ޤ�����J8K�\�`�y�՝j�-�._���2��&�q��Q,0$�"��A�F����i��e���Q��$�>�Q��@��eɃD���琰�Hgy�)��ۤHUwe)R��"W���$��U܎��2��'������Zl~_��5�0T1�#���?��SS��<��C���}�|? ���4^��6���+�m�t/R[�U)���|��5���u�.�/�d�w�A\��!��[m�~r��|@���9�z~a��<$��DL̼�f>֊P��O4aAc�"�h����~a��F9P�Y&��x� "Jԍ��Pӝ���0'j#_d�H��42�E7x�Y�TP��St������*\���C�s�i��
-�+�:޶J�w���)���7�*���-O���/ߘ�D)I�Z)���؅@�fV��X����e^��:�" n����M"3�\v��i׀HƕJ��� Zt��	I@p��1A��/� �&~ �A9���m8��H�(`~&!�P��U$wV��_�W�
-pw5�<��^�MT����5}��?��Oj�S����?����g5�9M^�_��5�%MYӷj�6M/jzI�˚���o��~M��W5�5M]����7���0�R"ׂ\���PR�e������PbX�2����ܰ%�PvX���X~85���j�E�������.�z�M��n���A��áV�P��H�Yx�-|�.|(�/�5u���3ڸV�\��;�N��;ǫ�U�����N ��߁|��������vc�{܃��)�>�%������b?���6�O(�	?���Zޭ�����9�������/�[���0�5�F���%�o1����a�{
-~�����?R�G�D��	�(� {��B�O\��s)x�ã����S��� ���/$ c��(�E\���P���e���Q�r^A�+0x%���U��j^C��b�`X�֯��{a�!�4hu�2�]�`7R�M�9u��1�G�}\���J�B��0x+a���)��k	�v���:J[�ůZ��!�Qn��#�����<xg0\Ãw�5�l�&�wc����� �ã���1�@0,v�b�ESp��.��G(�Q{���cp�`�	
->�����{�>c�jϳ�|�>g�Z�;�"_s�͸Z�\��/C�i�`���lbз��1I�f�^�8�O3X/c�+5��+MT��� p��4M�������ȇ����ޏ�H&4e���?�����:�� �o`�3Q�*�M�ÉMDK��+�f8�m}Gr��&�$��ߢZ��!e�l�wb�;��.50��
-M}75���=A����+��4-�5��0��B�C!��$��C�P˩YA�H��X���C�W�ϩ1�������7|�.[F�B�^�V\�+!sѿƟo��+�43�������Ä��j��|G�������+���y�*��4���?�7����b��	������u	���?�`�@��/�׋��b����?��KC�C�\�5�T"�+�j�bK��	����B��p�f/���̿A`�Pu �a�zyH�"��;�7�o\�{���*�
-}Xc�+�̧:�NX�E�8a�ĮR�|	��)͟ix����wX�0��c�/��K.�o�@<���,0v��JJ�ˣ������x5�"�����cn�{#�*����z/ע�n2^��>�os��S۾�/g5��x��eH�l���M=�Ƈ������
-d��*��U�N@o���%�>4��'�t���V���[B��݈	mn�bG'4��]�+ٱ�Ⱳ+'3V�baz|�ʞd0�_�P1H�	e}��¡���PpE뗚cC� ���Q	�#�9��m��;� XJ�l%B��2E$D�_4�b�^����<s��\��2e�xVɮ���Ly��e���;@��+����c{���"�����_�a��d��C�XA��q=W����:;�Dc���R��k\&T:n<ի??��9J2j��%�@�K�xq4�����M	��M�[�����Dx�b�7@��n�!�V�p�S�\�h,W"}��S"7*����Je�0c��M��W�۔�*E?W1V)�[��r%~�Y���/S"����%
-��Ї��>��
-��@�&��	!�B������/Up�_�6�E�#���2/R��PF7����Ob�)ͻ��%��=\�
-���+_l��r���k�6Y��@��*JA�~��f%<ⶣx��c����!<~��@��[̓���0Ї�2��]�+�z5�r��m��.��i��4oa�^��k�O�>�]�ܬ��#n6Ps+��kw���o��D|��꯲��{N����x��T�4��F�Ҷ���@Οk<р��ާ�W��x{��)|��}X��x���?Ѫ��{U���nPnm�TAk3�90����Z�6��o��:Yh�	�V�F�X$�5���줛ܝt��I?�N�4�b��N�su���V(u�I���	�׆��B��!����4sM_�o�7���C����W���!��LI}Uh��;ue�N�Bva-�ᙿ'����O�sю�юxg|^:���Z�/�;f�W�$�s�3Q> ټ��'^qZ���p����g�����x<����Yu�/r���ο����{3问��{θ����?uK�=c�-{���f�I��L{���N����o���7��9p�@�gtce$'k7���!�?�wԨ�hx��<5�m�4׷���t-Xp��/��� �_�U� |��^����b�Gx�_�b�z.8�7������>^��/ݲ���y��g��q��텞Cwֽ���O���i��f?>��.�_]S�d<E�]p�(����xa�c�q�s����=�|W�)=�ES)�y�a�U��L.ޑ>�S�9��K,����	�ho��_U�.?���}�a���}��o���Hko�H������{�e�K���.���-����_���~�H����_�a��َ��o���ߊ�߿]xx�z�+�x���������֖�W?����z�r���o�~��3�ӳ�����y24v'�f�d��qx�=��wΙ��GL���u�=�v����o����l"{/s<;'.�����?��ҋ�o7���?9�?6����������x[���/;O���Â��x�8.��w��ɧ���F6��HS�����N���l*��楻:�3��B�s^{:8��iM���Yݹl!�2Ȏt*����L���;�\GU��
-�l�<���^X�f�Ϭ�xw��*�s��"�.ex% �dW.]��ܞ^�*R=%5/=3�y����D:��9#�-�]ɞ<��AH���:�lWgm�d+̐i�J����B^8�sZ�vutwuBxZ:��e�]91�Ƴ����83��i/P.���3�q�-�@�R�t����pfz^6_�-�j�TH�g;ӹP#y^[
-ɥ�]=�d:_�r&��P��ٰ��ٕ�iO7ǓP�EX�|aQ{:_?u֬Y��N��sT[v���_I�C���A4X#���Ξjlj{ZV�Cu����qx.�m�9(7;?mL&�V@�f�#��G�y���isZs3�H���j��Xs&RQ:eѝ��j�����L�l�����DW<��� ���̮�i
-�Э��`a�9V�T���HG�����N��2�ަ�s���F�=um}Z	�����Z��,Ю�<y
-���9���؊!��G-�l�=��5`wTk��xn^`�ޕ�Ri���a,�#�q�O޸�3r]��\a�T�;��YF:]�i�Lav���I�Q�29��d5�w#�YR�=bЃ�L����"BG*Id;S�+�)�Xp�����|�uΫ��D,h��3�UGT�	ӫ���� �yԙ]���������/?��OYc�����3�ihaмݬ;����U;�eJO���98��B�Xɚ� ^H��XPg�5S��4��3әt+�~�����x!Ω���\�+G/u�Ұ�f����g���O��N�n���צ��i�f����H��b;4�}��t��ad���z�=��E5�A �ܙ�!&YYw2�L� �:��L�p�8��D{:T`Ż�.�m`��
-����\�����1���=���������N�)?�6�F6�s���gf;��Mh��:テ��a��d{O*��ɩ�Ek9F8JpՎ1$>����@�������/e�Z��ۈs�P��.5���BJ���Q��Lw�H��M/0��S�@#<�i>L�,�5. ��͂���FW.�8�Y�]P��ۇ۩sk��D���bT�U�3�r���N��~ZlE� 0ރ�v�	����]<�&�ͥia�P5������Y�1h�9���;��U���F�3���t�5N���y�Z�o�I����$t�9u\t�`�X��&���P~A�{*�Ʌ,�6e�� gץ�z�j$�9�Q�l.�A �������x*E'��֙8�P
-�g�vψw���C��E� KX� oLv��AA`0�	�]Ҥ���a&'Y����N>�L�3q��c֜m1�pY-���
-�U�.O��wJ�l��Z�'��@���\��t�X���[  9.�~\�
-����"HP�A�K�����9�:�$���,�҉���l�vᐓ'T��8���0M�(	^�z���-����B6�M�wI��H�È,�vt˴3�gCv���ȝ[:m��:�K��N�hޝuv�i���<(�ю�O����p���)~X.�"9���`K���,�[�@r�
-��F�2�Z��Q�H�ɽ�h���y.�bpx����p�=�P2r��4,�y ��Y�Z�Bk'4%�Bd*�3��˦�s�%������ 7�\������t��%���Kd]�|]�Yf�4�ҹ�.�	CT�:_7��W��I��:|�����v�xm�u�H'�s��!;��hD����9ht�H�9����ю.?.��x�I�B��i��6�m����8���[]ˬlG7ض�.eH��R@fG�(�D�S:S��Jg:_8֩��x�=�B��j�5
-��	��`���⩮D��8��N���(�����gq��o����IT����l���oPqd��9��
-����x�ȑ-g����4�����1L���D���řO��S�H�w��1q�\P���b���XO��XGT�r��j�`𸠝�%��}Ҙ57iG�$�9�PКm�(�~�+'2�r�9��gB����qj���;/�"0��w\��
-(��r��M�����s�����^4�kA'Z�tWǦq�2(!�a��h�� S,�:�M�-{zI�Y���l����9݁h�o��hީZ�������[j����'l��V�j$�(�B�ŒjS�*� ����A������%0�pf �e|l.հ�v�3T�&�ņ�l+&'=q��Q���e^�(6��87�o��R�s@�i{3ޜ�� �ϋQ����P�h��Ў��v��ɢ���bB�Iѡ\�^�/M�v���������\
-7�@�5�>ɔLoy��a�f��9B(���$L��0�M�S�ٳ��TSέ��&���.:����ۍ�R�S�Uc�'HUYT�u�>ݱ�Q��Z�E�}SJN񩦄M�	�ߞ�5��w�h�AÌ�L�O�:@h�抌0eSDG27�d�n̥�W0�t���X�N
-f�0��tQr];��0�@[g�Q�1��-��Sa����Y��5���U;��^��h2N��y�]�x��..�+СD�s���u�!����b�-mѡ�F��L�����Fd�)��X ���������3�b�.'"���\�`���o:e���R�1p�<�6���l��Nq�j]��N�Q����O�Ρ9D�tѹln��q* ��{�>jR�]��
-��ԴjXS�9�tu����Si@9�J�C���r&��4�uv�%]��Sm�U6�~�| o-�j����w�=�}UE�)1Jê��K>�v2�@���}u�e̹����SA�nZX�V,�K�u%6]k��dh*�6;���0p�� a��XK_�9���8u)J�T.����:�֔+Y�� �O�uԁ�\��2gF� F6��x���BI� 3��Ls>ܱF��g
-��=�آ� �%��s�u�!�p�`�uC�gwQ��ĝ�"&}n�v6AN]�Ğ�z;�k�朢A���4:To��a�v���{��ƻ���!������|&ې]`-����8���:���{�j�J:�b�1Z�5�AF���ȷ���Zy�R5�:�`Ś�ZԱߩu,g�f�yK
-D-Q_�d�9��z��6-�6h�s��G���\��-_��BP�k*=��niQ��ja�ج7M��(W�ܔ)G�F�v	�'U��2}��Ӑ"QK�f{	�����e�#q+�����]�z䩄��x5�YEC�/��;��T1ҨSd�-Է�ݕ�IG�~��4X3{�wZ���!��,����@z�|8Ӯ������!����3;��Ksl�q�3�f?N�jV�s-�rY-�?�����ۈ��`��Z7C=��Y5�Κ�j��EѠK���3>�K�H���9*��9���$:D�K:�X�Cx�l�x�'��ü�#L>f�Qуr)�;S���괦�Fؙl���.��p��&sm^�=[XT;D
-�ت�^��D-JՃ��<�2h��NH�}r{�Ts���Cvx����t��̵hC�����/��t����;A�C�<@�\4\��F�iJx�P�Ke+�	8t-ه#t�K���b�ݐ[��e�sa��2v۶^���C��G�ߌ�5�-�{c˙��T�b*�v��.�E6u��9l��'w�p"�˷dNO��{G�l��J�t5ٞ��XB�4��ײ"R�~
-�T�v�w����Nqjhb���.o��.{*�U�m!>��5,��{C��`�R�`���xNu4$���5���S�Xu��5�쨃�95�zF%�y��t5�&\e9��-!y��=rP��Sk����Zd��҆J���9������7�$���vo�Fw 4ޏZ��i#,�sP"��E"�|�6��ɟ��a����C:i8k����Z+�H��1�:��0#��U��p{*�U��F�v��9��y9dI-�x�K	6>Q:K3ب�(�)��`���X��,>�Zy��E*[(�2����!�zX�ޯ�3�
-����p5W�6D:|H_��(�tMDk/�����3������ia�� lM��
-�c�r��9S̓�Z�����Qu��3�c)u�:AV�
-�a��׍���;��s��x��)�w�ټu��zV{��|�9� ��\Pi3�!�'�I�D�t�l=rVաK���uc�����j�<%d�a�ေ�?h��tu��De�����%��4�Ҁ�#j5iϜ�k�Բ^�l�ou�!K�\�A56�gu�`È��xx�2l�<�\Vl�V� ?X!<�!(��ڹx7�>������x��Q2�$�\*��%� q�8�ҡ�Vw`�r�"Zg���H���E��:FX����!�I�P�l��!;�̮�jˬ��n�a���C0񵟛�2x)�"es�D�>�k�#����P�k!/	�P�Ri��5 [A��b,y��VG�-��|~<���:ֱ�S��Ӎ���9�4���)���fg����t��Y�f�Ug�s0ߐ�k�Eᛉ��J'z�͆��،=�$�Ӳ�Bu��t��-1�M;�'�)faÕkE]-�.����J؍K�����=Yup!��F�`q���0��uݨ�rU���.W��NvW��m�Y�C���
-Y���g��|�Q[�F�Q���4uf��L�z�Վ��Re�y@d�z���4=����e�5V �fGF�v<�]Nd�MC�t�&��_��W���	�t"���j�V�z�:,
-�����)�����*ַ:j�'�eZ��񄝯)�}��K�����rz��yԑ�f�k+�:jM�A�Ϊ��1
-��s�]��Cސ�}�Z�L*E�P��pޖ��BL�g���(�;��������y���Q�u8��D]��"���4�����p��m�v� �S�&u��:83�8D�Pc�[���FTG�Q���J��x�b�nYs�]���Փ�$����s�9k>�,1��҅�$��9l��
-]���t� �L�S����d;�����!��"3��u��BS��nk+RkM{k;���!��;��y6���|&T��r�K�u`d�v\�`����3���<?V���v��R6O��bf2�vl�7��N�P�e4g��{�]݋Pf�����l<��J��ɍ�u���nu>,�.���3�R�=M^�n�7��K�jC#�u������0���&=Ȭ��g?�3�2����aJ�4n�Ӛ� c�B���dԌ3{���J6,�b�O�Iz�����U ���00M?�L�r��Q�$t�a��P��˧�\t���M#7@�E�%X&�TS#l��H��c RP��+����:3j�U�8���F�u�$w���QMǴ�.[B���eq��7pE*{=������F�t��m�fw��;RH$,X�B�2mx�r\�P�ς
-�=���7R���\VEmڢ�xG6I]0��W��1L�^��7ɣ�N$��4$!�({�58K0k�4尓L�G�^�.\e�l�Y*�c��n��<'��!��|7��9ÒvՖ���������,�숓��h����V��,�����\�@ۏ lf�2<]����W]�$T��@g�n��i���C���e=��Vji��M�F��M>��5��fh#ϵ�qc����y-� �N*Մ�D���/�/��Bb �QE�W�Z�D6�Ń�T��D�B��{�MΟ"�@+㾜�)xNhbl �q&pkK�L�y3y
-;�WX
-�J�E�~ �jwԹ�k�<�-����Z��̰�'�;V����=8�er��ȲQ��Ιؚ��Ř���C%g6Ivގ��;��tƵa/2U+��f_mgW翧s]�O��a�^G��D>P�`T�ì�5���;�A�y�@��S���b;�xx�B��3��Q��!��%�z�3XFu��Yi�GUؼ���z����׺A��+8_!ۦ��H��9���S�Ȏ��-o=��%<!N�v*xF�Aڶ��u���Z1hVJQ~���}Z�`��#%� �{,��|��F8|����k[�*�A֙��a �6�S[��&��d���jƎ��Ι&e��2=2����2���h���<sspwWB�����pW����'��R�	��yt��#�$�J�s�8�)ohR��$����H���-�;T�8AZa`:�4�Υ��������WV��
-I\i4ܐ����Bk��f
-��<�;��6a��j�o��kMO�;�AXN�-k[�;aĐc;����6X pF+����Xqj
-B �a��x���@��Egє���S�!�ސ�)����4Ը���68�z�N�=Z���l�\��P�K�20���lw���{2l9�v��ӥu4�����:��B��sX�if��E���J�.:��Cb�P� c�*�iЊ@�22���a��P�g���Y���-`�Hg[�|p~6�zRVD����]���I (F��&WG���hu�}u�]C�lW�=v�uh7�a��W ����-�����j���l���jD�xG�j���t�2r���s6B�^�2���y���-܁���A%�ȁ��,��t�!C;�2�AB�oG��,ӕ�i<�wg:,|��l��8mp�B����k����с�*C���-�>~?|�s���un=eHJ�r4�)��	pFJ-�P��ZG�{]��Go-5ʱ�JjL�OlI�������\~>7(Vu��ƊSL�	�t{!.wshp�Ts���r���C�|��{�u�M�Zh��J��L��б#��C��g}-3��<�)����<v8�g�c\����.��N������@d꠳���`):d����.<�g�G7L'�L1�d��l.,�͛F�I�d�Mn�-�D�"c�r�p��,�͗��Üc~��Țn�Ҥw	$��dW���m��:�4	D&�u�2������W�ɝ)v�����]��Τ�Ŕ��i=�$�9#Y�Ffl<�0���LᥥsN>]��:Y�v��
-$0-K��-Ң�`P�]g�׊��6�P3�t��Ҁ9�M��9�29eڭ�u�>��:yB�&d�r�2��*�E*�͗��4�j���Iam���'Cl�le�oe��1�4���B�`$�Z�R$�E�a��)I�&a=.�Ou��d^�!B3 ���eR��Xy>G������@�0?	�!3K>�R�C��>���}f�<�e�����?r�<<��í�t%�LK#歩d��:�ax�i�������x��[@�)�}@҂�bR�3�g]�	a˄%�kG����!�Qjz@~�<�]~^�m������fv�8�][C��d<ي[/�������֓Ŵ�^��_��Xa��:�+���g̠���wUS�]oaʢi��1,��LMs�i�}k*w׹ƴ���5�H��t�w�n@�V��ae�9�EC{�	�H�U�旓p5�
-3����M>��S��'O���>픹��kh��3�\W��f#S��[�{��4���p�|�y�Z�Ý�9DUt�M���{���Z'�m6�#M�3k�r����ɉ{���D�f(S���Z�$'�s	P8ŷ/
-��X�4*���r�7؝�#�2(ɡ"of|��89�gݩ"��J��މP~A��1����A�J*�a47�U���"fF-�:�Defu��+?5�]���iI���<7f��͞$xxbo��a��v)�	�tîD-uC�s�Շ��X�1�����$/T1�0u��c��h͎�W�-�����ܔ;*�3��rD��zS�b��bhC�F��d�YUU>���#�x�EJf#�݃�L]M0m+DX�2�y�юx���Y�N��\��4�i,�=����"�!7D�6���Q
-z���N���0&��J��)��
-)-Z���-<VТ�����E-)�L�8���	�%5e��=2vZm9M��h6y�ƍ����f � ��J�&�U4�ә�Q%�T�U�%]#ª7�P�f�!n���I9q����@��vre%�v7�(���kd�� �#�����|U%s&D�	1ϗ@R�1˫�b�K���aKK�`��r�ׄ�������:�����p�V�G�-Zs�~2j4����n�tsW�&���[%" h�͝=�1B���Q���RQMo���Ex\X�{i�nJ@�ּj����_<@𵨥w�"p�1�")����3Qs��!dY�L��M�W=Qp-�f�5g���Y�{�ő��=��&��0HxW�:�5fm�Mx׻	���XI8m�H�������09G&�1��s�L�������I����>�'��:�����T:�K��q���Ӷ� ���N�bU>9��x
-�32ڼu��c�<�o��ȑ'���&��]��軆��.YwK!t�c��s��|��%��Њ#{/��������.��4~^3,�Pl	�PF>4ÂQ�P��u%2mg�ڧ�i��(B���Aev�Q $����Y�8lY�@�~G�A��Ѱ$��nz_EG7�sâ��u/+1.�q���|mbuJ3�%���F@<��.k��|dK��5f��Wё��6#&|�l�b5W|��x��Y��7\��oӘ����V�����<L;�H<�s����~;���6�0IL��y�x�`��+�	UyT
-m�WBU^9ªgl�t������se��a��<?�^��~F�+��M���CWs�>�Q&k9�x�N��1)`��g8��H��e΄m0���|@(�hUZ^`h���	H�vt�.r݇�iT��zô�8]m,�6�k���b�W��u���J>+�4�[qp	{��f�������ײ�sy#IH=Mv)N8d�FY(
-i ��ђ �|�8��Ǫ
-�^VP�gHh� ��p��8)3�/����mB���Dq��9s$���z�y6M���LF�o/���V�,�l8�$�w#2�#���!�+3�A�/2�F/�ůלhh�����.T튳L5�0�*�����g���] �Ѥ�Q�I^q�7'��BI=�[���״��á_=�\����_��2畼�B����@���
-+W.tmZT+,RBU.r$Tp��v[�E�ˆv���X�C�Wn����$�F��'s4L�)D@g�h*�􈫣��Q���F=8�q��\���Z�\���0��.��e4��!"��5��q1�BlrQ�7�e�5*���E1�餑���h��H�5nz��J����sJ�r#�غ���S�"N��[V۾C!��+�2�@h?/���y�=��z�7�z㷿~���~눺VxQ��6�v�**i#��~!�5����a�-n����M3����Y��Uơ�0G�J�3<jV�-��V˘16�9	rL%%�MD���1�r
-Z�LmK���Gk��Jx�
-�=r��\V�e��1�_$V�u�	�]�֓��y"�REe$����z�E7�Py�/��ܡ�eBh��[뇴W�;��=5D]h]ot�pw��l�B��v]Yl�S�FL5� nC��\��y�8]c�D�u�)��%��s�����x�Y��=�b$�O~xy;B����
-a�4��E=@�*˸�h�j�D��M!"��0I��P�8�!�tK��<�k�0\Z�~A�1����M�<xC��*_��(r��J\�P^Pܖ�$[�*j��b�|{�P���F_�x@w���q�I�-(�P4^���
-e���^�U^Y�R�c~?F�"�ܳ%{K��t���c2Rd��5����>:��1����\"�/�-���1� �E���ȭ��� d�8��l>���<)���7k�G�]F��A���R����tr"s0í���.�����I�d��F|��I_�&�ߋ��J���b�?eWBC�0ӛ+�z�	��a�D�Ї�C��-��q&�c�D���{"ߐ΅[B���b�Nx4Z`���,r�EfO�ҤG:7��Q�'>V2r)�h���=��h�	;��}�z�ޑ��_Q�o|�����{�~TZ��k�LvϿ�H��ޘ��B�-e�[���W4H��C��ֳ��-aw$*%T�RE2�����b��C�iȖ�a����~Q�'MK���qЉ9+���C�Z���]���v�L'������j�~�0�#�9]����(�}�W:�0f�D�44U��>�XFq^k<�xԐ��/T���C��m�z�6׊� ���_��n�
-�/hKi��)%@Q봖���d���m���fP�{��Gm2Y�S����M*�tKUu��kd���	Aڧ�_L�&�ݰ~��N��ѝ�!:�s�7Y�S�SE�|EZ�@��}��͆�ef�I-c�9�B�i/2Q]�a?�<�\z1���EDꦢ3���J>�Uܔ锒�\70���e)�Bqz�XF�B�&�0]�u�6�B�\ŵ��I����D�ZHg�*o:��2���9�.jwX��%�>����(.v}.�/4$���KQ�UR�_�S��KǠe%�����Xv��!��H�))�}B����CA*m��錓��ҫ��0r��Fh�*l!/9�MQd-�}����Yd�6!���E����J�9ِٷW���	;���*���p�	��r�!���!��m��/@�J�K�t�*�� +D���m2"Y�M�@��)!6����^��3r�	�bUA�Usi�XR��+{sj�[�p��J�#&��U'S1��^�q�o(��P��sbC��M���V��6�v�ڪ�}�ߋ?��g��G++�;o�-�0�ˁ�XI�^y]O���FZ.mÌv%��i:�_��0�%�ǜ�����ר��'��]1�q>L�@$4�f} �AFt�Ūj6�Ej!�����<��#]	�Ǭ"�T.�� ���7���o���ۍ�P�G׫��V8Z����<�[�Q7��w��U�W1��V���JaG���[�+��D�(�pq�C\Z�X�?�F��NH'����娻9MJ�mBÂ��%���o{�٥�Mv�����Ĕ�O���d��{:�J�B.2'_�8�H���.��p��[����c���~)&�74��ԨJU���A�_b�P�����r���_ZE(�ӈ]@�i�����SUo���ϏD��%5�̛������48N�ic�׵0�*�B\��$`�a�b�9�:F�61Hr`�/�)�w��l�� ��F)]ϕ�dWd|e7+�h�dd�̱9�����mT7>�CQO��UdR�����b1�c*�)�T
-o"�&�ǯ0_��3&7()��=�~(�M�ϒc�ۇ9��(/�D�����Ƈ����~y�[���o61j�J/2P���	�S��Y�?�=���8(�X����e"A��+�4$�v����JS��H�K��`�Q/���tG�Ȏ�9�>\��q�ژj��nˉ����<��
-�.f��Ѫ5�o��H���cS��_�i��u�9:Y����◩�$YW�z!�
-H�NiSƐB+��ґΦ2��i8�l4����2f�3b�#�Z���4�ԝ`o͘?q }T,�ȆotO��_*.���ޣ�-0 M�DCL���F���:
-�>-�
-�m�Ҥg4Lk�87�$#-�yvFz�����F��s��%�R�&�MC�22�m���~��Ym/��<!�u��~�8#Լif���̴ƙe�G��ABA�ƙ� �z�LH�$����)��PUi��2�s2��:ެS���u���/�T��g�o��fx�f�Y�2�s33r�3�Iz��P��3]m�Ӥ\�FUz��K
-�4�������-�I��Yf��P��L�tm�f�?T^�U_EW�F���C�M���p��xa�n��a�AvFZnF�ǸE��2^Zz�f#y)V�7ܦ��9��f�gh��@\?d��//��/n����β�[4!�h�}}�ggg4���"���Қ����݄J��I �"l�5�yn���T--�d5lh)-,�R9X�V�x"��K/�I����mm!r��U�C=]��lc�u6�h ~,;�i��u�M�ydA!A����\Tyco(˕�������<2�)�>�1��P"��4)'՟賿���Gՙ�I����9�UּD0��PA�)D�����"����lR�rv���2�^q�zf3��\�6���J�!�4��k�(G����Y��նuA�lb
-���o*&��x��>	]G��&�Sl�ץ��Y!T����Ĉ�j΍~���Ƣ�ء�o]�/�!65����BG�g|Ѳ@�	�aD/�Ok�w$X�-�k�~(��&Y�s2B�Y�7e5���Lψ�7�jS����F��@&5)z({vF�n�X��
-�A��=޹YY�ChC9����Z%��%ވ�lO��j�xqNSĨO#d��!����d�t��d�}}�\����i����j�p��9��S��&h�s3h����XH��� 3W�&���47#�7ꅥ��5�h�)jDEd�ѤGc6Qh�$e�9I�seB!�p��%=��54��k��j3q1q��ZZn(��B�W�Mm#k������[s���F��sB8QrbH�qF�\{�S��B$+Th��=���7�j����<��[�7N�ۑ@nV3[̐�I�ߤ9��g��f5����#�%D��g��f�5��C����$�,R���se6�Sӌ�KZ���~���g4�H���d�|kӬ���?�Fi�٨]�s�R�^�'E��vق���l����A$�m���M��9��7v4����(�inZcG�x��I�ki�s�7����Z�K�۔(e���YM�ě7�i�� �afF�7#;;+;�QFvV��0M�3�3!v�ML�	���7��Wwa���1c��;���5G3��L1'��G�2�|e�~(�iiF2�pn��4��Bwh��f|�+ŢP3���k�#騕��xs?l�����͛6�Z"�i9�M�4m�a����]}H�_.��t�G���h��h��Nl��A�<��ge�+�ͱ7o��V�.�v{z=�]�s�*@o'G"	���5zA9�#���4�iC,�ʀ�C*1DS?XZ&���M�'Q���{m���\E̤HB�YbS�I�KƯ�#Z}|!�e�k�?��|�0+�h=��v��Y�Yڥ��Fߋ>|BJ6�H�1*�����vyE�=�� �.��Z���Nt+�qV�����E���QG���P�d�8�$�u|��#M�K[���&A(ꦗ����n�Xc�����32�R����.�$_��<:���uv�G�K����&�͛Xg�o��S.�V�"}��ҕ��c�.���˝1�L���;!�w�29���n~�s�h]�T� f�efT1fI��6�����p1����;P�����)�@����pb�6喻��E?����{1�1�|X7���46�����$����Pz�#�2c��&��;�ӌ����^l�y�LV�t�aV��9hy�d �h��P�vb�7{.&'���2ڪH[鈶I��bJA���L#x�Vl�$�D�oUu'���r���~d�F�e���q1e$����H�>�Ȁ�������oH��R~����v�u}EtM^�S[Q�i^S`c�[�j��][sQ rb@wt�#�Л�����i�����sXaQ�\G��Z�+�GW��6-�1(Q���?K�J��9t�����<r�e�,0+�Oh'r��":�l��B�Ӛd�;
-3M7�4;W����,;#Z%�WR&C)�]"����Ea�E7W���8�[��iƿR k�6�O�a��(�@I���������_��2�ϕO\����i�x.R�hx4,��E�[Z6䠉ˍ�d令k��e�4����_��(V[�%�\��>2�Ct�~�~��qO�8�l�y�0m����*y�=�Q�9Tc�Ml�G��,[�E%�唀^o���{�.*�'�O�m�Y1�knp����DxwZ��B��h,�K[+u⍫�MW�IM�a��H� ��^Bc��%[$��Ҭ�!���T���Pa��"Jω�%>.mY$���Y��2ib���ZDGH�)=m9aEs���?�t�~:+����n��"$kS&�:��=紡Yf㣦u�t*�"�:�:������D�튢�oնR���Q�a{��T�v!���#��aN��H�+b�n�m�w�6_�
-�(�JNu"�5�t=��c]a+��C���T�a^���Jm?�[	iS�j�ń*[Q�}�DҢ�".��6v��_�R���&%��"apr���a<RԒ}
-��`���
-��r�X��H�I��2|�nH!4�!����@r<&��d0M$O��Q�K��iTte4��S�4��l/��U��i���-��E�k,��d�M�t�j)�=d��R΋t�����pZ�'2G"+I�U$���XNtdDX��.�� �(�l�%�;�c��-�.Y��8�V�����;��y�ӫ*hR���a�e��D�]X.�Ͱ���3�&'�"M�:�W�1�[g�X�֠1ˮ����i�GGtrHg�A�$�s���$��͜��"�U�h�A"�B���̭T��C�ۢ_O+�7�ҪG�����w�Q��{Źo�s(>�^�t�B�С�AWZ,^A�*���G'U�9*�e��#ϐӦ�hX�cZ3yEO�؍�#?JK�3�I�4q�+5�¢/0�-,.--�R4�<|�mI�����P�lm��$��%s��V�d�TQ��.�~!�%���{!w��Y^��H�����^Y��O�S6pPc�j��:OHy�h�(�.�u�}��M�H)`(��=��T��ѕP+���k�(���RXpD/a�k���h>����N��T��Z��F�%Ԋ�]-L��>��$�i�PfnF��;�No��~�V�lB\��>����b��_�fU5l��b�^
-�d�K�>+�Xi����[���y%����g^e�_b�^к� �ɸ�E��V)�����RҰPƥ��V�~*�lsח�G�(kRP�Y���ἒ�kt���A����0,X92�J�))BOD�:u\rw�����#eUx�}�i��3�q�H6��kMT��:�]�W��lB��;��9�o|��ղ��W��](u�Ho��<����Y3��Ȅ����[?�������(������u� ��D�<���Ű&Bf�+z�Ŧ�m��)�Z��#����tQ7�R�6P�E^�=))쑝��/�	U�x����{��Q��d�qgZ��^U:�Z'��`��>��f�^B�~��ќ�S�v���+�F64z��ϿN̵;џ�pÎ�N��u��M�+��Wm,wJ�R�U������F��К$�H���#EHm)R����s'���k�S��t�ݨm��<��Wv�cY�z�l�с{?��锂���ެ�z���gr�_��M���jgkA7�40��_�#-��J[Dº[���m�O�"��q�"�uB�<L+e#�Hm ��fYD�����r�3��ּ�(z9�?����Mz��E��'"��
-���;ˋS��RZ��(�*�*��("[=�/^��ĥ.u*]��6N|	1��1�5��ȕK����(�u�7/y��^�d�#�[�։�j���믿�{���N�%O�M��L�SՅJ�B4�z�vɴtK�-K(�K�u��[�J�uB��U^o��<M�8X�6-HU�CΎSuI�N��V�fU�_�'�(�P�1��֖E�Nq۠>�k��f9�'Q�rj�J[�����*�M���뼤�\l_�Ol.�4�)�O~���?_��4��ӷ$d���Ӵ�ς!5ӏ�Y �ĵ0-և�t�g��r���l͈�l��� ʢ՘�tv1#�4>d-�ˊ!���ahB�����MraR�Y]59�\��5Uq���������@�ei�6Y�E�#uIMꆖi3T���ͤ�ĭ�K2�W�����nN�Y�ynnVS1F�F�A��?b7R��iF�Ǥ*zN�DOy"��ek(Uʉ����|�f�8c������쌸�m�D�a[nf��l�8-f��H�C{��|�L"���#7�7-�X����|�ՉG2��%���W�vR@�Ub� ;��J=�c�_ï�h&��AO��¤�����PcJ6���6t�6)���=�^�~vf����f�0���͛6�J��/_$�.�ǉ�7������9�)9�b�C�X�H�t��� �����фGL�`zF���9��MҚ����2�z��H(7�&;��PíL��ŗ����Eᘩ��]kO�iRN3~R�2?��:-��ѧqP��=�J�%7�>�}��5n�a��k}�Ǩ���U9��ׂ|_E}��X��JU�"Q��"����+.̌*hM�\O��<xDI��N�)��E�l�Ef�%�p�� _k�[Ut=b�G�h�5��@���Aq�˂�ɝ(�t��`��@������UέǸ�V:�M�*K^&�m�8]n�+oӷI���� �fY9�.��G�G*/��84l�gB�f�qD&�B4}�efɭcs��:iじ�GW&�R斵�gAH\��଴�J˞�<.`���c+�MD4�� _�qi
-�R��)�OiQ��
-�5��!���m���}?�+�B� [SҬE�Zh�^P&�����B�t�(����<z�S��>�g�"+ED>'�q
-���h�WA~
-��)*�/� E�jcaQF���)�INQ�#�5�u�����If��dT�u@��R�|�V^�RfR��,����,/m\�95�&ekzߡ�GT��ˬ��eV�f�i�� �'�\���G�~{��^=1� �PVP���ImY�.�� ����5/��5���B48�a�����M��R��0]s�S跒37�u]N]�i��HeZi9�n���{�WI�XU���-䕼+/�jVʹ�1@iX�mB�L64��B���X>hҘn���+��d�����RW���"k�DS�^���Y=+i��y�b����]dx�J�]��Yet� ��_F�ӂ��!�N��s��S�ռpJ�^�Hį�ӗԚN��B��ԉ@m!Ŷ�[�4��a|���Jp�%�	�6N�i$�����~Ƃ���+�t];E�+kk���mR� �[���[�D�+?��㰽L�npFU�Ѿ���6�J�˘���R���0"ڐ��tq��cF�d���D��|H򶵢ь?f�i����������t�^z٧o��%��� Y�r|������'V�^L�u�6��m�WJ����R����R�~QA��
-�#��b���)��l+�8k/[�2w�9-��I^�S�%G4���5�2��/(.��Z!1�bˣ�3Zy�\����!����Bw��Ď/��Jʲ�)ʷ㽣�������8�|���w�)��h�1hf�ld�iy4z�u��~����FQ�¼b|�-�9�8�[/�e���b����)t!j�N���uAB�j��>W��j�w�����vԇ�5~��M	-�y����ht���&�^3�9�$�Ԧ0x=4���^�*UP�����.�͡���p;�m��'�7�7��'�oh��g�9Β|�c�a��>���:b�"��Τ`tK-�><�ƦmJ^Jt��㍌;���ϥ�b��Hi�&,��KzJiY�\�����+�GW6��Mt�b�@.�c��#7!��'�����c���LP�n�lڬyn�CTeh�?���z)QM)�OqԖBX&��t_Q�ôq2^�e��RF;譠4 �v��� EjC�~�#G�EC��gӪH��w�[�Eo�ܴ4��U7�B�-��񣑝��W9!*��~�b��BhԬ�K�Bo69&��D��ߏ_��ń�N}���ȫ^�1�iM��f�I�D��!QP"{Ş~%_�z'db��>Ƀ�Tq��V�M�rCi�C*6����"m�<�FE��^1�Q��F{]$�i�m�I���k	�����*N!~���!�l޳��%`8�@|�z�F 9����Z�Wuo~h��)������Z�U�����)�aE;�h'튢]W푢=SlՂ�`�VM�js���VĘn�fڂsm�]8i�&�[�-x��nްoڂ�l�۶�[�-x��o>�ڂ�l�Ƕ�[�{[�-��lg~i��;؃��N�`g{��=���f��#�A��{p�=86m�=��\ol�7ك[��v{�=xܮ��kW��5{pNb��,8��0$���2m�V���@n�Xp�`�]L�ʹ#,x�O��i<˂�X�
-^E�@'-8INтӴ�-8GӾѴ�Zp�\�Wj�J�т�4m����"���#r��-�Xv��^<؏kxp0�T�\��� {$0��e�30���Nsg8���m	�D��Ed�3���#��1�v�<�^!�N�Sk�
-�w�6ݥ�t�����
-$��+x��El7�WD����ɜ�.p��K��R���\��sד�fwp�;���#��Qw�;p�<M��K��bo��=�N�`��z����&x�S���	�#s���h�_�����Ӿ�.j�_�Y_�9_�y_�_�E_R���O������>�O�ާ}��:��!~m�_������~m�?��������q�jIT����[�B5��%p3.p+.p;.p'.p7.p/.p?.�j;�\��Ui\��uiܔ�-iܖ�]iܓ�}i<��#IO$��4�J�4�م�4�K��4:J��4:K��4��H�#��?IbO��=���V�z�(��u���o%�'�t	�z�����t[�Q-i���O�^]۝�4�k{�	"�?%]A���jU��ITi��v&�s&}��t)�IΤiΤ���I3�P�M�j�D���I��TE��r&t%QuL��DՑ��;�I��I�`/���𫞓��#�F� Oձ�w�IT��VxZ*v�+����RCyM�*�>��Z��A�`����!�Pu�:\��TG��K�ک�}�J��~�V�{=��<UD��V����jW��o,�2�K�\��K����TU��|��\�X�+ԕ�L��f{e���zk�Zutm��V���:X�Uu���Wf���H!6��e��l!�Vu���v;Yw�;���]dݭ����%�>u���� Y������zD=*�<F���	iM;I�S�ii���g�sҚ~���T���6�H���K����d��^��F��z]�!��7�zK�-��v��w�{����d}�>��Ə��X}"�M�'�S���6mg��KK{��fu kGK'im֙�],]��������CZ�{�ʛ���7��VG�����g����2 .���]Mu�-�������w���1�B�Z��ũ�g�e8\>a���쩦���H����na��諦�QG[��������_*����2�2a�[*U`��[qS��`�2�2�"j��J*��q�4r��iQ'(��Y��ٖ9�W������\�7:��8�*�|K�x�)�B�3q�+�,Ӕ�p_b�ֲԢ�g���R��Tu��̲�s���so�]%|�*�+���!�Ŗ5H|����������΂�{���R1�g��n�H����?E�l���uߕʖ�|�|m�Z�l��.�nQ�(�zi;�@��Q��.�&e�(�v%u�E�R�m�^��4X��C�]�~��HUY�~���SPrI���P-�s�CT�#^�!��z��P�<jQ_��L�W�S������F脅j�%���%R=�*�u���zF<�-�,�����s"����2G,j�E�wpz�\��#:.��pz�\N�g��5K�=U�[nX�����M��@��N�m����U~�E�+Lb��T+Sm��1�3���.�����T�����	̞�� cA�%1^�ٟc��25�ٟg����9_b�ef��R����]��_c�:�����o0ϛ��Kf�S�|�e�z��6s����3�s��9���iL����̞������c񍙽	�5e�,�m�\f�l���l�{���g���C���y���e���������X��d�|(`�B�>f�f/b쟬����`	�2ޚ�1^�x��rV�3�?g��,���L������/�m��F
-�9X ,��%���R`�X�V��5�Z`�� l6��-�V`���v��=�^`�8 T;���=wDa��
-��q�'^�z�(짧����,p8\ .����R�¼���o 7�[�m�p��W������{�y��۩��/U�R{ԫ�@'��;�<��3~MQxWU�y
-���O���»�6�g?�X�C��/��)r�vGl<L�0{��^*C��j�����0��+��A�`�s������0�����%�Z`���(`4�������rV�Ü L&xBu2ҜL�}��0g ��0g��9�\�}��#�p[,þ��R�ː�r�+v%��T���U���}�X�z�� ~#�M0Q�6��l��6`;�v ;��;�F�n���x{�^���~� ��pG��u�a��y��`�^�:������?�n�`�V�:�p@�Q���ZR���Y.üB~�s�u�q�	��۔7����~x <��1�Q�_yB����3<S;S���Z�@G���]`v���na�=���{��7�>��������?��`�9�`�_Cv(L�xu܇#`	�?�c,앱����>�D�M��/��d�S�O��a��?�~̹���yHo>��_s��\�� �u)�e�r`�V�\��X��}=�n@za�;�pt���`+�ۀ��w ;�]�n��A���>����p?8
-�p�	�����yO�?Ey��4�8���9*�`^Ђ���K�/#��Wa��:��M�p�w`ޅڼZ�(>����#�1ܞ�Y��������v�޾�[QO��@'+{����v�¯��0��=(<��c�'���_o���j������ ��� �}�>��1a��m��0G�m$�F��1p�q0��O&�a���S�O�9��̈́9��Vf�ce?���j̳�9V��U�X�<+����B+��Xle��F�.AL�J귰/ů/��r`�W¾
-�a��=T�0���H�7�5I݈8���-i�{u+ܷ��@/��}'�L�V�n`���܇��� �� �C�a��7U��?
-����	�$p
-n��̳������w�W����KV�\F�+p�
-�k�üAo�-���;�Qsj߅�=�>� x?�ܩ��?�3�V�~�{�)����PS��6V�̎0;����5<�N�n�wz����7��������́0���~܆��Cz�=�`$�G�ثh}j�?ncf���'��s��0� ,jM�Tا��k3l��,`�5��g�4�,{���<�χ�w����@�_�~}1�%�-�X,��
-�j�J�]My��X�u6���]~~{#�M ҩ�a���
- ��� ��nG��њ��	~�@^����~/���D�����a? ���!�0p��Oݣ�[Fi*��1��a?aco�8��o���_��E�;�엁+�U�p��n��;�]�px <��'���S��Ύ��: �N@g���� z���@_���Κ��0��Ro���k��aRы�Ca��F��� c��#���x�g"�$�L�}2x��� 9}t��?��/S��/Ӏ��`&0���� ��� B�_�\,� �K�e�r`�X��O��3�:;��F;sl�}+����v ;�]�n`��� �C�a�=bg�cv�@����S�i y�?��� ���G��/�>�<� ���k�% ��_����X�
-+�ng��!�� ��� w�{�} �l���G�c�	��Z�=�x�����c��K�=��t:]��@7�;��	��*!����L�߁� |P
-�� YA�p0���!�P`0`@R8&*��`�00)s,0O�:��V�A�'2�&3Ƨ0@�`&0��Ё�ٟ�X1�/����᷀1�B�xG�b����/g�U):�J�Z���Ɯk��:Ƽ�o��f`~{+�lg̱��/� {�}�~� ��싃0�k{8��$X���@�S����� ���%~�ˌ}�\#r�7�����o����w�߃���K�>�|@�!�GDy���ў��m�k���Xj>5�^�[�u%�n�uG�@Ox�"WtY_*�ɫ������0��Wh q����:�&�!D��8ÉAd$l��f1c).�*��2�'h�=Qc(A�d�u$�>Uc���	��Tgi�>����
-:a�<����MY��,$�q#���R`��5�K�0@Ő���)��k������F��G**�� e�k�����$�C#�m�@l�@�m��R��
-���
-�cu'� �Tz��.�"�`er�fB���{����G	 ���{�Ɔ)ǈ'r��I"���&r��Y"爜'r��Ez��w��e"W�\%r��ud�&p��������!�x|<��8��� t:]��@7�;��	��p�Z_�X��(� �(_7��c�A�A<�и�kD��C9Z�xe8��5^A�H"�f41��+c�Kd�vk<q�L$r��O"n2g�S��Jd��Df�Id��D��K�"��'���B"�����,!�-��D ��W��\�YW �J��"���8�%f��D6 ���ę}31[h+��,ۉ� ���."���!���>��O�0�9D�0��TG�;J��T`ǉ;�'�Sd9M�;
-F�D���（��s���`�r6A��:p�,7��"r���8�%�="��< ��#x>&�	��yJ�l��u@{:��HL'"��t�SWb���NL"=��Sob���KL?0��� ��tp���V��)�Ha��������%B�H��2�F��h!g�X$<�\FS2㉛ ���$ĘLS�L�����a�	�Y�l����8����j1�%�R`�R�尬 f%�U�`-��������I�
-���f"9M�&V݂�[�m�v`Š٥�������q�ab0F����p�R<A�$�S �u�i��E�s�r�la���KD.�v���`�s�ܮ�b�!�l��p�	������6Uy�11O�|�S�Y�9Qg��NX:��HL'"��t!ҕH7"��1=��71}��%ҏH� �+"���`b�&2��P8��e��D�Z@F9�4e����:�r�����3��*�A*���d�H֝d=H����(�@"�(�xJm���R&;�lJj�2���Hn���%n�2���Q��QE_9O���C�<e.q��Gd>2���-p�o(�y�Br_Dd$%���(�:�|�]�,u2�2��r'K]�dE�
-���`- �0u���`#�	��d�(���b�Jg��-Q�;�bJȾ���w8�Tl����p���P��O� ��D��a'[)�⨓�"n�r�	r��)"��g�l�r��y�. ��KN��d딫�\#�:�� ���m'�!����G�>�DyD�1�'D�'��3'ۨ@�ߨLS!¹�{V�YY`��b�]��NX:���t�#~N}L�\ ݉�WOx��S{�Co8����|�۩��2 �_ሜ����Rǯa�K����p@�է�8�)�DF�6
-�A��d,����>"��� L&��R'ÜB�0���b�i.��b[��[�Y��v�_r�]���0�ܮ|�2�-#��y.�M��y� �]*�d*�^*�[*�]*ƚ*�p�z����)�B�^@�"0��r�b�.v�q	R��d���Rdv�1�S���rXh�9�RYAYY� ��Yf��,�n=���m ����`V����b�-.�C���� 	��I�����������l;�-
-�1��`��z&Ƥ�G����1<��9A�I"�����b��J��,��#B�+�����r��E"��Dd�ˈ|���(J��`��p1v��)#���m�&���0�V���]r�G�>� �d{H�=/B ������T$�ԛlO�<#�΍""�/� �a�E6($�9w$҉Hg�M�]�֕H7"��������@r��П,��2Ѝ*v�C����P��
-f8��H`B��9�B�%2��p�@��`&3�������Sf�Id������2�����!2�|�f��C������"�����N+ˈ@a��쌲��*7s�v���nv��J������ܛ�̾��l[anw�l�]��I�j���!��x��:�SAv��Z-!�A�䷕\v�K� �Dhi/B�e��n��I�n��
-҉���}�|orG_��Hh��!��G2��Qd9@i�R	~�l���������U���p���)7�����,p΍~�<���)ߡ0.���
-��\u�;$��U����w�p�:��rFgs�TޟS9���r��F�_��䎛=P��}"x�����EA��<���'�}O�)�U�q�<xx������3��a	=쑰tSXBg{�t���n�X�N6jsz bO���}`�C���L���@"��&�5�!D�Fd8�DFEd4�1D��ϔ���yؗ�D"�<,q���'I��A��_�D�4{m:,3�Y�l`0��, zXgu�Ű-!�[0K�e�rrX����J<�ɮ�*�mrZM�"kt��,�l$���fD���d�Fd;�Dv�o��,{��m���ڏ���!�0܏ G�w8��I���w�9�}�E�����uS���
-\nx�G����pnw�{����uW�y|<����@G�3���R�m���OE��C���N��{���@_�?��j7�W����@b�@_3!�3��p�F ��;�(�VG��Xƒ#-���xX& �B�/Zsu���y��׽(��(��S���4`:B� f�������8�����"`1�-�X�� ��&`����>�n0{�����>`?p8�'���Y�<p�\�7�[�m�.px<���|x_@�t�a���.@W��������@�$�����!�P`0����O��c���O�"e�� � �nV��5�H�}�T&��c_��}�#�o
-��Ӏ��`&0�|���E�b`	�X�V#�k|�q�Ob1�����H�R7�|h���7ò��v�}�="�������`s��a����M"�)_���V/���c�+0w`ȴ�\��p��n��Z�T��r�������:�v���������Ѣ�xZOKr��؝ml�X6~�l<�1���M�}��/��&�F����b4?�:��2:�v� Lg����������@O����W��O?"����ӊ��8�dZ�LsD�P?��(ÁH��ʏ�&���ZwuS�TZv�B�&�B�:�Ϧю�i��e�S�F��c��5)�& �'��z.�Z�թ�M��>���3�N>'��G��(��7�����������],�iX�o���2`��7�
-o<�xz���h|��uB����0���X�H�9�u,[)���|�9s�v�Y�N?���Dj[U�YM�G��3�=~6K݇x��l�z�a�%ra�s��	zC'�w
-8�Gѡ���I��sd=Od3�@�E"��D�2�J�e�*p���4Det���P�����d>��d>���(�'�?F����)����]M����d������;��)�w&�s�Bf�8�-�ɻ�#����􁛽o%�?0 �O���*�/�;�d����u���D|N<��8�I
-�f6䒯���C�a@w�O��D��3HNh�z���1�H����uL�~l?��~8\�Q��q9>��Sx{Յ�?���q�?@_�~���2�
-L�3���,`v\������v�,���8$���Z|K��1�XQ��*x��)�+��B�-�]P���!�
-�����؛`n6��(�>Ǧ��6�lv�!^?�ׇ������[����î8Կ��'?��.U�:��7��� p��G's$q���f�~�8� N�����8~�ר^~1��y���'~o�z�����qx�VpW�z�Ƃ��X�z_iS�S�u����Pg|��>> �#�1�x���]�w/mԊ���y�[��<���j�1�-Q;���MF����q��|<0).�O��������QK��D�&���?a.�.����D�,�/ ����PF��@� ���� �t ��~( |u�D� ��F�j�a�5�<`q\� �B�>�����o��9�R`�xj��W�\	�z!����'��c�O���z��0���"k ��an��	�lf ���t���m@{�����s$��(�'p���'�V ���O�� �^�����w� ��;�?��f��aN�y����T6�$�a2�R�P�_n5�Vqj�j"�5��5Q�5�����Y��'�<�OQ�?���)�HA��]
-��9��K�_
-�{�/������ya^@������3��¾�E~��"��QN/"΋(�Q^/"�y	~/�+�/#�/#��x�/#�������˨/#�Q/^���_A�W�u������QiRy���s|x�������R�*�9%�U>��*��W���C���?��G���+����xt��4��S��.��^X_�0z����Q@�Z�_C��͈��7������ɿ�G��1���P�Od
-�̬���ɯ�7�������u�V�o��E�T�O�y��l��ˑ�.	 ]�t#2�ҝ�~��H�s�uyτ��WB]d��ޛ��$�
-��w?`��.�	*�l��ϻ���K]��q���ɷ"s���x��W�@`08��d���^�-��ڐ�+��\� _'��I�e�/�Є_"�@��q���~�/��耐�������M�K�����y@_tk�a.H������d`����Zm>�b�˵��{V�d��+��{�������d�>�z�Z�K��GV~Ъ���o�ZDڨi|;0ߦ� ROv��8�~�ם�V��d2��$]P�^MK��ݦy7��o�g����g�9�z�z�?�
-2K�O�z(�ex��T���x��y˷y�ۼ�mޗ�O^� ��0�S�,6q6ٲ� �F��`n���
-l�;��	l�e�QK&��l�9�jY�H�߮��M�|E2��p�-v?" ����Q��p9%��$\�\���o�
-�a�����)�3�,�sDz9��'���fX.R*�U���;�|�r�C6V�8��+��� ���k0o$ ��i�k�v�߁�] �z�<H�C�����w���w�h�;���|�'	,�}
-�g	��cM��
-�:�oJ|�wn+�@b}����;�����t�5��L���l�m���^�p�CN}��#2�<��g���G	�� ���
-���?b���:r�*���2"dRH"#�:��`2��vă�&��~���1��3��1od,%:�d�ΔD~����)+�-�,$���bx.!����T�h%��i|0���U <iHtU"�4C����4����y�&�!�:Jh=�D6Y� ���IH�,�ɺ����G[��C~��a3�QM�ۑ��N`����o��D9H�0�#D�&"�ǐ�q��H�'E�Sd;-~��Y"�(?�;O�B"�$�l�z�� `"�$�P1J��QR}���c�T������㫮�W}����1�|����{����Jb�
-\�7���i���p��Hl�
-���K�ӝ�?��� ��Ty�bKg+�0;��Ŗ����H;���=M�������w��e �S"�I����t��l����������������7��m�2h��o�rh�2hė;�1d���и��|+�~YΩ����{���a��x��x���(�4��MxG�T�e���6M�b����0`80"��`T ���w�d�6&�~/�j U2u%���i��|���f���E���5��\��a`�ڌ�4C܌�Am�~oj d&�q����`����b���3#�W����g�����~8���>�y0��������g3�"�/�P&���l~�����\�7��Q'$7��A�+���� �V���G]C�4>��|]�9,��eC��~ŧ�ŧ����$��g{��� s���<�����ߺ�|9��]��u����&�[��[�kۀ��ō�Ye��c秕�w�L�M/ -��{�<�>�_���yB
-`����V�a�[���C~��Q�_���_P�����~�Q�:��1�ǁ��t~�k;���o%��_��Z�)t�տ�It.a������e�� �}i��˚�7���i��yGOS�h[��QC|20�����C����B8���Fk��	��C|�5p�i���x�2�c�=���=Z�?�����~>�d���s�%��==-x/`k��)���џ�0, �E�V�T���f�������#����ͦ�"8�-�Q�(`�9`q�@T�95�QTQ�Dt�9%c�$�ĸ��]�C����|d���?N���h��d$�	�G�H~q��Бܐ�����Ȓ`
-&P'j5Mq8�󇒌FJ���Vz<�Z��4].a�XtT���#L���`�*
-��Ø��\�*눰QQ���o&_Mw��PC��B�"	H&K�d��.�&"���Z���W�
-�$�����9b��y=j��9��?J��c�*���%�'RJ>�Z��O��U~Hf&����E�#�s�V�>ɦ��U�-<,�J�*��!��:D��ŜQ���+&	Y�E�1�}Q���<�	�S->_̧l}��#'�tZ�t㏣EҘ+�OF��O���3=;�ȗg��?~�2�t**7��E��(C�SV�/�`ܠ�@ԗ�Q,�j�L:�2%��[z�Th�TK��H^,���l�%>��xU'ү�^%gl[�֐�b����G������D�R'B�p�PN�H� �)�
-�\�LC�����U���⮋�v�4�}��ч(V�2d�bԘJ}ӏ�Uj}1Ml�=�ԏy�O/�}Wn�#�f䫌tΑ�iU�-o��%�D]b�VlO|�#��7��[i{%lP5�4�á��zW��o�2�j��$D>tˏ}s��/4�zG>s���r?�`�`�CU=�RV�	nU>��lF�����ݞٱ:pU�z���|�\��o�W�O�v̷a1�I�Za*�U�1G�\�g"ŭ�1�q���h���6�]S4�V��oY�E_Xl~�kJ6
-ɭ<�z���g*�Q�;�_S�_��&�RAY�g�D�U�ޤ�ෑb��R��66�]�X��f�2�*��s��?�h�&d�
-9_��VdX�6�`^���`���C��:4T�gB���2�f��w�ԣ�(���hąYMs�~�/"ͫ��"O��</;pُ+����������������Wh�"�4\��-ҋF\"��o������{H@*�����%{����U� �4�"��糉nQ�ě[�w��~Gd�d�Z�|&Z+�W�En~���,ҫW�ɍ~E��Qm�XD]��c��*I�B?+�8P�?��"?�21/�_X���G����R��<��m�-�����C�+V-bjU�RI�{ۨ�?�p�ǍM!f�X9�)'����FL�9v$�FL�[��V�i�_�bYI��p��Է�?��������o���ݷ��ll�Ib;�I<�ř,��N�'!�$Nf�D�g�f��'�If&�D,B�!@�  !� 	;���A��7�I���TK���Y����=}p�ԩS�NU�:u��[4�r"$CJ�0{n���U2{��?���a�x�V�Y/8��m�8z�/lz�*�c������4�Wz�w��Jȫ��w�
-!_y�J��D�R�L3�(��W)�{Y9rF�>�\��<0�L� �����큓�>�,z���<�_=�����
-���z;��{�b�cҭ����u� 1�?��`� �2ɡ�/����s~��u��;�`$>��T���[.��y_��,��0�	��%ҝ�o�_�G8�\=,B�.�$.�u�?�څ������#-ä���f���@�,+0��K�9�t̯��^'��?pe��;`��{b��{2�￠sz����}GM�ﶊ�W�4����O�����y�O�i[�}o�Gq���U �yI�Ѓ�������}�#�5�ױ�A�gz	�:�/᜽�m���S���Q=ʆ�A�㑳��:�����#��)��x�o����x�n*��){���Z��v[���_���/�!M�7_����qy�H��_�_ ~'>ȍ�6�c?]�Ʒ�G��)����份A��w{] ?��{�E���ׄ�uo����! ��������W>:���'��v���Q�'C=@F��Ka�)�7P$^%����
-�C����g&�ԋ��  �V�5۶&�j�|�^H�s�ợ�}����*��TAЛ�Y��M�,�͠@�L
-�O�4J����4��jj����i=�K={�c���3{!T$��#`?R��/Е9�weu��7��m�;�{gWͽE`p/��1~�[�z�ʏ�I�x���i .��<�`������_<xk��yC7��dջ�,xO:/}�~��#v�Gmlݫ�^arb��R�����P��5��]������.��s�f��rS}D��`���Q�p(�Q�I0�����T�+����9~�u3���>��w����vܔ{]�X$M��O�B*������W�;�����ܻ�p��՜7�K��4��X$z��j����CR�/
-�޽��䍞�HY��,����x���='�?<��������/5�ȋ����G�t��<$N)��9��������!,�����#G���:+�>Ѭ���!������![�����+��t�����?�����Gu���i�64~?ҧ'�A����#���}� '��r5�����b�����^��xU-��(æ�i��9���wك�Nw�o?\�����'^��3�oݫ�x���s��������/�x�^�ãob�|��R����߼��Z=ш�}̞�B���ӧ��w�b��n�����aQe*��=�8	����S��ϧ���T؝hĪ�~�끿����~ �������T�����3͗ս�z@��u�}j=��b��^7<�xu�{pCz�_�
-~[��#w��}������?�V�=^���_��|[�Gz_�kt��}(.�{��8J��>��w�zo�O�~	�s�.�㋮���s�������t�	�z������Fe���}��&�F��mM�����������=������n�����������ۏ���)<�q��d�vC?�Q�<�2����G�W�]���&��k�U����U�C��G����ם��;��2�g�8����(B��m�$~��I�vfj��a�ƻ_a��0�2�}R�@��w��?�|(�l'8\�
-�)8R�tG)8Z�3�R0[��(���X���x'(���D')8Y�)
-NUp������L���l���\�,��*3_�(�P�R�\��b�(X�`_�_g!���O��d�?q���r���{���_`E�΢�,��)�G�E�>�����d�WΞ��`/����o�~!Y��{��9���翕�#��ٟ��d/��`��δ�I�|*�M��d�P.�S� ���,�ς==��o�$4E���`��� ���b�w�=7��M+h$H}G�Tt���/���d6d���b8^������J���cA�BbϿ�b(��35��������&���dd�2`�Td�>�ۓQ��頽>����Lj�� ��. ���H��w#���Q!��x��f.���!�N��sA{�X�|��|d���D�4� ��,!�����\��2*�g�����K#=�~%�9c}0��,����2��Wb0V�|_���|_�S6�*���{�����z7�W�P��f�k[��"�x���Vl'#]°v _-v��]�'�n�]�A��|/([E`��<$�P���)���y#t�s�nq�؇���e����lF1B�d�� 2 ����������aN.�*Gуy�?�&��l�'�b?�[�)PV�Ӡ�gP&"ϒ������9�����S����EN�O4U��:�8�#���Hs���#���
-���*�_�P��s�:�<��f�hd'�IDޢ�*@����w��Y�.9.y��l��<O���`6?�
-#D*�h����"�a��)0B<ˆ�4�Yr$Jw�t�l9
-p%FE�m|4�s"C�n�	|��Ru����H[�17,S�
-��"/�8��S���B���[���/�I�v���d���(<�O�^�T@C�iBMh��/�|8���!G�O�3P/W��� ��(J��gA�5|�j�P<�(��
-�ja^ �L�*����gS�|�h%P��ւ@߅`[�K}��;���M��o�%�uG��j��.����Q��g_4�W�0�.�U�/��A��� �� w�����7I���ƀ���&��bs@ڂ�N[AZ!�A|*�.Ƚ��wҨ�](��݁�=A�WЅOxo�Z���cp�s��F� ��#*�M�V�>5��Q�Q4�(���S�,sPa=o�y�a�q�AI�8
-xTC�o�ON�Ǖ"��y�$�*?�)�*N�-�@����VAq�95��QzE��������*m�L\B'�aE�c�Fr�IN���q�	�#�e�U�+��ɫ�
-�T7��`���E����q[��^'�~��L�?����T��Y��]�À�å�Yhs-!I�4�ȑ�3Dzp1
-5��h�qB
-�����r�f"wFd!̙ó���<�<^��y�R>���i��D�|�͔cI:�d�<O�9�:�x4�?w�{����An���	ν2���D���3�*'�W�J��)�{*�i��Pi����|F�͙�l� -b����(T���l1p!�C2$����i�(�j�C�	|>�^�]�yl��X �����"W$J��-,/�jy������� `3_��,���d9�L,�~��?+0FD#��`�/��"`�I�H1���e�����a����J�C�*�*���5�6kA9 �.���2^%��P���`�7��^��b
-���A�I�� ۂ��k|;4�;P�E�m��<��r'(�Ů�v���^��5h���/u�w��C�$� �	̾`��4]6�� ����2�J�A� X׉CJt1l`<珵�A�����0,6�A�vq�n����~�}�8���~c&Z�R�`���� ����h��n������A�Ċ�,]� ��@�#.��j����K(���p�)�$ݰ�C�փ��P\�>��zr��ǯ�6O\E�g�5��	�ϯ��*�%nH�N�&j,��-�X"nV�;��]���=�E�KQ�d1y��9��g��0��b6�ap&��U<��d������Mu9�|9R{��KGn><�d��(M�s|4(c�(�#y"��>���L�բ�$��!ԛ'E��!�Qs��M��CX�
-�\�|��`~$�����jy�8m�\�ǃ�UN����C�\m���`���d��)���Tj\#�U.3aaõihn�����3�C!9�ղ@��ٰ�%r�F�6�5����,��i�Z%�ht���ҽr�ޖ��E��Łb�I�J /���4��B�2��@+����ɧ�%d1�3��hf�\�q�Ke9Hղ휓K���e�g�2T(֖��EZ%�`ټoh��J�
-m�8�#P!�F�\��YIG�Z��4�^�%�!h�=]$� ���G%�Z�xr������%�Y��u��ݪ)��MS�r;����\��fk;QN��1���.��h��i{԰��X�є��E�-�N#�Uؠ�F��hM�xB�#.��\�p�v 6�J�6Ƀ�,��=x��GzV�?k�*ye��N�����j�G�>�b����"�C�!9x)��E�@��Z*��Nb\��S���N��΀rC�#�I�ȋ]�g����K��g�vp�������'k吼Q^�p)2'�E���6��=r-�Lm�y	Ֆh�yZG0̫P<R�D���#WP>I���嵀�B�y����(���D�Jل���{K�2���3�QV�U�=K�L�]5��Ԁw-�������\�6p�6p�6źm;r'��%/`P�˴B`m$��hQzO���۠�nɟ�W�V�[娐���(�&y�ѡgY����5{�Y��ӲCA �z�ݒc���v�n����XE�	�,���r\��!d���Pn��a��	`�!�Cj'�`�6)�"��WN�~���Ц�x�6��`�M���+���j@�(nmf��� �^{l��٪���s��XKs!{�6�U�<j�2ċ�۬��Fm>ʷj%!59B� oa�)�.S")�X/A�mZQ��^޿�����̐��l���
-�iװ(�T�OhK��e!c�������[�!r+��Nm�b]�U�9>�]�FW�-�Ym��&�k����`:����f�_�6�UȜ�6*I�Db�TӛA��*����	��i[T�V��k4�ǵm�=PuG��D�em`��姵=�G�M�h�����!�;��]��j@���*�8��c5ZZn�*�r�VO��ڏ��O#�ӚP뒶O��P?����H^f�XK�<d~��ѬØ,�	�g^GQ{X��=�0�aD�8��Љ�[h<�j'C���)л�ӀCCgB��i6:��y���[�|6���K61���,�9^ �96+�.�<�A����\�Wd"�@�H���Ks�	�˘%v�+4W���0�W�|��	�k@���C�:���=��5t���:;b��|��	��!z�B���bw�|B�= ���-���;� ����@��2t6�w���]6^g�c~�M�C#t��4G*���(NP��c�5����u2.�j(RG�L��г�����:]/��8e���O�?`�t�bzsU�X��)��?�f���x��&��k�Un����u�2
-\E�D(�CV�k�q��St���
-�s��"=:M�˖�t [��P�3��r� p�>KQ(,+�g+�BЗ�stu�D��N����:��_a!>���p��<����"T8�C�:}�.Y�^�a}(����k�R�*�HV:g�<G�E���d������K �A�`5�%�F��.��N�K�W_
-�}�V}9��C]�6����-��MK_	���
-����M��M�Z���:�fH�oF�`��zP� Юd���$��N�J�Ǆ4�􍘁��y�ǬC��$3�]��f5�[��uU
-����V���w���G�w ����w���n�i�=���{�.�M�xj�ph����m�w�:�����$����^f�Aw�wYN�}W��m�p`�d��}�'��C��p3(��@�e	J%�>�<�� |���G@)	�>8u�>z)$H61|p�q�c��X�K6�������i�2p�Z�g@�>�"��M�_�v�>��9��, .Xa���>���C�#~�"h��_D�ߦӽ�Z���g��j�2کOF-B���8�N:���w �n\~8|�D�jׁ7�o �4n?�Ef�x)|�b�.J��I��d'�]4Y�԰`��C�8i�meux��p`�1�#���=�Q�w�G	g �g��h�+��px��l�[�9�g�	Nx�-hK#���I��s�<P��A���xP�Bg���@���%��~3<<]�I�롛dc��������jL�=<���dk��Ai� ~=��Fx(�L�u�್Y������`y��������>��Q�〳/z*X�1����&��!�'U�W�C�"�����/�/��0�C���qF(��`��@O3�>�	V�8�(e�1p]x(��2p�/e�QJS�0�X� �76b�$�N�r0J�]/AݡF9�\c(�
-�Ì�����'�?a��,Luy8�F�a%Fe�1SX�+^6��m3�W��b�}UX@ark�VA���X����OY�^�vj���*����a�/�QPol�36��-h��ɐ[�tM�����|{w�?��k65s���G`�XgG�bZ�݀��=D;i�����^���Q���dg^~��5�S��RM��c�+f�F��e�5L�c���X��6��R���o��T�k��A4��t��9�A4Q���y�B�x�yp.(�-�����GQZb��<z(��'܎�g��'P��<	��|)��-[iJju�yJ��i�@��d�L^��_���8�G�կ��o��Qv�yN��y5���]���c��c�c8��X��>1�LŞb~�=��t�n2;����IKڼ�̕0V�J��0�ב��j��y+L�mZ�杠�]d����]�͌�j �ˡ��3�����G�4�&]e4����̑�����Λ�6ʀ+R�d����C��H�F洙�VHĊ6��]7s�gX�9�3<��q�o��0' �4��A���9�"�	v֜	�ͩ(�fN�jN�2g �2���s��,��,7����(�k�vp>pa���r2�"E�z�,�)s>`�YI�q�7�s�O���8"�Ƴltd!�3#u�Y6*2���"�C�#�@ϊ����H)��4*u���S��XŗYd8V����H2G�\	-Q����ZZT=^bjd)j�#���e�fG�r�<+R�_ȁh+��YXY��̋�F?�#k�B��Hh������q٥Љ��B&�N���3���"b�c��ID��#���D����l�',��8�,�T�qO]�G6�͵�B�l�2R|e���pVa���r�)�6SO�E����j�S�q���yz;��+�à��������H;�f٩�/C �7�K��K����k��Uz������A��"tQ�����"��d��P�tO��t?�����"���M��D�^g�<㬉p���F�I����@�c��{;�Fx�Q5F�7/F� ���=L:i<�;�S���?�/�{i}"�׷#B��"����=�;��~m�K���=�O�W5��>�D�+�R��(�AՓ98�cQE�Cj[���HT�9�nD��z�5�	�1cNȜ��1��"����d��ߋ�>�:E��:M+�:�������P�)���Ϣ8�ji�3ԃ,�c��㬋�c�6�|�`�4�j>����Ki�թ*_&�d���
-t\��u�\�`�R/ú	<˺8���cN�!Ί�6g�;j@�*xO��N}]���085	S��
-�P�o9�t�i�JC��`#�$h$ݤma�b�`���S��r�v9�ΦY�l�,G�z�	H��@�\3��X3qt��*����mǜ	�b�I&Sj2U�)��MP/��+��(�c�Y����4���I�:�Z�d�k
-�k*�Bk�|k�	�d� ^�ʚ	����cΆ۱D�INo���e�阅����;s�vۚ�j�l�� �[ŀ���׬�:k�k!$�6"(+)��Z��Zx�Zb�Ŕ?aU ^���Z� ,z ��Z|�U	�b� <g���V�Y��Zk �[k!�0�:d:���7����*���F�~�Z5�k��no6���- ݱ�^��Ջ��6�����%k`��S��.���j\�fḵ���^Տ�;�Z�f�p�U��j �m5���0�k�}��o2z�\e5����^����`��nI�[���� ����?e<k� �c��j��g�F�*�3�oZg?�=�
-���c��~�:���`r.�vע��e�E�Q(��K�ځo�: �X��W��&]�^~Ⱥ
-�d]���utp�uä/�n����^	�$[j��^�6�6��a�/�璻j8����3þ��v�p;5�3�=p�=p�=<���Ii�=p��QQ9���h��v�T;���>���`gGH����P��\�,{l;0��8{<`:��"�>H>(�퉀c�I�#l��ٓ���S s�J�i����g�3 �와v�h{�♍�&څ�s�-� 7מ�����E\�͍̋�iE��H�������.��y���m�� ��K#ϰvD���Rc#�`�ԗ ��.�gW ����/C�M�rP6ؕ�xgE ~%UD�[�WC�2{Į����"*]Ou����oWQ�4�7<�A�)�
-[a�F�E�怸��T�г�%6����N4h�����/�w�ۻ��:��D�����y�Z�r����
-o ���Hi�Λ(�����b�Ti���6�
-vC'�� �m��C�
-�-j��y�}-V��cGQ��>�h��3�
-�������5�^g���t���	#��>C��?��4�J)"�sw�>O��~���j����F���-���btz'h��6��i�e�v�d6B�צ��R�]Y|GЛ�`�.C�f�
-�r�OF�Q�t�_�Л�7T���So�<a����r�"sԾd�zlR�J;�
-��ԣ�a�3l�=܂�G%iTr9�k��j{$�F�g��C8m��n!��G��U{4�e;���	x��l��ӝ����{v�EG�����y���8K�$㑹bO ��u&vؓ ��ɀi����TR��s:H�����tK�3��@^A�̲���C�r�B����|.2#�y��"dn��y����9%�d:텀��R�r�.
-)��(�e/��-s!�7!��
-+�y�^_,v��a�C/=Np��|gY�bN;��h1�Y��^�)p��B�^���TRස5���x����Y��U}�G/X�rV[�1ښ���u�s譇\�ކ��{T㝵���Yg)#�7\&:�&�4�����;
-�����v�7ơ��y��2�ـ�zQa�C�#Lu��"��/��Л-3�*k�e�q�9��.v6ZU����
-GVB�R(�,[�T��;��p	�KA�jU��ٌµ�*,�fnT���Vnr�Qa�ۭ�����vv�.w8���qv�����٫:T|x����7\���iԃ��i@i���;�&�{�}��~���fk�e.�StB-�D�9`�S��`����nr��ba�g%�'F�C���Qp�8�~�;'���4��~���Z��Y�N+���I�<�q�B�
-)qй��hS���J���3�׮d�[���`wΡwĮ8�B�5�^����Bz��Coמu���N����p�͛�Rw��]����[hmN����� 0[���\^�r0�w�0��=eqw��J�k
-�y���F�*����e�\�=:�xR��]DC7-���� ��.gD��:��%�G�܀�KTYDN�,bL��FSmXD���p�*̏��a�_��3��0qJt8������4�i��;f5�Q4<Ҧ�L� FGΉ��ɻg(�	��hpǶ�m��D#^}"Ǧ�H�gYt�-��h.1! ��$Jc�$Js�*J�0�.,آ(���(�ʚ(���(�ق(�Gq��cE�fhe��,JsS�Y)�Һ]%'��$[��)�~�1� �������S��As�q�DCt<��(���໢��wF'�t(��N���ҍ�)��
-�':��X8�i��PW��%���.:r�3��"Y}� x�IV	��F_��؏D�,�Gg�ޡ�,��h���f;�s�ѯ̵����ċ�"���JGt�M�Ԗ���. �.�U�S��K�2�:]�����TےKlz
-YR�[��?� >�]�[��M�^nӚ�DI���&OR�g�+!�JtU��ŷ�k ��k�\��\t�����h��7�t�[ʅ�&P���� �w�E����9�`��R���VPnD���Zt�tw����w�;'�+����.���n�a��1�^������Z�[�u�<���n ~*Z|�� �r��ƖM ݋V�t1��Xw?`��l��zuF�����j�^��m����$�-4W�%��%��%�Č����]�~夭��S��=�6W���v� S�AA�{���V�m�9���y�].]�T��H���Ľh���m(��^��m������@�edv�W���d�����\�:�X��Z�7Q�½Ը�����]0-p���j�^`�t�
-V�v)�����6>H��wS�tw��������p����і������Hp�s���� ׸��hT�Un��\�{�,�g_�� �v�84��ԱYy����<0�u�9j	�Gf#:O�Nj䃴ٝ��NRp�3�܋�ҕSP��N��mOs�a�tg�c�`m���3u]
-��-P�,g+X����9�*�5XC-����E����n�⡙���G�C�G�
-�wHü����n�[{eGԤsb�ιd��R�W�rƀ��-C��ޢ��W@�p��KFrF"�ee
-'�4jw�sS����Gx�h�ͭ
-����u�t�]�]�(�@Vr�&Y'��1_�)��[��`j�BK�]rW*�X��2��n�y�v���G=�B���L�K3��ԡ)�r7�U�6:�xu0������q7;�a�n��[0i��w���ӷRM)�9�u�큜K\ń
-����19�����M�v��A�򼽎Z5��v�hs�W��\�^YW(s@�l�����To�do�C��y��L��{� ���.��>�;8�;�(�}�b�x�Ή 9	�L�`�w:��d�{g��Vd&y���@����.��� �KJ������^�"�AG�y_s�}��=㲚�+`X�],��.�+��e�M��л���1�!{}n��һCK!�{�����x�Q�1C��#�aQ5�~g6Qt$IS��
-�~q܇7Vx���`V��b�JDJ�{����૽�(F}���F� <��n����C�^$,ۼqQ���
-N��`��+|"JwxGq|��MR��
-N}�75ꘇ9��q�����x|:�7y3�3��1Κ=V@���YP�7�7i.��0J��DNyb�����7ʞ��Ǌ�I�)�2=Y�:x��n1.z?v��8�za��ӛ�t����Cڗ��~��W�W�Fh��!�,bfaWY�l���qz�覷(Z5���2�x�bq��7�/��-�*O��Go~�=�/Um.�쫏��:�.��ӷ�>t{}rj��r�4���-���z�h%HG}��c��*J_k�n��뀹��(}�A����5�l��F��T�j�>���g��jd6(H����雋�>E�5�5HX�f����H��L}���i>}\�����ħo�|�~�O_�uy�'t���)���WEբ��EN�t�9��O�N��=��i>}yqا�0j}:�V���s�jt�O��>���t0��o��l��C���ft��G_~������O_S���T�?	u���h�_����Z���(��E_���Eպ.A�����oW#�CA:�o�黭���`v)���w���O
-����C1�����B�O�&�����a>���t�_��F�4}O ��w����V���-��3��>���{kл]~-����3�:�h�_Uw��T�߀����Ya�OK�����B��Y�ӧM��F�D�N���(:���M��}Q:��4�D_���h���
-9>�^V���Q�N����t-P�ӷ�}:��.�:4'X�?
-�1�?�f���|�4�ȧϣ����]�߂w��>�?6�8���#ʈ����>���cQr��!���q�?	�҉M�G�{:j^�F竅z�?`^��l�(���^n�:�g�Z�G<��J��Wm\����f�.�>2�8*F���bk1hi�p��Kh6+��� ��X�C'J�Ɔ ƹ�������WPk\�*8gĮ�x�i��c7A�U�B���2w��������{AQ*M���=��M�u�0W�r#�$-HF���k���.6
-pJl4(FH�@fz�
-t΋ьL�e��7ob_��,�6;��I��vØ�Xn@�f��l~�?��vi,�U��8���9ϲ����c �����$���cQL�,~�:�XI��e���\��,6�c��/�M	��v�y�bLLu{^�Y��u�{sc��&��
-��&b��qhw��(�����l4�)���X���9�o������<�[bE��j����DNU�8��`���@�[� '��c�
-�=����b�Bw��-vs��K�ژVJ}�¥m})��2����!XS̬�}E��t�[��E �� (X�
-ָ�����l�k�Yk!�@l`Kl=��W}Q��Z���X��<�&d�6�m<�
-x,�X}:B��3ۂ.nw�c;T��_�]��#)�?�I�p�����=6����(��ۣz��/�j^��t[B����pu�����U{M����)���vs�z ��/���=v�R���+������3v�xu��Oc��{�}����s�/�_�#.�� `g�1q�.��<��:��']=����>8�0��	���;���[]=�s��������"Oਢs�d�wھ��6�~ߝ,ġV�R�^BS�(���:-Nmw���x5ف&viЯj��e��A�_v}9*� Y�1264>@�C�djhF��
-dn�8@JB��(T KC��2�&@օ��:�%@��v��PM�ԅC�
-4�F�}��P�H���ӡ� 9j���� �� �Bw�+4LW�==@F�Y����qz���T�M�y� ����5s���u̍���\����8��d��C��2�Y2cZ��Bg�uvB��P��	qwa	&v�{���(?������S=_kՇz~�~1Q8�K�p����/��˺L� |��Gz6�'t���p<��҉a��<���ƋF� ��a�,�V�Y���S�����9l��t����6�e�X�d.7*l��-�:;�Za�I�:�����f���j�ڱ�jc�{�����'6ٞ��fc��*7줤F���!!�4�xLڬ�NrV�r���(�cz`Rx)*�b�Q9�-1�혽��Qv����F#�c��Ð=�ԇb��0b;��F��	t�!��0�I�x�6��v�`�v���L�#�����D���Q�O�mL���s�hn�h��n�<�p���6c��G���ߌ+;���F���,������q����3�`�������c��G:�y��dy�w�(���6��v����k,�Q\4zLsp��+F��;W�E���Pz��]NR$�\�ƛuN,�n.AF���T������
-�����1`N�G�K��	�2L3�C�kr|w�y��<��[��Ƿs�ZǏ�{�Xx��ˉ�����s�iUb� x���$^���!��t�%���5h`2`�6�\�A|�Xh��M�"��a��ܔh�*\^E�,1q�&�0�
-3n��1��5����57��~l��oo�r��X��2�+n�%����I�Ƅ��6�n2�;���.���廩���\��X�$��PS5m�˅�i�B��&���}=&y�� ��e6bnv�5���馹���Hr���{�cb'k&�-.?�����F�`��n�'\���Q���fg\~�4ju�Q���ˏy�a^t�qOw�K.?��ّи>1�'Q�3�H�0'��GB���+.?M*^s�j�FBT�����-���N�������?�
-"lN�-���;O�r�("/:���;TKyB���U�.P���ڈu�g�a;��$�+	�vM�9�Zc-6>��bVbӱ�A�w;-@M�ڑ̳���.��e��_!=�<~�����5X���a,X@7H�<��� m��oa�=)��l�Mq���nc=y���u����|y�_�.4�����~!&��:�u��3<��ĵ�3�,+s�@W8qW<�'kO�58�䑊��gK�b}mN45J1�N��p��Dnx��L�Y	4/oo�����E'GYA�i^]�@����c	��x4b^�! N���Ϧ��q�����7����l�.a���x�r}�?�^7,3az��}
-�xc��+Ip�'P��*�=}S�,������^���p��S8��C{�|��k���D��;�3^h"uv��'Q�$&�0TaS|j�����c-��4X�>����g���I�������H�Z+'��<m6�Z��B*�J͡��#�z�t�ߦu�s�l��<�i&+򙞈��}��"�����B�C�����-�v�u��ǋ:�5_[�̫�z��!�ao��|]~|�^��ozsc� g+�%z�@�芘��Tۙ��Rq��˩{=�&��-�U��˥4$2��2�1!�XM��1��O�'b�r�(ö+a �c+|����Je�����U��k`Tgb=�bN��O��5�>˳���y.�
-�C"��c���3�	�=��D�/A�%/Cb̖b	Rs��"E�gi�J$�Aj/��s�j|ZHc���Խ��r�^Z���4�g�����?�4i\��"}lR��C���?�������"��O.�~���%!~	����x;ҧW�x��o�N�،c	���+H�lo�_Eڷ!į!}�9į#}�p��@��D��D��l��B���!~�s�!~���C�.���=���.�F�<U��G`�C�����aH?:A�Ñ~l��]�}|��?���
-u�����X�k�/�|���OT��y�}r�ο��O��s��i�Gc/_��F�|�S��H���7!��0Jc��
-�zd??&��~ai�Dc�2�/ ��"�Qc_Z`��k��e�k��_���=��ƾ�`�i���ԁ�_c�5�Nd_?e�=H��j�ƿ>������&߇��3L��f���r�Pc߮4��i�;�M��ƾ���gP��j��E��[Mފ��{Mކ�u&������	��0;��ф/E�7�"|ҿ�ዑ���_����_�tpI�W"�qY��A��$�7 }{}���a��1«�ws�oB���S�����ߊt���G��[>��2��ǐ�ǙV�������M���[�� �����M���2a�����?��/g��B����~Ul�����ͯ�g��p�g4��R�/�4�oK^���+���s�&�����-H����ې��~�7#��S?���;����rx'�T>,�/��p�2�gbS2����>)�Sm���Q����s���K�k���`��_��h~ �_�X?�j,�综Y|2"Y �|&BY 9���56�7�|���\��x:��8��4���+��h|��(�����x�W�5��sl-_GD�7x<7��I�ڃ����Ko`̦ "�SA���O�­ ��3@���� ���������
-4�" ��e��Xc��� "�@��s>_d.��� �x��)�W}�^c����O��������g�,�3c|������/�E1���W��X ���[c������#�K���1���1���|_�/����[���_��h����?̠��5�>%8V�Ko�j}�R^���x(De��2e�y��l�}�q)	�bO�x��\�}�qM#䕞��(�)yD{���w{�\�B-%����]�fO�*��Rf�=��}Oa%
-��YD����?�)܀�pJ	�~�S�˞(4Rʈ�/�~s�K@%��j^����M)�5u)��7#?�yi�E�œє�����
-x�qwp�����6w�9���s�����t�p?������V����O��go�v�q�:�&��_<�}��+�>�>�Cj	HG]4�kj�ٚ��/������D�z��#�@���'��\����o�4#}��?<�qH�������J�)�oB3#?�y�o�Ӎ�@y�q7!W�����q��)~�yo��T��ِ�>*��f@Lg�õC����/�&d�&����y�#0<��X�p1�A$o��%Ki��e�!�ݔf9�����GH�����Q�sb�!������YJ�<���fb����-��~M��+R�������\,�K)�����)m�-9i�v?y�T�� ��O^��T3�yƈ��!;����cCv�ɍ�J��O>��=~�� �/��|SBr��<C<ߟ=7h��!j�v��!O�5Z�H�@��?8�EǴ����J�>�A�'jS�?�~�sC.�tR��r�[/&�8�����|P������L���f���ݵj{���Z���G�V��emJ;��;*�"fb�[E�^� ���{����V�*C�|,�5/�9���A��T6Q������k^�}�o؀�/}������:�?�L�_��/HE�a�-�G+�9u� _�g쵚��%�V��-Tǒ^L�_O��ֈ��v��О�~��Q���=�AÙ�>E��Ѻ�FS�(�6)�E�4e��V�6(�|��MB������)��T�5�q�pr��M,�Xݠ��g0�ZXC�Cn/F�u�@�3�>�x�Ҕ6ޣ����a��9�tȈ받�!S��K*�` )�EO������d���!9�q9{z� I��H9i������1�̏����+�Xr�8��܏N��ǄO-$���	���t��Z,�&?�l�>?-�F�*e���Ԇ�v�ф^:�%�m4)5��P�J���dS��~�j�8Z�$��+b1��߯���C�}0�/z�5?ɑ���yO3f��<���~�����3}G�}{��(���?�Յ���c8�;A��<�Vtp��'����n+���w���U�����h�?�?֟���b���x
-MTJ��+e�,�j�j��I\���x�K���7��w5�~Yq9��Ju�Yt�zl�o���I���_/�q�'�A-���=���kp%����!{Bj���~NN��2�)x��j5��´���^��0�I�ٛ��� �PF�z1���C5Q؋�����ۣT>7�M#y���,�ŽpVQ5P�V�W��j"oj���_�v��h�Ki�j����TS��Ck���Օ�/L�2��W�?��Z�����2ߧd~����[߫�=>䰟s���/��l��-���x�WE���5�M}+��}�Wx� _����X�>���XM���2�8�0�������+�6����+��)�cO+�[��ځ�|ޟ,�xw�ݻY��yZy�/���zZ��Q?�OLϡ�>��OWt��뮎������a�%�0J$D�JU�}tꀹ��/�;���"&�[O'��g8��OsE�^���E�a+�5���pĪ����������~��P��/����狂�{��X:t�R$�)��,�J�^�3N	r���J���Hc���w�S�;��P��
-����O�"���/��~q��:��wtUޡo����_��גx_�	�Ǎd.�d.IE���z�Tyַ��/�Ɍ^�K��"�^M*M܂O��!rCN���`�5?d+�C:�=n���|t\��)��Yox��<�=K�ʸ�g��Y�t\-��"Q� <+��<�:�	�<䌟�4��<�!����CZ���(������I���:�
-!���WT��(�n"鏽�,V����v�Zt�$L<uD���������VD:��aFy�n��[;䜟�Mj�Y���j��Nu��p��pSz����Y�/;�,Q�xgZ&[0�[h����l�6�Ǉ��ı!�QMUq�jpT��8�^�ju�c/�g/MϦ8�a�ج���U�6	6=i
-�'7�CF{�YD�Z=,i�Q�Q=��j+4�T�g��G[���I���c���y+�T��T*6��T�ቖ�����(�J�ר��!%{k\�54�T���kc�Q��O����ۗD�������5�5�{<�%��.9��o_���(���q�hdv��nFd���8G:��+Α��$cw��*���
-WI��8G+ɨI ��d��9��u��9��:�hK��s�V����qj�1�1�ZiR��K*�~o]�p��>\���"��O�-�4e�L����Ɛ�/������(�e����(M��}r�����
-��'	%���I�^7RKT��Ҥ�8H�$���ޕ��x�����.�C��׻�<���\��lQ�?T.	Z���k���p	��Jz��RB��-᪌K�*	�J�Ѹ��=�7���4����B}=���/�l7+���s�y�q۬^�퉸�;$�d\��@R��q���|*.�4	>|�G0������^���W�̝���w )U�<���ָ��$�����>�r�(˝"�4j�0j�=ϏAÓ{5|>�pՅx�e�Z2]��.��S���6<�W�����T�_�>5���chi����qL/������yURd��p,���W��ԅ��՚x��*6���|���M�Lq��Z졕Щ��E��<�	�u�O�`P���{�g����`������[���~�:p5ށ�Bu`����:pM����� ��'�z\�lX�l�7T5�T+�/�B�)'p����M���Mj�}n�?���P���vH�O�ӷ�R���[���[��=��ڋ����O}�1�L��C.��E��867$" ��_4���,h����h�
-"�+>Ok�}1�x��j��ߕ�m���^Se�r'nC�Ȇ�Ƴ7({O��*�z{C�:�o`>�oR�D�ƾ+^}&UO2ؽ��}�Z�@Rf���n<��� �� �[���C8�ߓ/N��!���eJu�&zd/#�Ä&�=�iM��A�2��"\SW;(�뾻�˰�2����EI����L}`��R.J� s��M߾H֚od�HkL^#R-���� 9ί{q�?��^��
-��W����t�c@�0�Nu�瘨���9��(k�c�)���D6<U�S�T�z�YI�$Cn���H�3�⧢�S�f��I�P������l�oz3�Ή�ތڛ���8���U����b��mN�gyrp3.������F|��^�U����7����󮙥�2�2`(�l�U #����eLZ�ȶ��὞̾7����{�i^ϛo��(��$*	I����@�]b�о��7��2B !	о����'�ͼY�����f�Pe,'"ND��8�ĉs;�L!Z���$g�<�#Nd�D���SB�[������,9|;ua�֒RZ(%�GN�.`�uI�P�K!ivI(�	Y�l�$ Ȝ��<�iRVی����6O�NA�F��|�Ԟ�Rn�ɚ�G�3�����͠�a��1Y%��ĩ�"�[o�:\C�:�4h�J��E~�Dr*6�/iDr�mflC�|�Έ�w_"�8�,-�C�S����Fb�7-��S�����[q��da�&��&����^�����7��ݦM?����R���/IR��:�0�l,#�$89�h�	>���]�<��Ъɺ"4.���� 4���9'w�7��el��Ҫ��)0���r��\�K���$R@9&c�����k��|$d��]\�In~�|�lT�R��p.>�B�^-Ky�R���,�����X��v�X)��W�@�x�o����J�;xA�0H��r(���^���/�|�������r��pO�"ꉘ����q9�����%<
-��k�+e9�n@��eI#D�ȏbP�n��B���@oN�vb�%�;h�9Fr:�X���j(`��"[m�8�H*X��#��H��l��$
-�XǜL1���ϕXY���-����bY����ۅ2��r��Z���.
-�ҩ�c�tՈN��A�7�N�͠�~+H�Q�� ��
-����m.�fH��۵��o��o%k��*�����d-0J�ĉ���:�;֍����(�r�щ�(5�S�������?��r�(�Ϝ�6]$����Z�&�'�nH��	@�j��jll�O4dL�˃��yP��ȨKv��{����@��@�)��G�
-xX�T�-C[#.�re��c��A�8f�\#Q���B��K[���,�{�7�p�6�w�@b�����9��)�68,f� ���d^)?�IuT�����Fg��\�P-\�x�³ͻ��b�����#S��s�Jz�������o*�7h�GLe�)�~� �\f�!C0�O�#��ٽ�tg$�;`)#�=Bv�i�ڷQ7��D��l��~3~���t�䫢�T��+�|�K.���m/r��@%7ȉW��+R`����rW�w����K��k�$�^�y ��k��1!���%ks�f�e�T}�U�6ҵ��!\�3��v�X�X'Ǥ�1���;�MO(q��nϚF+e�!	01��DpN��A\>�w%�֠���aH��~�=��1NdP�К��1�a��<x�����ܨ�zoGDF�SУ�:�ߦ/��D2_H�/����īR�U
-�%&℟H'��h�^����5��X-9���%9��!�&��:0�1�.�����/ȸh,������:
-��h-����ur|9nC7qC8K�bC�"�Slh7Ԃ����L�#�ɮ	'06�r�����B+zp����7dk�l�WfADda�1C�,)�pΑ����̑�1Y-fLVq{ލk��	Ke蘺3K��Tw�ݙ�r.�Y�fF�g6˅��퓬7ekK��|Z0�wQ�X�;sQBƉR�	�b�qB�)��q^�e�W��k���\r�L�[�#�uR�^Wz�ԱX�S��Ř�?����8�]-���i@A����ޑZ (LQ�STL�s�����,nR��o�Uί[5��.nd������` �8=�!�����,C�&�)Z�;�`�rV���i�iU�*��r� \��"U�ڣ�b�=/+��~�f����Z՛Z��^l����1��%jd�8�㍟J<E�$��V�#nDK�M�y-]���)ua漜��	a����+��JJ[��XI��2���n9�[ƾ�B�r��:��y��r�M����������+=��� "(�P������R��ye�t^!��=����{�v�z�M=�v�� ���6�c%1Y�O�YN��2&��0�"v���ݦ��\���
-	��X�Ȕ�$��*�'�"�y�_$'+����n�տXi�����(�#j� ��i�j�V�B�� 9 /5/���5�)���S������H��6��6%9�1��2��y��~sP�(��%Z�7�y��%���`c�-oKNq[�0��aa�������(n��7�<���4mxw�Rߖb�%�����Q7��W�G�hw��l[�<�dԋ��O}?�����5��ڐ9�Tyri�/�"��֕�7�H��g}!�=%p~(�s�r�3��~%p[U�ݩ6QX!�v����-EV(C���C�/�C_�-�L��XM�cS�i�������g�y#�WƖ�`!*�"�1\��:�q��Y;2�5����G�:N�H$G4�e��qp04�v�8:Ʊ<y
-i�Q�΢Q;��~��.��t[�
-�~]
-��2R��%R��'T�������R��hQR��m!��e�,)��C���^�h�p�LT��
-1^ݬ��%�PJ��1\��4@��M$P���-a��c4�A�,�������rm�n�V��4f��Zۘ�n[�Y���@g����,(����4)�ҭʵ�Gt*��I�2~*�
-�##�����΀�	#��T��A��o��۩P��r¿Et��
-�㖪�^$��Dg���Nr���?E�����?���	�y� H��Z`�;�:7SU"�.LJ���x�r���}YV��y���� ��tEj���	��"C��LJ΍ԋpJ#�&�{\k���NU��Wuܜ[�/UK?eП%��4�<cė�J�_��J�N�z$M	U|W�UL���J�)���?4^;�s�(�f�h6�f�^�4�0J������
-/�xnTK��0�֛01-W�5��a��y���К�>N��}�����(N�!�=���rr>�^n���k�l��I�r����������z����Җs��P�U���M�-��T2E"ޮq�ϋaV�sh���
-��,��˿G,-�o���)��s�
-���à9
-�(�
-*=
-$�p���xAA���t�_?����7�+���F0=Es77�a��Da��`Y ����S��^��V�"�r�Sd�>j1�P�.t�zV�w�3�e�øM"y�8�c�e3;�hh?�^,��Sj�z��^e�Y�EQhkV�ͯ5��ɷ�K A���h��6����:|��w-��)mm�@y販�}y�����|tS���̅�����Z�:6�m�PxU��+�W�^c�����԰���_�*��g�>*�-lM���n�̈~�(�o�OKɝ$��$v]���4�N��{"�tB씅�RA&Δ;C����r�;�k�<��lX���Ј�
-�}�-�٪V��֠��>���$:�S�+�T��I�)|0���2iԸ����5�����%O����C��I=�j�0�K@d��
-E�e!v���-v�!�W�N�#B�u�l=k�᳆��LT9�$RP*m���<oH]�]TِY��]c�d�JB+�4�j��5pDxչE=0h�su7��/� I6�!Fb�)��O�LG�C(!"�E���6�u
- �h�.@���C�}-(�`!�ZP���6���PM��t1�6){[�C���l�!�~.H;���2��B�e^W�o(�U��Co��QL8cGI�QTA�j�
-�)��R�*�J�v59M!�(3�1���#W�$��I�͉�'��*�Q��㯈���V�VNn�}+�Y���qGfs��#Js�^Ix�a��G���Q,�X ?&c�ڡ�[[֞�/[�%k�{_���b�jΒtZq3N+�>
-�}�qin����Ǎ
-�7*R�;����'i���ȋ�P$ae_�4�ڡ�'����%�@g��K/`���w�4��3?40,�g(�j�Nd�㝊�dl3ǥ�H2�������Ŏɲ���ː�aR�i�A�?^H�T����ҏ�����s�u6�*^l�T	����^,EGQ�w�[�qA_�hȧ�E�/Np�1Pմ�ַ~�����}9}%��#�6ʄ��&�0v�!�T�U���9��r�L�S0�N��g_�r�RHo	��Y#�K�^��H��CKe�Fa:�DD�*���H���F`Bk0��)@Lۻj�TZ�f����<��v ��K�NH(�R�;�=�v�B��ӹ$G��b=�B7ʠ� ���F��r�`��#Ǌ�C=�b��� ���m	�����u����������:B4,1�xۃ��`��y�Dh��&�xZ`��o1h���J�����Mla�<L�D2�q��x��^z�ED�Q.\�6ϭo5�m�t
-�����;x���t��l��qU�㛃Pq��;�ٴGTv���+ت�6�f��'�`��No^��1:A�Ȍ٪�_	F�{��#���nTg2m������A4 �9��_	:����T(�p!�X�TH)/�P���4T���JEha�����1Q�x*Yy��Ȇ^ȓA
-�������g)V�8�(k�*��"�f�XE��:\k����J�DR���fDߌP�3��@iJHo'1����w|���-#�-� ���8��yŰ\�E඀(_�����(�_�js+�>�=
-E3wP��������ӻD�ƙQ$�d�ۢ|��hE� �tu�J���P*���6d�H��n���ڗff�F϶ю���78��t��:Œ
-�q�r�i����I��b!�R�luf��<� ��ՄS��*sk���*��j�f�Ws�����G�S~�4��������F3vßp'7�$)�^J�b {�D߉P�c���^K�����?V`���{	��F�M�m�h��'�s��QJ�-C�$LB�)e���*Np�R��1������tC��i����k��Bb1�:@5���i-h�����\�񼁂:`�G�oq7������\����㱷)V0�	�Xeף4E�,�H�F0q�j�܁HY� E#/\��X,����v9���}��7�:� fo� J$��[C�����e��F�5
-�}F@���"�g# �b�1�Xn��o�5Z�]#��3#��2���*��Y"^W���[������I���d���-�!�� >���d��I�g�A{�O��#�P[a�-a#N��x4������W4d�� ���(���r��V|�������g�Yɋ�r_T~i�NlI��3���ş
-�|���!����.{:X6c�d�"m�f��-9�0�!�y{��Gi�1Fo#�6��oxY��\J�#{�D
-a��\��ì?�:O��j=�p'�S�n�j��M���?Z\�����M�1��pm����`����.&+bX��~������̪Wz8�4�$:��`�lu/��f�+�R	DN�ᓞX�o\V�����ǖ���n7�v��7~�v?��#�7�p�|B��B������	���I�U㟩���#���=��<T���>Q��%wG�j��.��6bA�;�_D���p"�8)킰?:N\��-�j�9F���\�|Ǡ�D��xu�O���c4q<2N�B��}8/���q��0F��am��M����2M&�1�:�Vh
-l4J�PK������I�|Tɶ�:�T���f�##z>��6߾DK�9��ȏm�f��c��a58ẗ~鱏S�i�]���k�F��ON�>-J�1�"tΈ�o���E�a_��v%��a&B��"�K��J�]2���5����v�}�jj39����9�n�O���~B�&�v�Nkӡ�	��Q6煕����u�x��;�0���������L���Ȑ$����=�V�)�t�[TlWx�l�Q|b�𥲲�k�"�\zMu�5�LO6�KU�_�m��/J�`��W���l���+'�J��cG2{%ʈ.��A
-4�'��z�B�y���D��Py\~3YMA0��L���\�tr��$e����$��#����-$��D>O�!Vl���M����*;�7�k|z�/�i_\�ʡ���9��L����#��(_i
-��Y����q�C��b�4��/��P-�OJ��)�#�i��j6���������u�mm٘f�@��P�:�Qs9$�!�~��"&�-qF�>(a<Ψr��έ*/��%�zi�i���Ӳ*���ʍa<�(�Q?	�EuÓDfO�/�Db�Kg
-� N�==�E����� rH�Dx$��ÚG�� 1^�Д؛ mb��mrs��X�~|p�e�9��Rnqm��˺{K0S��]�0�A���L�+�srB.����o(@սP���>š�?l��y����E�u^P^!�9��爓w���	�>�r�c����-8�n�dZC�[!Z�y__�=j��*^�c������6ukh�D� �$�g���8��q�o�������H�	\�V���KOU����N̂H����2��*RE��t�~���/���p��a[��ұ�@F���V:�����^�S):M�\2��e�Dl4�l�G��B�L��<�Ɏ۟jn�a��� �sY'&�f&+��`�������@F��.�y�z��C�L��D��.F���r-V9R�	�QM�P(DYy�!�����jk��\�-��!�Z^
-#�A(If�"0�U7Xw�5�'�hXEW���a����u"�r��E-�Z�:U��0�w�B��Ft�LY����!1���>��F�g���ç08)/��osY9%(�uC3��z*��/\Q�yNvK�bؚ׼90��yg�*��W�5x��@�:�hV8�
-w4����3<r��x�${�L~�3s{����W>��K��%�J�����U��� ����^�!�;�ཪ?�)�C��8���l�����2�"1���hH�yH����(��clA����(�^��d?jZ8�>6p���V���~��YPS��3̀\����ܯ���J^Q��V��y�/�p�ڗos�Y�fڣ<߲��_ ��[�Q�3 �m �����o|D�X-x�Vw�Z�6o��H��V��2e���{y�nSa����|�тq��Yٞ)]o�����u{�/<A�&D��.&* �F%җ(H	�I��4�%ɸ�ogq?WԆ}!܍yO��#A'�U�ŷ���$F��t �J��Ɋ�V��������QJw��l3=�4yR�ek��$�bc������ô���pr�#�@����G暒��)�V�����K�_zY�S�?�KX�у���bn�X�{O��ZT�9+���x=�3H��{͋w�'=|y�4,·�Tk_(g�_�����O��%���l��'=U���k� ��ּ�h��ےwit�ֻ4�OP�%�ys>�w����ct$��Op5���(�y%4WH��	��P�����==O���V.Wo�v��v'��-�L�F�t���̮b��gN(���v��5���s���jFq��:<9T\����Q������=� w�#���7%\u5�	��J�?Jx����h�-��0�ڟ$Ϳ��@���3�\OGd��1��[��1ҝӤG%�d�����/����LES�[�^���R�ӄr�H�u�V��/��r���${����|a���L���@�1����M|FP!�����[d���,E��|��,9����2I���?����KI�q҄~�������gȭ�z2�&���N�ge%C�	��U�6 �fo`��K�ސ8q��MPe�vq\:?�oY���L���c�M	l^*�B�'��|�Y�P���P��ޟg̩@\����	����Vզtw��7�˪=PR�a���n+�٭{�Ntݏsf}y���W�s�*��[t�r�s�g�1M(8�󌲼�&{b�:{��<XT4:�g�x����vG~ۛ����)�� ����1�i"c��[��0z�K�y=�l![+䱪�U[��]ձj�b:X򊔆�a��=�H)}���b(��Ki)p��������Z�(��?伣��d�u���.n)���$�W1��D(�"�ŗ`�C�1����؄5���FhQ�k�\|��s������*	w:�q?̛���q��Ը�#�B�Xf�C���1�����E�|�[�4;e�R��V�~y�dQeS���U�nܺb#+~H;�
-Ӫe�ei��GY׎��Q�:	��� �ˌL�d��{+2��k.T<߰K�9�t�����C*^�)��٥��G)�*3�=
-��~ϰ'k�Gj2'��u�VV]��d�/G��tw�.L� ��	p0ˉ�+��(x3����
-���U'�4�X��Je��$G���V���DZ�k::U�E�\n%^�%���c4x�r�b�W���j�sLN]�\�/��VM���Mj'�_�=��k�;=/��k��5^��Z�h$�>���!ri�s���]��ZeկK=����]@{Ϋ�$CΫ���X��Y۵<���G��k���.&0���us5!xNU��<��Yڕ+�p`X�������~�)��.�8YO�N|�9��<Mk^esȧT�3�֔(���f���xL��N���/n���W�h� 첟cL��JE>���� W����gj��D�oз�w����𫒼@��?v_P��
-Ώ�3��Nv���ܩZχ�6���bχ��s�lm�]�>_���E\6�۲b�э�e�Ch�`Yl*B��f����*�fN����[�&ax����9�I�om+BC�ۋǨ�chtG�#@�dN��#51Os���g��"䛀�͐p�&A����h� ��rp3 _�������� 7�?���L��z�Xr2:�Z1�$*z�+���]jsf��|��{R-s���'��b��(����������|��*�
-�sű���}��s�8\�V�hE�V�hc��؊���05�E2iɗ	��Ux}���J|D+�d��B��Q��\�MuL�+���y��������ѓ>.O���H=����}����?̡��h�@���;t�TVA�J[P%oA���8���X��eԺh��P�/v���	�ue�S5k@���-����8O�O`&�1��nQa7�s'����e�F'sr��ؤ��nR��F�	f?ס�F�9���&�|0�v��x�|ğ��ǁb�-�����[�-���+�a��N?T��N*�>�'��%қN�we�I��2g�A�7�:2}x��������Eқ��ff�����"\՛8]����^�im뱑~I[*�؛��Tk](=9�C��!!v!����2��;c��*d���2�]�1E�t{�ΡI�=I��u�]�&��D=�n\���?�Wʝ[�O�A�y���)�5faV����@@��Ewe]1��Y���c���[�&j��2�TJ�`���}N�������N�%M�In�$$�s�7�I9�i7i����c���zNbo)����X�~��q_FP�9�y��Ed�?��y��1~��x���]��
-�����T�Ω�`H���k§�j�ٻ�]#��,TT��j����gT��7�Y�\�]%ܷ����Ҁ�R�po)����~���*��S��pVsRQi�L����M:rx���Ӭ���{[������ ��8�j挜|�*g��C�Cj���);D�,9k9$���:t��a�r�W�SE�َ�%Q)~��%9�.IJ?C�O�����O�v�:p���Bz��|}��}s�xΈ��L�A��D��[�����4/q/�WχQLx�9�Y�w�U!{L����s	?�<����	}�o���S~������>Y뺯��X.���]%�a�{���y�~(*�*��yE	VV-��/�ת������F<�E&�v��pz�*|[��7��x����S��Ti��� �\r�
-� U.~�Ī��*��$<vUHʮ
-Ѻt쭸�Q�!��ثC�����ȴз�_(����-�[�{QQh�)7�[m���8$�87+�ˁ����T|������l�7��aMI�4{���k��F�e-�ɏ]P#)�*@3�����;̧�N�=�7bk�����$�\�/'��Y��K���R���:���X{�F�8&�T
-f�T�u��p�Z<�H���]R��W�҇�uaK�Ia�G8DK ���ּ�~D���|��([�I�)(Ց�FK��u��W'g�Qs�46�:X&M�R�TA��Hr1�T�u�I�w?�����s��h�@yBX�U�d�[�N
-GՍ¡�nu�8�w?����$	�V/��؁�,��$k�*�qm���[z`����R���[���
-w��8܈{��Rj췒�+�M��T��vB��=�	�KE�3o�:��g̸ŋ����ՠ�_��|I��g�
-�^�J��U�'':�X�0��s�z>N��Ǵ�cZ�ge���'ܚ�F��Z>��Jp�1؀F���)��ث�+d�:�6�Q���iWa��5�Cr�"��nhql� 0���9���*��.��5��;�e��q�����^��a�ʺ���m����9�����\W����NU��u*�OM��0WW[B��Y��0U���D�O��~�v@�%%�xYq�;��pk.���xZ�5���#�U�a�m�
-#��0�K��(î��;7(`[�԰�D��~ (��>��E���"o��B�C|n�Obv0B�]�Zuwx1��	2���#J�D�$�4<�IM�����|څ�1X�3W��齑���&���p�]uR���������*�ڠ�օ������D�ޘ�L�Or�.�_̷�?�k�}&��	՞y,Z�8�}� ѩ�D'��\=L��&H�W���ƻ��Bq���g��A�sG]�N�]���Xh��Bu~]������c�)@Ã#5��D͞J���`�/��+�&�TE�?{���l��~����ˏY���=�
-��}Ϭ�*`��0������+K٪^���ùn��~�TD�/>��B����dk<����%x�	���4v�0&�KhЮik;��T�ûT�E����`1���,�1��/Q�ih�^U��[YO%ocr�������.fw�{�h7(o���T~��^�ݘC�Z��������
-��Z��=�*$�<#y&�|$
-c��U��񞽂m^��[��J�#F�s�˹�z��E�y�1N�:s~�G�oO��Eg�������a�Tv��p�-�l����}���G)L�G�^EB�kϦ�"�a����%�O<ミP��B�h��z������|�
-
-9gk0���JΉ$�VV�\�]&'x�L�&ල]��6uA'u�n�����3�R�0��m4I号a�yY�<8e�e)S�ғoϚTgkR]X���kRݵ&��B}q��A�ö(�T'����8Y���c�'m�Bh�`�Y�/�ގ����b��&;E��p=>!J%H�S%�������g��e�?4i�E2;������ }������,MN�U���%fj#��35��j��6V�5oܟ�XWc�dT�oK��Bl2|�v�o��o��� �yY��Sy�ٌ�!��v�2� �`�o�q}_UlUT�d�6փ�}f�1�Eu��:�_��Ⓢ��p. ��P�"޹�?�����������y~=7
-O�*���o�,�U�5�y�����;a���pj����/��Ȳ!��p�'n,BJ��N�_��9{	H��xl�50��U'�!�˙�縲�:�������]S|��.���.�L�.�LwA�Eb#�-,�y���h+w�Q�+gK�}5y	���\R���{����@(���bp���z ��%�^�Q�5�j/�5�m�q%HO��㊛=�҂g��~�"y M[�Ԯ���Mu���	A�ͺ���Fx����bU��:Q���l]�& �+Հ�¸��Ԧ�E@!=]ot��&ڴB�M��4�	ڮ���4�?d�����d{1|2,��p�mVG��K�6��@�:8A��c6�y6t�γ7��a�y3�bMJmk��?��Tm���*��O7��F��ښȁ��Pm�FTVY�,owh��^�׸�p����l���ȴ�)
-<��r`�n?�Ft����:���Bz��h~��m7���*�Q����$ ؽ�Bz�Ζ�p��=�M�T�B�*&��RU��<UMqx@wzEw
-�Gt��V`�&���S�$�QU�G.�ä�Dj!
-�/L�p$���B�}8B�����nӞ��v�M�D��D
-$�Au~C���ehN�,�4~G!��@�5<�l����ޤtXD1����؏n%�h��|��D�� �"슊K�/��F��0�,aVs�
-5'-c��tz�%�X�0��V1��e�����%��*5����70 c�Y�g��x��	�C��ج'k�	�ɼY���ӲZv��A�/�w�]����4�\hh�.��$u.7�G�egL X]/��G�`2�x>��`6� �t$�c��*�ח8��c�X�7��{��*�����q�%�*N�,�yaP�.S�ؗ����������~_?���Q~:� ؏�Yة�0�y�/e+���|�)�����r_��h��u�k�J�U|"L��w���%�
-�U%��A.|K���>���ر�/E�_�I��vBhQ㯫��H쇧
-��3��
-M߃|&��K9���O�اj`��OBjyAٷ�:���Ѫ�*~ !�JD���!�Tb�p�3��h�$u{'�C��a�N�q�;��>p�\��TE�H��v?�T3�یn6b�M���8�F�]����l��觵8���'G���vE��\�m��DE���}E��*.�,���
-@����c�����e���̀t{�3 W��K���"���w!���W(����j����\���Zcf����t<��뤱� �SZt��7us�f�U�-�Ƅb��Ԭ7T~Ew�?(DSsP��K�������i���!a��h�0��3����2�H�ְKbҴ�M�>�Lf��Z�-� _�Q�N��b��n� X�j�X�����Ү<�(��S!�PE�^��]y�9�~��	S��Fq�#'耢�c��RS�/}�� �a�@G�,ҳh�ar�ޖ>�
-�׉�j�0�*{_����*���R�b~���gՖ��س�2��T&��o�3���T:��T����N�
-ȫ&x
-n����
-a{�1���!��G�;����z�լW��X����q�k����76U���Zy\/�pR����/b³n=C�S;ٚ�_ 	�����K�J8Y@����Y�Ã�U*�=�MBx(o��߂=���&?Q�^R���X��qN|�
-ᣴ�V]Yu�9�Ը>.��k���e\+�Z�fO�3mGd|����>�ݝϭl'���4�w��Ǟ�����t�x#=�Avfʡ~�u�*��wG؞��
-�+=V�z*z螉���g�BML�
-�ۑ ��Z���P��֊Th�뿩���]�0{���PAy�Vc���[G��|�/h+l�0��;܏��I��&@���X妿&sm]�mWS�*}4��RZ���AU*R�jP^U�+aI��(��
-}�'os�b���S�U�xm�ڍ��9M�'�&#�U�:[F�V���B�
-����`��Tcu&�
-Km ���D���]�VҶ�/�]Yڗ<m]�r���3E?x�O�]�	5>?�%Q&��h���VC[[�X� ����։��QVS��Һ����P&3�-�@�U
-�2�V5ڙV��I�Zu!UJ��V�����y�� v�^5ޫc7#y	~��DOhlO(�Y�˞�N��1�&���A��Z�k�lJ/2�YÌ3��
-�J[/�c��Ŀ��-��>P�5��[
-�qs+&�{�~k����ׂפ������� ^1�0�񽘎�Ř���Z+hZR�
-�$�!tfO�L
-/G��x��!����hӡ�ޙk��xI�$o���F^�֩�塱�i��R.��7���Rk���j����^W���wc��u�`�����{�P��(,x���دt���a*�W�uű_Gc�DL�+ƞhc?�ZgUw�(��;���Cc����U�������/;#���jbM��5��LA���'�
-���Э_c�p�x�p�g�qx�{�w��XV����,�a���ش�^�����5�%[�j5��N!��^�x[����X��C�M)D��M������ʵq�3|��:���ֶ�B�A]�*�ʪ����~���a��i�g��僳z_>:\p��~9��e�O�7L|��~���U�L�ׇX"ئ�#���S�7N�+�`����4�Z>��j-��!A�m�Y��p$�C�)r�~��@�]�g�5�AzЮ5�W�=�����▎�f���8��{{�j|�44ĠF�xH��[|��`�Iz�!��xN#.��}�A���j�����V=_t=Q����J���*7��>�1���R�]Ę��'ZX�狸'��m��S�R7�7����O�IMQ��3tg�!��o���Ĺ�e{xc})$���/���K����K��؛�7�eo
-�������4W0_��l�o����v�:�/ݯ���_��l��䭥d��s�ϩ��E�s��o�X�K������]��ėHB)�^+U��7����O�)�>% �}֊��B�NS�#�-�����~k&><@&W��=�3�BM셦���;��^Uu�o���?K>Ȯ��}>�;K�}�C��y����� O�x�Vq!8�=��%���`��}�0<2�[&-����&���:�=;���E^��O"��a7E㇔=^
-�)�馨�o�����k�LM:����v���4�si��������~;0@�X��<c�0c+y��3:�R��8]��^Wr��z8��9��]��,�����COi,�>�����}`@�灁��3A�Ru]1��X��	>��Ԧ��¶ j�����{Cp&(nH����H�T 2W�+��5A=MJJ��w�$H�����
-*e*��{��'�����`��rW0'U�`0��h���{��g!t�U�s:�a���3��Sqf>�]vb>��o�T}�*��Gpt6��ԉ���$����颭�N�
-Nŉ:]��<��Eg�t��\��ݶ�s[ӵ��f��b+��K���a�v��0���k]���W���NC�#xsh{]k܊K6u\ȏ{.�O�r��hvb��7��iX7T+P�X�m!��Ҿ6DϪq6��(&1<;S���)�s$�ou��
-�.|�J��]nT����Z�5���3�Ċ<����Tm�}
-�*7S^U�/(o��� 4�b�j�U�u$�Y�%{4�P��W�'�Y�%��ۭ%W�w���U�Z���}P@mQ%�O6��U�NU��K&�ݚ�#�Z�Ln���SH�m�
-!)g��c�1ݚC�\���m�6V����X9T��6vjc%����6v�x
-m�T��z��q��&���S���	��/D�֎P�D���4�����4g�"�G��	.��p��BTC샐dmG��|,�%Cr�=�P�
-O���xj��%.b��|7w�_��-���{�s�-w���m�ݏk2�8��~b���� �
-X�}�FJVMxE��"��+��]����E^ *}���J_g�+�+�P��PU���O�B�ג;�яk2$��9��Sam�D_3b��RlN�d�6Y��u q
-��ӵxQL�3�b��
-�1������'�f���MZ��5�(�-·���2�U��-��9��3��&+��9�x���!馺���ў�]:�}�|��o�½��V�L����4���R�-ϩ�����Ɔ���G���I��G<��J֞�U�-��ɟ�s��� �Z�=Z�3�G?��S?������XC�ܝp�k�9��>	T���3^�w��@{x�/��E�]�z�kÝ�.Z��@W�8	��{��{��jS�O{�����$|�o�$whNz��.h�Zr����z-�As�4)�Xn�,��͊q��U� H�53{`���}t��~¼J�	K{�o�]��E�S2���û����>7}��p�~�����F{��تŷj~v �1�J�کA����3�Qk��~�l�ac�Lk���w+��U�~U�1|W�wO����G�2�i�w����2�h�s�gx��6���%Ljy[�ϋ�dm�`�J�ȩ֋�g��ܢ5g�h��% �X�1�Ek! 8[WU����6w�3Z�}�wI�	�0i�N6D�c�y�$y^΃*�m
-�)"a�Z?�9��m����О_]3�-�.)�0��7�������,�ʈț�A������M��{J��5���}�Q�&��C3/^ڇ̼x�h�P�CG��D�c�)0I'.�8��*q��B-=��;���{�D���D��!���<��TE�?2qs�!#<>7*��k�O��j:Dp�Q=�������2B<�O6݆FpCN�K'��)�t�M�C��sN��v����^]3A*��Ъ��|W
-��u"�(��c�eNp]?�Z�O���S�Vr0��b�.w8�9������XtH���I�^͵����]��&��*a��xx�bmЩ�T���t[�S�l-u��V�]�V�p;��9<�Ó8<��C�ƿ`�/�(i�� #��3�f�rq�h�L���i�q�׶|���z)�1�#q��O� ���DwEnlw��9�8��QvU�	/R��P�+�~���o*��'�F�:f���_&��c����q�׉���=i6ۧLڼ�[��ѝЗܫ%����c����=�ߚ>mZ���-}Ƥ$��$��N��6[Uj�A���QU���Y��0��K�7��UY��p"�Uڪ�@��gM~v�ͺ��߼}�$���b�=�k���E3}����;g2����OM�j�uDJ'�_�h�q�����Xηe�����[��_���#��UY���U���وTUyqZ��*S�)��oRA�� Rl��~���4�6��gw<%�K���f-�Y�.x�����8}����ԋ��_�i�Wǎ��Qc^�J���������ywn��PC�\�u�B�a���Z�3".̞�Κ��fk��&��fG�]�nώF+0c�}Z���!p��?�Jn�pX�JͼآNt��l�aQ
-��v� ����!��9_�s�G�yTilNz[b��̀<:����'TE����w�V5��N�+j�(^@�(׉~l:���)���=ʡfg�^���$���x�K+��X��!(v�}�?G�6�љF�KS*F�q4���#�\�[e��ޖ�h3��q� G�����)��s��w�\hS��X��i��e+�F�U�!�eCHe��e������}�į}�,(�#��B�(�X[j�Q�_����TY����}E3&.ь��f���u�皌z���|y�Qic�9(��?_dL�����?�te�O����.&�$\Lg�������	����a��l���j������	{Y�������"qhN'��pZ!��/�tRvq:){q��I���i�����ap�pї\��^E���qB���z��$(���W�`�=ښ(���]I�9�d	
-f"[GG��l�=e���=�w��]Y�\��߽ᆒ��y1 <�!����"���0w�5v[]�֯�����\S�=�.�̰'R$`O����{d{2A\{��R��j����Y5��=�4I�EJ�?E��Mu�U4�����w0'�����J�}5Tc�����j�\�{���Ò ڢ&ꢏ�ֹ`t�]K����l����c�O/��S��I�`��0�2�g��wp>�w��w*�{ݭ�Q�A����+���ݳ#yP��P����d�'s��L�"ه�׉@�~�.����͉PLV���/T{���^7�O����?��s�S��rMu$G����-��@$i�C���"R����5D=3�F���̨s���Ϥ�C����C�@����?dЛ�O{+��E?��e�g0P����?�M�G@��`(�IDh���*P������6MQkj�}W���b����G��Jyr�M�i��~�ѺFb��$����U�CH�횮��6�8DS�:�ޫ������y^�]E��V^��s�~���[���4�V�>������
-e�$�QU��[�n��L�TE��S�7NH���t�����{��I -����&SNO�k���:I#J�e@�U�u��BB�t�2�G?��zV}�ѐ9��p|�>�]O3�!E�������u)5:ɌN6&�R/ϛbF����}h��������WF�J��M7�3�+��}t���ft�:L�cft�p�:����2ی����ft�py�WF��:��E����Ft����7�S�h���f��f�I3���>lD��D2��f�#�EG���H�Ht����L5���P@��Q���S�������z��B���!�(d��Bfh
-��or�^�����=|��_��vU�Oо�`?�I�jwr����U������^�i�D��X�����e�e�����/�_3�X��wz��N�5d>F��uz��P.�y�~
-�v�����"~�
-�x���.�v�`l�2� ��}����-v�yà��jh.��s�@s~9�OF�k��@�I�xP��5��"�o�O3�<S����a"YF+��D*�T�+�r���W2�*�#�J�j*�M{�s���J��V��Ct����݃;|MC�:����E��;rM���0_f����!鹺\��<��0�8�E������٧������q��&u�&u�}|���K��چ�q��i_��Vʧ��F`�t�Um]eU[��������l0��5dN ��>\W���a�t�Նt��t�h�*Gs�`4�ސ9	4���\�Cz~��f����n����WC��_;�ϖ���`��oȜ����A���U&�m��bo'bn�w�?k�;)�-{� �)�A�~�"߶_�˵د��o���5ݣگ�e�:��7�7xe�I��~�'�	�y>�
-��m
-~���6���6�����Қ�w�o������*������o�~�`w��~Nzu�Zp��X��1���}�s�>�#�`?��P�M�Q.w��������$�Nq�i��*�t����Y���q�9�AT��ҧT��bƝ��̛�ԛ������_1�\��&{��([���f����m�v[=R�L;���'��3{"%�ؓ���dJzǴ�P��۪o����fcj=���!
-�b?L`Su{��1��\��{��H=��Щ��N�1��������t�a0��А9:}�G�=>=j?
-d7�쾫-�}WXT�@vs9�[#KB� �Շ�6C2�n�����{W�v���(�v�`l�ѐ9lw���]�h_��WCs���=������`4�ِ9�7�>4_�A�	�ǈ�o�g�#�Q��<��{'=�4?�|�<N�O�����7���W��W���Ct���N�5������d��I�8�a�<p54\Mg4�h�=�o5d. �^�PԪܨ�Z�b�}Z�>��ڜ�i��d}�:Wk/� ������`�zpx�������ؿ3�o7d.�=�A��H����������CW�CW�C༯���|cC�S�߇����AJ7S�B�{��`�_��W���!�>P����x75d>���>�xG��bF��z>ܗp�i�(�3^�=�A�ӣ#W�ё+���=:Rޣ���;��ѣ�}=�ķ�/�G�����a����dl��c{|0���/��	�'Y!��\ӵ��z�]Q�*HW��Xũ�i�^���pd-�|L�M�w�g��S�tq�v�.nц���!�x���gw��!�%�x���s���<'΁���a���j������H_(G��`�oj�|�?�!�#�S�`/��x�� [e���A��%>�6r�&��6��-�w+z��0�<s����v�φ����rp/on�\B/����75���3��H�������\�^���� �G6d�t�^B�](n���Q�dg=4 �8���/s��z�^����o_��CPz}lׇ���������~y'��q��>�Ґ��Pu��8YǶВ���[G�^�&#�V=�ߣx���S��̔a:s�j�9u��L�3S�;����D2��3�:�^� 
-b������!}�
-H?<��ˑ�1�[2m@�ҏ�c����3W����}tl+�v�`l�ېy �v�:a{��L�|-��#G6~�f΃���˚��o���=�ϴ�Bf��K����g��Q{u�Q�Zk�n���$ݚ���œ�ǽ�}����2�y�^�И�*57�M��E�a����ኔZ�%�|��>�_��D>�o=�uEU�q���^a�m=��o���1��z�	�����ȱ?�K��_0H��z*��h�d�]#�_�_O%�=�l8ql` �����D���Z�u�Cz#�B��%Eϙ�2�YP���P�j�|jS�4]�,k:nҜ_A^�& MG��
-�B�.W�}�����
-��"���ٽP=Y��P��X=]���f몮�����LjM��y�x��U���&��<12�����Bz_}��z��r��)�J�'G/�m�zj�gz�CxN[Bԧ鸄���������V�N�c�qs�t�s�s&����9��g�"���:�:��t(�qt��� ��>���_4df#g�P��\W)����� ���&��A��0�_#ٟ�R>U�\�~^��k�~n2�_K�絔G�+��ZM�c��OX��?���/�S���Tu��W�xOD�Y�a��������Xw2����W4�?�;-��B��k���^�:]i�2������m����D�n�6��uވu��sZcO|,��7k����VԴ�5��)-�a�[Q#qb�P)����5��X��s��zj^�`7~d&�Ta���E�p�4�>R�WV)��B���nw����n?��'t�	�v�v��������k
-�>����jZg�F|y��7�>%S��>%`�
-�mRc�K��%�	+d��߳:ѕ�.�ه�"���C�]���E���"����E:R��x�^ÇON���9m$��:�������S�v�Ȝ2��)t��7��)t�Ȝ7�m��n33mf��90$/h�}!e���G	9j$���F�#9@�#3`$�R謑9k$?��gF�3#���22_�O��'��O�G)t�>s�>y�B��3��}e/R袑�H�Q����q,��+�������%���uO�`r%�=�7����/��\�}�(��j���2�@yI����K���j2�j�_�F��d��M~U�X��
-��C:=4�ֿ�m�
-9D���ߔ��������:\��di�M���C�3��E��=�4�V$�p�kv���Xڤ�֟O��g��E��p���������O׃x�B�3�R>��s4���Q*ת9�����jޏ[�y�᪵�σ�H��Z6�R�-�lXaO�W�cWI�MA�LW���������a]��
-�݆�P^�7���^7OTw�"��!:�:�-D�X^u��vk���q:��l���(P� *�u}��Պ��;ڕ�S�=.~?vh^�WQy��T���;Z5f�v*1
-H���:"�(�Q���� �+[����a
-R��0U:ؼO�}o���|�C��
-�P��y"
-���_�;#fE{j�nC�j�%R#b��o��a'q%�!�����p��ތ�Ft
-��*U%UU�GU�*�<6�>�L?(N�O��Wԣl ���0�}y�4cي�rC�q��E"������D�vW�!�m�T&{V𗃠D�T=�`!z�w;֏Ut�^���"��Ԉ��U޹��L�B�$�.)�,A�U�vS��3�Ǌ|���ACf6��C-��%)��/r��O}g@z:�Ia��~��{��2��$!�L��^�R�B��Ii���:�B��A�t���8O�]�S�jT ���N��,"�=���z75�x!���e�%PH�o�+��9�?�R8�r b����S�ş{Ͱs]A��u딮T(�E,ȕ��{�p�����7TH��\�U��"�-�BAC�˧�Lq�/�S�Æ�vL���Y���cRfb89!��63�<w9���Y坨�<��Q�;��)�K�v�cw��h/�I�N����f�_Խ�����Q�Zu�?�\�<8w:5H2�^�!q:���,?%
-%<�t%[�I2�ϕTN>�OVo���K<�������D����A����yR8:S�L
-'����j3S�������d�ݴ`�\Lzs�;?nȼ��g�aXW��h��܂g��������M�$s�����.	y�W�4����O`(��}vj8�D�L�τ.��g����},y��m��}6h={�'�q_�F�g4Z�A����Ce�"��W�@��!�<Z\b�W�<!cF������!d�ձ��sɞ�<H
-��N����[C��")�8��U0n��к2�� z����+z@���� �2�9 z����e@ �����ʀfh�h.�6���i{8)�,_8#׈Ȭ�ȥ2��)�hL�q�ۙyo�gz�S�zɞi�g2_d�t��}��9��}��DVQܡ
-\TpW\@�%2�
-�UDED6���?7"2���{޼ϟTƽ��s�=��s�����n�{�Jн Z��@���Ы���Z����rs"m���Ǳ�s�����F��$�4fC�O�;#`�5n���ޏ���5���7���{�Z�[�υ��q׳��u��z��Y$Uf����^*����ڏ���4��Hyf��B�_^
-�՗���,�������Je�v���<$^����K�7Ty��ʕ���Y�z�SE\$/��C�K!����2��c,�茖��h�KjϏq�:�o�����ա�<��!AS��z�?�[3}U(F�ZaU����4a6���wE��!�ܓ��H���jɤ\����0���ZX>]_p�w�M|ޕ�67#�w)W���r>T�4����?���I)1��m�7@̭�I�v-3��r�V��eni��A�n���y�!�;�����źPw�<�:��!���r�v�Ie[��m�<�>~\e=�q��9����Rو��}B�}��#�͙����O�y��%0U839����R����61�6�¿��T����1��~�&�=�U��=Z�O��S��
-���Q�p���
-�4�@j����grg�g�T�$;�����;5�-)ܩ��H~z��u'��'����gic��i�i�$\�W�jC��4$*c#�Ϡ__N�?[���:�:��"j�ɩ�T��X�>�~�s�E<�U��׺U�ϒ~����IY��x�$(��,��7m���=�ԥOK��'rSS0rX��^�U{ϥ��6$^���gUz��{�TƵ�e�e|�0���%�oz��OH�NK� ���� ��Kّ�o���f/�D�����#I )�b�z�7=%�q��BT	6� ��T#TYcԄ ˋ'*%˥d%ѠkBX����;�74zN㳰6�o�P*�He�&��7{cJ�q&��ƯU��qҍ�7��^��oJy�M��)O(뙕�.�ܜ�/�ܒ�+�[S�♝�x�m)���9"�T`*���x�Vk�_�~C�=��K�-����& ��	g^��-��y�>���l��O���)��
-�Xfڱ�A%/ȃ-������˓V~�fvv��i����c����`�����v��rP���	��/���A�>�~��fo����sR&��a@�� 棖-�2u�ɠ�����dfџ+}V���EBvɌ f�dl�oOɲ2��;Rl�MXk�=��cǟ��D��|Gj�X;���1�0�8}@��º)���]Ź)�$*�'���v*6���kNC��դ5�pNT8��Wj���u�H���X%�dn���Hm�h����uL����p�ط��X��c�	����Yd�`��j�Y͌/�S�O$J.�*H��	�&}�e�LI�߰)	��c���ek�iU�89�W�_���$y��\�h��>�xTON��~��K��<�3�qm2��qR��<�b�.���K9H�;}�����1��b���W"zt��G��$�~���fC�4�^T~+fyy���cK�=���H"���*�qmg[�D�ޝ�� ��f�-�d�E",���ƚ(��Y�|!,P3�w��Xr��C��)�]� \N��v���z�$/|�eG�ܨ'l�(��{R�{S+r�~��Ӛ�A.�wk��'{��i=�85H��H��׍��kn������a���j8�0����y��ݽ�����ՠ,|%4���.Tl��>���?�4�?�i(����#�;D��#��';P�^���7-��Ht��|#_�Y�e�
-fnM������5��S-ߗ�J�@��SƖT��ڠU�Kʫ]�L�?��B��~!+h��~�~����S�[�V���T�*��5D8�F�����l�Ӥ���"��J���	��	A����5�/� 4u�����l�2�j M�>��WBe���}E���<�չՉr=�'!H�/ō��ʦ�0�I_T$�דM�y)���U\�d4C+⺣���V����Z`��kzG�vj�Kt(,�jE��=�]�%�F	,�v�F�"Z��v�˾�Yv�,G#l-tl�h���ʾ ���wh�;4Oլ��w~��[��i�i��I�O2e�pl�I��d]��~K�͡�h狊�7%UeɊ�%Ya�����v�[k����j�I*�Ou&۱��G�Ҋ�M�f��ٻ_�A˰7>�����)��lǬe����3�hh��qТˁf~�J�/^��wkf�$D�)gIK��09�\��4-t��dx��[�4�st�V=wҖ�q����#����%�GiX_��7P&)н5��wKhs�ҏ�
-�S-p��~�-�P~����Y[�m@OV�8K���IV��g�(~J�6˓b��I-?
-�,��6�(���FiTө\5��>��4*,��#�銗*�r�Y|�T3�@U �� T�Mn�� �� ����HD�6��;j=Gݢ>�Ȉ݇�� ���2°�ϙ�q6۝}g�����渣����m`dw4ĭ㸹J��N�^ ?`����*衻��2�C�`!��VX�ߕZ�%-���o{�/i�絮��Z�e�y=w��ϣ;�IF�&⊉�2 �s ^&�qc�95|Ъ�/�*[Q��
-6%��h��͕W��*-�Tse��*�H04J,ч��$��JD
-�.�"�����R��)}UP_��I�S����R�����V �͏�k�����sx��[��+�'{7��T��_V��֟������R���-�*���Vk����j��9e�^��1��>��{����AH���J/(��ò���_S�1�_t��i{Ox���`{��P�g� ��|d	�X�̳���!�ox=D�L������;�=`�+�j���[f�k=�iu8ɲ�D�;v���8��o�y/�c��C��4ᛀ}3p��2m�ۗ���aQ�h#�-�ʸ�`{���]���#��*�S�~Ŵ�+h U�
- <~�S�r�}(��x��6&�S4��4���?a���*��^�n�WyC˼�\yC+��eV7W��
-k��+͕�Za��Y�\Y�^�2�7W^�
-��k͕u��Uʰ����_�lEa��#w�&u�zU�������~��k��[Zfms�-��^˼�\Y�6j���+��-����A+l�2��+���&-����	�{]��Ѕ��}�\{��3�v��3��Je1(���z�!�@~������!�@����CJ���s3���UA�}(U|(E�����ŵ��������ڵ�g�*v�����
-�%�'�"���I)+R��T
-q�Z�i�x*�[�f��h��4��N�}��A+����.L���rky[~&5W�𡇧�pZ
-S4���S=ݤ-T�ӣ�����k�-���/��od�]%u���Wō0^�`<�x�Y63w%���*Ȫ���Dq���*x"�!BuȤR��@C19��qҍ�ϥ���I� �������I�U���[53�'Fi���+7��{>%]�zI	ʸ5��⣉�r�8�D���MB�_՚8�����:�Cu�aA�MX��G�Z���`�s���êfZ���q�nrF��H����)xc3�ƍ��9vk�͕�Z�]-����V�2ۚ+Za������S+l�2;�+۴�.-����K+��2�+{�B��h��k�w�̮��;Za��9�\٫�k��͕�Za��y���U+��2��+;��{Z�Ps�=���X��S���_�V9���(E70��Z�VyX�&,ሃe�[�b
-�W�A�.]䫛����qCk�go8�<2+�C#�}�e�vg�ee;�*0j<�p-�����Aa�k���]�윟v[v�nw�x#=vpS�i�(��a�x���c`l�l��n�F�.\Oخ���sz�;�H�e��9HO��{�'��'Cu����:ҽ�t��aߩ�ng��
-�:4�
-�s>r � b�q� ��р1�9@�I8�F��Ɣ���D���~"_Fe���`�p��":I�w����PD��%��e�=���+[(���&����ƚ?�
-ˏ!H�	؏E�>�n�X^��[P]��ɽp�����ux�	v�K'B�K)��f�on�+�O��zP�Q�&S}��ϐ��$�~<���>J��a���4\#qg?���]�=��C>�uO8��c��ϣ��f�C��Bݟ�<�c!��*>⣟�C��~���1?Y��?z��~��KW���)�X����_����g%�8C��R�3d��he<�̐;�/�z��.�>r��� Kr�����H��:�w��������j̐�T��f�.�{V�[<�r�z�b{eJ�'�[��!��q�0�C��<�jd:�<�դ�E\M�x��I����� W�>������}���<.�E��79�<.�G��j~B5��O�x8r�d�����p�sL�������h����K�c�؉P�k���}�L�<(#�d]H�౯���A�F����u@��\=Cy�������#O��I�C���7�w��F1\���h��>�vj6.�n
-����Yc�Ã1�Mk���P
-��Ԍh�<	4l $��[<v���at��zѰa��N�8�?n����}\�$�tx�����Y�7�:GB�����$���'�ѸS
-l6��d���+��ֵL|�HB�_U\2+~Ρ��,�h���22Sfc�3���(B��T��	��|�72�;m�_���Ꙅ�M��깄>[��O��`:����O��_�����D����r�z�}?��_"��S�?�,�1F�����x����d�#�x������ٲz��N��ޅ� �w�ܓ a]�"?$0!�)�a�8����t�{��H ;@��j�Q((x�����}k�@�P��=Q�y�;�O��@� ��l��U��%����!��8�S��Zp���� �&���M��W#^�o��0�a\#������!�N�p�7I���T��M��Io��`��� O!��/�<��21t�K��!~O ב��5K���wX�X4B=�P��coH�j�%��/�	wH5�`����f)�_*p�R�:��M��+B�i5�/ D5����m2��9����<��m�Q�,��̵�`'�+�wH��=̅2ބ�2e�,������{���׿�d��dر�qR�(�&���q�5_f֙&�f�&�7���S=�#N9������3`+̗;+�e�}9��	�WI����;I�z6�?d�^I�W��;�����̭NI��Ikj����oOd�Oͳ��$��?�e��p*T+�*�B�!C�+��%1�z���'-��a	��8rPK�|��"�_є)K���B9M�O����B�됺����4��u��ZJ�_���� /T���B4���YU�O�����ɨ�z*�!wl�`�hr�tHK��%��vV+���(�y
-W�zTt8v���ܝ�׫�7ͤ��:]�m螣�s����Ce�\�F�cu~�[Ô_6lt�SZ܎��4F��-~���_��рA篡�_+:��:�*:��:�*:� �������ތwlF�!�T�Y��՚�H�8j�J�-�X.�:+;��S�*O��$W���&��j{|��jd�|�N��� ��7q�p��{d����7��G�+�q�b&uc��{���ΪpKǑ��L�ʎ�D�f��sا�,�����L��C����V5��Wn�D�p��:��D���"��F��H�9������ѷs��V����6�^�8����ľ��J"�!����N��N����*6h.�N�>-�Yse�V�@�|�\�@+|�e�h�|���;�F+����򖵋�7m�e(�nu؃��Z�dse�V�X˜j�|�>�2_5W>�{T���� 
-;��e�x>!c��I`�W��@�[�/-��H��e�	YR�~\���>�ެ�P߬�[����r���>����o��o�� �^�>�X�ڗ����*O!��~d��I~3�>��T�A�u�a�-s�T9�J<:�H/� ��L��L����C�]DzI�_��ձR&eDZ�iS�H:�E`Y�Dj85�D�\�U>�
-��3��AT��F�<��f�E�b[��{R��r�:���� ��ɀc�U�e	�L�y#�[ ���j�j��$CH=��JO�H�m��R5���^b뙑�]G��H�[��ύ��_O~��z�#�o�����؀m��l�K#ax��a�H����_vzg��;F[e%�a��������^���a�+�U^E'�:|�}�����u|N	8?iD���x�����*���{�Cki����:�ש#��^�6ӿe�u�T���:٬����`�M*�o����Jf�OH���ʧ���(H��;|��2���'�v��ĬMݛ]����&�7��8h�Pc&��6����r�R+�|�2��ʨ:eTQF�ib��T�ķ�M��µ�>E�跲�L�=�*�����l�-l�[Y&l�]ض:�6 �6���rp
-�L!S&R�D���Ms�[@�.W�<��oɸJRx���%��Lw�f����g��⣴�]굮6o.����fZ4lUw�X�5Rk炝��Zb��H���`�5#�nd�=N��F��sz�mj����ׁx�;�Ļ���@l�N�m�z�~+���sK]������>r�m���oe˙�-sa��`���cgN��aH���~J��r���ou!?� ߊ�~�í#1Y?3Y�\����35�nW�2�QƧN�#�����*Sa&u�2s�q�)��q�����~���c��4W�#C��p��?����Q��A�C��d=���n7_�W\o�ԑԀ������[��8Tv˂�?�g};�wB�^=�S���j�-Ǘ*a���r&�=�$Ri�<�ӯG\'�7��9��/��t˘�:8/+EƔ�Ɣ���;d�Ͽ'gߓ=��7��I�\����t3׍-��7ڃ�;�4���Hy}�oȫJ��.�LïۄR}l�G��;�����H����ID�{S��m4M�9{q��z�k�E���y��&q��$~.4���t�%F,A@7M�Kۀ�d����Lt�᯿#6�FP���U�/O�?�9��,M(��}�އ�Y3���j�i��poq�kR����)��Y���9���
-��4�llL)>��SJR�}���R�Ҩ1��Ɣ��5P]B��ïV>��i.j�ɖ��`-���{e�9���}_�Y*��2v�8 -���µ�2��C� /� �/��@m��?t��Е���h��U�(W{��
-�G�>va�7��N���r�d$4���{����W��4��I����qq]�:yB��HSN(�2Z�1�Q�ޔ�� e�v�]36�#��ʈ��{��G����`س�Qu,�,,��Q�&���5�����)�G)"�u�8]ޏ,Ri�<+�V$3������Hgg#d4�]��v��B�an@3�1pĈ��^k j2�D�^�T�ǩ>C^`)"Ii���P!�H�%�%�F�R���z,�o�<�L-!XJ3�וb�R�l5�����{#��[�b���������ch�H"̍�&��g�~ܮ~��#D�r(x*��Z�jH�0�<�H����&��	LYF�>�����<88�) Ʀ�1"61����.b����Ĉ�Ĉ���S#���������I�$�O#Y'vYU�(����=����^��(z���Nk���s�쐖�U�ú��6R�`-ʚs�h�]ψ~؀hr�nDJ�DOm�Ia��]�'�*'N�bf�&�$�/��33�����u�(�7��q���?�~r��>��� ���{��`���t�v/&iy��S<����0��1��T#$j������kP���f?�Ƌ�B��|���\8�ߣr�l?¬���a_ |V��~x#�~�����?�ɑ�*�jֿ�fN6�E �~�Tk�M��g�2�j_M��7��t��飃�=@�fö؅m�`/�3�>5���L;f��?n�^V
-�����޳F.)�RC�K]�1��y��v.�l��N��MC��G��}$K�6
-?*ٲupPd�#�󾀙�/ ���#��)*ql����4ţ�
-�\<��Q�2�ߊ�γ��!�J#R����p��l���r��)��+����r�s���Q����
-��B�5 Ϲ�<�Zjɍa$��_��~&�ʤҎ-��F@T��x$EH��!;��"M#�ٞ�N��.W�:��SF�I�sh������<���&D֏��8%��wONG�ё~t$�'��w���jv����V��G�ԯ�ّ����s�Ftaw�5��g��zX�ޘ/e����})�D��e�{S�Oj�:�T��ԗJ�z�Jֻ+����9����J$1�D����q�?X��!Ew���Ka��u�^�@��/@�Ϣ ^�"�!"^��;��������F��38E߁!&f��B�pp�_<�/0 �ܺs� ��XV� �U�`� �i�se��6H���`{�3$�ۑ ���h�&a��h�����Hs[tu͎hH]5�0Til�:�uK�uD�TѺ�N��!�S\��	�*I�P�-.uZ'�[�u��u��W,h��)�&��a�M\#���Ĉ��Kq\?3�$���y*9��2�����)X�|{Li��Rǘ��cJ�]���Ҙ��wX:��*]�U�t�.�*]Ē��œ�A�#�H�	&���¼`A)� ���x�~��x`��5/P�F�R�e
-1]�|����;H�x6;��;�7�o�~OR|��tV���������ΝX:ǈ�A����	ha�5'�������y�9�H���nN�F��X�2������H�� �Q�Ɣ��؏�ht��6����^���!�2�%zcx�i1+��0�~������"��im2��r>��ꤑl� ��RɔW�-g�Mf��U�UR����z>?/j���|T���H0�i�iF��C4<ˁ{�z	ꂁ�-��>���.�)$ҹ0��)�o��RK��~О�;����Щ��]Hy/EK7s%���g��J1�_&M����2�c�z��h�k�!v>kN�E\����#�f��;x��p/b���X#7�LA���q3�f\l3����ԝ�4�3EL�Ŭ4��#�<�ƅ�q�`���߶�tШ5.�CK�a~���O�a.pu�IC�2�0��`.l���sQ#Lb$���mtV�ȝ57^�G��v�o�uA]�7�ᷪ��*��g��o���R������o0��q�Z�C��R������A�.�a٠��XR�F-<�Ƚ��<�L(��.#vW�$;�
-�lx6�	?�:��il�A|dܓ�� [`]��p�mM�!�-cX���4:k�'��'ĭ�8B ;m��m��!��p��aյ�jC�I��p�yh��mh�	�.J�G�=%�1n�y�?�<��!���KJ��Qk�/=�j_k=��Hk��֚�6ZyE|���1Zz�h��t���j1�f�V#�[� �Fk�]@p�ᮔ�.�Lk�6���4h
-�
-��%<(�̚\���/K�1�И�<�����1��~\f����q���%�����.�ҋ+�G��[�x�
-��P��_���Wk�BsH8����ߟ�z�ӂ�b��� [Q�\]e�9̰�S���s�+�� LI=��(T	��	�_�z���$�/YqX�����^<��^d-�zZ��ܤF�!���G��R �a����l�c�X���?I=�Ix/�9�Ӭ؉�[E0�(Zq¿8Bw�4W)vl�|��42r�?C&�؂�CZ ���[��Z0y�L�_4���iFw��:-~R����?DG��!q�����iH�/A��TGnY�08�ӊ��
-	�ё'V�� �#<���-�
- f`\�#1'4��2��ز&�GN�\D���jɬ���7�����o�K"u��c\c�-jL)��_��5ѿ(�k��9v�_���-V��i�b�W�9(�R-�Od�e?��LD�1��0���F�QJ�,�ka�r�I�m@��*�%�ׄF6ͅL�J~��:��l��t���h|w(��Έ/Ѐ/��0��#�/xF|�|M� �:����E|!�7w���g�'7�kv�Ɍ�ky8>���|��O��Pm�7��_t����,��X۴�O
-��<m���p�U���ɹ�}���,Hm4��y�C�[�I1��L�k�ǖ�Üx�|^qJ����a\�f�)���3p����)��V��8�S(�� �f��
-����a����
-�8���oR&�v_�)��I��|��nI!��L���D�T���M�H�vD�.,�j���(OS�e&X����w�����V�T�o�H%���PG�s�9OO�Ԋ~�?g����s���[�Y݂��z��e	�kJ~�����,�~�ś�#�e��ә��Lg ��Pq6�t>�����9 ���6�����+����@�x{�9��<�Ų#���(�[˳�I�)���m�Wc��P�	���bVp��tik��K[�]�j�e�֥��ң��ңC�� [ѥ�����-ӵ�G{~^jӏɦ�V<�2�hҸ%�o	7D��z��X�Gǔ�ǔ�1|Z܎��N����m���W���uRbZ!��pD��/��V������O%kS�	�mCÖ�����W������7b
-�P��~�5����R&���+�P��F���PO��8B��M�����\^�x���ۆ�,~��W��r���m[1�Zsm�4Q�4���ݥQ�$���=��3=J�ƽ.�<<�y�cK����rX���J4M�U��d�|gq��i8�h��`1k�M��G��}ߨ�H|�>�ic�L�Y_��^;�7��ܴ��#_� hb5�aQ�Q�2�5�-^���C�Ȓ��+�$�HI;!{AdZ
-X�p��A���rg�(�
-��:<\V�gHA�0��|�:�Խ8��n7v3�5)b�T��Z�)�܇S}�����l>���;c�/J4]�Ŗ%�lH�7�67V����ట�GI�:`(E���!�k�Dݣ$
-o*�Q6J��Q��6�5J�CG�{�X�QQ�b(C|�Q��Ґ���o�(�g����(ɍ-%�(�Q�$���F�V9d�]��I��n�[��u3ج�Y��F3�mb0Y`��HL������b0�O�˘�g���z��"~��,T�?{�������:{�!l�� ��c|����	fĵ�Xn#1c�Gx���$-u`�)<���t2���GV�F\�sK]cE�c�)�k+���X[c�5�z����5�p}�����lns��s]C��M��a	W���g�f�m|dvk���6JƔ�L��4>L�~�z�<�OȄ@T`�d�b�̦QoBvr�LW�R���h�O��`M����c<���Q����*:���o���F�HXy�sb3;[���l!3_��� ݐb�I۲��\�\��$V�5k����5��O2�����߲~>�;�2~�H�ء��E�x�N5��f��g�Xvc_����>��BX�O��-0�6�������5����N�0Vz�`$-vA�(�P��E6Y��&l��2��':\���&���5��3Q��U�ت������BFD�D`悺n�HL:K!�&&��#3��7��Ȥ����#3��:�.�=�tq�T�I׸�ti�I�cҥ.&]�{0)��l3�F&]�bҥÙt�p&%a��8�I��ĤK���=t�t�L���TLz�L*��TL:�Τ���I�aLj�^��zaf֡Lj�s����I��+xp�̓#W������fd0�ma�)�︜-�x��/�����@��9"g�$Z���� O���
-ߡ��M"~
-�g��i��Q|O��-~��\s�&lr��L��T��d�䏼���8�#rU�GR�dJ�	�կ�ø�ݺ��<�֪���F��� �G��[Z�Q�?d�søq����kX��K��L˨���0�!nWU�X�u�*l�Xws�
-1\��wW���V�]n?����d��&�#©A���^����e�M�F�ٴ�Q+��;\����$�i��@������U�=�J����kL�ߕ4�1i>�t�)���o��C[[�C9ʺ���m�����5m�_�{�"pm[%���
-����/��0���rR���S?=�e��f�m׽�'ZRa�d��u.J?ȶY@�{д���˭�Tq7�S�o��p�R��w�]"��`[7�	�'Z�n�G��(I��єᏈ�-�3�g�!���	#`'�'b����l��丵Yb�㗱}6E�^�Ul�W�����Bf��=80�v���o�?�i�
-x���K���c�����r�����F�x"<̢�a��T�0�7>���T�I��pt��s5���0���[)|���ҙג�ex�̭|�������Xa;V�+�M
-鵛��{R~�ԽB�Tޓ��������CJ�=���=��G6��?��6żVx]L�_�௾����9��䴾7�<��_ ��Ƭ��^Z@iN	ȷ9�?�·�ܔ4|�+%
-J~+Z��ުH���.;��S��i���4{��&��h|�3�����V^��D��c����tyfZծG�J�G����b����;�|.Lڠ7���yoI�k�T�[��7-g��=�/���I��3���oK{�_y�=��=��=��=w�=^��.��KL���0��	�%s��SyL�N��4w+ց�hQl"����ٞ{@����x�þ�U$��x�f�
-��
-�����+h29�$�K}pPas���ܴ�M��q�pP�V*�m�C�P�j'��ثS��(�ٰ���c���L�9� �q� ��b; ^t ��v@��@��J�g�5%[S<�I��lF�¢�$�}��8��coRj�;���8���do1�	�x#|
-�§�+\xv�~5V^��%��bf�Q���4ysw�=�Jgej�:��ϲ��+���<{�nk�= j��)6 e�IKl�2���o%�l�T;�x�����*T`~t�����Z�Ƞ_�<>����i(]�R�m
-M�����AwJ�6�鋺�m�NQ�k���8�2w���[|>��͖_*��b�
-�̖de=��zX�����nk��(8�(|@�� �aSk��ܽi�5.�� �j � ׆��}~P��6q���>8?ٙ�į`��1���}i}����U��wZ�1.Q���?7?�?��i���n��b�G�QYu<A�e�[
-�>~+�/�����:4^X���ɅD�LZ��wy���R�%SZH��Ғ������Ûa8[9$�<͔�ަ�_6R
-���JN�j�+̭B7���vļUD��jD��i%v�ĎFJ�B�L�.�D��i�:f�(��ݬH���h�����^������dK�+mGW�z�T�MO��8�/���q�"X���?c�j��!m��}���7��=	iM
-�=o��Z a��P�|O,I<��L�}��9E�-��Qr�PT�Bnx��Rυ5�Y�.nJ����3t��]gqq�p�$�!%��R˽�H���/��F�f*'��)s�y\�~^�K;a�G6�	�Qխ1�,�3�[I��f�KH��jv��q#��� ���E��EE3/*��x=��N�8�|D��8�Ŭ&Iw�i?���$[�T�׎Av#.�H_7`�\�l��տ̲�$\�>f`"�4�B�]�*�
-�{������b�ʁ�и�P����8��4�Pm��G�`���$�<�!��օ���
-����'ld�1�[5[`�b�Rr��3iI d;A�R
-ҿP�7�����ɒ,�()�1��j?��X�'/iЋ�thه�������HR�;�"�[)ׄ��z�pn 6��<�uu$M��M\�s�(E��E~��s~��P��rawr��ܞ4A�[��࠽�C�Xe5���^�J��Ƽ��7��U6���4s5y�؜i��o��H>R���]Iv�"i��w�V�#��<5��&="���DQ#f�8[.��C^�Y'��$I���yL��
-�m���]���3˥��K�[H���Y�	�%)WB�n�i�Ӳ�����Z����d��S�C�q~N���J��(��܌��vyq�^�g)�=�H����Ⰿ��J�I4��N�[x�&��8�ٝ�V����=I�Y'��.����ieT��h���ԗ�p���X�Ek���;��� ubh^H��Ѕ���x�u�pׄ^��t�p(�,�w�@A���/��h�ۀO:>�Q�˽�z�{7y1�L�����WhI����Ѵ'${0�<���J�R��X��Z=��j���ßJ��X�A��]/K�`��
-�6&bk"�f)��꒹��BZ0��0 z���4��UlѮ�F� 덚�^Z�H�V�&9���������ߌah�#��z��p:�!@��D��8�������z*_���|��of�H����(� ,����p�B�흗 �Q0lբ0�+�.�C"�@�-0�Z��3$�,��I\F�I��\+�,�C�/��ǁ^#��u[���D� �f*oR�i]���/S\�T+
-w��R��y?��Y��m�� �j4�lI����R��o�����./�N���h-�졯��r��LPs٭��?0��g(�m�;#T��U˿b9�m9ŋ�wx�[���G��}d�E��j��~Hɾ�x{��+� ��S&2߼�d_Q<�����s*���U$O{Ex�|�E[x2�)=��su�ojbț��-aԗ6�}i��$-��HC(�3�]��U6]�zXO_�e5���� �2�\M|����5H[*�V>�1!���({��/$�_��s23���27sD���� �$j�����&�S��V:�ݰ��*���1ؕ;ɍ���1���Rv�a��0䢸����Sr�)��]$[���&u��突zԸ��.P��6�kD��E�]a�rb�J�՟B��4��X�L��F�z�����A��kI��s4���焒G�ź�H)��0�1Z��q?U$�"�1�����B<�ZI]j�����w���$K���_W
-u�d�>j�����Yg9M"����*O�UcIU�l���\��M�b���0�f�j�7��WZn�#�B�^�0��YO������dQ��'z������Ł/a���,��G1?��h)�?a����e&߄�&ҝӞ��$�`��������I��T7�y�Ҋ�7 �(M�'���<��������¬ciK���k���ͬ}��ZZ��Uj�2@kК�	�`��	h�ڀ6��$x������J�+�83�>&�wy'����j��̔�J�Za���b_���s��lbR��1-��ꃩ�0�c��$��ڕ�͞+X��)k�&Z�VC�N{��\+B4�6��n4�Y͝�[��RX�� �o� +�Ox�����0ֵ�;"�{?�������st�W�3%'�aWL��|�"k��qU�Dz��Qk�78X-�����e�应tɪP$SLª�8�"���✁�m���!0���8삯H�1kװ�kݑ��4�&f�j'u��"�����5 זF�q��nm�g>N�+DUM��VuZ�lH_J�;/�=������%ccb�{6m9��=��1ħ\�G]�8��ỉ��=�7%Ēߚ����i�\�Z�Z�A���]Ia­�Y��5PXM��Z��Y��ޘ�}!�᩸>��)췖+�ߩ���C"=�C��<Ʀ���c���	 t��T�$�������z���zx��6G�;�/��1��E�x��b=v�W"
-���4�*֤Rs�)������L(!�P�4���|��E ����u�<�8Ŝ4��S������}�DT=bq2u��:D�Hdh�<S�3P_R��"�>춿�^b;J�M�W�i��{�"~Jɭ����4<�0�4���wՇqv���;f16m!�q���ư�}5��\�C�~S��\��~���R�k�ն��l(���k٫����X�E��33��P�so��~T�\y��K�§&��h>�*o�*oP(lf_NK���@<���۽���;�$^dY"f�.�
-����^���Y��P�3}y����>���v���e��i�G=����WK�W��嫢HeZ-WU������7��Gy�k'��� ����J�k+_�h���N�Q�mt~ƀ`Sp�M�G)�QŚ��T���~�_�G��n��fUS�(�c����s����|IU���n���Ds]�[�\P���t5�*-�V��fÉ��p\h6���� �]�$�9�.�t`;j�G->F���Ӌx%�3���`g~�{~��sUdGCEv4Tz�{��<(oc�z�.9���_a��94�Ȕ*x4(w���k#������#R;�8吻�0�R�����2ʴ�Qw��Qw՗Q����qM���*P���_�'���'�ܰqPL��R�sJ����j7�E�'
-ag'y��$$4,ĺsFZ4�{q��t?�WM������W��	^F:3��n%�gv=���NC�%saj��Nz(c�Y�����Mi�_O!^(R��i\�����������H�u$��-0��dī��+��=���)ޚ�VR�5����e���;�'�9�]7`m� �*6�;�s��k�.����@ɯ�B��V�
-"X(�'򥖹]�|��k����q�����M�|�>�23��gZᘖ�Q��
-G��rD+|�ux+_i��Z��rT+��:��Z�s�#P��-���J�O�jF�5?Y힬z*7��>�JO�O-L��4�p/~�U�Ԯ�,�p�z��r��� '�}1}�j]���ŧ&��.>�e{����դ�T��yjv�J�%�ùAk�#A?��ҧ�f~|���2�=���{�o�PuJ�`C��=�����0�؂���N"�7��Fk�)�d�u��;08(�e�N�Fl��T�Ǌ�~���f�G�X���o�{Ƌ���� �kբ4}�r��ش+�,r�Ûi��1���	#��LT0!*x�~�^�jV	5��@��{�JދJ�d��Q13�������*��M�U���w�v�M�>&J�)Ӥ,Ud�I��N��#�-��#4�`z֪�N�BAn�B~������}��-*��&���1��V6�^�V.�:.L�F��y�*�̹�$<�ui���_©��Uw�1��UN'v=b�h$80?ܩ��;U	�^,*�(���1�=I�@��twOR��I�W����t�I��ߔ�ޔ�I? ��i�B��-Bp}�渾,�!f�^�c���v�Ү���=���$�~S��'�Щ�S����@�<?�_o��\K��Y�|��>�
-�[��\Xة�ǵ"�FaG�?=��`�?�zԪ��@:�3 j����aPC��4᠂�,���5|P܊{E(�Oj�)�m����I�IÝS��-�H'�&���y7]|w(�uij̐������q����C�v��;���Lw�ە.��q���ջ�{����I��M{�M�9�[��o�$sSK~L�ul�u����Z�L�#eN{��s;��� ,�h#��;X�]f�k���C�Z��Y^�C�a����Fp��$����r���@��,Wg�跩WJĲ�ޯe��[i�ߪJ��t'�_6��KG{�1�bC��ڒ88`x��gw1�6"�𴈅�t3�2�;��|����6����_�1�ଋ�ݦ�h���A-��Q_�<!���[~��;x�nqh)`�h絾69 'a�"�S�����5|�5G��9�D��
-d�J��"�#13���s��D_��.s�<�)����#qr=&ssq;8ໂ,I�'$���ܯ��^������>L{�^�G��	�r@��'V���H�fR�T�f�egR�m�c�7�3s[�Y�8���~����P�J��R��F���N���~�ࣖ}f��Bo��;(�ࢬ�I�Ʀ:�D�7���_�4VF_ �
-9ߞe��
-O_����{T���Z1��G|T��g �?;E�3W�P��OwHы��:��\0A=�(xD�@j57_�h�����V���O)�S��"�y�S�y\���ơ�ק��?vD��>f��c�}��8��(��agʝ�
- �0TQ��/ʳ3�_&<��q���Xtd�=UҔlO�luԞ*9`O���J�S%��(��}\�է�N�w5vŉ���t^��������pn8}�w7��%!��3ڰ
-,���=\�L���_��V�c\ߎؾEE���������P��G">I�����/�����Eo�k�G���,���]�b-�i���iZ��<�֗�u7����;��3	}�|!�?�
->��?��K"pB��}�oi�9����	d}��62�b[�'��^D�;�k���ڇ
-��؆�}�����/�f�&��T�|,�;N?���6G��e��yP��î��'��x�����E>� ��e^W;+���Y��,�����1��d�گI&���vݮB��.���/�8.��@X�����jV�6�
-+��t��I��*��(��>q'�A�����"�y��ϛ4P�Axv��qu����.�dy���RLvgT*�U�8����!�|$=�?�#�[��U6����
-�~Fe J(o�P��'�X/���k�Vy��Zս�*/���D��j��1����v���B�����)�Htgl�O:�^�V/g��Z�����X-�;+=�:�W8�}����˼��G>�_��%�?�~u�*�
-o�[�>\x�b�UG���r+�t*�\�v���*�e�쏻�?�d?��/Dl���)�q���Ļ�xɡ»��~�?�|�+��=���Ӫٙ{���+<D�'��	���L�I�0`a�m�ʻ�h������<N��V�dw��t��W9U݊���^DU�JM۪�ƃCF� �.��Z�?��5��[��B�s����Z>���v�}B���O����K$$��%)�C�rB�4˩v>@�8�\����nv�)��)��䱞0$FJ��9��ITF����W��Ա�����0�~��>%=ꐚ;�z������n��|���{�]��T��#�e���L�����*_�ߥ��.��A���AX$�dz��ۛ�]��%�|̵*���'�?M�e�ظ�5Z7~�$��w��}�����
-R���$/�o���u�z��B�f�"h��B�.��M�"2��
-�Eک{��K�r��]ӄ(��٫f>�<C����/1������ر��f? �dTp��]�zz�X��� b]��8��Ś�!�+-(h?�5�-2�-���W�m�*��Y�	tx�LQj����(�!9�����ɘ��`G���x\+à���XE|�!O�2˜ǓHZų+Tar�J���2}�)A����1Xy�H��	2q�u{��X�\�BB`�W�[���L�:�2��+��sl�ͺS�SD�ik�9����ҕ�Ԃ�ߟ�+�Z���|
-�C��:�:�	 �"[a�����_y�[����oM@Q$�9�\�.�I�=��5��iOD�H{�Z�i�/i������y��봧I�L{���Z�E=��Y���O���z��<׷zB�gR�G�<k"�p8r؏������#j����E<��|��N֕�18�����N�b`�AM|0�;��a���0����ߊs����x�2������<���1F���Hf���� �&�z�T
-R��Wm�#�f�R����E|�.B���D���졺L��$��5j��?%/���!x4�|.���S2�O�R�i��Y�=7�4�-�x����4<Y�ۊ�aa�bP����w3��B�O#o[��j�,�
-�6�cK*���ʪ��F���Ah	k#�P8r�O���@W)��7��zO��/�ܗ��Ա.R��j�Z�O�R�ik���U�B�[v6�l��jV����h�� �$WU}zM5�Y�	He�:H܌v�&�%*����D>D�9q��HP4�>�L$�ڮ�����L���C���N��4�UI��"u�@eUj�
-�dEk
-.���������)�d�WT��}�%�.���7��41��Ƈ��ڟ�<�VOf�*v�a'#,�D�o%�@giwx���|)S��B��CX����/�HPVֳR����%�"_,CdyQ���a�?z�:e�D�B�����@˔~�aJ� �te|S7�3>(2RZ��ߜ�2~ne�Н�!�q�F��d\K��g<`e�wg|Xd|�2� V�=���[1�O0)^���L��0��F�����T�t��{""��j=Z?�bqBqT�K�\�\�����c�__Zn_�������AN����[��(�%5ͯ�U�*��?v����!X������F�[
-�H�:�!IA��z�����I���-��T{�=����gRZ���u�`�m}�`և�܆��&�C�e��OWqrka/EWH֝R�2@[�v���/I�b�+c'e$V����b<3_ĳ+Bl��wW[��vj���:fEP��>��7�p�C�5xzT�Q�X<�2�Ň��.�5;�c�q�z��>���1Է��m�C}`A�(��m�Ᵹ���5�D�`gC�X���e*�mb����e���9��#����*�ۧ�C���+���Q�{����{?�����:1�G೪�g5�y�f�û'�SO���Ƭ��"Ve݁Z{r��SmO�߈�[#�ed���Zvr\r8�f1nn��L<��Y���Nq���b�]�٬Ii�;�g�������QF�R�ѤX���A_��� ���	��{���SkZ�tx�=��Ԏ��x�X�Utl�$$~�G7'���R���nFr�%���d�.ͨ���YF C���-�<1#�o�#��BL�)���s��f�������GT�	w����&�j�u��Jͮ�VIs��`����M(%�V��P�2Ije�':��Y4��aFR���='`2�2gf��9��ck�Z�1[���RJ	��H���Y{��g�*b��9��Z5�>�46�Hǅ��4��4�2X�7(zYz���8���&-�� [�>��{B�e���YWYa,��Ɓt��%�d�U��H��3��:<��Ɩ΅3�s�s��p��@;<�V�Q�^#a���Z�@:�rj���w�l�?�oT��)���LFXKN6��#g���j����1� ���]ˮ�ٍs�(��:n��q��*n@:�o�O��j�=�6�'��-�qU���D�j���l���F��	��pNIX/FXF
-�
-�t��+WRd�!2��	sQv"<X�_���SלzRX�#���&C�w{���l�2�����؝�w�оEi4t��]�u��+��	n��Ɵ������`��h�Òd���岞^�r��*k,l��M��>�2�l�� $(�6�\X)w�XV�+����UL��_MvTr��^Ğ�#�>φ4��-E��ٽ�Ǳ����:�WXv?(������ǖ�0n���O��|<Q|:����ωp�`����h�i��@�԰��J�>#0'W�yQ���^C�	W�	w
-��G�#������>�a���פ��r_���o����虑:�X���( �}�H����8��t�D�t�=�z��>��ib�Q�,����#����ߵG6��u�t#��kK�6��6��Q��b�����I4����4��[�2@��x1�x��)b�ذ y�1^�����.ia޻OL���"��C�B�ߌ,Cb0�"�H�t�T8i��(�L.�ؘيq��Tth�2MUv8�4=�=��IiOr*<x<�7�%Z/f1�j�A���@bV1,I��l���� ��
-r��Q��U����S�);��w"R�.�~�$=�.I��wH�s���5���7{R�x��GQ��4�^�B���A��9.���}�*�лh�NK�.,�iy,l������g'�m��׮^�ë`��Ӻ���U���������7_R�W���9�ʔuL���bW_�bD�bD_OQX�˯����ujnv��糪��v�ٗSqH��ڙ;���q��ʫR�a~0�Rťm7B+�_���)�p��N��n+�i��C�_l���˥��v��E9�1(�ђK��s��¦I~��ۣ��wx��{D�? ��jn�ڸ� �}�/ ���4��w���Jg='s�%)�|�^����������[N[8 [��f~;�Ny��]��2�R�v���:7^/d�H�|ą�����,����#�2�g�2V<��ʎ��qmx��l"�.���w��ߥ�SקUZ���=�J6�n��K6_�_诿n[���U��q�rƅ���c���^���T#���H�C�WC�^.�3�������^L���j��	\���Do�D���.�����'�Y�U>��m����ƓZ����S9������c�I��<�2)V8����� j�o�8�����WzH��2�[2KZ��[��c�G[2���K�o����\C�=�&w&{*�s���pa�X.,v�Å^'�.�w�Û����f�A��[��p��#�X�"��ʢp��p�.�O<^	6��[ۓ�����jI�����K܄����/�ᴝ1�K�s�sb�XM���x+�����}���W�D�r{6�,M�]�J@"��E$����E���6'�d�>�	,o��v+Z�;��S-�,'� ����n��ws��B'������6�A�*����0�
-��y��v�:����pO���L��O�����p'��@�������k%�s��.o1�H��ô�����R����޻�IUey��D�xd�G�� �*լL
-�ֶ����n�z�DQt�ʚۭ��܈9Yw����[�3}��'M�oŷf�4��"*(�af"�����(*q�o�sNDd&�5S=��񓌳�^{���k����k��$�ͥ���j�VKõĶf��2�c��D\no4W =U���Np����� ͉9%�xjΉ�ͥnQ;n������{�y1���$�҂��O��;7�bq;��Q+�R�&}��b� 㾿�^~�k��;�q�������3í��2���{'5��W
-���E=��ݚ_����Ep`NLRf�%4����ܘh�fSc|һ<���~g`jH��oR�ޡV7 1G%*�S�b�)=���"������M�r��\���WY_���s�VEe�=-
-��C�A�����RE3}��C��04=��O�H��2Z�Š�A�z�Ѥk�na��Z)s#l���2��(�m�/c9�ԭZ������U������eBW��47��Y#u-T�)_+yÊ�FW1`�>�Q�P�/Y)�O�e�Sa�ClƉ_�����;���F/r������ܼ�Ì�-�0!Y3/�I��=�,9���stYN~�A��H8+PU��Q�{T�+���`Kc�
-$�7�m�d\��@ ��1yKL��0�D)�n
-���-�2����+�>�õv�/ys�obj&W�=9S��4�,��1�ķ!��֘l�i_,u��Du[L����5�t��az(���KB��N�X�ΘDͯ-y�9Kƛ�u��Nm�w9�t�C?&���&�R�`�'P}��O���G���pF�jü �L�l�JP��z�zX=۹O-Cκ�e��B>'��g��
-x�~wL
-�I��$�ROL�Ťޘl���`�jYL�3�{��H�}1��?&���b�̱��NXz���$=c�W����(���Ld�L<�� �'
--;��P�tS��;X��4{`����.�llz��]x�f��Xr��e����T:BS�W��o��)}n���r/��%�>���Jz��'����Ml~�M8k��?�3&g�2�k���!�RZ7����WR�8m����)~~�g��B���և�(Ħ櫅�|n�D�>b\_��c[�
-��Ӛ�>���ϲٰ�B�rb��V�RWڻ���X!�|Թ�&�-�ti>t*Ŭ�{�I8�"�n�pg˭���S���"�'2*ԁfy8n&o�IM��>�yD������n�FCQ���|�l�v�6������b9vV�]:��HDc�K|I��f5�4q�D�)Qj�]�������D�n���^z9d��lJ�hJ0����7��x�|Z5��|xCH�W%���U'OX�a��UÁ�2�?+�$^,x�#0����C$ww�TnGy�Fe�<���c�E,�|4��(�~biT \���sv�"�H˽�r�C�#�`J�ͺ��x�)md�cqI:�z=6�.�~��Á���oӋ����e���ª�h}Ԇև���Լ�jV)Pó��!SX�Rd7�;�#��"�����
-��,�
-Z/R;	�7?�Yg��]�SV(e�$����1�5^</"��f�nN�����x��΅Ɍ9j%�C���>^�y�),jE��n�U)����}?�������G�����ϩA��wd!<�����/���� G�R��D�U!J��5UcK���H)n�lBYSK�����KU�$R[c�H|�3m�"�X��V�ck�g�#�$�yD�9��S{�ҿ@����*��ĽV�v���R�M����oR�I�R&�H
-l慉z���q�	�KkeIV��xq�ps��C�;B���v�_aT�L���<([x��/k>b̯�>��@�)��֓.}����b�ė_��r�U���O��&���m����CL����l���x����d38Õua�DӠ.����2�p68Y�K!k����i��7��Wb*��^%�J�X��N ������q�Qe ��F�D�FQ��*��>���=�?������i<���LV;xD�������:��bni��4U���%�D�n�+��Hta�Br��%L}�_�U�ޟ~�6~$��y�뾓�� O����Kݺ����2��,=?�}�#��Be���nr��\iՃ����ԟ�u�9E�$�-�n�-����#��.l]��w�3�Et�]���� &���_eZ�H�0��N|�OvQ�5;"�S\�z�^�����O�0'���,�&��9�t K��d�P��A}�o8�Q��#>XqT�+�S�>W4�%�S}׋�V�r瀡��El��h�{Su�d!�'�a�>��.�F+����I�h^s>�Żi���FҾ��/Ș��q�gf�i��ݴO�I4K�.�ϡ=�̰�$OSA���2]�i��}l�aH�`p�0�y��S�b�����̬�<�h�*<m�TL���Q83�i=����j�~3�T�4�+�z�Q�j���e�����R���J/���o>�%ꞩ�Ik��8���#�D�x�4KWHF_$W^�_)&}�����sw� P�`B�Jr��H+s"��Ɛ r�����H�J�9&!���u�	�Li����M�$eU=�����߁�J��T���b�.�t���bQ�\J�ń]�m��їߦ�7�v�?��8O�	 g�q�=_���u8�ި���n���=�m��
-pp��k5����@r#�����d=�s��K�b�Ė�bn� ��V�V�
-T�y��v�q�xwx��N�Op�Ѐמ�k_=#�hU�wم�]��r1s
-��nݧ�����q���Ѐ�K�1mCԳE��_�Ҷ!VF�`��k!�����������ݤ��7��u�}�g��u�S�i7�R�*���p�Z�Iut��d(<�� 4m��>�m2�;�d3G���-𾪊�_�� [���~��q���s�ƹ��`uXroL���n���`�󦶫lX�UJnWqv�Ј��;)}�n��#M�#�?�r�F�~c���P�%��m���p�T?��-]j�A�3b��;�RE�E�^������A��<P.�R���x9efCI����	@]*�>T�1�K�(eC���T���~M�􍲌(����{FրŎ�h �;��ƍ�7��~45�\m��4�p��[
-��ճz�
-�&��E��@n_���ǟ~�)�:�#�I���+ƺ�	�~B|9#�T!��R��<�?�3���C��Q�"(6�b#(6�K}	e~��/�/���Bߠ���0|^��^���u�E\���[ɔ:̃�*"��z�A�#DrF�:E�a���hE����W�:r�YCY�ꇕ��׫^9�8��z/��zS�^=����Oi��u_�v�C��h�ㅘl���XgY����$��o:�%�;,B"ˎY�v��w���}��e��p��WN���҄B�>��k}�`j��InP��hni�%�UN�ƟV��כXi�3�l��	t<���#O@Z�!�,��ˈ8�ܬ*����u��=x�.�����G���	��&��gzS�k��T�B�u������:5�5C��_a)Ө_�ZD�/�,!��!�.�y1��C|6X��Yi)4�v���Щ��bnfx#��-5����Ks���z��(*�vZ�ş�i���C��5T\V�N8���D�
-udC D�sh��ߞ�j	du�]�����4�������*�Or��P�Y�7�X�M���V)���j�M��L_� P��% {��U6���M��8�[-�%�wFख7e�'��y�C�LP��Oo1��D�cj�<āXu��Z�nF\����eͭ�g#�/U0��{���և�k}�[�A��� �jd1�jx�E��Z���v��ꞑ�R��0?LU.z�o�]����ڄHV7�[���4s��_�TMY����W�Kԩ��T	é��F�~��qy�¼̳�J{ݡpD���	\"x����!d�l�q.k����1�Qt���ڪ�⡛�0_PU#�S�1N�j0{�2Q@�x��3bB�[Шߥ�\��B�����ق�l��m$y7�o��J�M�K�K����}�wC�q�B"�.Vϯ}D<#O�߃W5x/�+���-���y�;�0>����)�]|���V{Y��7�V��NQv�:�LaX�jIJ�5f��
-�t$t'v�>�~N�p�~h%�mr�
-6H�R�iܳ��G����r���|�� x]��&�k����YV*���}��S�J����_�������t���W�@h�]��I��F
-��!4N�и����t�q:��1��<��Wh<�B�X��Z����2���r�A��9<�I��$�gI�7��1W�ғ%5�d�dp�,��%�D�$�mn��7�u�!���V��a�J��zuX�W�c�����B�ٺ6*�%�1M�#b���)���5'�w�:�K�ջ�	�G����O���zs�3�C��,����h��z����5 �원X�9�*U���ڮ�E��ęU5������h_f���dM*#�Q+�5{%��	˪D�\��f�����W�Zi찐Ɯa�<i�v�,6��d�l�J�(g9��{�]�qS�^���{�!��{p���w���y�o�R�M�����!��G���H��<��f4��Q��[��?��/IJ�f����pR^���Oʚb�u68��r�יa�5|���/�~���we���nr�R��)N�z�u���9Rcb�+J�d�H���9h���C���q"�64z�#��AֿJ����L�x���1�V�,q�I�L������?)��Ly��V��Yy���OΖ)�ˢr��M,�;��|�P�{;�@�5P�v����E�S�|"��/�C�1�.O�|�d���ʒOA�|j��ާu���vU{��\mJ����!�n���}�c���_�֑h�Wm�[B]���n���>_�����Z���������(�\)��B���!��ߊUT�=ՠ�>~�#�߭VY�Ӆ��]T�ڧ�t�S�t�/����yO�pWθ>*,�]�W�|s������RG�*�_�%'[��V�6zH�J=ݐb�d��|����T��
-Wz;Z)�
-pA���Ƥ��i�����c�>�� �Ql%y�&�D,w��ťފMz+&9]��PjwT��N��3��ȕ�j�*�	�]�bB�CGYY�>�&^�OLmd�}9�X�O��ǀ6+�������c�:l���?�W��Xs�ݘ�\)���}����U>��G飘�?�+�z� ll�%r��Q����Cj�QH5djo�/?����ĭ�����N,�ʃ�7��,��fi
-0Kc��g�D����q������ج��o!�[r׷��5�Z�NZ�J]�+C�D�)�+Tj�2'e�=%Kk�b?\e��S)R�pz���T���K���C۫�z���o�K5�34�3<�prg�n�����Br���!wE��]/�A�O�&'�3ڷd����+����,�l@%�ݴ}�W�M�s3����I�OG�vL4}TI���y�a�����a�<�<�t2mJ��R{HeF6��ޏ�0Z������DZ��̆��.�+`���� �Ɇ��zʃ�Q/��� �d�y����|^���'t�0Yĵ�]u�N8��OԨ�l���^Q�lwYfh�	[]�(��E����a��0c�"A�ꅯ����޷$�M�ˉ�[��l�f^"��e���{�l����tE�W,�cM@��&Ut(�ph��������Rk��ab���8�K��d6:�_��ي��~��W��|�LR�g����ܙ��MJ<�����B?;Zr�t!�+�ӿ5���t_~�� v��YA���y�B�60�%��/X���]��A�/9Ö��u��8�Ѓ~Uۋ7|U��g"�w3���3CRG�����FH��O�Q�U�f/ڏ�ֈ��U�z<W�Fw�� oǃ�W���2����#����'��?K��o\_���e��O��M�2PI�}� r��Wew�}����R�Zi����j�6v@��8=1T9Wq�R6T_ҹ�,���;>?�s����ڂ��A���R~�l�*Ɏ��@$bx�B��/����j�:�*�_R)�՟�,�ߟg>�_b�Q��\Ǽ}I�MDO�l��,W>������JQْ[vGw<`�t�"^2�o��ơ���E}�z��V�*��,l!���rR1��ũ)�V_��[���IS�ʵ2:��r�h����:�9EEP!��&��U0�+�ߕ�[��ت�呴�Fq��M=_I�|L�R��x���C��_ip�2���N��B�7���^�*au��rY)~^Ν-�Ζ��\^���S��8���y8�3���^V� v�n��+��3�������f��oh�%�5ӟ�ͭ��|-D�"��&���5�������H��iqЃ�����|�eڐ}B��5�f�H9\W�TN4Mj���2�	�iV	l䄊�:���/<�	��E�,���Y �mn�Cb�+�b���^p�a�3�?��[?(%mh��������L�,%f���J��F�Πع#b���i��a�Ѝ��s�� ��R���g'�|ni����U��c��cQ��b�`Q���O�_WS���qbN�������kj��Xd�5�*�~UM�v叨��R�j�0ͼ���c���(뜽�_Цj��B�m�o�z���P�4�}u��o����tjށ��`L���'ڎ3q����w��C(>�s����yaKW��k�_��$!��흗��l����p������c��K��4�|F�	�P�ꪗ��sB�p0��Y��"4F�ƋP�~]�^U�}9��'��S�4�So��1��l,ef�$���t��͆/S��߽�X��܅/QkO��&���q��=� �b�DqD������8�π��q)9#.%V4�%ٯ�l�Z1�uA�X.(���^����&P<r&�F""�6qF��	��es�B�!t~�H2�/�5�^��;5�Xa������_j��X)����N�8"Ҷ_Us3��*�&g!���q�@�7���f��wN\dq!��P��ؔICB}��K��s�ay,/<������g*��nj䠹]ժ�O��������������*�(�]Y{&}(>X���=�sѪ�!������#w���P��@[QP��^A���X��ީ�$�Q�Vs���N����æh��d�)�X�y�K�(�y9�)�ʩc���}�8����S����oI�׫�^K����d);�J4/�0�e�ʴ���5O���;��17���o��1�6ʍ^���^�����W����<���0ӫ#�rI����#*�pa��KE5h?�Vq��j@��Bqq�v�����4�F�e8��~�W	W?N��]�q�x��ue�	@t��)(�:�b���s���AA5�=�>b�QY�j�w/B�m]ߩ�ƃ��'��x8ߥJX�y�m����T'x"N�@x$JR�EսN|q60ZgT ��E���P�+t�F��ɝl#�����(�ܹ/W[�N�%���p�_9�?W^q��ʽ��\ ŵ�#"v��:/�J�g(L-�V�RuX��P�l]�o)_E8_��l�5:X����s5���l#%f[���Z���φ!��F�k/����n��v�p��1��EW��a�k#E�°�?mBg�"Næ �.���lc���>�B����<Z33�q��*ǈ�q��E��c�#0�bL�F��p��&Ol�0�R����"/��]䠘;��Z,�bA5
-SԱ������X�p�� ��A�XNRB�.Kk��R,-��Hf@����
-6
-��9nB�k�[��(�VKKK�s��ÈWt��H�h�5��\r���Eq���+�ʫ��Z�\$�����yi������~�٣/�]��'(�S�o��	���m���ۍnP�+�n�_��f�	y����x��r�	�y���M��v�����c\����E�_n������������N�O�.��I� `yN��W����q��q��&��T(�������aC�0J��q\��F�r�uE�M%9�*��fËGI�*n���R��(w��W�ϩ��D}}��TG9Gɯ�h�vw��S�60��q�P��`��N�]�X�y]�Mђn� �� �"�ɧ��:C1k�Z�/��qDx�"�e�M5��*�$�v���y%����
-0c|Y3a�{x.xGu~�
-\G.���G���mLp�@��hs�MS�HM�f��<�xA��F����>0�
-Gg��M�_��Ք*���W�$��0�w������*�
-���#z���^N���Vo۫7�+�xW�q���2E��<�KqK_t�8��I��,!׳\Ƚx�:V^+ۢs�ّ�����PЀ)G=���J��u���z��z�S#"N�ELbI��-�M�i�NV9�I}�È�4~G4ޑ'tjX�[>�'���l}�-�7�1_��)
-���\�\��
-��u�����m���m��u8��_��o�L�+LK��RXcSz g����۸5��7���qt-�u��q���lĵ�qI���#�ߘ!O��o�*O�h�N��h@S/�[|�>�*��"~>�K���oYkt�W��j��ت*�v5,a�aԚuQ���9I����Bjfw�����y*U(��w�{�8���(�eP���^��}�v�&�����~�inq�b��e_]��#{�:�&��]�z�u#T�녔���y�*��^���������Nc|gd|�9�ӪRZ}��r�6�P,�jvXU�n�/Z�[U-/�RwEk��ɝ0C�e�^�)���S,w*���/�o�|���q�M�Uѳ�T1�?�D`ȇhۤ,aL.�&<�i]gPܦaq:�m��w^}x.)�LV�����H���`��S��(�EهGE��5�d�!����RdW�^Q�9�|sd���򫢆����?�l�X|��y��}l\ܩ� v�A��
-����r���Zx�
-�Q=J1.���a�u����%��A_�8���t��q��a���p�vb�I�����������ӧ�b�8�{���I��$�����K�lu-���~�|X�>��>�]?������(�c���}�}:e�@m��Kο��OGS�����;�{�#5��J2I�C���S���������_P�xK�w۔�P�$��
-�.�F�qp�F;���#b���g�2�*0�����S�B��/��W̯ĝH����˨����e)y�|�����M1���S��;�i@X%!���W��n�[XN�tc�Νa(�z�l��p����h�P��u�@!���,B�k�d_�)uI)y�ܞ�ӐZ�+����M���'�>�:*D�3�}FM��]!�p�Fh���di��A�*(=�	��Y�T��h�
-<ː�|T��ī�'�����
-|r�
-(�*�ayX��V���P!�mٟ���x�(���(�i�}�*�R�T��OݤY^�{���8i6']D�����ZOf}��V"(#���~>�����Ǡ���(��<�F��o8|�5L�aAMh�����W�P���p�I���,����g��,Y&�u4���xB10�8��p	l�$����q螉�cnL Vtikʊā��0��b~�	&,���R��yf6���Yt׍ƈ'J��Di.��I�R@<QJ����:{� sw�-�G�7(3wų�pЁ��g���$�Q��f�}p4!�L ,��x�ͱz��Av���4�Os�(��Ul���R����hf�L?�ٖ�Z[G�W� ��P���Nl� ����g�k(]���[2�z�g�T��\�	-A�	B��#"��t�v���BC8�V]�� snsH�v~�rTi��Q<(�i���D�*qx����+>ze���>���}��2Y�i�9���l�C��7����$���8�S��(g�!�	���	5���������9�i�F����k}t������j��Y�r���R��r�v@�����5z/�jǼ�K��Wl�ﹷ�}��ԩ���?�x�F�����ʣN�&��x\n1Op��J�6��˵�Y#Ԕm���#�2s��Il�ώ�zr��� [ܠx2��C�]nP<y��� +ܠx��d̸�/��/�)�����|��r�Y�����{�W��Ex:鉟_�u�'eti��e���{��G�S�7�r�t9��0sE�~e��K�J��9]�gh��Zz�v�����g�w�&�ĥ��(�Kh	����?��t�PJN�|�Uħ�zk��)��`����Z��l�7@�0�ΦG����(�������T�G�&/�7p,,���%�����(k&�%I�J�x�M�~�ժ�_󦅊����
-���{0�z(\l�5���YZ���L��_��0�\Gh���֗��,_2��ߤ��R��-6���5�/��G��V.���}?o-�Aկ�!_��3�mX���0Y"�/�h����x���D%�3��Z�^/��R��.6�$ ���B�K��/��S�ŶP+��b����¼�!��!�`̗�k�~��г�< _Y�oc2VJz�+w>�;宮.wg�a �c������2��&!��D�B�c���"&y�l/�&�#��i�[�2k ���(UD%�E��TM���6~�[�B�cm{�MՀ�5`~m���2��7ac�hM���(uKM�)Q��ZS�{M(�1�lM�s�c&Q�<t�㣑�6�1�"oԮ��7j�E�]��J�r��v���wp�"�ߣ��8��{���f��@'����$�/���r�9�C�3U��a�l�Fͱ�IHϱ� e�X�����)�j�>f�W���u����̏����Vn������'��z�?���S���M�/�����j�R[�~+�Zq�����q�Y/3�)]O=��G�5�u%�����*O� z܁N>j�&�q�f�p3`��J���W�&mxI��ħ���;"T\�)�W�}(�������Pܛ�  �� b o{��;:A<H�������Nzh!4� �q? �� �'�����{����j }�YMhV�#C���u��B�N��Iأͯ�(^��yHc�X��k��(^�	�G5�MBր=��_���/���ͺ�￢�)/]�N$����`d,<�`��@jͺUkT�
-D#M曏��K������˿��o�0���OU�c�W��S���w�z|b��K]���1�4�O�g���%T')7͇;1�� 8�mɇ�X����z1&G(�\�<H��Rf���C���d
-)�cF��y��Z��SF������~ʶ��m��mZܽj���ަQ\~0}΄��0>_W���F�"Rؠ��ɇd9�'�7h��]t��-ᧅ8Bpۉ4�k闈P^�~T��Q��"�<�?��/p�7�dh�9���.�)OADAP��r�|�����@�����[�ԶPǶ�Ds`�+���N����ų���}<�{Ɯt<$#��2Oʔ���SpY=�׈,��1�Im�:6j�X�?z4��<9��x�	����5�	�zT����k��qH�R����W��K?[�����"���5��[�9>��\��-�.�erO�3��J�����)�ڬMڬIA�n�L����d��a܌�q��ܒh��ftW`F��q,�]�T[��X�qh�C�N�P��gz5�%�wH�7�<j�Wˉ;�DO3V�T	�v��,E3�~^�>�R�흵	��	�SYB�`'�mD�mk�&�~L�%	5�!�m�ih�D������ܱ9*
-��R!�B�Ա�%����~10~��K�H�A��q��1�	��R/5��ϕ�h�%-���ѝHXO>���H�3��J��Y�O���l�)�d	o;����4ڬ�NpA(_�蔤R����Г���ZR�s+�:wB�pfe|���Mts�S8�qP���=�@��ZGY�?��峣~o5�g=�0��E�N�g ��ĝ� >ìő/���s��n��A#*�"pu��%�1̝�i��S2��6��>�6��5-سJ#��;7S��`L�TY�ƃ�z)��(��N�ԊY�'�!��Q۫j����Ӗ�#������&��r����ML�S"���nܠ3۟��\C$w�۵�g{/sx�X�Rbd��ml���B�ۈЌb�����3��\�
-�7Hܑ��0O
-��S�\P�׈%{����1�t�md�Y�\�>���+6-���&�ظpD�}X�P����y���B ��LT6w�b�7P��{��>b�-`��j�
-f���RV7���_�Q�_>fL:fH]ǌN�h�]�ؖ(	�=썡ܻ��#q����\|6�pݬ�c��<��}��9�U�g!�A��ڳ�b��[�h!;ψ(£U�-���@����UM�A�c�qj{�zQ�x����p��٫�Kr���؇���
-5�:E�ևK��S��h���sn�8��`�W�7�W�W��0�I����ω��S�S#&�*��|����ͳM�����I
-�>��b��R���֑��q��r;�N���dY0z�����h������>�m���x�Z��!�uO(�r�(�LL[rvj�5�f��L�?E�42��/>œ�D�I@kY[�Х�T��6c�ܚ8m�̻�iK�
-�̀�O��ܬQ���Z<Z�rk�
-�g�|�2�8�2N���z����'�ʸ����o�����F>�[��5q]�ʍ�\���� G����k��\s-*&?�Jϳ���y��5✧����"�a�zgc?�6�/���0�l��\7_���=�Q��P	��	��á@+��}���Męq>N�6Ƌ%��&pt��l �n³ĝ��7����2l,��^�1և��|p\W(R�ܦ8��-~蔯���{3�$��&�*���2�0F�����M�fu�mZ����������������jpΎF~K4rO�K��oկ����E�}i~����[��l��֫�k��%JX��d��XȺP�,��T��"?�4�)F�m�	l�.�O�V愖^��t�&z��qV�����������z�S��0�n���@�ye��0��E?tB4� K�2�]�LE�ٺ@O͉L����e/Гs"r!1���̋�K���I��|���Yr_fa����&� (9�n��efk�=2�^☓����3ڮ�3s5�md��nZ�(X���w�i��iE��B��S� �`S׆�l�!�4׆�?Qh���p�;
-�rB~ӆ�*���8����̿����퇠�m@:�[�X��l%�A'4Ra�7���z�l�����/?[~�l���e�\��\�N�����Vxc~c�ң��4�G�WVEp~��[u��ۭ�xO�`�k@��C�!x�0DA|��������zr���յ^��)��Ȱ�Cy(u�qQ�-��ב�lQ�g���-8��Et,C�J��r!��2�>�W�l�9��<�2�z&��
-`츳 �����Ҏ�R�4�H�Ls�@S��=�!��-^��	�[��{,��� Vyig� I�?��֥@ecн����o�z�t]���t]${8��B_��`V������3A�̠�y��vREׄ[�k����x�_`}q��~(ܥ�8~)�R�7Ԇ��{����3��P�@!��滾S���fZ�/M-���r�R��`j�^�G�@�;��su�~�G��%}����>/4�݈̑��B��B���*&7�d����oUG��GDXD�5a��@PF�q��v'��+�U\��zfK�Пy9X�Ok���sL���)-s�~��C��F]Y���2oq�΄��{ojj�׬PS���fLBXd��R���4w�-��gӫ<	wD��8� ��|�1W�oE���h�yv�:N�${�Χ�s�ԛ��䛚/?WG��"�,�©�:@Z�u_�F�ux�(����uiI����:� u���'R�m�倬�4P.����6L�Bow�������H�L��ͺ����?*�&��x�����t�;a'w�w���|�_B߾&%�PV��pP*�T���(�<O��wj��E�:ZS�]��;U(q�x^�k<���o� �V�:^J�{���p��"+�m�Щ�u����2�y+F"(-T�&��躘���'�� =q�򜺿�	^��L7$������g4�$��,fj�{�&M��̬Mz�8�Kqm.�-�>]�;��^æ��q�(����,b�(>���<�Ew�$_�NS�M��h	�ʡB��ʥB���!p/6���q���@p�_(�)�E�r9�ӿ:�&�bٟ�E}R�-����l-9�b?DC%�w�y7�/��T��߲���2R��щ�D1��7S����$�UJ�:H������[��֦'�{gӋ����n�g�Zς�����zBg�c�0[�?�ތ˭�\�l=W���H>�+�~��ސe���H�6���:�2K��ø��	��[|���n�q� �ؔ*��Q{@�Z����g����C���%�Ȝj��L]t6���?��%���)�NH;%��8�ճ�ap"X�1GW���ͪ^	��k�>����4��#��l�����Qv|�,8�>&��N��4p�0�����
-�ۄIHy]�6"��Z�n�lk=ۗ>������=���m���c�������s���ɞ�s;�3�E�~"q�� ��:�0�?������p��D���4�k��8�E.h�{���"j��=��g�:�]�s
-G�L+v|��Up޶�!�'����mO����6�%*0��F��2�{�"�߃i92���B�OI�I-���"�}���C�$�Ln�e���1n��Q�q�`���m� jՀ�.��I����P�߆:EBr0�V}��J���}bw�좂��88	�B�?���N�-}Vkϟ�ҟhNNΓX�6��"�$̆�wB� u(��`�wF�7�޸�z�Έ���}���O/�=z��~��3���R=��~z�L/�,�3���^=s/�"���Tuco���E����/�v�qȥ��}�˼)O��ME��hu�q̓}/%�?�{H �V��7�0���T}�#}<J���s'���N�^�Q�I��h�ao+��G�������<�̀x݃�L�qԃX�c�r�X�㼜�)A|f٫u��u�R�Y8j����~�_�J�xH�����'Qʛ^)OR)O���<�' ��A<��Z@��A�%���8�A� �)bA� Ļ�6@��Al#�m�x߃X�<���z[��� ���{	b# >ar�6jׄ����:"V�9�}㌜?��}(����tܗ~���q��v"7h�k�g�a^�Ɵa��L�5��PI|سI�1���m-rk��R.�����[Yn<�#=����xȔQ���!S�;9A��x�'�(��'&�I����zjf)B]c��~HO�'wǥ�C��A*��m��^�q�����.�	�ys�Z�Oȭַ���z��N������R�·>��l�P�6iO�5����Ԙz�#��g�/��&��t��-��"��qMJow�M�����Ͻ�����O5K�U4B��ԃzǃ:Zp���+��z��%Յnw
-mgLԃx��]͔�ˏl�c2n>DG���q�e�)�.(�l�fdo�ܓ_��v�_��7�A�w���U��n��t�����G#��D��e&����0���tWS�Am�Q��+�W�hS_���Ҧ�Q!(
-�nş^������T͵4�(�Oii�����A����&�cg�jbM�#�����am��,��m���o�>˷\�L��Kxx ���XTm�.|�yd?�t%��%�!y�o�L\%˙�_H!��)��[�?�'N&�'���H,lL�lN�jN<�|��K�eg��^x5.������$3�E�p�Ys�0o4����EB�ok�-�(��Lf���w�啰�,���=�����{8'PG�d�Z`ӥ� ��~�eBOOpo\Ħ_��s�:�	������xn_�~U�'���BH�	����{ݦ�G������s�6*}�8�Q�>�[�~N5��|�T�q�TAz���- ]\��-B��y�H�Cz��t Ho�E:@H΃�_ }n�%&�J�+�Pv��eޕ�o��Ĝ���AW��s�h?7��0���z%Pt.;C�q�� �/W�D2�3�8 ,�=�V�ʆ���F
-Ϙ�گO�����Nڂf�2��p]8���@*;)+ue'�<�[���3���y���`6<�U`ڻ_g�A�����M:}����q��K�8T�{H���:�wҥ,|,���t	���z��ix�\���q�D��{�	%z�i��/�Z���ʰ�h�C���RA�C�{��K:�t�a��D%�Jn�^hl��8q��T��Oe|8���Kw�k�tѨ��f��q��A8�4�� /p}1Nj砃S4q��#�[���z�v+"��V�݇�Wqb�J��_���F�tn`̼�������a�����r3T�C(��G#�b�V��!(�$���s���:y�:Y��,N|��P̢=���"�Ěf
-@W#}������y�$��E}�
-*̝Σ=D|�
-�֚�Ƶ����T"�����a��f�;���|r��4�]ʿ��/�� ���%k1'R�з�p�1ClL�*@.<ⵏ��/Q��;f̠ٗ���
-y��z,���;sŸ�2���#��#:��lߞ�����p�Z�OT-uĢp�=+�b�T�L�A3�G(M*	ـ�7@�L�Qx��| ��)��t�Pj`m��q� 
-T�t��
-t��[�p\���Q�F��W��� ?�$\lc��vnS�}Bo�g4�JqZ&\F``vZ�Rd�ޜ{>n?��W�:H'_������>=��N7F���}���d-���t�~����8d�q�>�f�)��:Ρ��~�Y4}>:3���eF'0s������X��������_̧i%z��uث!I~k�/(�?��m�o�q_A8ty�	�+�v�W�@�+U`�����
-�2C���w�&�a]���]�ы]��r�J:d�R'���`�����2p)��W�"��~�Hjo�0�����|5�F�L˧$��y�o�|�b�3����+O�H�c���O�3F�Kj����cr3�PF6�ޯ�W���5�ĝR�}�DF)�>z,�}�H0�9��J�\�=�̓zP�࢘���"M�0k�&�s:;9��yZ��7�C���cy�d��9��������xT]�oR_������^�	���0v�\K�l��&F
-+�;h{u6�����N�9���ǐ����z8����$�8=l��pg�9]$q��sjG���e�o��%�N%_��9Z#U�H qX�S���,7<�d?~d��s���1��gXn*%p0�H5zf��rh��x)N����G��"xT7�"�������ݜ
-�p�~����&���b���#w��_楸�'J��t��A���
-�� �8˚��Dw�XV�6O�"
-��^(�PU�;U�ۜ��G�X�(�U��� �^����vP����~�\5X���%����)��$*����N��AOko5�ݠZf��q�
-�,�� �<���d�7�'���`����:~2\p���dx��|>Wt�Z�j���|>g��qM���|^��������|^^�yy����?/���\�|���g�?<[��g˿>[n������Фx�Q�Y�0�GO��	�D�,>4چ���i9O��H��z�}�����`�~F�{��3؆�����A�vqZ���(Ҭ��������尣F��8��	[p�V�~_�0�@��R���;�p�	��v�8C+�+�B�x��x���tE�����Ci�~X˜b�{A�m������gzV�w�9F[~���f�����3�HO��)Fz��Z��5�wB����Q0�P\��l��%�H5S�s�a*�̝et�2���m���K;{�a5����-�>����)���4��	���0���Fn�؆����GT�6�p��o/08�Yݏ7:�Wq�6t��°��l^�D�E1ݸg\�7�JX!�u�?�J��!���,�%�g��ϒ$�K��iy���p4\J�j�S��(�L5�>�V9�A�m�a��yN/�e������^x��]��>H��C�8�+i7;��o:��~��&mV�a�B��h�TB�ϻ%d�8�Ehz6�g��K�2���E#%�q������_�~%����s�#_�C&�M����c��z-���L��c�=����Z���{�)��B���̾���^��N[a�ӍywD�{#b�	�YA1�*��&���t�Z&�'��g�G�~�+��ߗ�{��keIQ�7@)қq)�Ko�%_��v\��<j�i�TX?R
-�q�7C�"~a7�c!TE.�4�J+�3m��?/�߇����\ꛈG�`[L�Hr7M.�v�a�'��8-�iTcM��l�)p��)���c�q}���b�a/�9��H����vԴ�����3�T�_�����qJ.n0r��H�`�������*[�8��K��<ÝՒ��T�m���sx9�`�T1(�& l��ay�&1���8q2�(�2��<���U&}l�HR��H��$�O:E���x�Ͻ�x�$�m7]u����^��[��B�f�9B?�m3q���L�0�&<��Q�4]�����n��ᓔ�jØ�.���&a��Z�?-�wַ�w�C7��kz�R�J����踑9�Ӧ/��16Xw+��%F)s�A�B�6��Q���9U�`^��?(�gzBnY�>�2;>	�&�+C��pz-����������5���>0T/Wpa;�����F!�@s~�1�C�b�=M߈��[{�!^�۪�VD�}
-�&����C%��܃�[A���@%�b�����T����ڗ��W���I��Y��,�6þ��%l��w)e��2xp���ɝ��t��@�=�1=Ʈ^1��q�~N�k��?��u�{��.��ύ���5���RaE4<���Z�UB�I��FY��_K��Zg����ug=k:�	�]U��%P��Ur�U8a>��z�p�5<��<�,|��m�>��lĝ�7��c�Y�����#������&'�F|�).��?x7J�UG❈�^Y�fa7D&m�H԰	��������ܑ��V�u�9�_zf%�J�33p*�pf����(� ��ͭr��6ν�;���F��u�����V�Qeð�W4��ܛ��"�j`�M�Ζ����`o���l0y��@V�e���u��9�u��G���n�B�G#n�B��>�z&W��8�BK���ڄ8u�U(v�dAS��c�y����H2�yH�C2G��j-ɨ� ���h�"m$�h.ɼ��1�dN��d^�R$���b#=k�$���5I支B2�|jH��/ �� ����7D2��jy��3tQwg���*���N�b���X(a{'O e�o1�sf�_J�l�K˺�����Kjk��N5�Q<[������;����=��Y��㬝I]�cG�2ƹ'U� *"���Y�
-����@;�� ����I��>���j�����E�/�V�5d2�����1�(�t9	j�%�I=kb����b,@�ԥ������Fh`<��U��x"ϳي�@L�f��� ����xuDep}j~���%5�U1�4��=x���˴Ɖ	��).��Z 5[o���A�(n���V.0=�lCm��y��{ٝ|�0J=j���t'*��i�R�X��w�Q�2&��l=�Gc6���d�?x���L�՜�^$��s6(@���C��4��~�����{�{����n�VZ-y��GZ����; A>_��1P���=Ͱ/ ��ģ��g�[��[{���6_�8�C��~�	Տ;Q�s��Xu%$�>a-�t߳~�U����������EO�Փ�?#y�n9߃�Ô�(H?�N����eH?ƒ�����Vb����J�b%V��[���Vbv0����J��o�����>}��ӳN��P�ޏ"�������J�7�w[�����J�Z���|����J�h���=Vb����wP�Z�+}���`��D�o�x�P�n�K?�����iT�l��iT�6m9�����jV�5�����@���D�S�/�.r�^R��������3>B=D[�@����ΖD������+zf)����'.����Z�mf~��^f%v��eV�^+��>/Z�am��u��e��a�y��B�a������6��������'����BXn��(`W:�}�~$׍�o�֔aA9��������?ml�a����+���ҧ����~j�����V%��^n�g�����
-������X�1�6+�[3�ڔ�c���Q%>7�r]�Pt2�]b凌�Þ�;��1һ���F3�<f�����OY�Mc��Ƥ���Ӗ��b���҆}�}�e5P�~�2�X����Ǣ����0s��i� v���^��iO�4M�����"ޚ��/��~e�QR�G�w�3ƶ�;�_o����M���.#]"�*�s�q uڇgPN4a��.O��5�	_W���T���w�nM��x̭ �
-i��,�t����m�	#��m1
-vtF~y
-}��7�M���D���ob��s3�NL���T�f��ԢǑs��k�
-�,�_R�n���ࢁ'�1��hj��Ǜd����*���챽i�������ǌ��o����y��:W�.(��WȽoA�z�Eӥ�+)����h;�h�������h�lb5 �X�����B~OCz5�6Rg��O������zY�@�y�'�	 ��A�ú�����E����K�����a	�ob쾠�fU|&,�D�[8+���A�z�hq�p�9�ۼB	r���A<�;x�� ���A�*4|�&��5`D�'3(��b����X��òX����C9����=�g q��A<���x�)�w)���̥U�����7`��ު�#�������<�׏�-0{�X�>"2����76�Xl)�H���k���*nyMʃU)����c�OM*f�[̂�K9F��j�=\Z�u��褕^'=M��4:i���0.؉)�� ��/�����a�O�;n0���-��0�������+m7�ۍ��֒캪���M�P���K���<���>��� ��Q�Hp�0��n�#���{���w*ioaJ��z�0u��v�D4��ak�g��p��������q�m0Fv��76z|�hd��M��{�^n��R�����OL�������P��1�/��WO�U?�aڏ����~j�~>����K񌱮���O�7��YoH6O�ݺx��
-��/�YV�铆"�����b|c�O7�xT�<͕|�)�Bv�n�dWuL�3�����a�zG������~?���P����]�,g�5̾Ǘ�i�gV�M�s�	?�&S�=��Hn6�I�rW�@���ez}��±Ʌc��{�2E3���}w0s7����E?K���A,{��S���r�! �jx\ɝ��r\��c���Ib���ݰZԊ�\���:^����+�Bn�Xh��}�T�1ݸh`��ɫe���=�6P��	EU�*>s
-\�O <@ :�kɟ�Ѭn�hZ�m��ײ�T�>�k��`U\���I@!l�)��
-~@�\H����sF�(<;�c�O:���6�ƍc�M%K!:+�П�t��`K�C0ק`��v�Z�g�
-u�L��ߚ��W�b�t`er���B=^��>��\��+@�F�}��V#�Ր��ܻ�h�bv�,�Nп�ɝ���f?h�b��6���%�>Nkj�k2a�R��N�Y��j�X)$�6����,pA1�]��E`.;��Gh���V������'�w�wqx��L/��^���z���2��:���w�&�T;�Q;6˖Bc��"������8O����[Q}¡��/s"j/�㵮�� �.#���r<��N�@��4����Ă},�����$��+
-:+���.�O��h_�C��1��"4E�>!���[�.VA�T�c^�S<] >*��,�g	�G#�-�1���ݐ~��*��	6��#�{)n��L��+�� �(�d����#�T���`����VL�T
-�.��̴'Z%���:�X��0�*����tysϪh�iBg�V�@�t<��ex佔�kOZ>6P o���$	�vʅdV\���UE�����m!S�������+LB
-k��W2h�g�Lu	XT�5��4�W�2�z�c=_b|�����ė��`��E�wL/�cBO9��zUz���E��
-w;ă^OSsz}�8au��8�k���V�^���}�|�Л�\OC�O�E���^�P,%�5��x˴ɘ��d�����I��o2#I�-��6Hu�A*$o��8z�����\�6�W'���b�R�ި�޴\�h7���_�����u&�
-]��5�P�=9J?d%��Y�>+1/�﫜.�4Ǫ9�8a�'K������T�����E�����(�8��d8e��@���=pWr3���v�����8�R%kɥ�
-��:�K����w�V���r��ٕY&�Se�\�T	���g�퀎�Ю�#a��G��26_{gib|�����12Jw���YIpU��*��_��~��;�u������ާs���}�T�����6�E�\�l�����<[0��5���+���
-�s~��� �FMU�w��.uas�*�K���u�Up+��"��ҋ8�nQȉ9b
-�]J&�]�5G��J+�o���J��2�p�r�`1�0y�Z�extw6�D��5<j��/J��(tp_��'��9��R4� �CѼ�����]�	X�A�X�A�hՠB�ՠ&�iPr`�@^�h� !>�T�/]�鰕g(�9:�R��6��;���x�+�v<�9�I�oծ��|B�����lv��GHֈ���xua�ww�/=H�U�H�w&�N�5������kƜ��
-�hWb�]a1�3<����Tǯk��,T}��U|5�G�������OS>,�#�E9u&�r�y_�yX/�K%!yFL��������[����_ ���Sd�"�5��I��H��E*�v���B��t����%��|�I\��/-V���UK�B,��j�0�S���$
-�)�K�iG3��s �$��9IlL^��e0�����fK� �h�ʷ�`%�֋`���GTH-����&}#0� �/BUxbU���C��o���3������`y!��?_J�`'����`y������3���I	3~��2��L�$צ[�'��s��rv�G��0�d���'S!ZS�|X���P���K��85��.Q�;&V='�^l�s��h/Y�hG9��7�����ԣ�� ~o�q8D��A�E�zd���>
-��p�����s/%��&]���Y�[�=I��醠���N~�Ѿ�T	�~
-�{IVE'�r���Q�*�/�b�Aр6���Zv��^��+DM�s{��¨�fld2>2#�$=B��q ��w��D������SM�Ô#n|�T����e������Lt<�v�{6us:�0?F<?WǙ�^T� [����(x�q<�S��_�9��<�KY0nȩ��y��n�97��u7r]�*�j��4�)������6��,l��Rgu�Y�u��٧^��$PÃ����hē�ݨ�����S"�z�7#�?{2`����C��ZbLof�������!q�R���X������)��6k���",S��b�����p?��N�	u&Լ�����)��ҟa
-�5x�%�f�	�3R\ |�
-���D�_D�0�,�Xj�Y��%��~�DpGF�k��31)���2-/��-L�}}%�7e/A-D�KHа<��Y 7p��(�[S��zi� �~h�b|?���Y�h�~����3�EC�|��2�Y�ޢ��0�##�r�	�h���񵧎�r��Qu,Wo[���)N���X�JO��1|�z{>�����:�a��Cv�� ��ԯ��#�n�S��r�ٶR��h׿U��)�!�Y��Y��Y�L5�o�&G�Ĉχn�:^W�\�B���N6����]膆�'葎�.�ǁ����U4�4��WB�����Z�7��@_4\�f&�����&ͨ�}�Y��F������9��$R�Vm�ܰ����K��	����1�$�Y�?{x��+���FE�'�:�,�=��&X�/az8��Nt����X¢="Z�����CL$�J�ix	U�*��e٪a�*����e�]�a��!RV3�K��U �}�
-�k2^S^��$�0����G�`)��� ��F�Z��J�@��p�<����!
-��+�x%mT��<Yʣ���L�Ey��l|H�?&�RDZT~@�nT47	�@YQ�-TP�RA-WA+���U+M�w�$6nׁ�z-��o��#Z�1�ңyL�t�5�_��[j�	��w#K��|�Ec)� kW}Ar�D�=�Ӷo�^���x���e@��h �2�����2��DmPQd:w����;�P��vb��7g2�2�n<�֏��������rUcs���U��y�!]�9�Y��.i;ˤ�����TlTǱv�IE�s峈����@WDo��~�t��pAN�d����!���?��J���\���e�`sK9�|�7�<��y���iE�����j�c�n�@��
-����7�D���L���/3�x9�F�`K`R�����2G>ĄT�6Z�G��!�x}��f�4��#�����}�L����ĺ���:R=)L�F�r��2�� �e�tB�+�	��l�Ch"�m"*��Y1!�+Jm�:�|�U�4~���m4���>��E+'��H��$�Ku��r��C�7g+Y|	�����Q�R,jt+����ѣ��)�'��6<xڭJ�@�9�����jĳG�fN����Ҡ����}5���K�{I��@f��^��F�N�3��(����e��Oq2{8s_D�m?���q�iG���Ku�d�I�U��x�~f��JH�g��L��9�#����WntB��v�����NF��GRm��P7h�Ḛh@<��᲻5#I�Sx�f�G�F��<������vB��D��ےI�Om ��)�>�AoI?��j+���)׈���r���ê�Gb�d23�?���r݄�ç�����h��QOS��D�4���@5 g'` �Z;�#����o`���&c#K�Yj-E�"�k2i�,�Fɯar%�2$8�	Ə����>-��061r�I�����C��(��L��S�ͼ4$uD�Pz3�dT��bb������
-@�fO�� <����k`�%����qz���T�J գR�ѥ�k����e� -8��
-7IƗ1	G�u�^����;�WXm����+��}��8�&P�P��G�
-ˣ�MH��-��/S�i�d������`t������ZmAx�@8m6�k�V�"��1!���ޭQX���'�x:��Dh���%h�b;�j��,��V@RF�i9���	����C�y�\���z҈n乕%i>��&�T�^�h�Z�U�3����/��p螒G���@��gK�#c�74�O�H�M��F=��K}���k�-`ȱ�߅�J/���&��#t�iK�70޴�~ЮX�!>]v��
-?*0��F�G��3�e�U�f�`��-�["�;h�D�&.��>����H��g���ޭ�K�#�����Њ����Ep����7z��y�4���h0�l�e���j`�@�-0w�߮�Gӏ����q&���[�1�J�ѕK��Q��>OU�`U��A*�����T���\��m�X�ǩ0J�q9�O˯�L�_G�$�x���X2�(��)��\�Z�ж�*���R]н�]>��W���P;i���pD�� �������0>�]2���ߜm܆�,yX��s1�©W��F��ڮ�|�v%�C����j:�V|�:�:����z�o[�1չ�����{�ƪ���\4���s'�T=��M�����(�x�wu�L����1ޒQ���O���)��t#��xUU2Rr����; |'�<5�iZm�h
-�����9����4^d��	��Cp��>��if�-M���>��@S,�ϊu%��Ya�1��rQsC�[��"�G7�X���m��%"9A S��~V7��g��P?C�v�>A���@Hi�S�t�юg��bB��6�NR��	Pl�Z|����m��V��U��x���	�!B(�T³�&�nv�����'�؎��j��� hB�Mƽ��E`O
-4��|�ϛ��8ј�05_q:��)���=2b(��6虌V��� r��63!d:�/��DL�kLk�FF���{�� �� ����G%dW(��n`�P��h=B�b[(�R��-�=?
-��Q�v�q�H�����T)����*�q�ϥ1���6�U���	"��p��r�s�9��o�D�������q�ޑ>�Bw@!j5t,uVu��_2�SJ/��J�R��)E̞V �*��L���IB3�5�� ���o>tG��=���K<��UY�qw+0D�VR}J�t��کT�w*��
->�ߋ#�9U�f�L}��}WIc�K�NE�C��
-4�Sf<����n�Xq,�A��*4'�z~�b[?�
-Mr��GY1�KbC}D
-��*�%��n~�K�-����c���!T�P��\����}O�3
-� |z��1G��)E�^L�&�$���8���ftC�O1>�O���c"�?8q��!�~~��#���	Ǝ?w)���!)ȝ���7L������fP�P&p�����C@^�A�cQ༊��6�C��'�a�`�u͢>�\J��ô~���V���-V��S���H�׃Rl����ld$�2=�x����z��}>�	t�B&h���QbxM����c�!:<"��+$�P�]p?u��O�����0zQu���L�=ԁK*:��Ѝ
-���.a���M(hbҧTp���yӌ�؜L��pw�qx)�W3�H/��I؏J��(1��^��I�+�@��tW��鰲@���Xݜ�Q+��Le �?�[�	�P�"������I�0����)��n۴��Z��8o��A|��f
-���Pg�1 �gts�0��0��m<T��,f����c�Y��ˣ��Ĕ7��@|E�����GW:p��k�Sl:��69��L��|��	�ё��i���7�)���@:����׎�Q&�Җ�Oo��ȉ�l(��b��߷�� :���?)�k�|��V�+T3#uL�ʷ�w�bL̵�%�g���H�n9�)�pR��h�A�� �x�L��@�L��+uZ�4K�D���$h#4@($ݸ>���;��W�T� ����)	]��Eר�z� �	5j� /]�i����M^Ys?&��v�1�<�p�?
-� 
->����?��o��(�hz������'���0�'��74655|��i��MM��m��O���_mjh$����oz�7��߾�;�w���`����2 
\ No newline at end of file
diff --git skin/adminhtml/default/default/media/uploaderSingle.swf skin/adminhtml/default/default/media/uploaderSingle.swf
deleted file mode 100644
index 1d3a0bb..0000000
--- skin/adminhtml/default/default/media/uploaderSingle.swf
+++ /dev/null
@@ -1,685 +0,0 @@
-CWS	�� x�Ľ|E�?�3���Jr���v� �q�8�;�;�����q:�Z�"�d�r�
-i��B!���{%��K轄�{���]iWV��������33��g�y晲be��ܧ(�\i��(�!52E�3����6�e�@*mM@�c�s��	��͛7o�]�f�����{��˸]v�	)v��ӹ������c����Vo69�Kf�-��d�r3�)5ћ/tp(��E&zǙ)s�L�q;��%z'�e���^���T�7Nō���՟�3/>�ܩ/���WHHyr�\�ܫ5��1[����-������vJ�(4t/O7�{lof`�`6��E��P����BE���V���k(='��gWQ�R�ެ�e�)\ŧ���C���^��d\>,�ϙ{���-��nǖ]Ə�����9������V�Q�S��;���	�� @�s+�w��=��9F��Plh0��'�lW2=;e����iT��b]�V��j��j�x%S�I���̝�Je����3�*X(���_���=7��#D:��}LS�EV.\��Py����V\x��O�M�>�#�X��/\�X[�hI`�O����?u��p�b�"���ϋ~?��>����u|�?��N^�+U�;��m��r��W��s�U��q�����į���qw|��~���B'|�D������Q{�>�-X��_�8x���[��8[��O<�\	L�9��ͩ�t�LJ��D�LŇ��l׎t��67�L��l|8d��mf�d�2��O������N�O�I��ɜꐃM�e*�]��L�&��}���A���i��F,�Bܡ,��Ʋ>:%�;d9����d��:�ə�s�n�)rbEl�9��ge��\�X<��e����|��iC=f�����M���xo�iYɞd*�nh��fd3�f6�4����t/�u$:3:930�I�&m|���XK�l2
-�L+�idr�����Pwr�����`w� � i���!˔��<'e�2�42�\��{h��᪮x:ѓ�_(��0H17�a*��a�S�U3����|�٩xV*�b���ʂ��N����e�"�`g"a&�d�>��T���9%�u2\�&�4gCp��eh�lm��n�f36W"��@�[㤡t"e:�n3�ʣD�2�Z����8;l*C���O��6h;��O�gI&gg���^��3���D^l��]�p��C��a�����if�Ù]�|���y��!�7i�UѼ�a��N��2��I�XU4�3�H��k��"i�l��Q��4�¶W���m�	t$�&6�f.4���aRp��ԭA,�;�D���z(�LYƤ�i�B���Lo޶�d:�I���~p�lr�ń��+��%��:�,�U��Ț�pSg�)��͜�L&v�y�Zsend�7?O$��ZD�,�f"*+uZ��K��m�݌�^[_XM�i=����>��Y����N�͎`��'^u�"�G�Mw&T'L�p�r�v��X�l|���.��jH��kN8
-N��lf _�E�q&g&�+���y�p��*�hչ��x�HB&O(�W��nJ��
-���4��Ty��N�M��i�h�ՎHxfl� iC�����n�%�WhY�m3���$�% ('$)�0]o9&��ɺW��C�U�0�S� ��yV(i��)/x��
-���1ݢlڱ_C���ԅ��|=��NJ��m[��9�K*�څ���͠M���>�LO<���_}^2��/0��P�L�k&g��dJ'�%3d�L�c�: ����en�Y��!^ziC�l&�����Ʊ��Zv��f�&tg�T��j��,�a`�$R�Vef0]2)�;gv�(4�Z{sC�TWr���S���H2�}#'a`���9@�[s��9wq�H �,ƣ��k��gâ/����
-l��U��y�Ja�g�-�O�*�v�c*r��|���|�o��2�[j<�jZ;�4�a&�V����K�6O�Sa��/Yw &�k+�$��L����5��Ob��fD,Gx�8-@Y#�H魦Y�v"�H?`}�PkzL�؜)WD�֌���I����٩>Y]~%a��L.�7,���r	���i��Qn�R
-9LMv
-�Y�(in	~�HA��gR2��Р��
-s��+WCx��3f��.K�?H*�Q;lb�K�Ͷh�/]��I��������W�nn+"'�d۬1{�U�:�M�$���@��P*�t���[�퉸l�\��t�������tI�l� ��e�͋��攙�K�dٱ"�p�ǚ��G��Ԍ�����4�6s�\�7cF��$'1w�*7��e�!����h���̤gw�}&ƹ�4�|�~mIi�ǳ�M%g�ԝ�Q(2���:B���F�t7��v�;��X�%��^j�"�(�9�Ͳ���I,랉�4b��T#�e14�q8^A��ٳD�u�m�m���i��$*Օ�X���ll���h�br�k6KX���zfdk7��3�6-��%�'5R2�BD�Ҝ�?�y�J�`L�J�"�&B��-X�O�:��m�+�n��G����Q��΋g4A�}"ʶS���.2O�*�3��m<�sy�gf����m�1�+�P�"�]��I s�*A�	�d�k���ޜ�-]m��T�N�F�l�ǜ�[�\�t���#+�N��R-��oy����K��<���t�6kΦ� ����A�e�G48%V�|{�r�Hg:	C�]B��(g�=�����ĺSU��+���	�h�Ѳ������l�F���T:�,��}h2E�b��*��v��S�Wˆ�ƅ�gsM�H̳V$�Ikh��`�4��VaS;4H��EO�lӱ��{��j,�����R�d�VƊ�M�d��z�rW�hz.tD���R�OΤ2Y���������M��0ƍ�2��"L�d䄙��[S[��	�}R.j�6�"�8W���������3�s���"RL;� %��@��*��'g��g�An ���9���㴮��w[f�;�M���]�M�_�8���H~ug�&fE�?�˰R��Y�cu���+��ױg:�Z���
-�H�%5#��hb���������[dF؏>9߬��M�p��ݺ��2�b�v�f�� ���cN!M	�J�\�٨G
-�򘯜�\��Yd�=���?h��RrX��q���N�a�nP*����!F=FI��R�:<Y��|gA%�(�>�̷�TG��4��E��Ο�Ni��6���JD��4��<Y{�d���zSf<+���B����Z��4d,I��e��I��� �3髴��g;1Yy�kf���hW�g�ܽ�ݶK$e�zW'�0ӴI���Ϯvum�Ԣ�%9+M��A�D7�ET{7!@����	�Sv)�zo
-_!M��o����	E)��Nޝ����(:>�=\�PYSha�r��E?�IW�2��l���R��i��Lo����06��Ǌ����kՖ*t�[e�Hj� � >-D�t_rvľ'�,-%L�&(s��Щ{]�2/5D��/����C�z��w0!���Cc:��/���T��E�/L[G�j�{p�=m���Ɍ��p���LF�Ҧ���7���k\�{� JVdD��;)sU�|���!I����ή�B(�=&j��STGY4o΀ky���awM��+O���������0m�F�Mm�x[��d|�O��'�V�&���yVto#H�ƀ<n5C=�J�����tr������]^!�^CjC��<����y��@	�
-���P�h���=eS	U����n&�y!Q�;0�=a���*�a��`�,&����A3�{�1�w�e�P�����ϊ���*�>�I��<ɤ��	K۽��w�c_�{�mK\썍[��ۮ
-�©x�����5��5���ʻ���Mm��':-6c�ʩ���fEۺ��E�M޷��r*�^�ΗhI-�D�Μk�v��h= ���N�m3L�Tڞ���XO<+�U:]��<<
-�
-L���\�b��E��R�o�װ�rUMi��a5�ТRU�e
-�U":�@9�4	#��ֹ��OV�d�'����}}0%B=������}F�����(]W[�A!b���cΥI�}��ڐZ�Fvq�Z�%��PM�9(��A�.����߲�6�rX�XE��)a-Ws/ˏF 6���PL�!��2V$�^��--����%��9#m�����`�4��K|@E^�lF�n��V$5m�gM������9�}Zw�>����"�Tǜ5���'ǳޑ�ޢ�.�e�a3r
-혗�
-K����'�*���e�[5�v�������=��ȡ�EJ�<�o���	o�K��'mVz9q�|�(O��Vе�i=��˭��8߁
-�g�W�{0o\�^p�H���bɲ�d�3��L窰s��i��'��J�-Uy�}P�o:� Un��uZ��}B��?+��w)u���'Ӷ�6�=q�yr��w�E/{��t��b ����)w��2�7;�LӕlB$-Yo�����L�:7��'�tuLjH�NP���v}32���֐�
-B@e��@2-=�����*���pk���3�4�s�X�r�o�M��4V�h�%U$ӽ���M�[�����+����>��S�,�F>2q�ر6�Zd#bu��*\�:/L�{i�̈́�`�o��٘0�)��w��cO�:��<	r��j��2LJCkj����2�J�R�.4�M9�Ө����gvv���r��r�������K�x_y6�^��4b�]���Iö���	O-��+��N J��e�10������X348XL�:��U���R�=�j�[4���ĉ���r2�Eo.�����}D�����*�%>O�,N��f-��\�U�9����/l�R�db�&�m2�e	�/>���o���(��t�6v����������B·k}�ۊ�ĵ���"t���'�tL#S��2���.��M�bBt`f���gh6��f�J����z���-,�#�żgle�^ϑZ8F���tҮ[�ϢkҺ���?s+�}����������WW�a�õ������(��u�w��t�h�)�;�Y���u���g�y�"��}�g��3��\.[kO�B�D���T�uɤ������O�.���U�_��׎E�L��vQ{�<ad��Txi�#�G�F��İ�c�e4��(����sC�r4
-�Y��(o;�tockJT��K�u����k3��1�ʹLZ��2�9������͚a{S�Չ��A?_C�ςv�dsE�[���Z�c_{2YrVm�<�.��������	��u�V9k~*���uy�[�=�C��*H�TUP�Pl5t�Z��
-��+��购���2;"T�\�1��8O}d�Ք�ogT�2�0]��Z�٧:���V�<m��m���t�i�{���tFL���8��-}�K�����=NIz/�C)�/g'	9������<D+;D7�lW &#��Qck;`��vZhN�Β�iG"+�Y�S��&��z1ټ�[e�'�En��ۺ�[��_'�o�|.��|ϯ�oEz8i�4���(�s`�=픹ܤEW"!��
-67<hv9JW>h,�%���ƽG��m����f$-:�A�JZ�E�Q�fnq%�G�Y�Æ{�7�J�̛Ȫ+�q�=�,L����^�����/����4%c�
-+��A�����[6{$�7!&���i՗��.��T���-�]�v�ǄR�+���h�/f.��kV�*��A;PY\NS�Eѡ�+��X��O�VU��n���9'��_���MP!W=�ji�����y�gd�������-�̩b;����;�o'B� T��'�T4�Ai���5�啭ce�e�P.���9Ǹ��O8�x�7x	�aR_�>c���]�"n�-S�V�p>�ӡ���,��� =��"�|!�m}��]~;aD*�_p�	�\yS�%t���7]���D�D[k���mJ�[�l��	;���1���SɁ��ޢ��7G�*�d@K礴�gU��3"O��@�6���Cy�U/�.���wm�b��b��[�ꡧ��j�\�+
-����92��;e��g����D]A�<�Ћ!9�m{���p��ޘ�� �e��Op?ωf�'8X���I�Z�Ho<�I�U4��Mypn<���!A'�E������}!(U3m���Ъ�;}lh�2��Τ�eB�d��Y�v3���6�R��r�SV{�����F�ϗ��0^���FƠ�K\�.&ʈ�v]aJ��zU�����tlf�6vN�y��S�~��P�@�sU�Ŧ�_gWFm�TUm�h�u���޵��*z�;C
-ُ��>Q��N�n�ܯ��c�9{u^;��^l+������vm�$*�*KZ���~�]���B���e�������s0�٤�h�>�)�'��Mm�ֺO{g�urwt����&��׫��wR�N�Y�im�g�s8O��Bn�Fڶv7u}O6�tS^չeOkG�3ftD'�v��N���y����NZO��Ly3����~O��}Ps�|n�F������^Ƀ�6���t�p�]J�rd��ֶ6
-����uZה�Sc��m��O{E~��Fh�� 6��uj{M�����Nx�F�,:-��<}ꌎ�����z(��>u�~�[/�'���F'�b(Ծ?2uu�/�9?	sm����n��-�����#J��4{y��2�Nkk�ȷ��8��ؙ���U^7����֎���;��-
-ɋ@٤����/mt����!�DT�#�鄶o��]��貄����B��6}Z{���b�䙝]�;c3g��ʈ�s���)C�B�([���i���6ἔ�h�j�P�t]R�(��iw���ݵ^Yry\�Y]6GP��vJ25��'��H�*���3���_ٲ0�s�>�/]}3+(ߚM���}"�y�/��=�Ԃe����2����$"����Z)L燐J�C�hk��:��[L���T8�XvڧLi��]���f�b,�.A=����m��Ѯ���bX���P��u�[��K}���a.|q�(��ܽ�_7���A�(�ol���]����َV���aTA��fL�A�g(� H��dh�j�&4��#F\q�ז�2��&����t��m���>(p�hWtR6��MYW�۱-��ܖb&��hk����~�?sP����}����~)�f���J�yFcK��a�2U{��$�p[�$�$xYY�����6p�Y��cZ�YQ}~D}��-<��p�3����ާ����H����ϊ6!^�%�+�s���F;��}o֝�͓[kaQ�{ސ;ɽ���(�R��,�v.�䤬J?8k!ᐃes���l�E�� g�O�;��nU���F���/�N�j��ײN����Τ�j��4%�qe��t���o��,U���}�b���"Q��=�,�Ce�����b�]���O�������o�r�A�=t}�����������r9+J��b�M��ٺψt�l|vQݾ�P�����n����V��Y�I���7N�i�ݻ#kO#�6��r��N�kR��~���<p�m*sf:�zhE����O���S�g����^ދ�eNWf���5ˬ��<d,����@)���m�LR�E%բ!=򝹧�:�<$h�($��E��7���)k�d/V�2-N'��(}��O��
-�;챂tL��3�A�Z�|J�����d�̨�ї�fv.6�1��q[���#o��=/t�h���t��ʴ���<��0��5�?�M� ��5�c咹!X�)O�ڝ�����l��?�U���X�R�2zp�G�V�70۔�ԁ����<Q�ꭒ��A�=A�nM�|����y��C��CoΜ��C�n����	��\pO@FA�������N��*%�҉inA�Ҟ�xE��v�f�=<3/b�;���4ځ���i�ЖO�U鉠�i���krgtFw��>�3�ܦ���m���U�����.���K��L��VzA�UvA�h[l��6aS��t�S��nt��S{EQ��,����ؿA��vM��ˮ��3zDͲh��Z:��q�:[��-�Պ�B�9԰y��["��-�9���.�񱝛c����[���R�T@kҼ�9ń��v��o�tYaO�u�R׺)Z;�4�Wϵ#[S���w�ݮ).]�/���5�*�J�t����"<0?���ÖΏC~��kW��!z����imp��'c��X&�}I31������(��3٠ڛ��5H�MC #�����ly�.��I:�1z�c�W.?Z�/���C�ӦC[;��%�d��Trv:����}J��` e�g���L��v&t���&�L��O�ߜn�'����-��F�
-R�/2��a�!L�i6{�5�<����o���7�Ɔn���[�ŭ�Z0-X}�-� �x���\��-3��%���YSZr�����-;����e�F�HX���y���	;�~n�]��x�._�t��G��B{5TX*��*,�Aר6e�K�P\���y�Fw9�9�5+a���� �C��D-/��}������<6����r��1���
-�&:���#�?hvOU'L�f,���:/�S e��S;+g��F+H�ҳ���}'�#�n�.�rc�|�%���?i(��������(�x��L��u�p2W�M�Z�|$�A��<e�NL2�Z���dy����Uvm��2����I� xl\7�M����P�z�*�×�1G�3��Ϸ�J#�itTn�������%��|Ϡ�`gHb.${C�Jo�}���k&�\OCRA��э��N�Yl��9�o�-��<b��8��;VU�k���)|�K>�_p�O����̳��b��E��hܛ��'{����|Q����}����p�z�q%��}s��}�	������卡����n��=\���I�#��q���5
-)t3K�I���(�Q���
-[2�e�iqZ(<�#�X�T�ůH�/SG�/$�'ӖF���[�=�4��zw��m�%M��M*�������ӧjr���o7��6h񕁰-W�����t����6/�%&�65��W��u��He����h"(�)if�<���E��b���2ƺ�cG�z>�[��]�p~D��4R����|�Q~����/�s4�=Y�~/&���8���(=Y��CS�P;�������
-7w�Zf�����Ӭ9���9_>�'-D_µ�A��އ��_�7>��'O$�ώ�c��_v;~��K���۪���m����>e��s`�׵�,��RG��V���|�񁔜�����l,�z�.0i5���p�:��Jd��?7�ydS����xO!�f1zY�
-�x_j�x?��l���=z�F�G9�����+Q^],�L�)nh$f�8�T��oG�g�*"g�gTN_��*�.�-�2�M���doO$s��ԶB���OK����r�cÅD�t�oJ}!�F�1��d�� N?��icU��+ev�~3n?F�����{:Qa���T,�N�/��o��i�Y�h����s�d�sڼ-ork���
-Q|�]�GZעg��GO�]d�쐭�eZ��P�{˹��T2}�C-c���F�RH`�:���S�4��-L(�n�N�ξ�����pK&�n�1[�A�Wn�Zz�[�,�wK*�+<�h����9�Dwl��k��������C*g:�i���{�S����%6���ٍ�7#�)�0{�����H��6a����3C��l��mq���l:諌��\�/���i���d�l%�2+i0uDv��i�Y��֡\�z�;C�t}����&f�D
-TQ��$�p�d�?_�6#�$Ӻ|�I�t�k�Ke�۔Yٶe�c� ֡lr>�uλ\57)3?��i�tD���vVIkύ #/d�Q#�2��Rd��3"tg��?!@�.��7=ko�i_#�`�X��Sa����g	�;�
-{�H����p�֒�k	A�Z䞩E���!i�s
-Z��a9� �>B�}�-x:��^�O��1:Қc1�~�_��2�4;��w�K�goz-�ʱLmᗱ����ח�C��NF���2MU����~�YfG�	��Cv]�iÒ���`n�G,�`ȓ�xJfc�/�`�!�c��ȹo�Mo���=��)�-�C�q)d�ôй\KC�����<�F7%\n�~�yl���۾%iO�a3�"u��I��؀}��+�,�v9��K�V���g[s�E�"��V�B,��}� ��?�_��}�4��^3���<7\!��~MM���L�󛦕��S$%8'�靃E���a2�N3K���*����Z�$ذSapxFr�������/mLk��|����_��q�ر�$�����k�����kNڴ�*ں��s��T2nɟ�?i<�LW���)I9}��7�� e������|�2�,�;K{�q>_�x- � %O��
-�}�b���o#v��g�Zz��-?��Ou��'$�Z��)o�	tg��c�s�������S��撒�u�vChHe�Y��w!n��������(^���zRC�>�t����p�J��YKA�,}�!�M�e��@<��:�;�b����X,%����q�|\��h��;O��TF�$U"O&K���kW[N����9`�Slk>~>�Ӓ~�7���J<c���[�Ąqギ�;��骲��9N��p�u��s~Q*���۱��tD�L̸TR%8�=�'�7�>qAΝ�� ƴ5���<_���b��7�C%��%=Yv*���T�`� �|�O���lۣ�O��v��a��4�T<���\R�g�=Z�����Ȧ�\<��=9�9G�=tPV�7{�Z�������3���� �qm�z��h��m`P�q��`��k�� �7SCTGRK�Ab�G(�d�k8��{f��8��`A?���i�k��<�9<ar3�gg���C�K�,�79tU�OZ<����A�|N����t��{x:�S|0�{�<���!ޟ��n��)n���s�.ˇ�|p�q�c�an!A���d�<5��r�/ΓY>7��y�0���n�9<�����8�m��O�d�X|`�ϙ��,�s��ͭy|�ɇ�\�"���y��s���4��R�d��	��yb.���iney�0����<���ԃQNO���|~?_0����j�,@��X�'��=<��q�Ǉy���hx����e���1�z.���$��sx*�S=<������@�dx:��	�6y|���,~�Ϧyv����,n�x.�sXO�N��5��N������zP��ζ���c5T�ʩ鄥������N&�b���9)57Я��jnnJ]Ѓa�����~�M�U*��
-�ۢh��Za�����Z����n%�������2sVL���3ŹS�$-�ɮ����⩖^����sa6@{y�{2�Qz�{�ٲ]��ȟ5J˿ᾓ�~l�t�7���X��F�q�n��~s�"Ӎ��怜ŹB[�ٰ���&�����5�#��C��5>�jӲIf`qŪ�(�`����I����	�o��=q:X5k	�$2���rƖ[9��������ZdD��Ø���/�ޏ��ճz�ި������7�o^�u������\��������Z�Y����J��XpN�X��5^�@��5�΃o��F��?���y�"��PUW�T�R���c�������S��������3�Bm�Nm�Aި6�B�S��')��ׁ���/Ԃi����4�߮5>�5>o�Z�GZ������7Z�Z�'�q���R=x�<Yo<�Bg ���҃k��st�R�z�y�{	=L�QB��/덯药S�=��<% ���4��� �,�2�x} xC�q}�������Ɨ�}�Л�Ʒ��<�"��u��@��@㏁Ɵ�E�bѸDP����2jt��Zִ�hZk4�m4�c4�k4�g4��5F���5��׹���i���v�H�2��D������;7�A��b���kM�}[7����p�%?1����0���������]��z�a��AoZh�ڴ>�tG��@ӛ���M���M?�3�4ƙ��,��Yee�h}ck�٬�v.;���.`�����Wu	������l���ѡ�����A��ײ�@�f�0Nc�3�� �v7R�l���M���:J�����fV~��n��h��Ev���G�����+��.YAxv�M��=�&���3v/��>P[�'�ޡv� 3��!���:{}\æ=B?��cv9~\��F#�`��')��)��?M��}4Ǟa@x��<������s2��F�=og����"�w��},�2%�0^%�k���번����T���`�X�jX� ,do����b��-bo�'x[ʖ�w�1��jYd;�mD���	���ٻn`5;���X�qU�>5p9� ?Fォ����,,�2���Z�P��z���D�A�QB4	�,�h�n&�[�"�-�J����b;�^�v��EhG��$��"<^DvlW��Fh�	�B�.���CD&��=E��|��h�I�l����p�Ч���+����(�?	�!*���t�!�?��.���6ST�5���D݁��o���>.�{D}��O�zS����٢�_�'E�A�(f�qc7.R�a@4�ECF4���ECV4X�!'�D�\�0O4�âa�h��h��h��h��h8D4,d�a`1`	`)�P�a��G �8�	m3���c��x�	��'N�8p`�t�J��U�3�g� ���8p�|���E#ģ����� �ЬQW�\����7j5c'.��cb�L4��	�����p��z���~�N��{7�{w�h�������~5? x�������?_�~��(bC�`��8�O�;(ؓ�>�\��4����PG�y�Yv�h~��Q�������x�^��LT�	?�
-H`�	�)��6��F&tL���P�����������O1�c8�h����)ܿ�џ���4�E|�0���+�5�o ��C��p@<ƁY��G�X�AXXX���oѼ�C�).F���#��@�||���&E�2�;ބ},�i�qps��xd;�٢y9�8����2�l��Hr�+ �ÿ�>1�8��U ����p�-#��������B��9p{��sA:p>����� #�%p/\�phW"fS�Up�`F�kw-⮃{=h7 0�F߈�M�g!�p�ALA�p+�6�0���#��;NCZu�wý��CZ�p?� ��!�ÀG �<��O�}�$��?x��,��PԂ=G�'�������0^��
-�x�Ҽ���o�)6����p��b�w����h��ᏹ�>4���-?|���K�W��� 09����;.�� ���Gr��[�w�
-� ,Q���a���pUD�P�v�*�?p�x�	�-W�ߢ� 3�Hѿ>Q�V �R�W���XX�8�?�9*Di1(�σ{>��~�*�/�{1ʺ��\;_	�
-p5�U��U�~�*~s`�f�h�ѷ�ⷷ�b��(�v�MT�NTqܻ\da7�ܯ�=��܇�>x�� ����*&<x�` :f³p���^{���/��/^�
-xM5�#�����MUL|�6��FАg�p����(g�G��A��������&~����~������{�? ���?�Mh�^?��3`�&�Z����K K>p�&�6�pЎ �0�+�>O<
-ᣑC5q�c>�qp�G:�a�	�/��0x5�$���ē�����;�����X8�Հ��_�|��ĵ��9p�����/�Ĥ��I���p�r��+W�\��O��u ��$��$h�I�#|�F�M ���Q�-���]��vL�))1�ML�p�n�=�{��`�< �A ��)�}�`����rʣ�B!Ly��' O�<x�j
-jm@��`���������}_�
-x��A�&�o�}�`#���}�z_�ɏ	�	�O51�3�皘�%�+ ���׈��=������Y�B݈"+�݋ua,��x�.�K����us�#�	8
-p4`����� ����w��u����Y�޳N��TݨDЀ�A��B�X�ڠ��j�t�׃��9���og�P��t;ɠ��p/@2���_���� .���/\?��W �U��\�����t�^�7�!�f��2��V]�݆���w;\��1_�T���;��.*aY��T�XAd8�cҾ{�dHv�.��G������Gt�z���BRO�����)�!���F���?�H��C����/ {��U]T������tq�ۺ����H���}� >|��	�0:��� �� |	�Wp��� |�w���{]�ԅ�3`a@X� �K K��f�H�Q��� � �8p`9�D�I��Ə�.r�DZ�0��0��0�C+1�� gDx5଀Ѯ�kb�� �	Mc'�,��.8.��P��s�G5�2T��<�h"CW���|��C����&34��Mgh:C����l����B�E��� .[r����WĿ�\���5p�\���B8�����_�~��p1�(r��D�mQs;��3 ���; ��{���l��w){  ���Lԇ��a`�/e���(�F�y���=x�O?����y�����sy���a/��ƴ�8�� z��� �đ��������H�`#�%���A��<�����	�O����8�}{�7�˷qU����?ĉFA�gpf��K�8��K�}(�	׀# G�v�h���=���,�8p�t!NegZ�Й�Հ5����\�p	�2��� � �\��p�V�z��� � �< x��1��� �q� ϳ��X�����Hh�����`lF���W�^�x��m�;���w��| �o?D�� dA}ڧ��_�|��#�g�� �8p8�H�рc �N �8p*``%``uPL<�ڠ8���9�9��  .\�pEP�Ɯ��;sq%��%�*�1MS��8�]����\��p�6��A�M�y'�w���#����>��ڃ���<x�$੠X�4�� �,x�s�{�"��X�^��U�k�׃�L�<o��-Bo#�`#�]�{�� >|�8(V�O}J�3�>'��|I������&(�b�"�y������� ?�Xd@��%���a�HC�aG�z� �g���xB'¶d-[N�	��'��B�:�|ȧV��U�3��f� .�:���R�e��W �$�/��}�a<�B\Я\�p=���T�M�`�%-;��:��L�	�X�Q�-��[�g=y� t�a����iB��a<o��/^��T�03�X�q)"��5øEf}�0^�ԯ�0D�M�o�l�kQ"�J�>����� S?�,F�s�|I�+B_�t>eK��C���Є'��8	p2��i���C�y&e_I�3��4B�	��k%��
-�A�fr������ӳC�q����B��ti��U�8i�dT�rf$#n#�%!b�Z���R=���2�Bk�0��h�T�:øynLњ�`�:T�a�i��\7�㚱Έ�"�F�b5�Y�$C��e�ٖG�cLYs�q��E�}�} ����Ps��\���j�q*�H�>5WæU��V\�VЎ�+$��M�xI�6^�̄q9�\��׫Z�:��#Qq�Zq�j��1�6j�k�	��-�Ek���Z���ء�:��@�3U�' ��L��?K�8pdXTw��qa�����'�=	p2����� +ȏq:"s:�X��-��[��0��0�oa���Lb�jBg!�@��(���z(�psV8�h��6�ͣ��y��A+�|D\ �0l���#�CM7~�57U��+��G��sy�i��:^q&���U�������.��.��ؕ� �����w5�k���(n��;�fp���Ak6����cY�hc�αo)7�j�I:o��8U�G�W��.ӌU�^�k��mu6���w���v}�B7���Y!�u䃺��n&�-�n���-*���U�b=�#[l=���Bg�@��fc=�I��=qir����q���qlh�/a�����z��Bo1�����[�h[�@�&�!�C���p�VX{��L�xIo4Z��)���<x��*^a/���e�+�� �^�x#l��oݼ���ؼ�q��-8�-8���Px[�a��m�3ۢ���l��n`k"@������7P?7P?7P?7���Y�X���0��Ɵ4cF�qg`�qw`�����`���Q�7Q�Ts�Ѽ��b����>pn�y{!���#�:��q[ h�����a8/����E��jb���K]J�2B���Е�n�tW��jB�ZG#wm�yG�|GR@c���qs�7G��Xڱy'��d��5>�5����/7�
-4� p9VB��X�<����e�"<�P�)���AVU���z��H���p@ բ2Y��tf{����S�Νd@��	WP�ʑ��r%HV�E�����L�ZQ4��:T�j$��⺦�X����)A�0=X�p�i�R��jm"�U�j���<u�ѣ���i��VF�I�<o���S�IÄpQ�� b����;X�@�
-��z]����q��T(�ǃ�Z�2�sn0Q��N��K�Q����c$K��<��g�� �49)5�X1ݕ-_�ހ�[N��Zc���
-1Ֆ�hJ�%?-���!4�t�OR�����YWb(�$Aڃ���|>9tA�fVM1�����9��٧�S��gz����&���gҍ��nf�B��9
-ht�Ҽ(���%����읭N�)���f_喎�(?��Tܣ����6�tPA�욮i�̙��"��E�Z	j��F"�@�pE9舲-Ƥ�2Y�V�n�'zѲ��]�����Վr
-V�ކ�l��K�˙V�)۳-y���DC��Y!�:���ש�����=���QWF��-���D!>_�o_���+G���ƌ˥ȓ-��c4wny`}���x{�Jq�v@6m;��)\��a���� �d�R4����/����1MuL���rq�l�vF̖�_�ek��\ީx���"�o��ҽ�c�q�|<���f�rH%��Їì�������F���P��[LI�o$E�0AI49��P8L3U.#��)���=��5���+�Z~��J��Ŭ���;{���4_��U��|�yO��غn������|��"�Z�Rx��Zbn����R�� l�����i����A��\Z���|I��ʋ�����n��8�w���$퀫\aT.Y���x�ה��1y�>.(���g�Ӭ�;�%�Y��嚷�F��/Z�j�P[2�l`����=�m�&h�����ڦ��=�-�����=\
-n]4��-��=�X�m5in���춓L�H�%�5��&�p�ɒ xR�p��[^��:�g��U��˥��P6mx�<�(ɛ�����em������^�i�pM���l+W�ҟT��?��ݣxU�P��	X�ῧ���+�y��	{�gϑ����[�lB��x�]�
-ae��1b��k�)��,�4��������tb��#mA�E���
-cƨ�6��-�x��MB���(r�9��_�:j��i�l��
-:TZA�J�?���/�n�+�
-}�Eh���͊GY��
-x���z�����Oa�Qv�|����U���E�J��VH�i~u[GJP� ;�|r2R�{����i����亂�o]�m]ɽ�H�H��I5�նAO����K٭#�K��D�+����j���9G�R�����ܶ	u��ƀ���ҹ�{�"ޣ�MM�z�����/�>3H�<o����~�.7�r���j�v܋��}	+��\F秷2n��Rur}\�o���#�]�6[���L��_tZ���O,�&���,�6�x/��FJ���"�"��nH��bx��>�g+(er����v*(����;��Ո�J~ic[<m�s��ި�%*�af���Df�?L��߷G[T�/SX�c T�#Wb�����T,�ӘR6F��fJy'S�]L�L��Ptu�~�v�zUu W�B�;��);��)�=�+���+[ǘ2��L�)Ε-z��m/SvIp�n�4�\i�c���Lٱ�)�L��A\�lWZRL�u�)ۥ��S�r�6�*�s�!�*�-�l�cʯ�\ib�6s���<��6_������.�J�?�2��LI��+{�[U:�Jj!�ʁ����R�?,Ƣ���?.i�P��C��o����	_�B��v|{���Y�@�9�̱��8hο����@J��~��l�%@�À8�O' u����@{���}ǂ6�$�~2��S�}*Є��_����ʤ� M\�P��@SNB0�����o��@�+���U�v<��C:W]o�L k5���g1�I�o�EH�{#;�\�������4�|�/� �.���^��r~1�Q��oإ���ˀ��ˁ�`W ?Ȯ�Ȯ^����]öTֱk�_¯^̯~���h���I�&��:�+�͌D�4v��;����|=�G��Q�u�Ff�����,v7�l`� ���>�߇������= �*{�K��i�a�:�=¶RNᏂ�{�{�8�Y�	Ğ͞��p�j�1�4���=҇lH�2�9b��<�9��8��|&{	����
-Ҿ�^E�������4{�j�&��-$}�)�0�Km��.�X�޳�>:q=�@v�CY�G�>�}��k�'�+��Hs%����爽�}���K��W��˾��1��[�o���=��,g�����6��? �G��$��YV��3�:��al1���%�+���_�>��%G�Vv���HN�s����eːm5;�����*9��H�4�Xv<����T�a�7;�W+�����v2(7�S�lߩ|+e;�@$�9�`�s���/�3@�����~v&�l5��<�s��CnO�`k�}����7������4����C��\��w�BT��]d7�b��e� ��/~�]��.GQ7��Q��
-�gWr���b\Ue-���5�_�k�׳��b�s���g�Q���&�?f��`7�K�-�_�n�v��|=�2~;'���v'��w߲��og���_�2�8��y�^{��ad�_������p�(���_�A�Ng�¿�=f��8��cO �͞D��)���O�"��tH���ٳ�ƞ>�?og~�������}iOb��t4�.��-�u���;؛4��[�J���ʳ�9WNa�``����f�����?e�#�U�����>�9�݌G�{�1/�O��ψ)�� �ɾ ������࿐-�A��k���������� ~��f�~Bٗ��Ay�-T%��8�H�I�x��,��u?�Nv�JW������Y7r~2I��4''��n.�@�;�����پ��z�U�6�L�1?�
-㕊�f>ĵcs??i���?��G���%>�������|9��'!������O�5~*�O��T�����Ay��D������W��<��� :W�E�&b_䫁_�g���P�3?��H�_�d���� �G�\�O�y��:W�����/Pi��C�wAQ���5���W�_H'�E����b��(�q~	��/Uɸ��_)?ê�1ƀ��.Q/y;�HU��8^ծ@�c�+���W�^|�z����UW��u ��^|�z�J�F��MH���VU֩,��r��ܬ���
-}�P}���q�%j��H�z�U��G��v����P��V��z�nU
-�=������}����_�> |�� �U�CH�0,�G�>���q���'h�oS�'�U}
-�f�i�[�g�ש��]P��,:���ZwC�U�9��~�y� u,3vc/���e/�d��,9�
-�yJ}x���=������Ϫoʔo����6���;H��q�]P�Q[j��Q���E)��+���w���>/) ϛꇒ_����1I�����rlT?���������o���!0�_����%�W�W�|�~���(���~�>R�ʗHÕ�^U�FU�iT����=FxO�G5������O�O�}g�g5����PЙ�"r��!c/�X[��6}S�j�Kڡ]l\'���	�Gh�=�Ԡ������h��Жi�r�vb�P��J�8���/�N���'*[�Tgi'"�r�$Ĭ�N�N;�Z�TM._�QM���N�N��	.���h�^�I�;�s���gkg_���P[�|GkgÿV;G��\;�y ]��OMa�*7�^hG]����ѺS�K��x�R�-�Q[�������Wh��ڕH{�v���5�ՔTU�AQ�h�R��WNԮ����ڍv�&d?J[��i7_��"�v+�i��r���#����R�e�TjX��˴�l�\�bO���&����4�!�W�M���'�p+��j�#͹(���ݻKP�	ڃ��Z{�Ӵ�iW�<�1�p�T�Q�m��V>����8]�m�,՞�9�!b���ƌVe����d�y��i}���֪<���>xP{�~�y�G���N�Eģ�%����]�ˠQ)� ��^E�	�^<��|��h���&���%kx��������j�?���TO��̌ɨ��/����jF���?�u|���;
-}YÎ��	���)����l�>�J���/����}	����"�k�7�oP����G�߁��=�O������O��#��,���G���X_�Coh���H�J�/�! ��O����i�"�G�b���À�FTe�~8b��?Ľ	x\Ev(|�n�[uo[vwKc,@X`z��a�$���Fɣ3���I�sՂN'�{?��$/�e����+��[�������-����+x�MK��a&������[˩�S�NU�sji6r��;r�����%�w�p/�sb�rb�r����P���?��6L�7z*�5u8ZB��;ō�^&F�R��Gj����$���?c4��ce�8�VKw�,`�5A��$m����+����'a�Jw�L�j4b�b�t����^S�x��se�V���m�M�
-�}�Z{���/����W�*�mĤ�� u�vb��wj' f���������f�A��O)[�� s@[1۵9��=B�W���Z�M���.�{L[��6%m�**>�\��(�\�Lp�kgA�:�͓��j�$�(T��(=j���Ք'�+5��)�~I[ ���H�?���Fޟi�C޿$K��]
-7�e�6�C�k�-ME�w��zI�"�?B/� �آ��L�����W!�h�[������Q_�ܥ�w��r��6 ����rGi����7A|��܁�p����׶����!�v��L2NWw@x�� ƀ+���~���&��H|OGms��'�� f��_���[��N�d��<YO�T��ׯ��3�v�_�t��l{j���R�c��؃�t죙zZ���{p��=�PǞ��g�%:9���7j�U��JF��i3 �Bo�ĕ��0����V�pHC��C�h�~X�#�_�$��Q�������׏��]��M�	p��'5�2���F~�n�H٠�Jŕ]:;��5�,�t/��G�e�(W��꧐c����u`e�~��"״�^x�N�ס����rVG6Blo���s�Ҩ��3����$����D����p��w�����#�4�89�k/+������
-�}����^	�	�<��__��|��*�e咎M n�>�S� H��#���C�=���.�Ȫ@b�b��r]g�t����=�R�>R�G�/�����h ��OўP����ߕ{�b����#9q���WCL?>^�L��ND��$3q�S��=�W��V�i�m�	�!������2�k8����|��l��9:1��2�+/��S��\]��� �)�ya-�h����\^�{|@,ԕE6�b�l���9|	���R�/���X-��8�`ǭ �	|%Ʃ�*;n�]��SS�Z�qK���|�3�zz�CUf�����7�R��QS�pk�
-H��k���7C�~�,���^�i+ൕow��j� �󝐵�=|7�+�p7���� u	��� �y�� ��|�S�����n�pw�஁\��ʧ�2�1�y�[x3��!p���]����w�.Lc�)N�B��D6��uX���\=�<�?��� ����6�F���ܱzJǱz�3:=����<n ����}��p��/�{�
-�����:�"a�B�q~bn��2��/�8����^�_��|����6�:�Q�~G��W�=p/�����-�~�+8}~ ?�}��W�{����C����O�*p����^��=�r���O�c1-|�EF1�Ub(��?U��a�\XR�����0����`1���� <T�J/�(�%FCT��81
-@G������+��-��9�ߕI��Л,��G(�����L1�b"�2GLw��15b
-�S�{S+��:� [�i��-j��%�C�<1��{�x�h&B�I��l<� ��q���� �¹�"�A��h��W�Z��,�C�JQ��|V���[,�()�!�M��%��Y,����M�L[{D=��F|`��6�������.V�	k �K�D�A��rTφ.]/�A�b=$�q�8Rm#į��ܛ!y�X�9\�[�p�{�nnEZ�'dO	?��I��#�ʃb��6�Q`��ZPz3�f���⏉� V�V.��F1:$��⏟3��$��Ż9��S����?)� ��ax�'1��y{�b�AW�~p?�Ԍ֡qH4p��S�MC�5��H��!�h����'��[�gM�+ȇ��q�G��`(G�G�	��!-6��38�4�Q(m�q Ge�c�ycp�A��'�j���1DeC��$�n�	�R���y��(59���������o��\�۩g����3���9�����<������"W�1����y��˧\'l8>����P ��@i�E��� �&��u�F��e]g0�q��q��Y�s]c�9����x�Y�l2'_�<I��\�W5�a���f�ߧ}�._"l'��މ���к�`L��z{6oE��b�8��8�f���>V�I��:�mi�!|U)� [�7���l'�����[Ժ�m����M�oT��jN
-�a�6ۆABo��d��ۀ7������ڼo_��l'Å`;�&���vq2R菳=x+h6Z �m�Kq2V菱���;0�j�?ʎ��J��J�P��.UP� ��T���h՘(|�:I�"�ƨ�E@LP�� ��'��Gթ"��S���^�NS��@��j��v�\�鲤"�֨�T}���Y�6�SgUi{u4�vP�
-�R���\գV]ֻZU6�l�4��B�Gu/�|(�QUݪ�:�]Y 
-`��E��Pv��>U[m9����~//̲jwe���H}x� ����с�q�\ _��;����t��[x7��6�3��]���~��~�d�G� k�?�	�N ?�d=��@A6`�d#��d��pA6c��d��hA�b�d�_� ���Ap����r� ��l'0�8����
-��T厪��l7tLs�w�|և�A"L\����{��d_�A�� z���b��L9	°�7 �sI!ujI#��� 29�h,΢1N�S4�z�E����[z�[˵/����$�A7oA}�vH:,�.ꁼ:�x�^�z��0����糵����+��z���{z�`�V��Vi�E�1W��]�i���c��
-x|�vZ:]k���hA�΂F�����b���z��2m �j��<��D��h.�ǐ���xd�vC��.�v�ن6e��4��ia\�<�}8����	��J�/h'���9��\+�i����A*o�R�,R3�5嚦�N�׵sP�@�Rnk��(�u/���w��,��y,v!�Y�K���oD�5ٱw�n�eL�)�N]٭+�V�7�B�]�k٪��z�f�9�k�-�,po�qW�����5 �0~&��M���H~�8���N��Yo��C�� Z�A���X�q�0��2{�;¿
-�u������D<o��'��}���L^o�G$�҂�8*H��X��>d�fA-E# �X	�~�0�A(ǅ^i@�U:f���iq4K��t�:��3�1���Z�v^� ���zV0�1��s��͆N��C�4������"h�:��:�]#�xPG:��zC�Q}S���D���X�Ga"�>�PQ�_�	�U�����D��"*��Nl'c�1�PL���@ُ� w����F�>ܘ�>�Q�j�aF���F>j̀J��:�P��h2f�b�1I�� �l�[�l#�GsŇ6FC�`��.�b�y�BH�v��uF�E#1�B�G:0���S�&O1����%�hk)�2�o��S�>J�LJF�L1NQ2��5J���w��Z����-J�0��]
-�S�*T������3S:V�b�G��SSU����*,�Lɟ��5�-������J%�S��Q%i?�E%��}x;�����*�S=�����J
-���y��`J��*�0��e�|��S
-71r�1�#�teʓ��Ĕ�N0� �Fj��<=V#�4�t�����R<M#5|f�F����F�<��n'5rP{�F�Ct�F�dʷ�j�Ly�s���ݿ��r����"��A�N�C����tr
-�å:�@�;�:i��wW�0�2�:��(�g!������28? ����NF�L�� |Kt�!��Ȕ?�oD�	��/0����̃�+ �m����皘�ۿ˔��������$8=aI�	S~+��R
-��g��	S��?b��Xh[9S~1�H�)1<�.���c���B�ɔ�A��{���=A���� �!�F�A��������19�o��9#;� �@8:� '��a���w[ty���B͆ѿ*|CI>��z')�&�^�I=�a���I>H�A
-ߠ�=q��I�'7m:����@ԯ�"��M�	i,�D�F%��\C�ا<4�'?����s<y����7��x�"�#]K�Rv�C�ߪ�a���úȫ�P'���j���</5�j�T�ԛ�ɳ~PV҉S4�o �B�a��)˿��DQ��j���;-PE).I{�h�T����픖�r�I\dqN]e�nA�˞�$.1�)�X� d�ZR����+HC������-�D�;�[����;?����S���I�C�"�:�-�6	���Z�4C+˙���,�, `T�� ���[�u�..Z�}��$\L���F8}YP(
-f��%���4�H���ҭ\���wHg��������ZXB�a�H�}�����7�XYb�x��PXe��hݕ�87*��if��b[�{8J�C�"E-�$�J�T~��zG�1�H���ƕ�o=׽�U?�z���7������Rӷ�˜��+�S4���w-�m�.�$���Q�b:J~�X�i�a?�*#��([c���Xg��7�Cj�N$6E��nA�U�i5vjl>-NΧ`h$�FRk>��4��Y+v�7���ћ$|�(�#�Ѩ���S�u�ݐ�Ϧ��1c�H��*?54�(["�hd U����&C��{�y��F���+Jt��o@DM�Ψ)]h��b�p[��V�w0HI����fXKHd'�������*�,���n����0� ��N#��P�OC+���\Z�f�\J�s��K�2����`d��@��@�:�� ��!T5}�i�QX�6YsH�I��4��}c*h`�$���hc�C鳤w��Lo�7$c.k� �vW��J�@��`{	�N��x! P��ӂ�����$f-�V:���(�����#V��J!؟P*sŮ�T�*R�6}�i �OD��XGi��8J��HC�{V��FJ�Gm�>���#j�(P(y�W�v��
-�ܳ�N����m��{���!F��x�qJ`j�M'Hk�XX��fk-,���)��e����4)�,UY��`B�kq�xU�I�Ґ^��xAc��0�5���΋v��	*�B2($�BF`3�y�����5�4�6f��G��D5���(b9ZB�(��N��}"%0�����5R�e���  � ��Lt���Q�@d!DB�cd�ZC��(s�u�*���v���j�����Qom5��]�� ��,uSBU{�~�莇��=������ ��h��X�$]�lD"L�yxC�v3M��h��$�(���,y�����A� `�H�g�	͘P٘����t-qL��'���)�-�S�Զ	:	�0$��Ī��Duΐ�L�!q��@���S'(�4	��>M�gHC���O����ɪ�r&�f�Z�i�L�����@0��nw�"�|	�]}	<�H��<�{�,�I��$g��5�F�urCM�����K��D��.ɶ�Hv�_��z� (3��������`|���k=r�z�r����n�%P9d��51�͖5Mr�4`�i4�9�>ǲ>ǲ��<A�s�����`UR����O������/-��qyN����δ���y���|�,h����̲����?�c�r�
-?u*�'�U��\�!�C��|�P�y�X�}E]� t�N��.���Z����U����p���E.��0�_GP��`U��� �J|�Æ�u)�pٴ�0�΂C5�.{�"Fu���i�VN�x"e�6��D�M8�*��8�&�h�-K�����I��N%�����jqnk�k�i�s�(h%�1A���m8�/���wR�w�@���Du4��ʕj���P�W%�J@�:�{"��v��<�Cm��J�{�t�d�N���51W�x���֓���M�0��A�kx@�W�\�T{[�6�B����X��M�[�a�@���JCA'�384,�)k�#���t�r0���~�d���V�9.��/(����<)�A���N�A�=ۯ��a-�2���ړ�ZJ> M0��:u��>�l(�2P�S?�]��a��V��l͔�@��S�� nC�"9Q�����,������������վ2z�v���?1b�2b#�h붿
-��$��]�5�1C��rؽk�7$��B�&��H��Rn�����h<+�Z���H�V:#�ɑ�)h�0���*[2{�����ˌ�jo�ɤe����=�:wdDV�"9�)2+��1o�����l��я��� �ި���A��Qc"�����p���1(�ƶe��?�TK�H�ҋ}�&��w�2����Ƥ]D�5%э��L�"*TA��i
-�1����%�[��6h3��gڲ�C�5�R� ��֐J��*��eRB10��(.��	���־)���4-����\���٤j��%��c�2���Ʈȩ���Y)c�d�J�ha�t{��myu&E9s5�����T�ʵ�
-�\]�Л@x�%��w@h�3��Bn�
-��j-�k��
-/��B�%�2�>n@�i3��Lǭ--i�{�@���)MEJ3�� ���`K%�oA�K�{5��k�ɹ��:>����Hd\��і!C4:J8���Aw�Lhq�8%�L�ɤ�j��g��D���oh|U9��j�����҅�m���
-�m2�'ҫjmq�z��uX��$'Z�-�� ��
-b[i�3�g^����A��H����ב(�:���j�QXQ\� ��+^.� 2k�1XYZp�L,`��"�KXr�Ӥz�I��b�$z��"J��X�8x�	����ep�������l�Q's)�ͱ����v��k��c@A�� ����9���U< Z�2 `1ir����`$�e��vl"i��R"�C;���y���&*r��K�QO�Qu��r��s�{r�{�ߐ ���_ѱS@+n�6��<��z�--_5�y:�ֈ���%&N�ŕ�L���9�li���}�ݪ�n�"���[\��Z.���
-RNB�mB�	��z�!�w+7ek����u
-�� �A#|� eG���ɰ3�м�9����:tV;��E��Pk�>"��>�$+�*�9	KX�^^Xj٩��9`�����Í�o��ڼp� Q���
-@��lx�<a�/�li�26&�)�aO�r�!wH�����;�$L�?��ì��`G��*L)�U����x�����38����X-I'kI�zdΉ�GR�GHC�P�&��,�6#��K�P�
-�Z��2dm$eZJ��u��j��@�esԔ�c�`�5dE?N�L���5d�>��� ���\��UA�V!v�;
-bG��02Fu`�ga�F������29���z�D����K�F�_E�6F;�t�%/�L"�6��|�x����\`H�,��o�
-�۲Bl$o�ɏ�":��"��7�^�����"���`��*��N� �Wa�΅���"�Q,fsB'm��Ҭ��\[�b��iv��M#,�z;rVf{�����zWN�����.�5zO�b	�7'f�,h���t�/�=�h� LI�}׏f�O	ڮ��B!�bC��� 
-jC��A��Ǡ.� �!�M�^gҰ�X�	2
-|Re7)|�e�4z���,}�(�w{0ET���;�� h7Y[I��1~��v+����7 @@��I(���O��iT��U%���^��lAc=�$l�W%�v���6<�`Y
-���+�D��7���˿�'"Z."������q,��y%m��r�qyKK�J]Z���e��bF�-Z�w�.�h��0Y��o���_����&ְ�8��A�9��/s"��1�
-��4�Cn2�`d2�注!�JM'�������}��d8-��r�qa�l`�����]4����m��͉�i*$$��"�M2�/`������-�e�o�
-SS��?3��6(!�'��+Yʬ[e�TNI�R�� .��^M�wL�fw���$�$���3ԉ
-���8�h��%�M͙"���--he;Dt(�u�NM���{ >�fcS��*Ll�Ņ��EVZ�!`0����A��\1��Z�$z�s4GA�Pr��p4�ًU��a��&I��z�ZL��nW��L�B��x{����	�o-�@l("�"�� �0"e�7d�8���}��Vb6%�H
-�s��(���WGƭ��#e⪑�mW��n�5����Ozp���+���qE$rݠ~��>�q�\�?�=>Dbob�dYWI�&U��A�̤#7��t�U�e�_�crX>��.��ƍf�sp�Y�p�y*�cOv������M��m��R+<c�����!�#0��`��ɥDOI�-��H�o�&R�-�[ıq[{Z�!^�I�!w��.�
-�'���}@E���M�T�s���� �)�='<K�|ԂO��% ������RNɆ?d/�L
-�_��&���FK���\����@���0�_�4�ۼ�ߑ��026_~�|a�����������6n��R"�c�F�C ��8�[�q#��i`���CD\O����M���%����n�::���]��<N��@CМ�=J� tQ��Օ����� �a[��<�p�p���b��V%�nE����<��|Q�pj�`��DS}���F|���)Z�
-+����:�&��$�b�)V�`_"�4�)�"}L�x���m���J�Iؾ�򠽁��ӛ�&c�A��
-�S�L���rƙ�����(����;�~��p'�S�7�=���kFq��|5��ܦ�A�&wP�Nyơ٩S�.�G�*�m�Y�Ʀ4|�*��RΓ�.��t�F��	����f�`5z�Z�&�.V��u^څ�H���=PV�x�������
-a-�ͼn��@���E�m嶭t�0-��|�&��`�"-Ð����;ጰ�'�adP�jaͣ��a5�z8������vI\�V?5�ƭ�9Em ���RaU�W	+#���x���?�"��	��^k��������0:Q���E<�����y)%��>�@�j��^�yXm������m��D"M��^gR^�ޤt��r��-������R��(�x�ȱ� �t�.!.I�q=����4�ZRK�<���ͤ0�Lb�It�Z�VU��q�������\�H�d�̢xV$���uq��,6�_r����Q5B��i�B��B!��D���%��D�)w��S��Zή(��IGc�-�X�e[+�m'�Nۄ�N½�	�����	����l�P�$�m�0�L5C�͂�M j�5�m�f�J'��������DL�$�Mp���*Ԯ�
-�]+����՜q�S��
-�d����ef`zߘ��֭���a)q�6�-b_KKt�l�J�-�\ ���O�9�-�� ���*�W�^���rO45�B�햔3��r_�,r���8�R-�D��3��I������=[�YiBc�!�!ٴ��gk��c E��(�~&�ϲͼ"�䷽�M;���މ���K8����ps]%:hz�b��ͅʙ4s���
-ҟ>����o����L@���:.������A�z�V����{)�HzLbXQ�,��ɳ��y�)$dgG�#T���|�}��ap�]P��Z��C�>*���5o	A�}��|���F��� �Zی��$�_�>G���VL��V�I���F4E��`��H*�u�FF��Z�&jD O߭V-{���(�.�,�E,�����o���R���0B�Ƚv�4�AL�Vjb�$�Z�lbO~h؉�S'P��I4x⚴��ZZ��Z�~���&7�ﴕ�&�h�KCyլ�QUz�m�4�l�#�;2Fo�h�FҒ�������\���2|�>$���aK@�l�[��+OW�7�m)�p���h9'<m�'�?�.�<V���'��g�Z�8Ǹ*��z�C֑��{���^�O$Z �ؕSǏ���.gg�N/�3��-�t�jG�F����4|�	�F����QfA�|�~\��G�d��ل1ٌ6�>7��7u{SW�7�A���d�ǚ�Px�J�yl����[Z�,X�Y��W�r�CIx���F�J�d�<�P�ǰ}�l��hV�>;)�����x��Ζb�`����8)�ò1�ӓ�P��xj'9���۪���ڵo*:S&�p�Q�h*��2�T���dS1�) �uT�3�Q�j*��r��L�nb��z��.n`q������,�0�}Ѯ�<"���"%y�F7�Tb�i��(��U��O)�T0�$.u���i����9	�c8ģ����0ά�Pf��ԅ��g٬�I��k� ���y��JjL4훤7��)� ֺ%�l#�k�H��'��:'mLND�ư��Y���g���9
-�˺:�4�b��I�6N�Q?��'��V@��X�C��X����#�z�(��R������)�=q$�Jzu+��̱	An[����������v{-����n��K���x^�P����v��B���F{4�0���fx�I�$�/%�J� �mH'�oq�������7;[�Z5ξغ��9�Y�뙎/�o�wgT�;����\vQ���A��F���q_H#�wzD�6�a�,�a�Mo�?3�Ӽ=��8���Q�����9;�z�P7���%�.�R�M"�	�rJ��3g�nn��� �7�H9�)��h�f6�U�6��e��S�
-Ɖ�lAz����`4(�D��¸��-���r����v,�5Z�H�$�h�T�1i�X:Q�&f�0;�=[���y!�z2f����ԉ F�ݻ��r�\u�F�di�f��0@������Id`��xE��n�"�T%#.�F�~*!�������uL�qmrّ);�<��?isY!��1Kh-s
-x�H�y[�\T��)�kB7Ź�Ow� ���4�6g;�?MY�VP�/�ɋ���m�E[�4Ҷ�a@�Mx�!�!a4��'Ѷ��L�"��IV�$�N����A��4C�3N�ﺦ�N�m8�+]A�]�+(tB[�,y��uX3Z=�=����K��0[6�R,K�Eie�����?�'0f�iN�uݐ��z	�$e�ee�c�ƴ��s����<}�M�����궭б�5��3rFs
-�K��33��]R�����vH�W�5{]5��9�N|h�Q�@� L:�V ���=�e��ҵDQZ���vhN���m�8yP�t����B�0��T'
-H�䀪Z�:׬���R�@�D�f�DR�gX�7܄��L�z0���멸�%�5�r�;w�xg7�iOEU�4H�3b�g�4E��tx8%�?��W��Y��v'w"���P�&ᒝ0�NSnW�V��և�!�A��je�J�&g��2p �{����{�Nڹ��e�zf%" �Kq��Qn�C�$I;d�$Ԟ٥1&r���(��~T5L�u��yh�xF)X.Th"�#y Y^8Fpq���z� ��6�rB0��)k�f�؎g��k$�CS�>܏���p�I0�oƵD��a�$��yb�2���5@f�ĵ��չ�ض:�C.Ͱ�@6�`n�Xb#����*��'�m6����|�OΖ�( ������JU?��-��p�/k����~p��G��CC���s���ݰ��5��ݰ���?�k\SN-έ:�B��.O���Ҡ\Z�]
-[W�����lQi�~�]h&��،|!����j��t!ӡ1������}��t"��Er�rٻJLO ���E�HTg�C/N� �[���D���J ��z�	�vCZ�.��BqU��.�q��{f�'l������.%q^
-X
-qr�9��"2K#~��2�H�CA���u�YSp�d��<h��3�h0�J�cw��K
-޿*	q��BLFBL�H��@��>�+�!��}#!z�Pa���_ș1���U�Ȩ[%ӡ��KRis�p��L�1ju��:�#��i��%�~̀��,(�ۡ�Bӥ�.)	z�n�R+,��$%6͡%��Bx� ��P'��{�@F�Dz2�}��8S��@�!�a���H}�P߀i��!�Q��ݞ�q( �q���ݐ�$�I�R"S�^B�a���p�Ns04�)S��pqkè#�
-���BcAa��p��|c��{A쉧�9^v��Pi�Hٛ��o�6������m��(� ���qԊ8J�h��뒗pt-��zI:�=��"FI��~�Ay�*:��"s�Z=�����k�2��@��Ii�0y�~��̱b04ھ�{h(���A{�=��R�{n��m{��+�c(��Q��0��ۃl�����kd�I�\Vt6������a�,�ThHk#�L�l���)�h=M���6�wղԩ�9D��Zj����2�jPK��k%4�,��=�����"��6=]�Ŵ���\������&?!���S(��M�c@�Z�1{ra�k0C0fl.�o[� ��C��9M�v�np-��Ϝ���b�wݨ�4|ЎzʉBEe�)��ţ"N�r4xAL�tL��ԏ2�̯$��c"3)�7�0�aL7���G���Z䄈�;!��W��T�;Z� 
--uB�UC�atn�Y�q�w!4��!�BC������9��hn��'w�}B�����[��[��~���-S﷼�e��������[��o�[Z~!��j�gU:l��~�Q������x��KݝM=��1u�@�b�M��!�3OiL5�H�W�t�nR����1 ����j�OB��WVQ:n�p��M
-�� ��P\�LV��3��y��פ�݄�M'R��������VRa�J㞱�[�}��/���Ab�� �G�\5��0W�!�X���7�����^��l��+�@aҔw��	؇��}�@܃N�>v�nr��Gb��*��#L#v��(LlV�W��������Z��sN�>���3��w��"\iE��\"���>���D��%B}.�s��vfn��s_��������6�>���������"_����e�gdzzG����ª�h�FXu�7
-�c/e��6z�M�����o7�3@a����n-p�����ƴ>��\L�s1����wv��i}.�6M�ʵ0��Cs� ��b�2����Ѳ��>�d��i���C5��LZ�:����	�R��z7�呼i�n?a��j`w�/n���Og)5�9��
-+��Ө��+�H��A�h����E���%�چ���ǪRѧ��Hd�J3�td�F�O)^p�}�o��#J�S�Ke`��npfE�.� �a*�bE���)����dɑA�XA^��^qF��̠x�mqn����խ5p�v@�WJ�m�����W��f=��<�\�<,��
-��S[nf��ٗ�@x��tR��R\"o���C��<�N&���̔:�d��u���'���ȷI"���r�v�|�1�ۜ�\�qy��A
-��-��d�m���mhhi�v�4��[��
-SQUe%��*�$D:(�d�4�lrq/�X��G�|���l��;j�nR	F:�:��>AXm���C�>�A�|��$y��y-��-�n���{Ӱ��K��LZ�o&�??��Xka�iW_��}9m�PKH�t�}#֦�M�U��qe��h>�3fS$�5��QAb�K�����Z�1K�[�<����HI%�����@)�PLt����rͩ�m����ȥ� ֔ݤ�x7�9��B�!�I�������{Ү��\�b#���Cu��´`KG��V�)��4���Z���S�}� Ŵblmi*��b`_YJ����L�^�ZC=��th-L{����D��5_K�	��5Zڅa�qy�G� ��i�%�̼�*d�� S+?@\�4}�)i��"�����.* {'��S�����zc����Š�E�b�z������P�3o�W�sh?��HKK�H���MIۛ)�C����ت���4��r��R��]���.���婵�嚊���,���{H��R��\��#v�tM$���
-�)��&zĖ��h�OZ��L>ZPl��xK�.��P�"��wVvp��~���+�T.��U�3�[I�Zr%qI߭\wή��4,D�幭�e�N!H�������,�q��+�{��|�x����"���V#{�߱�e�v5���x~4x%)�B���T�3}��������fF{H9��8���\ڃW������=:'�:�3�����r��t�m��/����7]�L�r_\ǽ�/'�fO ��[Z��(ި���w�ާ��^A/�p�)q,�~Z�n���qVg.�S�Hsj��y
-��q��/�\��,��6^�^K$^l����6�8���@ i��;�	�P�5ا�l*-�Yd��ulni���&��2.o�d�a_���z��0JK#փ��m?6i-4IG����c�+F׈��PX�]�.��Z5��ă$�-.[g��@AξBJ��nVqIC:�=_oJM�y��	�u�_Ȝ)g��ڮ�
-�U��?`/	��keLw�9-#w����F�5.Nm[D�m ����������?��=�z܏����b�jJ��e#�t*kВ�U�y9�eOu���5�6�'���'mc|~���禂���j9��ɤ���2�j�5�*���x��	��vU=�%p,��y �~�$��L��L�dz������`��^�5���f��n��Q=����[��V����� �qG�^9��'�2��i���b� |�ǉ�J�OE�qXg�����m�-�Vq1s�Uq��?�0ϗ/<���ǂ<���(���RB��@,�dZ9��R{X?�a���V��7���ɗ �J����{����k�7�h���ZMU���?���g3��+R�q���lmH����Ć��`��J�\���aF��*H�%�E|ΣI�o�7�m�HCY3����<�USJh�Zo�6���f���5^'��fh��l�fk�-fh���:aX�[��T�f������ �BC��N3���6C{��^3���7C�P�J���ʘ��f��5��f3t�}h���#f�#3t�3C���f�3t��4C���;�Ɛ�i�5��0�o���u��{C���� ��u�}Jw;u��ݭ�������>»�K�f�!��4�~/oF����qj�Fr}��|�K����XL>�%_�w@�/9��C�6��  ������M�̓7y�M��<v��F����C�y�:�]�1<y�Ǯ��8���O����i��U���tb��N삿���|;�s�4M� ��g~�6�Y�1��jD� �.�Ž��ϴjUy!�-l���r �ÿ7�����9HS�ݖ� 2�'9�!�\�%ߑq�� �����t���,�Խ�e�(��,����9Y������]a�H�����!�����a<��~�#|��pWR�ǵ��ևPW�ҫ���B���dW�(-�@����T��T���E�T{k��/y��'���"t�'G��}�͒�y�B��d���-<9T�F��>�%b�EhO�;<4�'��XZɓ�E����x�����=59H�F��.�!bwyhO��q"�ȓ�D�J�6�d���<9\�*Eh	OV��0�Ɠ�Dl�m��!"�W���d_��C�x�����<�G���Z�(b�D��'��X�U��"v��f��m+B�+bDh5O��"��'G��J���Y*U�4\ã3*�Bzv����3�]�OuY+�e��Z�񼈊P�K���5�l�<��1`vk�H%Ҧ���eiy,C�h �@�IY��rr5�����f�&t���
-NwkM� �yY�� ���X$㰈�sr16v����Tw^���#��;�_m�$l�$l��c�zO�a��{����=a|rU���z*1L��VU��l+��F1j��i"e4�fx��� |�/��({�)=����ąm�Fخ�`���k.�o���}&Dll�Z�.��g��9 X)��0� kpY�C{S���w�T-Oe'�}Q6&�ZaU�^\΋�E���������n����r�?eqPm�l)�?��(���Zey;<�m���}�Ci�]� P\���c� ��(������� �������:�F!�|�"t��{��*}&
-*/��� 	ґ%*}��/P��"�	��x��@�{���OP"��jN����L�[�d�T5�;�nDF�	hy�GvI��jOTU�i?�"R�)�T5[�@�:C	"����B8ĀH�qV��g�"_�h�J���T5$��5���1�;���|�y��Y%P���+�}�������b!x���>��pI"�=���zU#��>I���}e�y���T�O�ځO����hG[�UL�k���-����ƶ9��H �^�� ��KP�T�r��VN��Q�Ҭg����������k=QL�&���D�\��49��s��QXV�3A���*�0G�t/X������Uqĩ"�sr5V1KV��*抧w��\�%��L����HI��٢hr���ES�s�٭���U�SMA���f.���R=OUU�C��5����é���=�z��P'��B�����}�=�h�<�@q�|��#���f�� Zd�^��<`�Ø�y�F�WX1J/��|�+ �F�^���|.	V�+���<^N�v�im����sJR�N��꟠]�G�|t�'zٕ�;����F�}�c��e"1�9�������u<��o���)��w�y��ì%��%��?���--��j��� ]s�ڐ*ۤƶ����)�YݦZ�O�m�-� ���
-�	��^5����
-�j�'�+%w��i��h�DJ��)�#`ָ.�Z�-��˾�_^vS~E��Fn�
-|ʾP��j�=]�U�-� ��V�Qq܌~bڞ�뉞pc\O��s����L�4y�q��5�Yg�
-���]<�rݴ6ڻ�Y�M�k���*@��}1�T�|_�G���5���^M��ޫ�"�f�}��9�=%���$��e����h��WS&�f�TcKK�(K�>b��� ����y[��ؗ�I�։�ZII���0c�&𤱊����/Z/&>�/�����Sf�)yb|/��v�l&�1�P6K�=&ke�u����R�������^h��Bz~�*����:$K����n[&�L|C�W�*�Y!|���8��6S�3f��I�f�j�r�CuG��g���^�Wy�٫9�8gB�b�<g=�h��h?N�X��nJ�8{߽ˆ�>O ���R
-������.�/ODk��5�$���_�����g�s�2^膡<�T�'���I1�q��\��W	p���} 9l 6x�<�;��M|�#��4��+ܠ� 7��xB`����	x�
-��jar��"7$�9�ѝ�jd��3�J�cAv�6f�������[�
-r�W{��F�U�/��P2��I��E�kk�(��Z�'�Xr���E$9��ͭ��-�Rz�YJ�l�R��R�\�x])����Zg��e��d~0��;<��z��G�z<���9�(��U�U6�V5�C�]�|����Z~*�79�ew�l��4k@c�m�4G�L:�XP|x��A�6��h>vV�6���Wv*�ԭ�S�7�g�-� ���
-�:(�I��0�B�Y�KY�[�����|�r��;��e]QHy�q�%罦v�{M�aU)I7��ô�����ה�1?�F�3�T��^q<�+&d�~��?V1�,I���k����k����J�6�n����v��Z�4d�3j*|F%᫦z@�Y �rdB�M��&<��Èi��\G/CG��%0L8�j������^3I띿o�;�7����k��]7�m��������-	_Z��_��DMA>�b��/�W�������`�#��g�t�|_2�DK��a�Q����F�,B#Er��-�k<�L�>�[<���m��"�IĶ��X��*bDh�Hn��"t�'���*�ϓ�Dl���u"�^���z���y�^Ķ����.bkE��H��-"4Z$���j���"�C�&��[!B�yr�����<�R�ֈP�H���"t�'���6��m8OUu����蓮N|_��-���|E��D�;�� /��ٖ��U�h�C��6�xAEc`!�>�Ylng-6���Y��A��?�K�]"4U$w��N�"�;��P5����@�.�݃�����t����o��L��YD���gj�
-��+j�*�Eɫj�"�ɋj�2���؈S��:ǑrG�i/x�g������1xN�={d	�j]S�K���Z�q:�d��J�C�B���\>p����&����Q�
-�x<�O�E�Ra��]d� JJE���NO����n�"�lG�����̫�����R�~��T��������*>Uф�%�����K��T|7���Ͳ~�8�ZV%��� �uW-�T�����Շ�SA�|3�V�ZDgLǣ*e7��Z�¨�IÃ}^R����!���y����p���� ��!�2 /���"շ����G����=�@��]���>�Ra����)����"D-fV�%��@@�%��NfMdɝ,VŬ1,Y�b���K�b�ۗ9Z�����1$��d�ڶ��zKp��`�� HrL1)�+h��,2�)��X*�C[���!���eL>���.c%E8����`�A�e�e��F=�1Ѓ��z��A,E���R�X�C<��1ԃ�sbC��-��$��?)�Zsj})[���P/��{��ª�W�5�	�7��{�������U�������*����  �(b @@��L�^(j_��ӓH+}��0R�bLы��p�+ӂ2M�����G���yU��R��*GA�������� !�M䇗��� ���"����Y�!��4�'ɶ�:���,��a�e]s
-���7�fj��S��E��I���<�bp�,h[/��x��
-k<�U �*p:����1�a�!�����Lf-`��ɰ�g0���/��@�����PI�YlƧ1�6?�=�1��c�Ӟi�V��_�8��2��c�"f�fa��f6��͙�a>�n#�mP�&�LG��8px�3��Fk�� �`��0�Y�X��WIYB�V|B�t�(K����S�{�u�0��ߨ��w��ȣW�X*�K����V�@��M��l�ˑ��F֝�?�62k=�#Sx���p�ɬ�L�_��DoMl�����\�bS/|'R�Z�� ��H_��wWe��5���a$�V�ᵌ��ew�su��=Od�O�f5�U~{E��v)��\>r��8|�����t��r�B>�W:§T��P%[Z%[:�L��/b�U���r	��`a�K��}��o?�:-"��Q�n!�Ӹ��_��UuU.a�r��;��U���r_�6�kJ�v�v0��'��wȲ����Qke�����C��S�/ϙ���l��1��vH��s�����[�0Y���*�ɰ]��fWQ+�*���;O/��+��4���zѯʖ���V�C�l#�����Э�����\p��z�u�W� �1Y�k�"��N��H�Om�ˮ��U��x}�t��6�|8g�f��a���rVɮMi|9�۝���u*�aJF���l\<KM�D�.��|��c$���n�@Tf���[n`�����hͻ�&����""��m.�t���6��;���0LC9YxM�\���΅^F�H͢����M0�f̻��5H�ͯ UD�l���7ahv�=�l)~`A0�ږ��ޮMY6P��dT��o��u�VQ@��D�����(zw���(�W�;���L��RTN���<�����S�;��^H���h�T�#I.b���O�w��2��i�a�5�оp��9OG:5������(�)%Eo�f�g�u��8`�}v��)*o���XJ2(n�oOJ��i�f����,:�E3��*�ϓ��a�k�f+�����i���uو	2b���CJJ��5da7�G�1��7Ѯ��+"ɉ��$�N��# � �6���d�|S*�Le(D�3��н�%��RX��q'M�=zz���֞M'N��:x�B@u�G�H�^@�=G���Lcf�h���^f���~9�m�l��k��z��;��y;��M������(�M����s����ز�;Wt�/*���.<�����Xd��s�
-G$�TY�;���E\q0��WlUj�x����|���+���d�K�����v'e��F����X��|1�Y{0��dQ����V�T�Φ��%�spg�s���\������*N����j�{�����TDEEq�qw�*�v�@�E��g�.�y����:y2##����Ȉ<�
-��/�^AN�u*y�\���W��2�z|�=�T� �7���@w�	IiBR� ���!��/a���R�u\�o����U�د#���d�	�:R�\�Zj����
-P��2�bB��$��r�� ���U�I
-�%�"���)z�$Dp���)K(
-?�uO�hk�O���j������� ��ޠ�����Ѭ�"ÞR������]���9Q�hv
-t,W�s0V���'��A��ۀ��X�O��۱���{��#���l��x��f������1�?M۠M~���.G�n�u�|�*���A�W���q �q5s#�l�[�r<N�Ws[�_͍��ʶ��+ۜ�Ws{n��:���GCd�u�]ao��d�ޚ����x�������b��t�p��q�:b���.Btu�`�r?�/�_¯O[b߈J�'O�K����'p,��=�W�I�������ǲ�"L��-Ђ[���d�0���W���cO�W!#�_��Pݏ���?�^�f�U��jDtBW����@w.��`iU�;�f�s��� ��2����b��D�@M�Jw��̍*y�)!� �d�O�fB����'Vc��ձ7��`��Lb�U΀�}���E�ހn{-�^��5vh�=9vPf��Ee�;��V�}�L7,[��d`m�o����z����0�J��J߂�o��
-�* �V0U�z/+T뽨P���BU��שT��?�w��m��gk�UvnpH��2N����>�u�y��7a��C�qx�෭`߄���H����֒�)�x�oJl��k1@�;U��~�xA����0�~���H���?t�;h������8��_�ю>s���nJ���w��f*A��.y�q�Q��VƏ
-��-���??�r&R�vh�@��X0�{�4v���h4m��N��˲~�l�,Gʲ�A6�r�$��d�$G��~�l��VY�Y6����Ra�)�E�B\(�%� �� �0,-�EB�B�{%+���$U�0b4�/��
-�
-�_)�F�zF�:��J n#܉'C��p�ȕBɸR�\!��+����������T�r�^ᓢ�r'��
-�cZ�q1v��^h�V��Zm�@BX���_-���h	+$\㈸C�ܩ�1� �pJ$ x<Wxf6�~��+�q��D�uȸD�-�6��	�վ�������2a�q����\�#�������JpXAW	<�����y�бI�]%�oR��ρY���bWh5�>W@W޺6��A�3�.��.���P�K�	u9Aam/�˩�+sj�ŧ��c*^�P��А����{�3�y�Z�Y�u|��z��!V
-&����4��@����%�7�Br_%�!�P����'��W�_�H�q꯽�WeHC�>y���˙��s�`2�.�E!h��E���"��z�nv=�@k	�E�o���8��n�|*�������uH(� �+��'"�X/�Y��c�_�>78�x�ʸ͉��i�\]��L�ltŽFqw��By�t��@p�\pCw�n���{���q�=Op���6Hm���$���Jq�
-)Q!��^"��A����BPj}KD����ҋT�#n�|Ԣ�{8u�b�B�|L��w*&�f��S�C)w�&�z7	�[}�[}[��z��~c8����[��MB����P�pY ����'!X(4��=%p�'Ȁ�y���Z�^��]�W`1���5G@d���L����<�%�^j�`[�u�h7���B�'<��QT���`!)�>�h��j|���xz����������|0l��qr��0�r��ڀ�q��0/]3<T��N_9�j��ou��#�֘ǲ,{IP�	�	ś��7	���%�Z�T�`��p�����˖[�~� �:�[\õ�k���Qt�v���������L�@�E�mCv� �N�6���e���݊������q���>_GZ>_��w���!�_��%�\�o����H
-�5^rP��"��
-��T܌�����L��#�T�~�T������},u�p��\��#���Se��c�������!O�h�V@L5,}-��*��q	r��G\�����ݸ \S�rlW,��1׉�U������� �V�eՊ}��0�]�C�&`�B��G�:o�����=��-\EB�%��H�(<� 0�.���h��z�di����s�?Ze4P��V�cv��Q��I�̏��#Ƞ�F��WeaC�ǃ��J��)ن l�l߾�W����R�[|�q���b�H��å���'�6J%�h��s�y�v�S����2t�f���rx��P�Zר��]��>��'��cl���ކ���^,u�-�ݥ���2eQPo��_����[�T�-c�>����֋.���],�#K����z�_��׽^����p>���d.wgMlݠ��v������y+�S@;Av댾A��6��I�;�oT��+i|cס��᥽�Y���e���@5�:���ئ)�}4�u�3����~�����T�������=U=��yF�+&�%���5�Ck��c���"k�H�[����'�ɑ���l�#;e�1��)G>���e�9�]����r�}YD6�GJ�&.r����R��{�^��-����d��/�!����ݭ�_Ѹ~%c��SA�
-"�[jo�6��B�6!F[W���`Z����D`���G����Kk�zl͏2&�n�%a�`z�}�<�>$O�ex��j$�p��U����&�O�U�t4j���-M��n��G�H��ۄ���^�G��q�P��}H���)蔅�Y���߭���r8��0���2�>WCet�*�Xv�ȹ���
-��&�56	���H�eN
-G����l��zx�@
-
-X� �;�6���.�����f?�c�k�Q% �
-�+E��mR�3���Xe�qd��V�?�"�5�i��J��	�q^��b��,�`�	t�����l� q�R�w��V�A����zn�EW�x� n)�KE�1�+���B|鏯�G���v�=��F�ģX��a��e^QA�½"��KV�����e�@�=�>�=�VR�x]_�nB�u��۸Ꜹ��.b��a�a@4G�U>��l1�ž[Um V�.��� "���֖�,���5������a{=��Z��v�M"���X�S*M������<h#X[-�!;��j�a��j���먂��|�U���ap���o��o�F�>:Ƿ;i,�s�Nk�	��WF�d�x'G�X�������'���l|"G>���^�#d�w����n�ܷx��n1�!�{�r��}��'c�$Zhq��)�6>�#���3�������	��}�7�����Kjd�`k<b�>ǀ�Bq�x�:xX��{���C��^P�_��]L��P1�{IY�;<g�CexM���7�����7�y���jǛ¬7�R<���|�C��!�f�Q��ݶX�� ��HµA�x�G���fخŶ�L3���ߠ�����˥�W��8�-`9�ډ�ݝ<����U+ξfH �?1A�^X����lxGE�y\�{��q	U�w��G0�0�q��U�N7�>J���Ǿp}��	ܭk8ʎw`����=����xԲC@��c[B�GZY}*7��ڭ����L�����٥� ���"��k0�k�m)���{H2=�|G��%,ll��Xް�G�.����0���˿3=����g2�PO�"Vcl��nw�:a���?!B�G��3�e`ID���m�}��6)t7S������b���m*ń7y,��mP�"�器�<s[$}�V�I�/���(�'�LQ����!�/��BI.��P�-�4;�K�@�$4�4Е�X�./U�@�0�@�@�6k�x�u���R�m�&�e��=L�cQSYm;%�L��8PL�J;��[��a�"�%c�i � U�L1�m@:���c��x-���Z�6�	�u['�	f��~����U���J�"ڀtʎ8^��]��fM�5���H6���L�i~�;}��'���LO`Y�[���=���@��^χ*^q���QFy>V�+��������Fy>�}����U �CGq�Α:'���5�40�*sƁf�M2?^Y@"�bĀ�ͧ�$�W\�P~���yz���ψ�����v?Ei���|��s�}�����N�%�blr�_�}!�WcOƳ��]K��.+Պ��F՚�����̋�YSj���B��%�JKg�̫Լ7�EBpG�O�y��/�>�8�g�I�5� [h���R$n�>g۠�i�9��AE�y 9�j��
-�_��F	�NQN?��D
-h2~�X4�;���"]�ˢ�
-"݇��]�O���B�a�4}���b絑ߘ�٥��u���	�b�[N=2i9̩�@V6ej�2}�0!4?�o]��o����mbM@�%�G(|���G���(��	v9<�n,�/���x�c�P*���fK���o��+ ���2ƓQ9◉���z��%���Ci ��@ ��Y!?7�y�=�����@ɾڦ㨄<��z�<*�3�@����/?
-	��G:[�i�������R��|��|�3v\�ي�؍t?�'�:����^j�	T�+�^WJ0F���j�o*y�XT�
-�٢x���)C�jl�:�r�4qZ�V�x�m�y�w��$(��v�r�E|�نF���P«���b8���l3�U����}���Qcߩ����k$\r_��%]
-��
-���c	li��G�!p���a�O�^MKQ���2w|F
-�Y�����L2W-��X&��W0U���*��У�����ȳ>j�p�������S^YM;j=.�G�1-Tpi�`/��Q����i� �����������Gy�������������������`�8Z�^'�D�E����g�@wD�h4�z�f�`1�zͲ������ v�Ry\�a4��} �� �RQ���!����	D鏻�#:�$[�$�wiٽ1��	ha!r�
-G�;b��)���fJ����f��V�e�}���>�=�RË���:�Z�<���Z�'
-�?��5"�,��,M
-LU $�-*����*��|��q!�-&����l�ul�[��Nl7`#^)@1	�:X����(�B���Bx+��y��.ܠ$$�1����,��9�jb���j��^�|K��)���	r� ���&�&��?�Ce0^k��x�	�4����û�pm�@`c�`x���*:1�_��J���׼�ռ�+�d*��rAޥ�^�ٷ���PD딉՛�Zu��%�w�G�K��Y�2� �3}��id��>�L�����G�O�G�)�ֶ�R�	�/q�6�T��<>2�����<�]��
-�"����������sEx�,���5�_�>F��_|B���*�^`[QV�Ռ]�1�^��l��٧��C�L�F��xr�b,Ie��~�\�m��s*4G�����'�4��!�B���D�8j&$N�bf��q���AR�&��� ��Ú�M����J6�Z6��A}�.��I�(����&��ˎ35���;�X�:�Ҙ:�-�B�2'�$��[��j��ݤ�:�iP/��B1r���v��3.F��,��H�_[���7�i;s6��?�Pg\Md�C�,�f��>�L�g��VS��jZ�H��q0-�<j��n��H�Eè�h�4�[E�o �_*�ϓ|O�M�&��Ѭ������4�3��t�5$��MӰs�US������{�j}�#)A�B����<��"�1\�~���eG���ȵbɸV�\%����� TW��尙3���� =+Ŏ����H��'�$�չFl�F�����V�Gnˬ��$�R�}�7�R�]�KÝ��"�g��bb�J1�J��c����4��~	�{(,�aφ#qA=��2ol`��������AZ2G|%��RzE�	��3%� p��,q3�ص"��V,�_+z�v-�x�Ů� W�U�c8�J���]iWP�9���<���[�-(��+�å��R�_��/�����l|!Gv��s�����Ib@��>��������l������|)�%\�~i7�Ğ�b7��5b�F1�Z��K�$����:��ϟ�����<JU��/�E�;:���t�̰g�5��}�e`�ּ��e/
-�Y~�Ώۙ�C�^��a�/�j�cA�p���7SG���&BY�u֗������3ȵb>����7�vN���5�5Z /���R��p!o��3�e�$/�|55��g�1�UP��T�Ϭ������~sl��7Ƕ�7}s���j�c%�淾9&ОO�}ܰo�0�o��?Dy<Kx��Q��I���{��
-��؉p)�v�D����r�y?{a�����?�����4�e�o���Ke�E9.a�\���m��)7�#�N�K�~�E˗pZ��b܄�v�T��^�G�dF�m~<�����S�K	Q�ϟ
-�v��U#���5�ښ���<��&�hz-��x�����8c3����p'fXae��g��q�#õV��0�uV��xx92\oe�3��2��3�Ӹۑa��pfXee��g��q�#�j+�F2��2l��iltdXcex�'���4td���� QZ��i<�ȰVG���$�����������l��l��l��l���,�g����=�s<䌭��|���K�s<nb�E���z1��R���{X�=�h)��Eo3���r���+�ai ���	��[���� ��A��i��=ߠ���At{T�D�\Œ�<FHh,�.*%�U�˵D���WůЊ���D��J�W�$�M�&���9l��*'��y�YN=���i�r��s�x��~K$�D=+�>�`�k����[��6���&W���L��-��-��DӪDc��Z{�܅��[��6����i��Հ��٪ǈU���g��V�Aa�X?l��P{��	M�*h��5&���=Ί�����a��Ʋ�c�̮���K��!�'DjZ-�*�h̰<R�E ,���4P��X�[V%FK�Z�� S�h �	�b���1��`� ���Õ0��0�Lv�n��g.^�f�2�����������^�pq>�Xbx��k���wl�=ظ�g��߿
-�|�_��:�֠
-�;��:1v�8�j�������5}/�X�/e��'�����;++4�,��V�Ð3�ju-� p�]��c���Ӯ�7-r�5���}�s���3����.ɳ$�`�J���#��W�m������P���|�W!���5B�������-��z*L	{���"�+}"�>�����ű�� �و�M�D`���w������A�[������ƚ97T�6D�P�&D�B �M"�t%�M�(]�*|�)��	m�����5����^����.V�Z��*.�Lk1�b�:�>FY/��}��̍"��PM�$�ո�� �&�+v:N�Ui�P�k���ng�%�	�"��E������H�v�|E�~O��8a��P��Z�'��mL|N�K�N��	���HG?X�F���p��x�� ��� �. v��$|�����^��5ֱk��(��Q}�v��mnQ�v�Wo�:��x{u�d�Z�(��o�c��0���$ӎ�$�VVB�	ƯѪZ�ϫ^���W�'V�W�#V�W�+:Ϋ�Ix܄w��+�ޕ���w���w���j��o!q�Z��#󐄻���?ɐɋ�@�8��U�u��Ct�&� �s}��{Y�^����au��<��͓��ˑe�#���>��O��3���v��3��x~	������}��߷�������o/�� ?��O����q�F��#{d�]x��6N����;���԰>{���9򝬟���e������y�s����j[����k�/�&����M<@��6��Bm��E���^�bm�a�%�İ~�6�p�2m�8�rm�x�
-]���������G��h�ԗk1od�;�x�.�6�{���^:<�+�;Z���o��X��1>#_��1���@Ʒbd7F�#{�Wd��MK���$��#�?�Y��!ޱ v�n�xׂ؋�Y{b/Bl��^f��,Y
-�(~>k������F;Cߨ�^��#ߋ��E�Z-�F���z��3�Gd;$4߫80�X�ޗ�X���c��YAӈ"<�3��N� �t`W��PT�K5�_��W��v�1�?�] �i�+��h�ϱ�?�t�����o>�P��z���b�g����2�#��!k&��R���<5vMɍ�C	���=��5���W���cp�]��ӗ�Ƶߤy����o�|�הK��G�e���$ƾ��h�L���8@0�ٟX���V�V�e3�g��6���p�������������'�M~'Q�^b��-u��h�v%K��}�����U��:Ӻ��:��X��@�^+����h@�޾A���ح2o�r:Sj�-�DX̾5#�3�"Vj��#��?���{���e&qc$nfǘ2�Ht�)����i�SH̅��Ⱦ�h��ts��>��c#�=+�@�K%�T�о��i� Хf�F$r/��7ԣ
-^����[	}1pE]&K��$��܃k�𫎝�}@ݺH}�8�B4���h��:-�^s��w4H�k�P�[Q2�h�
-�6h��Zw�k@��Mc�'�[���g=�rv}�V���{ 7A�n����F�ήo����-v�ۤ�� y	R���Ef���8���Gp�yR-�'�oSʬ��Y!S���v��Hg��E~v-���v�F������?rv-������z�Fg׷ktv}��Gy�kt\}��շi�m�s�F��4<�ި���D�QdW�r��K�v�k~��(��oJ��!���}��uH9�W��k?�~L��b,4��-�H�=<����3[�Ď{��=�--��b�}��c;�>X"㹲)ޯ���f�@�lZ�]h�> ����A�E���j+�AH�W���^�m�I�_����H��?(�Jd���)�p�_.��(5Vj�I��B���4�l�*t��YSp�V6U��T�'�J}
-��˦��Ϊ�S�������&D��� �-�ێ?)�R<�և5dE����o'$c��'e�*�? ���Y7H��Z�E�����m��N���$��z��@6�~QT���y�F�̣�h6)�㬢IرN�I�>W]>n�Pd�c����a�,����t�3w�s��M?���CN 	��l����03nb6� ��0����CJ
-�I@��,&����]�ƻֻA�U�5��NH�aB�yf\��	�O^ϓZ�%׀(��R1�F���j-�j��&��OiOJ�YOJ�|���{d<\�� �JE�Q�{��Àx�d~o~��>y�Q��3gأ�}2�50�_�NZX��Sq����G���Ct�kW"��F�`e�v�C�i�������*�����hj.��u��ԣr�(������N����H�M�Xc�T���kg���$@&}�ƷĤT�Q��y��%��u0�E�RE�At=�n��?�J����R���yF��gA|�G����(��"$~��A�m���O)�;%�x��[�0t����v��EN��֋��%M\��n�P�g�ߤ���9P�и�s��z��Z����kd�Mu��y�m�A6�}��8փ\:Ď�JPd�T��!�cl�ȉ��G.H5���5`��$~���&�t�2k2Y/A��Bs�>�#}l��f)� <�"��'��2Z?M�Ci�U�+ѣ ��=ˤ�bwm̬V�K�K�-��b�k/�&�����J��0CV����U;Ƥ;��g;��g�n^��B��b�G
-�^�G]��Ma�@Y�_�<�����h%��$��'���������q
-���zߤ��I�䓀@o��o��?dl`y����{JF߀��.�	����X�F��i�@�q���7�]l�!g#5�s�Y3b�\�Ԅ@�nU7h���t��C�1<$��hS�8;y��{H��dt��~��3����;���(��*Y�6��#΁VUs�e�����{'���qz�,>��!���4�O�����jL��/�Rq�o�o�V"`2V��v�x���}uRʝ��ާ�f|/�b��y	��ɞge���������Z�9�8iy}Yn�R��yB�;�T��ue&���^	�r�_ R=p0z�����fE5�z���dd��6w16�}�xr�u����*;�"�f�I���:䐢��՘�d|F*Ҩ��*���^uG,��诌8��*^k�W�2�?��z���q��Lh�󌔹��9c�D�Ag̥3䌹s��yc^u�܈��k�i%-n�]���d��{��ɰ?zFj�ٳ��o�K�ȳ0>�J���.2G��Ѻ� `���R�ۀ֌`���E���Tpf�D_��A�Vvi�0
-B3l���
-��~�$/t:}Vj�5��j>j�*Gb������a�9�(�J#n�.u���_�2_��7�g��78h(Ա�o�Nn1VK[��v�� u�q�@\kG�g������8 ��F�C�v]�6lSY� o3�*�3�a�8S���菈�Y���wev|����к�9,�=(C���㞓�)�9ifle �{4�.�S�<|K�!Κ����������]�d���ھo�����zl�V�jW�w��46��^�x$�G�+��qPC��`����;4%"۔yq���&~e�U�7@.p*��U��ɔ�r���Pڋ�_�H�`���\��;˺43��#���k��=G���([�jU%�|��㱴��i�?�d��}���#6Ըu��"�؉� 	��^�R3:C)G�T�fTm��5x��RI�m�e����&����� ���Zʣ"pkI�j�e���yT��c��Rl���'�
-C�)Q��Mh~�}�37�+� GϘ�W�>H؁'׾
-;f9xVv���=��l������	��l�=�����Dϐ��~��y$���#�<�j��yO�|�W@D=�5�����<A��F����	��#�Ա��02����5eTƚ���Hƫ*�L�ѱ�4�M�R���׫h����2���\J�WPKhk� �
-(!�eC�2;��O��if�'�%�S��(R���=�yJ�%�5.P"Q�>�/J�|%\c��D.R�~�"%�g%,V"+aѸ�g�_����gF���g��T��:���`�<%?T�|Ё5M�	?s�{���3	1�ֺS� �2�hB{Y��mB'�q���#(�!�	}�K��%�^m �2	|����5v�_W�0�pd�QPY�(v���.�m��h�:�ʔ2CxG>���P��I�� փ��2��<�u�!�RB�o�b�#�^�" t�$�����R	zP�]��/"�E=��s�ߧmd7"B�~�.H�xd�A,z���#^oR�l��g%��%\�l����N4�]�/V�K�E	G�8�g�(�~�Y� ]#KH��5��2@�ʨ�`e�{�Ԭ�������A"�\�sH؇D���<ƐيϭR�����)�{���v�x�%�*n��yw�S��|�6x-�~�y���B���P�����׎�k`a�������>�~���bCR���Nl+{يu����H��-���{Yj�B�[X�:vH�h26:� ��Ň���-6�	�Ej�
- qA�D=���}J�E"&f�U3�hE�q������1wB4̃V� ��rl���,�Vs�u
-%��1x���I�k���/0m$�
-s�Ǣ��,E*��S�I�s�K�ǿS�p.\E���9ٴ�|�ei�Y�o[$��-��?%r
-Dk���ǡ�1B˓��}��7�(%)P+E������˶���{�k�ؠ[���^�V�ID�f���2�3�ɸRiT�@�N�=@4�#� �S�&�e Zd�D��P��q<ކè������g"� ~�QE"qgQ���|	� w��ͳ�����G4�QML�7k�����?��Oi�Ӛ�WMFӟ���4�yMA�_���4}��o�����4���/k�6M��!ME�_���4�uMC;��2%r%ȵZ�%�}PV�J���� %�E(3,A�a�+Pr8 e�U(=�凃P�p���Z���z�I��n�ڄ��>�f�Qx�)<j�
-�����@��@��B��-P��AP���P���yc�+����&ԩ~�y���ʽ��|�{�w!_���6ϧo����>wb�
-~�A`Ir��?��O0����S
-~���(�?����0��~��/)�%�F��ap7tK������տ���-�P�;~O��1���?`�G
-������?ap���`��A���K1x&���`xL/�B�l�=���5��� `�2�����1�
-���lb�"
-^��K(x	/�����^��+(�J^k�����b�!��a���_A�+�Z����á^}%(v ���a�W_��(vo$7a�f
-���-p+�Qp������^���(o��=Ń���<xG0\ǃw�5�d�"�wa�n���� ��c{��0x0,��`���EQp;��v��)�{���ap37c�q
->��'��{�>m�jϲ�|�>k�Z�y;�_��͸\�\��/A�i�`���lbз��1I�f�^�8�O3X/c�+5��+MT��� p��4M�m�����ȇ����>��H&4e�!��?������� �c�3Q�*��ÉMDK��+�f8�m�� ���M�I4��E�
-�Cʠٮ��q���{�� �B�*4u��T�A��w�G~��HOD�4�@��7?�2�#}� �F�^`���}J-�f��"Ec�wa!_ѿ�����*���u7�\��<�f�~)���WB��?��2�W4?hf�ѿŁ߃	OR�����=� �!ޣ��Wd���U;iT�	��Oǟ���H?3?g��2�9�	�ځD���������s����?���;�k\�D�V`Հ��h{.�����y�^L=S���0��@#���~I��w�o�߸�^_�5B��ƮV���4t�7���%� q�]�t��V�RZ?��T��a<v)�0Xr��\��R�xHu�Y`�J�������/8%�c�5�j�E.c������F�;T8ՠ��.�E��b</u|���'v|�_Nk1^A��{ː�Gٴ���6v���P��S5�z�5��k���}��Kh(�O�����C����!t���`%�><�Nh�3V�cq+�ce;VN(f�b��>����}�`B9���b"�P�*�R�C��\���ݚcC� ���Q	�#�9��m��;� XJl%B��2E$D�_4�� �^����<sh�\��2e�xVɮ���Ly��e���;@��+����c{���"�����_�a��b��C�TA�fŸ�����A��y���E]����5.�7��UF�i�%���n��eX�8��Zs\w����O���_ǂ�VL"<O1�� �7v�{��D8ϩ�]�Ll6V*�|(�k��MƵJd�2q��Z�ܤ�g+�MJd����k��Jl��A��P��W(���q3��<=�#�}̟�1��uJ1~B������q�)v^��?�m,�G&	�
-^�[��mB�-�	��nRZw�}�-{��UJb�W)����˵�j�5��Td--B�(�Z�Q�����][؆�:����kC��o5^�S�� ���v]��?�)0�h�Kʥ��=��~���Ѽ�!z���I?���w!r�R���@ݍxP�z��%�? �����R7�_fQ�����G��9�*�i�
-� �m�oV�'m8�T�D6r���_�������U
-�aM{�Q���D�6��U���6�Fٿ��r�͸��ps�w%rh���v�c��d�'ԻX�k�b���*c�k���sw��V'��;)�b��yW::i��I��NZ�4@'M�N�"�_ү
-�W��kB���5}EH�6�_ү�+C�@H_�W��B0%�5�y
-���U:5
--؎�8
-��=Ѿ�Ξx*����^Й�v-�vŻ�ҹ|tΒ|!�5��z�x������>@���>����oÆ�7�?��Df0����;5��"��y��{��?�~񪫽gL��S���3~Ŋz{�����􌧿;���ξ��9��=S��}���{�6WGr�p�m������3�?�+!O�Y������<=�������}���5����?�ڄX�!��W����s��8��v���5F��Ƌ7���o^*�0�f���{���w^��ǧ�v�_7AY�k����p��/�-z2���.8G���A7y<�0Ե������Qɾ\�'wԴ�����<���ƃ���Ż��y�<Gy��bk=���!��֭���UM���9�1�ƿ�@	��>w�t��K��t�����Ňv�+6��lY)=��[�5���� `o>8$~���5�l���M��o>(}��m��V�����C;�{/Y=c߃�����/\SsK�>�����e�_/Z)����[��yFҀz��{~1�=���5�5��y�oO��w�Ma飦|il?��=;~�K��}r��}>���9�w&/�����?����o���?1�?�n;���8������4�<����^q��/��f:�y�T6��_"�����d�#M���Lǻ�{�� Z���RNM'q$����=�G���沅�� �ҩl<4���;57��gzr]5�n�*�`^p|���6~�t�{�FOA���ŗ�� (�+�${r醶���bW��	���i��̋'�u%�9�͹lk�I����BJ����/d{��ۦZa�LcUJ/Lw��	�h��6������3��d.�[��)��A5��̦ǩ�|_g�rɭ}�I�kn;��J�S�=݅S���Bn�W�CJ<۝΅����jPH.����%����Sy����\l�u��T_g�5��:.�J�K:����s���Ќt�3���*��7/��JBr=�P�����Nw��Z`�;�вZ����f�ώ�sq}��A�مis`2xPw�� ��0�>J�KmN�׆�[�F��=Vk�ĺS���)��Tǰ�rm�PFw2�`��࿦�$z���X�f�,LSH�n��kα�-�G;��(���N�O�9�6-��M7����`h��J`vO_��樶��e�v�֩�(\�A�֎�<�"N�+�d�������k���s� �	R�挛ٓ�*!����XGك�����zzӹ��}: s�t�P�68��l/���d3��mjH*�j��FB�!���{��;�	���/�CT�$��v��7�i�Xp����|v/h��D,��;��@$�s����� jyԩ=����������/?��OX�����3Zjjcмݬ;G���U;��^e2��b��um��C��4�9���4�n�5�i���3�V*�� ����B��Z�	�\O�^�am���Q�3��='#�#���	-惯M���Hڈ907ەf��Nh���E�t7�Ș׿����m���\� ���OBL"��d 9t�x�ՙ�q���t��(�wC����'�������[szqog6�-�Lg+/6�S~Xz��l*-�#�43��v�!�*Ў�/v�g#���ξT���S��9r�r��/bX| ۝-d���#� �	�_ vʒ�xg�砡t7�]jXQ��.�b_70�T���l��0�^d�1ާf�FxT�B��Y�k\3�53S��\�?p
-t��Sz� ���S���:�t'9�,�
-"�� �CS��	�4�ت�` ����qh���xX]*�K�*ϡ�*�	����Y�U1�����]n��rSa3u�)��d����B�X,��w����teB:�.GM�Y�ddSs�x(�(�;�w��B�z���d�R=}	Z5�g��(K6�� ��xw�M�@<���S�.\�L��I(�3g��Ļ�Z�!��"ۀ%,n�7&H��!� q0�w���.�R���2���}������S�L�5Ƙ5g�G'\�G�8��kU��˓F��0�0���	�:�*+���`.�2��^� H�����)�<��Tg��Ҫ�l���x�N<	2c>x�ubsŚ�֮CB���~fh%�KM_65�ͽ���S�f����.�{�0�{�Eڎn�q
-�l�΃�7�s[�5P�sIc	҉ͻ���=#ݙ^ 4�Qs�>��qA��u��aŏȥQ>��8l�����s�H��pm��+S�5Y�Ԝ��������)&�GlI��߃%� 7�L�b��?�u�%,�wC�P� *D��8c��l�6G�X�X�^rC!����)�̟AHYB/D֓�7��f�O"a*���4@u���M֜�I�#V컐u��kp��G;��+�ىG#ڰ`x�A�'Er�	��nwt�Q�|��㏛4J�(?L�| �$lw�h�ǁDu����d�zA���t)C�_��2;�FQ&��Н�W����I�Nu��S��ZMVs�Q(�N:��E�O�$�P|���s̯��@�Gw->:����xg�ȼn�R���f���|��#s ��	\Vh��N��}@�l9k�l�'�Vі`e����a}�$��8�-�|b.��F��d-��cv઀"(��k�@��r����s�V�h���,qD�欹aH;Z'7�A8���\F�=9�ɗc�ٟ<j��֎s=}�y��������P@H�s�l:�XX�M���3��tz���=���в��:6�K�(�A	��<p�f#�w �bA��oBn�ػػDZ�zF�f�����Ds|ןE�N=���4��R?L���>a{n���"�F��m�T�S��� )�l�f^/o�v,��h�3�.�csp����˞�b/1.6l��X15Y苓,8��V�(��ưY��Ź98P|Cܒ���Lۛ��\O~^��7F��D�M�vd]�&NE%����M��犾�b_xɈh��{_��������R������K�dZ��id|�%�]���h�/֒0D��H7N�fρ�S-9�
-+�t"���k+o7�K]N�V�E� UeQ;փ�t�F��k���M)9ŧ�6%&~{��U��ь�������-t�Ј�aʦ��dn*�p#ܜK��>`�锓��Z���a"91��NZaD��NM�$b�Z�ާ�@u�i9�*kk�/�u������T���:{�ι=\:W�C���[����v���0��[ڢC�8��L-0E�Ȅ/Ro� l/�	Nѯ�g.-�]ND*�Ϲ^5�%�t�V��(c��yz}4_�m��Np�jC��N�Q����7��R�P#"u��\67s��8�Nٽ�5)Үqc�l�VkZ-�)s�6��onω4��xM�r�!��q9��|��:;ג.Tǌ���*s?�P>���S5lo��A��`_5�lJ�Ұ�������9���\B],Es�c�o�Tе��U�K|��x]�M�[57�
-�l��N>�g��S@�,(��Wo��-E]�%��/��͸��J�1�3�u`5W��̙Q[��FX϶=(	`a�����G:�(\�L!���[4�D<yF�!:l����P/�:qn5��nܹ-a�'��6kg��E����ӑO��i�)4���M���V�:&��k�����Ѽm�KNak� )�8p0^( *�a���3j�ڋ�H)��S�������Ξ��+��^\��0��`F�5�fփ�떪q�Q+��ע��N�c9�4��[Rp j��'͹D5�%�Y�As��|>ʞ��BE�n����]S�QuK�ZWs�f�i��H�(G�� �L9��0��Kh��_8��O��sg���Z25�K |��5�a8�[9�mT�|���&���U���h^Vkw�ݯb�Q��B[
-�o��+�]��t�&i�f4�ﴐ��OB:�Y�ǟӁ��K�H�]�9���ͻCl'a�gv`Ǘ�&����g.�~����^}��Z6�z�<#'9ʷ��J��Z7C}��Y-�Κ�꣕�h�%wq��銥Q$;������u|G&�%���a�Z6g�?ڗM�a��Q&�	��Ř�~���)���t[SY#	�T6SBa�Np�MkS�6/ۙ-,�&�ilUc/�Ń��Rm�\2ʜG�*f=�䁴:�vvN7�h�!:l���n��A��K��\��dl��)��:JG�(
-��T>�d�E��ln��������P�ҟ�SAג} 0B���	6����z�>�lC�!�a�m���~<D�oCp����z�R�7��_dNE+���i���^dSg�ö}jw�'�|[��t�wl�F��LW���^�%ď�9|=+"e�@Juh�yǎ�������!��	��8�s^���s�]#��7��&-5V���s��� Y?_���$w�J�ڨ��&��dG\ͩ��3*��s �ϧkY7�*��o	��
-�f��s��\�{��x�6�"yHg�s�Ti�{��b� T6ؽ]��� h�����FYT�D�+!�D<2Z�tmD��?�9r#���5D�u�H�4{-7�VL;�b+Hs�u�aF�?��	���T>�=���r1s��rȒں��ȗ�l|�t�f.�Q�QSz��H�ͱ�e���$�"#�T�X�c�{��æ����%f0fo/�;�j�6c�t�v�Q(隈�^��S�:g���;�9��U��.�AؚhU�G�r��9S̓�z�����Qu��3�c)u�:AQ�
-Sa������;��s��xpŔͻ�l^�:�q#���u��V?���VO-���a��E��]�$["v�j�����%EM����eh�V�R��Q��2M���p���4_�}���V"�1�y
-�Fb��nSm�����gN�5C�Y�L�׷����l.:�׳��P�0��;1��[��$����$���W�u ���;�v.�M���u�k+�5JƐ��kS�q��$�G[:t����@nYD�L���I�ܼ�y\�먟�4�>i�mW>dǜڳ(_k�u1�#M9�"�!:_��m+���,R6Id�#�v92� :i%z�	.��^�DS?(ƒ'(km�ݒz����l�C�a+:�8ݘ�ܼSORxA��kn�Љz
-�MǑѸ�ձh]uVQ=����[���k�t�o�\X����SM2:)ە-ԦzNyݲ�ݴc���b�6\��P�Ղ��ϘάԀ�hP�ta&0H�`�2ؓUB�i�p7'�	�ț�Ћ�.�P5 i��qE��dw�Y�����;�꬐���xv�Η��n�U+�1H�g����/[��,5��)P�n�oY��JӮ����������o��倔(;5F��c���o�����C*q��Q��f�Q��C�|��Ǡ��h��u����7�����c�1�8�X�uh��02ɋ"X���ev�9.�1�U���Z��7E�dn<a�D���.j��~�QnCo�0M�=3@~M�,��X|��iU�5Ga�}FeE�(;�aڌ�"؝�,b�Q�'�;���U�)��im����T:~.����1�D���h�'_b�6���86M�{HӁ�)=�}�P���!��q{q"�����Q��`F��@MZ��nq��6ڋZ�#�>&�_�B
-��e3G���_}iJ2;0�>c��Ic�sq<�]�H����ᠦ����Lg
-���:u	9:�Hv�Lq���f.2�aIoZ.�0��@�vд�cZ��ظ��P�g��^�`�aaRU�)G����\�`��U��کL���Z!z�ޓJK�<)X4��Ͱ7�-���Jވ�z�B] �њ-���I��.AY9��NS;��<F+�7�f듸���d��ЗKφ"H�Hv<y�y�n�,Ț�G�DN�&q�OZf{]��0����O�N��"�+��������g2� �`�K/�w3jF�����_%�?�
-�G1�+���T����Z��E�b�����z㰸J�t���x;u�Idئ����0Љ�3�j��Z{��r2�"E����
-���A����dE�9΅��1v�*���4��4��6�e���`u����M\��^Ogcál��}ݧr���=�� 	ֺP������<9`A��<AH�8zqWq>��6cIw�+��.a��+�����U���1�'�IB�rF�y�
-���l���	*w�a/l��2:A�� ��1�Z�Qu���Z�|_���VƜbI�j[��������
-ov�IPU4�mrX�Z+�J��IZU�x.]�mO 6Ql}�)Ö	�yy��Ld�Nm��P'��C\�áO��z�[�2��Y��a#��'HX�I�:����Ш2N�Ս��Lpe'�j�V^7�;ŗ�� !1t�"�/L��)���m*ݍ��l!]�����O���"@+�>��8x>ibl�q*�pKMU�y3y;ӓX
-�J��#�@������[y�[2���-3�aNZ����{p((��)�e��E|�3�=�=d�1#9���l���}�w��Ɏk-�^d*^��;���O�z��\��H���X�|�`���Y_k�OJw/�"���@ME7�gk�N���l�\_wE�X+C<�K&�6g����ɏ��i�I!�xm�k��׺A[첫8}!ۦ�����9���S�Ȏ�j-�A��%<�N�w+h �Aڶ΀u��[1h�JQ~���}J�d��#%� �{$���l���F8�ٕ�����*�EV�s�` �6�)�mN�L��Z�\�T5cG�HwG��	���CR�n���p_`��d���m��9��+!��NVy�+������t)ÄJ�<|����N�p�48V�J��b�Ц�|�=��D�rQU,�Q�V�N4�js��d�u����BW7$0d���ʬ�<´�'t:|�&U:̆������u�#������F;.�	�l��3Z���|��SSy[/Ɠ���.z��,��?s1��N�w�HC�;p�n�i��׭v��V���`��R��:]X�a�	�<C�=�T�k,��ݦK�i�}]	u��~�g�6�3̒��E�ߍ�,�!:��5a�W� c�*�MP�@Բj��pa�_��S:��#����I$}�=K>�0�C�,+���Xr����$�#��R�k��~n�:É�6ꮡl�+����:��В�td��`�e�5�kzI-�fv��l{-"t����R:nY�4��9�R�pݜ��Ƽy�do�FVv�m��B	9r��j6�"%�~���,n�f���1��,Sx%j�����"�4�~4Nܜ�$�����dvvt��v�H�s���������c�{N'���E� A�ylbI��H�����Z{oh���{��Xc*���#b��F<_qv�+bUSl��*���Jw�r/'�&'35����L;��+����CmZ�b+�W�$gR����I�V?\l�=�ILc`o���t�9Ǒ?{ �D-@_tI�u��n~"H)�+w&���0萅�&�/�����o�1e�2�<���,�@6oZ5�$E�y�7��
-����8�˝�M[2�6_�;N�����; �za/�v\� $��k�=�sz�e0*��0$�L7Td:aqo3���GkS�S�H�;M"C��I�����3�P;�}�F��:��x���2ؒ�K[��|�6Gu�*Z�8�C�G`F�h9�[�E9��.����UGmd�f���K#&��*m�F8�25eʎw�>��:~R�-d�Tײ�庅%j�͗��4�j���ISm��&Cl�le[he��qU�4�F��B�`$�Z�R$�>�a{�-I�&a=.�Ou��d��!B3 ���eR��Xy!G������@��0	�!3K>�Z����>����f�<f���=�?r�=<�Sĭ�t%�L�&��d����x�j�N��!��x�x����kG�)�mDҢ�`R�3�(g]�	a�f%�gG���9>�Q�x@~�\�]�e#mW����Vv�8�]�C��T<�[6#������6����^��_��Xa��:�k�6f̠��p�wUS��naڒ�ނ1"��N�pڅ�k*w׹�4˟�3�H�ټ)���	q[�▜�g�����"=V��f��Մk����4��O�Ν:-�v����)���g�M��.���F��)���F�iV��	:�en�V�HgaQ���}���bv��m����P�������.oq�Q���(�e��ܭLr9�� ��~璀=�u��Q�V��;���|!�A�H5x������<�N�Wʏ]��2����8dMzUR������J-�N13
-hR�u`5*3��d�]��R��%W�HK�Ћ����*2Uk�$�Ssx���
-ܗL���F��w5ji>��>������Øw��M4y��9��\.J�kvL���b@���R�z�sS���0F����[�M-��nv�E�M�ȟ��eUU���3��E)��ht"K4m;F���dF���e�j�]��S�s�D�"+.h��X��5�Ex�F�EnYkF���K��]wYaL�s�,�S6��UZ�`�Zx��Eٽg�iK�Rf�fpv��l[j���l��(��k?o���2�/W� p~ϖ�Mb�i��;�K@���\9J�F,�Uof���l:Bܚ���r�i竃|����JV�n�KQ6D!��ר�#D�&jK����!J�T��Sd���6�Hc�W��f�X�`�1�@�#��,��������66i?�r'�����k`Sa$�Re�{�vM�L'5����DV�փkp�ܵϭ>4]��X�n���4�?�g`G�.L��tuM��4�%{-{��6�7���H�p�0+�dk-$V#l�7��9g��9�`r�`2��19s�S�=A�}���_�'xN�:����r�*ϧ�>�J��\~��\R�5E��c�l��6�,��f2��}4����Z��bb)TAT,���RԇnF��(��ǅf����5��/̇w�
-"�4Ε��� ~�-�q�F�ؗP�v*��rȽ��9�7ڼu$��E����L�;^do�J��=���h�$�j):��8�)��d����3r%���bcpYIA��M'͂�?��O(>�/3�ia!���-�Jd�O�ҧ�im7NO���^ers�ԯwIk�rq<����<��P�I�iI4s1#�	���"l$�E/6cNVb��g!��7c�V���n~K���9L�xv�u]�`o�y2�������B2�8�U�e
-Œ��0u�&)��k��j�MsҢr_��
-��N�0mw���q�t+��A跣A|�Rn�
-S��7�����: �:�*���J���#Gc�̭���2�k�T9-D�c�@�FCb�Q���48�r��n��B7�^.K9���P��&�_��#=��&�h��X��BG���BS���Ǩ3EqG��"'彈�F0h~��L������Jo�����.���I�Z�������#��$\hn�j�U���4��b�j�J��D!�Hq�e��.3XT�B�IY׌�����4V��Zya�!�e���B�ј*+�'��.�G�ى�V\��唇�!<'�2��9��2w<�]M��"G(Z �2�s �[��F$�G���L��;M���1���Qr��uS�����P
-,Z=a��We����>��x�LZt�@�vWDm�G�%e���E�T�k�J������m���Տ�����]Ð)���ڵ�u	�(�TZը��a����XiA#�vA$��T��miѥ6U�F�ӚJ��rG���-� %>3��ܡ�skB�"� 㤘�ȈH����6���l����h���Ң��ҏ&�xZZ�����[������^��K�$��H���n<��ƓN��h��I+U.z������qsH�r���ߐ�yV��N�e�Yv5��C!��+�2	O�?-���Fy�>�z�7�z���~���k�J+�����QY�
-�[����t���5�S�ia��6.�g�bfa�������֏�؆oURg:<YuKet�pj-sv��$�a���,w������[؊fu[��j�x�OU����-���eM���0N��YR�r�l�s��袸udc��*.���L��4\4ÉU7	�m�mL\F������~L5y�fa�����O�2����r;��6-� K���&Ob~Ĵ���2�>ȅ=��A�3ԙ�^dX����R�Ѱ�t�@��6�3����FJ��d��ُo�#g{(���U�ٌ��t����@U�����L��D��$"��0���hv�B��0,M�w7�ȯ9�(��z�X��619�	�g�|m"�HYV+q�DEaI[&�l�"�mv���s��^�'�
-�����4M*mWq���eϮHFhtџl�_���ž3W�On쒭��\�Ϛ�?�2;��Ƥ9�ѽtH:N]c(Zt+bS������v�)q�,��Ln͍�>����$��J>xV���3!�73"�d�h���*��/T�xE(���8�!gPK)8���$ݘ��	���1�!��'�,,I���� ȻR�Q]���3�*�I2O��
-�J�b��цјdQ�'ҍ޹�%V�4/���iL���
-�"�_d�dW���Hq�?���c�!3�b��<���+��
-��C^ k��w#�UD�	0?F^H3�ѼX?(+k�	Lv���'�1YE0��������Q/��>��;a®HP��*��6:q�/��>q�!G�)���⊏��e�c�c7rV�-u��.��БI[Kc���9��?�����O�x�G�?ehޢU�����B'*���H���*r^�+"�,�o�'��9��U*`�PlN�^d#cv#׊�RD�Ϳ�M�z�.���m,�I}���R��4N���D�ԏ�-&W/U���3��А�<�c��ҜrM�.nRiW\R���@3����p���}�Ņu��2�3�D�j�����q'�S�4�=Ud}X�E�q&H�mXV�שe��	o�҉$��E&�+=�{����3f$Uv����)+��`��ҏ��7p:dON.-����M.�"q��\i�B(I�ѝu�^�B7��N��{�l�d$a=d0��;�#��)+c�B��;,\ޒL/my��F��8?��R���WȮ�����0��ߙ�Ɨ�A�JV��)tca/�(�_C(O��S��+ڄ�O��5*��r,��a,�j2*����+�Len���:y���6őu�w�dh�K$����J`0jd�;��+C!zd�fd�_���N����w�Ŝ�˼�@�l����e�m[�R\*%��ѹ����4}�'�Ԑ�Y7E=�TO��E�*�٧F���U�^%���}��{\���3�J�5ǟ�r�8G���h*�t�ы?,^L��bϊ�}Nj��|S1火uw��yrn�+}��[ʋ�8H//��t-�v1�ˁ�XI�Yu]O�]�J#5��af���9�P�1�R*⎄�m���k4T��gI�>����y�L���ӄ���TUQ4�G��d������ܡ�s_��ǭ"�V͖x)��o�7ހ7ð�o��Ox�W�3�p4�K��{��f�P>#>���V��7-6�k���(K��"�A��8���j&⤃�Q��ܢ l��"f�b�ѐ9b4�ۄ~c[LtE�ޘ��Nq���W��)��E��J5^1vr�ڹE�(6�:%Q-/(g͌����vQȂ��T����Px��nr~ICSS����~�%��K��~��'�Q1�
-ʪ��c�c(%����[u�������@���F���FF�ί�h�?&!fcv�k�h<�x�����-���K̰�a�1�� Ɏ������e�rﰕbBϖ6UJ�b�E�W6q퓓�Of"�������~�����{��/�I�X����=��-�D��Ř��Qj���"�&�ǯ4_�*�3'7(*�y>ʾ/�t+Ȗc�8��n9��(?�D�������?�>|�V�z�[�lbT��13��Fg)���Ngu��p���9qTP*�**����+�j%E���I�����V�*���dA���=����.��144����/���������ʧ�|v�TMj=Z�����AB|�">���<M��R�ߜ��e�>.~�ZN���1��������9��K�y�P��:��䜬6�4���2g�3�#��^��:G��`Lgݜ?�#cT,�Ȧ�OtO��XP&�H��t�-4+ ]�ZCH_�6�Feeۋ�?.���mo�;s22�7o�j����<'3#�nVF^#_D�����T��$�i�Qf�[��1n܊�)L�hџ���r��o�j�4�iV^Vz�23�iy/���+m��i�?T�J"�<Y�,�n�#)T]��̜ܬ����ԭ�J��~��o��}@��	M �j�h���,3'/+3��{S�f�P2&��ş:u1�Ϟ�q�Sx٥�V�f����u-[f�fyﳬ�� k3���ڄ�&x_���5���g�FY�3B9�M���t������8��P�������y_��x�e���<x�|�jr�c�d�ڤiCb�]�$3M>y7N}qԃ���u�آ	�@���h�<''�i^(7)5h������o%V������ʹ�7��V���e���-eEEV�+]��@DT}�4�VXڲ�-DB�Q �7�1T�ʚƸ�a����r�1s�v�!�i�,+$�u����p�%jyr2�X�34�G�@ehTi�5O�b��椦c�Z����u�#�KyR�E�.o^*)4��{h"Qp����ŭ�#��i6ā��dR�r��F�2�Qp<Fb��]QC�FO�ruY��?Q�A�2�����Ƶ+x���d���5e/�r�a��w
-�0��P�cw�M�F_�iv�)7;')�Y�M�q秩����ml`)(��6U���TOGt�g~ֲP�	~D[�qOk��$X�E���XD�&��s3C��6e7����Ȍ�P�nS�����F���MO1U_ZNf.*p�X��G��я��y�ٍC�C�����%��K=7Y���5=��\q!1�.��,Ӆ:�Έ>&s�#���T��I�a����V(��N�	h��K�d7A���I[%>4GD�w�{Yy�7��KQӼ�.d�K��5!��)�DE`�פyGsNQ(�$}�?IEu�Bg�����>�w���c~�5�j�f���;�yk==/�C"˯ȡ��5KK���歹�NE@� ���!D�D�4�l���cTUTa>D�B˧�؝רy���fٹhϳ���� �L������(��M�O�&���^?;//���_!O)م/�#���8n+$/'��_���B� #�GĘ�(��_�f��Z�7���ko7�l�����z�֦�M3��h��2�32sP���9�n�܏��*4Y�kr��/5qtɨۥ
-���TZn���ƍ퍲s�>�n����=Ч�C�������ٍ��e��-�e%m*
-��@Ü�&F�͛�6�l��0+3Ó����� 3';D_�.�Y���Y�|�ML����a�ƍ#��UԦ�$d�ۻ��No�c��͙x.c��m�6�LT_Yy�K�f\��.�M3ߵ`�f�A�o^�{y�sj��m�q�%�2+O���2C�mؼi*%Ҟ���_H����twK;���T��B[L����Ond���h���xe��'f�t��ΡW.���5o��ZG�}w-#�X�j��
-����H"�xj�VP��ȮuB�h��9���*2Vb��v��\� .)i�T@��x���V���ɑ��g���g'�ҏ��񅼛����.�O��X��Ъ�5��Y�Yj��g�Fߋ1�BL6��H�1�ր�WcM���"��ir��*+�G�Rg�ޡڼY�("�n��c>T�A7.����糖&w�����D� t����Ka[�X�1��x޻��M���+�)���쨈�v8������Yk#���$3#�yK��wmb��qF^_l����bW��~d�9Mg����!&��
-��浨LN1�g��s92���Ĝc���jF.�q�ǆ�@�qd.�1��qMk������5���N���x�(��'x��x��3b��F���=����0�1�'"yR����~B3XV�3��nu{t�ѓ#�%/3���7�n�<5/��8�_2��FL�fOť$�RR|�ς�*RWڣu�+�\�R��%�L޲�:6V��DUuUwmK����D�������J���qy$v��ġ�XՅ��+~M��ې�L���yq9%l�芝��Ƕ�p�������A��8� 6�"��!t���k�W�w���i�4Q��VT\(Wh��֫Ǌ�aW-ܦ>����j�WYq��w���6�VD��|�G3̊��G4�9��zr�Ct�Bsқd��
-�b.O~2V\�feW���h��YE�����v�0Fjj�i.=��H-���j]�3]c���x��n�H�dD�]��j�
-c�j�S�_���,K�T��i�h ��g�|-HC��а�-꾥�p�@]ܿDG(�"���-ä�U���r�E�ڢ<1�&c�ь���[�+'ͫD�ii�lȋ�iK���8���k��4��ڡrW��bc>J��eY�..�S�^N	%@�V
-�{�螣"|b��F.����w�Qޕ^��PH.�K��J������R�0}q����ltu�9}�5��o�"����T���Ua����H���>.kY,��Y��<i{����ΚS&F�rڊ�
-|����D}t~Vn@�H�4���O֦4L]����9��5�5�~fP���8P'�v��Ef�ܑ�"kZ���+�dpXkՖ�U=ð�G~8�Ƀ�1������x�]��#��@�#�F�>TC�#:��PS������ە~�.�}vҿ�0�UqI[���V��il8�#cB��-�����\(iQV�..��2���_�����&�Z�08��E����d��d�zHiXk�L,�x�0�I~9�^z!4�!�:Or<&�ۤ7]DO:��Q�ˌ]j�u�4���X������q�:��-��D�k.hr��&.�s��r��ϋ4����qz�;2G"I�UDo��XT�gFX����� �+�l��>w���)[�M��q���ޚӸ�YV�O�:��q_k܇��ʙ����B�7�ƶ�ObU69���x�n�:��]+�ڶ�1Xvfd7�Oc>�أ�C+���^=7X��$׼�#f�Hn��8Zl���f���Vr�V��̥�mѮ���Si5�L2b�w�Y؍���O��(^��?�,�<�C탡�X��'��b(2�\�r����ȟx��6-DŒW��[����ns�Gi�|s)]\5KՀ���3g�J���=TcJ�ⶤ_�PH�M�6�n�iA�%wKa�ŝ)����z���grX��4�y/B���?�/w�r�1+�#34򩺋æ��l��[�^�.g�qm�yS9R
-��'�Oc%W�z��*/�p𘗞vMv��;P�ݥv6�NG��IG�nUq���J�	;[�Xl�o�̦�CYy�MBr��������OZ׳��M��\�K��6�������*�]BSX`%�U��I��H��v��H��Z��~� _X~�Z����6�r��KZ��r��9蠈i-#�
-�\Z?kU�ɉm����0e�
-K>)��P;�_~��X��x��+G�:u�(�����/J��8#z�:�24�yjHւ	�JT�¾:�odIW�`�D�R��P�)�!f�VUWT�8�m���I��ⓎO։��%X�G�vq��:�{Z)m+-�E�s���%��~#��ܦ��F^'�N��OV���[���/I����b�w˶�Kڔ'���ܠU*�K6�}V�
-d��P���� s�[H�4B�M�D*�T�IH���̺��k?Q%!��v�7
-�C�'&���	�}:Z+��׬*3zh2Ǎ��Z�&-�|��0P%%���v��H�"�Z�W��>��V_�܋�Do>��U4<�A�aJ��ph1�Yֺ0��ղ�,\h�<�j0��y�����4�ȗR�q��1Q���E�$ƶ�z~�'T�
-���o͋��+�S"!��|�QU�޿؜�C`��}�GEIjEyj����R�Y�ӫ�x@dC����6q�I�*��̳L�k���'���UD����(m�u�79��)��g|�����[Y�*����33ln��k)�M�'�
-'x��248�6{t��+n�6�Z0Ӌ�bz�6�9�1�bZ������t�42�ԉ��I�#�`�ԉ�~���+�<�ْ�N�j%w���_K�S�%K�"T�F�vʸK����PRb.]J�S�}KVj����(��ʣ���|�bg-ڴ -~v9N�Prt�6��~�����.��pC1���	X[�8�͇�(�E�}̘-�+��)k~*�3W�(�MlU�eb�jARs�Ơ^N��|������#f�� �ſ1��,;3�ԙ���U��Xi��&.E\N���G� oq)2�<*��#��=�������>kYQ^����_RC})0��J�@��&]��e�1MJ�)+Z<��Uk����Z�+O���z@� �j �d�T�"m�����(0q��c��Ц�o*���Q�y^^vS1�D�%2>_�n���qFu���*z2���O��f��=S�Rn� ��ࣷ%�͑`(C�s2���K��6�� ö��&�96q8L���I�}�Uq]0ݲ�{���a�L�J�����#�N��2��+x�t�e�jIg~�Z��|h�[�%MyV���)�@�������jνF��x����1�'�*ţ?Y?'+��Pz�f>���Mg��*�7�����B�\q��|�yfn^jnf���2W$2(���C �A^�;4�.��Y��SF���Iz���2sB�_�X	�eӬ�[�j�U��r�%=���CD��\q8n5��P�S3���?i��c�VXb����)��{�̒�^�Ӷ�w�7ϴ������g�����Z�aja���*Xw��S_e�J1�h�t��Cs���wFu�&W-'��<�?�U�(&�)����ͲJ�q[I!�ڭ���T�􈡎��˂k&�����d�h�[ND�R���~����qI�WM�ۼpW�}1W<K	/��L&�q+��o�3ot`*���Ͳs󜐾CE�/M\b���2�y3�8"�t!��ҳ����AZ��@L��)�;'����в0$.d��UVn��M]��2Sob����&��M�ϓR�T� ��?*kSR�ڢ0��kj�C�+�-�V�����~�_���A����Y�|Z�(����\\ke�(C��.����	����6�g�2;U&7�q*z�E/Ӗ�T:�S\D_Na�迺�D�G�Se�XJ8�8�{�$�<�)>��&Yyv��=�/�˷h塽c1�%ћ�e��>�A^8F���v���U���t���f�m�� �+�V�U'���?�S����n�$��5~T[E9K*:�Wiv��5/5�3�>�"T8a����Ma�}��`��(�Pg%�h\qڹ��-R�喺��se���Vs����ΰ�Tg�Z4�/}K^��*�Tp�5���e�D3�Tt
-U��by�Ic����0�SXV�s�FJC믳@tY[��b��\G�L�YI��/�z�����I�=�(����W<��}\X�:�w�)y���_���NE���
-��Z�|S�_�u�S[�b[ɽA���0��Ĩ%�)	�C����s�MF!���7~Ƃi�э%J�:��䗷�|\�69���-�9�ܑ�*H/�0��U���&0��wR֦B�w�s��WXJ²3��6�#+C�-F��4Y)2�b�IζV4���m� Ea	��V���R��\ƗQ��Ns-����'2� 47�Z�^W���[/.�J�t��6�2��0��%�ac^�g�a�8�h���X��s�{3�
-Ϻ�˚��UW̴A�������h��}z$&b�_XR�)�Bb̖O�d����W�@zS��Yr6��e%�`�P�hx�(61��3kv:N/'�bʭ)*��b��dÜ���;�^?��b#��[Q~	ݐmN���q���x9h��无|�M-�KR�u�7lt$���&mh���f����9?���ay�+oSJ�|s_���I2�����n�n�srL7@h����C��m�R��r�X��\zIu������Ý�?q�y�_qK}Ba�x�O֘�(-�?�f��>*L�e�r@I�L*F�T��S�lڦ�FgEL�:�ȸS.�B��&��Vm�"��T񡧖��ʥ�:���rF��F���@�!�Z�/.���i�q���/]��/�"�T�۲�6k��m�ַ�Ɵ�c�p�Ԩb��?��k�NX&��oq���vq^���U|TF=詤# �v��� U�aC�>�#'�EE��gӪXnܷ���Ek�Ҵ,��-8hB�.��s�����8���@:?S9�*>t�V�E����I��Iq�T�wf'T�E1��C��>9r�yg��cZ|���XR$�[!
-KŪ�ؼ�ȳ7B̈́��X����8D�#�G��P:�v��+6+��Vx#u�<�jeA]��}��S~����/��t����u������U�j�n���!-a޷��%��w !P3�D %��s�Z��u�~h�
-�%��j�jJ���}��Q�c�~RѿW��J���?P�v��F���
-S�����V��a�gق�lp]8i�&�[�-x��mޱ�ڂ�l����[�-����|l�ӂ���Z���;i��Z����i��Z���{i��Z���k��-8ZNЂSa�gk�-Zp�ءwi��5}�<��j�9M��鷴�t�ɂsXp..f�b%�e��ob�-,��d�Xp/�g��L?��S,x�ϳ�,�^c�,x=��=8K�у���"]_�����*=�^n��e�ܬ���v=���>"�!r��m=؞��� ��a<��ᔁ<8ܮa~i��1H`�#8��,G`�#8���.t�l-�MD�9L�#x��3��9�~����"�=����ws{8a[��9�K���rO{���> v��r��|Wp�+\����*Wp�K_��7���\���Nr��
-�w{�8�
-�w�u�#�UW��+x��� �\��`ow���a��H2g�����\b������b�W3gKп�&wU�/y���&_�&_�&_�&_�&���^��Wo��;��N>��O���{���>}�O��ӧ���>}�/p�8��O��)~[�d*���l�}d��]���<���������@��d*��rC7�qKw�qW���@��H?H�
-t���;H��4:I��4�H��4�I��4zH��4zI��4�P��_�gɣ���	z�DXj%o�>NèY7y1��z2}��@j6H��jΰ%�ғ���Ě5�#��c��M�~5QD���\�0���K�Trkf%S٭9ő<ݑ|=)�Fl���ɳ��D�'S�M�����$�x*��TF�O:��T&S�L�R	c�]��]ɇ`����p�����-3 F�Hw2��?���\%or(��]a�SyVyByY�()^��Zi�u���0u�:B�~��R�TG����i�6O%ח櫕�����R]���ժ�	u�4u���j}<��RU]���媲B�ԕ��\��Vg���>W֨I��ת��ש�e�_m �Fu���z3Y��[��7�Ⱥ]�!��v�u��[Z�5Y��{����Ⱥ_= �o$�!�����Y�Q�J럎���zBZ�O���zZZ�!kwU=+����z^� ]~����~'��+�Է.������G�+d��^�֬�d��ޔ�?�"�m�����.Y������>TIk���Xmg֦�-�~n� ������YZ�u!kWK7i}�;Y{XzJkN/Xy�������j�kQ�Y��-C�wXB���=�4�:�2¿%�?��,�}����!�9J�T�H��|<�"J���KMS=�/!+-ea�e罹�U�XԤ���K�%��+i���2�2~'X�`��[��Pԗ�a�2�2��j��J�
-�8e:�j�gY�	�Pu�%a�e����<�DEM�o���o
-~u��ZhY��*�꘦�K,��p�S�e"�{&��P��LW�C�²Ҳ�b$r���V<�Uu��ڲ�s���u�X?��^��S6Tr�.@��-�Pu�����o���ق�z���Rك{��n�H��ʶ87Euo��;�����t�t��Z��/�ڢ�S<{,�&�R.':�"��}��-�~�7��J���!_;��R��4T�Bد��BfOSY����W�Pt���_�XP*G�A���J_����z¢�<T=i�h9���P'�%5�i��3���s�H���(W>N�y��7�TP�Rʿ)��\�)�΢&^�|�}岅�~��B�@�&D�v(��-�${�ܴܰ���]�[��r���J�=��M~�U�'<�Mf��T+Sm��3�3���N�����T/����gZ"Ӓ�`,��dƟd�S��4SS��S�e����<c/0�E�Lc�/��6�^f�:��K����2�k���~��_3�o�V�y~��g�����d�?1-����/�i�Lk��[Lk��f	���	Ӛ2[6�4c���3�i�,�9���ػL{�y�g�����7���i�`I�dZ>�Z�@K(`�B(b����b�����Y��[�`�f�ߌ�3f���6�O�����%�'��������O��)��^���B`�X,�_ˁ�J`�X����F`��l�ہ�N`��������A����a�'*�o�U�ώ�<��V*?�(��S�i�p8�. �����R/ü��g�ׁ�M�p��Uس����#��y���ګ��U�|��N@g�i]T�l�
-��(����
-���O���»�6�c�+��h����b�B�aj���Ke/�V�jV���a�9�A0C����9�G�D�j���/����5�Za~	�h`�ca���S��D>�`N&�<�:qN��>��3�,���9�\`d��BĽ���`)��`~,�񬄹
-~WC������}-�����7��&�an�����6`;�w ;���k��6���7����S�A���A�� G��u�Ⱦ�y�c0Q�j���')m�Og����L��Z�a^ �Prԋ0QJj}G2<�%�ߓ�\�yq\����&�n��;������=�;�����!{����[������ t:��.�w��������z��Y�}��P�k��l �A0�s(�a�p�%^	��(ؿF���H�8��`�s�&��Vk
-���Ӂ��f���?�<��s�[�"��a.�|)�e���A����3u%�
-n�a�ւ_�6��a7!�Ͱo�_8eVk���N�������"�>`?����!�G�8�����'�����~q���Y���j���Eؿ	���y�+0�¼\n 7�~�m��Ϋu���~�< B����ǔ��vV�4q��('@'�3�]�,�+�n�a���O�I�Q�P���7��@�@�Y�LԊj�a ���7�}(0�1~F@6�0GA�%�Fc������x����'��)�O��i�Üs&d�`Ά}��is����V>ת�+���X_dE
-[Y�%�R+{	%*mB�UR��}9~}�V� _����\;Z���an 6h�jo�;J��a�@��m�q�{i;�;`�	��Rw��~�R�
-~�n�`����yOq�a��К�߀?
-����	�$p
-��w�Y������EJ+҉R��wV�\���!��+�¼Fo��7�[�Qrj߆��.p�7��i�?�3�T�~��1���j���� �w��	fg�]`v��d��۩��@O�{����{_����� ` d�`�9
-��ᐍ F�G���G_�}����ڧ��c!?��O ?�$��aN�9~QjҦ�>��^�icufsl(I6>Ӧ�d��+�m��&��+�� �~�Z���0���W�r`��U �����
-����l�U����&��f�[ �Sw+�l��@|uw �S�	���6���׈iQ��m/�}p�-۫T��� ���#�7pGz���
-�Sau��<�	{�����,p���8��o��࿃y	��0/W����_�7���-�6p������#��1�NC�|t :���@�+��� z���@�� C���0�5s0Rciha�Q���'��:���8�=;�D`0����P���Na`��L�g��{� =�nZ����u���:�� �E�b`	�X|,�Y��
-�+�U�j`�X�6 �M�f��V�9�i�;5f��`�������!�0p�8
-�'��{Jc���������-�4\�.���� �Q��\���� i.�
- �Hk�5 �֮k��Ưk
-+���"4�E����� �G� �ߢ�0�1V��� �u��	����(u��tz =�^@o���� ��"tf���j���F #��/`��Y�R�(�_��1�X`0�@�hL`�&`�R4�`*��Ҁ℆[Eí�`��b��f� ��B`CÊ�`	c%蔩Ka_|�匹W��;RW�\�cL[�X:Ze��ik��-�9�2��m�y�3�	�n�k����ǘ� c�� � G�c ��ώ�<�d��i��R���va/ !�D�.WK�
-�u��+��܆�R��>����Dc�^yD�~ �H;�=��u�ց����;��fcѮ�t#��:�\�	[/��&�>����~@8 )����@r�``0�È'O#�I�#;!�(�|Id4�13��qD��6���`&3��RK3��?Mg��:�@�f�#1�l����u>��Q]�3m!�Xg]4��R�/��M�JYNd¬����`-��t�K��@�0���	1l�鬟�r���oC,*�� e��n� e7q�t�_C��=Ġ+;@A?��:D�)�!R�eV����AJ +�Q!%�"T��+��|XgÔo�G�c�q���^>���i"g��%r��y"�|K�"��\"�=�����w��5"׉� r��-$�p�� �G��c�Gt :���@�+���z��>@_�����������Q��Q�7��c��ġ�:F���(��Gs����X�.�xeq�L���Ġ6^�D�d"S���PS��Fd:��~q39K�E�l"s��%2��|"�,$���b"K�,%���WD�Y���)!���"�ӎW��������d�Hd��m!f+�mD�#�;��ə������5��,{��#���"�"r�������`�s��	"g)#Nw��i"(��W8�b"����C����%�|�21W�\%�g	�a���������%r��}΂ ~H�GD~ �H;;H{;�1�t$��ΰu��H�Lbz�E�7D}���1�� 2�A�3���`���De$���v6Ie�0��V��)�_
-����c(�����8"4�4�	�D`0����*q�FӦ�'��dE3����f#��3��̦-�e\K�u�K!\,V ��H���k����FQ���l"f3�-�6`;ŏ��������.��"[M�
-W������� ����C��ǁ�p
-�ib0������p�b�@�["E�!;�#���p�$W�v���� r�[��s�K�vW�A�Я܃�>� x��n�@W����)�t$��ΰu�����@��Ӌ��D��K���D��@b�b�Fd8���$�"��|	�hb�KdD�	d�Hd�}��6]��`�4_�6��r�rR7D��r���Ⱥ��������<&���̠�f:�le��͡�f+�l��8�<�+�|)5xh+U���%��DP=,P����DV ����J�O1,PV�|5�/)�5�HY�`�u�����(�9�b��o�e+���{���N`����`K(��c�^�g��-S8�R�H;��:��
-[�����������R�9N���DN��i[-�⬃�!n�r��-��D�ó~�`��D��v�\n8��mPn�r���`���oR:@[@���D�9A���H"�t"ҙH"]�l��.�fe��Xw'�ʶ*�, =��9QН�����#*��П� "�4N����$�P`Y����6�,#�|��)M�f{r�X� [���8�b���b&��d`
-0^R�i�26<�ځ,3�<���K�s.ǐr����;�{��mW��߮,&n�����Ne��pr����T��T�-Ӗ;�e���u%��T��T��T��T��T�:U��v(�B1U��U𽜘�`0hU1�T1�L[�p-�+(�(��#��� 1��zr��D��X6QR6��b���l'���	�"��l$f7�M�|M��q2�^'ۥ�� 1��s��v�� � G�c�q�����o���s��S`0bM;�Ӵ3H�Y�����\ �["�|�%b��e���{�\&B]Y��Ӯ��*�kD��Ad��|���*�hX�]�����N�s��1&?�<��$1�� 4��a�z�$?��1�v.��I���9�a�#qG�t"���$BẐ�+�n�C��d��A�榉�I�^Dz��Hޗl���'2��)��8%�00Ád�bG�Q.|B�h;����XXƑ�x0�T0�L&��c
-̩�c��̀t&Yf��M�K��b�y.vLYHd��.v�Z�c���!���2�򕋽��t��&N*�a[�bl���V6A_�mt�3�f"[\̾�����9�\P�m�B��.���Ŵ�.f���*��N�M�!�a��8^}��s��#U�#��B����cr�N��D�9D��P:J��(J��&�Ow��NV��D�6�����|0ͣS �T�hb�#��H�D�� �4��^	�#�)"�(,�m��.vY9� \�r�Ů+�`���B�q~�Ŕ�Ȍ�.���n+�]��pn+w�C����n���]��{$FcscV>�#���U�@R�!�%�#��<&y;7��Ҟ�ω�&/��G�kG�N�u&҅��u%������nv_4f=�,���=��
-K��f��~n����*�Fu�@��u(��;��ک_E�K"���!2��8"�L 2��$"��L!2�~��:���t7�\�Ed��%�q��I�d7��ï�&f���� �E�b`	�X|� V�ܬ��������z`����M݌gB5�M���I���m#�^w ;ɲ��n"_ك�{ᶏ,�� r��!����"Ga;�f��#�	�$p
-8��,���!� |\��;�]��j_�u�7`�t���-0��;�=7� >@$< B�x������jG0���@�+���z}�~��f;-|�j� "�<�#�}���R�[@� �&�G	��hxC�X�G�x"`��Z�$��ZS�B�Sa���Q̀e&0KD����:��z�4́��ޔ�ޔԴ��<`>� >��/�xXu)ˀ��J`�X�6 ��-�6`�����=��z�7�O=
-�p8	���o���+�5�p�� ��v^t���@g�+�����Jo/��}`������P`0	��I�9���	�D/�ȝ��d/�/@� �(S�l Y�u��5j�i4Ë��,"��l�:ǋ6����m0X ,K�e�W�r`�
-X��끍�f`+��K��$vC��N8����*u7����X��C�a����G�v��c`�s�IbN9�e�༗�o�7��ƨ7���2�-�E�� ;�۰������/Kk��#X~ �|l-ǎ�=%��>|�>�-���l:��M'Т�:�!t�(�����cJ7�D;/X���c�i��$�k1�Q|�J	ŀA�?}��@?���O�e 0�c�+C�e8�DF��i��/*6����Ќ�:·8�#�`"�����I�t?��͝�U6����N�I�ԭN��gc:m��N;��v�!�4sNGL3���,���D��6����ul��R�/�9�"������Q�"�b�-!w`��������W��*`5�Ƈ&n-����F�oe���	�_�#��A�h�m���`2�7ڗ��]>��9�Lu/,�(��}|����8�K}��|�Ḱض�|;��vBԇ��o|l�z����$�����,��#�<�􆾅�E�{�E|�_�^&�"��U��N����l;�A���=�����CD������i���?'���w�;x'�;�Q��y��y72��y2{�yO2{�y/2{�y2��y_2��y�3���~>�``02m�� F��lJ�~�Z���;�������Q�ׁ'�<P�5K�/�g|,��|
-r|��h��u���p��g�$���l�:Տ����P�/ g�����(��t������Au��ϥ2r܂��Wz %|�����B`�X�Oq��V����U��#����+����r�"�J���H��Ld�n���������t�����n�k?�WR�|�Ma���� ��?���>~���,~A�@p؏�w~���玒��*ߠx�f���O '��>4<g�s��U��/�G����E�;����D�u����������^�g�J����
-�6Y��X�����}�މyQ漼}�eƋr��#av��#��@�^���{���s�����H@P�^	l�ڛH��7�����(�0;1*�~DJ���@6�~P��M��D�K��D�K�C��D�X	�� c��$�K��$�M���=�� ?�%� qׄ���Wq�D� ��c�5��Ü �?�$�#��)0��
-s0�tbA>�,`60~�Gn�W��ρ� �"`(��0�!��#����R`�0ht�[`9�@𳁕�G�\s5���k�KZ���9�M� � �'��0W��s�� �1��[�>p{z~�}�Ѱτ��/����	�a2Ғ�|H��@�Y
-¤�R��<{
-�7��Ox� ������<#=)?C�:�42�i���Y*"JE&�"�T�ԑ�Rᖊ�����p��Y�y~���g��Y<����,~����s�}�s���9�y��a�!�sȐ�q�!�yn��[	/�A^���2_���/ �/�p���_@y��Ix�^�wanƀo篅8i<II�>��	�x~�O�������������%���{$�k���Y0$U�2|��Џ:t@g�]��@7�{"���?���x�-��`n) �-)/�N[��m�������Z�_�SZm~FS�k�L᳘�P;��ګ|{��Z;�.���园u�,���a���_�}i���KK�D�~D�Y�� n(q��.�X�N��$t�����D�^����y(0�R�D�w���W�u�`��.��8��^�{��}�<�H�`�%0:�`��/^�u����3lT�9<�H/c��c�Hy��K|I�2!��v����_��6 �4+��8�ٗ���,ːP߯�m�`90��a�L�������L`���zm��J���ڞ;V��g�������ig��y�[=���eV�+?dU�&��|��u�Xhӑ��%���xj~�׃��V��Xd
-�	����ú�RϳG�lQ=�,��6����C�R��zh]�!�L+�l�w����)+�&�����ㅿ�E�ヹ��-��#�N�����.�a~s̽�>`?p 8JdS-�юZ��!�AΦY��S~�w*�g3,��y4m�=�@'�c�I�0��;��,IwR���z��u*�3,��O���>�r�}O�2��D�$�ɇY�L�5�e�ʇi�Ǡ-���H�Z�Wu�s@g:��{�H�y$�A"�a"�A� ^}�K���Gs+/�Cʛ�Cқ|��&?b{�;±SvN�] ��&>VȺ=��I�佁�ʛ豾ɗ���}`�}����p+��0 �ͱ�T@�[:8	�$Fd8����^G��I�:�cʟ��?!eB�Ba��4��R�1nHB��Leꑅ-�LL���KdY'�@�lU��-�#��d]H�^~��i�<�C�ߙ�ě��R}�$�Բ��j"kඖ��Z���0��$�1�>�Lf�QG������$tC�k�5�oK��&�aZ}������"�Id��D�&�|M�l7��K-{Ⱥ��%rN��ӧ|���9�n��Z�@����G�R�cD�9A�$��D�9���C���v!�+B^$�w�g�|O�3��2qW�\M� ����U���M< �H�35����L0fj��V|���7����_�TG����P8��qd�4䷒����.p����� �����B�F�'��LtF�P���C�-�t����@P�/�t$Y'"�- ��� �k�G�1�;�u�E��^�{}��@?�?0 �V�|Ҕ���ŧ%e�y��<Yx�,<_Js ϛ�<���g!��Y|�#�?�?�1�}H�:&�9~���bm�O�6�36�36�g�m�Ҕ7����*�����)͘}4� L�n�@9���=,�`�@+�m0���e�����NT��WS���oc��6ھ�����40P}�ﵼ��2�Է�
-��,`����ur~n�A����0����Ŗ���Sr���׾B�zЩ�+���ȅG�Y����l�!_��D�"���>��y)��?�W=������l�ക����6���	��wށe'Iv�?��~��~��ߤ�˗���_K�e�r��W����\V���ͷ���?e�k�����k���ׅ�YcEM��i�}~Qy��G��:E��Q �z���>?o��S��\
-?�z��s}�/����7~:�7翡������p�y��+�_���.�M��)�7�G3��`�����l2�c�L�.&��-x$B��-��bM����N	�^�l����|��O>��&X��w�O|ʗ|1�!�l�'��g�?�dp� �e�'��?��2�m�sܿ��zJ>*�|d>���ǘ;�?v�Hi��[���d֒���7��)�
-��ZTk]�۝��m�FnZ���"6��6�n���tZ�P� `j�aq8ATgll&��"����X/���p�.t71�X�����j��qr��a�_$!�0.?="��u�#�!���_�靄�dI��&� j]����Ǣ�J���Vy<�F��8�Na�	XԨ6�#L���`�j2���Ĕ?�Ֆa����?���!����,���E2�B��D�]�MD�{�k�a�_+�$9<�=�<E�Sq�G��#�M�������*���XK�K$��F�&��$|��)���|�|pQ������O�j"�:�(Ҷ*$�EO��T��ĦGl�㊋BvQ~L�7���W��!�������z�$2M��L�8j$�9��dp#��+�?7�c�|y����G)���r�i�y��9%����M*2D}���⨡ʨ�!�P�ƻ�7�b��N��J���b�E�M�$��/D��6��∯K]:"P,�M?�r˸T��e��"S�D��OJ��D^1%ja�K�q��W9���'�����]O�ž���lC�|�A1KL�����T�޸*6RUi�<Ƨ���Vˑj3�UF�H��j�׈y-V��.1u+�'�؟#�nT��Gq{$lPu�4�ݮ��rWmO'ҽ��󨶪UB�C���7S�e����'[B����O&�40����7D/+��:n�>����t�Vp1�h��k�W���t�Z���c���-�*�iՎ�6,�ݤH��0�����k�#yn<A�g"�[u�Z�Huk�c��+��l����Jo�x��-����#_S��I.=�F�S,T?S���ј����Z�TIU2�b<�%�Q��[�����H��ʐ�#K�XF��m�P�F����_���Pv������ע[1��G��b�6��#��@S��Ӳ��4��D�	�?$z'��E�4��5T)�%:M\�5t��G�"�|��3a,�Ȧ]�����?�S��@��0�I̛�*�Ȱ �j�i_#�H=!:>����2��T$c~�S�O���K1]+G�p0��x>�h0ŜABlI�#��\I�_̽	|U�u?>s�����O6��$Cl�8��,N'ql�v'$q7��l�Di��I��M�V �@!@�X��" @,b!�M ��"�E�B���������?}�̙sΜ93sf���{��>�~�����F��:�]��~���q���ɛ���HwkWO1��j��z"�,^ݓ�<�u���U_����P�C<�t_�ş����\<xLzб�&��)Ā��\������"�����<�Hȋ]K��,�@��Z�s�.wl�;�>q̈a��"�!����+!�pCF׹�g�i=�����c�ӝ�CY�*�묒k,98׸��N�R��GQ�˄�����	�z�31Ί��B�#�H���)0|N.>��|���\��fZ��8[:W�w��E���=�W=�pO;r��Q�|����\�(���t��ꫯu���-7~:� Ax��$�b�УzR�d-^�]wN�����c���O-�=�f�@\zX_:����MRN[�ٙ���߸�pz�1E|Cyp����	�toWD߾=x��=z�A��^7�`��U�8_Ф��B8�7e��'�?r�̺����Ƹo�����WwN�5�+��Т� �^�����<������ ��{��kr�n���%{����e �yILׂ�����K�������.�����%�k����s�F���/���NՓ}���V���������Z���e��7��F�C�}�y'�f�ܔ=����a;=��G���N�s�~H�����A�� )�;����ů���Fd�1��.T�[HOi|��0���ֿ��j����+��֍��f���� �v	�~H����s��Hkl�/S�Sw���h(v5���.V<��:XJbU	��J|���(Fg����(�S+~t�����BK�m���ʌn�d=݈�*um�'�/VI=(|KAo��l�·�S����� ����hp#v�g�g5�����i������]o�.�n�؏e���Ϋu���]Y�D�-ao��]wvY�@����k�D[���܃z]����8%F=xL�+ 4�?d]/D��W�h��"�X�ݳlS�V%�<p�z��s|��-��8�%~N졁]rxC��x�G��`��ы�	Е�Dru<�#ϡ��^r���V�)�<b(�=�A	�B� �*J�=��'	��1�Mg^�'��?�t����B<��]n�c�Jx����L�>�z��������v��6t_�U���U��R">��B����Cƍ?x@kwV ��m)��c۔�
-/E�=\b����-Ɵ�vy8��U�}�K�x��@���=�c7珌C�����S�$�+N<Q��:�_u޷���W;����^�ng����o�"C�G����l���TBʃ��\�{j\L�q
-CT������X�{��F����[��������z��9#�^��R0ɑ�MSiGsh����e�G�u��C�aŞ�w�ޟy����u�*�%���{�.�2�=4�Ͼ�Q����?�|E��?�<Uw����}�׊E#��e�"�� 8�zu�,u�Ѐv��p�^�HW�����$�����eCg{>߭��� fg�����/?�b�w}2���z�^�� S�<��f,��9y�+�\�����Y�t��x���Oo;y�oH=�#v�����fƟ�+�����^�x�����y�,.ϻ��n/�t�eW������w}�*q��Ey�ן�nҏv}o��.7��I�y�~��Q^��߄|<��O���G^��G�S�p+y�ݥeO��۪�5$z?g�������Յ������O��_(=�_����}���"��)<���eeb�$�Rp��S:D�z���ly����В9]��.Ec�����|0��>�t��R��-_l�8ovEb�*�P׺R�̔��(�d7���t�w�Mº�c�^	�t����w��OE�r�,�*a���$̐p��#$̔0K��0[���H8F±��0W���I8A�K8I�	'K8E©N��P��IX,�	gJ8K��K���+a���$�/�	�$\(�"	KX.������O?��L�g�g������Ō�7�"��ÿ쓿RX�����`�5g��Ra�����of��`�(�����#�S�_�^�O�g����o�}�8SS��OF�I����X�CA��?),��=���{��$�V�?(��C!�o8��~'�_� ��<9ʤ9��l�L %%�4����x4��h��J$���c@b_QƂ��X�<%���_cQ�����7&���D�oM�Ы��}s�/ ����S �3	ܯO�i oLD�ۅT��� |:?("3~��Y����@���	ޏg!;p6�� �3��� K����E�oKI��B�@��|R��O���<d��ߔ����"�Y�(�I�+��3�CMkq���x�[Ɨ�
-t�
-�����������O7�J���G���O��7��`���Pw@قZ��V�u�6�5�vr6�l�U�N�T�𔲛G��{P��e�Rؠ�R�P��K3Sԣ��
-���/m{���(�	%I�h��F��$GW!ӟ~N9�����QN��1LS������򕓠l�P�l~%6+g@��gA��Ci��8O+�h��,.���_�C\�-.sځ�a�����
-�"ʹvi6W��U��]��}���چ◔(XϹqU�����[�d�M��C3V�=G�|�Ҏ�O��h�g��T�~�"��X�����P`�Bc4Q�$Ұ�_Q�*d@��̇N�nW��# W�W��3�7)Y���>Z��e���UFC�Z�<K�Q��*Q�f� '�\)9�MJ�"\�iW&^T��q��IȍW`�h^��+�uELQ�6Ð���4>�C��
-<�OC�Q�|>xzQ�^�V�bY���UfJ�g)����@i	���-���(>��̅��J)��X�{�Cl_�S���]��Qe#_x�/F��J9�e�쁥���e��b9�7�
-H��A�+�����tUY�YY0�@���i��p��^��!H*e#6�U(R6�R6�-h�e+H�6�O��Z�w��+�.0�kw�pO�T+t�SٛJ-�~�} �v�"W��+�Z@
-���A�eG �Ri���i�r0_�F�u��Bߤ����8��q�c�	�7�~2p�S���iT�I�r��C�l=?/;�I���ۋ�^S�BE���rYr��/UZ��F+[E�
-\2����*4S�An�r�d��pC6�&�[��w"�U~�^���U���; ��E�=|������i�g*C��"Թ���y�"p�2<���y��x!�{X�^dX�ܑȝUFA��8��AOae��K��/\�s �L9�Xe��æ���˯`��8A' kUƣ��n��[��H�.�.+7Q�Iν2�/b��࠻Pg��$^d+8���d@ö���ne*��iA3��t0+ER��ie��OEO�R
-��C�YRh6��)%Bΰ90n<����jb���� �)!w���|�f+P�mL/���2�m���B�&�ܑ�bH��0-�?� ~�}4^i�6l�R�7���c�!;BT��Z|1|Ua���`�
-p��,�kmւҨ�\��G�Ky���7�rB�y#
-��U�+6�qT�0�:�l鸲-h�(i��aa�����FY%\�	�;A٥�
-aw�쑶V�3DԠ���x�R�rw�^h��ԃr���?4 �� �(�۔�1�Ҿ�A�D�*���9��\�:";y.8��Qxl?��-�qT�ݮ�*~�1~�*���4�3�3!���zh?ࠗ���l��7���b��� ]��,C�^�/�>C�,Ǫ��[��ϛq�)�-���Z���у�U�b����Zr�󇯃6KiC���i�)(��o����NW�>����������J�,q���LIU��,�����mQ9۪�nS6a���D`�o�³0a(8땛��������@��l%f�p��`���
-��3A�� ��#Yȕb�����Q���8��R��J���Cd��L14-G�EX�
-��O��F��1j�:V����J>��E�*;oT�T'�}�-�|�:	�� p��L���l-#�ai�T�^LEa��iԠ�(m���ң�l��"Q�Ҹ��Z̀�61
-�b
-�n3U:��w�ȁ�;b6�#��WĜ���Ȥ����<��s
-D��a�u`�Z�>:#�G[���E�OS�Q��8����r�6�%��I,~Z���P�D]�j��
-h���
-ЊՕ���*�q��@����b�4f4k��S�z��Ԇ��hi���ƫb#4b�<^%[�	�:�?L�R�ج�'>[��nU劻M��r;�7����V�E�N�2���bh3�݀K�=�۫�/TkT��֢�fQ��µ�^e��U�A�I����Pr�F�%�A��6�C��S�>�����q+�Q��;a~�JKW�8���e��	'�搘|>�ˋ8�bj=
-UO�_��3�LU��RρrS�#��Pi�.�K�YJ�h����du#4����\).~��S�2�A��e���b-�,u�����c�+A7�{�z�_ׂ�\�چ�č@�B�Vq����[�OWo��B�Cߜ���k,[�}�7[���H�=�{r�;d���d���$�=(����i���P�Ij:ؚm���b'��).�Sn�a!��j�F����'����a�.���
-�Qj-Jl#B���¦�73������!9go��
-1*�u��5;p�C}������B�#Ա�6.��� j�$r��#�_��qs�,(��Ah���]8��j~HF���]P;���a��d�ǨS�ﵯVթ(Y�NCsW��@Aw���7�O��u�CE �W�e�g �a>>�6���{�Z��l��"�K�ۤ�A�Ju.�[�Ґ�y!z�7?�,�.�*J�H���V�$�"�Ry�9еQ-���d��/.A��z��V����T�Y�1F��
-�8&���"D�J4���J��~^�1>��`��Q�㬶G]ص����Z�S�Qg���/�v%2M�F���Hl��z3��4��J]Ө}���
-n�J�~B��Ϊ�Sw�N𯪻 /���?��<�nBC��ՠ_PC�i���Z�%�Vz�a�/V�:�ܠ.A���^�,�}�n�^�4@�quJ5��eg�eujcP�A$ϱC��C�H�<d|��U��b��;�t�L��b'B�!�IP��N���Q䆇�g��S�5�L�L�:��NS��!� ���E�{�%��r�1>�F�X3��\�����_��!v�<�*�/����y��@�?bm@�BNq�W1��&�����a��m X�C���Xu���2C���:C��
-;b@^E�Y����s!6�7إ�uX��4z��F����t ߂$�ۀ,� ����@��r46�w�x�e���1�1�dS���@�QfK8ZÊ�}�1�ϦkT�!�h4�J�qr,�3�q�N�
-�Z�FWR�5�i����?d�5-O#�� �%�/�X�+�&I��$�G�TSdn2��Ӧh�e4��kSa�[l��N��B	�k4C�$����߰�Z�X���t�[�͔�Y0x�6p�V")�Uhs��\�Wj�������
-�n$�i�4
-���B<������|���(pZ+������`��E�����C+ܨ-�����_[
-�3�2��BF�*m9�MZ�n��$C)��j+��j+��@^�zm(��j�]��9��൵�j� OB�`{����k �i��l�6?�U�6�f�U��C�����F�+X���$��X��l���"��mF�m֪A�c�=����IF2�����?wŇ����
-���sxxt����g�k G�k��u����xV�pD�p(�uh�����d*�(lp���$�]��Tߘ�Aͱ�c�a�	T�"��!���D >|j�(ԕ���R>���	P��+ش�I��S�g�O�;)|����'������f�σ^�M	7A^���p'@^�|�6/|�� �@Ra�×A�ne)p��[�/F�
-�nwn�
-(���t���Mk�� 
-_mu��kt׻��x��?kC�l��I�I�P�EC�A6귁	�^��~*|�|������w ���u���N��ʪ�߂�8ׄ��2T� �=<�(}DQZ8��,���H�<}��p6�{ã�ׄs O�� n
-�E�ѨW���q�c�\Л��/�L�p��p:�����&X[x"dZ�����'A�`� ������d���]���)�w��B&]�� ll�^�Nx:���"�{�Š�C+�� }���J8�^x&(9�,��ó���%���s��E`z�����s����>B��ڋ	�~��-U�8}�,}>���.�գՂ]F{v"� ��p�[h΅�Bh������r�*�lx1�Yz9��Ma��%���P��O�Ԅ烲-��i�2P��@9^8��� �חD��TI�増��@�}`)�P���J���U���O'?ae�X��:�`���kÎ���u�.�>l�����+I�?�Z]���2LK�F�WIH��M�
-��5��ͨg��E
-o�T����`�w ��wJ�.T�svH��t����¼�3�d�;�+T�1��O`�0�N�JԜ�����֤+�sz�|^��6~�.��@g���K6�@�9ƿ��r
-_��1���c��M60��7����}��-�eȵk��QT��p�����	T�Pa��I���S��KAQ�"��l�q܅�9�K���Eae�Ĳc�߆��J��*��$�wl�!����E9>�$��~ϪL�$��C���:��*���#DٝF��+����)���:
-��o����t��a����F*��k7�A�N��C�Ͱ<�ܢ)m�S wG»��F;�{a�UDlF�N!�`3���ri�5�RSY��Ҹ�(����6\��`� <nd�6� �t�qиE��	J�1\���b�:"�$�t����c�㐹h�B�
-1������q�5& bN��Y#x�1	�1� �ɘxʘz�9�uc�UhS�e�n���k�1������8�uɘ�Kw�E	�®%`��sdG�>�,%\�n·����^0� o�������\��Hêa�G�O���bȏ1��,�,%�\���(3���B�/i���P����P��D)1IJO�ry�Rݱ�9�b�ez�1��B3�\Z���nA\�B�-�͕(����d�t�JL�6�6� ���e���Rs=�|sZ2�܀v.0+QC&�O3�Q'���Z7�u��&y�BY�8&[�:�HΗ��=��*�4B��^�}�f%��[@_kf�y�ܢӇBK�]mnE����2����,����9�b���r8�n�Ԓ�&߉2��]:������k�����f�N87�{Ф:��c'3k��e�^��Z��IH��ͽPwҬ��Ev��O5�AO���t�z��A;N��\�ɟ.C���6]�6�������I����1�k���C����o�y�l�%����5��P�l��AY=�j��Ԗs&=}�h���ti�䟠�L�L�l�����Cq{o�tqz�<���4���e��^3[ �L�Jm5�#Gd��R���]7y蘤�-��SU&�����x��5O��v�j�g���j����Y}fȘ��l��hZ�i2Y���C�&�#�4���4�S��Y����]�	Y_;�ji��G��`]̷����N�����F[m��A���Tʶn�· o��No݅�8�0Ϻ8Q��cu k��M����q��"���o�A�&�P	����%e���Q0C�.)#$̔��1sڲ��=����Ip�4hOȖ��%̑pL 4Vf=A��q���Y�q ��Y��v�H����<#Q�#qn����I��]ǘ���
-��LbR%c�>Y�lI�b�ՍBD5��-���Xn��п�B�E�t��V`�Ul`M�f _ k�5�|�G�Q�e�Rf��͖��Q����zw.�ۥ���<���|�Vk�U��p���J��K����Z
-x�Zx�Zn��T ?o� �b��g�l��	�fk5�����Z�k�k=�5k������tCT!s��x���jo<nm5�W�m~��n�Nh|���!�.�[�����m�7{@�nU�Y5ҧj�o��d�е�9k/({�zَ�5�>���~�Z� �&���:x�:����C��+� [��}�x�j�8`�u �Oo��Zu�u
-�1�4�Y댬�,��9���y��V�.��P�"�º�ú,��u�����&�%��`p���f���*몴�(ۭ��ڀ�n ��nޱnt�z�	��!�.to������=����5���ƺ�J+�����x�J3�^Ϥ�:���.��`9v:�3�a�#��l{8`�=���41#���� ��Gζ�M��f� N�� N��{���G�� �\��o���2ٞ 8֞h�xa���'��o ��Y
-cO6��)���S'�� 3m��ۅ�'��s�"iI1�b{�L{&`�=p�=p�]"e�@����LcuD�-��}�<{.�?F$чͷ��Ŷ2����E��%\�Q�e�8u���\j��b(���M9��0e��?����R���2諷�C�V����
-{B[��>{�	{5�{�융(��^�{�)�m�W��p.�U0l��	j�ۛ6B
-T�RX�zN��)���;��A��|�m��'�P~��; ��v5�=�hd�]���h����&ߋ�����k��U�|�)�{�)c��`���6J�B�a�������4W�G)E,���������� �E�)l�}��jM~:��r��ϳ��ϡƝ6��y:n7�/���좄� uھLj�l��6[����D@��=Qe�P�P��M�W(=nr�.�ɾF�S&�U��69Z�Pn�M����f�����i���}/�
-�Ծ	J�Mw��-9n����]譶۩��&�g�7��C �jѫ΃�#� X�4���P�Cv�%�C悝d�[�>�%�d2-�d&���	�����M��&? K7ۣ)w��_�j1�&I��L�%�U{
-�:c��� Ӝ\���x�;v�Xg�g"�'ߢs�$�mv`�3ْ�d:쩀��4��N!�]{:�-�0�)�ufX2Z��8�/��X8��%��9A2ג�W
-�LGƌ�<����2c��@�Bd�:�,Zs�RK�i��s�A����Q!eW��VY�|-_�\�W[���m�rg�z��С7&�;k��p���{3�uZ�л>������yf:�	�7�9�%�Ǔ���^��F������9U�|*�)��Wg�8�E�C/WLv赬i�f�X�l����3E�1ۡ��8���|g����Mr��~�C��Lu���2��{(q��Y�P�ء�:���\g���2�8�c+NO�W9;�햱G%GT@�:�[���mpvs16뀹Y2�8�����!f96���K2w;�`�qj����Z����`�~g/��ީ~�i�ó�愳_6� �}�Q�^��>
-CE��!P���t�@u�sx�sL�:nQ�ª��eX���	v�9i�C�S?���>�包0�خ�(��:�d%�!y�i���?�\��/�i|Yқi�:-4�V����&�*`�s�s=���8�I#n�Iq�:~%���ǻ%u�K��z_�C��u8�~���1��w�n:�2�=�^ֽ���<���uסyn8�^�s��vv�>�C/��r�X�ۡ�K����v�k���0�݈y���=iD���^##�:Y��H�}�2�b+� ���uX."�!�|u!-H��/"��"� s#6Z�[}DzD~�<bRd�݇DF���J��P2�G2�,�|ω�YP332pVd`I$pv�ˎQ�i	���T�"c �"cmZ��I����x��m�َ��z|q�	6ME�?�#m�-��b��ʾ^�1���X�V��͢��-rT6Gh̖Eh<�#4#4BU����JE���-2�M�U�5��9�ďqR'&I3
-$|	}p*��d4�hd
-���62���4��BpO�"���t���"pwE��7*�@d�Ap1q"3�����V��pd6��� �E�#�9��C�`��A�C����������H)ʝ��<�gc����|�r���\�ʐx�X5S�E(r7�ئot�A)p����Km�,�vd9t�F*�ꮠҖXi�J��l�;�5��wMPn-��l{�Msj=89��V��Px%R	����l��\�6,��8�����VY 1k�l��raw'(7"�@yܶw�4ͥ�"�E� �G�v'��V��4���5�Ǻ���u�3ܽ��n%,Ju�����}��������C�F�t�%X[� �&w��!�#����E�P���(H#`�`7#ǀOv�f�'� x�]푓 MpO�vO�*�W���X;o��h���<M1����{����*Ft7���˗l�7_�ҍ�e�Y�6�� ��m��mE����:�*`�{p�K3�.M�2�:�W�m6}�|�=�MP��[��aq���@�]d��v[����u;P�B7���u;4Ň8��4G������p�Ah�[��7���H�'ڀ
-����t��E0
-�b�#Pl��	�,�n6G:��𨠆lGZ3Rk�ѐ��� 6�c ��c�c=*U�&w��/��x����N ��Nt������4�*����Nv����.4+�;5(1�j�P��.a��Q�����sg��˶g:}�Qw�S�5�ۮ1��n�#/p��r�H|���Γp��u$�����2���BXxU�y��H�����ޑ^�#}�㊻�Q�R����`���_t��E�]r��2ȴIW�݂��r���*����t�]��.9�0�(��+4��Pt�]��2dn��Pz44a�sW�5 堜`��@�:G.�%i^;8�0Sa��3���0��z�P:��F}��J�zD�t��t�*�Mmrh�ތC�-�\b�G#��m̡!���ݵ=��p�����}K����v����X�<�������ܞVM%��q��o���.cB	z}��q���:����h\��X�-���w��;��ծu���S���u�2P��	L>
-�,���C�'Z=O�2�;8�;��;8ǫ��i�Y��s�E�yG��MȔ{s.�%��z�{͝mB��k�W�)���k�A�A[�.�n �z7���� ���H�>4d���c�G���w倵C`�w��� \�F�>8��
-oHDa˽���c4"B�z��K�P2L�P���[�y�
-|��%U�����FE�$[fFK��M6&�����q��+�����	�n����u�D����z}���ʱa��ؽ���X <� u��9�	�Fp���I��z�<N�5�tI)���ZoF�1����!��ê��Y(~ܛ)�'8;�!JC�<u.,:�����������-�2Z�������Ӝ]���H�q�LO,��kC�yãK��^�c�����T��bٟ��'>�� ������z岃�H���#d��-�Mؚ}N/&�+"�"�^�oZ������}S�<ç��J5�=㯑u�~ʧ�*��e>}H�קx�ѧ5m��2����CD�vT	��>��7F��o�\.ۿ	X�WE���I��o��Qs�/���*��:��׸�o�=�MB�(m�O_pl�)�<�߀��~3��>��S���/��r�>����S�>��K}��n�O_�]��۳L?�����}����#r�ѧ'�>݉���Z��#;����;��>}�qȧ�i�� X��Dc.�t
-������O�ғ�.�M�O�e��w��#|��쪿�g}�6c�OO�&���5�OO�6���0�>��U�WG��-��l�_�Ӻ�I>}G6ί�=T'!�w���%o0�@���}����gG�|
-���0����ۇr�>t�����|:-����o@�Um_��.�|��֧Gt�|��٧CC��?0� Z��o<�ӱ~�-����+B���]�ǧ��j�>���O��>}1ҧ���G��E>$6��'Vt�9�����x`Y}�@E�~t��tx��O�S*N���t+pħ/#��t��\a�P�¦�#0�������q�>tX���V�|zo�3�g7|���f�n���t��N`j�E�\9/@�=�":�ÿ���*��(�i�װ�E�Dm��7�s�5��̊�t-�-���W�x�56zM�q=Blt;1�����qQ��݌N��B��j'Do�EoC&7|qܑџ Ĺ��������(55z�s��0���֢���C\�x_�%9-:4Ȥ��M���uz4#`G��n죶Y��@*+��r��$;HF���l�G� Ό�Ei�)����)Q��h��e�6�ը2����G���#O��`3�*A^�ȓ�׌��-���8jWD\�{N�ڵх�lYt
-�5ѩ��Z���ceTƔ81�:}���pWD!�!:p}t
-$�G����My7ɸ�]1��pc/m��t'�F���g���s��K�DH:G�A��J�bT�+Z���D7��y�;������ �-^](��a��h��svF:%,�p:�;�K�N[�d��X��7�a�;U�C��h��
-�1���=UW�r$�ڥ]}��ѵ��� ����Qc}�����.��ӂ�Q%����4���SQk3��n<�
-x6�͕_[lwi�� �Bt�+W�]Ȝ��<����M��Ǆ���	�X�bE��� ^MM�I�?GP=����XF=���7�ڢ�N�'[��oDH��%���2s(���]�v��Y�QPnE�I���@�d�2ߋ��ԝ�i��Q��;�g)r���Y��4�>Ͼ���%�&{��#�9�%�w�ˬ^8C0��Eخ)^D\t5'�K��\q�eF/�)����lȵ�Q��+���UWS!u��C���2��Z4n\��;����K�?Oc��T(1�MTe�D�r��U��[.S`�U�F;����U~�e�����";4&@ƅ�db� @��
-�(43@f��ȼPY�,
--	�e��*�6@և6Ȧ�� �� {B��7�/��à�b�=:Џ��ȉ�� 9j
-���� i]��Э �� �Z�&�tmx�dj�d�66@r�	��M���w��B����\MtP�c͏�R=M�#�,!�X����fQQ���i_��-�.��jl���kj:��P7��T�B��j������/.k#<_m�2=?Ԣ]M0�@����M�k�-Md��L��&e�y��v���s��j	�
->�j�v㬱� �E^��
-��a�@���8*S���:���s�R��\��M�#��*�$c����۩o�����";ɯ�z����.}��l�+��C[����v=��ݡo��B�a;)i�>����}"�u��v�I�zNr+��vT[�^���&�����v�^�ǌ���ު�c^bպ��'Q�p^�����x�&�#��L�01�-S��$����Y�]�Y��ѩ�+�4�w��B���A�Oly�����[8���Tc��BN��vM������*��;�Ɩx�uK����}.Lvp�d�Wq��{5棟ҍͶ��c��7�2�_�z�wO_�1k�b����r�8�X���/����X�۷�����+б�z���p��d�5V��I�A'e�D{F�P��b�3��h=��+�p��m�AS��P�e���u;�����{�S�o�3�9��k4:~$���Dã�z'j����Sk=��7x�O5pfj_Y�FW ^�VdlB� ��Bc3:�	�����T��[�K��i�m4@�]��nmb��l�]F܉w��H�+e'|`��s.��6��X퍍.�C�\^�i!�bM�m.�%�;��<-l`?�n���a=�qy�s�>*Z���$�/Q� Uu�廍p��j�F���8��p�}�\g���G06�F���4�8��c���ˏ{�c`';Aϸ�����9��"��\~��l���xZĸ��dY��ϑEW\~�,���&OӍ6�_�4׸��f��X���K(��"ӌ3s�d3t��nwy3�����r��-=�L��D�<~�H�	���"����]�f�l���q�Q�ɜ/5�uB3��d+B�	{7���6S�N�va� �Q	;w��:��t��@[q4�Jl�j�M��4�M�X1V���\�-����-���f��1�^X��p�e�R׎�x;�9���Ⱦ	�x!��k&�`�x|�mS<��#b���l�ĦPE�ņ�Lx����b��!�a��=�_S���zZ�P�tTd�6����x�7x�ϔ'�
-'ޤ5	t�_�G���پ/���	�hI�y�S�(x$��JT5F
-�&xi6,��fGؘDnB���7V����FfDXiBhQݖ@wFؙ��P��S\��B�K�ȍ�ǣ{�y�����w��N�}u�{8��'�x��}�B�vuz���^7�I��-MH�I��<��{__ߓĚU ��{�}_;�M���!/Ɯ���Fol>����D�3��+^��[������	�"�|U��p$c�Ư{�p-���3�M�E�,*w�M�
-7.!Q8�*Z��z��o'�vxj)����y�ݞ`ͧҵ&�>k�ᡐ�Cb���(�j��>��"����,��p�6?TL���r�?V�� ��������D=w�਺T��2t�h��]���eF��ޠ0�K��݆� Z=?a��2e	�<�n��+ȴ���XI&6x|5a�Ƿ$���j꒰XC]"�u�E�Qv0!},��L����:td�n��� ����<$*��nDÛ�U�U�k��TW⽰��]�?ǿ�2�E��Uƿ�� Q^�㐈�����BdB����h��K���ː�EBY���2s��T�Ys��^��7T�Q����"�U^�Խ��r�^V�	���	��H��C�iҤoA�дoE������ל����!~��!~�c4��~h���W��M��ⷐ~dg��F�њ���/pdA��`��#�s,��!}�T�w �{>�S5���⃑~�j�A���OC�T{�E����#�x�Ƈ!�?R�H?o���<��@���g"��4��*��L�Ne����C*��Xe�H�S5�}f�ƟR�g�k��*��9�?���_���T���o��nj|;ҿ���H��揩�Kcü��Ǉ�A�_^�P�Wօ9�-��u���^X��O��kKt�6����|җ�����ܨ���u��W�뼟�^=��Zd_���z��h�����_a(����S~�f�(�o�����ʾ������n0��*��&�_��moF��]oA��z�_G���oC��&����g�E�������H<��K��m�ɗ!���&_���9&_�t�B��A��KL^�4y��7#}g����1��j�mȿ���ۑ����@���L��[&?��'��	OMɴ�Y�:�
-}We�r	�?}[e?�����~>��S�������-�V~��_� �����*������������u�Ϳ��ߌw�T��
-���T����V:|��ms�.���v���u��5H�p��'��w���"��!�i�����d0�u���3���4����P>9�3����d��_QY_�_V�p�5����wD��T��OG�K*��"�e����]>���@��\D�@F�C.Ue9��ˋ��ላg� ����q��nG�|��ԁ���S�x��㯫l�f�M�M�Y��GT��w{|�I��=xE?���LF��gF�� ��A��Й�2��bOR������8TY5���b>��KA���}��L~��@f�>?d6���@Jxj��2��G�% s��(����Gy�y|n��De���(��T_�G� e�2�'Y�7G��*[�k�HT���G�2 �1��l	?�+@X�OD�: ���(O��I�)*��W�o>h���)�+V��o�Q{��R��*]��P�x_$��z��-��M�/1.!_�1ǃ���!���*!/Ƙ��)��R���bU.SM���f���X�J�B)�D{+f�?Ę`j)ED��X��17�N)%��c�_Ę��Sʈ�KN�޹�Y��R�򪟭���I)�յ)KH��Un�?�~v`��̥HJ�;����B�r�x���t�w�U�_�����K�^r^t?��픋��+��lv��iv��o7��[�gN{�7��;-���1ҙ�t�E���J��~6���?�����ۏ$o��9罂��G�;�]�^c�7�0�^�<�_?h�����������d�o�0����ީ��C�~,�
-c$݀܆}�u$��x���S`o�m���A;|��M�����k��C�c���|�
-�C�5ZA�U~�R�*���>�d)���F��P���(Vu�Ub`��h�x��\P��a1p����O�K�\#1p��T�`�_����j`5��9�ɔ9b`�x*�Y�]�&'������d����2K%��3F�O��'_�1�O����>9��O>��}~� ;A0Aaɷ4_�)O�cO��f)�j������j���'�/���/�e��A��PL���JM
-�G?sN+�ēN+��c���$?3���3|�魿�)h$�E
-zCA#�ԇ��R�]J�!V�����+(e�T��Ii%������ߤD�s�����%Ry�H*jRPd0���}�����6�rP�2��OT�� �j��gk��1�����O��DWz�Ƶ��9���7���0���QK��<�k⌽Z]j�og+�ٰ�g��דb��P�J
-�
-Z
-Z�+�E�0�,���ɴ���ŷ�G�5IL2�)#Է��Y�ﳔ�$���<���O���@�Z�	��Ǔ��DM�j���Qol�ņ�q�hpFt���6 Mi�1�����6��bCf܆��Y���٠I٭�j���w�32�g�׳'�Hʞ��';�� ��h�~�-�Vj03H$G��kp�h��|B��f�Y,�~��9QC���q�O'v�OȎ1��G�<5���}��Ŧ�	g�$��q%dZ�4P�m���=3Eu�q�<E����W��|�	�w���l�+����c����;��WN�<�oFj��充���ּ�)*E]�S�Ç::Pqn�3�R�㥝O�Ҋǉ�)�D�vO�bw���e�����J��~��Y?���&�Y�c��Bȉ\!R�`"W�T�N���ȫ�����ީo����sRz�i�W�YO�Y��a�H~+#�-j�M�z&�K��8�+Ժ��wt�����dBI5�BU��������M�ou)����~h���[=�th%��]H㴮�m�	�2��E���W���.W���=N����0�7+�E���Uxf�(���+�/�>�@�u���Fm�$?W����5K��j����XC�k5��h����#�H��e�#��Qp6gH^���!����4���~�+����	5�;:zC�ܸ�G`�2�4ބzj�<�U�������ީ�b�<�/�:����5�T�&:U���=�<f�b�,� [���&�</J��u^��xF�u������v�_�J����WJT���f�n��=O3/��T\G%�]�I�IT�+f����k;��k���:�n)"�RѨ���>�s ��D���B�"&�ۏ'_��p��<�%��Y�V�e�n+�9����i��`�����S{���^�w��i5�xY�5�)͋f�v`)%��1 C�`U��[�<=�(A/�9�����R�����͌�7���:��!TU��e�C�㿐��B��4Z7��$��V����=�R�_��m�E.�8�$��$��I��3��K���5�9,2��`Ux6�]���A��ò��k|���A�>J���a�ǃ����nilYm����@�̠�Y�x?��,�=O��qK����diW����%Ju)dV�	�<�ڿ�<��Ou�k���í��+~r��j��juJx��ީ�B�J��E�`L��H�C�H��-������		��L-�j��ޯy����ͫp���}��ф�t�OU�*UȬ�7su���'�Х��Ե��	���-��H��6��.R�*��E��L�dzz���x��T�x�6B��$��%�HbC\�
-U$Q����n�KTcx�ix��GIb��~��lM|z ��O>��=ds���-GR�ĨOՖh��+C5l�؛R%��x�D+�#�I�(���@��MY:))�ߐ�WKfi^H���~��V�>��5�~(=�����c�H���;���k�?k��(d��]p$�߹N���A����y�3��}7=2��nG\b8վ3.1����]q�6ұ;.�m�cO\��tT'���D:j����6.�
-���..q�$��%NB�$I��%
-��9{^�� �{�@��},I�*�7����@pS
-D"L�Cﾄm4M�����=�-��L7%U� �䢁��'�+Rm���^7Re�PS~,N��O�=ص�M/|����J����<��r�ò�G�¥A�X���#%�_CÑ���X�@RJ���]5����6h�"5�kh�E�@R�hď�{��{B��_��NQ )GD�p�>�����'��I����b )���]��+>K�����)�r�OS��E�ٸ�Jr�sqŕ�~�R��I�'vQ|>��.)n��ߑ�<�@zn��Ԩ��x���=?O�R�x�e�U���41KPq���S����V�ѥ�K�Rŗe�_�<5���S�i�A��ݘ�Ei3P�Q:�
-����%���J�:PY���\)�P󦏓R��ҁ�5�n�{h&\��{��5ņ��:է~4(�Q���t$�J�x*�FYõx�0߯Q��P��+��@�d�=�9R�Y7�7�ڋ�%Ŵܔ��Rq�����%J�\.�t��%w[�I��5O��T�6WyJN�������T����w�+w�c١�3y�+CU�ڧ>�L�����S
-퇱�� ��~Jq�+:�S�ߑ���#�m�yz}�3��+�|����~I��kj���C��q:L>��ޢ�=�Oɬl�-Q=�B�������I1bS���#^����*"ؽ������@R
-E�hE�xӣ^<9�^���qz��LQt�0��'��M��^F��(�o�&U���yF$��<'�wVe�Y��aI�]MU��ժ)�(�2�Z��퉸�DVE��Tu�fzz��0y����f&�A_��P@�D��
-����Q�Y���8�dB���?�؏��^{��^k��Q�sQ��/�,���b����QWw1)@ؓd�UT�Kr�K%9W���C�/J�:�}������7�Rn�^�s����!H.�+���s��{���S�d�㐊��'�<Ϊ.�!Vu�U�C�cS����^���Pc}�@����cL�g��/��/Də\�P	|�1�.ȶ������l��6*����!�bw��8Jc����zc�`TI�Z�{�5��F�~.�I���Q�-E���3q��'2�ir�kSBb�"�:�l�����!����VJI퓓�%�+���BRg�P$�U�*�:�  sjN|��kRNی������@���@�F��B�Ԟ�VnI|˚����܏�e�?t���p?��Y%���ĩ�"�[o�:RC�:�4h�Jʾ�_"9�`;q�yu�6/��V�Zg�?9Aqh)��b�,'_&�eb���uj2�5�_t+.�M�n�
-n�P�l�Uj�/�`ap��m���[)q�,%$'A�>y�JWh�����N4�_p�.|�h�d]��h^5�f���h�)ܱ�7��el�7Ҫ��C)4���B��#ܗ
-���H��rL��9)���*�� H(�)۹أ��S���Q�H�M�|��B�v��,��-e)K)�ݾk㤔�UGD(V�I)>�Mo���+�Y�r/�I�P�2Sk����N���h� �jY��!�z�1����ԙ���rj9���Jtd�[� W�r(+ڈ��˒F� �Š����*e��^���GK$�w�Bs��tV�.�s�P�5E��>R�X#�`
-�t�#%����`(`bs2�HƎ�W�ĚfP��rf��$���I �Y(P-�O1����@ �J9Vo�U#:\�e{�N�7,e��x	��/�ޣ���Cr�߮a�~��+Y�%W�t9F��5�(y����:�;ֵ����+�r�։_+��������o��|4$�P�;�\Qfyx<s6��"!1=Jh�2� 59�p��)1�Q�U^�M-������d��2�]�)�^��f>��J�_(��G�
-xXsT�-C[#.�se?�c\�A�8�_����a`�A�%�-�C�`�½���p�6�%QPBɩjb�J�T')6IILR��R����%������Α�/k�L��#�/k����!<'z��s��8>.��<�=�k��Y.�tL���7��;�l�#�2��s�<`�
-.3�!��|�ayBv�&���x���!�E�k�ڷP7��D��l��~3~��ݴ_r�(��J�x�%\r��1o{u7P�Tr��|]��.��/�ͥWʸ:�C\��Aj�]�g���w����]���i����$aX[�4�c���oĭ��a��+BO�p��
-ڥ�bAW`�|!ſ \q�C�����������R2$&�~�v��0����$���r=/��`���A���.�&�y�k؄����i>��.?���p�Q'���1��\�*���S�g��"�o��7Rh\or��I�����ġ�-�K3�ϸf���HNa�3��X`H�Ie��{La���!���2.��#�8ā�⠎b�0Z���U�nCN�!�m�:ng��7t�Nv��qC�8��QH,�=b���pc�>"'��X)��R��(����lm����YY_dH4�%Ne(����Ș���Tܞw�ڼ�xBF�Sw�GN͐q�ޝ�!�Sejfdv�\�(ڻ���lm�1����/�C}g$���g$d)e�(FG���
-��Q�)%աXv(��&��!61�%�d�Vz�ԱX�c��ŘĿ�_�!�8�]�V��}�9�� �J|��Wj��0]MLW1��ʲ>�r��I%F��W9�i�ㇸ��~Wh����/��� m�vJK�QC�,��Z���`�rB���i�iS�*��r� \��"U�ڣ�b�='+��{�~�u�׵�׵i���im9cJsK��̉?��[%��w%��6��nDK�͒y]�N�iuq�����V���Ws�?U�O���8���: [d���rb��}�����u��󠿕����%z �ȫ<�H��(� j�`�QJt :���N)4��݁v���@���`���Q�~R�O��~�$�ɉi2ˉ��C�d�=V�>�r�(㲧��i%�B"�'�9�+������i��^�]*��)����#ny��/SZz�k��:4
-�ZO�fcZ$�Zz�Ǉ���"��F�KE�K��n�Cc
-�e��eT3��x�<����c�EI��S�2��y��~�^�qѳ���u�D��z����9���m���~�����E�D���y#�H��FZҴ���+�m�k>#�>W�>G�4����(��w�"�l���dԋ��~�ťaj�ŵ!s�u�"�Kk~1ny�,����QFz��>���)�Ci�j���*��ت��N����*��� �W�P�䣰J���p���(ldf���j��NL����� }=͛�}�0��Q�5!��"��1~�����5#�.c��S�<f�]��������ee\FM��0��q,OC��q��Ã�h�#����[��0����_�B%ڍ�u�,��2�?9S-3U9�M֭�Ѣ:���J\/�YR<ns��k�h�p�LTËb���b��kB)I޶h���ev�H�r��{�0�e4ˋA�Gԍ�\��rm�n�U��4��V۔�n�Z�FNj�*�Y��}uJi��JM
-�u�r�q�N�0�"0U@�O���d��#���C?�8a���$���}!�~?�_BN�ND�~?$���0n�Z�E2JPQIt��k%�;8���YlП%������@��r#�QO�f�J�х)iB0]�x�j���� �YԼN��O�~+:��j����JC��LZ�MԋhZ#�f�{\[���NW'&�:nέ�/Uˬ2��j�y�1Ľ�+��FVRwr�#iJ�⛸�h�bʧ�VRO��b��!�����ΐ@Q4E�Q4���)�QBUb-�ۯ�bL�G��;03i�	�r�YKFa�]�i�
-������׹޻Q/����޳�,'������g�\N����ZG�:�j���,�=�i�Y�@� ���ț��d�D�]����QV�sh���s.�Y,���X2Z�3qS؁���Jk�7GAs�S�TV(���u~z��/�v��~�5,؞��y��0k3�5ws#�H_9��JL�;
-��+�a�ܦA\�àK�wɡ��GM�!�*�Ӆn\����w��t7I$�A�}L�l&`��GW�euZ�_-5�/Q�}Qښ�������۫�"� �F|4�_4����:|�Yp-�imM�@販�}���_ �Bl{��+L�Kd� )��� tl��uVxU�« �W�^o����̼��SiI��J �Y����ZSe?ۍ��O�-�WRjɶۈ]�;�P4C�M6�+�6:!���T�� ��K��ڎp9N�4^����)�"r82�r��}rKS��M��-�`���40�N��/�B|q2�D
-Lg4�L5.q�k�\�� �W�T:�RR��[�z��"��K@�57�}�e1~�{�����\^�:��%^2d�eð�6ĸ�p����v�v�6�WI6RWwU6dVgw��*��ԊqM�Z�^unQ�|�50�K�@�p�Mp��|�b��.�B�J�ȳ"R�B��D��;�o�P�l6B����� �B�/��D1�mn��PM��t1�&)wS�C���!�n����V�ڭj��J���ʾr��+ń3v��E���T�}��y��v�x�l���O!�({*�cN���#��I�Ǔ�듏+N�qTP%���	�_����~���L;�f���� '
-2����*-ٹ������B����3:���C��#�?��w�����
-k�?��/%k��@�s-b�jɑ���f|���}���/�v��ǔv�Ǘ俬H��>xT܏U����K��H��0�4��ԭ�zfvt�N]t�ۻ�"�7�\��K��,���q��a	>C�⫡��]Ht)r���~)�F��[��V�o�_�\�Yv����w8���mZh�U�RG'K���̢���5sNb��fZ���Q���(i/���t�{��>-���G@!��.���UM;n}�X甘S+�9wI�m��ޟ�n�n7$��}�J�,�s�+G�T?A�UA/�*����K�5���%yP��,�m��`=����#	wb�v���pZOP�����1�RiS���¹�y0&��@��NH(�R3��=�v�B��ӹ$�q~=E��n��0���F���`��#Ǌ�C=�b��� ��m�����;���,��6�/hJ��Ѱh�!���_�*��K�6-jbp��v��k풛ڨwu`�&��.�&l"�w���D��D/�
-��ED�Q.Z�6ϭ�nH���4pk8D�'v���A���UQHl�@@���1[d�/���ݼ���鴍�ٷ��,�B��i�� ~�� ��dƇ��l�3�plS�G\?�<��Fu&�fi%�J#�$:'q<v�-$���P�-$�"^�B��R^H�Bhi�"jy���
-�S1�u4�DA�d��G6�B�S�-b�Q��B��X��to�p�Q"��_���5b!|�p���|bjT��*��|#�_G���N�)!��Ĥ>���6�)���p�!�u˔�-ġ\Zz�媰�,�D����l�C�����n�֧�gBA��c�
-��UR��u�M�0�qf�'٤�7)���!Z�1  ]��8�-���yCF�t����H�uf�9��m�!�5�<0���q(��%#��R��V^Ƥҏ_��t8W��ONf�Z�j�)Jc�=�����*��#j�f�`�j���U�h��O�G�A��F>��f�?�.Nn2IR���,��{�P��:��@0�{-s���T�vWh�$D2}F��p[����p�{��(%��!s&�m4�`��?�8��Kb�������o���Dߧ)���P	�4��{�TS����ЂV1�����g�����F�G '���A */�܏����w)��f$�b�]��Q��"U���a��r�ՕE?�h�����2:�`8*�x�]� ��˰Izc�#`��:Di�Խ7��!��Am�4IyJyFy��_7�=#�V��7BJE�#$�Ї|�0B�5��F�B}d��CFhDc�c#�W������x]E�%�����'Uz���F�x�0G����x��K$9�흷��G̷R[a�-a#N��x�����r���+�O�h���
-�Yg�U�i+��������g�Y�3�r�Q~e�;��QΠ�G,�X��v�SC��]�t�l�z�E4�
-�Z����l���G8�&c�K�d/��oxY��\Z�#;@"���t����!֟������j=?�N�=�h�Ѧ��7��F��hq�G�w7��)�k�F~}��4�Hui�0Yú���0�W��gV�������%ѩ��Trս�[�k��J%9-��~��xbm�i�oP�n�j,[V��z���c�x��PiW�CXq�9�x����'t
-*�~��>
-���~
-���Z5��z�<�K���#GO��#�+��:Ea�Ov�����3�K㻙XP�N�7y!��&O��vA��"�W�`��\H<)K-c.Y�cP���Od���G\�0�8��4�N�B���p^�Q'w�|�a�p.� �z]/4���i2�s���b����F�<����OY�
-����yJ��ש;�Ѡ��9f���ſ�ͷ/ٚ|]��.�
-c[e�Y���7��N�IF�}�bO(�Ϝ6\�7
-���}�p
-�9Q�k��F��5bө�y0��О��`�Eh�i�krn�iOiSL{�H�f�[j9m�{�j�!�g��r�C�L{��6�%"t�i?���thmB{�����j���غi<w���\�LQA�}��p�Z)�kdH�����]�6��_:�-*�+<u��Nl�X,|��l��}T�U�ˬ�n�昙��D���+��y��%]0��/��	�l��] ��KɑcG���%ʈu���0Z�#Jr�L!�<��Jr�����
-��~���`�ř�=&����B�Y�.���I.�G�g�IH%�|�Q#�ؾӺ339��Je�ީ�Ƨ_�ec5�KP9t�xz!G46�)�"3y}sh�����������N�84<��&I���
-x�)f�J��1�#�i��g6���������(u�mm٘f�@��P�4�Qs9"�!�~��"&�-y\�͔0�U9O�x�f�Yr ��^�&cj昬���b|�rF�?|;��``~�W7<Fd� N�r�A$�;t�BĢǷ�A1?b�D. 駓��?3���+D̆��$0%�&@�ض���$�%;�X�wu���ה��kJ�[�յ�>)��-�2�	��<hZ���	8��g�� U�B!���$�a�6���s��Ӳ뼠�B�-%�M8�ɻ�^��jQ�M��LS�d7����V�����}���8�����#y0�M�34J"�jl�q�史{��K�8�60�1�f��m�:������ �����-�抴�y�lxu` m�W�������ұ�@F���F:�6��CW\�S):M�\2��e�Dl4�l�G��J�L�y����e��O5��0�x tN։������>��?�&�)�΀2���p�̛���
-OE`*�`$z�v�0ڨ�/Z�k�ʑrW��j�HG"�*�)�?��-X��� �R��q©�e�0���d8!SYu�Gk.�O|ATEW���x��-�Dn[�R�}-�Z�:U�E0v�B��&t�����5�]Bb.b�r��z���Ocp�^���pY9%(�uC���z*��/\Q�NvK�7aؚC��10��yg�*��W�5x~w�P~4+�t�;������~�����0������Df�㏘���6`�z޻��_���yANQ���"	2z��{u�Ο%x���l�����(�!l4[�|���@�L�H�|�<:dd�+A&��ǌ�{uɭ�O��?I��������s���m�J�����f����{��"3$��	
-�8����Ԧ����
-��}���5k׬B{T�[V߈��9�������~��V1��@d�g�"/��3�?#A��Fj"�[+%5e��zyמ�(�4��B��ó�=^��8�����u���p��M�B�](LV@&q�J]_r��Ԝ́H\��{$ɸ�ogq?�k��5��(Y_���=��E�S���<�*Q�;�*�Z�ˣ#��')�M���2M��v����$�׸�������C�a��6C�N���h��m������i�V����R=t��\��t�����?zp��C,�]u�����|�� �n�Jw�4^3x�_q�y���¤Y&�V�"|O�D�f�|�jO��?]B�h�=���d�׭�L.Z97��D�d{%��(�.��#��%�ys���l�ˁt$��Op5�[��¼�+f�	��'P�v�|����������M�.9u�����	Ԩ�����5"C�K�v���Sը�B���ڒ��9�8txr��e�'�\������-� w�#��/5%\u�����J�?Ix����h�-e��9����?҆c A���`���n=��1��[��1�m���^2ȏ������D�Zh����|����>)�	�>n�{Ҵz�B1�{��h�4&�'%��c�d�$��BpM�Ì�6y��b�����_i��ۃ�Qy?�Yjqˋd�zq��-kJ�/%M4��ޏ�4�c �.l�!���	j�Y��i\��J���Uk�ʷ��5,4v˹k���9���'�2s;M8.�_�o�7����lp&jp
-�L	l^*�B�G��"�Y�P��P���_`̩@\����	����V�jӺ;L�k��MP{��x��^<���g�N|��8��̆��Քɯr���n�ʅ�y�1�4��B�3��֘\l�Pu��:[�`Q���#���4��Ulo�
-&��$��賾�q�"2�!j��/����Z ѳ���J��9�Mͳ�U��(��%�Hkxv3ރ�`��2_���RE 2y)�"�47��<�^˜�����w�.~����2�L����f�Ў����D(�"�ŗ`�C�1	����؄5���&hQ��k�|�p��wn��MY;U�t�~�7��up�5��ƍ�R�
-��~ �I>k��zY$�WɰɰS�.E�d���W9YU6��L�Jv�֭Y�S��3��Q���(Ke];ʺb�����I�w��F�_vd�y�����1�v�Ŋ��q�s;Gm��2;K��4�s:���=�����!�G�~�!��Lm�hM�<����ʪ�ٟlʩk���|]+\�>Jlۣ�`VqWVAQ�f�)"��*(
-�P��hc��*�U���W�Z����)^ӱ�u�Q��V��]r��:F�g)�)F���y���W�R.��Z�ff���j'�_�=��k�;=/��k��5^��Z�h$�΂J��!ri���l�>��Ze��%���E@�,�=�U�l��	�UC�Wlx�Y�5<�7�G�'k���.#0���us5!xN��O�v��*�Ny|��A��>%t��'�q�I�7�p�T�i-�l��Ju&6�%6Q�o�خ���9�$�m���Љ:ԴS.�V��.�Y�T���Q�s�Rp�?dl���v�H�};���@�[e�O�_��iB������g�q~�"��Ta���]��RDh�_�P,�RD�l��j������|��q��n���
-D_��
-Bk���>�W�x�!��p�J�ٯ���э~���M~�S5';���>��r��U���C|�W�8��DM.Ԝ�B���͇|��n�$�7U�c���`�w���m͕U�'���Q����Lϴ����~�i��N?�*���u�v�%�]M=F�=�����	����\�}*�~y��o��ϣx���T�<��a�p�[��|�Vs�1�,���&�<`j��$
-dgi����Tx}��k.%���0Y���c2���Z��c�^�����������Ϡ'}\�+u�zrF
-��F�o����D��@����������Jނ2�#�xSh7�g�eԺh��Z�/v������2�������y���g�Q��Q��;�x��p1�s'����e��*N���j�5?�Uʾ�R"���u��QxN����L���ig&���40��7����o"�7����@�~�m(����mTn:|(HzsJ�7�H��|��	��[��� қC�3<��1����Oz���G�����w�
-���.調�^�im��~K[*���U��H��h@ˆ�xՇ�/P����lO��P����8��V5�������:�f��l���3Dh�n����e�J�(q��I��@�,]�:	��Qc�iv��z��c0��㮬���β��TC����R5Y;�6�]�R
-k-��s
-�0E��)�Q�lN��&�F�NZ�&�@�,Nz�M���2�sE�TV=+��~�rG��9�_e^6{ܗy%��l
-F6#[����ȫf��s��SolX�%;*�v�w#l7�a�Q#���e§ЋF�w��^qY��ze�3.�wW���pg����J�o	Y9�w-����Z½���K^?��XKXO���Y�E�U2[��w���m
-^N�z�m�{����<�?����3r
-	��M�����2�@�������:�d�iI��A*Gy�.��f;V�D��B��Ļ%)�$��1�[�B/G?����b���6ӹj��}s�xΈ.�L+�A��D��[�����/q/��χQ\x�����X!�B��<��y�r~y�����	}o���S~����m�>M뺧��Z)���]-�a�{���ky�~$*�*��IE	WV���/�Ӧ�����F<�{������U���o�/� 5��_�J;�Ң�!�����A�\�j�g#ֳ�����g#R���K�ށ��~!����m�i��iI`�?峪��-�[�{ZQh�1?�{{a�qH�87*���n���ߨd�'m���$N�=`	K�F|벖��.������j��/�;�E'Ğ��5Zo�x�yJM<E���ji�.�ɥ���u�YU���M�qLu��v�p����5xJ����ۥe��d�D��"s� ��x �-p�B軠[��EQX�F�P|�&Q��TG�-s��MC_���Fm�'��[�Y&MS�TA��H����5x�}T܏���_�{��8��v�#r�ڡ�'��uF8�nw����1S�S;Hܡ&_P/���Y�SI��T���6E���$�1����ƛ��h3�o��q�������o%�W��۴���ƹc�7�Fg�tP�Ϙq�W��{�A+
-n������m�V
-�^��*;O��|�����!���1�����|P�?��xV���x­I]ˇ�~	.0��(c�lc����J&��ks�Y)��v�^�8$��9�.pC�|�W�yO��!<��V�Ou���q}��!,�Ս�V��]�2�CT��֖���(��3�Q��~4��
-�֩��"W�N���i�A����-a��na���؉�!��(퀄KJ���,w"ܧ��:L��xB�5���#�U/�6�nF~Qa ��QF]#5�Ӻ��mS�Â��x@P�e�}~�:��E�TA)�����Obv0B�]��twx1���	2�m��H���Q��IiϧERsh$�0<�v����Y������y�&��oq�]uD����*�1S�im��D��zM�Qj	"poL_#�'�c�
-�/���k�j�#pD���<��-�A�~d���J�TI��]h��E榿���ƻ�wu���5�+�W`�/,%Z1�P�W	�?��:�s�=�(bxp$��+Q��W��x�_5K�*�P�ٯ��!q�f���������k���ꁡ`�:��:���:��/;�������M��mp�P�W؏�DQ��~�l�	8����!�q	^yt��Ú�.��DsI�5Mb�b�#]�{x�
-m6JN��~���R���^�Dt8(�Ш�T;��l��71�z�G���W����]��2(o���z�T~+��Q�ݘ#�Z��5��V����
-��Z��MRw��<�k>����,��x�^�6/�έ��J�#F�s5����z��E�������c�9��	�7�gj�͢ӎ#��0����@*;�i�{�|�+Wv���/5 ����#���HګH(p���t_$9l�~�d��3>���\�����Y�G��U��*4(0�|H��C��L"he�;�����O��p����m���v�������h�MCK�ř]iM}�6�����۰�� E��ꂔyf�ɷgM��5�.�I��5��Z�NQ����� �a[����X��D��B���'m�Bh������WpoGp}@d1Cx���BD����$����8+�虮�DY�M{�̍���y;H���]�w�!X�����NӒh#�3h����X1ּq�S;�0.��`T�oK��Bl2<%:�N)wg_"�!/��_�Tބ��l�3�k���; 3���w\_�P��VE�IV��z�;�5���Q����]|��a�w����l���;�^�#,QX�xk�����>��~/����$�"����_�]���9<:/�w��[�ǵ�%��Ȳ!��p8 n,BJ�%;ٷd*������W!q���Z����t�����>Ǖ��ױTFx���O�v��څ].�������.�n����F�[X�5��&��\�+�K�}55�O�d��"��Pv�ju
-�vg@�-��� kX��U5X��v��n{�+Az�>W���<í���4m�]�jɛ�<U���u��rM�tK[%Ū�_u�މ�K���"M �W��q����ދ�b�Cor��&'i��$�{�.�h!4������4��庱�3+e{|2,��p�mVG���I�N��@�I	O�M��1<:���h���ݼ�f�&�Nl��?��tm��;�B�֧�L{�ysmM݇��H���ү�`���%�(�i��d�5I���m#�i�5�xX���#�� �щ�|��t�b<���z��]v3��O���G]�.�� `�3st����D�A=h.��*IW�49ԗ�"���j��[ ��+�S�<�Ì�6V$�$я*���n��5��(<�0�#uu��,��G��w�#��XŴ��x�M�D��\
-%�Cu~G���24'�%r�E��@!�g��|OEo�:,��Az��؏n#�h%����x�Z.h �ivE��K��ѥ%�#K�՜�B�I�X�9�aI&�/����D��I�xj��s����J�30 c�y���XA���ӰYO��L�x�v��'d'����_v�λȿ��ia���\��Y�\i\)���>� ��A4ߏ��4p�|���|��H<H��AU��/yR-�O���!��a>���/_���<�8�t p�A�RL��b_���2�G�G��߃�5���G��8�`?fa����]��͜� ���,d��W/�~W�
-�J�f����D��#&�3�-zC���K�O��<��e���X툰c�@�п>�'i3�1�EM�V!k��O7�~�`_�*4}3�L���r:\��g��Y54��G!�lB�ͽN����ꩊ_�HH���*m�0�-茆(7Z"I�~��!�԰o'�ޝBqo�r�6��zPU�W�^���ɼ�a��d
-��aO��fW? ,E!��76!���Q|r��jWd�M/�Q��>p_ѯp���++:��B������t��.�C6�w̐ts�`���P7sI��]J�R��.������>�?����,�Xh^�5eh�Ϋ���:i�:)D����n��bM��z�%�S��P��A��M�A��/q��.'_��C�kG�Qv���!<����|��%j���m���RdJ�e2�7A+��α�4��i�_��J܍ˡ�q���%㲴��:�q�T��sn�~��]�9�~�v
-S�]F=q�#gꀢ�c��RS�/���a�@G�,ҳh�ar���>�+~����aVٛ����oTi|�b�_��1P�'�U[[[�Ϫ���R��3|��}FM�Р������Mu�W@^5��2���bCt�+H���4��8�It_��w�k�qW�^�_`Azt���{L�A��ol�"��^���1�^Ąg��.24�v�5G� �-C�ӗʕp��jS]76�,��]�T�{���H��A��l�K��,�zI���b�.�9q�]x:��ҪZue�Gx�A���ap�nv"�qm�j�=��t"��t-�/��yD��ne;Q�������~{:S㽦�t�x#��Avfʡ~�u�*��wG؞��
-��,R==t����ĳ@�&�S��3� ��Z���H����td�뿩���]�0����PA�y�V�1ת�m#�j�ꗴ��p[�C��G���$�Z ��l�v�w�\[c��ܴF-m��V��zpPU���Uj«�z%,I�e� \a�����ŶL��ש��I�6s�F
-윦�͓]���jl��#۪�S�U��DBu}0Tt�����R���-B{vEzom��-|�k�K��.]9��^�����+��.눚�x&A)��N�h�)�VC[[ѯ.����խխ#*j�Z��_V�dsmYEگ�x��\�hgZ��R$m���B���"����C���oQ�l}j�O9�vF�n�b�ɧ#c�����p�ۦ�1�Ē�8HS[+x��M�>���5�8�.�����H�D�zQ�'��m�P|��*�=�R(�[�0aޓ�3}u�s\^�b*�~x����2:�a^hJ�Ok��iIWD*h��Y4�&̞(�^������!VCZs}�ѦCg9�3��+qI¤`�����֩�5��kh��R.��{�7��Ajmw�]Mv��u�`_p�����b��y��.0���eC6����b�W�}B�0���c���u4��@�D�b쉆1�9�:��c�@ɦnر_��{D=����~���w�'�쬻�Zߣ&�W�]_��Q)-���v8r�e�������J�6�vo�����;T�}�#�����Q���,Rt���˴WUS���^8R�dk�VS�����E�O��ڟ�ٔ�A����tk;�Z��\�8#pʭ��N�nm4�'T��蓪��: ���G��|�&�f�z]>8��b�.��N�����>��L|��~���U�L�7FX"ج�#�����7N�+��`et��ah�
-I�=��V�ǐ ��,�
-k8�r���Ӱ~` ծ����=h�Zī�UWV�eqK�l3�W{_��=s5��wbPcP��:�<6j��iH;�*�ӈ�nc_�tР���Lj�^�]O9$��:5�ڍ��,?�3�P��1f*�"Zx��qO�?|�j��Ka��r6`�M �C<��?)�)�����Ct���	�'6E q�`��X7G�V1vsD�m��$��^F�~]���[�JJs�*��~����x��~KٗyKe%�[*g�,%o*%��{N�=�Z��Y�O�U�T谸[�p��-INb�$��o��Jը{SX��[�d��WB��g=W�F(�i�{���-�9m�Va��`j�J1��;����~hZ?�|M�WU'�o���$ �C�����!�ȫ���~  y�œ��o? �(N��$ �F���IK�m3�S�֮ұ��q4���R��)D��Rx)��>��5�5����K�5s�f���zD��_�	�z���8?p�������t�g�$fl5��FW�#�+����j���@�!;C~��[�E<8kJc��ami,�>�����e`@������0A�Vu]1��X��	΄__j��l�`[5������!87$�=�D�U* ��芕L����f%�v�]
-$N\�*�k�2����&�v���b�D���Q�=t�M���BR�,�ι*~�A��\v�J�83+8g�\�s�&�q�Su.NU�sqt�����:<)�H�; �-�sD[s4����u�v�y:�k���9��8X�m���h�����3���!���{���p���u�#ǊF��U�!���9���1n$�\�@~�sA}���E���-8�%�N�ڡ�X�:�j�	�n��.�c�*gɏbó3�<П��>�I��]��¼ߡR�w�/����.����"��̊<3���lm�}�*_����_R�:P#c?&V{��zZ���d��R+4��Hv�vW(�JK-��b-������C�-o�j�*Qex���_���TU�^2�^��?ê�̴�&8�v�)f�1�oG���f������X�9��_-�췱ml������{P�������o�q���U�+%�;f7�(�fר�lO���ʴ^�dNG�ajK���6�i���HX��]�	.�h=��#TC��d��4:��X.K>��R{��(����;��]����v�\-�|�CF]���s쀖��*~�p�#�L9N!�1�h	_a�+��U�JVMxE��"�w/F����w�6�4�	*���M���
-<��C]|�CU��?�[ ķ�Ԯp쫚,I!�VX;�b{���Q)�h�d�6�_�:�8����Z�(��YT1vQώ_���
-���r�x`�-��a��&�[]�	u��*���������y�/>Bg�9�x���!馺����\:����{�^US�k&�H_��M��x��F)Ė�UV\Cz~[����&���_(Y�|��}Zf�ɟ�s��� �Z�}Z�C3�G?��S?������XC�ܝ��5ҼsG�*}��8�m��WQ�^��y��P��6�Yl��t�'��p���ߡ`TY�c���w���k�J����vK�U��13{��Zj����z-�As4)�Ln�.����q��>U� �4��`���}t��~¼J�	K{�o�#��E�c2�Y���G����!7}��p�~�x���&{��ܬ%6k!~v �1R���iP98�͐�_�:lf>1[z���S�zY����ħlU��������i��sZ�g���^��y��^�zN�O�j�����ZҤ�wF����I�&6�4��j��y<�MZKv���_� �0��V��uU�	�/8a�w<���g|�$� ~&m��Ɇ�t?ϗ$��P%>Q�EA�E$l�Y�<�ubC{FluҞ_]3�-�I�x��K�i��+��Y�)����7�\3<
-�r����I��ld3 ۇ�ڟ�`/�/̂x}hi�KE���p訙�"�{���t�R��Z��A�����{�*=����ñd��!�����E�����9��Ϗ*�����it���kT�&;����t[!��g��nC#�!'s	�����x:��M�C���N��v��>Re���]*��ئ�o{G
-��u��A�����˜�~j���Z-�vb��,���x���H��,��/�Ǌ�O��~��d��\��l�ee�/���ģ�;�i�NE������&�Z�j�E���µ�gpx�gsx6�gqx����L�%%-�`��sF��W.�͟�٧y93t���-%:��^�~���D�i��b����\^���B�T�|�����)na(w^n��',�k�
-�Z���V�N��I�W�S��Sf(w��u��`Ϙ-�Y�6o�ppt��R���;Z�e�;�������9gZ����ڤ$���N�N���6[Uj�A���g�Z]]���a
-���o����҄A��6�
-0�����g߲Y�y�[�L��.���[Z�2�������bߚL#�hfB�g5�6"�x󀉯xT4���THMW��۲�{�"-m��I\�a���v�ʪD��lD���8-�͕�ʴ��ہ�t�=�C���%�8�-4��O���&�ûQKl԰~�g��t��D��Kx�E�U���9��ձ/h�1�K%�������?��8�_��/��X��g�=�[Z|b}HfOXߘ��fk��&���FG]�nύF+0c�}Z���!p�Ԓ8�Jn�p�ge|3/����%=�C�R���p$	uG5Fd��|��)�Q��yi��6��C��н�!�:���h�5˻Z�SzE����3��+�ub_���q�3�R�:c'84`vv���gGxmއ'��������bg���w�s�`S[h$��%?z���}�����++����E[8^.x�;8
-��֘]L	��Ӵ�k�B�*��j��L��--[�1�m*�#*�](�CcS�~NH�k�z@���G
-�C��P"���*�g�"�J��������gl2͘�B36:t�I�Z��k2�����JK�Y|���"c����i�����(+sL�Gpy0!�%�b�8{/�{X2P���g �n��b��n�3���7n)�=x��(
-mS�ϣE��<����J���tTvq:*{q��Q���i���?�ap�p�W]��^E���qB���z��$)���W�`�=ښ"��]I�9�d9	
-S�����;�^��5S�q����	�;����=;5��;�X�@׀�<�"���I����)U�jk���r{F}�����wV}��ʞ]��M4��(���_i�]�}?A\q��[��j����	5�n�(�Rl���;,7�Ǟ�1�=C~s�3^cW�����+��Ϊ5TC��6��p�hG��Fn���S���h�v �Mj�>��n�u��b���Z)���;)��~�)5�@����;m,m*%���g.�<+ �OT_s=���W�x� �ߨ�R[7�=HR�h��5�9��N�z����i{]���dG����|f��#5/�F1MA­_��|(�P��>�<T_�y����on")+�\O2U>6+�]�%?�k��k��x�KdWS�/m�j���V�p�c}��\�>"y���	���;�4f���.�9-"�uޙ���5D�?��P�'��ho���!-���&�@?��P��	�} }�M�$�CZb� 4I�)�
-��5"tA��j�ZS�k�+M��%q�-�H���)On�)4���B-�/bH!T�k���2B&���JMm��C�u����jy+�'+8��쪭���D��ˊ���V*�)�O/�������G��gh��T�M~�B��D���;ɻ�If�*3��FU�o��^2�������2Ϣ�lf��������I ��E�p�)g��7�-·�҈�����1��dׄ�#$TMg�yxт�)Q�g�w��/���d�j
-!��7^sc#��N�m��ow}�z��^L��;�NZJU{��읕�r��]i?�iO�"=��<���t��e���^�r�N����w����6�G��@���E�I���>4�u\j�:.2E����rl�m}c�(�]�v�"l��z4�_
-��As�h>Z��c��lh���4�xP�6�,�+�d�k?�Ĳ�)�9�4�3���^C��a���>�{=K'�~�~�J7��c^������Kt�D����Ë�;�dp�/k�~�/txw�?�5���a�~����I��-�K����_��W��F��&>�7�����G/5��^dR�����}|bp/o�G����[)��`�b�Um_bU����3�+�q}j0�W4fO �U\W����a���K�c��C��L9�k�yec�$�\@s� ��L����m�w;���a����A��?W���ѿ�1{
-�@�EM#�'�L�;i�~���{��D�M{'E�o��`7%���7(r��f}��΃�ol�?�K��l
-��ܴ��2����۽X=}�Џ�[|��*�R����mO��;��w)��~��^g�O��Ǖ���>��o�}�`�5�8������'b�~Z��Y}��$�s }��K���8J)��Ǹ�W�w�}\��?'t��O�&W�������߈}�+��S�!�*�[�t���P��L�!{մ'4�3��Ć|�nOj ��ې��v{�h2�G�S�7U�S9e�L���T��=��j�Yhn6%�"قJT�T}S�M�4s���� s)������ ��6����{�=��Ha�0t�l��������!�tC9��4�N�n̞�{� ���qa7�ٍ� ��Ԣ�_dQ�2��ʑ�<�k�g�� �[�����a�u.��sl���rl�Ɩܳ�vG ������a�,\
-��E�|m4w���k0��i̞��h���z�G��h/h@xaV��G9�1����%]��M�E�^��xs�N�T'�\��o��|y'����nc�kt��dџ�=à�{)4{/�fq4{����fSc���O�Z����������[<)�ykB���v�ok�䷇�������ؿ5�{˱�7��5f�����#]�g�2&�ǁ����֥F�����;C��^9����������� �jW���"��0l4�ؾ�!���6c{͟��G��������c��.�=3��py�+c3�a�>0cW�;8\�Gfl�:L�!3��p��������t�r���χ˛T�.�M4b]fl�{ɈM1b_���Fl���iF�I3�Ɍm6cF�݈=h��:Fl�몋�gľ���k�"V�.F�2ϸ�j�kv��s��b扆ē������r
-98�B�m��B>
-P�!�j�X���V0e�e<e�e�e������`���9���?c�c@�)F|U��9�4E����E�>�GG/գ���gC���}9�G?h�N@��zt4p���ǆ��إ�=vl���W���mKcv"�=��$���&�|��l�>���w�o�-�N}�v�)U�z�l���L�%������S�tq�v�.n҆���!�x���gw��1;	]<��9��Bo^��F ��0H�Լ�ȼ��oʑ�v0��5f���H0ҷ�I�$&b3M��*{K�����2����3G�����_G/s��2�o.!��f�>��	zY'��x}c�}����x��N���,�����0��KM̉�L̽��HO.Gz�`�G6f'����BQt�({w��7�!z��y;.4�]l���7���}���a�x�R}<u�>N��3��8spoh�NAg�8[ǦК�����N��ȿՀ����ҽ����o�Μ�Tg�^�3���̜���?�3���Ttfn�3�����/��;@��a�>w)��]�yC �`9�����1;H� ��^:D����ח���`���>R������1;�.�u������Z:�G�l�B͞�|�H�5U_��;ٙz�������z>�fg��Gu�ګϏJ�Z3uk�n�֭Y��Z�:��z���M�Y�ܩ{��:�ֺJ͍bc&j���urEZ-~�N!�~C����U���-�je(ԭ+����ϟ�
-Stk��^���c��&��������,E�/$�at`~Q2]�_�}��J����� ��~5P'c�5\\�ӛ(*k/)��i���	���Pt�bTc���\3젡x\�eM�=��kȓ�	H�Q�y��'P�����+�1�����Z>ɕ~'8���35ف�T.;W���-=��kz���k����V�.@/Vаj8z`9� #�W�~��̡���p~�81�]lƔ����O�l�u<����V�n%Q��Ü���_�>i�>m��?���O����;g��w�L��ZZ5�.��.��cL�ݠ�Nt�i�|��sw��1�(r�j��*%����k��M^���Q6m�\�'D)��]�N���ɟtR=��L�'E)�]�kj5�Z�yv1a�����OW�����_WC�L�Y���A���*��A��]ğ�}E����I�i-ğ�q��B0��K}Q�"����"�`�z[It�M>�[��a�7��J�kyZSO�E�;k�����iӓ��X�F�Z��)�\�ĉ�t�u��ߨ���ක����l�6��}�G����*,�ꢱ�i���G�^,��R(M�U�����T���w�n/�����^������kŏ5H�﵅�o�&|C��7�9&S��>&aI��R�_5H��%�	�d�z�z��J�'{t��ߣ?�H�>�أ�I���'{t��Bx�v���'s�Ȟ3R[j�̖����YJ;kd��S:edO��:od�����afg��=���=Z�@fR���	�;adO�{	�^3{���J��fv����r�1�����6��N4S�)4��N6S�������	
-�hȞhH���Ɇ�Ɇ@��șٜ�:E�����_�W�i^S���_�Jm�X�b&W�J���go��M������~��UMw�U��'/���6%�X��M�Gc�k�����h,W�����S:=4�6����
-��(M�w�����;q@}�c��ό&��m�P�̗�:BQ���ƶ��-Nf�����K���������w���=�i���epn�\��I#���A*d���+���F�ʵiN���
-7��m��Q����=�z<��M�������>�;�
-�*)�jX�#����3�̷��Hk�xސ� �k�������橃�NWdCt!tbs���0>!�8�]&�~��q:��\���Q�T8�:��Պ���J����_�E��Ň��<{��z��-m�A;�$��RuP�B[�7�aW�S����Ήa�t�y����t������4Z���
-D�����x0����&��F�$�1="�(�;��lZ�I�BI�HE1���ҝ�����N�#�U����������r�(``��}���]��W���Կ��a<�
-ƿ4cن���-tc�q쏎E"�.�n)�D���C���L���A���dA{&zVp;֏Ut�A��+Q���j]��U޹��L�B�$�.�i�,A�U�v����3�_�|�����1�6��C-��%)��h��7G��`@Z^褿0�t?X�==n������?d�Vl�.M�͑�O��'�A]�Fw�<]�>�.��fg��
-5����V�>B����ֻ�A�ix�](.�z�@�~�]���q�i��i�#� �DΪ�.��k����ʏ^ЭS�R��� ã�e¹��.��H1�wSp1W��0���p�.��3���.S�����j��U�/{P��M͎Ʀ�fg�x9w!���Y�]��k�g���w�Sf�n�������~�'�dN��?i��N��(���!����=�Mw�,{%�����0�<z����0N�_����[�c�^]���I2�ϗTN!_������E�/^Y�̬��ꢪQ�i��f�F]wvܝݝ���)�y����0�VmV�N�ڽz��u�~{������ʫ}"�<|�
-�|�"� �*�TAA��������n�ٻ�~teD�8q�ĉ�s&'������]�k����ۨ�FI��|����+ߡ�gk�;˳��,-=��<������b���R~��B6�sȰ�����8�vR_
-��� m���#��r�vp��lg~6�:���֊�������砆��!��B���c�l�V.�u�!}uhܥ���e[��Z��_�.��B�m����l�&�?l)�������e{�q�Xdܭ�~�E�t����T�[�4�� <ٽS+-��C����b���n���� �:�% z�4@/���j7P�^���Kn� z�h�ָ����:�����@��-�z7�b �Z�@�@ hc� zM��PkQ�j��F��b��78{X�f��ߔ����lH�N��lrCg��%�f�Z�	y�y�7-i߉}94�G�]/�S���{���R��){�h<����~(uf`���Hi^��6;6���~��1��o������W���X�Cb��_�����+�ף"UY�z�RE3�A�6��鯄�5!}}h\��:����h�kjO��c�>�Q�|-t���ZH��_��z���՜�1��*B�卤	�))%�/��2K�$3�"R��g�dR��v�Y�6�g�,ﴯ�,Ul��Ε�67#���15�"�e��h�֏����n��LKy��S2)����4��k����]���н��C�<&���5O[�/�и6�y�w�[��WR��pR-�2v�l��­�ǖ+@�����I^�����܋��>!�>e����m���U�Q��*���H�L\-YZ�g61�6���G���C�������k<�EZ~�v���T�?�ߧ���/��k8����	�}�	Y*,�3e�0�[�+�|��o�������s���г�kczK�k�h�$\�WFˏN�S�|T�F��_�%u����W�s��eF�Ҍdif�s,V���O����Ou�	6oc��B�y��Oi&e��_�ݒ�pD����*U��{��C���4�){{�M������k�k��� ~��>$���b�R��������K�a�1󛼿�F$�p!)sG�������_�.q~'�.G0s�$J���JHagy��YIQ��d�F�J�a�X����&W��J��K�R�.��~���yCc���?pk��V���d���tg�$%Qaf��q�Zo+�*��&y�VM����<��ʮ�'p��Τ'x��$�ޝ���=I�W�ܛ���c�O�n��V�����.�ٯa��S����#y����d�� ���Q<��>/��#����a�6Ir\���<V�!���yp�fa{�����{P3�۳j���r�vر'�`;�ؓu�v��rP�N��-~���ˠ���_�h���K4j	��}In�0���l �ш^Z�a�;�l�L�K�y�]��j��U<���gмkF���YE���IY�CF�t�M�	���a�h�´��H�H��ONcg��������K$�� ����QX�ԾFe��O��S�M�Z����kHM:P�2�D��r�J�3�N�+BR�2�D���8���mw��"�c����s�W�]8����\]��"��D����L��~B�Dɷı��m���̭I�=��[6�a�y��o��`��Z�,�HB�U�'�2I^�
-�)%��ħ4�3�c����
-�}?���ol�L"m�o� �X�Ѫx� -���al^��*��h�6�!j�^��ѕ²"f�({`�/!N8�MB��zI�7f����[c��>w���D"���FX�me��E�,L�{���M�=<Xqcm*Uc�ebԌ��^�%ր�{d�΂�1�y�no?R����Wc�Q	�!����*YZ�,-N
-��	K�n (O�4�Q��6}�X�4ի7O�lƩA\��pu{����8;#|���&�G���üƟ}��e~�5��.֠,t*�8�	[t�N-*�_�<�O�'�i�1���&����ʽX�hXi���vii_XJY���w'��AQ�=5�T)-Iv$�����1EUd�6hU����P��^���
-5�>��&��+!��!��C0��@��a�f��=_C��f�G��4"bV�Q�-1�4��� f�l^'v���8��&1`��
-~���S��_\+��˸�P�h`���^	��
-eA &�W�JT'��@�0� �y7K&��'}QM�D_�7dLz�Ǝ�Z�%�x̪~�S��*�����kP�^��4E~�V-��̉o��.�6Rh`�wBU�ђq�5I��=��d�힎ɞ�@M������ݯe��<����'������NV�$S���!H�P��}�&�_�C��.nf�aK���M�-v7Wr�L�Tz(ٞh���>AJ+��$h�X����kG�2Q�OG���-�Ÿ�q���@m�[1kY�%~�1.Z)Zt9�ȯ[���j�B�l������KZ����o�B��i���@��Bmr?�ѕj��ɽ�c/�yc�`7J�MJ�
-x�R�@�Y��٧�T�;�B�E��"�e���O�e�=b-�~�R~з*X�%��H�_ �NW���m���6��Zn$�Y��,#����QMo��|�Egp��i�*��f5|~�c�B�T�����:�� ��z@����m8Qپ h5�U�yJ ��7���}����b�a���gw��o��w��z9�nw�����VFvo]��q�)u���� ~�ꡟ��w����JS�����Z~~7h�W�܅�.�^��봎�:-��~6��8ݱ��m�� M�b# :	�q,���b���Y5�yK�=�p��M��%�kZ����kZ�u-�bc�u�{@�D���b�>����0�z()������֗'�I}cP<�?��W&�'��+�]!���j����������#�]��Ê�R_�ػ�O'[���|>�����N�3����7pl��SzCK�&��@�^R��~�CP�ˊ�WzY�1����q��YJ��}XU�}���{�k��S|��=�.���WC��Q�����%�|�[��2V������3�gF�k�ZwT��N�`u�
-�o�v����d˲A\�ұPuA]%��}"�A�Ezl���~0Tڤ	/�e�í�	l�ߺ,�o��F��(	Uƭۿ�U+1�����1����8e�WO뼚V P5� ��'<*�؇�&ٴk}R+E�S=�wx�9�����|��*wtݾ�[Zz}c�--_��o4�+Z��ү5�M-�EKoh,o������f-_�қ�Up�e�V�z��F[Q�-�����q�� �^S샆�k��kb��P��y��կWK���^-�UK��Xު���toc�_��i�jc�O�o����۵�6-��Xކ�����`�[��a�=�ۙ��v��Ilg>A��JP�ME�CT��!W폄��!��36�
-)��B��R����<YX����$��69C���!{5��!�v��Y��j��������_�8��X:���:��/&W�^����Z%�C�%�Kh�������p���'ŀ��]i-oK/''�*>��4NKb��Q�R��'�-T
-���ֿ����-TS�|��l���t	���%
-�S�W�(��a3ݓȬ�U�U��ɉ�B��T�Dv����� [��br>i�e�&���I|����ugN�$���㭒��'Fi��
-+7��]��.bݤ�e~�Ej��%Q�P"�}&!��JU����Og�7�:�����8Iϣu-�΁�VI]��;�iu�������W��zMK��F�ƭ��9>��G�k���'����.-����K���5�?������n-�OK�Xާ�?��_6�?���i�]�����-����G���'����Z�@c�C-���������߫�6��j��Z�xcy?X����ۜʯ�*�����vJQ�u���֦�?��	K8R{��*���U�{BXa}�W3F��΢���
-���8�X�,g�w��4�{������y��̣`�X���� ߧM����aw�`?a��N����n
-4�;d�|�5pflװ�bl:ئ�^�F��O#l��i>:3ҏjH?`������c�dB:م��3#}��� #�f�=5���S�������R��F�����������h����I9	G6H�(��??�p͖�S��rX��`N�}E��L+��3r�Lȱ�ՙ~��8:3��C|E��b�gB��`���/ca�2)5���У/@���ޞ��E��r7��-��ޞ6�"�����.�pi�TH8{5)��/����Ǌ�s7�Q|��T�M�o�3oH�d?�=�|�a���4\#qg�ҡջ�z�	�	�t��=��Z�nV|�D(��D���w�}�S>����R���4>W��`���%
-����D�=�X�(�����!��cn��B�����������T��(�v��~�n����Z�PzJ�p���(J�q��1�kH�B��=h��~7����2W���l���uE���(Ǫ-�7$��2;':�J���r2D1\ɓ!��IA����
-�$}<Ε��'�����+I�������߃���WT��J�r*yR������ĕĎ>i���\ɶ3N��������*V:�ߓ��S���(�v*��Z"vf�6��d�M��xp�ׂ��L���' lZ P$#�M���|F�	%�G���SR�$�(R��f\o#B�Ǟ'�@��O�*�0Lo��P��\wS��G@�g��6F��)�O)�3C3���!H�[ !9a��!�*-B�#�֋����'9�I;?Ƭ����$��3(>�P��@�@��c58���7�v'xoy�F��b`�Y�#�,�.Q���`�Ԝ@�f+�zY�kU�Э2	E
-o)Q!�e6�<ۉ�eA�QB��k?a��a����L�v���H��p��r�~�\����I��\פ?$�ҩP�D=|*�;w:�)�<��'�$z=��t��/a�����
-���1FO����y���3��a���clu����)ļ�:�{,�ԝ07$HLW���	L�q
-�yX�lαD�e�n\��*�H ;@{�j�Q((x�����}k�@�P��(�<��o��@� ���f��bIIK�?4�CN�q@������?���J&�QG�|ٯJ�� �3�øJ���ȯCH�Yn�㿛e���JU*�=�c�y*��-�T��@v 1t�K��j�'~oB��	�k�<��P=����0�8��S�0�����:���ǄK�*�.�p�T�T�n_���{�ItpE�9͢F}y��FTtE�KF��c���^}1 �-2����v���<��T�����l<\�)c�a9�#�d{����? V�`'3����X�a��Dh�8�Z"3�̐�������$�BW�aN������޳`�/���Kd�<ݘ�t�*$^iҗ��$|�i��C�%K�'��B@t{۳o$�\ĤմI+�qog����3o&%��=M���q|����a�<E>�B���8����K��҇%D.��a��)���z���'K���h8�s3e�p�P�ڤq3eoy�L�z��)�/-ph8U��_�����vqVU�)2�."u uR���rW�vk6C.}i��ś�KP��X�,lNR��py�&�p��͗��|f�i�op9@��q��9R�=G��wO��ʲ�⭤���&nS~����O�NiUp;z�X�z��*�c�"�f����B�o�����������j��$��g�c+�q�b�2��t�PZ�!�0_h�r~��6P�)�_��=P~1�Ǹ42"��I��Zs�!3��2ow��j��Y�����ϻe|'�$�g���e,fS7F�V�����82�}�)�nٱ���b��n�?G�=�T�F�?��[���8(;w8��k5}	���$w���z
-�=����F�d5�nt�j���6z��F������<'v�+�X�@�:��{	t��p1�|����ˆ�}PK�j,��i���gZ������a�c�Z�r�j��Z�'�R~
-%,P�<��\KO�ʟk�#Zz�V>��k���a �V�r xA�S(�u>+c��{����G��@�8�ݯ��ge�Y_%�{Z��{�jo��նi��(�4�,R�c���7|���~�Ṗ�s@��jS<���_�[����#y�j?/[�$W­����ɏ�C�1�j����QT≡DZ'�H�H+�H� �J�Hk]DZ'��elr�"�2"=�i[�H:i-�<�D�;/�BKߪ����_j�U������yơ�v�6�����J�鳪u�*�G7 �9& 7Ȗ����x�H��Hq�c���d��+I��zA�e�f�n[~7Y5+�!�V�`G��åﬥ�4\�{����K�UK_3\�����܀���- �%�Þ�W�K��������1Z�/��Xoo������bK�5t�kC��1F����9%����,���R~��t��[��LC�w�7��E�>����W젾���گ���fy�lu ��8�*.n����If�wI����g��MS�~�]>�-�F���㟝1k;�v�vn�����3�r�W����l�`�������r�|�2����攱elw����lC�v z���;m��r���{�U޻6�v8�L��ͳa[�¶��V������a(��ꗉT&j�2p��AZ����`��ȸD��P��,js��6�U�O<�����r�u�yK鐗]���h���2k$����;�}� %������yo=#�4�m4i���oSS�������>A����{�8���{V��o�����rW�>u��ll�X����ٰ�pa���6��3o�aH��[��*��oy��,�g��v��DU?w�����]f�wI���<[�q�q�)�]�q�)������e씩0��:K�����)c����׻_�"l�,��ٕ�� �>\��c� �>��5h�th=��_9|�������v�KN8��o�{e�uCy�,��k{f�w�}�T�S~7�k7P�Vk�8T�n}w��I�k)����tRx��59\7�n��;���O{G�Ѹ�yE12��0����#S|n���'{&�s��3�	��9�n�0��_g��k�P\�#��M�|C^S��w�X��&�c7>���?��<�EJ���/0#)H��0��<�ōG덮�y>u�9���y����lЈ�oP�i"��0olF���vXĢ2�	����؈A
-Z���:=�; r�,M(����ޏ�Y5���:�i��pw��>�Y�ųp��e֔p�@�%�tQ66�]l]LP`�(�?�����ő���.�+���*��:��_�t���XT�3,wk�jz���},g>����'r�|)�-�����#H˺pI�ZZ���#�E�������>w�}�\U>@�(w��D����5T�������	�vʍ��0��#��Zz�����h��~q=3q��;�mץ��'������H�9~�EH��ϒFs�?4b�>2N�����}��+z��O	�=�Y�r��r(i���4,��AXε�0��K�'�<֥�T�s�`��H�9��&��8pP�c#e�c����ȷ�"L�y~�9�=������#�Z_�`D���< ��#�C^h)"Ai��Q�P!�h5J�5j���]��X�!� y��W�Ki���b\��� j���r��ވ�)�֎0F�;���*�ch{H",��&�g�~ܮ~�#D�r(x$�ĵ��A��X"�d=��7���6a�2���h�к��j͒�M1^�O#b�!s��#��/�L��M�8��85M<31�i.���H0�15b`�5l�Ų��6��ڛ�x)�8��Y@���n�=���m�r��jqX�2�C��EYsM�i���u����A��Mt�:��a���'�'N�5��6%H�_k����&�m�!�-n���6��	~N��a[g��'�%����3|�	~:O�)�b���{
-Ǳx�-L*Ap4�<���ʄ^��P�c��8?C�L��3�x��F��xʇ��q���_�����W�23���$<��'7b.�3+M=TX�*�Ui��w*�hF`��ɻ�L8�o���C.P�27$~��e������o��`��J{����m��3���o��@�]�PeZ1�v�qG��b��s�\�[;7�E�RjH{��3f�I�#9����Z4�S��Ӑ?wP6Bك�d�gA��#���z�����t?�~����cI%V�4���ʕ�����&B��#UjH��t��4w�zA��Oʭ�r�k9���H�(Y�Q��gT������n�-�䎰?��o
-�AZ?�Ve҆i�܅A# ��Q8�$$L��N���lOgbj�+�5��3F�I�sh�o�����揑&��r|N���œӑ~t�	�	� �mAj����j=�Uw��A��j8t:�\�]��su���^��6f@�K����z�e�����#�S_.M�\.Y/���d���IEĝU"��!�t��C��J5�)��{�BZ"�N����1������$�,
-�ݗ+b""��(���j�D�fǋF�5j���)��11��yф�#��!~{	� ��j���bY1W��}�0!���+KL�!@:'g,�;�A�̎��Ds�e#l4�2�e����-���fG4��Q���ԷNܺ�Ժ��u�h�a�u��)���G��q�t�;��k���:�ݺ����+���w7ɰl�&n����ib����8���_���<�]1����֩X�\8�8jt�mt�����bGGqtG�,�t/�(�;���(^�Ҫœ�A�#8(WBz�Ƽ`$��<(�0��U��i�$j^�t�2���p7�o�~��o#�R�/��L���[�7N��鷩�xN��ֳ����vM,�g��f��&ha�7'����ʄ��y��I���nN�F��X�0���h���&H����]�SF�b?��сK��;cJ�zqlF�H�<��m���CT�Ŭ4��|���p�k4
-�&�8Lk�Q�����&�D]��e`�J���^9�&�&��k�̫q�|���1r܃Q�G5�����z��a`4:D�s�u�P��o�����ޚX���H�����	c�#������	��~��N���@��$-�̅���L68K�V���d��G�ӂP�CL^�0Z�,_�n�g�I3�4w?_l����w�e4���0S, Sl������Cɸ��B3.�����a��VuF��"&�bV��~J�[�q��ˉ).���Ѩ5.���@���A#&���\���W�63��ab��|�&>�%�0M�1����F�Y]�����.0Z���u��T��*��c��7b���$~K:�����>�� \��Y��C�%ۋ�
-~㝃dM�æA#�����2F��"w�3��⻌�]����_�g�s!O�a����Mas��#힬��C4�B=�le��nÂ�؈��^-=�DkzB�̈#���ӆ�݆1E���6���V*N��k���6h܆V���|��S2��6\@�C8��lʾ�T-��v�R��5�Ҟmi͔�\5RF3����8ƈn3�: �!"6�F�2D���X���. ��G⮤�.�Lk�$6���4h�
-��%<%��\���/������<������ň~Rfk�'屴��%�����..ы+����;�x�
-^�`������Wk�*BsH8��N־O%�3��b�o� �O�\e�9̰���� ���9##R�y=
-U¬i�iR2�I"����M1<���Cj�E�"�ǠE�Mj�R���p䗖i�]cb��1��c�7B�$���&㥔��δb'�na��h�!t��ș�R��@��ٳ���[��YZ0}����,�ւO�҂�õ`ư-�T�.D?�!��_��UH�ƯJ�g��8
-d����J��d�����Ku�U��#;�H�!��2鏎<�������"����*���Qp�Ĝ��O��gb˚x�9#Hr�3�k%�2��0�<�����e��9�Ѯ1˶4���?B����7����q֯I���խ4L1�*��v9����2v�2��l "��ZuN��MX#��(%H�4��B��$J�6 �T���kB?#��B�
-dE�vy[� l��p���h|�*C�Ί/P�/��0����/xV|�:|� �1��Y���E|!�w�0�ϊO������ߤa�)gŧ���|
-��j���e�e=�Y,�Xی��$���yړb�õV���&���9n�fAj��&.`���,�h�f�_#>�x���
-�ۋ	Ƶl��(a&�I��d��5�� �;��S�B�k�F|���;��&���,̠��Y�d��KSi��5�2��!W�,��۔�����&nW�Ȧ�H�vD�,�j���T���d&Xir
-v�ۋ߀wԏRP�>��7x�d̡PG�~1���_��#���9��>��V�`����-��,�t�Yi-�Q�'X���/#�nә�e:�.@�
-w2�M�s~F�с��r���\���8�?�J�:��~�0�(��ǥ@���\��L��4����"PK�����w+N�6��Y]�\��f�c�.mF�?c�ԥٌ.����&h����y�����+�4Z
-_&��4��#�MQg�����������Em4��b��$)q������ؿ�NJL+����c���j��?�S`��dm�:A8l���uR๡ns�2R�o��FL��>��N�za�Rl�D�P:&�"U?l4��ڏ�z� �Bgn�]�׻xe�Z�	>�o��p��(}�t���*�b���~i�B1hv[U�K#��H1t�{<�oR�7�$6�u���1����1Ŧ��
-���aɁ�#�h��{vw�0����6k(�(��`1k�M��G��}ߡ�H|�>�i��l�Y_��n;�7��ܴ��#_� hb5�aQ�Q�
-�5�>�X�R��ewȒ��+�S$�HI;%{AdZ
-X�p�����Grg�(�
-���<\V�gPA�0��\OF�^h
-V7�뻙��e��d-�g�é�X���vi6��n�<�X�MW�c�eI�/���ͺ�͍������"8��(�X�(z#Z:�u���{�D�G�5J�CFI�5J�ۆ�FIe�(�d�k?*JR�`�7JH!��N�v���(9n��_�)&�(G�$A����\�p��k�d~$��`󆂍c�9u`s���b���`���F�4�x)��{�`�ԗ1�����%�Gs�\1�b��-p�Y�����]g2���d10c�/П�>��aĲ[�k=�l$h�s�L�A&��i�Yg���?��7��^X�[�k(�kNy�X{��]q��M�Xs��k��X����o^��6�X;�54�ޤ��pLl~mf��Gf]a4�7��V�(]l0I����7I�B0�M�i�6��?!Q�ɒ���2�F�	��ѳ]�Jղ�R�a>�O �U1�ڏ�Px��A�;��^��`��G��zD�#a��ω��f�/RC����||���A��$m˖��p��pO�X�W�	`"��W��<U�DbN�~������B���"]�b�~Z	&޸S�`�Q��2���� ��,����t����1o3�t;i9�$1C��E ��n#I�]�0�3�w���ۭ!���I���.�A���qM��LabU4�b�{&� BD����P�0����s8&���ޅ��t�ōs��N+���ty�I��L���g�ͤ��L��Ƥˇ0�r�.���L��tS=�.w1��L�|(��0�m¤ˇc��^Z�:L:g&U\L�&�k&�]L*&�Scһ����&�Y/�b�03�`&��9�b�̓$c���<���A���RՁ`F�j32���0<�w\�g��VT��~���e��>&g�$Z���� ���\���E�lǋ���%���{���O����&�q��L}J*�1�~-�Co�h<�-;ƈ|=�C)35%u����=a\�n�rY�xkcp�M#XMd�Q���-��(���d����q��/��kض�3�+L˜��&aPCܮ� ��HX�����b�fs������7�~΄��[���Ώg�>n���q�L�Q�����Z�B���7R���6�o����d]eu��^(����'-r%-�OZ�7�~*)�M�ji)*禥�5���R�y�f+p]K9���
-\�R�E�V+��ZʿģC�E8�!'�9�>����U^�l�l���[;�E�L>���E��� q�ֽX��d��T-U܍���V�]j�.�K��l�F�/��D�֍���%�Q:�4�q�g`bz�;�x������+9dy4{&�al�ڬ���+�2��u-�*6�-���q`e!3Y	z=8�/���H���������/K���'��㴯����{�~$?�b�����[z_im��_�~�*�@To���#����������1 �J~@���b9�ޔ�l�#��<������G��n�,�V�
-鵽J~��{J���)��=Rz���f(���c�4���(��~뫔춘�
-Wc�g�0L���ûb�>'\����Vƿɞ�܁��9@��M�;�m�����𓝙�7�w
-��Jn'Z��S��;vM����+ݞ*ݑ*�J�?�����Ʒ>;U����[xiVJ�:?̴����Ҽ���]��J�ǝ���b����qle�ڠw��W��ޕ�7�"�
-w���ݴ�'���a=B\)}-���2��ޔG��羔�?�3?���?��zU�Y����
-%��0��4�u��駼R�L��4�*ց�hQl"���R�l�.U �w0�°l|�r6����Z�Zx3���j�L�(Mߦ>8����#JGaAJO���P��R)Q����GU*�3�Ni�Pڋa���!��!���� ��A|�5�n@�u v�n@�s 6��g_ە�v�C�͆aN�*�$�z�^�q-�M���U���T�'�hH��p��0�)�	��5�OA�7c�g❣zs�3�K���H��.Ly�U��\E�7��sz쾚�ų',��������bRfQJb�����\3d��J�m��W�'�Y�s�*���7+D���1Tu|MC��.{O���Q0�N	֦?}Q7��M��)����}��Z�;^ s�/⾰�r@�wh�T0���D��K^��כ�m��󀂣����4�MylVڳ�Sʛ\�q�Q�an	�C0�uXa���5�=p{�Q�'�kv�/)-I�)mX�	Xq�����J�����J�/8q�_����X����nTVDEPuٷ�^Q��poL�f�W[X� ��R_LK$�3ahq���E��J�ϕ�ܔ�j��$�������[a�Y�L�y�)5ɦ�_�S
-���JN�j�+̭B7��d�ƼUD��jD���i%����zJ�D��L��D��wj�f�(,M���S$��i4~Mh��u.���IV����vapϫ�H��S�-"N_�Z	���X���B_ϟ�g4m�ː��:V
-_s�;�EM�2�Fy*,�J�؈����J��� �PD�V��)*�-n��oI������#�¶�*���������+��/Hb���R�ٷ)w	��88����k��˜{ײ_V$��JX���e�(T���X�33�6�;V�,i�ƚ��b?$�V��1h&Ns�b��F^T`E��	����f�s��"�@�YI�(n��~��y,I�n��/)�m�@\.=���߀�\��{��e�I8w}�2�DJi�9Exv�*��)���>b����矁���b�$�1���)\���8�����=��R|M$!�91�ص.��,vV�?c#c_ފ9��)�S�.g�OK!�����b���Ҿ����O�(ʢ!���"C_��(�+H3&J��B�%�@��Y���
-/�m��D����7�~rH�&�F��=��s��ؽ��Y��#ib�n��YE�(J��(��ӯ���:�0��s`�����	Z��T����m������k���Ә����|���C\�b��!/�3�o��{��#�.�P4�/��\$M���>N����iu�v����~Vc"��3b����!/���%��$�I�a�G�<�Xl�v���0�侓~R�){w��a���	�!)�@�n�l�����o��Z�n��d��S�s!�8?'�e��$G^
-���In�G	M��2e�GO��͜T��B��'qq�G����=�k=V���&��9��8�?�ϯ8�IB�	��+�pu�U�$�Fp���6\�d��/X�t�?p�:�C�c��#��.�����|�]z�w����>��(c� 㣕n>�l��F	������}ˋY�f߽�>|��Ly���<��d暀�iZ�\�yF,=V�<�fϳ��z�ÓJ��X�A��]/K7�c��
-m�DlU�V-%�ZY��)��Fw������4�~�آ]8*��Q3�0-�	�R--�&8�w�������ߌah�%��z��p7�!@��D��X��?''�T�`)6Y�΋��<�"���R�X0	"���^�f'���;/<�`تE1`�Pj��D$��5�0�V��Ӵ<���V$q�'y*]V�X�q��������z���@|?��)Tޤ�Ӻ�)Z�DqR]�X(0�Ec�!��|���j���� �j4�lQ���b��o�����.-�N�۶�(%�졯��r��LP]�н_�<�(���rC/��b�F��SZ�i^T��%n��wIe;h�E�n5oeR�BɬQ����+� ;zP��|�yU��r�S�~�HW�6�<}@�7���~8H\�˓��Tk����*�Đ71[�hi��,MI��iAB����ho���b��:�"/�i��`�ؕ�s<�_�W!m��j�K?��	�������#���D%��� ���`��(r��<��DM�^���$y
-��J����XOV�:��U4z��8V���J� �U��� ���6����}I�l� �J�Pi5�|���uA�� Q����bӿJ��X��0'N�����O�r���{�A&e#N�x�{؊U���_i	��s4���焒G�ź�H)��0�1F�~�H��VͬU$*�o�j%u���ڣ��^ۓ,1F�C1�Q�M� �ч�S�f��4�`�7�~����R�x,!k0�M��C4���7�XW�X_��r0'�"���������`���,�L�|��o)h�n\8���leI��Q��FI��90 c���\���'�y[0�������I��b
-7�y�Ҋ� �(��O��\yh]s�)(K�ĬciK���k��nͬ}��fZ�lV��2@kЪ�	�`��	�g�ڀ6��$xm�⁁��J�#�43�~&��y'����j��̤�J�Za���b_��s��,bRx�1-��ꃩ�1�c��$��ڕ�͞_���SְM���������V�hnu��V�h���{o��Ka����٣���2+��q��Z�s���9��0�!g�!�a^��&9qu�bB=�뀘�X�O��0'���-��*�-��������.Y�d�IX�GY��>P�3��m`T�#�ٿ�]��6f�6s�;����Pi����R�=�s�W���3�>���Z���#	�IQU���U�ҟ!�Ԇ����̕Ҭ`�hb٘���֤,7�ٵ)C�J?�����M�6��9���I,��i�̬Ky��j�F��w}�ۨ�����6*�1K3<�2��<<��_���k���3���H��p@�eSM�~x���o�:[[*|��UP�6Oa}�֦���x<���a�}@��]d`���(�c�^j�
-����*�֤Ru�)������L(!�P�4�T�|��E �����<�2ɜ4��ͼ���$��W$������C<�!�%"CC��2(����r�q�a����2�E�^q���J�&��-����_����昺}־܇�a��Pa�������8��xc��*�������T-�4���=��T�>���<��>2��/�����]�]0�	0C�M�5�&I�'�-�' �����\x�$Q=��C�r��\U(lf6�$��h ~���2۱��X[/�,3C�P�j�qg/��L?��P�N]Y�a��b�l���v�~�k�QOn<�y��y-e�_n�(R�V�nS���z�/�m�q��ZI�V�e���f'��m�ĝ	p��ݪ� O0����m�	J|B��-��� ��!�����w��&�����ܬ�J%�T�W���3����q�eab�u����5�o�r}�b�^OU2����)�Ywbh��u�}�8�s�4I��$�X3o��Q��s8{�b�]M��VC���Pt�CQ��U��u�[W�!TXv��<(g3��IN>7�7npMEF>2�
-��]`����0��c�,���"�G9�#����T�_���ZF��2�۵��-��>/��5�X��X@_�AD���v�Jn�X(��"(��ԮTGG��,�>W�8����NHhX�u��hĸ�ā�S}^1-�#~���1��x��T�
-{���z`���1�*˺`j����P�*�z/.���)�6��/)�.G�|��c
-�T@j���HR5$���B�2�A�P�e�oJ[3�e%��X����]&�{��xb�s���F
-`�bS#��x>z�u����Rr�����o�! ���x�����k�ɱ�i-}�V>��'���j�I��)-=O+���_k�9Z�k-Bk��'����6o��X����+���6�3����\�������jF�V57]7]��oU��W{���������w����v���y�5��<U����U���\|j����C^��	 \܁QM�0W�.\�f���]� =��IŠ��X�oa�3U3��J5=yD�3.����P����7��V[;ۗ��^��Lu2�Qv3ZE�&���������/��wr[Ķ!:S�y��w���4��LS%Vĩ�R%��[Q���i �5�jQ��ە���)WnY���J
-������p��-7l<j��P��BFC-��Z�r�SɅ��l�iss�*u^�Wᝃn
-w��9��S.��(1QN�&e� �M�k���m1F���)o?ӳZ9j/�Y��_x��u���hiI,��}7��s1��V6v��ŅM���)j�y�*����L�S�����d(c X뢿֖	�Ǝ���'4��"�W�����z?(�(���1s�$���Ը[R�-���ޗ*��
-+�Jn[jܶ��@*�lO�"*tn�����e�IkX���}���+�*��ү��y-ɢ�-=�o��S����NJ�e�J����@��nJ_d�)}����Δ>�v���V �0l鼗��'�F��^
-�VP�]�� �qW����x�C���V������
-��n���ZnKiw��{��=�\:՝����=��74����QUSԘAq�
-�ۚ*l�7U�;8�T��q�R�}7V�����ǩOR��)��x�<����]�m�,=wDnt�>uL_�>uY��j�>\�-eV�<�Ĺ��9��A��G�,Ʈ�E�5P�k��!�"��s�����`}_V�/�k��#��"j�[AK���J�9�%��߭^-�b����yD�N�w�G��'��a���1�����ih����7�u>v�[/FN �g�?�G}əQ�iI4V?�!}��tAD��Z�&��u���T�Pエ���OS��F����� �뼥u���x�I��Kۯ����
-�ɝ��������Q���U��S�7�B�����m��}$���w�#��b�11b]Q'4��ZT������?|`�ԥB�z����A��+�׃}��ԡ����&Vn�C�����z�#�Sp\5G�;��N�̡�یǆp�g��f�H*=�~����Ҁ�J~0V��!@z"ABw�tf|�t�i���Z�mn߃Rj.�
-�$Yi�Z��6J4�s���b�S_�a�_�ȇ�	g!��8s��n�P!��Ԍ!�XD�q �}b��S�3�5鵸�RmR�����`��ē`�T��j%��*�0b�G�K�����f������>��tq���G���Lc4��sW	�t�U%;q Ur�3Q��bg^�*!)5TW�0ʓ53�Lٸ�ͤ,8�Ԟ9i��gN�CjϜ�gN�3'왓��y����ߞ�Ͼu�����1w�mb?�%���K��g)u�Ro�	q!F������m�˔�f�--�U\�f�S\6\F��`���\%嗪�k�]�)/U���ҿ�V�!�������Fd(�/9�{�s���̄�E�%C��뽤3�}�%��ݢ������@&,B�� ���1%���_���c�M���(�_�� �O���s/l�>���C�?�=�`�K��c�\�����U����a�gD�����ʈ}��1�u���#�'#>I��E?%������ڤ�.�G���,׾T��Z�j�d��|2%<~��_Pk�@O��=���M�.W�&�)W��&���OG�&n!���m���&�uX������ʔ���{�ǽ��Go�&U�k��kal�G,5�of��%�5}0l	s`��ױ�zg��l��Q����I����b�>�홈W�&���'\T�/��f���Y���fgz=5O۫��=���L�t�	�Ck$�����ۃ�	,ឋ���7�+N�f��cŒ�@���P*oP��IQ��K���@�B~2wi/��w����^³W�O��m���U���Jc���(J1���Ri��[`�N��.�NM�K�H���i�转��J�_V�J;����${�������TށίW+�wZy����H�ZuM
-w�4!��_-���'�;ʓ���ӥ�M�ҶO��N�W��/2ћ�l+��+��-���-��_r��_*��y�a!8r��~k����M"D��+���o��p~u�u8/�=.���;Q�W"����Tɝ�fܕ}���4���=������� �ѡ����p�܁��V�������=_���T�=�O o���j6]����6I�,L��S�|� ���f5C��ӬW���a��H�:�M���i�����M5�}53������'H�����#�|� ,�-llm�6�w�d6������v�����;ù�>�HDf>����rg��,�� }�<z�(�0�]��3�ǧR�S�c=1%H�'d��s2��V�5�g��-�c5^��A:�f��r{\�W=�f5~����67��U�:�U�X@�+�;s�$ i!�o�}*��0����F��a8#�8{"�	��T��.��ӊi��*���'�?�e��~7�/~�$���x��o!���fKv� ����fzxE��ϡﰂa�^ԡ`���8��L�F�4N��K�Ve��Qx�t@M�'i�ցw�\fB���\c�o̘6߸F? ZdT�T3&i0Qh(�f�X0�$���Xl֥u�mB�G�f���f�'iv��Z��,��<M�LQj��I��(�!9�����Ը��`[����\/�����XE|�!O�2˜�Ӕ��gW��%����9e�J��gf���F�`��"a'�����b�~��IVEn-bG��2!�$��"���k���u�o�8�ͯU	���\^�����I���Z>���S�o������ ��l�-�Η_����Wy+��L1���	�R�H�<(��w����_�L�����fOP����h�)͞����	h���=�Fϴf��ynn�4h�[�=Q�sk���Lo�Ț�f�W��h�(xf6{B���f��y*89��N���;b_�	5���x,�\`�����1E?}J�{B���%�1
-�9�_�L]|]�[q.~v?m=/_���~<�7���q{��8�l��r���x]�ȊAJ�����# p��,ZQ1����E�R�(�lm T�)5q�$0��DP��啶q7O�WvA[�=/S0�,�^�;ź���qLQ�J����a�bpٖC������\r|N�x�J|[5By_�1E���Pe��k#�H�Ed'���@(��O��@G1�ӷ���-a�g&����R�:HӿTk׎ؽM��H[�s���T��}�s`�~f˽���U*ZZ[�}G����r�)�C�͸������:�N�K4'���&�gC���Z�xg!��P*��P_���G�$́'UR�:H��SY�w�ume5k*.W����������O2��"3=߿,��4?���}�&������Z�K�7���I����̦���Db�o%�@g�vT�^V������ �w����t~�Qb/����V]S�h����,�U>��=,�{��N�ڋH\�}d_�}t��>�A�S2��%\+��������Hi}�s2>R�q��xȝq����F��ɸ,�]�x����;�
-�q#e�=G��}��������'�/�[;g�i\N�����\.u^�_��#����j-Z��҄⨤W�.˜������c�_��V�׵�z��S}~ij���ۑW�e^Us��ZZ��u���c�i@�g�j�h"t3�Ө�c�AAG5$)(4C�yӫ��c_~�g+��na/%�3����]�@�1��.l�TBS	I٭!L�<�ĥ��¬���.����/2Q m�u:�-I�B�+c;e$V����1��IM��Cl��bwW[�k��1%nEP�dOٱ+�y����#k�2���`���X�Te���z��NYP�Bw}GԠ>��v 
-��۹z�n�,���yR�`_C8Y���U*��0	��x+읈/����{����o�Z�޾J�ds�����S���asoeb�O�g�������s�w��Ns�*��ĺof��jkb��Sim�_��[%�ed��jfF\r8�j1nn��L<p�Y���vq���b����6kR��� ���fh��T�4)Vi2�x�W��x���X�̼_��iM4�������i��R���zIH��_ݜ��I=ʸ�T�pt���5��4���F�1�� �V�[�I�n$��pdyX耉���Z;/�F\�7Y#�6ͩ���?�6��#���Zm���V�ѵ�*j�u,K�Ѷ	�&��9X�L�Z�扎dw#��e������C�Mز���X-3'TylmSk:����ԊI�2�i����լ����S�bs��z��H#VmS��R��`�ߠ�e)�e�#z����oG٢����c�ǵ,+F�.Ӻjcv|u�� �X()S�0�cDz�h�����v6�x>�u�/�_8��km���Z�G�y��&K�WI
-0�ѤS��T�ewA�_���`2=;����*����#����l�{��1� ���]˻�ٍ�(��:n����~7T�����Z���6����-,rU�:�D�j���l���F�uBh8���K��������`��uǢ��A�0B����0d���5����Tt����Pj����v�����؛�u��Ei4t��C�Vk;WX16�"8�?UgWO?��pM�Ѓ%I��ܵ����r�M1k|&t�m��
-�Ԡ� $(�6�\X)w�XV��1�������~Oّ�9<.�{.�H�<
-@�8��p�#�v��fW�Z6�vN���.P�.e\�.�:/Sl��=�,�2��٦��d?QWe[�S�d�F�$��e+��@��o��n�yQ����.�3\K�<;�&������˪%�!�ϫ[�c90%lV��)aߕ�@�Ha����p��	,�mo��>o8�]K�}b��r�B��?���=e��@i	���H���@o�����	�o�#�}��e���%{Fk��R/�]��|h���I4��������[�2@��x1�x��)b�ذ y�1^���خ&ia~�GL���"����B��/Cb0�$�H�T�T8i��(�L.�X�يq��Tth�2MUv�4=�=;��IiOr*<�<���%Z/e1�l�A���@bV1,I���l���� �{r�Α��Y��#k�Sؑ;��w"R�&�~�$=�&I��H����Hҝ���\f�3��<\ϽJ�t
-g/l����{���Y�g��J+�Z��ҽKwZ�4n��½���ļ�U�s��C��zh�SvZWuк��[��"<��<�g[.��+��3�}H�!i�鯨���7�Q�Q��I
-�Ҧ��N��ܠfv��Y�o�v���ƤG��n����ג�ד�ma~йAťz7B+�7�@ٷ����9�����^�^�#֟�Qm��R��v�څ��
-#T��o����Ͱ9��D�~���y�kܰ�D��ُ��}��;|� V9�l����e_K(��� ��L��5�����f|��Vu�pڲ́ �BL6��q��o��!0_�Z
-ڎ��T��B���\Ⱦ��+x�"͐^^6L/�v��.c%<se��𸋶	�O��[C���������ߧ�S�TZ�ve_R%~?��e[.�-��^.�Kn�?�*��x�J:���Ƕ���kUv������P��@z�i�@�1\?�r9睥����7������3����̬ʬ>T%��@�-�b`��x�c{�x
-��q{��Zϯj��MM�f���][�53�4���:�-$,�::�Ё$$!DW��	���H���"3���%������|PWFċ׋/"^��w�PƩ�<��:�;�k�+����Z�k���8��m���律��l
-d���ͤ>A�r��Խ��fj�����j����rn���o7�6Sw����]f��ݸǴ&��u���yQ�^3��!���~���;aV��k*n��<�p6(�V���n`��z�<��ֹ�ujj�X������j�MRr�ڶHEw}�>RX�p�u�M*r��ϭU�=j[~D$��_>5��m�Ǳ}7�T[0R�D(/q>fm���v'c��,}����kk����xʈ������X��C�+ħ5xD�a ����u���u�M��j[Wԃ���~7�T���x��Z��i�t�6X]n�7b=��4X���Ū��ܩZs9�W��f���&�ߔ�&�ڤ�P�;���ƨ���M�Hu���c��胆�S~��G�Lm�֥�#�LM�^�[f�#Oǌ`^L�y<��48�y�@�f�<I<���A�6��wͦ�[�k͏���Go�D\v �-� �s�
-�=�k%�K�^k~���DE��<3D���j[75M��,-�z�JrZZ���g�2�Wa��Q+VR��m�o��UR���`Y���u	q�Z�m�e�l�4�l�rVh�p�q�n<R�S��ԩ�U߻���QI��Ѐ:4��K���Q��"��<��f�=0U$����ԽK����D�9�\*ƛ��;("�F�l��[��QOnkU����rv�Y֗9��~uF��WuY'��Y*ḳ]sU��G����B)����(�1(Y��iu��)�N�"���(��R��mFY�:�p���@�:�?@����(����
-�`e����O�JP��F��:�����Hnð��M\Xr�j�A(ԗ���^���Sa�Ple���D���ku��e�ݻ��n^r�kIl $G�k<R�0wuΔ�l�8�=N~:C�>�H�"*r�(X+TV����sS}����4�e���������Ҩ�a͊R���݉�F��R�V�J��u�œx��3>9��К��z����d���-�o[��熛K>"�=�����h�R
-Z:��o a�3�+lB��Nvy4�"*Q�Ku���j�xOU]�6&]��/�Iw1�E��c<����T�$�䓧1.�d#s���w�Z0/)�9���5�V�n�+���m�*ۄPC�����z��%<O�J�ieTRo�VE%����:*��5Q{,*��Z�(��x�8�E�Z��>
-�)�����u$�(�&;��>��lM3��g�4_��P��7��/����]8�w0��9`tèM7�]4��2p={XI�V�E"��l�:;/��t����!x/��)�e����r?mI,P=��/��w���C���$LR�Θ��ʔ�����*�u����*d9w���/�ƴVق�P-)���2
-���j>1�`�U�\_+�cS��2X��O
-�bn��,4(�Mv:П��*D�����k����ҥ�Ю2J�I&���({y�Q�S���4�p(��QD�pG���l����DOTjx�T*d|�g��@�,PԔQ���H(j"ۖ����	��F1w�X�o�0�	d��بv�P�"�y.�%}<�U��ĵ�4�_m����b7qmy�X�/�JV�����^ݩ+~��/;��X,c��i!�U�g��}'��GUbk�G�I�fa�CU���2�?(�$^,x�#0��?凡H�l�A�܎�~��y|b�G;���hf]�S̗��Q�U�W/���"MK�嬆��F����S�u�9�	���厝�1$i�	��U�f�ҽA~�ˮg/�z�΅[�[ �����5�	5���eҠ!�)��h�} ������h>s	���W���
-כShFք��S�'e�$�7�]Q�5n</"���E�����㸑P΅E��j9�C�\��^�y�),jU����U�^��=7ʑ��{��=�3�%�	JwS�5�d!<����ʭ�KDh��o�n�h�:��	њ��;��J� �P��	eM�"�mM'zUO$�{�7K���}�"�7zi�ܶ'�1��$�yD��Ų%��?_�����"����V�t���*]�&�����o�ϕ�7J�]�0QO�X�@=��?|Ai�,ɪt�^�>Ԛ��Ι�bG(�r��]�W�e<�e#~-�n������=Ę��l�g}M���XO:�~���,�_��|y�˽f���Ij�$f��;� 1�����OL�]ے��0���"M��`�E�+��3���_
-Y+��T��}�I��A��JL�n��DB	u�P�	�Ҳמ:69*���Ho�հ!*Cа@��� kE��G�F�������MO�	���d��G�%�p8�YMc�>�[ڮ�MU*�y�&х[��]�_��\*j���}�f��w�_���?Mq����yz�P�]�N�¯����Ʋ���}�*�-c�;�-Nr�]TJಿS�+����&�r��ª.M>)��I��FхMu1{9S�DWzЕ�M��	bb*�U�����4wb�O
-�q��\�*��}��j�{��us�*`�YM�GmVڏ�`?s2���~���3�l�(Њ�,8*���)��<�ժ�6�׊\c0T��M-��L�>Y���w|���n�C����`������S,޳�$-5����/�11��,��௙�h��h�_@{�A)��T�ZAf���_�f77�g��ە
-��˛wl�yDk�Ƀ�Bb0*GF��`��`�*;$Ȩ��!̴]�Ҩ�Sk���e�`m5�r)�����J/���oܗ>�%ꞣ�VLsߵ�8��#��D[x�4WWHF�U~��q���e>�lZ�Ν}�@�?�i�+��b#��l�^�<6C
-�ʱ������DB�I��h�+�`'�1�y:�17T>����_.�4����@pT���if��	�K�ix;�҃5Qa�h�jm��v����9������L 8�ފ��$9kp��U�D���"p7 �ww��
-����q6�=Pz�E�,�<�H� �YB�,���B� D�[���QQ�p' vQ�$��@�ԅx�\��	�y@<�B<�_�^�����:<��_�Sr�U����.X#�>���
-�`�+t���&� �O����cZ�gA�ԥ-���Z��(��~����{��x��6�5�MM>�Z'=�O�3*��W1,5��j5�7��T[��z^���B�Bh���mF_�6��F��N��UTdm����m2V��O��[�}�c{R�a��Q��͛:�O��~�M�Q��w��أ��~ð���)i�
-�|��N3�]�59��,�r��p����Q6�F��N/�8�Mj{��s{�Z�۵bY�E�Z�3������y�[�%�f���r��-v.��n2|��cJ�� �n�t�(0S��f�ʒ�(����{J&��m�F|��d4nd۪����(c]��:���C�g	TFPF��m�
-�&Z�#N�/�J����?��ϡhۺ1�A��ף�8j?!���+S�Q�s�ğ#Q��?��(�b�(6�b�N�ԗ�����G��8U�J��T��+�ZO��7�[�͘zO2�qp���������D���0���� L�5R�����f�F�E9�P���!�<K�kU��-��r��b�6�!P������i�߰v����H���l���X��o>��jx~ٮP,�ޛ"�#�l�]g$�~k_ �h}�Hj$;\c���.���pĚ������[DLb��X�#��HS|��Y�?�?�|��'��Y���Y��׶KU�G�4$4KEB�]Dy&�@lb��,<qnG�\C]�΅�x/���ߝ[����q?W�:�n�,��cڡ�L���-թ������2��e�I��n���f��w��@0`�g�y̝'L���^�y?:5�^���nՃ��jP�wC��\���V�A��v"�S�?���:i�<�4�,v|`"p�M�Lw:� QG& �@�'�����Y�՗���69�$��@35�v7����a*�|�k��jc�ڵ��Y�o53Z|����� ��}	��5���O�d'��A�>%������!̛2ړ^�8i�&`&�f�ȧ���aA|�0���@����M(7#�_���I���f	�3��_Ke�D����}/�n� ���C����3@������*5�����Y�v���Tt��B�j$Ǣh�@葿9�
-t\���[�� aH�Pn�v43��J�s�R1e��(n}�.�.�D/P%Bv%l�0������/������� ��L��;(߿�B����ƫ����A�f;Р��
-�:��%5r1ەeW�
-�[-�1���ٞPT(}�:�X��h���O���"������'���K�_��I~���!��@�>�.S?r!�2e*��"�ყ��������O�E�?�Hqƕ�`6+��r��hnlE�W7�x�o$�h'e_���v��/I�������q 	��NЃ���N����;�`��,Ƽp���?��g��zΕr���q�ғ���Ԍ#��f�>�ݮs9�s��/��}�tex:��B�/��#4��q�p�q&�ƙ_`���_@h�	��x��i�t����a��D�J�<up�`��Z�|��؀|3����C#^�H��mK��	��
-��,髒%��%��d�@�,$�$�o{������i�׉���}&��
-�W��zu<���1��@H;[�D��%�V�t<!V=�_�!HN�q��b�q�4Y��gry�+:'tJ���֝����b�fZ�d�FK~��-�D�'o�a߄��ΩY��7�Tw7(��8_9Ψب�ė��]D�2۷L8cPQ��j	��-Iď{�BD��E)�h�]1}���Ǝi�ӕƪ��d{�v6���+g�p��Z�G����� 5�C�������~���~�����/5�T������}D5-�M.B�gFC͞B+?rJ��Ǹ�9I���4�ű�N�k����*��g`�=��1{�F_CwJ���>z��W�Ik�#�Z
-�����'Z3R|�-5�{iP2&�BBYt��>CYt�7\[��lC�+:�>;��d���j'�a��:'Ȧ�XZ��$�3Y*��)�~Z����gK������R���_�/Q��VF�Lۙ
-�(�o�8��������v�f_�ۆ�o�:'���D*r9_.��c�>W���dɿwdɗؼ�H��c/��E��o&6R�0?��U��lѴUۢk��ת5$���!��; u�C���S��*ꠚ����}>���-+�\'��}B��xH\����U�]ՠ�~�#��mVY�Ӆ����Z������6�ʩW�b<'~���wݔ�"�u|u�7�J� _3�Pj;����e��t�լ��&r%�꒬B���}u�ݧr!OŊ����JQ����QM8���ܟ�4*�U���
- �&�_��:�>b�q�3�	g���u?$qK;��Ӄ���O�S�Vn-X��3"ĸP�����uX��U�^���rbW�K�\�6+�����VQm+��F9/������*�k.��J�uR)*�|RG���Ǡ
-������;bR�j<�+�Z� Ll��?�x���So���|�xH��fOzro������xr/��N,�ʅ�7���*M����a��:�M?!bb��u앜B�Oj������o�����@�)u�S��ѯ�w7����R����'�B��:��O�hW
-T0|Ru��T��b�c��^�}F�Z��7�����k8�=l�A{޺I��)��I��-w���!�@�/�Yz|_��k���e<�FC���S|�M['=��4O!;�߃�5���t�}�~5ѯJ�B\�ϻ��o�O��3�k"K&Ѧ$�,��P� D(�[b��� ZH��L����2)�	,�Y�G�x^ϱ>ʓ	������^䯩~��d��Q��L�+2���v&�8ƀ��.��	����U���C��G�@���,���nQ.Ӌ���&�C:L�a8�:I���
-W�k<��+��ˉ�[��L��F^´�e���{�L���tE�Uo~�>1'���{�&Up�[�ph�{w��_�Ku�;���'aȓ���A]&f+��_ѽ�Z���ۼ2�K��W�w��씘pK<� d���,/������{�_a����t���ӥ ��i��_��M4�a�]��]|��g��#�!^r�,Y���#dq����ڋx�wD�ޙ~ƣ{���F����5n���7!�䎨�<7ڋ����z<[�D��� g��b]�]ƒ�1��`K.�)4�y\i��҆7��[*yo-���T�[*Q ���úGXC�SCz+�:�4z�^���#+�zPS��>q{H���=1X>W��R�T^�9�,���;>?Y`�u�k�0��ׂ�S;�[���8,Ɏ�&O$b8j�@�Xo����j�mu�۪�{K��fo��~��������FǼ}K�MDwzj���V��^���O��-9e�͌���v�TīB�����8���ʈ'SK�j��f��-�չ_v*&3�8y_�����f�}�}1�p�\!��*�ivQaT�.����w��
-�sd�f��%6�Ny$mۥQ���uR/V(��خ�_%�lS9��b��YȞ�h=,dOs�^��ű�TǬ.��¹R�|�x���Ri5;�;NQ�-��.�)��o�?������n��˧�����߉�k�}��u͞xW#�����/��B$,�����YX���a��d�bQ��	4=;;�_Q�Z���&Z��9]�n
-���4L��BӤ����ƍk��FN����a|����E��P�Yd�"�Y^ ����%��r@��~Z���1"ls�<�'�tE����򺺉�
-5�_���4f�41>kX�T��;,v��;�FH]X�Ύ}a�Ѝ��s��k��yⳂ(����4�����]�:~'����*N����+<=0�LS�'��IbN���jk�5��J,2����-����:J��US�R�]5�>ͼ������q�9{O��E�v���G��_B���큦ɐ�j�]�
-�M�l����a�1��ğH+��u�k�>jl{����1l���K�:��_km����& ��.om�bl{�P���+��6��]�,�$c�J�>M��\P�	4��;�I�"�Q"4V���1zU1��`&��d3��i�%?T3�2��h���H���i�P�u_��w~�£��ޥV�i� ,9�����| �=u ��jy�U|���01'&%�Ƥ�Ɔ^�$���bU�v�.I������K2���P��G�Dc7KDd�n��qӸ�K�Q;s)�ڿF$_��|��������o4�\]�c{�/	��u�?!
-���v�8"Ҷ~�f�Ś�5�I.
-v!�̙1_ݕ�eN0���.��,$x���4hH�o3cx	}�<, ���Z|�~�R+��FA��U�
-�4+(�Ylq��������r�r�7�Ϥ/ ����;�|�!Z�1�>3�����^�.�!7{ ��(�Y�aH� ڊil�{�{jF;�T9�U�����G�ӄ1����)Zq6�K:Q}��Є�-�k\C�rj[��e�96z�y`���T��l��j�z��k�|=�L�2��Đ�d��B�2�0�d�Sb���4�-�y9���y[�A�8��p�W�����G�����x��b�WFR�(�*��GU^ႜ���J����3�U�('�s��%���e����y���c���ڥ���.��>]WF� D7<��r*����\1gX��T�������ũ�z�2�>f�����X0��Dw��T	��#O8|U�Ϝ��7DlK~~�FH
-������/��F�2���� �J}����9�mxW�M�a%\8�5jS�龄�}N��G��+��QY���eR\��"b{�������M���jz-�f�R5X�jP�LM�g	_E�_3�L��>:X��/|j-��zJ�4Ck��2)�(�	B�]H�k/����N��v�p��1��E���!��#EՂ0�?y\{�,Nä �.���L}���>�B����"Z3���_�cֻ*ǈ��1��E��bZ 0u1��0=0�6&Wl�0�P�ܯݬ��AŜ�(��b�0�+QX�������End��^D�D&�i�9AH	���DCK���,=>Y�B"���Q0���r�\���X��@1X����2��ֻC�Wt��H���5*�r���c0vQ-�y�[ˣյ��H����K��x{�+iÛ��ޣϡ]��uvP6�F;��+��N��Wl�;A���8A~9N�e;����"'����>;���b'�������6x���J��N��N��>*���_~���҇��>��t��A��^S�jwӞ��qw��YwP��x�S�{cS��s8�d�L(5�r�qQ����lP'�䘊Ԣ��	�!9�8��FJ��s�� �n��n8��� �Re%��_��ڃ>�N�@?���B���c�Ug�c�J���N� �� �"�ɧ�q:C1O��6�_h�c��D���)5qJ�P�x;�I��S���K�{X1������|���`��ߪ�Ev��6&�b��L�9Ҧ�f8���e;�aU<?,�i�C��`�h��3A��ɯd|�jJ`]��$��0�w���b�ʨ򌣇#z
-��N���Vn�+7���xW�q���"2E��<�KqSod�8��Jѵ,!ײ\Ƚx�:	F^�ۢ��ᢆ�s�PЀ%Gݯ��j��������z-�z�R#�v�EL��F{[0қ4�	�U'�mᤶ�a�m�#oˌ��5,��?�����Xp�6��dۂ�I<F�J�L�Hm����cq|��{|��Jq�_ӯ���Y&Z/,K~��8Ʀtΰ�׏�qk6�8��G����̘&.u��m�`�8&I�uy���)�$���<i���8��� M�Z�?��Q�?�3(^��1��Z�8]�~J���y�VU>������Qk��8T�Ij��\R3{�/�(���S��	�(��/q��?ݣ�w@='Gz��a��SN0ޏ�Ï8��3�lw�b>�eOM��#;]�ڃ�O*Rϰn�Ju�����9�V���k#5���6�]���n�m7+�V��+���)�w5{͊�s��-{̊�����]�Z��oR;̐eأn
-35��˝��0Kb����/���^^�i�&r^�ʖ��'�?a�!�6(�S�����iZWǅ(nې8�����;��<�L&��Qτ�M$Oʌ���)qhA���C��\ޚB2ɐ~��Sy���'n�(�^�1�|cx�QC��e�|&@,>�����~�-n�R{֠�wQ~�j:CefL�w�����F�����v��F蠯\���t��1��k����)�Ĩ����������jj#�S���ܧ�,�8{��T�I�
-Ή�K�lu�t��p��P��^��۫�s<�����fngP�!ǟ�d������4�v9���
-���5%��p�PA	�s%5u^%�$w��9�X���q�%�(�#
-.�5ջ�M�0�I$�ߩp�bm��'�6�S̼�EĄ0X��t�>�Ʊ��:���NzRk<��\�LG3k��f.�]�R�yb����A3���g��.������#D����ݕ�C���F���!%P�~ c$$��q�7?//D�K���A!Q]7P�>�`ѺbfR�b�
-�5]�K.����b���Kݡ�:D�;4�-�����[m����~qJ駽��M[_7V�a_9,�.ó��Ce�+�N���թ�q:/VeH8,)P��
-tr�a��&k��xV)�K�U
-焼�Z���H�;b��$�u�N��Nq�<N��H���/�����[��� ��t����ݝ.��
-�A�X��=�lF�����*tH�Ԯ����K�0��^�Y2����s���%��fC��F����B(����n�����tÓ^��yǉ���.�MY��Wt^&���=i����7��p�)�B��(���ٸM0䣾� �(����F�;�]�f��ͣ1����J�����?跡3>��y�t�a%T��;�8��6z*">@ĒPc�V-j�F|v�?��X!��g����?�RrA�l��'1��Rkkh���d;ʠs�����B��к�Y�>4�6��?��(W�CsD0d���a����H)+���̨�?Co����-D�퟊*��n�6^W5�yi"�|�8���VV�2Q�{��<�T��,+�{��JO&�"@�V�jHKplƱqx�C����S���ۻ���L�E��|��T�Ń��G��!�>��j�<Z�t���R��t�z@�>�u�ջO��Ǽ�K��WL�ﹷj=��ԩ�����Jw�ȿ?r�y��� ؁�kL�	N�\�b��!�|���k�2�#7�xjf�K�Q�-��Q/A�;A�d�/A9A�d�/A~��K��NP�9���5��J��+gK��w?+��y��<����;VX{�Ex:Y���w�R�=X6����Gy@�Sru�i�9�}ع�H�2DYI����9S���r3���)7GK���lM���B�����%p��3��3�|11S��W�^��!o@�M�>Z��i�؎��>a��m��3��Qj^m[��+�隇 hM^��X�b/
-S�-㓳P�,*K�ք�ŷ�m�ހ�jU��}�|�]�?RAy��q,�	�sDs4k��8��L��_����\Ch�������X,���oP��)C {�����A�������H�?J%�{#���xP��w˗��_#���Q|K$}���/�ۉg��HQ|8t��e�BxY�#?H���ᓀ�z��ƿB��1��Z>������{�FT��&�|�P�0�M��6z���OV���X�����r˝O��G�OW������a �c�{��}u��_�� {*
-��Ғ?1���mBQ�� L[��(&�~
-B�V�RETbF��LU��"n{��u*�/�=���J�����_;���������ʛ����;-���W�Y
-��ԁ���6u�C�х��3y�ec(�~�f)w��Z��E��D)G x��R�:罄�J���\>�Jk�8U��)�R)��N��w�O��&N�s?�)<SŐ
-}���Ԩ�&6	��f���\��8!�=>�$ʳY�N�r�QQJ�����4�k�>k���KkRv}�3%���zV�˾���T�Y͢�7Ĳc֯��f���eӗ�q6��1�Y�4�)}�z|a{U
-9����O�lK婽D�{��'C0�	zܦY?�B@�`��:��Y�6mhI����Tȧ�����]�)���(�#���T�j��q�]�Cq����L>wt�x�j�gSr��S�I �u�<Ih��g.�@|�B�!�5�8�B q�-� 
-* ��mPG�A���l��aE�g���&�g4����A��3��<�x;nm`��6���`o��4�mBV�=����Zro���0�:��컶`�)/��^$���^ga,<Wg=%�6Ѭۤ�JU� ��AM櫏���]p�[��2��!�wP�������z~�z�TY������0� ��8�e+3g��KS�x|fˬ0��Iٻ<��6�ߒx"��|rF_/���Ȯ�&�o��^�%�TlQ�)\� ��2p�QԚ��SF������˔�eʶG�vkup������&�vk��Lw�A�0���5y�W^��Ha����^Yή�s[4k��>��Rz���B&�=D�{��[D(oi7����?��Ϡ��9��2�r��xJgv�J��� 	�� �r�p��f��x��	��zSõurW�mW@���/��'��"�
-N����û���u<���d��SZz�Ly�x9���y��"s��V�m�&Q�E��У����F_t���j|�=������ɷ���5)yXk;L?Z� ����vj�`������v�uo�N���Y��Ұ��ٝ�0�������)�ܮMخIA�nMϊ&_��'^!z3�c�@!�P$��Ft�oJۓ1,�S�p���D/���G�����~T��BDCN��� �r�%���y�U���*�%�h�Z�iU�wh`k_u�y�b8�5*Kh죱��m�>`X�4Z�P�iL��4��Ǻ�O��ܶ="����|��:���0��������M
-DZ*?*�`�a���hA�W�S�A�s��|K�<*K�~t'6����C��;�߬tO�'�u�Τ\�Tcw14A��x�=�!�N��zϤ~��C�T����2��]K�r�����P&�~*6B�o�ħr�S8^򋿴����ܬ5���ы_>;��Q#|֣Qx�ntϤ����~\���3�J����zO�P�	O�0<hD���$N����D�0f��2��?{R��-�1b��1�I_Nk��U)'Hܹ��.cR��Ϩ4�׋�FI�vR�V�h�%`A���6��?���<A<D�lD6A�#�$�ncҜ�����س�o�r� �-���k?/sx�X�Rbd��n���B�[�Ќb�����3��\��2�3@ܑ��0O
-��S�\P�(׈-%�����1��{x��6��b뵶�\��xy��������_��\�= �� ���;o2���W�cb�M`��i�Ff�ωR6�/W&�<+�}�$�|"4�DH�8j��6�%��$����dφ���8�c��s���u3J���6�|���푌">��]!"��Ԟ��mw(-d�ټ<|���S��Փ�<�Z����[�S��=�o�����3.WI�ih,Ʌ�sc7pc1�ej�!�ĭ��m�gѬ"��	7C��R0��ţ����ej�$�~�P������G��Ԉq<��E1�q=�I�H�H�,O�;O|{������XԱ�亶���\~�����~;z�E�,9��a��[h������>�m���x�Z��!�5Ⱦ�'J�����}Z}մy�E&������|�]<�H�ɓ��յ�� N�jh3V�n��f�x ����4(�Ȋ�$|���خ���E1�5֮PzF���&�c.c��|���	s��yB���e�to������F JM���#0]����JȑK�����k�I��晩.3���u����}�"�▆�Â���~m���ea�0�<k�8Sν����{��a�_���-	���!_+���@��"����;b�"��8�b�/�ù�p�q'� ���[, ic�#���Wx��A�:����#�3�fK�#:�k�������$�&���H�_	ƈ��2�A<Ԭ� �M�Sv�S�8���#VƊ ܪ��V����o�F��rus�~����S�t��"=Սp�����9z�q�^�`g����~J������Bs�NE]`,��i8S;���ؖ�;>�O�V洖Z��st�&���qV�����������]�i|b�n���4@lt!��\�W��	�̼,��&ȻuC�i�.Гs�憥Y��ܰ��O�����f~x�|3�a��^�7�0l���	�%�����Oz�fX�S�y��ک?�z���f9=O3Z�����O[�h�����v�
-"���]� ���i!ǈý�C6i�����v�1��)t����+������w;�g��Bkl�~�۰ie�l&b�
-������p�yϘ]*�Z�K�������]�K�9_�J�KJ��J����&w̏�Ξt��8��q��a�����Gw�����AN�] ��.��@�C4��:?��]���'f�8[}��p;Q���-.�n��V�� ��-�x��#j�C�9z�Dsx|�{y��R�∜�80��<��-f����<��-���_YM,�=w�a5sq�S�6Xl�F)�h��i���.��@�˭�T��
-���Q��|��VyU�?I�/{L�P���1��tL���a�a�.Xtb�.w\E�=<cg�0��?�t����X���~f�ļ��QE7�r��pݳ'ύX�D\�إ	v�$�_E��[���g��!������5
-��5�m�
--�ha�*�H�OX�ˉ��B�.���E&_�;���t�~�G��%}��	��>������o��iÁR)�5PHl�$V/6����UE���ram�6q@T�߶��2���{�� ؝�����Tq]����ݱ|_�-���Ӈ�焖>D?�j�c�3CO��~�iԕy�3-}ҏ�v&�i&����)�Y��f��fLBXd��R���4w�-��g�a����J@��j�Y>ù"AXw�y����Z��d-���t��<��iM��<�y:"��X`�N��) �j��{��SOܯ��F�GP�������0����i�˅���T�,d���R	�7_�ah��z��9{P��ԃ��<��]X��R0l�����׆w��s7��`�ɗ�� ��Qre���K�m��J�W�K��mv�Z��VTժ�Q~�%N/��x�|�K��XaV�o;ꗌ?r���|�AVt�:�]a�
-��d�ފ�Jo�I& �.$�j��-4HE�(Ϯ�1M��?g�!!����;t�$��(fj��D�&� 3+A�~C�ġ���R�.��uX���m7��hQ�p�,b�<>'o`�� ��g��ޢ�J+0Z��r���r������F��\���_���y���Zd��-0���n�-�թw��Or�I����%��h�h��.�����27��m^�B
-�>�1;)�P��.
-�2b�q��3J1SC ɏ4b����H��ڴ��w6�R*�\qV���zvE�gs�g���^k[1����7�r*~	W<S��%� >{cr�ޯV��� �ӆ��_ZfI{��>nt_�k}��<���l�q� �+ؔ*;�Q{@*Z����g�������ŒUdv�^��LM�)l˙B����.bgl��v�6���q�r�g�C�D�2�m��؅-���]��K̯����"���w"��z!�q>C=,����	�0�W��L}�q<y��Q��&lB��#����eÕ�Z����������vv_�^�y��.�s��2'����qΰ�Jx�X@�}�f|l�o���(c������R���6�mg_�"4�?�A�"j��9�y�I��w�)lyd2I�u��U޶�"�|��>l�o��9,�l�Q�� 6�7���-
-�~��H���
-	?&�'�(�O,
-��R=�Tw%�L�)�zؑc���#�=���PZ��è=T���7��gAY(�uz3�����s��f|�'��#vW�.ʟ^��#a�'��rۖ�m�)�ӧ�N���y��<��r�(�7$��wB�-��@���v���7�Qo,��X�S�V���z�Z��W��r=��~z�t/�<�����zz%���ӫP��h��2uU6v��g�zT�@�3��ǻ�T����M�X�5�*��G��c���{	����M`�0��ۯ�q�)����]���I8�~NϞ��[��C8:t���6
-�Мܭ� s�;b ���q�N�q҅X�]����x9����6붟+�%"�M�p�}I����5K�xH�����Q��n)/R)/���.���ąx� ^ ��i@|�B<MO����{	b/ >w!v��� v��, J.ĳ�, :b' n7����.�V@��Bl%����� �,���M�<��D����f�hW��sg4����[Z�~󤞧�^��ϾnZO�m��0o�z�O�z����7:�PI�����r�a^�\�ӥ���R��_P*=�r�d#�0���2��"dr}'��}mG=2�2[xb�@b=�mlѓ3�H�[��:=9KĤ�:�ڢ�g�m��n�q�{Vk;�'�w~/oΒ��q����ց|!�Yz����f�^���MhV���H�#	V'�X����B�Aﴥ��n�!���?k��3�.�/�:�Ԥ��ڔؓۃ��p���v���(�6�mғ��m��h�=\�_�eֺevU��.��1Q�3��7RZ����I����w�����wA��`K4#{����fTtꗬ�4�/�Εp4K����.ܿT��H���t��@�OgZ����M���� �Q/T�U����7�T��	�	���A��������Ds-E%ʹO�����S���9-�Mo��YfX��c�Y~����A�E�����4Cq�Nї���>fW�8� P�?1��D]� s�~��H*%�9�<��M��� �d9���������C�������Ɇ�k���O4�75Ɵl��ӡ�3�A/�����s�}?H��A�p�Qu��`$����EB�ok�-2)��L4�߃`y�bK���:��3z�3�~�sp�5��]C��.}yh�Y&t��Dl�=�/{@g=��t���˾�~��|��BH�	��;�{�;M���y/6���=�6*u�8�q�:����~N%�W�|���2�\���H?"�]�a�tp҇\������!Bz�"H��!H{(�~W`���iI(c�4�9���M�%@�za��x���*��}	��N�4�i}�~8�q�����	�Ճ[ѮL (ikD����ɗ�q��,���N[�LM�e=X��ݗl��.u���ey���z;O�>�[��pF�m�:���G�ۃ�t�w��(�zU���a����%'����֥�,/�q�|�O/�?ϙK�`=�n�Np�P��� �b����]�-��c��Q̋~(rϲ��:�s�a��U*�`�W�=_�@Fq��Ѯ<(����������@W��z�j��q�nA8e��AN��b����l���C�8l�3z�C�5lg�5��܊[W|?�*�x��g�X3?�'����A���>��_�@W��?��A�l:^��G��?%�yXOn�'l���a��x��B1��u���("��S���F�$��'���B�����fT�;�G{���u(�}��5��Z��PL*P|ݟ{0g����;����=r�M�8!�K�7u�M=�'0��b�D�
-��.#6*b����\��ȅG��Qݼ��г'L�)�3ec!�݆�ϲ�ǬwxUO�6�)g`�l���P�p���ȿ��hɣ&�GM�YA��"�.43��Ҕ�����zS>t�d�7�ጏ��	 ���I@����E��"_�H'<�@;����%J����q+��+��𮈄�m,���n��N�-�}u�7b�L*�����3�&�*
-��i��Y���<�Wt�N�=5�E��T?��׍7	�Cmu������@���o��ԯ��~mo�^��Y�)�[U'��t��:��.Fg�:ý��f!�SL`� 0�;��_�x�_�U���4�į����:�֐$�u�䭿��ʴ>��ތy�£�1;��\D �_��R�TV�He�pV2C����>M��u1��묳����!p�Z����I�&�z�Y�j�C��U�Y����v�3"����hڷ����{�-������h��Q�b'b�|(G��?�sGYsGe�0w�(��A!3Ge�E�n���
-���QE�B������豼�E��O�9��Jޘ��yR�\x�P��A�f-}�d���c�a���ӂ��y�i�N�面��Q5q��ގe߉�B�%u��������	���0z�\]v�Vd#������P��n���p�}=�o��B6�W���u:�D��ͪn��0�b( �k�(�S���Z���A{��x;�xK�h�Ti"�a�N!�c��q&���sԙ�ÑeN�m'8�:C�)��>[Ҩ�30�C��$�{1ZT��
-�㺱��D�#ݘ��!<�w�+�a�߶��TłpʎS�>���;�`�'�^����%̓"�����eD�����I,k���AbY9J4�8.�(���@�d���T�o���(r�DQl�-G �P��]� ��A�_	VcDebɿ����*�$IT�����������Z
-:A/��hc�ly�	�ز��N��O��p�~2<���d�5'X�O�_v���d�U'����'�U����\���BAeLC����J��+�w��й��s�m�J�>W:q�T{�t��ҵ�Kz����K�8_j�����{�hR�o+	vɗ�z��G�v�0҆~���r(&v�n�r���:�~���ц���8x�݆��&o�X�A�v����(�<9,�s�I����J���`N�# D�����A�7HA/��<���1���P� ���E��R��ӆ�(���&@i�~x�9��`j����+�W�M�e��=���PKnn(5#Ԛ�Jͤ����4��J�5�r�B�ǁ|F�k;hx�����\��V�H5R�sCy�;;�6;��F�ik��n@\�Y�Bf��*k��B�N�S���цdF�q&���r�:�egP���O��N�Hn�
-'����"���ot��-�m�Z�Aosɸ܎�)�b:q�
-��o�d��B k�� #���$��������$�I��i�y���p�]E�����꠰2=�q6�[���`˄�A��9NϷ�O����^���]��>@����8�)h7۟�ʷ���y=�oi��z��&B�G�����z�PBg�#\���P{�nu.#��X4rPb'��7�+�����s9�d�w��{ڎ�d"��+�uO({"��J�d,������]�����v2��Mcй��_!�"'���6�cW��=����b>�Pph�*�U!�5pl��k�4�;�/~�^�Tl�_���>��C����u������iP��IL��ҙ��i�>��?M�ixi�XX?R�1闃�~a8�c!TE��%4ϊ��7m��?+�ߕ�!h'{��Q<��.C!��C���55d�JL	ᴴ�Q�U�z��;�-����wsB�E:�+�BփQ�����b�m���VW(���:�_��u��*�N�#�����CN��)�{C��.���&������a�u��Y-I��ߧMr�b�/g�X�!�B��	3gX��I�y���v��8�ꄆ�3�}AOz��v�I����%��9�G:G��v�<���s��s�m7u�G]�k��P�-Dk����?6������i#�ɗ;m�e|��~�я�-�[D�-(IՆ0�>���a��\�;#��ն���B7��kz�R�^���?�v?s���iz���к�~�օ�X�KPV��KӿG��&�+}S��f�5�H0�ϮZ�ٷ��R�6Q��i�����Z�m�C������x5���>�F�\ƅ���AʘZL��c��ša(zE?�=M�/=!롐x%:d���q�)ؚ,�L,Z'�n��4��&���%�QD�JD--Ծ�O17�C��� �2O�XKB���F(z�P6�>��=����黃��g�=�6'ʾ^1�*̾�>�B6��]k}���x�k����y�i]�����j�����rKJE�&��R�d-�v-5�i��|�^�/�kY��_�?���LMb�"'��;�����x��	f?��<�K�����"�6�)p�Q��h�h�?�]�$8)f�%�?{xRbg�c�2j���W� ^u8��x�Q�avKx�D�Ȩ��aX.�mL�_��;����t0=g��fF��zE��dc��k+��"�>3��|(�_��x�
--�L�C����6�=�'��V۰�|)�,%���Y��g��M� 2�*���8���v���N�}=R�.w*�>v�Ȯ��3�zH�x���*���k��f����I�L�{��f���dԋ��Q�d�7f�j�Q/@2�$�]�d��$�9$s�%�.ɜ� ɼ��HFw�%4�d�Lh8�|��I2'=e��SE2h7��,�,�I��#���F�����:�k�_-�S�F�t�"v���
-�"Ʊg�8P��2A<f����ʖ�@��p'\�c��nIm�׮f���YB_ZF��9Z�3v+{��N�����<�u3�붍��(W�s4��JDE��X!�S�T_�?�~����=%�5:$��5UV3�/�/d㻌��و���~&>�v5���!1-�eԳ�%F
-�tM]����^��B�7��zLA<��نgl8 ��
-�Z迓���UL��2x>5���5TU1�4ڵ�x��X�4ǈ	觱),��Z 5S���"Q,���6.0=�l-�1��n���v>T�UE�E:�tuv)t�qU��H���l���1�sDE2�����N��j�Y/���1���wO�M|���w�����=�����ez�]z��jY��+�N�e��$�.���z���U���Y�������>�o�﬏�;���������oVlŏ7GT�x ��P�c��߰�J@h}�V��f����<��_�ۮ4ԕ���4�!9��P�� ���~/�w˹�H��%�k+��3������n3���u�����,�a3�Č���@?�Tu�~���T�O{�Oנ����?�"~e���_��G��{�L=j�w�G��r3~��[n�V��Fn��ZJ�k��fj��b䖡��2԰W��M��?qu���d猫���6ikQ��܅�T�i\�:��t�cH>;������+�˜#�ה�B�����%%���ц×[�쟻'K���s�cv�q*�q@�wwb��y�zƂ�'.����{��n#�k�V��Fn��Ze���Uh}�Y�巛N�ϰ/%�Pf'%�Cu���ք�ئ��k_��9�/q�h9�/����<���ҷ�F�f��|Kw����i�1k4�%&����T��!;�'B�7q���6�Jw1�+*{�����i�V��Jn��Zk��ע�SL�`a��1�n����(k��Hl6��(9��IiT��M�\S{?Ԝ�Y�M<�ʽJCָ��p�J��P��^߮P�%�5����6�5�mT��B}���d��sF��挶֘f�֘��xތ�ܘ��ט�����u0d�Îh��� ����B��Mت����$���[o�l�9}��P^�G��ټ˚;���1u��bs�����ԫDS���~v8�<��{3�&�0[�G��<���#���>e2}��;W�U�r*�˩ ��4�T�4�6�m� �O7��6�v��VdJny}������C���|�7;o��8�[���`�<O-z9��x�Z��- �Y&� �{� .����9QC��8� #m��Y��g��O;d����o�
-Ž�`�w����\����fO>��	�٘.�_I�|��G{�Gs�f�f�A3���e�>Rź|�X��L��Cɒ7~g���|}���dY�"}�`_ ҅.�'��W��:��:��|�t��E�����/(��e�	=n�#Ⱥ��;J��GЈ&�	���r�[���:
-Y�B���x���/(*_�u����u&��r
-���[h{ͤ?�LVfr��e�[N�rQ�
-"�G]�<A��kzl3��u)�t: Ǘ�*:`5'��B������x�����<��K`ւ��j"2�.�]4:�7��c$i��ؠ�k��+�[W���"e����u'���)f��%#I��=Q��vR:�I�������I�]���x�!p��>L��u/q�.��N�Wno����k�אS�C-�á2cy��U �g��
-���Ҟ�&�--�Z���"i��4�Ϲx	� �M����!�̏�[�������if��Mڻ�R��^7L�~a���1�����9޵m�f����|EUws�-0Ev��׻|�hdR��My����n��T���o�NHm��s�֖@_!�6���^����*
-~���2z`��G/S�_��[SQjj����Y/�����u��'�n]<��3}���K�p�Q~�bH@oT ��h���� ���`�)�R��n�Þ꘲�Q���&����J��u\xڲ�^@��P���C4��t�3�d��}�'�{�;�&w2%[��C��!iB���ڟ��x�K<��������yk�?�ܟ������g�?��~V��+�X^悿NgO��:���o%{R.p�v�r��.c��:�"�-j��Xr'm$�^$�}p4t���V,��AL'��qq�2[���Ϛ�P�^�v�f�eΫ\�_@x�@t�Ӕ;�Y�,Ѵ6��J?X'|@Su�y��!
-�q��&��%c�0�*��p ��P(�;�g�O:�����C��M�L���Z@����M��X��%��]j����)ԍ�(��Ҥ�����CG��U&�Nz����Z�����|>���j�%v�$�@>{6IR̾>�����|$�/䥪Y����Ī:U�ȗǩ-��R
-�B�)6��UM�+����6��(f	��"0��YX�G�h��Z�/���S�8�%������/�K��^ �+�4�aZ�/Os[&���AL��Ԥ�j���!j�!�f�Th��H��?� �ƙ�(¡N���Ho�t�Z��[]k ���"��3b;�Íb����';�y��L=�~8���ć$��MP���=��{���"f�H������j�����{�h��=�<�Ӯ�G�;��M'i촳�$agJ�a�����l^��;c7�igd���6���F?$Ŀ�c0 l�]��c�lc�C��z�s��}+�d�����{Ϲ�{������24��6O�pHW���8�2�$���Q��t����$�K�COK>�!>դ_�n��Q;���E�+Ɯf��yt<�}�d����#��{��Z(4f,۬���qXJk��N�`h���[{bp�:���Vy���
-S&�lԳ���4�����yc��@��wo�^�|l� ��C	
-4��� \��c=$6j�M��9�[�aG�=���N&1���w*FK <*e���=�K3sA�p�>0��K��Ë�tvQ|��.�x�t!F+&���`�Tb�U��}��Ӄ67S���̉�4�D4�j�DΧ��6�~�i��6�c�C��r�5v�������&_H���u�765�K�F����Vo1����;�i/��D+-�Q����r��g�7��y�'� 6)>�L.{�W�̏`r�6�2����u%�E�{mĦ��s���ꗅ�n-�U�&dm-�.a7�r��ji�����X�~�z�wu�QvϾ�Ba�g�o�c��?���E |���@�8/��fv`���-�kZ�n-��ͦK��!N68Ȯ�/�֥m�C���߽�ݿ��wA�aEU�u�^�zPsu��w��5�	�G�@�x��6�]8���٣e���FS��!����F��/�pf��Gb	����o�5FV{��)7(=Ou�`!.�(�V���p��/\�����.���PB����1�|tD����Z��� J�Xg|�7(w|l0(_|l4(C<��+�g��*�&Gy֒��{Q�(���~�X��{Lw��z�����ny��a�fv�����P�k��^](�nZ�����kQyc�PSk�a1�b��0�DdW�'B�Ğ����**��u�چ󜥤[��l��?QJ��~��a��2���c�Oh��$�Z�K.�I�@rQ@I�T�'U~E��	���|{�zޯ���!�W��H��*�JKt���{��]zj�/D8����c���1��eTA�g�X4��^������j�}UqQ_��F�So(�+1�(�V@m��/��S(G:8b���t؟$�Ua���v�������g��释&37L8������?2��[�9c��+���2�$hN�8T�H��)ڹE�ɉ�sKC��,�ٹ%�ٍ	������L��ͬ�Onm8j1?��>6�@�q j�|:���	0���O'��ݗ��^���X6V��聱�����8�c��x���J����܇
-ù���Λ���e��<No��T�˟v6Қώiu�r?�jw_���]�_wI۴�� >'u��dI��� a��t�JL�>�c�;S�Ts{,qIUw���m1r�Z�)Y��a.�fz�S��D;>t���B�A!�����(;�������Lb�]ʑ�?��<�-��+he�F'��T��n���\Wv��yNe�Z��A��'���I�v�������o	g�H="�="k�H/*��R`�H�-�
-٩���p)���u 4ne�,-�p�sR�%�:qqv��UΚ���i��sĐ(��\�����G��>���?7���MÙ� ������˷i�~��#u�Bu�zR;����#��F�7Q����/i�J���B�,�48�K��Ӊ�B1�Z(�%B��k����"U7�N��SB��T
-�!���W�BO	��K(�%�\&��Z+�!�}�b�"a#*yP@�Z�-��SN��?z�b�
-�Z������Q�'Ox��TU��HJʹZT̹��1k?�4�J1qH(�jӌضc'w���i�"�9��hO��4�a�ڱ�!�
-�-�T�ؾ��X ǆ�x^�./����Lc1�X�<4掔c���;B��e��|�x�i�獓浘~/e�P`�6��H>,���W���OI�I�|�s�3���dS���c��J0u�V�Lk�9�Η!�p��..}�����T?@�]���Z�4��4��b��������1���{I_)3*�=���7�s��L�W�Ů��9����a�)7)W�Yn��PIRϥ�IsO�K�c�ˮ{q ~�z�<_FX����1��6�}����2�H��e���7oi�(�e�z�
-{�A�W;�P����)��/�U�PpT�PRqJA�+�x�����R7��j'^)H3��%`�`vq\���0�S��)���+��j��k�en��K��]Ɵ�)h�������&���2�o���6k?��-|�F�5��T�y�ǜѼ�↉�)+�� -T*h���Ex�ժ���<���th��dlx������}�� �z�Q��Ѧ�8+M�F���?�[���U���/�N��M��3`����Q��c\�|��(J��U���s���V@4˷ S������6����>��� ��� G�j�0��KRmf��a�T���{��fq����_���dmK���ʬmk���(���0;Wދ�����=Qs%���cgz�d8�
-c��R�8%���Mі��ȏfr���R�O������Wy�?f�9;�ɟU$��;���#yeE��ɪ 3��e���I;�&T~�\��rH��3���،R�m%��d�o
-%�RL�Vk�
-������Q��4+�da���=/p_#��<�n�\�Tak#l7�\.�m�X.�'}�D���!�˦%@(QWQ�VAlŕ��&[jm�>�x���Jqr筗ӱ��JEA8�@f�`3�o�s��ɕchMn�گ�����T����m>��x�������x��CK���[m���;��b��O�@0�=+�yZ�|^փ��7���T�|w�yi��JL�K�Y��S���V���Y<��Z�ԯ���HY�s��N?U�Og4Z�I�i��y^���RG��=3강x[?ӿ�RRDr�Pp��!�xpmu���%#t��*�8�h�#W����Q-
-w�0\�auF�]�}Ȱ�����N�9i�!PΦ���V�\�M^�x�j��A��k�����2s%��2E������ee�ρ�h\�����2uqQ�͙x�t3�*gBLt�̤YOѫ"��� �N>��9���)['�Gz�p��$қ���f�^+�k8�
-�_# <ŭ��>���^-��Z�09�0�#�k��v�FQk��&�F�^W��f��-�)j]��L�݂PS��W}���V)��nO���|��:IA�Ivۀ��d��N�z�T��:�C52G�7R+D?0���>*W*��aF2�BУ���J��侺��(j��~�6,�[�q�@�.�)L>_�3!s�Sҭ��:�&��:T�k %'���,(���Pu k�S^,���k5���츒���A��U|2d$UO������o�3HŞo���nQ�� iEe��Z�TJ�[�h���za�[�c�!�j��>�A�x��i<z��B�]���V������p�e�o����\T�s��s���`���i�7j�ף`>���y'��IK9t�̫,�B��O]l�P�CQ��tj��7	Y�T~T��X�a9K��j8�R�Q�h`�S#
-�O�v_�T,�j����h�]�ޫ*ژB��P�����	���k����!/yl�Α����R&�3��k�̼ӛy��Os2?�`uw����ͼ��yW��dZ;�e���wH��p�a,���g]B�z1&0d9�2�#M��.�<�*���N'�X�"�&��,gW�vd+�˲u��y4.��a�5=@��7�큅D��
-Ckoo�)C�Q�P���O+�P!x�J�P��|�D�_��;G�*v���G`�ީ���p�Hw-�S�����"-� ��Ž��Z\�vk�=Z�g���{���ڋY������Ԡs խ~�چl��{k���z{�)&�ܪZ9��G��~J�x'��ݢ?o�E�:�cU�[�{㖌^��f���:��';�|f4Rg+9WB�A�F�� y~4�<ی���[��8{�o�05���A�ϝ0�l>}ޭdNN��<i��aa��*R�t�H��A�(D�V���<RÜ���<��	# 	�tX.آ:��AD[�ѧ��b�腭���
-�>E�4�� ��\�U�EF'�;eĕ.m-�ݨ��B`��:��=�_����x��������I/0A�!$��A�5�rs,m�{P.���Q��VC�Ƥ�����К�x�>���Ɓ����ӆ/?/j�Y��44T�����sl��!HG��0�GB�������0�CC��r�҇��/���d�1D�T)}�ʮod�􍨔���S)��ة�w�@X-�����1X��G�#���:�TG��:��d�ձ�/k�O�I������A�P$��_p��Ȫs��7�?��(�BRs�+����lH�1�X�R�[���%� ���Y���Rg5;qVSs�4�.�/ԨS�AB;�5�X��<�߼_�Q�tz��P��H~�$�=�~����Z�W����j�}ڤ�>-}@�#��y?���m��roi��>���O��`�X�9�^m�҈J�-���I�Śk���Ęx@�1���c���6��3���2���G� ��R����MM��Ē4�%��6��ͤ���*��w�أ`��ǩeɺ<��e~|�j/�`��$?~mz؏y$�ʃ�M�Ƀ��O����̅j�����
-�~�p#�]�z���tMZK�l(����\��Š��l������򍗉�ʍ
-מ��:�[��C��|CX'0,�|]3o�c�����n�ct��,9ـ��` >���O6��*?�zӃ�N��~G�t1��[��l�:I���3��p��>M?.Ro��׾՟|�K�r��<�:���o#�{�}h��������pu�D)�9�ث%�xQ�3�L�E�~Ӵ�ڔH]X�]*��|f�p���3bR���O�*���:}����DP� ڴ�R������؀��IMY�Zن`�@� ��-��X�>%�WR��E�b�<���q���扵M�a�S��-��B�<�g�-4�Y�]R�� ���Q�����S�����Yi���#�IQH�,�XH�3��)���舿�#�`�y����+o�݀9�Y1���9W�l�jz�qsd��y�ٶ��]�RT)O�����nEu���C�����ā��E�³����;�_���J��k!�kǬv��k��l�}JUk[�E]��-my�ĸ����4�"UO�*'}Z��V� �'��|��9�W:]�sT*�D�jC:ڊI�F*�fRH�q}N��(t�C��E,bQM5>��hZ�p�3�dB ��!D���|����(�t^pe��=L��=L؎m@��P�ϊ���O���s�o�����/�����x�{gϚ5�����jhl�uWc��g5�gn�/~9������Y�1�s�ȳn������;n����*4�*��2��
\ No newline at end of file
diff --git skin/adminhtml/default/enterprise/boxes.css skin/adminhtml/default/enterprise/boxes.css
index 5a72f05..4bd9d34 100644
--- skin/adminhtml/default/enterprise/boxes.css
+++ skin/adminhtml/default/enterprise/boxes.css
@@ -1423,8 +1423,6 @@ ul.super-product-attributes { padding-left:15px; }
 .uploader .file-row-info .file-info-name  { font-weight:bold; }
 .uploader .file-row .progress-text { float:right; font-weight:bold; }
 .uploader .file-row .delete-button { float:right; }
-.uploader .buttons { float:left; }
-.uploader .flex { float:right; }
 .uploader .progress { border:1px solid #f0e6b7; background-color:#feffcc; }
 .uploader .error { border:1px solid #aa1717; background-color:#ffe6de; }
 .uploader .error .progress-text { padding-right:10px; }
