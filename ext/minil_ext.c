/*
 * minil - Mini Image Library
 */
#include <ruby.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "minil_ext.h"
#include "stb_image.h"
#include "stb_image_write.h"

static VALUE rb_cImage = Qundef;

static mil_Image_t*
mil_Image_new()
{
  mil_Image_t *image = (mil_Image_t*)malloc(sizeof(mil_Image_t));
  image->width  = 0;
  image->height = 0;
  image->stride = 0;
  image->size   = 0;
  image->data   = NULL;
  return image;
}

static mil_Image_t*
mil_Image_create(mil_Image_t *image, uint32_t width, uint32_t height)
{
  image->width  = width;
  image->height = height;
  image->stride = width * 4;
  image->size   = width * height * 4;
  image->data   = (uint8_t*)malloc(sizeof(uint8_t) * image->size);
  memset(image->data, 0, image->size);
  return image;
}

static mil_Image_t*
mil_Image_create_from_memory(mil_Image_t *image,
                             uint8_t *data, uint32_t width, uint32_t height)
{
  image->width  = width;
  image->height = height;
  image->stride = width * 4;
  image->size   = width * height * 4;
  image->data   = data;
  return image;
}

static mil_Image_t*
mil_Image_create_from_file(mil_Image_t *image, FILE* file)
{
  int32_t width;
  int32_t height;
  int32_t comp;
  uint8_t *data;
  data = stbi_load_from_file(file, &width, &height, &comp, STBI_rgb_alpha);
  return mil_Image_create_from_memory(image, data, width, height);
}

static mil_Image_t*
mil_Image_copy(mil_Image_t *dst_image, mil_Image_t *src_image)
{
  memcpy(dst_image, src_image, sizeof(mil_Image_t));
  memcpy(dst_image->data, src_image->data, src_image->size);
  return dst_image;
}

static bool
mil_Image_free(mil_Image_t* image)
{
  free(image->data);
  free(image);
}

static void
rb_Image_m_free(mil_Image_t *image)
{
  mil_Image_free(image);
}

static VALUE
rb_Image_m_alloc(VALUE klass)
{
  mil_Image_t *image = mil_Image_new();
  return Data_Wrap_Struct(klass, NULL, rb_Image_m_free, image);
}

static void
rb_Image_m_check_image(VALUE self)
{
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  if (!image->data) {
    rb_raise(rb_eRuntimeError, "this image data has not been allocated");
  }
}

/*
 * Image#initialize_copy(other)
 * @param [Image] other
 * @return [self]
 */
static VALUE
rb_Image_initialize_copy(VALUE self, VALUE other)
{
  rb_Image_m_check_image(other);
  mil_Image_t *src_image;
  mil_Image_t *dst_image;
  Data_Get_Struct(self,  mil_Image_t, dst_image);
  Data_Get_Struct(other, mil_Image_t, src_image);
  mil_Image_copy(dst_image, src_image);
  return self;
}

/*
 * Image#create(width, height)
 * @param [Integer] width
 * @param [Integer] height
 * @return [self]
 */
static VALUE
rb_Image_create(VALUE self, VALUE rb_v_width, VALUE rb_v_height)
{
  uint32_t width;
  uint32_t height;
  mil_Image_t *image;

  Data_Get_Struct(self, mil_Image_t, image);
  width  = NUM2INT(rb_v_width);
  height = NUM2INT(rb_v_height);
  mil_Image_create(image, width, height);
  return self;
}

/*
 * Image#load_file(filename)
 * @param [String] filename
 * @return [self]
 */
static VALUE
rb_Image_load_file(VALUE self, VALUE rb_v_filename)
{
  mil_Image_t *image;
  char *filename;
  FILE *file;

  Data_Get_Struct(self, mil_Image_t, image);
  filename = StringValueCStr(rb_v_filename);
  file = fopen(filename, "rb");
  if (file) {
    mil_Image_create_from_file(image, file);
    fclose(file);
  } else {
    rb_raise(rb_path2class("Errno::ENOENT"), "%s", filename);
  }
  return self;
}

/*
 * Image#save_file(filename)
 * @param [String] filename
 * @return [self]
 */
static VALUE
rb_Image_save_file(VALUE self, VALUE rb_v_filename)
{
  rb_Image_m_check_image(self);
  uint32_t width;
  uint32_t height;
  uint32_t stride;
  uint8_t *data;
  char *filename;
  char *extname;
  mil_Image_t *image;
  VALUE rb_v_extname;

  Data_Get_Struct(self, mil_Image_t, image);
  width  = image->width;
  height = image->height;
  stride = image->stride;
  data   = image->data;
  rb_v_extname = rb_funcall(rb_cFile, rb_intern("extname"), 1, rb_v_filename);
  filename = StringValueCStr(rb_v_filename);
  extname = StringValueCStr(rb_v_extname);

  if (!strcmp(extname, ".png")) {
    stbi_write_png(filename, width, height, STBI_rgb_alpha, data, stride);
  } else if (!strcmp(extname, ".bmp")) {
    stbi_write_bmp(filename, width, height, STBI_rgb_alpha, data);
  } else if (!strcmp(extname, ".tga")) {
    stbi_write_tga(filename, width, height, STBI_rgb_alpha, data);
  } else {
    rb_raise(rb_eArgError, "unsupported image file-format %s", extname);
  }
  return self;
}

/*
 * Image#blob
 * @return [Integer] pixel_data
 */
static VALUE
rb_Image_blob(VALUE self)
{
  rb_Image_m_check_image(self);
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  return rb_str_new(image->data, image->size);
}

/*
 * Image#width
 * @return [Integer] image_width
 */
static VALUE
rb_Image_width(VALUE self)
{
  rb_Image_m_check_image(self);
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  return INT2NUM(image->width);
}

/*
 * Image#height
 * @return [Integer] image_height
 */
static VALUE
rb_Image_height(VALUE self)
{
  rb_Image_m_check_image(self);
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  return INT2NUM(image->height);
}

/*
 * Image#size
 * @return [Integer] datasize
 */
static VALUE
rb_Image_size(VALUE self)
{
  rb_Image_m_check_image(self);
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  return INT2NUM(image->size);
}

/*
 * Image#set_pixel(x, y)
 * @param [Integer] x
 * @param [Integer] y
 *
 * @return [Integer] pixel
 *   pixel format 0xAARRGGBB
 */
static VALUE
rb_Image_get_pixel(VALUE self, VALUE rb_v_x, VALUE rb_v_y)
{
  rb_Image_m_check_image(self);
  uint32_t dst_pixel;
  uint8_t *src_pixel;
  uint32_t x;
  uint32_t y;
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);
  dst_pixel = 0x00000000;
  if (x < image->width && y < image->height) {
    src_pixel  = &image->data[(x + y * image->width) * 4];
    dst_pixel  = *src_pixel++ << 16;
    dst_pixel |= *src_pixel++ << 8;
    dst_pixel |= *src_pixel++ << 0;
    dst_pixel |= *src_pixel++ << 24;
  }
  return LONG2NUM((uint64_t)dst_pixel);
}

/*
 * Image#set_pixel(x, y, pixel)
 * @param [Integer] x
 * @param [Integer] y
 * @param [Integer] pixel
 *   pixel format 0xAARRGGBB
 *
 * @return [Integer] pixel
 *   pixel format 0xAARRGGBB
 */
static VALUE
rb_Image_set_pixel(VALUE self, VALUE rb_v_x, VALUE rb_v_y, VALUE rb_v_pixel)
{
  rb_Image_m_check_image(self);
  uint32_t src_pixel;
  uint8_t *dst_pixel;
  uint32_t x;
  uint32_t y;
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);
  src_pixel = (uint32_t)NUM2LONG(rb_v_pixel);
  if (x < image->width && y < image->height) {
    dst_pixel    = &image->data[(x + y * image->width) * 4];
    *dst_pixel++ = src_pixel >> 16 & 0xFF;
    *dst_pixel++ = src_pixel >> 8  & 0xFF;
    *dst_pixel++ = src_pixel >> 0  & 0xFF;
    *dst_pixel++ = src_pixel >> 24 & 0xFF;
  }
  return LONG2NUM((uint64_t)src_pixel);
}

/*
 * Image#inspect
 * @return [String] inspect_string
 */
static VALUE
rb_Image_inspect(VALUE self)
{
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  char str[256];
  snprintf(str, sizeof(str),
           "<%s width: %d, height: %d>",
           rb_obj_classname(self), image->width, image->height);
  return rb_str_new2(str);
}

void Init_minil_ext(void)
{
  rb_cImage = rb_define_class("Image", rb_cObject);
  rb_define_alloc_func(rb_cImage, rb_Image_m_alloc);
  rb_define_private_method(rb_cImage, "initialize_copy", rb_Image_initialize_copy, 1);
  rb_define_method(rb_cImage, "create",    rb_Image_create,    2);
  rb_define_method(rb_cImage, "load_file", rb_Image_load_file, 1);
  rb_define_method(rb_cImage, "save_file", rb_Image_save_file, 1);

  rb_define_method(rb_cImage, "height",    rb_Image_height,    0);
  rb_define_method(rb_cImage, "width",     rb_Image_width,     0);
  rb_define_method(rb_cImage, "size",      rb_Image_size,      0);

  rb_define_method(rb_cImage, "blob",      rb_Image_blob,      0);

  rb_define_method(rb_cImage, "get_pixel", rb_Image_get_pixel, 2);
  rb_define_method(rb_cImage, "set_pixel", rb_Image_set_pixel, 3);

  rb_define_method(rb_cImage, "inspect",   rb_Image_inspect, 0);

  rb_define_alias(rb_cImage, "[]", "get_pixel");
  rb_define_alias(rb_cImage, "[]=", "set_pixel");
}