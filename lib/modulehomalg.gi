#######################################################################
##
#O  PushOut(<f>, <g>)
##
##  This function finds the pushout of the homomorphisms 
##                    f
##              A ---------> B 
##              |            |
##              | g          | g'
##              |            |
##              V    f'      V
##              C ---------> E
##  in that it returns the homomorphisms  [f', g']. 
##
InstallMethod( PushOut,
   "for two homomorphisms starting in a common module over a path algebra",
   [ IsPathAlgebraMatModuleHomomorphism, IsPathAlgebraMatModuleHomomorphism ], 0,
   function( f, g ) 

   local B, C, CplusB, inclusions, projections, h;

   if Source(f) = Source(g) then 
      B := Range(f);
      C := Range(g);
      CplusB := DirectSumOfModules([C,B]);
      inclusions := DirectSumInclusions(CplusB);
      h := f*inclusions[2]-g*inclusions[1];
      h := CoKernelProjection(h);

      return [inclusions[1]*h,inclusions[2]*h];
   else
      Print("Error: The two maps entered don't start in the same module.\n");
      return fail;
   fi;
end
);

#######################################################################
##
#O  PullBack(<f>, <g>)
##
##  This function finds the pullback of the homomorphisms 
##                    f'
##              E ---------> C 
##              |            |
##              | g'         | g
##              |            |
##              V     f      V
##              A ---------> B
##  in that it returns the homomorphisms  [f', g']. 
##
InstallMethod( PullBack,
   "for two homomorphisms ending in a common module over a path algebra",
   [ IsPathAlgebraMatModuleHomomorphism, IsPathAlgebraMatModuleHomomorphism ], 0,
   function( f, g ) 

   local A, C, AplusC, projections, h;

   if Range(f) = Range(g) then 
      A := Source(f);
      C := Source(g);
      AplusC := DirectSumOfModules([A,C]);
      projections := DirectSumProjections(AplusC);
      h := projections[1]*f-projections[2]*g;
      h := KernelInclusion(h);

      return [h*projections[2],h*projections[1]];
   else
      Print("Error: The two maps entered don't end in the same module.\n");
      return fail;
   fi;
end
);

#######################################################################
##
#O  IsOmegaPeriodic( <M>, <n> )
##
##  This function tests if the module  <M>  is \Omega-periodic, that is,
##  if  M \simeq \Omega^i(M)  when  i  ranges over the set {1,2,...,n}.
##  Otherwise it returns false.
##
InstallMethod( IsOmegaPeriodic, 
   "for a path algebra matmodule and an integer",
   [ IsPathAlgebraMatModule, IS_INT  ], 0,
   function( M, n ) 

   local N0, N1, i;
 
   N0 := M;
   for i in [1..n] do
      Print("Computing syzygy number: ",i,"\n");
      N1 := 1stSyzygy(N0);
      if IsomorphicModules(M,N1) then
         return i;
      else
         N0 := N1;
      fi;
   od;
   return false;
end
);

#######################################################################
##
#O  1stSyzygy( <M> )
##
##  This function computes the first syzygy of the module  <M>  by first
##  finding a minimal set of generators for  <M>, then finding the 
##  projective cover and computing the first syzygy as a submodule of 
##  this module.
##
InstallMethod( 1stSyzygy,
   "for a path algebra",
   [ IsPathAlgebraMatModule ], 0,
   function( M ) 

   local A, Q, K, num_vert, vertices, verticesinalg, arrows, B, BB, B_M, 
         G, MM, r, test, projective_cover, s, projective_vector, Solutions, 
         syzygy, zero_in_P, big_mat, mat, a, arrow, arrows_of_quiver, dom_a,
	 im_a, pd, pi, dim_vect, first_syzygy, V, BV, m, v, 
         cycle_list, i, j, b,  
         pos, commutators, center, zero_count, c, x, cycles, matrix,
         data, coeffs, fam, elms, solutions, gbb, run_time, BU, FlatBasisSyzygy,
         partial,temp,V_list,B_list;

   A:= RightActingAlgebra(M);   
   if Dimension(M) = 0 then 
       return ZeroModule(A);
   fi;
   B := CanonicalBasis(A);
   Q := QuiverOfPathAlgebra(A); 
   K := LeftActingDomain(A);
   num_vert := NumberOfVertices(Q);
   vertices := VerticesOfQuiver(Q);
   if IsPathAlgebra(A) then 
      verticesinalg := GeneratorsOfAlgebra(A){[1..num_vert]};
      arrows   := GeneratorsOfAlgebra(A){[1+num_vert..num_vert+NumberOfArrows(Q)]};   
   else 
      verticesinalg := GeneratorsOfAlgebra(A){[2..1+num_vert]};
      arrows   := GeneratorsOfAlgebra(A){[2+num_vert..1+num_vert+NumberOfArrows(Q)]};
   fi;
#
#  Finding a basis of each indecomposable right projective A-module
#
   BB := [];
   for i in [1..num_vert] do 
      BB[i] := [];
   od;
   for i in [1..num_vert] do 
      for j in [1..Length(B)] do 
         if verticesinalg[i]*B[j] <> Zero(A) then
            Add(BB[i],B[j]);
         fi;
      od;
   od;
#
# Finding a basis for the module M and a set of minimal generators
#
   B_M := CanonicalBasis(M);
   G   := MinimalGeneratingSetOfModule(M);
#
#  Assuming that the generators G of M is uniform.
#  Finding generators multiplied with all basis elements of A.
#
   MM := [];
   projective_cover := [];
   for i in [1..Length(G)] do
      r := 0;
      repeat 
         r := r + 1;
         test := G[i]^verticesinalg[r] <> Zero(M);
      until test;
      projective_cover[i] := r;
       for j in [1..Length(BB[r])] do 
         Add(MM,G[i]^BB[r][j]); 
      od;
   od;
#
# Finding the matrix with the rows being the generators of M times the 
# the basis of the corresponding projective.
#
   matrix := NullMat(Length(MM),Dimension(M),K);
   for i in [1..Length(MM)] do
      matrix[i] := Flat(ExtRepOfObj(MM[i])![1]);
   od;
#
#  Finding the kernel of the projective cover as a vectorspace 
#  
   solutions := NullspaceMat(matrix);
#
# Finding the kernel as a submodule of the projective cover.
#
   Solutions := [];
   for i in [1..Length(solutions)] do
      projective_vector := [];
      s := 0;
      for j in [1..Length(projective_cover)] do
         a := Zero(A);
         for r in [1..Length(BB[projective_cover[j]])] do
            a := a + BB[projective_cover[j]][r]*solutions[i][r+s];
         od;
         Add(projective_vector,a);
         s := s + Length(BB[projective_cover[j]]);
      od;
      Add(Solutions,projective_vector);
   od;
#
# Finding a uniform basis for the syzygy.
# 
   syzygy := [];
   for i in [1..num_vert] do 
      syzygy[i] := [];
   od;
   zero_in_P := [];
   for i in [1..Length(G)] do
      Add(zero_in_P,Zero(A));
   od;
   for i in [1..num_vert] do 
      for j in [1..Length(Solutions)] do 
         if Solutions[j]*verticesinalg[i] <> zero_in_P then
            Add(syzygy[i],Solutions[j]*verticesinalg[i]);
         fi;
      od;
   od;

   for i in [1..num_vert] do
      if Length(syzygy[i]) > 0 then
         syzygy[i] := TipReduceVectors(A,syzygy[i]);
      fi;
   od;

   arrows_of_quiver := GeneratorsOfQuiver(Q){[1+num_vert..num_vert+Length(ArrowsOfQuiver(Q))]};
#
# Finding the dimension vector of the syzygy.
#
   dim_vect := List(syzygy,x->Length(x));
#
# Finding a basis for the vectorspace in each vertex for the syzygy.
#
   BU := Basis(UnderlyingLeftModule(B));   
   FlatBasisSyzygy := [];
   for i in [1..num_vert] do
      if dim_vect[i] > 0 then
         partial := [];
         for j in [1..dim_vect[i]] do
            Add(partial,Flat(List(syzygy[i][j],x->Coefficients(BU,x))));
         od;
         Add(FlatBasisSyzygy,partial);
      else
         Add(FlatBasisSyzygy,[]);
      fi;
   od;
#
# Constructing the vectorspace in each vertex in the syzygy and 
# saying that the basis is the generators we have found.
#
  V_list := []; 
  for i in [1..num_vert] do
     if FlatBasisSyzygy[i] <> [] then 
        Add(V_list,VectorSpace(K,FlatBasisSyzygy[i],"basis"));
     else
        Add(V_list,Subspace(K,[]));
     fi;
   od;
   B_list := [];
   for i in [1..num_vert] do 
      Add(B_list,Basis(V_list[i],FlatBasisSyzygy[i]));
   od;
   Print("Dimension vector for syzygy: ",dim_vect,"\n");
#
#  Finding the 1st syzygy as a representation of the quiver.
#
   big_mat:=[];
   for a in arrows do
      mat := [];
      for v in verticesinalg do
         if v*a <> Zero(A) then
              dom_a := v;
         fi;
      od;
      for v in verticesinalg do
         if a*v <> Zero(A) then
            im_a := v;
         fi;
      od; 
        
      pd := Position(verticesinalg,dom_a);
      pi := Position(verticesinalg,im_a);
        
      arrow := arrows_of_quiver[Position(arrows,a)];
      if ( dim_vect[pd] = 0 ) or ( dim_vect[pi] = 0 ) then 
         mat := [dim_vect[pd],dim_vect[pi]];
      else 
         for m in syzygy[pd] do
            temp := Flat(List(m*a,x->Coefficients(BU,x)));
            temp := Coefficients(B_list[pi],temp);
            Add(mat,temp);
         od;
      fi;
      Add(big_mat,[arrow,mat]);
   od;
#
# Creating the syzygy as a representation of the quiver.
#
   if IsPathAlgebra(A) then 
      first_syzygy := RightModuleOverPathAlgebra(A,big_mat);
   else
      first_syzygy := RightModuleOverPathAlgebra(A,big_mat); 
   fi;      

   return first_syzygy;
end
);

#######################################################################
##
#O  NthSyzygy( <M>, <n> )
##
##  This functions computes the  <n>-th syzygy of the module  <M> by 
##  successively computing first, second, third, ... syzygy of  <M> 
##  using the operation  1stSyzygy  and at each stage checking if the 
##  syzygy is a projective module. It returns the  <n>-th syzygy if 
##  no previous syzygy is projective, and if  <M>  has projective 
##  dimension less than  <n>, then it returns the last non-zero 
##  projective syzygy. 
##
InstallMethod( NthSyzygy,
   "for a path algebra module and a positive integer",
   [ IsPathAlgebraMatModule, IS_INT ], 0,
   function( M, n ) 

   local i, result;
 
   result := ShallowCopy(M);
   if IsProjectiveModule(M) then 
      Print("The module entered is projective.\n");
   else 
      for i in [1..n] do
         Print("Computing syzygy number: ",i," ...\n");
         result := 1stSyzygy(result);
         Print("Top of the ",i,"th syzygy: ",DimensionVector(TopOfModule(result)),"\n");
         if IsProjectiveModule(result) then 
            Print("The module has projective dimension ",i,".\n");
            break;
         fi;
      od;
   fi;

   return result;
end
);

#######################################################################
##
#O  NthSyzygyNC( <M>, <n> )
##
##  This function computes the  <n>-th syzygy of the module  <M>  by 
##  successively computing first, second, third, ... syzygy of  <M>
##  using the operation  1stSyzygy. If the module  <M>  has projective
##  dimension less than  <n>, then it prints the projective dimension 
##  of the module.
##
InstallMethod( NthSyzygyNC,
   "for a path algebra module and a positive integer",
   [ IsPathAlgebraMatModule, IS_INT ], 0,
   function( M, n ) 

   local i, result;
 
   result := ShallowCopy(M);
   for i in [1..n] do
      Print("Computing syzygy number: ",i," ....\n");
      result := 1stSyzygy(result);
      if Dimension(result) = 0 then 
         Print("The module has projective dimension ",i-1,".\n");
         break;
      fi;
   od;

   return result;
end
);

#######################################################################
##
#O  MinimalRightApproximation( <M>, <C> )
##
##  This function computes the minimal right add<M>-approximation of the
##  module  <C>.  TODO/CHECK: If one can modify the algorithm as indicated
##  below with ####.
##
InstallMethod ( MinimalRightApproximation, 
   "for two PathAlgebraMatModules",
   true,
   [ IsPathAlgebraMatModule, IsPathAlgebraMatModule ],
   0,
   function( M, C )

   local K, HomMC, EndM, radEndM, radHomMC, i, j, FlatHomMC, 
         FlatradHomMC, V, BB, W, f, VoverW, B, gens, approx, approxmap;

   if RightActingAlgebra(M) = RightActingAlgebra(C) then 
      K := LeftActingDomain(M);
      HomMC := HomOverAlgebra(M,C);
      if Length(HomMC) = 0 then 
         return ZeroMapping(ZeroModule(RightActingAlgebra(M)),C);
      else  
         EndM  := EndOverAlgebra(M);
         radEndM := RadicalOfAlgebra(EndM);
         radEndM := BasisVectors(Basis(radEndM));
         radEndM := List(radEndM, x -> FromEndMToHomMM(M,x));
         radHomMC := [];
         for i in [1..Length(HomMC)] do
            for j in [1..Length(radEndM)] do
               Add(radHomMC,radEndM[j]*HomMC[i]);
            od;
         od;
         FlatHomMC := List(HomMC, x -> Flat(x!.maps));
         FlatradHomMC := List(radHomMC, x -> Flat(x!.maps));
         V := VectorSpace(K,FlatHomMC,"basis");
         BB := Basis(V,FlatHomMC);
         W := Subspace(V,FlatradHomMC);
         f := NaturalHomomorphismBySubspace( V, W );
         VoverW := Range(f);
         B := BasisVectors(Basis(VoverW));
         gens := List(B, x -> PreImagesRepresentative(f,x)); 
         gens := List(gens, x -> Coefficients(BB,x));
         gens := List(gens, x -> LinearCombination(HomMC,x));         
####         gens := List(gens, x -> RightMinimalVersion(x)[1]);
         approx := List(gens, x -> Source(x));
         approx := DirectSumOfModules(approx);
         approxmap := ShallowCopy(DirectSumProjections(approx));
         approxmap := List([1..Length(approxmap)], x -> approxmap[x]*gens[x]);         
         approxmap := Sum(approxmap);
         return RightMinimalVersion(approxmap)[1];
####         return approxmap;
      fi;
   else
      Error(" the two modules entered into MinimalRightApproximation are not modules over the same algebra.");
      return fail;
   fi;
end
);

#######################################################################
##
#O   MinimalLeftApproximation( <C>, <M> )
##
##  This function computes the minimal left add<M>-approximation of the
##  module  <C>.  TODO/CHECK: If one can modify the algorithm similarly 
##  as indicated in MinimalRightApproximation above with ####.
##
InstallMethod ( MinimalLeftApproximation, 
   "for two PathAlgebraMatModules",
   true,
   [ IsPathAlgebraMatModule, IsPathAlgebraMatModule ],
   0,
   function( C, M )

   local K, HomCM, EndM, radEndM, radHomCM, i, j, FlatHomCM, 
         FlatradHomCM, V, BB, W, f, VoverW, B, gens, approx, approxmap;

   if RightActingAlgebra(M) = RightActingAlgebra(C) then 
      K := LeftActingDomain(M);
      HomCM := HomOverAlgebra(C,M);
      if Length(HomCM) = 0 then 
         return ZeroMapping(C,ZeroModule(RightActingAlgebra(M)));
      else  
         EndM  := EndOverAlgebra(M);
         radEndM := RadicalOfAlgebra(EndM);
         radEndM := BasisVectors(Basis(radEndM));
         radEndM := List(radEndM, x -> FromEndMToHomMM(M,x));
         radHomCM := [];
         for i in [1..Length(HomCM)] do
            for j in [1..Length(radEndM)] do
               Add(radHomCM,HomCM[i]*radEndM[j]);
            od;
         od;
         FlatHomCM := List(HomCM, x -> Flat(x!.maps));
         FlatradHomCM := List(radHomCM, x -> Flat(x!.maps));
         V := VectorSpace(K,FlatHomCM,"basis");
         BB := Basis(V,FlatHomCM);
         W := Subspace(V,FlatradHomCM);
         f := NaturalHomomorphismBySubspace( V, W );
         VoverW := Range(f);
         B := BasisVectors(Basis(VoverW));
         gens := List(B, x -> PreImagesRepresentative(f,x)); 
         gens := List(gens, x -> Coefficients(BB,x));
         gens := List(gens, x -> LinearCombination(HomCM,x));
         approx := List(gens, x -> Range(x));
         approx := DirectSumOfModules(approx);
         approxmap := ShallowCopy(DirectSumInclusions(approx));
         for i in [1..Length(approxmap)] do
            approxmap[i] := gens[i]*approxmap[i];
         od;
         approxmap := Sum(approxmap);
         return LeftMinimalVersion(approxmap)[1];
      fi;
   else
      Error(" the two modules entered into MinimalLeftApproximation are not modules over the same algebra.");
      return fail;
   fi;
end
);


#######################################################################
##
#O  ProjectiveCover(<M>)
##
##  This function finds the projective cover P(M) of the module  <M>  
##  in that it returns the map from P(M) ---> M. 
##
InstallMethod ( ProjectiveCover, 
   "for a PathAlgebraMatModule",
   true,
   [ IsPathAlgebraMatModule ],
   0,
   function( M )

   local mingen, maps, PN, projections;

   if Dimension(M) = 0 then 
      return ZeroMapping(ZeroModule(RightActingAlgebra(M)), M);
   else 
      mingen := MinimalGeneratingSetOfModule(M);
      maps := List(mingen, x -> HomFromProjective(x,M));
      PN := List(maps, x -> Source(x));
      PN := DirectSumOfModules(PN);
      projections := DirectSumProjections(PN);

      return projections*maps;;
   fi;
end
);


#######################################################################
##
#O  ExtOverAlgebra(<M>,<N>)
##
##  This function returns a list of three elements: (1) the kernel of 
##  the projective cover  Omega(<M>) --> P(M), (2) a basis of 
##  Ext^1(<M>,<N>)  inside  Hom(Omega(<M>),<N>)  and (3) a function 
##  that takes as an argument a homomorphism in  Hom(Omega(<M>),<N>)
##  and returns the coefficients of this element when written in 
##  terms of the basis of  Ext^1(<M>,<N>), if the group is non-zero. 
##  Otherwise it returns an empty list. 
##
InstallMethod( ExtOverAlgebra, 
   "for two PathAlgebraMatModule's",
   true, 
   [ IsPathAlgebraMatModule, IsPathAlgebraMatModule ], 0,
   function( M, N )

   local index, fromflatHomToHom, K, f, g, PM, syzygy, G, H, Img1, zero, 
         genssyzygyN, VsyzygyN, Img, gensImg, VImg, pi, ext, preimages, 
         homvecs, dimsyz, dimN, vec, t, l, i, H2, coefficients;
#
# Defining functions for later use.
#
    index := function( n )
   	if n = 0 then 
            return 1;
        else
            return n;
        fi;
    end;

    fromflatHomToHom := function( flat, dim, dim2 )
        local totalmat, matrix, i, start, j, d, d2;

        d := List(dim, index);
        d2 := List(dim2, index);
    	start := 0;
    	totalmat := [];
    	for i in [1..Length(dim)] do
            matrix := [];
            for j in [1..d[i]] do
            	Add(matrix, flat{[start+1..start+d2[i]]});
            	start := start+d2[i];
            od;
            Add(totalmat,matrix);
    	od;
        return totalmat;
    end;
#
# Test of input.
#
   if RightActingAlgebra(M) <> RightActingAlgebra(N) then 
      Error(" the two modules entered are not modules over the same algebra.\n"); 
   else  
      K := LeftActingDomain(M);
#
# creating a short exact sequence 0 -> Syz(M) -> P(M) -> M -> 0
# f: P(M) -> M, g: Syz(M) -> P(M)  
#
      f := ProjectiveCover(M);
      g := KernelInclusion(f);
      PM := Source(f);
      syzygy := Source(g);
#
# using Hom(-,N) on the s.e.s. above
#
      G := HomOverAlgebra(PM,N);
      H := HomOverAlgebra(syzygy,N);
#
# Making a vector space of Hom(Syz(M),N)
# by first rewriting the maps as vectors
#
      genssyzygyN := List(H, x -> Flat(x!.maps));
      if Length(genssyzygyN) = 0 then
         return [[],[],[]];
      else
         VsyzygyN := VectorSpace(K, genssyzygyN);
#
# finding a basis for im(g*)
# first, find a generating set of im(g*)
# 
         Img1 := g*G;
#
# removing 0 maps by comparing to zero = Zeromap(syzygy,N)
#
         zero := ZeroMapping(syzygy,N);
         Img  := Filtered(Img1, x -> x <> zero);
#
# Rewriting the maps as vectors
#
         gensImg := List(Img, x -> Flat(x!.maps));
#
# Making a vector space of <Im g*>
         VImg := Subspace(VsyzygyN, gensImg);  
#
# Making the vector space Ext1(M,N)
#
         pi := NaturalHomomorphismBySubspace(VsyzygyN, VImg);
         ext := Range(pi);
         if Dimension(Range(pi)) = 0 then 
            return [g,[],[]];
         else 
#
# Sending elements of ext back to Hom(Syz(M),N)
#
            preimages := List(BasisVectors(Basis(ext)), x -> PreImagesRepresentative(pi,x));
#
# need to put the parentheses back in place
#
            homvecs := []; # to store all lists of matrices, one list for each element (homomorphism)
            dimsyz := DimensionVector(syzygy);
            dimN := DimensionVector(N);
            homvecs := List(preimages, x -> fromflatHomToHom(x,dimsyz,dimN));
#
# Making homomorphisms of the elements
#
            H2 := List(homvecs, x -> RightModuleHomOverAlgebra(syzygy,N,x));

            coefficients := function( map ) 
               local vector, B;
       
               vector := ImageElm(pi,Flat(map!.maps)); 
               B := Basis(Range(pi));
               
               return Coefficients(B,vector);
            end;

            return [g,H2,coefficients];
         fi;
      fi;
   fi;
end
);

#######################################################################
##
#O  ExtAlgebraGenerators(<M>,<n>)
##
##  This function computes a set of generators of the Ext-algebra Ext^*(M,M)
##  up to degree  <n>. It returns a list of three elements, where the  
##  first element is the dimensions of Ext^[0..n](M,M), the second element
##  is the number of a set generators in the degrees [0..n], and the 
##  third element is the generators in these degrees. TODO: Create a 
##  minimal set of generators. Needs to take the radical of the degree
##  zero part into account.
##
InstallMethod( ExtAlgebraGenerators, 
    "for a module over a quotient of a path algebra",
    [ IsPathAlgebraMatModule, IS_INT ], 0,
    function( M, n ) 

    local N, projcovers, f, i, EndM, J, gens, extgroups, dim_ext_groups, 
          generators, productelements, j, induced, k, liftings, products, 
          l, m, productsinbasis, W, V, K, extalggenerators, p, tempgens, 
          I, g, templist, idealsquare; 

    K := LeftActingDomain(M);
    N := M;
    projcovers := [];
    for i in [1..n] do
        f := ProjectiveCover(N);
        Add(projcovers,f);
        N := Kernel(f);
    od;
    extgroups := [];
    #
    #   Computing Ext^i(M,M) for i = 0, 1, 2,...., n. 
    #
    for i in [0..n] do 
        if i = 0 then 
            EndM := EndOverAlgebra(M); 
            J := RadicalOfAlgebra(EndM);
            gens := GeneratorsOfAlgebra(J);
            Add(extgroups, [[],List(gens, x -> FromEndMToHomMM(M,x))]);
        elif i = 1 then 
            Add(extgroups, ExtOverAlgebra(M,M)); 
        else
            Add(extgroups, ExtOverAlgebra(Kernel(projcovers[i-1]),M)); 
        fi;
    od;
    dim_ext_groups := List(extgroups, x -> Length(x[2]));
#    Print(Dimension(EndM) - Dimension(J)," generators in degree 0.\n");    
    #
    #   Computing Ext^j(M,M) x Ext^(i-j)(M,M) for j = 1..i-1 and i = 2..n.
    #
    generators := List([1..n + 1], x -> 0);
    extalggenerators := List([1..n + 1], x -> []);
    for i in [1..n] do
        productelements := [];
        for j in [0..i] do
            if ( dim_ext_groups[i+1] <> 0 ) and ( dim_ext_groups[j+1] <> 0 ) and ( dim_ext_groups[i-j+1] <> 0 ) then 
                induced := ShallowCopy(extgroups[i-j+1][2]);
                for k in [1..j] do
                    liftings := List([1..dim_ext_groups[i-j+1]], x -> projcovers[i-j+k]*induced[x]);
                    liftings := List([1..dim_ext_groups[i-j+1]], x -> LiftingMorphismFromProjective(projcovers[k],liftings[x]));
                    induced  := List([1..dim_ext_groups[i-j+1]], x -> MorphismOnKernel(projcovers[i-j+k],projcovers[k],liftings[x],induced[x]));
                od;
                products := [];
                for l in [1..dim_ext_groups[j+1]] do
                    for m in [1..dim_ext_groups[i-j+1]] do 
                        Add(products,induced[m]*extgroups[j+1][2][l]);
                    od;
                od;
                productsinbasis := List(products, x -> extgroups[i+1][3](x));
                productsinbasis := Filtered(productsinbasis, x -> x <> Zero(x));
                if Length(productsinbasis) <> 0 then
                    Append(productelements,productsinbasis);
                fi;
            fi;
        od;
        if Length(productelements) <> 0 then 
            W := FullRowSpace(K,Length(extgroups[i+1][2]));            
            V := Subspace(W,productelements);
            if dim_ext_groups[i+1] > Dimension(V) then
                generators[i+1] := Length(extgroups[i+1][2]) - Dimension(V); 
                p := NaturalHomomorphismBySubspace(W,V);
                tempgens := List(BasisVectors(Basis(Range(p))), x -> PreImagesRepresentative(p,x));
                extalggenerators[i+1] := List(tempgens, x -> LinearCombination(extgroups[i+1][2],x));                 
#                Print(Length(extgroups[i+1][2]) - Dimension(V)," new generator(s) in degree ",i,".\n");
            fi;
        elif dim_ext_groups[i+1] <> 0 then 
            generators[i+1] := Length(extgroups[i+1][2]); 
            extalggenerators[i+1] := extgroups[i+1][2];                 
#            Print(Length(extgroups[i+1][2])," new generator(s) in degree ",i,".\n");
        fi;
    od; 
    dim_ext_groups[1] := Dimension(EndM);
    templist := [];
    for i in [1..Length(gens)] do
        for j in [1..Dimension(EndM)] do
            Add(templist,BasisVectors(Basis(EndM))[j]*gens[i]);
        od;
    od;
    templist := Filtered(templist, x -> x <> Zero(x));
    idealsquare := [];
    for i in [1..Length(templist)] do
        for j in [1..Length(gens)] do
            Add(idealsquare,gens[j]*templist[i]);
        od;
    od;
    I := Ideal(EndM,idealsquare);
    g := NaturalHomomorphismByIdeal(EndM,I);
    extalggenerators[1] := List(BasisVectors(Basis(Range(g))), x -> FromEndMToHomMM(M,PreImagesRepresentative(g,x)));
    generators[1] := Length(extalggenerators[1]);
    return [dim_ext_groups,generators,extalggenerators];
end
);

#######################################################################
##
#O  PartialIyamaGenerator( <M> )
##
##  Given a module  <M>  this function returns the submodule of  <M>
##  given by the radical of the endomorphism ring of  <M>  times <M>.
##  If  <M>  is zero, then  <M>  is returned.
##
InstallMethod( PartialIyamaGenerator,
    "for a path algebra",
    [ IsPathAlgebraMatModule ], 0,
    function( M ) 

    local B, EndM, radEndM, Brad, subgens, b, r; 

    if Dimension(M) = 0 then 
        return M;
    fi;
    B := CanonicalBasis(M); 
    EndM := EndOverAlgebra(M);
    radEndM := RadicalOfAlgebra(EndM);  
    Brad := BasisVectors(Basis(radEndM));
    Brad := List(Brad, x -> FromEndMToHomMM(M,x));
    subgens := [];
    for b in B do
        for r in Brad do
            Add(subgens, ImageElm(r,b));
        od;
    od;

    return SubRepresentation(M,subgens);
end
);

#######################################################################
##
#O  IyamaGenerator( <M> )
##
##  Given a module  <M> this function returns a module  N  such that
##  <M>  is a direct summand of  N  and such that the global dimension
##  of the endomorphism ring of  N  is finite. 
##
InstallMethod( IyamaGenerator,
    "for a path algebra",
    [ IsPathAlgebraMatModule ], 0,
    function( M ) 

    local iyamagen, N, IG, L; 

    iyamagen := [];
    N := M;
    repeat 
        Add(iyamagen,N);
        N := PartialIyamaGenerator(N);
    until
        Dimension(N) = 0;

    IG := DirectSumOfModules(iyamagen);
    if IsFinite(LeftActingDomain(M)) then 
        L := DecomposeModuleWithMultiplicities(IG);
        IG := DirectSumOfModules(L[1]);
    fi;

    return IG;
end
);

#######################################################################
##
#O  GlobalDimensionOfAlgebra( <A>, <n> )
##
##  Returns the global dimension of the algebra  <A>  if it is less or
##  equal to  <n>, otherwise it returns false.
##  
InstallMethod ( GlobalDimensionOfAlgebra, 
    "for a finite dimensional quotient of a path algebra",
    true,
    [ IsQuiverAlgebra, IS_INT ], 
    0,
    function( A, n )

    local simples, S, projres, dimension, j;
    
    if not IsFiniteDimensional(A) then
        TryNextMethod();
    fi;
    if HasGlobalDimension(A) then
        return GlobalDimension(A);
    fi;
    if Trace(AdjacencyMatrixOfQuiver(QuiverOfPathAlgebra(A))) > 0 then
        SetGlobalDimension(A,infinity);
        return infinity;
    fi;
    simples := SimpleModules(A);
    dimension := 0;
    for S in simples do
        projres := ProjectiveResolution(S);
        j := 0;
        while ( j < n + 1 ) and ( Dimension(ObjectOfComplex(projres,j)) <> 0 ) do 
            j := j + 1;
        od; 
        if ( j < n + 1 ) then 
            dimension := Maximum(dimension, j - 1 );
        else
            if ( Dimension(ObjectOfComplex(projres,n + 1)) <> 0 ) then
                return false;
            else
                dimension := Maximum(dimension, n );
            fi;
        fi;
    od;
    
    SetGlobalDimension(A,dimension);
    return dimension;
end 
);

#######################################################################
##
#O  DominantDimensionOfModule( <M>, <n> )
##
##  Returns the dominant dimension of the module  <M>  if it is less or
##  equal to  <n>. If the module  <M>  is injectiv and projective, then 
##  it returns infinity. Otherwise it returns false.
##  
InstallMethod ( DominantDimensionOfModule, 
    "for a finite dimensional quotient of a path algebra",
    true,
    [ IsPathAlgebraMatModule, IS_INT ], 
    0,
    function( M, n )

    local A, Mop, resop, dimension, j;
    
    A := RightActingAlgebra(M);
    #
    # If the algebra  A  is not a finite dimensional, try another method.
    #
    if not IsFiniteDimensional(A) then
        TryNextMethod();
    fi;
    # 
    # If the module  <M>  is injective and projective, then the dominant dimension of 
    # <M>  is infinite.
    if IsInjectiveModule(M) and IsProjectiveModule(M) then 
        return infinity;
    fi;
    Mop := DualOfModule(M);
    #
    # Compute the minimal projective resolution of the module  Mop.
    #
    resop := ProjectiveResolution(Mop);
    dimension := 0;
    # Check how far out the modules in the minimal projective resolution of Mop
    # is injective.
    if IsInjectiveModule(ObjectOfComplex(resop,0)) then
        if Dimension(ObjectOfComplex(resop,1)) = 0 then
            return infinity;
        else
            j := 1;
            while ( j < n + 1 ) and ( IsInjectiveModule(ObjectOfComplex(resop,j)) ) do 
                    j := j + 1;
            od; 
            if ( j < n + 1 ) then # if this happens, then j-th projective is not injective and domdim equal to j for <M>.
                dimension := Maximum(dimension, j);
            else                    # if this happens, then j = n + 1. 
                if not IsInjectiveModule(ObjectOfComplex(resop,n + 1)) then # then domdim is  n  of  <M>.
                    dimension := Maximum(dimension, n);
                else                                                      # then domdim is > n  for  <M>.
                    return false;
                fi;
            fi;
        fi;
    fi;

#    SetDominantDimension(M,dimension);
    return dimension;
end 
);


#######################################################################
##
#O  DominantDimensionOfAlgebra( <A>, <n> )
##
##  Returns the dominant dimension of the algebra  <A>  if it is less or
##  equal to  <n>. If the algebra  <A>  is selfinjectiv, then it returns
##  infinity. Otherwise it returns false.
##  
InstallMethod ( DominantDimensionOfAlgebra, 
    "for a finite dimensional quotient of a path algebra",
    true,
    [ IsQuiverAlgebra, IS_INT ], 
    0,
    function( A, n )

    local P, domdimlist, M, test, pos, finite_ones;
    
    #
    # If the algebra  <A>  is not a finite dimensional, try another method.
    #
    if not IsFiniteDimensional(A) then
        TryNextMethod();
    fi;
    # 
    # If the algebra  <A>  is selfinjective, then the dominant dimension of 
    # <A>  is infinite.
    if IsSelfinjectiveAlgebra(A) then 
        return infinity;
    fi;
    P := IndecProjectiveModules(A);
    domdimlist := [];
    for M in P do
        test := DominantDimensionOfModule(M,n);   # Checking the dominant dimension of each indec. projective module. 
        if test = false then
            return false;
        fi;
        Add(domdimlist,test); 
    od; 
    pos := Positions(domdimlist,infinity); # positions of the indec. projective modules with infinite domdim.
    finite_ones := [1..Length(P)]; 
    SubtractSet(finite_ones,pos); # positions of the indec. projective modules with finite domdim.
    
    return Maximum(domdimlist{finite_ones});
end
  );

#######################################################################
##
#O  ProjDimensionOfModule( <M>, <n> )
##
##  Returns the projective dimension of the module  <M>  if it is less
##  or equal to  <n>, otherwise it returns false.
##  
InstallMethod ( ProjDimensionOfModule, 
    "for a PathAlgebraMatModule",
    true,
    [ IsPathAlgebraMatModule, IS_INT ], 
    0,
    function( M, n )

    local projres, i;
    
    if HasProjDimension(M) then
        return ProjDimension(M);
    fi;
    projres := ProjectiveResolution(M);
    i := 1;
    while i < n + 2 do
        if Dimension(ObjectOfComplex(projres,i)) = 0 then # the projective dimension is  i - 1.
            SetProjDimension(M, i - 1);
            return i-1;
        fi;
        i := i + 1;
    od; 
    
    return false;
end 
  );

#######################################################################
##
#O  GorensteinAlgebraDimension( <A>, <n> )
##
##  Returns the Gorenstein dimension of the algebra  <A>  if it is less
##  or equal to  <n>, otherwise it returns false.
##  
InstallMethod ( GorensteinAlgebraDimension,
    "for a quiver algebra",
    true,
    [ IsQuiverAlgebra, IS_INT ], 
    0,
    function( A, n )

    local Ilist, dimension_right, I, projdim, Ilistop, dimension_left;
    
    #
    #  If  <A>  has finite global dimension, then the Gorenstein 
    #  dimension of  <A>  is equal to the global dimension of  <A>. 
    #
    if HasGlobalDimension(A) then
        if GlobalDimension(A) <> infinity then 
            SetGorensteinDimension(A, GlobalDimension(A));
            return GlobalDimension(A);
        fi;
    fi;
    if HasGorensteinDimension(A) then
        return GorensteinDimension(A);
    fi;
    #
    #  First checking the injective dimension of the indecomposable
    #  projective left  <A>-modules.
    #
    Ilist := IndecInjectiveModules(A);
    dimension_right := 0;
    for I in Ilist do
        projdim := ProjDimensionOfModule(I,n); 
        if projdim = false then   # projective dimension of  I  is bigger than  n.
            return false;
        else                      # projective dimension of  I  is less or equal to  n.
            dimension_right := Maximum(dimension_right, projdim );
        fi;
    od;
    #
    #  Secondly checking the injective dimension of the indecomposable
    #  projective right  <A>-modules.
    #  
    Ilistop := IndecInjectiveModules(OppositeAlgebra(A));    
    dimension_left := 0;
    for I in Ilistop do
        projdim := ProjDimensionOfModule(I,n); 
        if projdim = false then   # projective dimension of  I  is bigger than  n.
            return false;
        else                      # projective dimension of  I  is less or equal to  n.
            dimension_left := Maximum(dimension_left, projdim );
        fi;
    od;    
    if dimension_left <> dimension_right then
        Print("You have a counterexample to the Gorenstein conjecture!\n\n");
    fi;
    
    SetGorensteinDimension(A, Maximum(dimension_left, dimension_right));
    return Maximum(dimension_left, dimension_right);    
end 
  );

#######################################################################
##
#O  N_RigidModule( <M>, <n> )
##
##  Returns true if the module  <M>  is n-rigid, otherwise false.
##  
InstallMethod ( N_RigidModule, 
    "for a PathAlgebraMatModule",
    true,
    [ IsPathAlgebraMatModule, IS_INT ], 
    0,
    function( M, n )

    local i, N;
    
    i := 1;
    N := M;
    while i < n + 1 do
        if Length(ExtOverAlgebra(N,M)[2]) > 0 then # Ext^i(M,M) <> 0.
            return false;
        else                                       # Ext^i(M,M) = 0.
            i := i + 1;                            
            N := NthSyzygy(N,1);
        fi;
    od;
    
    return true;
end 
  );

#######################################################################
##
#O  LeftFacMApproximation( <C>, <M> )
##
##  This function computes a left, not necessarily left minimal, 
##  Fac<M>-approximation of the module  <C>  by doing the following:
##                  p
##           P(C) -------> C  (projective cover)
##             |           |
##           f |           | g - the returned homomorphism
##             V           V
##          M^{P(C)} ----> E
##
InstallMethod( LeftFacMApproximation,
    "for a representations of a quiver",
    [ IsPathAlgebraMatModule, IsPathAlgebraMatModule ], 0,
    function( C, M )

    local p, f; 
    #
    # Checking if the modules  <C>  and  <M>  are modules over the same algebra.
    #
    if RightActingAlgebra(C) <> RightActingAlgebra(M) then
        Error("the entered modules are not modules over the same algebra,\n");
    fi;    
    p := ProjectiveCover(C);
    f := MinimalLeftAddMApproximation(Source(p),M);
    
    return PushOut(p,f)[2];
end
  );


#######################################################################
##
#O  MinimalLeftFacMApproximation( <C>, <M> )
##
##  This function computes a minimal left Fac<M>-approximation of the 
##  module  <C>. 
##
InstallMethod( MinimalLeftFacMApproximation,
    "for a representations of a quiver",
    [ IsPathAlgebraMatModule, IsPathAlgebraMatModule ], 0,
    function( C, M );

    return LeftMinimalVersion(LeftFacMApproximation(C,M));
end
  );


#######################################################################
##
#O  RightSubMApproximation( <M>, <C> )
##
##  This function computes a right, not necessarily a right minimal,
##  Sub<M>-approximation of the module  <C>  by doing the following:
##
##             E -----> M^{I(C)}  (minimal right Add<M>-approximation)
##             |           |
##           g |           | f     g - the returned homomorphism
##             V    i      V
##             C -------> I(C)  (injective envelope)
##
InstallMethod( RightSubMApproximation,
    "for a representations of a quiver",
    [ IsPathAlgebraMatModule, IsPathAlgebraMatModule ], 0,
    function( M, C )

    local iop, i, f; 
    #
    # Checking if the modules  <M>  and  <C>  are modules over the same algebra.
    #
    if RightActingAlgebra(M) <> RightActingAlgebra(C) then
        Error("the entered modules are not modules over the same algebra,\n");
    fi;      
    iop := ProjectiveCover(DualOfModule(C));
    i := DualOfModuleHomomorphism(iop);
    f := MinimalRightAddMApproximation(M, Range(i));
    
    return PullBack(i,f)[2];
end
  );


#######################################################################
##
#O  MinimalRightSubMApproximation( <M>, <C> )
##
##  This function computes a minimal right Sub<M>-approximation of the module 
##  <C>. 
##
InstallMethod( MinimalRightSubMApproximation,
    "for a representations of a quiver",
    [ IsPathAlgebraMatModule, IsPathAlgebraMatModule ], 0,
    function( M, C );

    return RightMinimalVersion(RightSubMApproximation(M,C));
end
  );


#######################################################################
##
#O  LeftSubMApproximation( <C>, <M> )
##
##  This function computes a minimal left Sub<M>-approximation of the 
##  module  <C>  by doing the following: 
##            f
##       C -------> M^{C} = the minimal left Add<M>-approxiamtion
##
##   Returns the natural projection  C --------> Im(f). 
##
InstallMethod( LeftSubMApproximation,
    "for a representations of a quiver",
    [ IsPathAlgebraMatModule, IsPathAlgebraMatModule ], 0,
    function( C, M )

    local f; 
    #
    # Checking if the modules  <C>  and  <M>  are modules over the same algebra.
    #
    if RightActingAlgebra(C) <> RightActingAlgebra(M) then
        Error("the entered modules are not modules over the same algebra,\n");
    fi;      
    f := MinimalLeftAddMApproximation(C,M);
    
    return ImageProjection(f);
end
  );