!IF 0

Copyright (c) 1989  Microsoft Corporation

Module Name:

    sources.

Abstract:

    This file specifies the target component being built and the list of
    sources files needed to build that component.  Also specifies optional
    compiler switches and libraries that are unique for the component being
    built.


Author:

    Steve Wood (stevewo) 12-Apr-1990
    Dave Hastings (daveh) 24-Apr-1991

NOTE:   Commented description of this file is in \nt\bak\bin\sources.tpl

!ENDIF


MAJORCOMP=v86
MINORCOMP=haxm
TARGETNAME=haxm


TARGETPATH=obj

TARGETTYPE=LIBRARY


TARGETLIBS=

MVDMDIR=$(PROJECT_ROOT)\mvdm


INCLUDES=\
    ..\x86;\
    $(MVDMDIR)\inc;\
    $(MVDMDIR)\softpc.new\base\inc;\
    $(MVDMDIR)\softpc.new\host\inc;\
    $(MVDMDIR)\softpc.new\host\inc\$(PROCESSOR_ARCHITECTURE)\prod


NTPROFILEINPUT=YES

SOURCES=


!IF $(FREEBUILD)
SPC_VAR=-DPROD
!ELSE
SPC_VAR=
!ENDIF

!IFDEF PROFILE
C_DEFINES=-DCPU_40_STYLE -DPROFILE -DMINNT $(SPC_VAR)
!ELSE
!IFDEF OLDBUILD
C_DEFINES=-DCPU_40_STYLE -DOLDBUILD -DMINNT $(SPC_VAR)
!ELSE
C_DEFINES=-DCPU_40_STYLE -DMINNT $(SPC_VAR)
!ENDIF
!ENDIF

UMTYPE=console
