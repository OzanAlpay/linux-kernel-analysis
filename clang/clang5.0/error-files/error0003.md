## Error 0003 ##
**File location:** drivers/gpu/drm/amd/display/dc/calcs/Makefile:27  
**Error Message:**  
```
clang: error: unknown argument: '-mpreferred-stack-boundary=4'
scripts/Makefile.build:316: recipe for target 'drivers/gpu/drm/amd/amdgpu/../display/dc/calcs/dcn_calcs.o' failed
```

```
CFLAGS_display_mode_vba.o := -mhard-float -msse -mpreferred-stack-boundary=4
CFLAGS_display_mode_lib.o := -mhard-float -msse -mpreferred-stack-boundary=4
CFLAGS_display_pipe_clocks.o := -mhard-float -msse -mpreferred-stack-boundary=4
CFLAGS_display_rq_dlg_calc.o := -mhard-float -msse -mpreferred-stack-boundary=4
CFLAGS_dml1_display_rq_dlg_calc.o := -mhard-float -msse -mpreferred-stack-boundary=4
CFLAGS_display_rq_dlg_helpers.o := -mhard-float -msse -mpreferred-stack-boundary=4
CFLAGS_soc_bounding_box.o := -mhard-float -msse -mpreferred-stack-boundary=4
CFLAGS_dml_common_defs.o := -mhard-float -msse -mpreferred-stack-boundary=4
```
