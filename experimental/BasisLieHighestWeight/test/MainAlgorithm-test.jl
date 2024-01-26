include("MBOld.jl")

"""
We are testing our code in multiple ways. First, we calculated two small examples per hand and compare those. Then we 
check basic properties of the result. For example we know the size of our monomial basis. These properties get partially
used in the algorithm and could therefore be true for false results. We have another basic algorithm that solves the 
problem without the recursion, weightspaces and saving of computations. The third test compares the results we can 
compute with the weaker version.
"""

function compare_algorithms(dynkin::Symbol, n::Int64, lambda::Vector{Int64})
  # old algorithm
  mons_old = MBOld.basisLieHighestWeight(string(dynkin), n, lambda) # basic algorithm

  # new algorithm
  basis = basis_lie_highest_weight(dynkin, n, lambda)
  mons_new = monomials(basis)
  L = GAP.Globals.SimpleLieAlgebra(GAP.Obj(dynkin), n, GAP.Globals.Rationals)
  gap_dim = GAP.Globals.DimensionOfHighestWeightModule(L, GAP.Obj(lambda)) # dimension

  # comparison
  # convert set of monomials over different ring objects to string representation to compare for equality
  @test issetequal(string.(mons_old), string.(mons_new)) # compare if result of old and new algorithm match
  @test gap_dim == length(mons_new) # check if dimension is correct
end

function check_dimension(
  dynkin::Symbol, n::Int64, lambda::Vector{Int64}, monomial_ordering::Symbol
)
  basis = basis_lie_highest_weight(dynkin, n, lambda; monomial_ordering)
  L = GAP.Globals.SimpleLieAlgebra(GAP.Obj(dynkin), n, GAP.Globals.Rationals)
  gap_dim = GAP.Globals.DimensionOfHighestWeightModule(L, GAP.Obj(lambda)) # dimension
  @test gap_dim == dim(basis) == length(monomials(basis)) # check if dimension is correct
end

@testset "Test BasisLieHighestWeight" begin
  @testset "is_fundamental" begin
    @test BasisLieHighestWeight.is_fundamental([ZZ(0), ZZ(1), ZZ(0)])
    @test !BasisLieHighestWeight.is_fundamental([ZZ(0), ZZ(1), ZZ(1)])
  end

  @testset "compute_sub_weights" begin
    @test isequal(BasisLieHighestWeight.compute_sub_weights([ZZ(0), ZZ(0), ZZ(0)]), [])
    sub_weights = Vector{Vector{ZZRingElem}}([
      [1, 0, 0],
      [0, 1, 0],
      [0, 0, 1],
      [1, 1, 0],
      [1, 0, 1],
      [0, 1, 1],
      [1, 1, 1],
      [2, 0, 0],
      [0, 2, 0],
      [2, 1, 0],
      [1, 2, 0],
      [2, 0, 1],
      [0, 2, 1],
      [2, 1, 1],
      [1, 2, 1],
      [2, 2, 0],
      [0, 3, 0],
      [2, 2, 1],
      [1, 3, 0],
      [0, 3, 1],
      [1, 3, 1],
      [2, 3, 0],
    ])
    @test isequal(
      BasisLieHighestWeight.compute_sub_weights([ZZ(2), ZZ(3), ZZ(1)]), sub_weights
    )
  end

  @testset "Known examples basis_lie_highest_weight" begin
    base = basis_lie_highest_weight(:A, 2, [1, 0])
    mons = monomials(base)
    @test issetequal(string.(mons), Set(["1", "x3", "x1"]))
    base = basis_lie_highest_weight(:A, 2, [1, 0], [1, 2, 1])
    mons = monomials(base)
    @test issetequal(string.(mons), Set(["1", "x2*x3", "x3"]))
  end

  @testset "Compare basis_lie_highest_weight with algorithm of Johannes and check dimension" begin
    @testset "Dynkin type $dynkin" for dynkin in (:A, :B, :C, :D)
      @testset "n = $n" for n in 1:4
        if (
          !(dynkin == :B && n < 2) && !(dynkin == :C && n < 2) && !(dynkin == :D && n < 4)
        )
          for i in 1:n                                # w_i
            lambda = zeros(Int64, n)
            lambda[i] = 1
            compare_algorithms(dynkin, n, lambda)
          end

          if (n > 1)
            lambda = [1, (0 for i in 1:(n - 2))..., 1]  # w_1 + w_n
            compare_algorithms(dynkin, n, lambda)
          end

          if (n < 4)
            lambda = ones(Int64, n)                  # w_1 + ... + w_n
            compare_algorithms(dynkin, n, lambda)
          end
        end
      end
    end
  end

  @testset "Compare against GAP algorithm of Xin on some examples" begin
    basis_lusztig = basis_lie_highest_weight_lusztig(:A, 3, [2, 1, 1], [2, 3, 1, 2, 3, 1])

    @test issetequal(
      [only(exponents(m)) for m in monomials(basis_lusztig)],
      [
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 1, 0],
        [1, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1],
        [1, 0, 0, 0, 1, 0],
        [0, 0, 1, 0, 0, 0],
        [1, 0, 0, 0, 0, 1],
        [0, 1, 0, 0, 0, 0],
        [0, 0, 0, 0, 2, 0],
        [0, 0, 0, 0, 1, 1],
        [1, 0, 0, 0, 1, 1],
        [0, 0, 1, 0, 0, 1],
        [0, 1, 0, 0, 1, 0],
        [0, 0, 0, 1, 0, 0],
        [1, 0, 0, 0, 2, 0],
        [0, 0, 1, 0, 1, 0],
        [2, 0, 0, 0, 1, 0],
        [2, 0, 0, 0, 0, 1],
        [0, 1, 0, 0, 0, 1],
        [0, 0, 0, 0, 2, 1],
        [1, 0, 0, 0, 2, 1],
        [0, 0, 1, 0, 1, 1],
        [0, 1, 0, 0, 2, 0],
        [0, 0, 0, 1, 1, 0],
        [2, 0, 0, 0, 1, 1],
        [1, 0, 1, 0, 0, 1],
        [1, 1, 0, 0, 1, 0],
        [1, 0, 0, 1, 0, 0],
        [0, 1, 0, 0, 1, 1],
        [0, 0, 0, 1, 0, 1],
        [2, 0, 0, 0, 2, 0],
        [1, 0, 1, 0, 1, 0],
        [1, 1, 0, 0, 0, 1],
        [0, 0, 1, 0, 2, 0],
        [2, 0, 0, 0, 2, 1],
        [1, 0, 1, 0, 1, 1],
        [0, 0, 2, 0, 0, 1],
        [1, 1, 0, 0, 2, 0],
        [1, 0, 0, 1, 1, 0],
        [0, 1, 1, 0, 1, 0],
        [1, 1, 0, 0, 1, 1],
        [1, 0, 0, 1, 0, 1],
        [0, 1, 1, 0, 0, 1],
        [0, 2, 0, 0, 1, 0],
        [0, 0, 1, 0, 2, 1],
        [0, 0, 0, 1, 2, 0],
        [0, 1, 0, 0, 2, 1],
        [0, 0, 0, 1, 1, 1],
        [1, 0, 1, 0, 2, 0],
        [3, 0, 0, 0, 2, 0],
        [3, 0, 0, 0, 1, 1],
        [1, 1, 0, 0, 2, 1],
        [1, 0, 0, 1, 1, 1],
        [0, 1, 1, 0, 1, 1],
        [0, 0, 1, 1, 0, 1],
        [0, 2, 0, 0, 2, 0],
        [0, 1, 0, 1, 1, 0],
        [1, 0, 1, 0, 2, 1],
        [0, 0, 2, 0, 1, 1],
        [1, 0, 0, 1, 2, 0],
        [0, 1, 1, 0, 2, 0],
        [3, 0, 0, 0, 2, 1],
        [2, 0, 1, 0, 1, 1],
        [2, 1, 0, 0, 2, 0],
        [2, 0, 0, 1, 1, 0],
        [2, 1, 0, 0, 1, 1],
        [2, 0, 0, 1, 0, 1],
        [0, 2, 0, 0, 1, 1],
        [0, 0, 0, 1, 2, 1],
        [2, 0, 1, 0, 2, 0],
        [1, 0, 0, 1, 2, 1],
        [0, 1, 1, 0, 2, 1],
        [0, 0, 1, 1, 1, 1],
        [0, 1, 0, 1, 2, 0],
        [2, 1, 0, 0, 2, 1],
        [2, 0, 0, 1, 1, 1],
        [1, 1, 1, 0, 1, 1],
        [1, 0, 1, 1, 0, 1],
        [1, 2, 0, 0, 2, 0],
        [1, 1, 0, 1, 1, 0],
        [0, 2, 0, 0, 2, 1],
        [0, 1, 0, 1, 1, 1],
        [2, 0, 1, 0, 2, 1],
        [1, 0, 2, 0, 1, 1],
        [2, 0, 0, 1, 2, 0],
        [1, 1, 1, 0, 2, 0],
        [1, 2, 0, 0, 1, 1],
        [0, 0, 2, 0, 2, 1],
        [4, 0, 0, 0, 2, 1],
        [2, 0, 0, 1, 2, 1],
        [1, 1, 1, 0, 2, 1],
        [1, 0, 1, 1, 1, 1],
        [0, 1, 2, 0, 1, 1],
        [1, 1, 0, 1, 2, 0],
        [0, 2, 1, 0, 2, 0],
        [1, 2, 0, 0, 2, 1],
        [1, 1, 0, 1, 1, 1],
        [0, 2, 1, 0, 1, 1],
        [0, 3, 0, 0, 2, 0],
        [0, 0, 1, 1, 2, 1],
        [0, 1, 0, 1, 2, 1],
        [1, 0, 2, 0, 2, 1],
        [3, 0, 1, 0, 2, 1],
        [3, 0, 0, 1, 2, 0],
        [3, 1, 0, 0, 2, 1],
        [3, 0, 0, 1, 1, 1],
        [1, 1, 0, 1, 2, 1],
        [0, 2, 1, 0, 2, 1],
        [0, 1, 1, 1, 1, 1],
        [0, 2, 0, 1, 2, 0],
        [1, 0, 1, 1, 2, 1],
        [0, 1, 2, 0, 2, 1],
        [3, 0, 0, 1, 2, 1],
        [2, 1, 1, 0, 2, 1],
        [2, 0, 1, 1, 1, 1],
        [2, 1, 0, 1, 2, 0],
        [2, 2, 0, 0, 2, 1],
        [2, 1, 0, 1, 1, 1],
        [0, 3, 0, 0, 2, 1],
        [2, 0, 2, 0, 2, 1],
        [0, 1, 1, 1, 2, 1],
        [2, 1, 0, 1, 2, 1],
        [1, 2, 1, 0, 2, 1],
        [1, 1, 1, 1, 1, 1],
        [1, 2, 0, 1, 2, 0],
        [0, 2, 0, 1, 2, 1],
        [2, 0, 1, 1, 2, 1],
        [1, 1, 2, 0, 2, 1],
        [1, 3, 0, 0, 2, 1],
        [4, 0, 0, 1, 2, 1],
        [1, 1, 1, 1, 2, 1],
        [0, 2, 2, 0, 2, 1],
        [1, 2, 0, 1, 2, 1],
        [0, 3, 1, 0, 2, 1],
        [3, 0, 1, 1, 2, 1],
        [3, 1, 0, 1, 2, 1],
        [0, 2, 1, 1, 2, 1],
        [2, 1, 1, 1, 2, 1],
        [2, 2, 0, 1, 2, 1],
        [1, 2, 1, 1, 2, 1],
      ],
    )

    basis_string = basis_lie_highest_weight_string(:A, 3, [2, 1, 1], [2, 3, 1, 2, 3, 1])

    @test issetequal(
      [only(exponents(m)) for m in monomials(basis_string)],
      [
        [0, 0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0],
        [1, 0, 0, 0, 0, 0],
        [0, 1, 0, 0, 0, 0],
        [1, 0, 1, 0, 0, 0],
        [0, 0, 1, 1, 0, 0],
        [1, 1, 0, 0, 0, 0],
        [0, 1, 0, 1, 0, 0],
        [0, 0, 2, 0, 0, 0],
        [0, 1, 1, 0, 0, 0],
        [1, 1, 1, 0, 0, 0],
        [0, 1, 1, 1, 0, 0],
        [0, 1, 0, 1, 0, 1],
        [0, 0, 1, 1, 1, 0],
        [1, 0, 2, 0, 0, 0],
        [0, 0, 2, 1, 0, 0],
        [2, 0, 1, 0, 0, 0],
        [2, 1, 0, 0, 0, 0],
        [0, 2, 0, 1, 0, 0],
        [0, 1, 2, 0, 0, 0],
        [1, 1, 2, 0, 0, 0],
        [0, 1, 2, 1, 0, 0],
        [0, 1, 1, 1, 0, 1],
        [0, 0, 2, 1, 1, 0],
        [2, 1, 1, 0, 0, 0],
        [1, 1, 1, 1, 0, 0],
        [1, 1, 0, 1, 0, 1],
        [1, 0, 1, 1, 1, 0],
        [0, 2, 1, 1, 0, 0],
        [0, 2, 0, 1, 0, 1],
        [2, 0, 2, 0, 0, 0],
        [1, 0, 2, 1, 0, 0],
        [1, 2, 0, 1, 0, 0],
        [0, 0, 3, 1, 0, 0],
        [2, 1, 2, 0, 0, 0],
        [1, 1, 2, 1, 0, 0],
        [1, 1, 1, 1, 0, 1],
        [1, 0, 2, 1, 1, 0],
        [0, 1, 1, 2, 0, 1],
        [0, 0, 2, 2, 1, 0],
        [1, 2, 1, 1, 0, 0],
        [1, 2, 0, 1, 0, 1],
        [0, 2, 0, 2, 0, 1],
        [0, 1, 1, 2, 1, 0],
        [0, 1, 3, 1, 0, 0],
        [0, 0, 3, 1, 1, 0],
        [0, 2, 2, 1, 0, 0],
        [0, 2, 1, 1, 0, 1],
        [1, 0, 3, 1, 0, 0],
        [3, 0, 2, 0, 0, 0],
        [3, 1, 1, 0, 0, 0],
        [1, 2, 2, 1, 0, 0],
        [1, 2, 1, 1, 0, 1],
        [0, 2, 1, 2, 0, 1],
        [0, 2, 0, 2, 0, 2],
        [0, 1, 2, 2, 1, 0],
        [0, 1, 1, 2, 1, 1],
        [1, 1, 3, 1, 0, 0],
        [1, 0, 3, 1, 1, 0],
        [0, 1, 2, 2, 0, 1],
        [0, 0, 3, 2, 1, 0],
        [3, 1, 2, 0, 0, 0],
        [2, 1, 2, 1, 0, 0],
        [2, 1, 1, 1, 0, 1],
        [2, 0, 2, 1, 1, 0],
        [2, 2, 1, 1, 0, 0],
        [2, 2, 0, 1, 0, 1],
        [0, 3, 0, 2, 0, 1],
        [0, 2, 3, 1, 0, 0],
        [2, 0, 3, 1, 0, 0],
        [1, 2, 3, 1, 0, 0],
        [0, 2, 2, 2, 0, 1],
        [0, 1, 3, 2, 1, 0],
        [0, 1, 2, 2, 1, 1],
        [2, 2, 2, 1, 0, 0],
        [2, 2, 1, 1, 0, 1],
        [1, 2, 1, 2, 0, 1],
        [1, 2, 0, 2, 0, 2],
        [1, 1, 2, 2, 1, 0],
        [1, 1, 1, 2, 1, 1],
        [0, 3, 1, 2, 0, 1],
        [0, 3, 0, 2, 0, 2],
        [2, 1, 3, 1, 0, 0],
        [2, 0, 3, 1, 1, 0],
        [1, 1, 2, 2, 0, 1],
        [1, 0, 3, 2, 1, 0],
        [1, 3, 0, 2, 0, 1],
        [0, 0, 4, 2, 1, 0],
        [4, 1, 2, 0, 0, 0],
        [2, 2, 3, 1, 0, 0],
        [1, 2, 2, 2, 0, 1],
        [1, 1, 3, 2, 1, 0],
        [1, 1, 2, 2, 1, 1],
        [0, 2, 1, 3, 0, 2],
        [0, 1, 2, 3, 1, 1],
        [1, 3, 1, 2, 0, 1],
        [1, 3, 0, 2, 0, 2],
        [0, 3, 0, 3, 0, 2],
        [0, 2, 1, 3, 1, 1],
        [0, 1, 4, 2, 1, 0],
        [0, 3, 2, 2, 0, 1],
        [1, 0, 4, 2, 1, 0],
        [3, 1, 3, 1, 0, 0],
        [3, 0, 3, 1, 1, 0],
        [3, 2, 2, 1, 0, 0],
        [3, 2, 1, 1, 0, 1],
        [1, 3, 2, 2, 0, 1],
        [0, 3, 1, 3, 0, 2],
        [0, 2, 2, 3, 1, 1],
        [0, 2, 1, 3, 1, 2],
        [1, 1, 4, 2, 1, 0],
        [0, 1, 3, 3, 1, 1],
        [3, 2, 3, 1, 0, 0],
        [2, 2, 2, 2, 0, 1],
        [2, 1, 3, 2, 1, 0],
        [2, 1, 2, 2, 1, 1],
        [2, 3, 1, 2, 0, 1],
        [2, 3, 0, 2, 0, 2],
        [0, 4, 0, 3, 0, 2],
        [2, 0, 4, 2, 1, 0],
        [0, 2, 3, 3, 1, 1],
        [2, 3, 2, 2, 0, 1],
        [1, 3, 1, 3, 0, 2],
        [1, 2, 2, 3, 1, 1],
        [1, 2, 1, 3, 1, 2],
        [0, 4, 1, 3, 0, 2],
        [2, 1, 4, 2, 1, 0],
        [1, 1, 3, 3, 1, 1],
        [1, 4, 0, 3, 0, 2],
        [4, 2, 3, 1, 0, 0],
        [1, 2, 3, 3, 1, 1],
        [0, 2, 2, 4, 1, 2],
        [1, 4, 1, 3, 0, 2],
        [0, 3, 1, 4, 1, 2],
        [3, 1, 4, 2, 1, 0],
        [3, 3, 2, 2, 0, 1],
        [0, 3, 2, 4, 1, 2],
        [2, 2, 3, 3, 1, 1],
        [2, 4, 1, 3, 0, 2],
        [1, 3, 2, 4, 1, 2],
      ],
    )

    basis_nz = basis_lie_highest_weight_nz(:A, 3, [2, 1, 1], [2, 3, 1, 2, 3, 1])

    @test issetequal(
      [only(exponents(m)) for m in monomials(basis_nz)],
      [
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 1],
        [0, 0, 0, 1, 0, 0],
        [0, 0, 0, 0, 1, 0],
        [0, 0, 0, 1, 0, 1],
        [0, 0, 1, 1, 0, 0],
        [0, 0, 0, 1, 1, 0],
        [0, 1, 0, 1, 0, 0],
        [0, 0, 0, 0, 0, 2],
        [0, 0, 0, 0, 1, 1],
        [0, 0, 0, 1, 1, 1],
        [0, 1, 0, 1, 0, 1],
        [0, 0, 1, 1, 1, 0],
        [0, 1, 1, 1, 0, 0],
        [0, 0, 0, 1, 0, 2],
        [0, 0, 1, 1, 0, 1],
        [0, 0, 0, 2, 0, 1],
        [0, 0, 0, 2, 1, 0],
        [0, 1, 0, 1, 1, 0],
        [0, 0, 0, 0, 1, 2],
        [0, 0, 0, 1, 1, 2],
        [0, 1, 0, 1, 0, 2],
        [0, 0, 1, 1, 1, 1],
        [0, 1, 1, 1, 0, 1],
        [0, 0, 0, 2, 1, 1],
        [0, 1, 0, 2, 0, 1],
        [0, 0, 1, 2, 1, 0],
        [1, 1, 1, 1, 0, 0],
        [0, 1, 0, 1, 1, 1],
        [0, 1, 1, 1, 1, 0],
        [0, 0, 0, 2, 0, 2],
        [0, 0, 1, 2, 0, 1],
        [0, 1, 0, 2, 1, 0],
        [0, 0, 1, 1, 0, 2],
        [0, 0, 0, 2, 1, 2],
        [0, 1, 0, 2, 0, 2],
        [0, 0, 1, 2, 1, 1],
        [0, 1, 1, 2, 0, 1],
        [1, 1, 1, 1, 0, 1],
        [0, 0, 2, 2, 1, 0],
        [0, 1, 0, 2, 1, 1],
        [0, 2, 0, 2, 0, 1],
        [0, 1, 1, 2, 1, 0],
        [1, 1, 1, 1, 1, 0],
        [0, 0, 1, 1, 1, 2],
        [0, 1, 1, 1, 0, 2],
        [0, 1, 0, 1, 1, 2],
        [0, 1, 1, 1, 1, 1],
        [0, 0, 1, 2, 0, 2],
        [0, 0, 0, 3, 0, 2],
        [0, 0, 0, 3, 1, 1],
        [0, 1, 0, 2, 1, 2],
        [0, 2, 0, 2, 0, 2],
        [0, 1, 1, 2, 1, 1],
        [1, 1, 1, 1, 1, 1],
        [0, 2, 1, 2, 0, 1],
        [0, 1, 2, 2, 1, 0],
        [0, 0, 1, 2, 1, 2],
        [0, 1, 1, 2, 0, 2],
        [1, 1, 1, 1, 0, 2],
        [0, 0, 2, 2, 1, 1],
        [0, 0, 0, 3, 1, 2],
        [0, 1, 0, 3, 0, 2],
        [0, 0, 1, 3, 1, 1],
        [1, 1, 1, 2, 0, 1],
        [0, 1, 0, 3, 1, 1],
        [1, 1, 1, 2, 1, 0],
        [0, 2, 0, 2, 1, 1],
        [0, 1, 1, 1, 1, 2],
        [0, 0, 1, 3, 0, 2],
        [0, 1, 1, 2, 1, 2],
        [1, 1, 1, 1, 1, 2],
        [0, 2, 1, 2, 0, 2],
        [0, 1, 2, 2, 1, 1],
        [0, 1, 0, 3, 1, 2],
        [0, 2, 0, 3, 0, 2],
        [0, 1, 1, 3, 1, 1],
        [1, 1, 1, 2, 1, 1],
        [1, 2, 1, 2, 0, 1],
        [1, 1, 2, 2, 1, 0],
        [0, 2, 0, 2, 1, 2],
        [0, 2, 1, 2, 1, 1],
        [0, 0, 1, 3, 1, 2],
        [0, 1, 1, 3, 0, 2],
        [1, 1, 1, 2, 0, 2],
        [0, 0, 2, 3, 1, 1],
        [0, 2, 0, 3, 1, 1],
        [0, 0, 2, 2, 1, 2],
        [0, 0, 0, 4, 1, 2],
        [0, 1, 1, 3, 1, 2],
        [1, 1, 1, 2, 1, 2],
        [0, 2, 1, 3, 0, 2],
        [1, 2, 1, 2, 0, 2],
        [0, 1, 2, 3, 1, 1],
        [1, 1, 2, 2, 1, 1],
        [0, 2, 0, 3, 1, 2],
        [0, 3, 0, 3, 0, 2],
        [0, 2, 1, 3, 1, 1],
        [1, 2, 1, 2, 1, 1],
        [0, 1, 2, 2, 1, 2],
        [0, 2, 1, 2, 1, 2],
        [0, 0, 2, 3, 1, 2],
        [0, 0, 1, 4, 1, 2],
        [1, 1, 1, 3, 0, 2],
        [0, 1, 0, 4, 1, 2],
        [1, 1, 1, 3, 1, 1],
        [0, 2, 1, 3, 1, 2],
        [1, 2, 1, 2, 1, 2],
        [0, 3, 1, 3, 0, 2],
        [0, 2, 2, 3, 1, 1],
        [0, 1, 2, 3, 1, 2],
        [1, 1, 2, 2, 1, 2],
        [0, 1, 1, 4, 1, 2],
        [1, 1, 1, 3, 1, 2],
        [1, 2, 1, 3, 0, 2],
        [1, 1, 2, 3, 1, 1],
        [0, 2, 0, 4, 1, 2],
        [1, 2, 1, 3, 1, 1],
        [0, 3, 0, 3, 1, 2],
        [0, 0, 2, 4, 1, 2],
        [0, 2, 2, 3, 1, 2],
        [0, 2, 1, 4, 1, 2],
        [1, 2, 1, 3, 1, 2],
        [1, 3, 1, 3, 0, 2],
        [1, 2, 2, 3, 1, 1],
        [0, 3, 1, 3, 1, 2],
        [0, 1, 2, 4, 1, 2],
        [1, 1, 2, 3, 1, 2],
        [0, 3, 0, 4, 1, 2],
        [1, 1, 1, 4, 1, 2],
        [0, 2, 2, 4, 1, 2],
        [1, 2, 2, 3, 1, 2],
        [0, 3, 1, 4, 1, 2],
        [1, 3, 1, 3, 1, 2],
        [1, 1, 2, 4, 1, 2],
        [1, 2, 1, 4, 1, 2],
        [0, 3, 2, 4, 1, 2],
        [1, 2, 2, 4, 1, 2],
        [1, 3, 1, 4, 1, 2],
        [1, 3, 2, 4, 1, 2],
      ],
    )
  end

  @testset "Check dimension" begin
    @testset "Monomial order $monomial_ordering" for monomial_ordering in
                                                     (:lex, :invlex, :degrevlex)
      check_dimension(:A, 3, [1, 1, 1], monomial_ordering)
      #check_dimension(:B, 3, [2,1,0], monomial_ordering)
      #check_dimension(:C, 3, [1,1,1], monomial_ordering)
      #check_dimension(:D, 4, [3,0,1,1], monomial_ordering)
      #check_dimension(:F, 4, [2,0,1,0], monomial_ordering)
      #check_dimension(:G, 2, [1,0], monomial_ordering)
      #check_dimension(:G, 2, [2,2], monomial_ordering)
    end
  end
end
