#!/bin/bash
#set up a new refinement
#Stephanie Wankowicz 4/5/2019
#git: 07-12-2019

#source Phenix
source /wynton/group/fraser/swankowicz/phenix-1.17rc5-3630/phenix_env.sh
#source /wynton/home/fraserlab/swankowicz/phenix-installer-dev-3594-intel-linux-2.6-x86_64-centos6/phenix-dev-3594/phenix_env.sh
export PHENIX_OVERWRITE_ALL=true

PDB=$1

NSLOTS=$2  
echo $PDB
echo $PWD  
  
#get ligand name and list of ligands for harmonic restraints
~/anaconda3/envs/phenix_ens/bin/python /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/PDB_ligand_parser.py $PDB /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/ligands_to_remove.csv
lig_name=$(cat "ligand_name.txt")
echo $lig_name

echo '________________________________________________________Starting Phenix cif as mtz________________________________________________________'
phenix.cif_as_mtz $PDB-sf.cif --extend_flags --merge

echo '________________________________________________________Starting Phenix Ready Set________________________________________________________'
phenix.ready_set pdb_file_name=${PDB}.pdb #cif_file_name=elbow.${lig_name}.${PDB}_pdb.001.cif >> readyset_output.txt

echo '________________________________________________________Prepping Amber________________________________________________________'
phenix.AmberPrep ${PDB}.updated.pdb 


  echo '________________________________________________________Checking on FOBS________________________________________________________'
  if grep -F _refln.F_meas_au $PDB-sf.cif; then
	echo 'FOBS'
  else
        echo 'IOBS'
  fi
  rm ${PDB}.updated_refine_*
  if [[ -e "${PDB}.ligands.cif" ]]; then
    echo '________________________________________________________Running refinement with ligand.________________________________________________________'
    if grep -F _refln.F_meas_au $PDB-sf.cif; then
        phenix.refine 4phenix_${PDB}.updated.pdb $PDB-sf.mtz ${PDB}.ligands.cif refinement.input.xray_data.r_free_flags.label=R-free-flags /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/finalize.params nproc=$NSLOTS refinement.input.xray_data.labels="FOBS,SIGFOBS" use_amber=True amber.topology_file_name=4amber_${PDB}.prmtop amber.coordinate_file_name=4amber_${PDB}.rst7 amber.order_file_name=4amber_${PDB}.order print_amber_energies=True
    else
      	echo 'IOBS'   
	 phenix.refine 4phenix_${PDB}.updated.pdb $PDB-sf.mtz ${PDB}.ligands.cif refinement.input.xray_data.r_free_flags.label=R-free-flags /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/finalize.params nproc=$NSLOTS refinement.input.xray_data.labels="IOBS,SIGIOBS" use_amber=True amber.topology_file_name=4amber_${PDB}.prmtop amber.coordinate_file_name=4amber_${PDB}.rst7 amber.order_file_name=4amber_${PDB}.order print_amber_energies=True
    fi
  else
    echo '________________________________________________________Running refinement without ligand.________________________________________________________'
    if grep -F _refln.F_meas_au $PDB-sf.cif; then
	phenix.refine 4phenix_${PDB}.updated.pdb $PDB-sf.mtz /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/finalize.params nproc=$NSLOTS refinement.input.xray_data.labels="FOBS,SIGFOBS" refinement.input.xray_data.r_free_flags.label=R-free-flags use_amber=True amber.topology_file_name=4amber_${PDB}.prmtop amber.coordinate_file_name=4amber_${PDB}.rst7 amber.order_file_name=4amber_${PDB}.order print_amber_energies=True
    else
	phenix.refine 4phenix_${PDB}.updated.pdb $PDB-sf.mtz /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/finalize.params nproc=$NSLOTS refinement.input.xray_data.r_free_flags.label=R-free-flags refinement.input.xray_data.labels="IOBS,SIGIOBS" use_amber=True amber.topology_file_name=4amber_${PDB}.prmtop amber.coordinate_file_name=4amber_${PDB}.rst7 amber.order_file_name=4amber_${PDB}.order print_amber_energies=True
   fi
 fi


  echo '________________________________________________________Starting Model versus Data________________________________________________________'
  #phenix.model_vs_data ${PDB}.updated_refine_001.pdb $PDB-sf.cif > ${PDB}_model_v_data.txt

  echo '________________________________________________________Starting extract python script________________________________________________________'
  #~/anaconda3/envs/phenix_ens/bin/python /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/Parse_refine_log.py -log_file ${PDB}.updated_refine_001.log -PDB $PDB
  #rm lig_RMSZ_updated.txt
  #rm lig_RMSZ_pre_refine.txt
  echo '________________________________________________________Validating the Ligand from Original PDB________________________________________________________'
  #if [[ -e "${PDB}.ligands.cif" ]]; then  #only running this if we have a ligand    
  #  echo $lig_name
    #mmtbx.validate_ligands ${PDB}.pdb ${PDB}-sf.mtz ligand_code=$lig_name #"${PDB}_ligand" #prints out ADPs and occs + additional information
   # echo '________________________________________________________Phenix PDB Interpretation_______________________________________________________'
    #phenix.pdb_interpretation ${PDB}.updated.pdb ${PDB}.ligands.cif write_geo=True
    #echo '________________________________________________________Elbow Refine_Geo_Display_______________________________________________________'
    #elbow.refine_geo_display ${PDB}.updated.pdb.geo $lig_name >> lig_RMSZ_pre_refine.txt #prints out deviations including ligand specific RMSD and RMSz values
  #fi


  #echo '________________________________________________________Validating the Ligand after Initial Refinement________________________________________________________'
  #if [[ -e "${PDB}.ligands.cif" ]]; then  #only running this if we have a ligand
   # echo '________________________________________________________Extracting the Ligand Name_______________________________________________________'
    #mmtbx.validate_ligands ${PDB}.updated_refine_001.pdb ${PDB}-sf.mtz ligand_code=$lig_name #"${PDB}_ligand" #prints out ADPs and occs + additional information
    #echo '________________________________________________________Phenix PDB Interpretation_______________________________________________________'
    #phenix.pdb_interpretation ${PDB}.updated_refine_001.pdb elbow.${lig_name}.${PDB}_pdb.001.cif write_geo=True # only need this if we are taking the PDB directly
    #phenix.pdb_interpretation ${PDB}.updated_refine_001.pdb ${PDB}.ligands.cif write_geo=True
    #echo '________________________________________________________Elbow Refine_Geo_Display_______________________________________________________'
    #elbow.refine_geo_display ${PDB}.updated_refine_001.pdb.geo $lig_name >> lig_RMSZ_updated.txt 
    #prints out deviations including ligand specific RMSD and RMSz values
    #calculate the energy difference of the ligand in the model and it relaxed RM1/AM1, but can be linked to 3rd party packages
  #fi

  #echo '________________________________________________________Validating Ligand Output_______________________________________________________'
  #~/anaconda3/envs/phenix_ens/bin/python /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/lig_geo_parser.py -pre_refine=lig_RMSZ_pre_refine.txt -post_refine=lig_RMSZ_updated.txt -PDB=$PDB


  #echo '________________________________________________________Begin Ensemble Refinement_______________________________________________________'
  #phenix.ensemble_refinement 4phenix_${PDB}.updated_refine_001.pdb ${PDB}-sf.mtz ${PDB}.ligands.cif ptls=0.6 output_file_prefix="$PDB" use_amber=True topology_file_name=4amber_${PDB}.prmtop coordinate_file_name=4amber_${PDB}.rst7
  #qsub /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/grid_search_ens_refine.sh $PDB $3
  #cont_var=$(cat "threshold.txt")
  #echo $cont_var

  #if [[$cont_var=="Passed"]]; then
   # echo "It Passed!"
    #qsub /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/grid_search_ens_refine.sh $PDB $3
    #phenix.ensemble_refinement ${PDB}.updated_refine_001.pdb ${PDB}-sf.mtz elbow.${PDB}_pdb.001.cif /Users/fraserlab/Documents/Stephanie/finalize.params
  #else
   # echo "Skipping Ensemble Refinement"
   # echo "testing"
    #qsub /wynton/home/fraserlab/swankowicz/190419_Phenix_ensemble/grid_search_ens_refine.sh $PDB $3
  #fi
  #for structures with ligands, should use harmonic restraints harmonic_restraints.selections=’resname PO2 and element P’
#done < $pdb_filelist
