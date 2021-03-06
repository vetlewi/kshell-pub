module rotation_group

  implicit none
  private
  public :: dcg, d6j, d9j, dfunc

contains

function dcg(j1, m1, j2, m2, j3, m3) result(s)
!
!  Clebsch-Gordan coefficient
!
!  dcg(j1, m1, j2, m2, j3, m3) 
!  = ((j1)/2, (m1)/2, (j2)/2, (m2)/2 | (j3)/2, (m3)/2)
!
!  using the formula by Racah (1942)
!
  implicit none
  integer, intent(in) :: j1, j2, j3, m1, m2, m3
  integer :: js, jm1, jm2, jm3, k1, k2, k3
  integer :: iz, izmin, izmax, isign, info
  real(8) :: s
  real(8) :: tmp, delta

  s = 0.0d0
  jm1 = j1 - m1
  jm2 = j2 - m2
  jm3 = j3 - m3

! error and trivial-value check
  if (abs(m1) > j1 .or. abs(m2) > j2 .or. abs(m3) > j3 .or. &
       & mod(jm1, 2) /= 0 .or. mod(jm2, 2) /= 0 .or. mod(jm3, 2) /= 0) then
     write(*,*) 'error [dcg]: invalid j or m'
     write(*,'(1a, 1i4, 2x, 1a, 1i4)') 'j1 =', j1, 'm1 =', m1
     write(*,'(1a, 1i4, 2x, 1a, 1i4)') 'j2 =', j2, 'm2 =', m2
     write(*,'(1a, 1i4, 2x, 1a, 1i4)') 'j3 =', j3, 'm3 =', m3
     stop
  end if

  call triangle(j1, j2, j3, delta, info)
  if (info == 1) return
  if (m3 /= m1+m2) return

  jm1 = jm1 / 2
  jm2 = jm2 / 2
  jm3 = jm3 / 2
  js = (j1 + j2 + j3)/2
  k1 = (j2 + j3 - j1)/2
  k2 = (j3 + j1 - j2)/2
  k3 = (j1 + j2 - j3)/2

  tmp = sqrt(dbinomial(j1, k2)/dbinomial(j1, jm1)) &
       & * sqrt(dbinomial(j2, k3)/dbinomial(j2, jm2)) &
       & * sqrt(dbinomial(j3, k1)/dbinomial(j3, jm3)) &
       & * sqrt((j3+1.0d0)) * delta

  izmin = max(0, jm1-k2, k3-jm2)
  izmax = min(k3, jm1, j2-jm2)

  isign = (-1)**izmin
  do iz = izmin, izmax
     s = s + isign * dbinomial(k3,iz) * dbinomial(k2,jm1-iz) &
          & * dbinomial(k1,j2-jm2-iz)
     isign = isign * (-1)
  end do

  s = s * tmp 

end function dcg

function d6j(j1, j2, j3, l1, l2, l3) result(s)
!
!  6j coefficient
!
!  d6j(j1, j2, j3, l1, l2, l3) = {(j1)/2 (j2)/2 (j3)/2}
!                                {(l1)/2 (l2)/3 (l3)/2}
!
!  see I. Talmi, Simple Models of Complex Nuclei, p. 158
!
  implicit none
  integer, intent(in) :: j1, j2, j3, l1, l2, l3
  real(8) :: s
  real(8) :: deltas, delta1, delta2, delta3
  integer :: infos, info1, info2, info3
  integer :: izmin, izmax, iz, isign
  integer :: js, k1, k2, k3, jl1, jl2, jl3

  s = 0.0d0
  call triangle(j1, j2, j3, deltas, infos)
  call triangle(j1, l2, l3, delta1, info1)
  call triangle(l1, j2, l3, delta2, info2)
  call triangle(l1, l2, j3, delta3, info3)
  if (infos == 1 .or. info1 == 1 .or. info2 == 1 .or. info3 == 1) return

  js = (j1 + j2 + j3)/2
  k1 = (j2 + j3 - j1)/2
  k2 = (j3 + j1 - j2)/2
  k3 = (j1 + j2 - j3)/2
  jl1 = (j1 + l2 + l3)/2
  jl2 = (l1 + j2 + l3)/2
  jl3 = (l1 + l2 + j3)/2

  izmin = max(0, js, jl1, jl2, jl3)
  izmax = min(k1+jl1, k2+jl2, k3+jl3)

  isign = (-1)**izmin
  do iz = izmin, izmax
     s = s + isign * dbinomial(iz+1, iz-js) &
          & * dbinomial(k1, iz-jl1) * dbinomial(k2, iz-jl2) &
          & * dbinomial(k3, iz-jl3) 
     isign = isign * (-1)
  end do
  s = s * delta1 * delta2 * delta3 / deltas

end function d6j

function d9j(j11, j12, j13, j21, j22, j23, j31, j32, j33) result(s)
!
!  9j coefficient
!
!  d9j(j11, j12, j13, j21, j22, j23, j31, j32, j33)
!
!    {(j11)/2 (j12)/2 (j13)/2}
!  = {(j21)/2 (j22)/2 (j23)/2}
!    {(j31)/2 (j32)/2 (j33)/2}
!
!  see I. Talmi, Simple Models of Complex Nuclei, p. 968
!
  implicit none
  integer, intent(in) :: j11, j12, j13, j21, j22, j23, j31, j32, j33
  real(8) :: s
  integer :: k, kmin, kmax

  kmin = max(abs(j11-j33), abs(j12-j23), abs(j21-j32))
  kmax = min(j11+j33, j12+j23, j21+j32)

  s = 0.0d0
  do k = kmin, kmax, 2
     s = s + (k+1.0d0) &
          & * d6j(j11, j12, j13, j23, j33, k) &
          & * d6j(j21, j22, j23, j12, k, j32) &
          & * d6j(j31, j32, j33, k, j11, j21)
  end do
  s = s * (-1)**kmin

end function d9j

function dfunc(j, m1, m2, beta) result(s)
!
!  d-function 
!
!  dfunc(j, m1, m2, beta) = d^(j/2)_((m1)/2,(m2)/2)(beta)
!  = <j/2 (m1)/2|exp(+i*beta*jy)|j/2 (m2)/2>
!
!  see A. deShalit and H. Feshbach, Theoretical Nuclear Physics, Vol. 1,
!  p. 920, eq. (2.13)
!
  implicit none
  integer, intent(in) :: j, m1, m2
  real(8), intent(in) :: beta
  real(8) :: s
  integer :: ia, iamin, iamax
  integer :: jm1, jm2, isign, mm
  real(8) :: sb, cb

! error check
  if (j < 0 .or. abs(m1) > j .or. abs(m2) > j &
       & .or. mod(j-m1, 2) == 1 .or. mod(j-m2, 2) == 1) then
     write(*,*) 'error [dfunc]: invalid input'
     write(*,'(1a,1i4,3x,1a,1i4,3x,1a,1i4)') &
          & 'j =', j, 'm1 =', m1, 'm2 =', m2
     stop
  end if

  jm1 = (j-m1)/2
  jm2 = (j-m2)/2
  mm = (m1+m2)/2
  sb = sin(beta/2.0d0)
  cb = cos(beta/2.0d0)

  iamin = max(0, -mm)
  iamax = min(jm1, jm2)

  s = 0.0d0
  isign = (-1)**(jm1-iamin)
  do ia = iamin, iamax
     s = s + isign * dbinomial(jm1, ia) * dbinomial(jm1+m1, jm2-ia) &
          & * sb**(jm1+jm2-2*ia) * cb**(mm+2*ia)
     isign = isign * (-1)
  end do
  s = s * sqrt(dbinomial(j, jm1)/dbinomial(j, jm2))

end function dfunc

!!!!!!!!!! private routines !!!!!!!!!!

function dbinomial(n, m) result(s)
!
!  binomial coefficient: n_C_m
!  s: double precision
!
  integer, intent(in) :: n, m
  real(8) :: s, s1, s2
  integer :: i, m1

  s = 1.0d0
  m1 = min(m, n-m)
  if (m1 == 0) return
  if (n > 1000) then
     write(*,'(1a, 1i6, 1a)') '[dbinomial]: n =', n, ' is too large'
     stop
  end if

  if (n < 250) then
     s1 = 1.0d0
     s2 = 1.0d0
     do i = 1, m1
        s1 = s1 * (n-i+1)
        s2 = s2 * (m1-i+1)
     end do
     s = s1 / s2
  else
     do i = 1, m1
        s = (s * (n-i+1)) / (m1-i+1)
     end do
  endif

end function dbinomial

subroutine triangle(j1, j2, j3, delta, info) 
!
!  triangle often used in calculation of 3j, 6j etc.
!  delta
!  = sqrt(((j1+j2-j3)/2)!((j1-j2+j3)/2)!((-j1+j2+j3)/2)!/(1+(j1+j2+j3)/2)!)
!
  implicit none
  integer, intent(in) :: j1, j2, j3
  real(8), intent(out) :: delta
  integer, intent(out) :: info
  integer :: js, k1, k2, k3

  info = 0
  js = j1 + j2 + j3
  k1 = j2 + j3 - j1
  k2 = j3 + j1 - j2
  k3 = j1 + j2 - j3

  if (j1 < 0 .or. j2 < 0 .or. j3 < 0) then
     write(*,*) 'error [triangle]: invalid j'
     write(*,'(1a, 1i4, 2x, 1a, 1i4, 2x, 1a, 1i4)') &
          & 'j1 =', j1, 'j2 =', j2, 'j3 =', j3
     stop 
  end if
  if (k1 < 0 .or. k2 < 0 .or. k3 < 0 .or. mod(js, 2) /=0) then
     info = 1
     return
  endif

! exclude too large arguments to prevent from round-off error
  if (js > 300) then
     write(*,'(1a, 1i5, 1a)') '[triangle]: j1+j2+j3 =', js, ' is too large'
     stop
  end if

  js = js / 2
  k1 = k1 / 2

  delta = 1.0d0 / &
       & (sqrt(dbinomial(js, j3)) * sqrt(dbinomial(j3, k1)) * sqrt(js+1.0d0))

end subroutine triangle

end module rotation_group
