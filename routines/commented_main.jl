# Packages. Note that, one may have to activate a given enviroment
# to make sure the versions of the packages are compatible. This can
# be done, for instance, with the ferflow.jl enviroment. To do this:
# using Pkg
# Pkg.activate(PATH)
# or by entering the Pkg mode with the ] key and running
# activate PATH
# where in PATH one should find Manifest.toml and Proyect.toml
using LatticeGPU,CUDA,TimerOutputs

# First, we select a GPU. One can run nvidia-smi in the terminal to
# see a full list. The function device() allows to see the GPU that is
# selected. One can change this with device!(NUMBER), the default value is
# device!(0)
device()

# SpaceParam contains the information on the lattice geometry.
# The parameters are, in order, the dimension of the space,
# the dimensions of the lattice (time dimension
# is the last one), the sub-blocks of the GPU
# parallelization (each component must divide the respective
# dimension of the lattice), the boundary conditions and the twist tensor
# for the YM case. The possible boundary conditions are:
#
# BC_PERIODIC = 0
# BC_SF_ORBI  = 1
# BC_SF_AFWB  = 2
# BC_OPEN     = 3
#
# The convention for SF and open is the same as in openqcd: for SF
# the time extent T/a is lp.iL[4], while for open we have lp.iL[4]-1
# (lp.iL is the lattice size)
lp = SpaceParm{4}((16,16,16,16),(4,4,4,4),BC_PERIODIC,(0,0,0,0,0,0))

# The gauge parameters for the action. The variables are: the
# type of group elements (SU3 and SU2 available), the value of beta,
# the value of c0 (Wilson c0=1), the value of the boundary coefficient cG,
# the angles \phi_1, \phi_2 of the boundary values for the SF boundary
# conditions, and the dimensions of the lattice.
gp = GaugeParm{Float64}(SU3{Float64},6.0,5/3,(1.0,1.0),(0.0,0.0),lp.iL)

# Integration scheme for the HMC. The values are epsilon and the number
# of steps in the integration. There available integrators are leapfrog(...),
# omf2(), omf4() (Omelyan integrator orders 2 and 4)
intsch = omf4(Float64,0.01,50)

# Integration scheme for the flow. Variables are the initial step for adaptive
# step case and the tolerance. The value of epsilon in the fixed step case is passed
# as an input in the flow function, but it can be ommited and the value of epsilon
# in this integrator will be assumed. Available options for this structure are wfl_euler,
# wfl_rk2, wfl_rk3 (Runge-Kutta integrator orders 2 and 3). One can change wfl for zth to
# do the Zeuthen flow.
wflw = wfl_rk3(Float64, 0.01, 1.0E-7)

# Workspace for the YM fields. This structure allocates the necessary fields
# for the HMC and flow integration. More details are available in the documentation.
ymws = YMworkspace(SU3,Float64,lp);

# The actual gauge field we will work with.
U = vector_field(SU3{Float64},lp);

# DiracParam stores the parameters of one dirac operator. The arguments of
# the constructor are: the representation of the fermion (SU3fund and SU2fund
# avaiable), the value of the bare mass, the value of c_sw, the values of theta
# (Note that this are the values of the full term, not the phases. One Should take
# care in imposing || \theta ||^2 = 1), the value of the twisted mass and the value
# of the boundary coefficient for Dirichlet boundary conditions (c_F or \tilde{c_t}).
dpar = DiracParam{Float64}(SU3fund,0.2,1.0,(1.0,1.0,1.0,1.0),0.0,1.0)

# The workspace for the Dirac operator. More details on the documentation.
dws = DiracWorkspace(SU3fund,Float64,lp);

# Allocation to store the quark propagators. The way to allocate this is
# CuArray (CUDA array in the GPU) > Spinor > SU3fund > Complex{Float64}
psi = scalar_field(Spinor{4,SU3fund{Float64}},lp);

# We start with a cold configuration. To start with a hot configuration
# we could do the following:
# randomize!(ymws.mom, lp, ymws)
# U = exp.(ymws.mom)
fill!(U,one(SU3{Float64}));

# We set the propagator to zero
fill!(psi,zero(eltype(scalar_field(Spinor{4,SU3fund{Float64}},lp))));

# We allocate a copy of the configuration in the CPU. We will only allocate
# it once in memory, and then copy the configuration in that allocated array.
U0_CPU = Array(U);

# Scalar Array in the CPU to store the propagator contractions.
pp_corr = zeros(lp.iL[4]);
pp_density = Array(norm2.(psi));

# Some parameters
Nmc = 2
Nth = 50
Tflow = 1.0
Tsrc = 1

# We thermalize the configuration. The function HMC! modifies the value of U
# and returns the value of the energy violation and a boolean for whether the
# configuration was accepted.
for _ in 1:Nth
    HMC!(U,intsch,lp,gp,ymws)
end


#Monte-Carlo Chain
for i in 1:Nmc
    println("\n### MC step n",i," ###")
    dh,acc = HMC!(U,intsch,lp,gp,ymws)
    println("Delta H : ",dh)
    println("Config accepted : ", acc)

    # Note that, to make a copy of the config, we use ".=". This does the operation
    # element by element and does not allocate the Array again. This dot notation can
    # be also applied to functions, so the function
    # dmul.(Gamma{4},psi)
    # will do a Dirac multuplication with \Gamma_4 (temporal gamma) to EACH element of
    # the GPU Array psi. This can be used with both GPU and CPU arrays.
    U0_CPU .= Array(U)

    # Some observables. The energy density and topological charge return the volume sum,
    # but one can also store the euclidean time dependence.
    println(" ### Some observables ###")
    println("Plaquette : ",              plaquette(U, lp, gp, ymws))
    println("Energy density plaquette: ",Eoft_plaq(U, gp, lp, ymws))
    println("Energy density clover: ",   Eoft_clover(U, gp, lp, ymws))
    println("Qtop : ",                   Qtop(U, gp, lp, ymws))

    # Integration of the flow equations for the adaptive step size up to t = Tflow. The
    # function returns the number of steps and the size of the steps in a tuple.
    # The integration with fixed stepsize can be done with
    #
    # flw(U, wflw, NUMBER OF STEPS, EPSILON, gp, lp, ymws)
    #
    # where one can omit EPSILON and the value of epsilon for the integrator
    # structure (wflw) is used
    ns, eps_list = flw_adapt(U, wflw, Tflow, gp, lp, ymws)

    println("### Flow ###")
    println("Plaquette : ",              plaquette(U, lp, gp, ymws))
    println("Energy density plaquette: ",Eoft_plaq(U, gp, lp, ymws))
    println("Energy density clover: ",   Eoft_clover(U, gp, lp, ymws))
    println("Qtop : ",                   Qtop(U, gp, lp, ymws))

    # We return U to the unflowed value stored in U0_CPU and save the configuration.
    copyto!(U,U0_CPU)

    # To save the configuration, uncomment the following line
    #save_cnfg("./runname_cnfg_n"*string(i), U, lp, gp)

# end
# The split in Monte-Carlo loops can be introduced to measure on a separate run.
# for i in 1:Nmc

    # To read the configuration, uncomment the following line
    # U = read_cnfg("./runname_cnfg_n"*string(i));

    U0_CPU .= Array(U)

    # The function Csw! computes de Sheikholeslami-Wohlert term and stores
    # it in dws.csw (the dot notation acess the values of the structure).
    Csw!(dws,U,gp,lp)

    # The function propagator! stores the propagator in the variable psi. The numerical
    # inputs here are the maximum number of iterations and the tolerance for the
    # solver (Conjugate gradient). Tsrc is the possition of the source (Normal distribution).
    # It also admits a point source with fixed spin and color. There are similar functions
    # for the boundary-to-bulk propagators for Dirichlet BC, like bndpropagator! and Tbndpropagator!
    niter = propagator!(psi, U, dpar, dws, lp, 10000, 1.0e-13, Tsrc)

    println("Inversion converged in ",niter," iterations with random source in t=", Tsrc)

    # We store the norm of the propagator for the pseudoscalar-pseudoscalar propagator.
    # Note that this will only compute the contraction once in the GPU and move the result
    # to the CPU thanks to the dot notation.
    # For the axial-pseudoscalar we would do
    # ap_density .= Array(dot.(psi,dmul.(Gamma{4},psi)))
    pp_density .= Array(norm2.(psi))
    pp_corr .= zeros(lp.iL[4])
    # 3D volume
    V3 = prod(lp.iL[1:3])

    for t in 1:lp.iL[4] for x in 1:lp.iL[1] for y in 1:lp.iL[2] for z in 1:lp.iL[3]
        # The function point_index returns the GPU- coordinate of the lattice point
        # (i,j,k,t). The function point_index does the opposite.
        b,r = point_index(CartesianIndex{lp.ndim}((x,y,z,t)),lp)
        pp_corr[t] += pp_density[b,r]/V3
    end end end end
    println("Estimation for the PP correlator:")
    for t in 1:lp.iL[4]
        println(pp_corr[t])
    end

    # Good practices tip: One could be tempted to do the following
    #
    # for t in 1:lp.iL[4] for a in 1:lp.iL[1] for b in 1:lp.iL[2] for c in 1:lp.iL[3]
    #     pp_corr[t] += norm2(psi[(point_index(CartesianIndex{lp.ndim}((a,b,c,t)),lp))...])
    # end end end end
    #
    # This is not efficient because of two reasons: the first one is that we are looping over an
    # array by hand, so the order in which we lopp over the memory pointers may not be optimal, while
    # by allowing the compiler to do it tends to be more optimized. The second reason is more
    # important for performance: it is very unefficient to acess GPU elements (CuArrays) by
    # scalar indexing (one by one) in the CPU, so one should move this to the CPU (Array)
    # before doing this. In many cases scalar indexing is not allowed (outside a GPU kernel),
    # you can use the macro CUDA.@allowscalar to allow it.


    # Now we perform the flow also for the fermion field. The method for the flow is the same,
    # but it has more parameters with respect to the one in for gauge fields only. The
    # same applies to the case of fixed step size.
    ns,eps_list = flw_adapt(U, psi, wflw, Tflow, gp, dpar, lp, ymws, dws)

    pp_corr .= zeros(lp.iL[4])
    pp_density .= Array(norm2.(psi))

    # Good practices tip: One can benchmark specific parts of the code with the macro
    # @timeit "NAME". This is done in different parts of the code inside the package.
    # To output the times, simply run " print_timer() ". to reset the timer run
    # reset_timer()

    @timeit "Volume sum" begin
    for t in 1:lp.iL[4] for x in 1:lp.iL[1] for y in 1:lp.iL[2] for z in 1:lp.iL[3]
        b,r = point_index(CartesianIndex{lp.ndim}((x,y,z,t)),lp)
            pp_corr[t] += pp_density[b,r]/V3
        end end end end
    end
    # This corresponds to computing the P(x)Pt(y) correlator with the source in x_0=Tsrc
    println("Estimation for the PPt correlator:")
    for t in 1:lp.iL[4]
        println(pp_corr[t])
    end

    copyto!(U,U0_CPU)

end

print_timer()
