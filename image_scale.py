import os
import sys
from PIL import Image

image_scale_help = """帮助
· 本脚本用于PNG/JPG图片批量缩放，需要安装 Pillow 依赖模块；
· 参数1：参照图片目录，支持相对路径和绝对路径；
· 参数2~∞: 约定宽度，允许传入多个；
· 完成之后，转换后的图片将存储在与参照图片目录同级的 out 目录下；
· 示例：python image_scale.py ./image 32 64 128"""

image_dir = "image"
out_dir = "out"


def get_mode(ext):
    if ext == ".png":
        return "RGBA"
    else:
        return "RGB"


def get_format(ext):
    if ext == ".png":
        return "PNG"
    else:
        return "JPEG"


def convert(file_name, ext_name, real_width=64):
    ori_name = os.path.join(image_dir, "{0}{1}".format(file_name, ext_name))
    out_name = os.path.join(out_dir, "{0}x{1}{2}".format(
        file_name, real_width, ext_name))
    ori_img = Image.open(ori_name).convert(get_mode(ext_name))
    target_scale = real_width / ori_img.width
    width = int(ori_img.height * target_scale)
    height = int(ori_img.width * target_scale)
    image = ori_img.resize((width, height))
    image.save(out_name, get_format(ext_name))
    print(" ✔ " + out_name)


def is_valid_ext(ext):
    return ext == ".png" or ext == ".jpg"


def list_images(width):
    for file_name in os.listdir(image_dir):
        base, ext = os.path.splitext(file_name)
        ext = ext.lower()
        if ext and is_valid_ext(ext):
            convert(base, ext, width)


def try_convert_in_width(width):
    try:
        width = int(width)
    except Exception as e:
        print("无效的约定宽度：" + width)
        width = None

    if width is not None:
        list_images(width)


if __name__ == "__main__":
    l = len(sys.argv)

    if l >= 2:
        image_dir = os.path.realpath(sys.argv[1])
        root_dir, base_dir = os.path.split(image_dir)
        out_dir = os.path.join(root_dir, "out")
        if not os.path.exists(image_dir):
            print("请确认图片目录是否有效：" + sys.argv[1])
            sys.exit()

    os.makedirs(out_dir, exist_ok=True)

    if l >= 3:
        for i in range(l - 2):
            width = sys.argv[i + 2]
            try_convert_in_width(width)
    else:
        print(image_scale_help)
