CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C11111111122222222223333333333444444444455555555556666666666777777777777
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C       --U S E R   E L E M E N T    S U B R O U T I N E S---          C
C                                                                      C
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C  USER ELEMENT SUBROUTINE                                             C
C                                                                      C
C  UEL8_PCLI_R.for 8-Noded Plasticity Isotropic Classical Return Mapp. C
C                                                                      C
C  8-NODED ISOPARAMETRIC ELEMENT WITH                                  C
C  FULL GAUSS INTEGRATION                                              C
C     UNIVERSIDAD EAFIT                                                C
C     LABORATORIO DE MECANICA APLICADA                                 C
C     BLOQUE 14-PISO 2                                                 C
C     MEDELLIN, COLOMBIA                                               C
C                                                                      C
C     LAST UPDATED APRIL 16/2015                                       C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C  USER ELEMENT SUBROUTINE-ISOTROPIC HARDENING MISES PLASTICITY        C
C  AND ISOTROPIC ELASTICITY                                            C
C                                                                      C
C  STANDARD  ISOPARAMETRIC ELEMENT                                     C
C  FULL GAUSS INTEGRATION                                              C
C  CREATED BY JUAN GOMEZ                                               C
C  STATE VARIABLES DEFINITIONS/GAUSS  POINT                            C
C                                                                      C
C                                                                      C
C     1-4: STRESS VECTOR                       (4)                     C
C     5-8: TOTAL STRAIN VECTOR                 (4)                     C
C    9-12: ELASTIC STRAIN VECTOR               (4)                     C
C   13-16: PLASTIC STRAIN VECTOR               (4)                     C
C      17: EQUIVALENT PLASTIC STRAIN           (1)                     C
C      18: EQUVALENT STRESS                    (1)                     C
C                                   TOTAL     162 SVARS                C
C                                                                      C
C    NODAL VALUES OF ONE STRESS AND STRAIN COMPONENT                   C
C                                                                      C
C     163: STRESS AT GAUSS POINT SPECIFIED                             C
C     164  STRAINT GAUSS POINT SPECIFIED                               C
C                                                                      C
C                                   TOTAL     164 SVARS                C
C                                                                      C
C                                                                      C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE UEL(RHS,AMATRX,SVARS,ENERGY,NDOFEL,NRHS,NSVARS,
     1PROPS,NPROPS,COORDS,MCRD,NNODE,U,DU,V,A,JTYPE,TIME,DTIME,
     2KSTEP,KINC,JELEM,PARAMS,NDLOAD,JDLTYP,ADLMAG,PREDEF,
     3NPREDF,LFLAGS,MLVARX,DDLMAG,MDLOAD,PNEWDT,JPROPS,NJPROP,
     4PERIOD)
C     
      INCLUDE 'ABA_PARAM.INC'
C
      CHARACTER*80 CMNAME
C  
      PARAMETER (ZERO=0.D0,HALF=0.5D0,ONE=1.D0,NTENS=4,TWO=2.D0,
     1           NGPTS=9,THREE=3.D0)
C
C     Parameters required by UMAT.f
C
      PARAMETER (NDI=3,NSTATV=10,SSE=0.D0,SCD=0.D0,
     1           RPL=0.D0,DRPLDT=0.D0,TEMP=0.D0,DTEMP=0.D0,NSHR=1,
     2           CELENT=2.D0,LAYER=1,KSPT=1)
C
C     Parameter arrays from UEL.f
C
      DIMENSION RHS(MLVARX,*),AMATRX(NDOFEL,NDOFEL),
     1     SVARS(NSVARS),ENERGY(8),PROPS(*),COORDS(MCRD,NNODE),
     2     U(NDOFEL),DU(MLVARX,*),V(NDOFEL),A(NDOFEL),TIME(2),
     3     PARAMS(3),JDLTYP(MDLOAD,*),ADLMAG(MDLOAD,*),
     4     DDLMAG(MDLOAD,*),PREDEF(2,NPREDF,NNODE),LFLAGS(*),
     5     JPROPS(*)
C
C     User defined arrays
C
      DIMENSION B(NTENS,NDOFEL),BT(NDOFEL,NTENS),FRST1(NDOFEL,NDOFEL),
     1FRST2(NDOFEL,1),XX(2,NNODE),XW(NGPTS),XP(2,NGPTS),
     2AUX1(NTENS,NDOFEL),STRESS(NTENS),STRAN(NTENS),DSTRAN(NTENS),
     3XBACK(NTENS),EELAS(NTENS),EPLAS(NTENS)
C
C     Arrays to be used in UMAT.f
C
      DIMENSION STATEV(NSTATV),DDSDDT(NTENS),DRPLDE(NTENS),
     1UPREDEF(1), DPRED(1),UCOORDS(3),DROT(3, 3), DFGRD0(3, 3), 
     2DFGRD1(3, 3),DDSDDE(NTENS, NTENS)
C
C     Initializes parameters required by UMAT.f
C
      CALL KCLEARV(STRESS,NTENS)
      CALL KCLEARV(STRAN,NTENS)
      CALL KCLEARV(DSTRAN,NTENS)
      CALL KCLEARV(DDSDDT,NTENS)
      CALL KCLEARV(DRPLDE,NTENS)
      CALL KCLEAR(DROT,3,3)
      CALL KCLEAR(DFGRD0,3,3)
      CALL KCLEAR(DFGRD1,3,3)
      CALL KCLEAR(DDSDDE,NTENS,NTENS)
      UPREDEF(1)=ZERO
      DPRED(1)=ZERO
C
C     Clears RHS vector and Stiffness matrix
C
      CALL KCLEARV(RHS,NDOFEL)
      CALL KCLEAR(AMATRX,NDOFEL,NDOFEL)
C
C**********************************************************************
C     P U R E  D I S P L A C E M E N T  F O R M U L A T I O N
C**********************************************************************
C
      CMNAME='PLASTIC'
      NSVARS_N=2
      NSVARS_F=NSVARS-NSVARS_N
C
C       Generates Gauss points and weights.
C
      CALL KGPOINTS3X3(XP,XW)
      NGPT=9
C
C     Loops around all Gauss points
C
      DO NN=1,NGPT
C
        RII=XP(1,NN)
        SII=XP(2,NN)
        ALF=XW(NN)
C
C       Compute State variable index corresponding
C       to current Gauss point and load stress,total strain
C       elastic strain,plastic strain and equivalent plastic
C       strain from state variables as defined in USER ELEMENT. 
C       Different variables are required for different constitutive models.
C
        ISVINT_F=1+(NN-1)*NSVARS_F/NGPT
        JJ=1
        DO II=ISVINT_F,ISVINT_F+3
          STRESS(JJ)=SVARS(II)
          STRAN(JJ )=SVARS(II+4 )
          EELAS(JJ )=SVARS(II+8 )
          EPLAS(JJ )=SVARS(II+12)
          JJ=JJ+1
        END DO
        EQPLAS=SVARS(ISVINT_F+16)
        SMISES=SVARS(ISVINT_F+17)
C
C       Starts STATEV array definition as required by UMAT.f
C       Different variables for different constitutive models.
C
        DO II=1,NTENS
          STATEV(II)=EELAS(II)
          STATEV(II+NTENS)=EPLAS(II)
        END DO
        STATEV(2*NTENS+1)=EQPLAS
        STATEV(2*NTENS+2)=SMISES
        JJ=1
C
C       Ends STATEV array definition as required by UMAT.f
C
C       Assembles B matrix
C
        CALL KSTDM(JELEM,NNODE,NDOFEL,NTENS,COORDS,B,DDET,RII,SII,XBAR)
        CALL KMAVEC(B,NTENS,NDOFEL,DU,DSTRAN)
        CALL KUPDVEC(STRAN,NTENS,DSTRAN)
C
C       Assembles material matrix and updates state variables
C
        CALL UMAT(STRESS, STATEV, DDSDDE, SSE, SPD, SCD, RPL,
     1  DDSDDT, DRPLDE, DRPLDT, STRAN, DSTRAN, TIME, DTIME, TEMP,
     2  DTEMP, UPREDEF, DPRED, CMNAME, NDI, NSHR, NTENS, NSTATV,
     3  PROPS, NPROPS, UCOORDS, DROT, PNEWDT, CELENT, DFGRD0,
     4  DFGRD1, JELEM, NN, LAYER, KSPT, KSTEP, KINC)
C
        CALL KMMULT(DDSDDE,NTENS,NTENS,B,NTENS,NDOFEL,AUX1)
        CALL KCLEAR(BT,NDOFEL,NTENS)
        CALL KMTRAN(B,NTENS,NDOFEL,BT)
C
C       Assembles stiffness matrix and RHS vector contribution
C
        CALL KMMULT(BT,NDOFEL,NTENS,AUX1,NTENS,NDOFEL,FRST1)
        CALL KMAVEC(BT,NDOFEL,NTENS,STRESS,FRST2)
C
C       Considers Gauss weight and Jacobian determinant representing
C       volume differential.
C
        CALL KSMULT(FRST1,NDOFEL,NDOFEL,ALF*DDET*XBAR)
        CALL KSMULT(FRST2,NDOFEL,1,-ALF*DDET*XBAR)
C
C       Updates Stiffness matrix and RHS vector
C
        CALL KUPDMAT(AMATRX,NDOFEL,NDOFEL,FRST1)
        CALL KUPDVEC(RHS,NDOFEL,FRST2)
C
C       Clears material Jacobian and temporary stiffness matrix
C       array for new Gauss point 
C
        CALL KCLEAR(DDSDDE,NTENS,NTENS)
        CALL KCLEAR(FRST1,NDOFEL,NDOFEL)
C
C       Starts updating of state variables with updated values from UMAT.f
C
        DO II=1,NTENS
          EELAS(II)=STATEV(II)
          EPLAS(II)=STATEV(II+NTENS)
        END DO
        EQPLAS=STATEV(2*NTENS+1)
        SMISES=STATEV(2*NTENS+2)
C
        JJ=1
        DO II=ISVINT_F,ISVINT_F+3
          SVARS(II)=STRESS(JJ)
          SVARS(II+4 )=STRAN(JJ)
          SVARS(II+8 )=EELAS(JJ)
          SVARS(II+12)=EPLAS(JJ)
          JJ=JJ+1
        END DO
        SVARS(ISVINT_F+16)=EQPLAS
        SVARS(ISVINT_F+17)=SMISES
C
C       Ends updating of state variables with updated values from UMAT.f
C
      END DO
C
C
C     EXTRAPOLATE STRAIN TO THE NODES
C
      RII=-1.0
      SII=1.0
      CALL KSTDM(JELEM,NNODE,NDOFEL,NTENS,COORDS,B,DDET,RII,SII,XBAR)
      CALL KMAVEC(B,NTENS,NDOFEL,U,STRAN)
      SVARS(NSVARS-1)=STRESS(1)
      SVARS(NSVARS)=STRAN(1)
C
      RETURN
C      
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C11111111122222222223333333333444444444455555555556666666666777777777777
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C--C O N S T I T U T I V E  M A T E R I A L S  S U B R O U T I N E S---C
C                                                                      C
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C11111111122222222223333333333444444444455555555556666666666777777777777
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C     SUBROUTINE UMAT                                                  C
C     UMAT_PCLI_R.for   Plasticity Classical Isotropic Return Mapping  C
C                       LINEAR ISTROPIC HARDENING                      C
C                                                                      C
C     ISOTROPIC HARDENING PLASYICITY                                   C
C     CANNOT BE USED FOR PLANE STRESS                                  C
C     TAKEN FROM ABAQUS SAMPLE SUBROUTINES                             C
C     NTENS: LENGTH OF STRESS VECTOR                                   C
C     NDI:   NUMBER OF NORMAL STRESS COMPONENTS                        C
C     JULY 14/2003                                                     C
C                                                                      C
C     LOCAL ARRAYS                                                     C
C                                                                      C
C     EELAS - ELASTIC STRAINS STATEV(1..NTENS)                         C
C     EPLAS - PLASTIC STRAINS STATEV(NTENS+1...2*NTENS)                C
C     FLOW  - PLASTIC FLOW DIRECTION                                   C
C     HARD  - HARDENING MODULUS                                        C
C                                                                      C
C     PROPS(1) - E                                                     C
C     PROPS(2) - NU                                                    C
C     PROPS(3..) - SYIELD AN HARDENING DATA                            C
C     CALLS KUHARD FOR CURVE OF YIELD STRESS VS. PLASTIC STRAINS       C
C     EQPLAS - EQUIVALENT PLASTIC STRAIN STATEV(2*NTENS+1)             C
C                                                                      C
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
      SUBROUTINE UMAT(STRESS, STATEV, DDSDDE, SSE, SPD, SCD, RPL,
     1DDSDDT, DRPLDE, DRPLDT, STRAN, DSTRAN, TIME, DTIME, TEMP,
     2DTEMP, PREDEF, DPRED, CMNAME, NDI, NSHR, NTENS, NSTATV,
     3PROPS, NPROPS, COORDS, DROT, PNEWDT, CELENT, DFGRD0,
     4DFGRD1, NOEL, NPT, LAYER, KSPT, KSTEP, KINC)
C
      INCLUDE 'ABA_PARAM.INC'
C
      CHARACTER*80 CMNAME
C 
      DIMENSION STRESS(NTENS), STATEV(NSTATV),DDSDDE(NTENS, NTENS),
     1DDSDDT(NTENS),DRPLDE(NTENS),STRAN(NTENS),DSTRAN(NTENS),TIME(2),
     2PREDEF(1), DPRED(1), PROPS(NPROPS),COORDS(3),DROT(3, 3),
     3DFGRD0(3, 3), DFGRD1(3, 3)
C
      DIMENSION EELAS(NTENS), EPLAS(NTENS), FLOW(NTENS),SDEV(NTENS,1),
     1P(NTENS,NTENS)
C
      PARAMETER (ZERO=0.D0, ONE=1.D0, TWO=2.D0, THREE=3.D0, SIX=6.0D0,
     1           ENUMAX=0.4999D0, NEWTON=10, TOLER=1.0D-7,MAXITER=10)
C
C**********************************************************************
C     I S O T R O P I C  M I S E S  E L A S T O P L A S T I C I T Y
C     P L A N E  S T R A I N  A N A L Y S I S
C**********************************************************************
C
      CALL KCLEAR(SDEV,NTENS,1)
C
C     RECOVER EQUIVALENT PLASTIC STRAIN, ELASTIC STRAINS, AND PLASTIC
C     STRAINS. ALSO INITIALIZE USER-DEFINED DATA SETS     
C
      EQPLAS=STATEV(1+2*NTENS)
      DO K1=1, NTENS
        EELAS(K1)=STATEV(K1)
        EPLAS(K1)=STATEV(K1+NTENS)
        FLOW(K1)=ZERO
      END DO
      SMISES=STATEV(2+2*NTENS)
C
C     ELASTIC PROPERTIES
C
      EMOD=PROPS(1)
      ENU=MIN(PROPS(2),ENUMAX)
      EBULK3=EMOD/(ONE-TWO*ENU)
      EG2=EMOD/(ONE+ENU)
      EG=EG2/TWO
      EG3=THREE*EG
      ELAM=(EBULK3-EG2)/THREE
C
C     ELASTIC STIFFNESS
C
      DO K1=1, NDI
        DO K2=1, NDI
          DDSDDE(K2, K1)=ELAM
        END DO
        DDSDDE(K1, K1)=EG2+ELAM
      END DO
      DO K1=NDI+1, NTENS
        DDSDDE(K1, K1)=EG
      END DO
C
C     CALCULATE PREDICTOR STRESSES AND ELASTIC STRAIN
C
      DO K1=1, NTENS
        DO K2=1, NTENS
          STRESS(K2)=STRESS(K2)+DDSDDE(K2, K1)*DSTRAN(K1)
        END DO
        EELAS(K1)=EELAS(K1)+DSTRAN(K1)
      END DO
C
C     CALCULATE EQUIVALENT VON MISES STRESS
C
      SHYDRO=(STRESS(1)+STRESS(2)+STRESS(3))/THREE
      CALL KPROYECTOR(P)
      CALL KMMULT(P,NTENS,NTENS,STRESS,NTENS,1,SDEV)
C
      SMISES=(SDEV(1,1)-SDEV(2,1))**2
     1+(SDEV(2,1)-SDEV(3,1))**2+(SDEV(3,1)-SDEV(1,1))**2
      DO K1=NDI+1, NTENS
        SMISES=SMISES+SIX*SDEV(K1,1)**2
      END DO
      SMISES=SQRT(SMISES/TWO)
      FBAR=DSQRT(TWO/THREE)*SMISES
C
C     GET YIELD STRESS FROM THE SPECIFIED HARDENING CURVE
C
      NVALUE=NPROPS/2-1
      CALL KUHARD(SYIEL0,HARD,EQPLAS,NVALUE,PROPS(3))
C
C     DETERMINE IF ACTIVELY YIELDING
C
      SYIELD=SYIEL0
      IF(FBAR.GT.(ONE+TOLER)*SYIEL0) THEN
C
C       Actively yielding==>Compute consistncy parameter and equivalent
C       plastic strain.
C
        DO K1=1, NTENS
          FLOW(K1)=SDEV(K1,1)/FBAR
        END DO
C
        GAM_PAR=(FBAR-SYIEL0)/((HARD/EG3)+1)
        GAM_PAR=GAM_PAR/EG2
        EQPLAS=EQPLAS+DSQRT(TWO/THREE)*GAM_PAR
        CALL KUHARD(SYIELD,HARD,EQPLAS,NVALUE,PROPS(3))
C
C       Update plastic strains, equivalent plastic
C       strains, stresses
C
C       Normal components
C
        DO K1=1,NDI
          EPLAS(K1)=EPLAS(K1)+GAM_PAR*FLOW(K1)
          EELAS(K1)=EELAS(K1)-EPLAS(K1)
          STRESS(K1)=FLOW(K1)*SYIELD+SHYDRO
        END DO
C
C       Shear components
C
        DO K1=NDI+1,NTENS
          EPLAS(K1)=EPLAS(K1)+TWO*GAM_PAR*FLOW(K1)
          EELAS(K1)=EELAS(K1)-EPLAS(K1)
          STRESS(K1)=FLOW(K1)*SYIELD
        END DO
C
C       Formulate the Jacobian (Material tangent)
C
        CALL KCLEAR(DDSDDE,NTENS,NTENS)
C
C       Calculate effective properties 
C
        BETA1=ONE-EG2*GAM_PAR/FBAR
        C1=ONE+(HARD/EG3)
        BETABAR=(ONE/C1)-(EG2*GAM_PAR/FBAR)
        EFFG=EG*BETA1
        EFFG2=TWO*EFFG
        EFFLAM=ELAM+(EG2/THREE)*(ONE-BETA1)
        EFFHRD=-EG2*BETABAR
C
C      Cauchy stress terms (4x4 Submtrix)
C
        DO K1=1, NDI
          DO K2=1, NDI
            DDSDDE(K2, K1)=EFFLAM
          END DO
          DDSDDE(K1, K1)=(EFFG2+EFFLAM)
        END DO
        DO K1=NDI+1, NTENS
          DDSDDE(K1, K1)=EFFG
        END DO
        DO K1=1, NTENS
          DO K2=1, NTENS
            DDSDDE(K2, K1)=DDSDDE(K2, K1)+EFFHRD
     &                     *FLOW(K2)*FLOW(K1)
          END DO
        END DO
      END IF
C
C     STORE ELASTIC STRAINS, (EQUIVALENT) PLASTIC STRAINS
C     IN STATE VARIABLE ARRAY
C
      DO K1=1, NTENS
        STATEV(      K1)=EELAS(K1)
        STATEV(NTENS+K1)=EPLAS(K1)
      END DO
      STATEV(2*NTENS+1)=EQPLAS
      STATEV(2*NTENS+2)=SMISES
C
      RETURN
C
      END
C
C11111111122222222223333333333444444444455555555556666666666777777777777
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C     SUBROUTINE UHARD                                                 C
C                                                                      C
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
      SUBROUTINE KUHARD(SYIELD,EHARD,EQPLAS,NVALUE,TABLE)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      DIMENSION TABLE(2,NVALUE)
C
      PARAMETER(ZERO=0.D0,TWO=2.D0,THREE=3.D0)
C
      SYIEL0=TABLE(1,1)
C
C     Compute hardening modulus
C
      EHARD=(TABLE(1,2)-TABLE(1,1))/TABLE(2,2)
C
C     Compute yield stress corresponding to EQPLAS
C
      SYIELD=DSQRT(TWO/THREE)*(SYIEL0+EHARD*EQPLAS)
C
      RETURN
C
      END
C
C11111111122222222223333333333444444444455555555556666666666777777777777
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C     SUBROUTINE PROYECTOR                                             C
C     PROJECTS THE STRESS TENSOR INTO THE DEVIATORIC SPACE             C
C     FOR A PLANE STRAIN PROBLEM                                       C
C                                                                      C
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
      SUBROUTINE KPROYECTOR(P)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER(ZERO=0.D0,ONE=1.D0,TWO=2.D0,THREE=3.D0)
C
      DIMENSION P(4,4)
C
      CALL KCLEAR(P,4,4)
      P(1,1)=TWO/THREE
      P(1,2)=-ONE/THREE
      P(1,3)=-ONE/THREE
      P(2,1)=-ONE/THREE
      P(2,2)=TWO/THREE
      P(2,3)=-ONE/THREE
      P(3,1)=-ONE/THREE
      P(3,2)=-ONE/THREE
      P(3,3)=TWO/THREE
      P(4,4)=ONE
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C11111111122222222223333333333444444444455555555556666666666777777777777
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C         --G E N E R A L  F E M  S U B R O U T I N E S--              C
C                                                                      C
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C     SUBROUTINE KSTDM:GENERATES THE STRAIN-DISPLACEMENT MATRIX B      C
C     AND JACOBIAN DETERMINANT DDET AT THE POINT r ,s                  C
C                                                 i  j                 C
C     FOR AN 8-NODED 2D ELEMENT-PLANE STRAIN                           C
C     B    =STRAIN-DISPLACEMENT MATRIX                                 C
C     BLM  =RELATIVE STRAIN DISPLACEMENT MATRIX                        C
C     DDET =JACOBIAN DETERMINANT                                       C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KSTDM(IDEL,NNE,NDOFEL,NTENS,XX,B,DDET,R,S,XBAR)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      PARAMETER (ONE=1.D0,TWO=2.D0,THREE=3.D0,HALF=0.5D0)
C
      DIMENSION XX(2,NNE),B(NTENS,NDOFEL),P(2,NNE),AUX1(2,NNE),XJ(2,2),
     2XJI(2,2)
C
C     Initialize arrays
C
      XBAR=ONE
      CALL KCLEAR(B,NTENS,NDOFEL)
      CALL KCLEAR(XJ,2,2)
      CALL KCLEAR(XJI,2,2)
      CALL KCLEAR(P,2,NNE)
C
C     Shape functions derivatives w.r.t natural coordinates
C
      CALL KSFDER(IELT,NDOFEL,NNE,R,S,P)
C
C     Computes the Jacobian operator and its determinant at point (r,s)
C
      CALL KJACOPER(NNE,XJ,XX,P)
      DDET=XJ(1,1)*XJ(2,2)-XJ(1,2)*XJ(2,1)
C
C     Computes the inverse of the Jacobiam operator
C
      CALL KJACINVE(XJ,DDET,XJI)
C
C     Jacobian Inverse times Shape Functions derivatives w.r.t natural coordinates
C     to produce shape function derivatives w.r.t x,y coordinates.
C          
      CALL KMMULT(XJI,2,2,P,2,NNE,AUX1)
C
C     Assembles B matrix for a
C     Cosserat element.
C
      DO I=1,NNE
        II=2*(I-1)+1
        B(1,II)=AUX1(1,I)
        B(2,II+1)=AUX1(2,I)
        B(4,II)=AUX1(2,I)
        B(4,II+1)=AUX1(1,I)
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C     SUBROUTINE KSFDER:GENERATES THE SHAPE FUNCTION DERIVATIVES       C
C     ACCORDING TO ELEMENT TYPE AT THE POINT r ,s                      C
C                                             i  j                     C
C     B    =STRAIN-DISPLACEMENT MATRIX                                 C
C     DDET =JACOBIAN DETERMINANT                                       C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KSFDER(IELT,NDOFEL,NNE,R,S,P)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER(ONE=1.D0,TWO=2.D0, HALF=0.5D0,QUARTER=0.25D0,FOUR=4.D0)
C
      DIMENSION P(2,NNE)
C
      RP= ONE+R
      SP= ONE+S
      RM= ONE-R
      SM= ONE-S
      RMS=ONE-R**TWO
      SMS=ONE-S**TWO
C
C     8-NODED ELEMENT
C     Derivatives w.r.t the natural coordinates
C     w.r.t.r
C
      P(1,8)=-HALF*SMS
      P(1,7)=-R*SP
      P(1,6)= HALF*SMS
      P(1,5)=-R*SM
      P(1,4)=-QUARTER*SP-HALF*P(1,7)-HALF*P(1,8)
      P(1,3)= QUARTER*SP-HALF*P(1,7)-HALF*P(1,6)
      P(1,2)= QUARTER*SM-HALF*P(1,5)-HALF*P(1,6)
      P(1,1)=-QUARTER*SM-HALF*P(1,8)-HALF*P(1,5)
C
C     w.r.t.s
C
      P(2,8)=-S*RM
      P(2,7)= HALF*RMS
      P(2,6)=-S*RP
      P(2,5)=-HALF*RMS
      P(2,4)= QUARTER*RM-HALF*P(2,7)-HALF*P(2,8)
      P(2,3)= QUARTER*RP-HALF*P(2,7)-HALF*P(2,6)
      P(2,2)=-QUARTER*RP-HALF*P(2,5)-HALF*P(2,6)
      P(2,1)=-QUARTER*RM-HALF*P(2,8)-HALF*P(2,5)
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C 3X3 GAUSS POINTS GENERATION                                          C
C                                                                      C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KGPOINTS3X3(XP,XW)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      PARAMETER (ZERO=0.D0,ONE=1.D0)
C
      DIMENSION XP(2,9),XW(9),RLGP(2,9)
C
      RLGP(1,1)=-ONE
      RLGP(1,2)=ZERO
      RLGP(1,3)= ONE
      RLGP(1,4)=-ONE
      RLGP(1,5)=ZERO
      RLGP(1,6)= ONE
      RLGP(1,7)=-ONE
      RLGP(1,8)=ZERO
      RLGP(1,9)= ONE
C
      RLGP(2,1)=-ONE
      RLGP(2,2)=-ONE
      RLGP(2,3)=-ONE
      RLGP(2,4)=ZERO
      RLGP(2,5)=ZERO
      RLGP(2,6)=ZERO
      RLGP(2,7)= ONE
      RLGP(2,8)= ONE
      RLGP(2,9)= ONE
C
      XW(1)=0.555555555555556D0**2
      XW(2)=0.555555555555556D0*0.888888888888889D0
      XW(3)=0.555555555555556D0**2
C
      XW(4)=0.555555555555556D0*0.888888888888889D0
      XW(5)=0.888888888888889D0**2
      XW(6)=0.555555555555556D0*0.888888888888889D0
C
      XW(7)=0.555555555555556D0**2
      XW(8)=0.555555555555556D0*0.888888888888889D0
      XW(9)=0.555555555555556D0**2
C
      G=DSQRT(0.60D0)
      DO I=1,2
        DO J=1,9 
          XP(I,J)=G*RLGP(I,J)
        END DO
      END DO
C     
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C   SUBROUTINE KGPOINTS2X2                                             C
C                                                                      C
C   2X2 GAUSS POINTS GENERATION                                        C
C                                                                      C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KGPOINTS2X2(XP,XW)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      PARAMETER (ZERO=0.D0,ONE=1.D0,HALF=0.5d0)
C
      DIMENSION XP(2,9),XW(9)
C
      CALL KCLEARV(XW,9)
      CALL KCLEAR(XP,2,9)
C
c      DO K1=1,4
c        XW(K1)=HALF
c      END DO
C
c      XP(1,1)=-0.288675134595
c      XP(2,1)=-0.288675134595
c      XP(1,2)= 0.288675134595
c      XP(2,2)=-0.288675134595
c      XP(1,3)=-0.288675134595
c      XP(2,3)= 0.288675134595
c      XP(1,4)= 0.288675134595
c      XP(2,4)= 0.288675134595
cc
      DO K1=1,4
        XW(K1)=ONE
      END DO
C
      XP(1,1)=-0.577350269189626
      XP(2,1)=-0.577350269189626
      XP(1,2)= 0.577350269189626
      XP(2,2)=-0.577350269189626
      XP(1,3)=-0.577350269189626
      XP(2,3)= 0.577350269189626
      XP(1,4)= 0.577350269189626
      XP(2,4)= 0.577350269189626
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C   SUBROUTINE KJACOPER                                                C
C                                                                      C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KJACOPER(NNE,XJA,XCORD,RDER)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      PARAMETER(ZERO=0.0D0)
C
      DIMENSION XJA(2,2),XCORD(2,NNE),RDER(2,NNE)
C
      CALL KCLEAR(XJA,2,2)
C
      DUM=ZERO
      DO K=1,2
        DO J=1,2
          DO I=1,NNE
            DUM=DUM+RDER(K,I)*XCORD(J,I)
          END DO
          XJA(K,J)=DUM
          DUM=ZERO
        END DO
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      2X2 Jacobian inverse                                            C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KJACINVE(XJA,DD,XJAI)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      DIMENSION XJA(2,2),XJAI(2,2),XADJ(2,2)
C
      XADJ(1,1)=XJA(2,2)
      XADJ(1,2)=XJA(1,2)
      XADJ(2,1)=XJA(2,1)
      XADJ(2,2)=XJA(1,1)
      DO J=1,2
        DO K=1,2
          COFA=((-1)**(J+K))*XADJ(J,K)
          XJAI(J,K)=COFA/DD
        END DO
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C             M A T R I X   H A N D L I N G                            C
C-------------U T I L I T I E S   B L O C K--------------              C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KCLEAR(A,N,M)                                        C
C      Clear a real matrix                                             C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KCLEAR(A,N,M)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER(ZERO=0.0D0)
      DIMENSION A(N,M)
C
      DO I=1,N
        DO J=1,M
          A(I,J)=ZERO
        END DO
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KMMULT(A,NRA,NCA,B,NRB,NCB,C)                        C
C      Real matrix product                                             C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KMMULT(A,NRA,NCA,B,NRB,NCB,C)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      PARAMETER(ZERO=0.D0)
      DIMENSION A(NRA,NCA),B(NRB,NCB),C(NRA,NCB)
C
      CALL KCLEAR(C,NRA,NCB)
      DUM=ZERO
      DO I=1,NRA
        DO J=1,NCB
         DO K=1,NCA
           DUM=DUM+A(I,K)*B(K,J)
          END DO
          C(I,J)=DUM
          DUM=ZERO
        END DO
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KSMULT(A,NR,NC,S)                                    C
C      Matrix times a scalar.                                          C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KSMULT(A,NR,NC,S)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      DIMENSION A(NR,NC)
C
      DO I=1,NR
        DO J=1,NC
          DUM=A(I,J)
          A(I,J)=S*DUM
          DUM=0.D0
        END DO  
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KUPDMAT(A,NR,NC,B)                                   C
C      Updates an existing matrix with an incremental matrix.          C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KUPDMAT(A,NR,NC,B)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      PARAMETER(ZERO=0.D0)
C
      DIMENSION A(NR,NC),B(NR,NC)
C
      DO I=1,NR
        DO J=1,NC
          DUM=A(I,J)
          A(I,J)=ZERO
          A(I,J)=DUM+B(I,J)
          DUM=ZERO
        END DO
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KMTRAN(A,NRA,NCA,B)                                  C      
C      Matrix transpose                                                C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KMTRAN(A,NRA,NCA,B)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      DIMENSION A(NRA,NCA),B(NCA,NRA)
C
      CALL KCLEAR(B,NCA,NRA)
      DO I=1,NRA
       DO J=1,NCA
         B(J,I)=A(I,J)
        END DO
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KMAVEC(A,NRA,NCA,B,C)                                C
C      Real matrix times vector                                        C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KMAVEC(A,NRA,NCA,B,C)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      PARAMETER(ZERO=0.D0)
      DIMENSION A(NRA,NCA),B(NCA),C(NRA)
C
      CALL KCLEARV(C,NRA)
C
      DO K1=1,NRA
        DO K2=1,NCA
          C(K1)=C(K1)+A(K1,K2)*B(K2)	    
        END DO
      END DO     
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KCLEARV(A,N)                                         C
C      Clear a real vector                                             C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KCLEARV(A,N)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER(ZERO=0.0D0)
C
      DIMENSION A(N)
C
      DO I=1,N
        A(I)=ZERO
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KUPDVEC(A,NR,B)                                      C
C      Updates an existing vector with an incremental vector.          C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KUPDVEC(A,NR,B)
C
      IMPLICIT REAL*8 (A-H,O-Z)
C
      PARAMETER(ZERO=0.D0)
C
      DIMENSION A(NR),B(NR)
C
      DO I=1,NR
        DUM=A(I)
        A(I)=ZERO
        A(I)=DUM+B(I)
        DUM=ZERO
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KVECSUB(A,NRA,B,NRB,C)                               C
C      Substracts one column vector from another column vector         C
C      IFLAG=0 for substraction                                        C
C      IFLAG=1 for addition                                            C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KVECSUB(A,NRA,B,NRB,C,IFLAG)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER (ONE=1.0D0, ONENEG=-1.0D0)
C
      DIMENSION A(NRA,1),B(NRB,1),C(NRB,1)
C
      SCALAR=ONENEG
C
      IF (IFLAG.EQ.1) SCALAR=ONE
C
      DO I=1,NRA
        C(I,1)=A(I,1)+B(I,1)*SCALAR
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C      SUBROUTINE KMATSUB(A,NRA,NCA,B,C,IFLAG)                         C
C      Substracts one rectangular matrix from another rectangular      C
C      matrix                                                          C
C      IFLAG=0 for substraction                                        C
C      IFLAG=1 for addition                                            C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KMATSUB(A,NRA,NCA,B,C,IFLAG)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER (ONE=1.0D0, ONENEG=-1.0D0)
C
      DIMENSION A(NRA,NCA),B(NRA,NCA),C(NRA,NCA)
C
      CALL KCLEAR(C,NRA,NCA)
C
      SCALAR=ONENEG
C
      IF (IFLAG.EQ.1) SCALAR=ONE
C
      DO I=1,NRA
        DO J=1,NCA
          C(I,J)=A(I,J)+B(I,J)*SCALAR
        END DO
      END DO
C
      RETURN
C
      END
C
C11111111122222222223333333333444444444455555555556666666666777777777777
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C     SUBROUTINE IDENTITY                                              C
C     CREATES AN IDENTITY MATRIX OF DIMENSIONS NDIM,NDIM               C
C                                                                      C
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
      SUBROUTINE KIDENTITY(DEL,NDIM)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER(ONE=1.D0)
C
      DIMENSION DEL(NDIM,NDIM)
C
      CALL KCLEAR(DEL,NDIM,NDIM)
C
      DO K1=1,NDIM
        DEL(K1,K1)=ONE
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C   SUBROUTINE KINVERSE                                                 C
C                                                                      C
C   IVEERSE OF A MATRIX USING LU DECOMPOSITION                         C
C   TAKEN FROM NUMERICAL RECIPES By Press et al                        C
C                                                                      C
C   A   Matrix to be inverted.                                         C
C   Y   Inverse of A                                                   C
C   N   Dimension                                                      C
C                                                                      C
C                                                                      C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KINVERSE(A,Y,NP,N)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER (ZERO=0.D0,ONE=1.D0)
C
      DIMENSION A(NP,NP),Y(NP,NP),INDX(NP),AUX(NP,NP)
C
      CALL KCLEAR(AUX,NP,NP)
      CALL KCOPYMAT(A,AUX,N)
C
      DO I=1,N
        DO J=1,N
          Y(I,J)=ZERO
        END DO
        Y(I,I)=ONE
      END DO
      CALL KLUDCMP(AUX,N,NP,INDX,D)
      DO J=1,N
        CALL KLUBKSB(AUX,N,NP,INDX,Y(1,J))
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C   SUBROUTINE KLUDCMP                                                 C
C                                                                      C
C   LU MATRIX DECOMPOSITION                                            C
C   TAKEN FROM NUMERICAL RECIPES By Press et al                        C
C                                                                      C
C                                                                      C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KLUDCMP(A,N,NP,INDX,D)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER(NMAX=500,TINY=1.0E-20,ZERO=0.D0,ONE=1.D0)
C
      DIMENSION INDX(N),A(NP,NP),VV(NMAX)
C
      D=ONE
      DO I=1,N
        AAMAX=ZERO
        DO J=1,N
          IF(ABS(A(I,J)).GT.AAMAX) AAMAX=ABS(A(I,J))
        END DO
        IF(AAMAX.EQ.0.) PAUSE 'SINGULAR MATRIX IN LUDCMP'
        VV(I)=ONE/AAMAX
      END DO
C
      DO J=1,N
        DO I=1,J-1
          SUM=A(I,J)
          DO K=1,I-1
            SUM=SUM-A(I,K)*A(K,J)
          END DO
          A(I,J)=SUM
        END DO
        AAMAX=ZERO
        DO I=J,N
          SUM=A(I,J)
          DO K=1,J-1
            SUM=SUM-A(I,K)*A(K,J)
          END DO
          A(I,J)=SUM
          DUM=VV(I)*ABS(SUM)
          IF(DUM.GE.AAMAX) THEN
             IMAX=I
             AAMAX=DUM
          END IF
        END DO
        IF(J.NE.IMAX) THEN
           DO K=1,N
             DUM=A(IMAX,K)
             A(IMAX,K)=A(J,K)
             A(J,K)=DUM
           END DO
           D=-D
           VV(IMAX)=-VV(J)
        END IF
        INDX(J)=IMAX
        IF(A(J,J).EQ.0.) A(J,J)=TINY
        IF(J.NE.N) THEN
           DUM=ONE/A(J,J)
           DO I=J+1,N
             A(I,J)=A(I,J)*DUM
           END DO
        END IF
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C   SUBROUTINE KLUBKSB                                                 C
C                                                                      C
C   FORWARD SUBSTITUTION                                               C
C   TAKEN FROM NUMERICAL RECIPES By Press et al                        C
C                                                                      C
C                                                                      C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C
      SUBROUTINE KLUBKSB(A,N,NP,INDX,B)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      PARAMETER (ZERO=0.D0)
C
      DIMENSION INDX(N),A(NP,NP),B(NP)
C
      II=0
      DO I=1,N
        LL=INDX(I)
        SUM=B(LL)
        B(LL)=B(I)
        IF(II.NE.0) THEN
           DO J=II,I-1
             SUM=SUM-A(I,J)*B(J)
           END DO
        ELSE IF(SUM.NE.ZERO) THEN
           II=I
        END IF
        B(I)=SUM
      END DO
C
      DO I=N,1,-1
        SUM=B(I)
        DO J=I+1,N
          SUM=SUM-A(I,J)*B(J)
        END DO
        B(I)=SUM/A(I,I)
      END DO
C
      RETURN
C
      END
C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C23456789012345678901234567890123456789012345678901234567890123456789012
C                                                                      C
C     SUBROUTINE KCOPYMAT                                              C
C                                                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C
      SUBROUTINE KCOPYMAT(A,B,N)
C
      IMPLICIT REAL*8(A-H,O-Z)
C
      DIMENSION A(N,N),B(N,N)
C
      CALL KCLEAR(B,N,N)
C
      DO K1=1,N
        DO K2=1,N
          B(K1,K2)=A(K1,K2)
        END DO
      END DO
C
      RETURN
C
      END