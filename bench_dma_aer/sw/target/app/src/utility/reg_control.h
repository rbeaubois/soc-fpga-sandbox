#ifndef __REG_CONTROL_H__
#define __REG_CONTROL_H__
    #define SET_BIT_REG(R,B)      (R = R|(1UL<<B))
    #define CLEAR_BIT_REG(R,B)    (R = R&(~(1UL<<B)))
    #define TOGGLE_BIT_REG(R,B)   (R = R^(1UL<<B))
    #define CHECK_BIT_REG(R,B)    (R = (R>>B)&1U)
#endif