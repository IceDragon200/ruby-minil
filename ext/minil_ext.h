#ifndef MINIL_EXT_H_
#define MINIL_EXT_H_

#include <stdint.h>

typedef struct {
  uint32_t width;
  uint32_t height;
  uint32_t stride;
  size_t size;
  uint8_t *data;
} mil_Image_t;

#endif /* MINIL_EXT_H_ */