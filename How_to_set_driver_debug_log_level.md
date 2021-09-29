How to set driver debug log level

1
Introduction.

1.1 The driver’s debug log level is as follows,
enum {
_DRV_NONE_ = 0,
_DRV_ALWAYS_ = 1,
_DRV_ERR_ = 2,
_DRV_WARNING_ = 3,
_DRV_INFO_ = 4,
_DRV_DEBUG_ = 5,
_DRV_MAX_ = 6
};

1.2 The default log level is “_DRV_NONE_”.

1.3 The default compiling flag is “CONFIG_RTW_DEBUG”, which is defined in
“Makefile”.

2
How to change debug log level during runtime.

2.1 Use the following command to set different log level.
# echo x > /proc/net/rtl8821au/log_level

x : is a number mapping to log level in driver.

For example, if you want to change to log level to “_DRV_ERR_”, please
execute the command below,
# echo 2 > /proc/net/rtk8821au/log_level

3
How to change debug log level during inserting driver module.
For example for change log level to _DRV_WARNING_,
# insmod 8821au.ko rtw_drv_log_level=3

4
How to disable all debug log level during runtime and inserting driver module.

4.1 during runtime, please execute the command below,
# echo 0 > /proc/net/rtk8821au/log_level

4.2 during inserting driver module , please execute the command below,
# insmod 8821au.ko rtw_drv_log_level=05

How to check current log level during runtime

Use the following command to check log level,
# cat /proc/net/rtl8821au/log_level

drv_log_level:4
_DRV_NONE_ = 0
_DRV_ALWAYS_ = 1
_DRV_ERR_ = 2
_DRV_WARNING_ = 3
_DRV_INFO_ = 4
_DRV_DEBUG_ = 5
_DRV_MAX_ = 6
This example shows the current log level is 4 (_DRV_INFO_).

6
How to change debug log level during compiling time.

6.1 In Makefile, please look for “CONFIG_RTW_LOG_LEVEL”, and then you can
modify its value to proper debug log level during compiling time.

7
How to disable all debug log during compiling time.

7.1 There are two methods to disable debug log.

7.1.1 Method A: in Makefile, please look for “CONFIG_RTW_DEBUG = y”,
and then change the “y” to “n”.

7.1.2 Method B: also in Makefile, please look for
“CONFIG_RTW_LOG_LEVEL”, and then change the default value to 0

