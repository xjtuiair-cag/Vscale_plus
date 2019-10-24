// +FHDR------------------------------------------------------------------------
// Copyright ownership belongs to CAG laboratory, Institute of Artificial
// Intelligence and Robotics, Xi'an Jiaotong University, shall not be used in
// commercial ways without permission.
// -----------------------------------------------------------------------------
// FILE NAME  : main.c
// DEPARTMENT : CAG of IAIR
// AUTHOR     : XXXX
// AUTHOR'S EMAIL :XXXX@mail.xjtu.edu.cn
// -----------------------------------------------------------------------------
// Ver 1.0  2019--01--01 initial version.
// -----------------------------------------------------------------------------

#include "../inc/global.h"
#include "../inc/hpu_api.h"

c_conv_param conv_param = {1, 3, 5, 7, 9, 11, 13, 15};

int intr_conv_act = 0;

void main()
{
    conv_set(&conv_param);

    while (1)
    {
        // wait for start signal
        while(!intr_conv_act);
        intr_conv_act= 0;

    }
}
