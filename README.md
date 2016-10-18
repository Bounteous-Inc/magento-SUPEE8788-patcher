# Magento SUPEE-8788 Patch Applier

The following batch script attempts to automated the process required to apply patch SUPEE-8788. According to the official communicates the process for applying SUPEE-8788 is as follows:


- Revert SUPEE-1533 if it has already been installed.
- Deploy SUPEE-3941 if it hasn’t already been installed.
- Install the new SUPEE-8788 v3 patch. 

Patch SUPEE-8788 patch includes SUPEE-1533, so the is no need to worry about re-installing it.

## Usage 

- Copy the contents of this repository on the Magento root
- Run `chmod +x magento-8788-patcher.sh`
- Run `./magento-8788-patcher.sh`

## Known Issues

- Test mode is broken since the Magento patches don't actually implement the **dry-run** method 
