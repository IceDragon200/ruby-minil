/*
 * minil - Mini Image Library
 */
#include <ruby.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <assert.h>
#include "minil_ext.h"
#include "stb_image.h"
#include "stb_image_write.h"

struct mil_Color {
  union {
    struct {
      //uint8_t a, r, g, b;
      uint8_t b, g, r, a;
    };
    uint32_t value;
  };
};

static VALUE rb_cImage = Qundef;

static struct mil_Color
mil_Color_from_ruby(VALUE rb_color)
{
  struct mil_Color color;
  color.value = 0;
  switch(TYPE(rb_color)) {
    case RUBY_T_ARRAY: {
      const long len = RARRAY_LEN(rb_color);
      if (len >= 3 && len <= 4) {
        color.a = 0xFF;
        if (len == 4) {
          color.a = NUM2INT(rb_ary_entry(rb_color, 3)) & 0xFF;
        }
        color.r = NUM2INT(rb_ary_entry(rb_color, 0)) & 0xFF;
        color.g = NUM2INT(rb_ary_entry(rb_color, 1)) & 0xFF;
        color.b = NUM2INT(rb_ary_entry(rb_color, 2)) & 0xFF;
      } else {
        rb_raise(rb_eArgError, "Expected an Array of size 3 or 4");
      }
    } break;
    case RUBY_T_FIXNUM:
    case RUBY_T_BIGNUM: {
      color.value = NUM2ULONG(rb_color) & 0xFFFFFFFF;
    } break;
    default: {
      rb_raise(rb_eTypeError, "Expected Array, Bignum or Fixnum");
    } break;
  }
  return color;
}

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
  dst_image->data = (uint8_t*)malloc(sizeof(uint8_t) * dst_image->size);
  memcpy(dst_image->data, src_image->data, src_image->size);
  return dst_image;
}

static void
mil_Image_free(mil_Image_t *image)
{
  free(image->data);
  free(image);
}

#define point_in_image(image, x, y) (x >= 0 && x < image->width && y >=0 && y < image->height)

static uint32_t
mil_Image_get_pixel(mil_Image_t *image, int32_t x, int32_t y)
{
  uint32_t dest_pixel = 0x00000000;
  if (point_in_image(image, x, y)) {
    uint8_t *src_pixel = &image->data[(x + y * image->width) * 4];
    dest_pixel  = *src_pixel++ << 16;
    dest_pixel |= *src_pixel++ << 8;
    dest_pixel |= *src_pixel++ << 0;
    dest_pixel |= *src_pixel++ << 24;
  }
  return dest_pixel;
}

static void
mil_Image_set_pixel(mil_Image_t *image, int32_t x, int32_t y, uint32_t src_pixel)
{
  if (point_in_image(image, x, y)) {
    uint8_t *dest_pixel    = &image->data[(x + y * image->width) * 4];
    *dest_pixel++ = src_pixel >> 16 & 0xFF;
    *dest_pixel++ = src_pixel >> 8  & 0xFF;
    *dest_pixel++ = src_pixel >> 0  & 0xFF;
    *dest_pixel++ = src_pixel >> 24 & 0xFF;
  }
}

static void
Image_m_free(mil_Image_t *image)
{
  mil_Image_free(image);
}

static VALUE
Image_m_alloc(VALUE klass)
{
  mil_Image_t *image = mil_Image_new();
  return Data_Wrap_Struct(klass, NULL, Image_m_free, image);
}

static void
Image_m_check_image(VALUE self)
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
Image_initialize_copy(VALUE self, VALUE other)
{
  Image_m_check_image(other);
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
Image_create(VALUE self, VALUE rb_v_width, VALUE rb_v_height)
{
  int32_t width;
  int32_t height;
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
Image_load_file(VALUE self, VALUE rb_v_filename)
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
    if (!image->data) {
      rb_raise(rb_eRuntimeError, "Image %s failed to load properly.", filename);
    }
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
Image_save_file(VALUE self, VALUE rb_v_filename)
{
  Image_m_check_image(self);
  uint32_t width;
  uint32_t height;
  uint32_t stride;
  uint8_t *data;
  char *filename;
  char *extname;
  mil_Image_t *image;
  VALUE rb_v_extname;
  int res = 1;

  Data_Get_Struct(self, mil_Image_t, image);
  width  = image->width;
  height = image->height;
  stride = image->stride;
  data   = image->data;
  rb_v_extname = rb_funcall(rb_cFile, rb_intern("extname"), 1, rb_v_filename);
  filename = StringValueCStr(rb_v_filename);
  extname = StringValueCStr(rb_v_extname);

  if (!strcmp(extname, ".png")) {
    res = stbi_write_png(filename, width, height, STBI_rgb_alpha, data, stride);
  } else if (!strcmp(extname, ".bmp")) {
    res = stbi_write_bmp(filename, width, height, STBI_rgb_alpha, data);
  } else if (!strcmp(extname, ".tga")) {
    res = stbi_write_tga(filename, width, height, STBI_rgb_alpha, data);
  } else if (!strcmp(extname, ".hdr")) {
    float* data_f32 = calloc(image->size, sizeof(float));
    for (size_t i = 0; i < image->size; ++i) {
      data_f32[i] = data[i] / 255.0;
    }
    res = stbi_write_hdr(filename, width, height, STBI_rgb_alpha, data_f32);
    free(data_f32);
  } else if (!strcmp(extname, ".jpg") || !strcmp(extname, ".jpeg")) {
    res = stbi_write_jpg(filename, width, height, STBI_rgb_alpha, data, 100);
  } else {
    rb_raise(rb_eArgError, "unsupported image file-format %s", extname);
  }
  if (!res) {
    rb_raise(rb_eArgError, "save failed %s", filename);
  }
  return self;
}

/*
 * Image#blob
 * @return [Integer] pixel_data
 */
static VALUE
Image_blob(VALUE self)
{
  Image_m_check_image(self);
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  return rb_str_new((char*)image->data, (int32_t)image->size);
}

/*
 * Image#width
 * @return [Integer] image_width
 */
static VALUE
Image_width(VALUE self)
{
  Image_m_check_image(self);
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  return INT2NUM(image->width);
}

/*
 * Image#height
 * @return [Integer] image_height
 */
static VALUE
Image_height(VALUE self)
{
  Image_m_check_image(self);
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  return INT2NUM(image->height);
}

/*
 * Image#size
 * @return [Integer] datasize
 */
static VALUE
Image_size(VALUE self)
{
  Image_m_check_image(self);
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  return INT2NUM(image->size);
}

/*
 * Image#get_pixel(x, y)
 * @param [Integer] x
 * @param [Integer] y
 *
 * @return [Integer] pixel
 *   pixel format 0xAARRGGBB
 */
static VALUE
Image_get_pixel(VALUE self, VALUE rb_v_x, VALUE rb_v_y)
{
  Image_m_check_image(self);
  int x, y;
  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);
  return LONG2NUM((uint64_t)mil_Image_get_pixel(image, x, y));
}

/*
 * Image#set_pixel(x, y, pixel)
 * @param [Integer] x
 * @param [Integer] y
 * @param [Integer] pixel
 *   pixel format 0xAARRGGBB
 * @return [self]
 */
static VALUE
Image_set_pixel(VALUE self, VALUE rb_v_x, VALUE rb_v_y, VALUE rb_v_pixel)
{
  Image_m_check_image(self);
  uint32_t src_pixel;
  int x, y;

  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);

  src_pixel = mil_Color_from_ruby(rb_v_pixel).value;

  mil_Image_set_pixel(image, x, y, src_pixel);
  return self;
}

static bool
adjust_invert_rect(int *x, int *y, int *w, int *h)
{
  if (*w < 0) {
    *x += *w;
    *w = -(*w);
  }

  if (*h < 0) {
    *y += *h;
    *h = -(*h);
  }

  return true;
}

static bool
adjust_rect_to_fit_texture(mil_Image_t *image, int *x, int *y, int *w, int *h)
{
  if (image->width < *x || image->height < *y) return false;
  if (*w == 0 || *h == 0) return false;
  adjust_invert_rect(x, y, w, h);
  //if (*w <= 0 || *h <= 0) return false;

  if (*x < 0) {
    *w += *x;
    *x = 0;
  }
  if (*y < 0) {
    *h += *y;
    *y = 0;
  }

  if ((*x + *w) > image->width) *w -= (*x + *w) - image->width;
  if ((*y + *h) > image->height) *h -= (*y + *h) - image->height;

  if (*w <= 0 || *h <= 0) return false;

  return true;
}

static bool
adjust_rect_to_fit_texture_blit(mil_Image_t *src_image, mil_Image_t *dest_image,
  int *x, int *y, int *sx, int *sy, int *sw, int *sh)
{
  if (!adjust_rect_to_fit_texture(src_image, sx, sy, sw, sh)) {
    return false;
  }
  if (!adjust_rect_to_fit_texture(dest_image, x, y, sw, sh)) {
    return false;
  }
  return true;
}

static VALUE
Image_fill_rect(VALUE self, VALUE rb_v_x, VALUE rb_v_y,
                               VALUE rb_v_w, VALUE rb_v_h,
                               VALUE rb_v_color)
{
  Image_m_check_image(self);
  struct mil_Color color;
  uint8_t *pixels;
  int x, y, w, h;
  int64_t padding;

  mil_Image_t *image;
  Data_Get_Struct(self, mil_Image_t, image);
  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);
  w = NUM2INT(rb_v_w);
  h = NUM2INT(rb_v_h);

  if (!adjust_rect_to_fit_texture(image, &x, &y, &w, &h)) {
    return self;
  }

  color = mil_Color_from_ruby(rb_v_color);

  pixels = &image->data[(x + y * image->width) * 4];

  padding = (image->width - w) * 4;

  for (int i = 0; i < h; ++i, pixels += padding) {
    for (int j = 0; j < w; ++j) {
      *pixels++ = color.r;
      *pixels++ = color.g;
      *pixels++ = color.b;
      *pixels++ = color.a;
    }
  }

  return self;
}

/*
 * Image#blit
 * @param [Image] image
 * @param [Integer] x
 * @param [Integer] y
 * @param [Integer] src_x
 * @param [Integer] src_y
 * @param [Integer] src_width
 * @param [Integer] src_height
 * @return [self]
 */
static VALUE
Image_blit(VALUE self, VALUE rb_v_img, VALUE rb_v_x, VALUE rb_v_y,
              VALUE rb_v_sx, VALUE rb_v_sy, VALUE rb_v_sw, VALUE rb_v_sh)
{
  Image_m_check_image(self);
  Image_m_check_image(rb_v_img);

  uint8_t *src_pixels;
  uint8_t *dest_pixels;
  int32_t x;
  int32_t y;
  int32_t sx;
  int32_t sy;
  int32_t sw;
  int32_t sh;

  int32_t src_padding;
  int32_t dest_padding;

  mil_Image_t *src_image;
  mil_Image_t *dest_image;

  Data_Get_Struct(rb_v_img, mil_Image_t, src_image);
  Data_Get_Struct(self, mil_Image_t, dest_image);

  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);
  sx = NUM2INT(rb_v_sx);
  sy = NUM2INT(rb_v_sy);
  sw = NUM2INT(rb_v_sw);
  sh = NUM2INT(rb_v_sh);

  if (!adjust_rect_to_fit_texture_blit(src_image, dest_image, &x, &y, &sx, &sy, &sw, &sh)) {
    return self;
  }

  src_pixels = &src_image->data[(sx + sy * src_image->width) * 4];
  dest_pixels = &dest_image->data[(x + y * dest_image->width) * 4];

  src_padding  = src_image->width * 4;
  dest_padding = dest_image->width * 4;

  // Debug stuff
  //printf("blit(x: %d, y: %d, sx: %d, sy: %d, sw: %d, sh: %d, sp: %d, dp: %d)\n",
  //       x, y, sx, sy, sw, sh, src_padding, dest_padding);
  for (int i = 0; i < sh; ++i, src_pixels += src_padding, dest_pixels += dest_padding) {
    memcpy(dest_pixels, src_pixels, sw * 4);
  }
  return self;
}

/*
 * Image#alpha_blit
 * @param [Image] image
 * @param [Integer] x
 * @param [Integer] y
 * @param [Integer] src_x
 * @param [Integer] src_y
 * @param [Integer] src_width
 * @param [Integer] src_height
 * @param [Integer] alpha
 * @return [self]
 */
static VALUE
Image_alpha_blit(VALUE self, VALUE rb_v_img, VALUE rb_v_x, VALUE rb_v_y,
              VALUE rb_v_sx, VALUE rb_v_sy, VALUE rb_v_sw, VALUE rb_v_sh,
              VALUE rb_v_alpha)
{
  Image_m_check_image(self);
  Image_m_check_image(rb_v_img);

  uint8_t *src_pixels;
  uint8_t *dest_pixels;
  int32_t x;
  int32_t y;
  int32_t sx;
  int32_t sy;
  int32_t sw;
  int32_t sh;
  int32_t alpha;

  int32_t src_padding;
  int32_t dest_padding;

  mil_Image_t *src_image;
  mil_Image_t *dest_image;

  Data_Get_Struct(rb_v_img, mil_Image_t, src_image);
  Data_Get_Struct(self, mil_Image_t, dest_image);

  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);
  sx = NUM2INT(rb_v_sx);
  sy = NUM2INT(rb_v_sy);
  sw = NUM2INT(rb_v_sw);
  sh = NUM2INT(rb_v_sh);
  alpha = NUM2INT(rb_v_alpha);

  alpha = mil_int_min(255, mil_int_max(alpha, 0));

  if (!adjust_rect_to_fit_texture_blit(src_image, dest_image, &x, &y, &sx, &sy, &sw, &sh)) {
    return self;
  }

  src_pixels = &src_image->data[(sx + sy * src_image->width) * 4];
  dest_pixels = &dest_image->data[(x + y * dest_image->width) * 4];

  src_padding = (src_image->width - sw) * 4;
  dest_padding = (dest_image->width - sw) * 4;

  // Debug stuff
  //printf("alpha_blit(x: %d, y: %d, sx: %d, sy: %d, sw: %d, sh: %d, sp: %d, dp: %d, alpha: %d)\n",
  //       x, y, sx, sy, sw, sh, src_padding, dest_padding, alpha);

  for (int i = 0; i < sh; ++i, src_pixels += src_padding, dest_pixels += dest_padding) {
    for (int j = 0; j < sw; ++j) {
      // Sadly, alpha is the 4th value, so you I have to fetch it first
      // and then set it after processing the first 3 channels
      // FML
      uint8_t a1 = dest_pixels[3];
      uint8_t beta = mil_int_min(255, (src_pixels[3] * alpha) >> 8);
      uint8_t a = beta > a1 ? beta : a1;

      for (int k = 0; k < 3; ++k) {
        uint8_t d = *dest_pixels;
        (*dest_pixels++) = mil_int_min(255, mil_int_max(d + ((((*src_pixels++) - d) * beta) >> 8), 0));
      }
      (*dest_pixels++) = a;
      ++src_pixels;
    }
  }

  return self;
}

/*
 * Image#inspect
 * @return [String] inspect_string
 */
static VALUE
Image_inspect(VALUE self)
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
  VALUE rb_mMinil = rb_define_module("Minil");
  rb_cImage = rb_define_class_under(rb_mMinil, "Image", rb_cObject);

  rb_define_alloc_func(rb_cImage, Image_m_alloc);
  rb_define_private_method(rb_cImage, "initialize_copy", Image_initialize_copy, 1);
  rb_define_method(rb_cImage, "create",    Image_create,    2);
  rb_define_method(rb_cImage, "load_file", Image_load_file, 1);
  rb_define_method(rb_cImage, "save_file", Image_save_file, 1);

  rb_define_method(rb_cImage, "height",    Image_height,    0);
  rb_define_method(rb_cImage, "width",     Image_width,     0);
  rb_define_method(rb_cImage, "size",      Image_size,      0);

  rb_define_method(rb_cImage, "blob",      Image_blob,      0);

  rb_define_method(rb_cImage, "get_pixel", Image_get_pixel, 2);
  rb_define_method(rb_cImage, "set_pixel", Image_set_pixel, 3);

  rb_define_method(rb_cImage, "fill_rect", Image_fill_rect, 5);

  rb_define_method(rb_cImage, "blit",       Image_blit,       7);
  rb_define_method(rb_cImage, "alpha_blit", Image_alpha_blit, 8);

  rb_define_method(rb_cImage, "inspect",    Image_inspect, 0);

  rb_define_alias(rb_cImage, "[]", "get_pixel");
  rb_define_alias(rb_cImage, "[]=", "set_pixel");
}
