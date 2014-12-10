#ifndef MINIL_EXT_H_
#define MINIL_EXT_H_

#include <stdint.h>

typedef struct {
  int32_t    width;
  int32_t    height;
  uint32_t    stride;
  size_t      size;
  uint8_t     *data;
} mil_Image_t;

inline int32_t
mil_int_max(int32_t a, int32_t b) {
  if (a > b)
    return a;
  else
    return b;
}

inline int32_t
mil_int_min(int32_t a, int32_t b) {
  if (a > b)
    return b;
  else
    return a;
}

#endif /* MINIL_EXT_H_ */
