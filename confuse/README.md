# 混淆脚本介绍


## 一、介绍

> 混淆脚本主要分两部分：**代码混淆**和**资源混淆**。
>>
> 其中，**代码混淆**目前仅支持`Lua`脚本，如需添加其他编程语言，请自行添加实现。
>>
> **资源混淆**由两部分构成：其一、**修改图片MD5**；其二、**添加垃圾文件**，目前垃圾文件支持多种文件格式并写入随机句子，如需针对不同文件格式写入对应格式的内容，可自行扩展。


## 二、结构

1. **Lua代码混淆**

    - `lexer.lua`: lua词法解析器

    - `RandomWord.lua`: 随机单词库
    
    - `system.lua`: 判断当前系统
    
    - `parser.lua`: 生成混淆代码

2. **混淆器**

    - `ConfuseConstant.py`: 混淆配置

    - `RubbishPng.py`: 生成垃圾图片

        - 需要使用`pip`安装第三方包：`pip install Pillow`， 或去官网下载对应`Python`版本的[PIL安装包](http://www.pythonware.com/products/pil/#pil117)进行安装
    
    - `ConfuseMd5.py`: 修改图片资源MD5

    - `Confuse.py`: 混淆集合工具（包含代码混淆和资源混淆）

        - 需要使用`pip`安装第三方包：`pip install RandomWords`


## 三、使用

> 首先查看 `ConfuseConstant.py`，确认混淆配置是否正确；
>>
> 然后双击或在控制台运行 `Confuse.py`，选择混淆代码或资源；
>>
> 最后等待脚本运行完成即可。