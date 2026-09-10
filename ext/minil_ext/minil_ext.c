/*
 * minil - Mini Image Library
 */
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#endif
#include <ruby.h>
#if defined(__GNUC__) || defined(__clang__)
#pragma GCC diagnostic pop
#endif
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <assert.h>
#include <limits.h>
#include "minil_ext.h"
#include "stb_image.h"
#include "stb_image_write.h"

struct mil_Color {
  uint32_t value;
};

typedef char mil_Color_must_be_32_bits[
  sizeof(struct mil_Color) == sizeof(uint32_t) ? 1 : -1
];

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
        uint32_t a = 0xFF;
        if (len == 4) {
          a = mil_int_min(255, mil_int_max(0, NUM2INT(rb_ary_entry(rb_color, 3))));
        }
        uint32_t r = mil_int_min(255, mil_int_max(0, NUM2INT(rb_ary_entry(rb_color, 0))));
        uint32_t g = mil_int_min(255, mil_int_max(0, NUM2INT(rb_ary_entry(rb_color, 1))));
        uint32_t b = mil_int_min(255, mil_int_max(0, NUM2INT(rb_ary_entry(rb_color, 2))));
        color.value = a << 24 | r << 16 | g << 8 | b;
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
  if (!image) {
    rb_memerror();
  }
  image->width  = 0;
  image->height = 0;
  image->stride = 0;
  image->size   = 0;
  image->data   = NULL;
  return image;
}

static mil_Image_t*
mil_Image_create(mil_Image_t *image, int32_t width, int32_t height)
{
  size_t size;
  uint8_t *data;

  if (width <= 0 || height <= 0) {
    rb_raise(rb_eArgError, "image dimensions must be positive");
  }
  if (width > INT_MAX / 4 ||
      (size_t)height > SIZE_MAX / ((size_t)width * 4)) {
    rb_raise(rb_eArgError, "image dimensions are too large");
  }

  size = (size_t)width * (size_t)height * 4;
  data = (uint8_t*)malloc(size);
  if (!data) {
    rb_memerror();
  }
  memset(data, 0, size);

  free(image->data);
  image->width  = width;
  image->height = height;
  image->stride = (uint32_t)width * 4;
  image->size   = size;
  image->data   = data;
  return image;
}

static bool
mil_Image_create_from_memory(mil_Image_t *image,
                             uint8_t *data, int32_t width, int32_t height)
{
  if (!data || width <= 0 || height <= 0 ||
      width > INT_MAX / 4 ||
      (size_t)height > SIZE_MAX / ((size_t)width * 4)) {
    free(data);
    return false;
  }

  free(image->data);
  image->width  = width;
  image->height = height;
  image->stride = (uint32_t)width * 4;
  image->size   = (size_t)width * (size_t)height * 4;
  image->data   = data;
  return true;
}

static bool
mil_Image_create_from_file(mil_Image_t *image, FILE* file)
{
  int32_t width = 0;
  int32_t height = 0;
  int32_t comp = 0;
  uint8_t *data;
  data = stbi_load_from_file(file, &width, &height, &comp, STBI_rgb_alpha);
  return mil_Image_create_from_memory(image, data, width, height);
}

static mil_Image_t*
mil_Image_copy(mil_Image_t *dst_image, mil_Image_t *src_image)
{
  if (dst_image == src_image) {
    return dst_image;
  }

  uint8_t *data = (uint8_t*)malloc(src_image->size);
  if (!data) {
    rb_memerror();
  }
  memcpy(data, src_image->data, src_image->size);
  free(dst_image->data);
  memcpy(dst_image, src_image, sizeof(mil_Image_t));
  dst_image->data = data;
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
    size_t offset = ((size_t)x + (size_t)y * (size_t)image->width) * 4;
    uint8_t *src_pixel = &image->data[offset];
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
    size_t offset = ((size_t)x + (size_t)y * (size_t)image->width) * 4;
    uint8_t *dest_pixel = &image->data[offset];
    *dest_pixel++ = src_pixel >> 16 & 0xFF;
    *dest_pixel++ = src_pixel >> 8  & 0xFF;
    *dest_pixel++ = src_pixel >> 0  & 0xFF;
    *dest_pixel++ = src_pixel >> 24 & 0xFF;
  }
}

static void
Image_m_free(void *ptr)
{
  mil_Image_free((mil_Image_t*)ptr);
}

static size_t
Image_m_memsize(const void *ptr)
{
  const mil_Image_t *image = (const mil_Image_t*)ptr;
  return image ? sizeof(mil_Image_t) + image->size : 0;
}

static const rb_data_type_t mil_Image_data_type = {
  .wrap_struct_name = "Minil::Image",
  .function = {
    .dfree = Image_m_free,
    .dsize = Image_m_memsize,
  },
  .flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

#define get_image_struct(obj, image) \
  TypedData_Get_Struct(obj, mil_Image_t, &mil_Image_data_type, image)

static VALUE
Image_m_alloc(VALUE klass)
{
  mil_Image_t *image = mil_Image_new();
  return TypedData_Wrap_Struct(klass, &mil_Image_data_type, image);
}

static void
Image_m_check_image(VALUE self)
{
  mil_Image_t *image;
  get_image_struct(self, image);
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
  get_image_struct(self, dst_image);
  get_image_struct(other, src_image);
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

  get_image_struct(self, image);
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

  get_image_struct(self, image);
  filename = StringValueCStr(rb_v_filename);
  file = fopen(filename, "rb");
  if (file) {
    bool loaded = mil_Image_create_from_file(image, file);
    fclose(file);
    if (!loaded) {
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

  get_image_struct(self, image);
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
    if (image->size > SIZE_MAX / sizeof(float)) {
      rb_raise(rb_eRangeError, "image data is too large to encode as HDR");
    }
    float* data_f32 = calloc(image->size, sizeof(float));
    if (!data_f32) {
      rb_memerror();
    }
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
  get_image_struct(self, image);
  if (image->size > LONG_MAX) {
    rb_raise(rb_eRangeError, "image data is too large for a Ruby String");
  }
  return rb_str_new((char*)image->data, (long)image->size);
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
  get_image_struct(self, image);
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
  get_image_struct(self, image);
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
  get_image_struct(self, image);
  return SIZET2NUM(image->size);
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
  get_image_struct(self, image);
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
  get_image_struct(self, image);
  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);

  src_pixel = mil_Color_from_ruby(rb_v_pixel).value;

  mil_Image_set_pixel(image, x, y, src_pixel);
  return self;
}

static bool
adjust_invert_rect(int64_t *x, int64_t *y, int64_t *w, int64_t *h)
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
adjust_rect_to_fit_texture(mil_Image_t *image,
                           int64_t *x, int64_t *y, int64_t *w, int64_t *h)
{
  if (*w == 0 || *h == 0) return false;
  adjust_invert_rect(x, y, w, h);

  if (*x >= image->width || *y >= image->height) return false;

  if (*x < 0) {
    if (*x <= -*w) return false;
    *w += *x;
    *x = 0;
  }
  if (*y < 0) {
    if (*y <= -*h) return false;
    *h += *y;
    *y = 0;
  }

  if (*w > image->width - *x) *w = image->width - *x;
  if (*h > image->height - *y) *h = image->height - *y;

  if (*w <= 0 || *h <= 0) return false;

  return true;
}

static bool
adjust_rect_to_fit_texture_blit(mil_Image_t *src_image, mil_Image_t *dest_image,
  int64_t *x, int64_t *y, int64_t *sx, int64_t *sy, int64_t *sw, int64_t *sh)
{
  if (*sw == 0 || *sh == 0) return false;
  adjust_invert_rect(sx, sy, sw, sh);

  if (*sx < 0) {
    int64_t delta = -*sx;
    *sx = 0;
    *x += delta;
    *sw -= delta;
  }
  if (*sy < 0) {
    int64_t delta = -*sy;
    *sy = 0;
    *y += delta;
    *sh -= delta;
  }
  if (*x < 0) {
    int64_t delta = -*x;
    *x = 0;
    *sx += delta;
    *sw -= delta;
  }
  if (*y < 0) {
    int64_t delta = -*y;
    *y = 0;
    *sy += delta;
    *sh -= delta;
  }

  if (*sw <= 0 || *sh <= 0 ||
      *sx >= src_image->width || *sy >= src_image->height ||
      *x >= dest_image->width || *y >= dest_image->height) return false;

  if (*sw > src_image->width - *sx) *sw = src_image->width - *sx;
  if (*sh > src_image->height - *sy) *sh = src_image->height - *sy;
  if (*sw > dest_image->width - *x) *sw = dest_image->width - *x;
  if (*sh > dest_image->height - *y) *sh = dest_image->height - *y;

  if (*sw <= 0 || *sh <= 0) return false;
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
  int64_t x, y, w, h;
  size_t padding;

  mil_Image_t *image;
  get_image_struct(self, image);
  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);
  w = NUM2INT(rb_v_w);
  h = NUM2INT(rb_v_h);

  if (!adjust_rect_to_fit_texture(image, &x, &y, &w, &h)) {
    return self;
  }

  color = mil_Color_from_ruby(rb_v_color);
  uint8_t r = color.value >> 16 & 0xFF;
  uint8_t g = color.value >> 8 & 0xFF;
  uint8_t b = color.value & 0xFF;
  uint8_t a = color.value >> 24 & 0xFF;

  pixels = &image->data[((size_t)x + (size_t)y * (size_t)image->width) * 4];

  padding = ((size_t)image->width - (size_t)w) * 4;

  for (int64_t i = 0; i < h; ++i, pixels += padding) {
    for (int64_t j = 0; j < w; ++j) {
      *pixels++ = r;
      *pixels++ = g;
      *pixels++ = b;
      *pixels++ = a;
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
  int64_t x;
  int64_t y;
  int64_t sx;
  int64_t sy;
  int64_t sw;
  int64_t sh;

  size_t src_stride;
  size_t dest_stride;
  uint8_t *copy = NULL;

  mil_Image_t *src_image;
  mil_Image_t *dest_image;

  get_image_struct(rb_v_img, src_image);
  get_image_struct(self, dest_image);

  x = NUM2INT(rb_v_x);
  y = NUM2INT(rb_v_y);
  sx = NUM2INT(rb_v_sx);
  sy = NUM2INT(rb_v_sy);
  sw = NUM2INT(rb_v_sw);
  sh = NUM2INT(rb_v_sh);

  if (!adjust_rect_to_fit_texture_blit(src_image, dest_image, &x, &y, &sx, &sy, &sw, &sh)) {
    return self;
  }

  src_pixels = &src_image->data[((size_t)sx + (size_t)sy * (size_t)src_image->width) * 4];
  dest_pixels = &dest_image->data[((size_t)x + (size_t)y * (size_t)dest_image->width) * 4];

  src_stride = src_image->stride;
  dest_stride = dest_image->stride;

  if (src_image == dest_image &&
      x < sx + sw && x + sw > sx && y < sy + sh && y + sh > sy) {
    size_t copy_stride = (size_t)sw * 4;
    copy = (uint8_t*)malloc(copy_stride * (size_t)sh);
    if (!copy) {
      rb_memerror();
    }
    for (int64_t i = 0; i < sh; ++i) {
      memcpy(copy + (size_t)i * copy_stride,
             src_pixels + (size_t)i * src_stride,
             copy_stride);
    }
    src_pixels = copy;
    src_stride = copy_stride;
  }

  // Debug stuff
  //printf("blit(x: %d, y: %d, sx: %d, sy: %d, sw: %d, sh: %d, sp: %d, dp: %d)\n",
  //       x, y, sx, sy, sw, sh, src_padding, dest_padding);
  for (int64_t i = 0; i < sh; ++i, src_pixels += src_stride, dest_pixels += dest_stride) {
    memcpy(dest_pixels, src_pixels, sw * 4);
  }
  free(copy);
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
  int64_t x;
  int64_t y;
  int64_t sx;
  int64_t sy;
  int64_t sw;
  int64_t sh;
  int32_t alpha;

  size_t src_stride;
  size_t dest_stride;
  uint8_t *copy = NULL;

  mil_Image_t *src_image;
  mil_Image_t *dest_image;

  get_image_struct(rb_v_img, src_image);
  get_image_struct(self, dest_image);

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

  src_pixels = &src_image->data[((size_t)sx + (size_t)sy * (size_t)src_image->width) * 4];
  dest_pixels = &dest_image->data[((size_t)x + (size_t)y * (size_t)dest_image->width) * 4];

  src_stride = src_image->stride;
  dest_stride = dest_image->stride;

  if (src_image == dest_image &&
      x < sx + sw && x + sw > sx && y < sy + sh && y + sh > sy) {
    size_t copy_stride = (size_t)sw * 4;
    copy = (uint8_t*)malloc(copy_stride * (size_t)sh);
    if (!copy) {
      rb_memerror();
    }
    for (int64_t i = 0; i < sh; ++i) {
      memcpy(copy + (size_t)i * copy_stride,
             src_pixels + (size_t)i * src_stride,
             copy_stride);
    }
    src_pixels = copy;
    src_stride = copy_stride;
  }

  // Debug stuff
  //printf("alpha_blit(x: %d, y: %d, sx: %d, sy: %d, sw: %d, sh: %d, sp: %d, dp: %d, alpha: %d)\n",
  //       x, y, sx, sy, sw, sh, src_padding, dest_padding, alpha);

  for (int64_t i = 0; i < sh; ++i) {
    uint8_t *src_pixel = src_pixels + (size_t)i * src_stride;
    uint8_t *dest_pixel = dest_pixels + (size_t)i * dest_stride;
    for (int64_t j = 0; j < sw; ++j, src_pixel += 4, dest_pixel += 4) {
      uint32_t src_alpha = ((uint32_t)src_pixel[3] * (uint32_t)alpha + 127) / 255;
      uint32_t dest_alpha = dest_pixel[3];
      uint32_t inverse_alpha = 255 - src_alpha;
      uint32_t out_alpha_numerator = src_alpha * 255 + dest_alpha * inverse_alpha;

      if (out_alpha_numerator == 0) {
        memset(dest_pixel, 0, 4);
        continue;
      }

      for (int k = 0; k < 3; ++k) {
        uint32_t color_numerator =
          (uint32_t)src_pixel[k] * src_alpha * 255 +
          (uint32_t)dest_pixel[k] * dest_alpha * inverse_alpha;
        dest_pixel[k] = (uint8_t)((color_numerator + out_alpha_numerator / 2) /
                                  out_alpha_numerator);
      }
      dest_pixel[3] = (uint8_t)((out_alpha_numerator + 127) / 255);
    }
  }

  free(copy);
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
  get_image_struct(self, image);
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
