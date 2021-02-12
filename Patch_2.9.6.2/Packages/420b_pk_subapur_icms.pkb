create or replace package body csf_own.pk_subapur_icms is

-------------------------------------------------------------------------------------------------------
--| Corpo do pacote de procedimentos de Geração da Apuração de ICMS    
-------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
-- Função retorna os Valores recolhidos ou a recolher, extraapuração no c197                   --
-- Utilizada para compôr: Campo 13-DEB_ESP_OA: Valores recolhidos ou a recolher, extraapuração --
-------------------------------------------------------------------------------------------------
function fkg_soma_dep_esp_e111
         return ajust_subapur_icms.vl_aj_apur%type
is
   --
   vn_vl_aj_apur ajust_subapur_icms.vl_aj_apur%type := 0;
   --
begin
   --
   select nvl(sum(asi.vl_aj_apur),0)
     into vn_vl_aj_apur
     from ajust_subapur_icms     asi
        , cod_aj_saldo_apur_icms cod
    where asi.subapuricms_id = gt_row_subapur_icms.id
      and cod.id             = asi.codajsaldoapuricms_id
      and cod.dm_apur       in (0) -- icms
      and cod.dm_util       in (5); -- utilização: 5-débito especial
   --
   return vn_vl_aj_apur;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_dep_esp_e111: '||sqlerrm);
end fkg_soma_dep_esp_e111;
-------------------------------------------------------------------------------------------------
-- Função retorna os Valores recolhidos ou a recolher, extraapuração no c197 e d197            --
-- Utilizada para compôr: Campo 13-DEB_ESP_OA: Valores recolhidos ou a recolher, extraapuração --
-------------------------------------------------------------------------------------------------
function fkg_soma_dep_esp_c197_d197
         return inf_prov_docto_fiscal.vl_icms%type
is
   --
   vn_vl_icms   inf_prov_docto_fiscal.vl_icms%type := 0;
   vn_vl_icms1  inf_prov_docto_fiscal.vl_icms%type := 0;
   vn_vl_icms2  inf_prov_docto_fiscal.vl_icms%type := 0;
   --
begin
   --
   select sum(nvl(ipdf.vl_icms,0)) vl_icms
     into vn_vl_icms1
     from nota_fiscal           nf
        , sit_docto             sd
        , mod_fiscal            mf
        , nfinfor_fiscal        nfi
        , inf_prov_docto_fiscal ipdf
        , cod_ocor_aj_icms      cod
    where nf.empresa_id       = gt_row_subapur_icms.empresa_id
      and nf.dm_st_proc       = 4
      and nf.dm_arm_nfe_terc  = 0 -- Não é nota de armazenamento fiscal
      and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 1 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
      and sd.id               = nf.sitdocto_id
      and sd.cd          not in ('01', '07') -- extemporâneos
      and mf.id               = nf.modfiscal_id
      and mf.cod_mod         in ('01', '1B', '04', '55', '65', '06', '29', '28', '21', '22')
      and nfi.notafiscal_id   = nf.id
      and ipdf.nfinforfisc_id = nfi.id
      and cod.id              = ipdf.codocorajicms_id
      and cod.dm_reflexo_apur = '7' -- corresponde ao 3º dígito do código: substr(cod.cod_aj,3,1) = 7-Débitos especiais
      and cod.dm_tipo_apur   in ('3', '4', '5'); -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) in 3-Apuração 1, 4-Apuração 2, 5–Apuração 3
   --
   select sum(nvl(ci.vl_icms,0)) vl_icms
     into vn_vl_icms2
     from conhec_transp    ct
        , sit_docto        sd
        , ct_reg_anal      cr
        , ctinfor_fiscal   cf
        , ct_inf_prov      ci
        , cod_ocor_aj_icms co
    where ct.empresa_id       = gt_row_subapur_icms.empresa_id
      and ct.dm_st_proc       = 4 -- Autorizado
      and ct.dm_arm_cte_terc  = 0
      and ((ct.dm_ind_emit = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 1 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
      and sd.id               = ct.sitdocto_id
      and sd.cd          not in ('01', '07') -- extemporâneos
      and cr.conhectransp_id  = ct.id
      and cf.conhectransp_id  = ct.id
      and ci.ctinforfiscal_id = cf.id
      and co.id               = ci.codocorajicms_id
      and co.dm_reflexo_apur  = '7' -- corresponde ao 3º dígito do código: substr(cod.cod_aj,3,1) = 7-Débitos especiais
      and co.dm_tipo_apur    in ('3', '4', '5'); -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) in 3-Apuração 1, 4-Apuração 2, 5–Apuração 3
   --
   vn_vl_icms := nvl(vn_vl_icms1,0) + nvl(vn_vl_icms2,0);
   --
   return vn_vl_icms;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_dep_esp_c197_d197: '||sqlerrm);
end fkg_soma_dep_esp_c197_d197;
-------------------------------------------------------------------------------------------------------
-- Função retorna os Valores recolhidos ou a recolher, extraapuração nos conhecimentos de transporte --
-- onde as operações de saída não estão no cfop 5605 e as de entrada estão no cfop 1605              --
-- Utilizada para compôr: Campo 13-DEB_ESP_OA: Valores recolhidos ou a recolher, extraapuração       --
-------------------------------------------------------------------------------------------------------
function fkg_soma_cred_ext_op_d
         return ct_reg_anal.vl_icms%type
is
   --
   vn_vl_icms ct_reg_anal.vl_icms%type := 0;
   vn_vl_icms1 ct_reg_anal.vl_icms%type := 0;
   vn_vl_icms2 ct_reg_anal.vl_icms%type := 0;
   --
begin
   --
   select sum(nvl(r.vl_icms,0))
     into vn_vl_icms1
     from conhec_transp    ct
        , sit_docto        sd
        , ct_reg_anal      r
        , cfop             c
    where ct.empresa_id      = gt_row_subapur_icms.empresa_id
      and ct.dm_st_proc      = 4 -- Autorizado
      and ct.dm_arm_cte_terc = 0
      and ct.dm_ind_oper     = 1 -- saída
      and ((ct.dm_ind_emit = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (ct.dm_ind_emit = 0 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
      and sd.id              = ct.sitdocto_id
      and sd.cd             in ('01', '07') -- extemporâneo
      and r.conhectransp_id  = ct.id
      and c.id               = r.cfop_id
      and c.cd          not in (5605);
   --
   select sum(nvl(r.vl_icms,0)) vl_icms
     into vn_vl_icms2
     from conhec_transp    ct
        , sit_docto        sd
        , ct_reg_anal      r
        , cfop             c
    where ct.empresa_id      = gt_row_subapur_icms.empresa_id
      and ct.dm_st_proc      = 4 -- Autorizado
      and ct.dm_arm_cte_terc = 0
      and ct.dm_ind_oper     = 0 -- Entrada
      and ((ct.dm_ind_emit = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
      and sd.id              = ct.sitdocto_id
      and sd.cd             in ('01', '07') -- extemporâneo
      and r.conhectransp_id  = ct.id
      and c.id               = r.cfop_id
      and c.cd              in (1605);
   --
   vn_vl_icms := nvl(vn_vl_icms1,0) + nvl(vn_vl_icms2,0);
   --
   return vn_vl_icms;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_cred_ext_op_d: '||sqlerrm);
end fkg_soma_cred_ext_op_d;
-------------------------------------------------------------------------------------------------
-- Função retorna os Valores recolhidos ou a recolher, extraapuração                           --
-- Onde as nfe de saida não estejam entre o cfop 5605 e as nf de entrada estejam no cfop 1605  --
-- Utilizada para compôr: Campo 13-DEB_ESP_OA: Valores recolhidos ou a recolher, extraapuração --
-------------------------------------------------------------------------------------------------
function fkg_soma_cred_ext_op_c
         return nfregist_analit.vl_icms%type
is
   --
   vn_vl_icms   nfregist_analit.vl_icms%type := 0;
   vn_vl_icms1  nfregist_analit.vl_icms%type := 0;
   vn_vl_icms2  nfregist_analit.vl_icms%type := 0;
   --
begin
   --
   select sum(nvl(r.vl_icms,0))
     into vn_vl_icms1
     from nota_fiscal      nf
        , sit_docto        sd
        , mod_fiscal       mf
        , nfregist_analit  r
        , cfop             c
    where nf.empresa_id      = gt_row_subapur_icms.empresa_id
      and nf.dm_st_proc      = 4
      and nf.dm_arm_nfe_terc = 0 -- Não é nota de armazenamento fiscal
      and nf.dm_ind_oper     = 1 -- Saída
      and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
      and sd.id              = nf.sitdocto_id
      and sd.cd             in ('01', '07') -- extemporâneo
      and mf.id              = nf.modfiscal_id
      and mf.cod_mod        in ('01', '1B', '04', '55', '65', '06', '29', '28', '21', '22')
      and r.notafiscal_id    = nf.id
      and c.id               = r.cfop_id
      and c.cd          not in (5605);
   --
   select sum( nvl(r.vl_icms,0) ) vl_icms
     into vn_vl_icms2
     from nota_fiscal      nf
        , sit_docto        sd
        , mod_fiscal       mf
        , nfregist_analit  r
        , cfop             c
    where nf.empresa_id      = gt_row_subapur_icms.empresa_id
      and nf.dm_st_proc      = 4
      and nf.dm_arm_nfe_terc = 0 -- Não é nota de armazenamento fiscal
      and nf.dm_ind_oper     = 0 -- Entrada
      and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
      and sd.id              = nf.sitdocto_id
      and sd.cd             in ('01', '07') -- extemporâneo
      and mf.id              = nf.modfiscal_id
      and mf.cod_mod        in ('01', '1B', '04', '55', '65', '06', '29', '28', '21', '22')
      and r.notafiscal_id    = nf.id
      and c.id               = r.cfop_id
      and c.cd              in (1605);
   --
   vn_vl_icms := nvl(vn_vl_icms1,0) + nvl(vn_vl_icms2,0);
   --
   return vn_vl_icms;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_cred_ext_op_c: '||sqlerrm);
end fkg_soma_cred_ext_op_c;
---------------------------------------------------------------------------
-- Função retorna o Valor total de "Deduções"                            --
-- Utilizada para compôr: Campo 10-VL_TOT_DED: Valor total de "Deduções" --
---------------------------------------------------------------------------
function fkg_soma_tot_ded_e111
         return ajust_subapur_icms.vl_aj_apur%type
is
   --
   vn_vl_aj_apur ajust_subapur_icms.vl_aj_apur%type := 0;
   --
begin
   --
   select nvl(sum(asi.vl_aj_apur),0) vl_aj_apur
     into vn_vl_aj_apur
     from ajust_subapur_icms     asi
        , cod_aj_saldo_apur_icms cod
    where asi.subapuricms_id = gt_row_subapur_icms.id
      and cod.id             = asi.codajsaldoapuricms_id
      and cod.dm_apur       in (0) -- icms
      and cod.dm_util       in (4); -- utilização: 4-Deduções
   --
   return vn_vl_aj_apur;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_tot_ded_e111: '||sqlerrm);
end fkg_soma_tot_ded_e111;
---------------------------------------------------------------------------
-- Função retorna o Valor total de "Deduções"                            --
-- Utilizada para compôr: Campo 10-VL_TOT_DED: Valor total de "Deduções" --
---------------------------------------------------------------------------
function fkg_soma_tot_ded_c197_d197
         return inf_prov_docto_fiscal.vl_icms%type
is
   --
   vn_vl_icms   inf_prov_docto_fiscal.vl_icms%type := 0;
   vn_vl_icms1  inf_prov_docto_fiscal.vl_icms%type := 0;
   vn_vl_icms2  inf_prov_docto_fiscal.vl_icms%type := 0;
   --
begin
   --
           select sum(nvl(ipdf.vl_icms,0)) vl_icms
             into vn_vl_icms1
             from nota_fiscal           nf
                , sit_docto             sd
                , mod_fiscal            mf
                , nfinfor_fiscal        nfi
                , inf_prov_docto_fiscal ipdf
                , cod_ocor_aj_icms      cod
            where nf.empresa_id       = gt_row_subapur_icms.empresa_id
              and nf.dm_st_proc       = 4 -- 4-autorizada
              and nf.dm_arm_nfe_terc  = 0 -- Não é nota de armazenamento fiscal
              and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 1 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
              and sd.id               = nf.sitdocto_id
              and sd.cd          not in ('01', '07') -- extemporâneos
              and mf.id               = nf.modfiscal_id
              and mf.cod_mod         in ('01', '1B', '04', '55', '65', '06', '29', '28', '21', '22')
              and nfi.notafiscal_id   = nf.id
              and ipdf.nfinforfisc_id = nfi.id
              and cod.id              = ipdf.codocorajicms_id
              and cod.dm_reflexo_apur = '6' -- corresponde ao 3º dígito do código: substr(cod.cod_aj,3,1) = 6-Dedução
              and cod.dm_tipo_apur   in ('3', '4', '5'); -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) in 3-Apuração 1, 4-Apuração 2, 5–Apuração 3

           select sum(nvl(ci.vl_icms,0)) vl_icms
             into vn_vl_icms2
             from conhec_transp    ct
                , sit_docto        sd
                , ct_reg_anal      cr
                , ctinfor_fiscal   cf
                , ct_inf_prov      ci
                , cod_ocor_aj_icms co
            where ct.empresa_id       = gt_row_subapur_icms.empresa_id
              and ct.dm_st_proc       = 4 -- Autorizado
              and ct.dm_arm_cte_terc  = 0
              and ((ct.dm_ind_emit = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 1 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
              and sd.id               = ct.sitdocto_id
              and sd.cd          not in ('01', '07') -- extemporâneos
              and cr.conhectransp_id  = ct.id
              and cf.conhectransp_id  = ct.id
              and ci.ctinforfiscal_id = cf.id
              and co.id               = ci.codocorajicms_id
              and co.dm_reflexo_apur  = '6' -- corresponde ao 3º dígito do código: substr(cod.cod_aj,3,1) = 6-Dedução
              and co.dm_tipo_apur    in ('3', '4', '5'); -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) in 3-Apuração 1, 4-Apuração 2, 5–Apuração 3
   --
   vn_vl_icms := nvl(vn_vl_icms1,0) + nvl(vn_vl_icms2,0);
   --
   return vn_vl_icms;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_tot_ded_c197_d197: '||sqlerrm);
end fkg_soma_tot_ded_c197_d197;
-------------------------------------------------------------------------------------------------------------
-- Função retorna o Valor total de "Saldo credor do período anterior"                                      --
-- Utilizada para compôr: Campo 08-VL_SLD_CREDOR_ANT_OA: Valor total de "Saldo credor do período anterior" --
-------------------------------------------------------------------------------------------------------------
function fkg_saldo_credor_ant
         return subapur_icms.vl_sld_credor_ant_oa%type
is
   --
   vn_vl_sld_credor_ant_oa subapur_icms.vl_sld_credor_ant_oa%type := 0;
   --
begin
   --
   select si.vl_sld_credor_transp_oa
     into vn_vl_sld_credor_ant_oa
     from subapur_icms si
    where si.empresa_id                = gt_row_subapur_icms.empresa_id
      and to_char(si.dt_ini, 'rrrrmm') = to_char(add_months(gt_row_subapur_icms.dt_ini, -1), 'rrrrmm')
      and si.dm_ind_apur_icms          = gt_row_subapur_icms.dm_ind_apur_icms
      and si.dm_situacao               = 3; -- Processada
   --
   return nvl(vn_vl_sld_credor_ant_oa,0);
   --
exception
   when others then
      return 0;
end fkg_saldo_credor_ant;
------------------------------------------------------------------------------------------------------
-- Função retorna o Valor total de Ajustes “Estornos de Débitos”                                    --
-- Utilizada para compôr: Campo 07-VL_ESTORNOS_DEB_OA: Valor total de Ajustes “Estornos de Débitos” --
------------------------------------------------------------------------------------------------------
function fkg_soma_estorno_deb
         return ajust_subapur_icms.vl_aj_apur%type
is
   --
   vn_vl_aj_apur ajust_subapur_icms.vl_aj_apur%type;
   --
begin
   --
   select nvl(sum(asi.vl_aj_apur),0) vl_aj_apur
     into vn_vl_aj_apur
     from ajust_subapur_icms     asi,
          cod_aj_saldo_apur_icms cod
    where asi.subapuricms_id = gt_row_subapur_icms.id
      and cod.id             = asi.codajsaldoapuricms_id
      and cod.dm_apur        in (0) -- icms
      and cod.dm_util        in (3); -- utilização: 3-Estorno de débito
   --
   return vn_vl_aj_apur;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_estorno_deb: '||sqlerrm);
end fkg_soma_estorno_deb;
-----------------------------------------------------------------------------------------------
-- Função retorna o Valor total de "Ajustes a crédito"                                       --
-- Utilizada para compôr: Campo 06-VL_TOT_AJ_CREDITOS_OA: Valor total de "Ajustes a crédito" --
-----------------------------------------------------------------------------------------------
function fkg_soma_tot_aj_credito
         return ajust_subapur_icms.vl_aj_apur%type
is
   --
   vn_vl_aj_apur ajust_subapur_icms.vl_aj_apur%type := 0;
   --
begin
   --
   select nvl(sum(asi.vl_aj_apur),0) vl_aj_apur
     into vn_vl_aj_apur
     from ajust_subapur_icms     asi
        , cod_aj_saldo_apur_icms cod
    where asi.subapuricms_id = gt_row_subapur_icms.id
      and cod.id             = asi.codajsaldoapuricms_id
      and cod.dm_apur       in (0) -- icms
      and cod.dm_util       in (2); -- utilização: 2-Outros Créditos
   --
   return vn_vl_aj_apur;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_tot_aj_credito: '||sqlerrm);
end fkg_soma_tot_aj_credito;
--------------------------------------------------------------------------------------------------------------------------------------------
-- Função retorna o Valor total dos créditos por "Entradas e aquisições com crédito do imposto"                                           --
-- Utilizada para compôr: Campo 05-VL_TOT_TRANSF_CREDITOS_OA: Valor total dos créditos por "Entradas e aquisições com crédito do imposto" --
--------------------------------------------------------------------------------------------------------------------------------------------
function fkg_soma_credporentr_c197_d197
         return inf_prov_docto_fiscal.vl_icms%type
is
   --
   vn_vl_icms   inf_prov_docto_fiscal.vl_icms%type := 0;
   vn_vl_icms1  inf_prov_docto_fiscal.vl_icms%type := 0;
   vn_vl_icms2  inf_prov_docto_fiscal.vl_icms%type := 0;
   --
begin
   --
           select sum(nvl(ipdf.vl_icms,0)) vl_icms
             into vn_vl_icms1
             from nota_fiscal            nf
                , sit_docto              sd
                , mod_fiscal             mf
                , nfinfor_fiscal         nfi
                , inf_prov_docto_fiscal  ipdf
                , cod_ocor_aj_icms       cod
            where nf.empresa_id        = gt_row_subapur_icms.empresa_id
              and nf.dm_st_proc        = 4 -- 4-autorizada
              and nf.dm_arm_nfe_terc   = 0 -- Não é nota de armazenamento fiscal
              and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 1 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
              and sd.id                = nf.sitdocto_id
              and sd.cd           not in ('01', '07') -- extemporâneos
              and mf.id                = nf.modfiscal_id
              and mf.cod_mod          in ('01', '1B', '04', '55', '65', '06', '29', '28', '21', '22')
              and nfi.notafiscal_id    = nf.id
              and ipdf.nfinforfisc_id  = nfi.id
              and cod.id               = ipdf.codocorajicms_id
              and cod.dm_reflexo_apur  = '5' -- corresponde ao 3º dígito do código: substr(cod.cod_aj,3,1) = 5 -- D-Estorno de Crédito
              and ((nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 3 and cod.dm_tipo_apur = '3') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 3-Apuração 1
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 4 and cod.dm_tipo_apur = '4') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 4-Apuração 2
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 5 and cod.dm_tipo_apur = '5') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 5-Apuração 3
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 6 and cod.dm_tipo_apur = '6') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 6-Apuração 4
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 7 and cod.dm_tipo_apur = '7') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 7-Apuração 5
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 8 and cod.dm_tipo_apur = '8')); -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 8-Apuração 6

           select sum(nvl(ci.vl_icms,0)) vl_icms
             into vn_vl_icms2
             from conhec_transp    ct
                , sit_docto        sd
                , ct_reg_anal      cr
                , ctinfor_fiscal   cf
                , ct_inf_prov      ci
                , cod_ocor_aj_icms co
            where ct.empresa_id       = gt_row_subapur_icms.empresa_id
              and ct.dm_st_proc       = 4 -- Autorizado
              and ct.dm_arm_cte_terc  = 0
              and ((ct.dm_ind_emit = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 1 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
                    or
                   (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
              and sd.id               = ct.sitdocto_id
              and sd.cd          not in ('01', '07') -- extemporâneos
              and cr.conhectransp_id  = ct.id
              and cf.conhectransp_id  = ct.id
              and ci.ctinforfiscal_id = cf.id
              and co.id               = ci.codocorajicms_id
              and co.dm_reflexo_apur  = '5' -- corresponde ao 3º dígito do código: substr(cod.cod_aj,3,1) = 5 -- D-Estorno de Crédito
              and ((nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 3 and co.dm_tipo_apur = '3') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 3-Apuração 1
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 4 and co.dm_tipo_apur = '4') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 4-Apuração 2
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 5 and co.dm_tipo_apur = '5') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 5-Apuração 3
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 6 and co.dm_tipo_apur = '6') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 6-Apuração 4
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 7 and co.dm_tipo_apur = '7') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 7-Apuração 5
                    or
                   (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 8 and co.dm_tipo_apur = '8')); -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 8-Apuração 6
   --
   vn_vl_icms := nvl(vn_vl_icms1,0) + nvl(vn_vl_icms2,0);
   --
   return vn_vl_icms;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_credporentr_c197_d197: '||sqlerrm);
end fkg_soma_credporentr_c197_d197;
--------------------------------------------------------------------------------------------------------
-- Função retorna o Valor total de Ajustes “Estornos de créditos”                                     --
-- Utilizada para compôr: Campo 04-VL_ESTORNOS_CRED_OA: Valor total de Ajustes “Estornos de créditos” --
--------------------------------------------------------------------------------------------------------
function fkg_soma_estornos_cred
         return ajust_subapur_icms.vl_aj_apur%type
is
   --
   vn_vl_aj_apur ajust_subapur_icms.vl_aj_apur%type := 0;
   --
begin
   --
   select nvl(sum(asi.vl_aj_apur),0) vl_aj_apur
     into vn_vl_aj_apur
     from ajust_subapur_icms     asi
        , cod_aj_saldo_apur_icms cod
    where asi.subapuricms_id = gt_row_subapur_icms.id
      and cod.id             = asi.codajsaldoapuricms_id
      and cod.dm_apur       in (0) -- icms
      and cod.dm_util       in (1); -- utilização: 1-Estorno de crédito
   --
   return vn_vl_aj_apur;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_estornos_cred: '||sqlerrm);
end fkg_soma_estornos_cred;
---------------------------------------------------------------------------------------------
-- Função retorna o Valor total de "Ajustes a débito"                                      --
-- Utilizada para compôr: Campo 03-VL_TOT_AJ_DEBITOS_OA: Valor total de "Ajustes a débito" --
---------------------------------------------------------------------------------------------
function fkg_soma_tot_aj_debitos
         return inf_prov_docto_fiscal.vl_icms%type
is
   --
   vn_vl_aj_apur ajust_subapur_icms.vl_aj_apur%type := 0;
   --
begin
   --
   select nvl(sum(asi.vl_aj_apur),0) vl_aj_apur
     into vn_vl_aj_apur
     from ajust_subapur_icms     asi
        , cod_aj_saldo_apur_icms cod
    where asi.subapuricms_id = gt_row_subapur_icms.id
      and cod.id             = asi.codajsaldoapuricms_id
      and cod.dm_apur       in (0) -- icms
      and cod.dm_util       in (0); -- utilização: 0-Outros Débitos
   --
   return vn_vl_aj_apur;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_tot_aj_debitos: '||sqlerrm);
end fkg_soma_tot_aj_debitos;
---------------------------------------------------------------------------------------------------------------------------------------
-- Função retorna o Total de Débito por Saída dos Registros C197 e D197                                                              --
-- Utilizada para compôr: Campo 02-VL_TOT_TRANSF_DEBITOS_OA: Valor total dos débitos por "Saídas e prestações com débito do imposto" --
---------------------------------------------------------------------------------------------------------------------------------------
function fkg_soma_debporsaida_c197_d197
         return inf_prov_docto_fiscal.vl_icms%type
is
   --
   vn_vl_icms   inf_prov_docto_fiscal.vl_icms%type := 0;
   vn_vl_icms1  inf_prov_docto_fiscal.vl_icms%type := 0;
   vn_vl_icms2  inf_prov_docto_fiscal.vl_icms%type := 0;
   --
begin
   --
   select sum(nvl(ipdf.vl_icms,0)) vl_icms
      into vn_vl_icms1
      from nota_fiscal            nf
         , sit_docto              sd
         , mod_fiscal             mf
         , nfinfor_fiscal         nfi
         , inf_prov_docto_fiscal  ipdf
         , cod_ocor_aj_icms       cod
     where nf.empresa_id        = gt_row_subapur_icms.empresa_id
       and nf.dm_st_proc        = 4 -- 4-autorizada
       and nf.dm_arm_nfe_terc   = 0 -- Não é nota de armazenamento fiscal
       and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
             or
            (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 1 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
             or
            (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
             or
            (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
       and sd.id                = nf.sitdocto_id
       and sd.cd           not in ('01', '07') -- extemporâneos
       and mf.id                = nf.modfiscal_id
       and mf.cod_mod          in ('01', '1B', '04', '55', '65', '06', '29', '28', '21', '22')
       and nfi.notafiscal_id    = nf.id
       and ipdf.nfinforfisc_id  = nfi.id
       and cod.id               = ipdf.codocorajicms_id
       and cod.dm_reflexo_apur  = '2' -- corresponde ao 3º dígito do código: substr(cod.cod_aj,3,1) = 2-C-Estorno de Débito
       and ((nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 3 and cod.dm_tipo_apur = '3') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 3-Apuração 1
             or
            (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 4 and cod.dm_tipo_apur = '4') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 4-Apuração 2
             or
            (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 5 and cod.dm_tipo_apur = '5') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 5-Apuração 3
             or
            (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 6 and cod.dm_tipo_apur = '6') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 6-Apuração 4
             or
            (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 7 and cod.dm_tipo_apur = '7') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 7-Apuração 5
             or
            (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 8 and cod.dm_tipo_apur = '8')); -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 8-Apuração 6
   --
   select sum(nvl(ci.vl_icms,0)) vl_icms
     into vn_vl_icms2
     from conhec_transp    ct
        , sit_docto        sd
        , ct_reg_anal      cr
        , ctinfor_fiscal   cf
        , ct_inf_prov      ci
        , cod_ocor_aj_icms co
    where ct.empresa_id       = gt_row_subapur_icms.empresa_id
      and ct.dm_st_proc       = 4 -- Autorizado
      and ct.dm_arm_cte_terc  = 0
      and ((ct.dm_ind_emit = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 1 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (ct.dm_ind_emit = 0 and ct.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(ct.dt_sai_ent,ct.dt_hr_emissao)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
      and sd.id               = ct.sitdocto_id
      and sd.cd          not in ('01', '07') -- extemporâneos
      and cr.conhectransp_id  = ct.id
      and cf.conhectransp_id  = ct.id
      and ci.ctinforfiscal_id = cf.id
      and co.id               = ci.codocorajicms_id
      and co.dm_reflexo_apur  = '2' -- corresponde ao 3º dígito do código: substr(cod.cod_aj,3,1) = 2-C-Estorno de Débito
      and ((nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 3 and co.dm_tipo_apur = '3') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 3-Apuração 1
            or
           (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 4 and co.dm_tipo_apur = '4') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 4-Apuração 2
            or
           (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 5 and co.dm_tipo_apur = '5') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 5-Apuração 3
            or
           (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 6 and co.dm_tipo_apur = '6') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 6-Apuração 4
            or
           (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 7 and co.dm_tipo_apur = '7') -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 7-Apuração 5
            or
           (nvl(gt_row_subapur_icms.dm_ind_apur_icms,0) = 8 and co.dm_tipo_apur = '8')); -- corresponde ao 4º dígito do código: substr(cod.cod_aj,4,1) = 8-Apuração 6
   --
   vn_vl_icms := nvl(vn_vl_icms1,0) + nvl(vn_vl_icms2,0);
   --
   return vn_vl_icms;
   --
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error(-20101, 'Erro na fkg_soma_debporsaida_c197_d197: '||sqlerrm);
end fkg_soma_debporsaida_c197_d197;
--
-------------------------------------------------------------------------------------------
procedure pkb_criar_c195_c197 
is
   --
   vn_fase                   number;
   vn_loggenerico_id         Log_Generico.id%TYPE;
   vn_existe_param           number;
   vn_existe_nfi             number;
   vn_existe_inf             number;
   vn_erro                   number;
   vn_vl_imp_trib            imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_icms       imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_ipi        imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_st         imp_itemnf.vl_imp_trib%TYPE;
   vn_nfinfor_id             nfinfor_fiscal.id%TYPE;
   --
   cursor c_nf is
     select distinct nf.id notafiscal_id,       
         par.obslanctofiscal_id,
         par.txt_compl,
         par.codocorajicms_id        
    from nota_fiscal                  nf,
         item_nota_fiscal             inf,
         PARAM_GERA_INF_PROV_DOC_FISC par,
         imp_itemnf ii, 
         tipo_imposto ti, 
         cod_st cs
   where nf.empresa_id =  gt_row_subapur_icms.empresa_id
     and nf.dm_st_proc = 4
     and nf.dm_arm_nfe_terc = 0 -- Não é nota de armazenamento fiscal
     and ii.itemnf_id   = inf.id 
     and ti.id          = ii.tipoimp_id
     and cs.id          = ii.codst_id
     and cs.tipoimp_id  = 1 
     and ti.cd          = 1
     and nf.id          = inf.notafiscal_id
     and par.empresa_id = nf.empresa_id
     and par.cfop_id    = inf.cfop_id
     --
     and (nvl(par.codst_id,0) <> 0 and par.codst_id =  ii.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = ii.aliq_apli)
     --
     and (nvl(par.orig,999) <> 999 and par.orig = inf.orig)
     --
   and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 1 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
   order by nf.id;
   --
   cursor c_difal (en_notafiscal_id nota_fiscal.id%type) is
    select inf.id  itemnf_id,
         imp.tipoimp_id,
         imp.vl_base_calc,
         imp.aliq_apli,
         imp.vl_imp_trib,
         imp.dm_tipo,
         imp.vl_bc_fcp,
         imp.aliq_fcp,
         imp.vl_fcp,
         (inf.vl_item_bruto - inf.vl_desc) vl_item,
         par.cfop_id,         
         par.aliq_icms,        
         par.aliq_presumida,
         imp.aliq_apli aliq_icms2, 
         par.dm_mod_bc_icms,  
         par.dm_soma_ipi,  
         par.dm_soma_st,  
         imp.codst_id codst_id2
    from nota_fiscal                  nf,
         item_nota_fiscal             inf,
         imp_itemnf                   imp,
         PARAM_GERA_INF_PROV_DOC_FISC par  
   where nf.id = en_notafiscal_id 
     and nf.dm_st_proc = 4
     and nf.dm_arm_nfe_terc = 0 -- Não é nota de armazenamento fiscal
     and nf.id = inf.notafiscal_id
     and imp.itemnf_id = inf.id 
      and imp.tipoimp_id in (select id from tipo_imposto where cd = '1')
     and par.empresa_id = nf.empresa_id
     and par.cfop_id    = inf.cfop_id 
     and (nvl(par.codst_id,0) <> 0 and par.codst_id =  imp.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = imp.aliq_apli)
     and (nvl(par.orig,999) <> 999 and par.orig = inf.orig)
   order by nf.id;
   --
begin
   --
   vn_fase := 1;
   --
   begin
     select count(*)
       into vn_existe_param
       from PARAM_GERA_INF_PROV_DOC_FISC
      where 1 = 1
        and empresa_id = gt_row_subapur_icms.empresa_id;
   exception
     when others then
       vn_existe_param := null;
   end;
   --
   if nvl(vn_existe_param,0) > 0 then
      --
      vn_fase := 2;
      --       
         for rec_nf in c_nf loop
            exit when c_nf%notfound or (c_nf%notfound) is null;
       --
       vn_fase := 4;
       --            
       begin
         select count(*),id
           into vn_existe_nfi, vn_nfinfor_id
           from nfinfor_fiscal
          where 1 = 1
            and notafiscal_id = rec_nf.notafiscal_id
            group by id;
       exception
         when others then
           vn_existe_nfi := null;
           vn_nfinfor_id := null;
       end;
       --
       if nvl(vn_existe_nfi,0) = 0 then
       --
       vn_fase := 5;
       -- c195
                             insert into nfinfor_fiscal ( id
                                                , notafiscal_id
                                                , obslanctofiscal_id
                                                , txt_compl
                                                )
                                         values ( nfinforfiscal_seq.nextval --id
                                                , rec_nf.notafiscal_id -- notafiscal_id
                                                , rec_nf.obslanctofiscal_id --obslanctofiscal_id
                                                , rec_nf.txt_compl -- txt_compl
                                                );
         else
           --
           update nfinfor_fiscal
           set  obslanctofiscal_id = rec_nf.obslanctofiscal_id,
                txt_compl          = rec_nf.txt_compl
           where notafiscal_id = rec_nf.notafiscal_id;                                                  
           --
         end if;  
         --
         for rec_difal in c_difal(rec_nf.notafiscal_id) loop
               exit when c_difal%notfound or (c_difal%notfound) is null;
       --
       vn_fase := 6;
       -- 
            begin
             select count(*) 
              into vn_existe_inf
              from inf_prov_docto_fiscal
             where 1=1
              and itemnf_id   = rec_difal.itemnf_id;
               exception
                when others then
                vn_existe_inf := null;
            end;
       --
       vn_fase := 7;
       -- 
       if rec_difal.DM_MOD_BC_ICMS = 0 then
       --
         vn_vl_imp_trib_icms := rec_difal.vl_item *(rec_difal.aliq_presumida/100);
       --
       end if;
       --
       if rec_difal.DM_MOD_BC_ICMS = 1 and rec_difal.tipoimp_id = 1 then
          vn_vl_imp_trib_icms := rec_difal.vl_base_calc *(rec_difal.aliq_presumida/100);
        --
       end if;
       --
       if rec_difal.dm_soma_ipi = 1 and rec_difal.tipoimp_id = 3 then
       --   
       vn_vl_imp_trib_ipi := rec_difal.vl_imp_trib;
       --
       end if;
       --
       if rec_difal.dm_soma_st = 1 and rec_difal.tipoimp_id = 2 then
       --
       vn_vl_imp_trib_st  := rec_difal.vl_imp_trib; 
       --
       end if;
       --
       vn_vl_imp_trib:=  nvl(vn_vl_imp_trib_icms,0) +  nvl(vn_vl_imp_trib_ipi,0) +  nvl(vn_vl_imp_trib_st,0);
       --c197
       
       if (nvl(vn_existe_nfi,0) = 0) and (nvl(vn_existe_inf,0) = 0)  then
                     insert into inf_prov_docto_fiscal ( id
                                    , nfinforfisc_id
                                    , codocorajicms_id
                                    , descr_compl_aj
                                    , itemnf_id
                                    , vl_bc_icms
                                    , aliq_icms
                                    , vl_icms
                                    , vl_outros
                                    )
                             values ( infprovdoctofiscal_Seq.nextval --id
                                    , nfinforfiscal_seq.currval --nfinforfisc_id
                                    , rec_nf.codocorajicms_id
                                    , 'Diferencial de alíquota' -- descr_compl_aj
                                    , rec_difal.itemnf_id --itemnf_id
                                    , rec_difal.vl_base_calc -- vl_bc_icms
                                    , rec_difal.aliq_presumida -- aliq_icms
                                    , vn_vl_imp_trib -- vl_icms
                                    , 0 -- vl_outros
                                    );
         else if (nvl(vn_existe_nfi,0) = 1) and (nvl(vn_existe_inf,0) = 0)  then
                     insert into inf_prov_docto_fiscal ( id
                                    , nfinforfisc_id
                                    , codocorajicms_id
                                    , descr_compl_aj
                                    , itemnf_id
                                    , vl_bc_icms
                                    , aliq_icms
                                    , vl_icms
                                    , vl_outros
                                    )
                             values ( infprovdoctofiscal_Seq.nextval --id
                                    , vn_nfinfor_id --nfinforfisc_id
                                    , rec_nf.codocorajicms_id
                                    , 'Diferencial de alíquota' -- descr_compl_aj
                                    , rec_difal.itemnf_id --itemnf_id
                                    , rec_difal.vl_base_calc -- vl_bc_icms
                                    , rec_difal.aliq_presumida -- aliq_icms
                                    , vn_vl_imp_trib -- vl_icms
                                    , 0 -- vl_outros
                                    );                           
         --
         else
         --
                 update inf_prov_docto_fiscal
                 set descr_compl_aj = 'Diferencial de alíquota', 
                     vl_bc_icms     = rec_difal.vl_base_calc, 
                     aliq_icms      = rec_difal.aliq_presumida, 
                     vl_icms        = vn_vl_imp_trib, 
                     vl_outros      = 0
                 where itemnf_id = rec_difal.itemnf_id;
                 --
         end if; 
         --
         end if;
        --
        vn_fase := 8;
        --
    end loop;
    --
   -- end if;
    --  
   end loop;
   --
   commit;
   -- 
 end if;
 --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_apur_icms.pkb_criar_c195_c197 fase ( '||vn_fase||' ):'||sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico.id%TYPE;
      begin
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id  => vn_loggenerico_id
                                          , ev_mensagem        => gv_mensagem_log
                                          , ev_resumo          => gv_mensagem_log
                                          , en_tipo_log        => ERRO_DE_SISTEMA
                                          , en_referencia_id   => gt_row_subapur_icms.id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_criar_c195_c197;
--
-------------------------------------------------------------------------------------------
procedure pkb_criar_d195_d197
is
   --
   vn_fase                   number;
   vn_loggenerico_id         Log_Generico.id%TYPE;
   vn_existe_param           number;
   vn_existe_cti             number;
   vn_existe_inf             number;
   vn_erro                   number;
   vn_vl_imp_trib            imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_icms       imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_ipi        imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_st         imp_itemnf.vl_imp_trib%TYPE;
   ctinfor_id                ctinfor_fiscal.id%TYPE;
   --
   cursor c_ct is
       select ct.id conhectransp_id,
         par.cfop_id,
         par.codst_id,
         par.aliq_icms,
         par.obslanctofiscal_id,
         par.txt_compl,
         par.codocorajicms_id,
         par.aliq_presumida,
         par.dm_mod_bc_icms,
         par.dm_soma_ipi,
         par.dm_soma_st,  
         cr.codst_id codst_id2,
         cr.aliq_icms aliq_icms2,
         cr.vl_icms,
         cr.VL_BC_ICMS,
         cr.vl_base_outro
    from conhec_transp                ct
         ,ct_reg_anal                 cr  
         ,PARAM_GERA_INF_PROV_DOC_FISC par
   where 1=1
   and ct.empresa_id =  gt_row_subapur_icms.empresa_id
     and ct.dm_st_proc = 4
     and ct.id          =  cr.CONHECTRANSP_ID
     and par.empresa_id = ct.empresa_id
     and par.cfop_id    = cr.cfop_id
     --
     and (nvl(par.codst_id,0) <> 0 and par.codst_id = cr.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = cr.aliq_icms)
     and (nvl(par.orig,999) <> 999 and par.orig = cr.dm_orig_merc)
     --
           and ((ct.dm_ind_emit = 1 and nvl(ct.dt_sai_ent,ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
               or
              (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 0 and ct.dt_hr_emissao between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
               or
              (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 1 and nvl(ct.dt_sai_ent,ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))) /* */
    order by ct.id;
   --
begin
   --
   vn_fase := 1;
   --
   begin
     select count(*)
       into vn_existe_param
       from PARAM_GERA_INF_PROV_DOC_FISC
      where 1 = 1
        and empresa_id = gt_row_subapur_icms.empresa_id;
   exception
     when others then
       vn_existe_param := null;
   end;
   --
   if nvl(vn_existe_param,0) > 0 then
      --
      vn_fase := 2;
      -- 
         for rec_ct in c_ct loop
            exit when c_ct%notfound or (c_ct%notfound) is null;
            --
            vn_erro := null;
            --
            if nvl(rec_ct.codst_id,0) > 0 then 
               if  rec_ct.codst_id <> rec_ct.codst_id2 then 
                 vn_erro := 1;
               end if;
            end if;
       --
       vn_fase := 3;
       -- 
            if nvl(rec_ct.aliq_icms,0) > 0 then  
               if  rec_ct.aliq_icms <> rec_ct.aliq_icms2 then 
                 vn_erro := 1;
                end if;
            end if;
            --
       if nvl(vn_erro,0)  = 0 then
       --
       vn_fase := 4;
       --            
       begin
         select count(*), id
           into vn_existe_cti, ctinfor_id
           from ctinfor_fiscal
          where 1 = 1
            and CONHECTRANSP_ID = rec_ct.conhectransp_id
            group by id;
       exception
         when others then
           vn_existe_cti := null;
           ctinfor_id    := null;
       end;
       --
       if nvl(vn_existe_cti,0) = 0 then
       --
       vn_fase := 5;
       --                     --D195           
                             insert into ctinfor_fiscal ( id
                                                , conhectransp_id
                                                , obslanctofiscal_id
                                                , txt_compl
                                                )
                                         values ( nfinforfiscal_seq.nextval --id
                                                , rec_ct.conhectransp_id -- conhectransp_id
                                                , rec_ct.obslanctofiscal_id --obslanctofiscal_id
                                                , rec_ct.txt_compl -- txt_compl
                                                );
           else
           --
           update ctinfor_fiscal
           set  obslanctofiscal_id = rec_ct.obslanctofiscal_id,
                txt_compl          = rec_ct.txt_compl
           where conhectransp_id = rec_ct.conhectransp_id;                                                  
           --                                         
       end if;  
         -- 
       vn_fase := 6;
       -- 
            begin
             select count(*) 
              into vn_existe_inf
              from ct_inf_prov
             where 1=1
               and ctinforfiscal_id in (select id from ctinfor_fiscal where CONHECTRANSP_ID = rec_ct.conhectransp_id);
               exception
                when others then
                vn_existe_inf := null;
            end;
       --
       vn_fase := 7;
       -- 
       vn_vl_imp_trib_icms := rec_ct.VL_BC_ICMS *(rec_ct.aliq_presumida/100);
       --
       if rec_ct.dm_soma_ipi = 1 then
       --         
        vn_vl_imp_trib_ipi  := 0;
       --
       end if;
       --
       if rec_ct.dm_soma_st = 1 then
       --
        vn_vl_imp_trib_st := 0;
       --
       end if;
       --
       vn_vl_imp_trib:=   nvl(vn_vl_imp_trib_icms,0) +  nvl(vn_vl_imp_trib_ipi,0) +  nvl(vn_vl_imp_trib_st,0);
       --  
       if (nvl(vn_existe_cti,0) = 0) and (nvl(vn_existe_inf,0) = 0)  then                  
                     --D197
                     insert into ct_inf_prov ( id
                                    , ctinforfiscal_id
                                    , codocorajicms_id
                                    , descr_compl_aj
                                    , vl_bc_icms
                                    , aliq_icms
                                    , vl_icms
                                    , vl_outros
                                    )
                             values ( infprovdoctofiscal_Seq.nextval --id
                                    , nfinforfiscal_seq.currval --nfinforfisc_id
                                    , rec_ct.codocorajicms_id -- codocorajicms_id
                                    , 'Diferencial de alíquota' -- descr_compl_aj
                                    , rec_ct.vl_bc_icms -- vl_bc_icms
                                    , rec_ct.aliq_presumida -- aliq_icms
                                    , vn_vl_imp_trib -- vl_icms
                                    , rec_ct.vl_base_outro
                                    );
           else if (nvl(vn_existe_cti,0) = 1)  and (nvl(vn_existe_inf,0) = 0) then
                        --D197
                     insert into ct_inf_prov ( id
                                    , ctinforfiscal_id
                                    , codocorajicms_id
                                    , descr_compl_aj
                                    , vl_bc_icms
                                    , aliq_icms
                                    , vl_icms
                                    , vl_outros
                                    )
                             values ( infprovdoctofiscal_Seq.nextval --id
                                    , ctinfor_id --ctinforfisc_id
                                    , rec_ct.codocorajicms_id -- codocorajicms_id
                                    , 'Diferencial de alíquota' -- descr_compl_aj
                                    , rec_ct.vl_bc_icms -- vl_bc_icms
                                    , rec_ct.aliq_presumida -- aliq_icms
                                    , vn_vl_imp_trib -- vl_icms
                                    , rec_ct.vl_base_outro
                                    );
           
           else 
              update ct_inf_prov
                 set descr_compl_aj = 'Diferencial de alíquota', 
                     vl_bc_icms     = rec_ct.vl_bc_icms, 
                     aliq_icms      = rec_ct.aliq_presumida, 
                     vl_icms        = vn_vl_imp_trib, 
                     vl_outros      = rec_ct.vl_base_outro
                 where ctinforfiscal_id in (select id from ctinfor_fiscal where CONHECTRANSP_ID = rec_ct.conhectransp_id);                    
            --    
            end if;
            --
            end if;  
                --
                vn_fase := 8;
                -- 
                end if;
                --
             commit;
            --
         end loop;
         -- 
         end if;
         --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_apur_icms.pkb_criar_d195_d197 fase ( '||vn_fase||' ):'||sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico.id%TYPE;
      begin
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id  => vn_loggenerico_id
                                          , ev_mensagem        => gv_mensagem_log
                                          , ev_resumo          => gv_mensagem_log
                                          , en_tipo_log        => ERRO_DE_SISTEMA
                                          , en_referencia_id   => gt_row_subapur_icms.id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_criar_d195_d197;
--
-------------------------------------------------------------------------------------------
procedure pkb_criar_1921_1923
is
   --
   vn_fase                   number;
   vn_loggenerico_id         Log_Generico.id%TYPE;
   vn_existe_param           number;
   vn_existe_sub             number;
   vn_existe_inf             number;
   vn_vl_imp_trib            imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_ct         imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_icms       imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_ipi        imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_imp_trib_st         imp_itemnf.vl_imp_trib%TYPE;
   vn_subapur_icms_id        subapur_icms.id%TYPE;
   vn_aliq_presumida_total   imp_itemnf.vl_imp_trib%TYPE;
   vn_vl_aj_apur_ant         imp_itemnf.vl_imp_trib%TYPE;
   --
      cursor c_nf is
     select distinct nf.id referencia_id,
         null cfop_id,
         null codst_id,
         null aliq_icms,
         par.CODAJSALDOAPURICMS_ID,
         (select descr from COD_AJ_SALDO_APUR_ICMS where id = par.codajsaldoapuricms_id) descr,
         null aliq_presumida,
         null dm_mod_bc_icms,
         null dm_soma_ipi,
         null dm_soma_st,  
         null codst_id2,
         null aliq_icms2,
         0 vl_icms,
         0 VL_BC_ICMS,
         0 vl_base_outro,
         'NF' origem
    from nota_fiscal                  nf,
         item_nota_fiscal             inf,
         PARAM_GERA_REG_SUB_APUR_ICMS par,
         imp_itemnf ii, 
         tipo_imposto ti, 
         cod_st cs
   where nf.empresa_id =  gt_row_subapur_icms.empresa_id
     and nf.dm_st_proc = 4
     and nf.dm_arm_nfe_terc = 0 -- Não é nota de armazenamento fiscal
     and ii.itemnf_id   = inf.id 
     and ti.id          = ii.tipoimp_id
     and cs.id          = ii.codst_id
     and cs.tipoimp_id  =  1 
     and ti.cd          = 1
     and nf.id          = inf.notafiscal_id
     and par.empresa_id = nf.empresa_id
     and par.cfop_id    = inf.cfop_id
     --
     and (nvl(par.codst_id,0) <> 0 and par.codst_id =  ii.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = ii.aliq_apli)
     --
     and (nvl(par.orig,999) <> 999 and par.orig = inf.orig)
     --
     and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 1 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
  union all
        select ct.id referencia_id,
         par.cfop_id,
         par.codst_id,
         par.aliq_icms,
         par.codajsaldoapuricms_id,
         (select descr from COD_AJ_SALDO_APUR_ICMS where id = par.codajsaldoapuricms_id) descr,
         par.aliq_presumida,
         par.dm_mod_bc_icms,
         par.dm_soma_ipi,     
         par.dm_soma_st,  
         cr.codst_id codst_id2,
         cr.aliq_icms aliq_icms2,
         cr.vl_icms,
         cr.VL_BC_ICMS,
         cr.vl_base_outro,
         'CT' origem
    from conhec_transp                ct
         ,ct_reg_anal                 cr  
         ,PARAM_GERA_REG_SUB_APUR_ICMS par
   where 1=1
   and ct.empresa_id =  gt_row_subapur_icms.empresa_id
     and ct.dm_st_proc = 4
     and ct.id          =  cr.CONHECTRANSP_ID
     and par.empresa_id = ct.empresa_id
     and par.cfop_id    = cr.cfop_id
     --
     and (nvl(par.codst_id,0) <> 0 and par.codst_id =  cr.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = cr.aliq_icms)
      and (nvl(par.orig,999) <> 999 and par.orig = cr.dm_orig_merc)
     --
           and ((ct.dm_ind_emit = 1 and nvl(ct.dt_sai_ent,ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
               or
              (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 0 and ct.dt_hr_emissao between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
               or
              (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 1 and nvl(ct.dt_sai_ent,ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)));
   --
   cursor c_1921 is
     select CODAJSALDOAPURICMS_ID, descr,  sum(aliq_presumida) aliq_presumida   from (
  select par.CODAJSALDOAPURICMS_ID,
         (select descr from COD_AJ_SALDO_APUR_ICMS where id = par.codajsaldoapuricms_id) descr,
        sum(par.aliq_presumida) aliq_presumida
    from nota_fiscal                  nf,
         item_nota_fiscal             inf,
         PARAM_GERA_REG_SUB_APUR_ICMS par,
         imp_itemnf ii, 
         tipo_imposto ti, 
         cod_st cs
   where nf.empresa_id =  gt_row_subapur_icms.empresa_id
     and nf.dm_st_proc = 4
     and nf.dm_arm_nfe_terc = 0 -- Não é nota de armazenamento fiscal
     and ii.itemnf_id   = inf.id 
     and ti.id          = ii.tipoimp_id
     and cs.id          = ii.codst_id
     and cs.tipoimp_id  =  1 
     and ti.cd          = 1
     --
     and (nvl(par.codst_id,0) <> 0 and par.codst_id =  ii.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = ii.aliq_apli)
     --
     and (nvl(par.orig,999) <> 999 and par.orig = inf.orig)
     --
     and nf.id          = inf.notafiscal_id
     and par.empresa_id = nf.empresa_id
     and par.cfop_id    = inf.cfop_id
     and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
      or
     (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 1 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
      or
     (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
      or
     (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
     group by par.codajsaldoapuricms_id
        union all
    select par.codajsaldoapuricms_id,
         (select descr from COD_AJ_SALDO_APUR_ICMS where id = par.codajsaldoapuricms_id) descr,
         sum(par.aliq_presumida)  aliq_presumida 
    from conhec_transp                ct
         ,ct_reg_anal                 cr  
         ,PARAM_GERA_REG_SUB_APUR_ICMS par
   where 1=1
   and ct.empresa_id =  gt_row_subapur_icms.empresa_id
     and ct.dm_st_proc = 4
     and ct.id          =  cr.CONHECTRANSP_ID
     and par.empresa_id = ct.empresa_id
     and par.cfop_id    = cr.cfop_id
     --
     and (nvl(par.codst_id,0) <> 0 and par.codst_id =  cr.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = cr.aliq_icms)
      and (nvl(par.orig,999) <> 999 and par.orig = cr.dm_orig_merc)
     --
     and ((ct.dm_ind_emit = 1 and nvl(ct.dt_sai_ent,ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
     or
    (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 0 and ct.dt_hr_emissao between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
     or
    (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 1 and nvl(ct.dt_sai_ent,ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
    group by par.codajsaldoapuricms_id) 
   group by CODAJSALDOAPURICMS_ID,descr;
      --
   cursor c_difal (en_notafiscal_id nota_fiscal.id%type) is
    select inf.id  itemnf_id,
         imp.tipoimp_id,
         imp.vl_base_calc,
         imp.aliq_apli,
         imp.vl_imp_trib,
         imp.dm_tipo,
         imp.vl_bc_fcp,
         imp.aliq_fcp,
         imp.vl_fcp,
         (inf.vl_item_bruto - inf.vl_desc) vl_item,
         par.cfop_id,         
         par.aliq_icms,        
         par.aliq_presumida,
         imp.aliq_apli aliq_icms2, 
         par.dm_mod_bc_icms,  
         par.dm_soma_ipi,  
         par.dm_soma_st,  
         imp.codst_id codst_id2   
    from nota_fiscal                  nf,
         item_nota_fiscal             inf,
         imp_itemnf                   imp,
         PARAM_GERA_REG_SUB_APUR_ICMS par 
   where nf.id = en_notafiscal_id 
     and nf.dm_st_proc = 4
     and nf.dm_arm_nfe_terc = 0 -- Não é nota de armazenamento fiscal
     and nf.id = inf.notafiscal_id
     and imp.tipoimp_id in (select id from tipo_imposto where cd = '1')
     and imp.itemnf_id = inf.id 
     and par.empresa_id = nf.empresa_id
     and par.cfop_id    = inf.cfop_id 
     and (nvl(par.codst_id,0) <> 0 and par.codst_id =  imp.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = imp.aliq_apli)
     and (nvl(par.orig,999) <> 999 and par.orig = inf.orig)
   order by nf.id;
   --
begin
   --
   vn_fase := 1;
   --
   begin
     select count(*)
       into vn_existe_param
       from PARAM_GERA_INF_PROV_DOC_FISC
      where 1 = 1
        and empresa_id = gt_row_subapur_icms.empresa_id;
   exception
     when others then
       vn_existe_param := null;
   end;
   --
   if nvl(vn_existe_param,0) > 0 then
      --
      vn_fase := 2;
      -- 
         for rec_1921 in c_1921 loop
            exit when c_1921%notfound or (c_1921%notfound) is null;
       --     
     vn_fase := 4;
       --            
        vn_subapur_icms_id:= gt_row_subapur_icms.id;
       --
       vn_fase := 5;
       --
       begin
          select count(*)
            into vn_existe_sub
            from ajust_subapur_icms
           where 1 = 1
             and SUBAPURICMS_ID  = vn_subapur_icms_id
             and CODAJSALDOAPURICMS_ID = rec_1921.CODAJSALDOAPURICMS_ID
             and VL_AJ_APUR = rec_1921.ALIQ_PRESUMIDA;
        exception
          when others then
            vn_existe_sub := null;
        end;
        --
       if nvl(vn_existe_sub,0) = 0 then 
       -- 1921
      insert into ajust_subapur_icms ( id
                          , SUBAPURICMS_ID
                          , CODAJSALDOAPURICMS_ID
                          , DESCR_COMPL_AJ
                          , VL_AJ_APUR
                           )
                   values ( ajustsubapuricms_seq.nextval --id
                          , vn_subapur_icms_id
                          , rec_1921.CODAJSALDOAPURICMS_ID
                          , rec_1921.descr
                          , 0
                          );
          else 
          -- 
            update ajust_subapur_icms
            set  DESCR_COMPL_AJ = rec_1921.descr,
                 VL_AJ_APUR     = 0--rec_1921.ALIQ_PRESUMIDA
             where 1 = 1
             and SUBAPURICMS_ID  = vn_subapur_icms_id
             and CODAJSALDOAPURICMS_ID = rec_1921.CODAJSALDOAPURICMS_ID;                               
        end if; 
        --
 for rec_nf in c_nf loop
            exit when c_nf%notfound or (c_nf%notfound) is null;
            --   
  if   (rec_1921.CODAJSALDOAPURICMS_ID = rec_nf.CODAJSALDOAPURICMS_ID) then 
         --1923
       if rec_nf.origem = 'CT' then
       -- 
       vn_vl_imp_trib_ct:= null;
       --
       if rec_nf.DM_MOD_BC_ICMS = 0 then
       --
         vn_vl_imp_trib_icms := rec_nf.vl_bc_icms *(rec_nf.aliq_presumida/100);
       --
       else
         vn_vl_imp_trib_icms := rec_nf.vl_bc_icms *(rec_nf.aliq_presumida/100);
       --
       end if;
       --
       vn_vl_imp_trib_ct := vn_vl_imp_trib_icms;
       --
        begin
          select count(*)
            into vn_existe_inf
            from inf_ajust_subapur_icms_nf
           where 1 = 1
             and REFERENCIA_ID = rec_nf.referencia_id;
        exception
          when others then
            vn_existe_inf := null;
        end;
        --
        vn_vl_aj_apur_ant  := null;   
        --
           begin
             select VL_AJ_APUR
               into vn_vl_aj_apur_ant
               from ajust_subapur_icms
              where 1 = 1
                and SUBAPURICMS_ID = vn_subapur_icms_id
                and CODAJSALDOAPURICMS_ID = rec_1921.CODAJSALDOAPURICMS_ID;
           exception
             when others then
               vn_vl_aj_apur_ant := null;
           end;
        --
        if nvl(vn_existe_inf,0) = 0 then
        --
        insert into inf_ajust_subapur_icms_nf ( id
              , AJUSTSUBAPURICMS_ID
              , REFERENCIA_ID
              , ITEMNF_ID
              , VL_AJ_ITEM
              , OBJ_REFERENCIA
              )
       values ( infajustsubapuricmsnf_Seq.nextval --id
              , ajustsubapuricms_seq.currval --  
              , rec_nf.referencia_id
              , NULL--itemnf_id
              , vn_vl_imp_trib_ct
              , 'CONHEC_TRANSP'
              );
           --                         
           else
          --
          update inf_ajust_subapur_icms_nf
             set VL_AJ_ITEM = vn_vl_imp_trib_ct
           where REFERENCIA_ID = rec_nf.referencia_id
             and OBJ_REFERENCIA = 'CONHEC_TRANSP';
          --
          end if;
          --
           vn_aliq_presumida_total := null; 
           --     
           vn_aliq_presumida_total:=  nvl(vn_vl_imp_trib_ct,0) + nvl(vn_vl_aj_apur_ant,0);
           --
           update ajust_subapur_icms
              set VL_AJ_APUR = vn_aliq_presumida_total
            where 1 = 1
              and SUBAPURICMS_ID = vn_subapur_icms_id
              and CODAJSALDOAPURICMS_ID = rec_1921.CODAJSALDOAPURICMS_ID;
           --
           commit; 
          --
         else
         -----item nf-------------
         for rec_difal in c_difal(rec_nf.referencia_id) loop
               exit when c_difal%notfound or (c_difal%notfound) is null;
       --
       vn_fase := 6;
       -- 
       vn_existe_inf :=null;
       --
       begin
         select count(*)
           into vn_existe_inf
           from inf_ajust_subapur_icms_nf
          where 1 = 1
            and REFERENCIA_ID = rec_nf.referencia_id
            and itemnf_id = rec_difal.itemnf_id;
       exception
         when others then
           vn_existe_inf := null;
       end;
       --
       vn_fase := 7;
       -- 
       vn_vl_imp_trib_icms:= null;
       --
       if rec_difal.DM_MOD_BC_ICMS = 0 then
       --
         vn_vl_imp_trib_icms := rec_difal.vl_item *(rec_difal.aliq_presumida/100);
       --     
       end if;
       --
       if rec_difal.DM_MOD_BC_ICMS = 1 and rec_difal.tipoimp_id = 1 then
       --
        vn_vl_imp_trib_icms :=  rec_difal.vl_base_calc * (rec_difal.aliq_presumida/100);
       --
       end if;
       --
       if rec_difal.dm_soma_ipi = 1  and rec_difal.tipoimp_id = 3 then
       --         
       vn_vl_imp_trib_ipi := rec_difal.vl_imp_trib;   
       --
       end if;
       --
       if rec_difal.dm_soma_st = 1  and rec_difal.tipoimp_id = 2 then
       --
       vn_vl_imp_trib_st := rec_difal.vl_imp_trib;   
       --
       end if;
       --
       vn_vl_imp_trib:=  nvl(vn_vl_imp_trib_icms,0) + nvl(vn_vl_imp_trib_ipi,0) + nvl(vn_vl_imp_trib_st,0);
       --
       vn_vl_aj_apur_ant  := null;   
       --
           begin
             select VL_AJ_APUR
               into vn_vl_aj_apur_ant
               from ajust_subapur_icms
              where 1 = 1
                and SUBAPURICMS_ID = vn_subapur_icms_id
                and CODAJSALDOAPURICMS_ID = rec_1921.CODAJSALDOAPURICMS_ID;
           exception
             when others then
               vn_vl_aj_apur_ant := null;
           end;
           --   
       --
       if nvl(vn_existe_inf,0) = 0 then
         --
         insert into inf_ajust_subapur_icms_nf ( id
                        , AJUSTSUBAPURICMS_ID
                        , REFERENCIA_ID
                        , ITEMNF_ID
                        , VL_AJ_ITEM
                        , OBJ_REFERENCIA
                        )
                 values ( infajustsubapuricmsnf_Seq.nextval --id
                        , ajustsubapuricms_seq.currval --nfinforfisc_id , gt_row_param_efd_icms_ipi.codocorajicms_id_difal -- codocorajicms_id
                        , rec_nf.referencia_id
                        , rec_difal.itemnf_id --itemnf_id
                        , vn_vl_imp_trib -- vl_icms
                        , 'NOTA_FISCAL'
                        );
          else
          --
          update inf_ajust_subapur_icms_nf
             set VL_AJ_ITEM = vn_vl_imp_trib
           where REFERENCIA_ID = rec_nf.referencia_id
             and ITEMNF_ID = rec_difal.itemnf_id
             and OBJ_REFERENCIA = 'NOTA_FISCAL';
          --
          end if;  
          --
          vn_fase := 8;
          --
           vn_aliq_presumida_total := null; 
           --
           vn_aliq_presumida_total:=  nvl(vn_vl_imp_trib,0) +  nvl(vn_vl_aj_apur_ant,0);
           --
           update ajust_subapur_icms
              set VL_AJ_APUR = vn_aliq_presumida_total
            where 1 = 1
              and SUBAPURICMS_ID = vn_subapur_icms_id
              and CODAJSALDOAPURICMS_ID = rec_1921.CODAJSALDOAPURICMS_ID;
           --
           commit;    
          --
      end loop;--intens_nf
      --
      end if;
      --   
   commit;

   --
   end if;
   --
   end loop; --nf
   --
   end loop;--1921
   -- 
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_apur_icms.pkb_criar_1921_1923 fase ( '||vn_fase||' ):'||sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico.id%TYPE;
      begin
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id  => vn_loggenerico_id
                                          , ev_mensagem        => gv_mensagem_log
                                          , ev_resumo          => gv_mensagem_log
                                          , en_tipo_log        => ERRO_DE_SISTEMA
                                          , en_referencia_id   => gt_row_subapur_icms.id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_criar_1921_1923;
--
-------------------------------------------------------------------------------------------
procedure pkb_limpa_c190_d190_1920
is
   --
   vn_fase number := null;
   vn_subapur_icms_id    subapur_icms.id%type;
   vn_nfinfor_fiscal_id  nfinfor_fiscal.id%type;
   vn_ctinfor_fiscal_id  ctinfor_fiscal.id%type;
   --
  cursor c_nf is
     select nf.id referencia_id,
            par.codajsaldoapuricms_id,
            'NF' origem 
    from nota_fiscal                  nf,
         item_nota_fiscal             inf,
         PARAM_GERA_REG_SUB_APUR_ICMS par,
         imp_itemnf ii, 
         tipo_imposto ti, 
         cod_st cs
   where nf.empresa_id =  gt_row_subapur_icms.empresa_id
     and nf.dm_st_proc = 4
     and nf.dm_arm_nfe_terc = 0 -- Não é nota de armazenamento fiscal     
     and ii.itemnf_id   = inf.id 
     and ti.id          = ii.tipoimp_id
     and cs.id          = ii.codst_id
     and cs.tipoimp_id  =  1 
     and ti.cd          = 1
     and nf.id          = inf.notafiscal_id
     and par.empresa_id = nf.empresa_id
     and par.cfop_id    = inf.cfop_id
     --
     and (nvl(par.codst_id,0) <> 0 and par.codst_id =  ii.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = ii.aliq_apli)
     and (nvl(par.orig,999) <> 999 and par.orig = inf.orig)
     --
     and ((nf.dm_ind_emit = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 1 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 0 and trunc(nf.dt_emiss) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
            or
           (nf.dm_ind_emit = 0 and nf.dm_ind_oper = 0 and gn_dm_dt_escr_dfepoe = 1 and trunc(nvl(nf.dt_sai_ent,nf.dt_emiss)) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)))
  union all
    select ct.id referencia_id,
           par.codajsaldoapuricms_id,
               'CT' origem 
    from conhec_transp                ct
         ,ct_reg_anal                 cr  
         ,PARAM_GERA_REG_SUB_APUR_ICMS par
   where 1=1
   and ct.empresa_id =  gt_row_subapur_icms.empresa_id
     and ct.dm_st_proc = 4 
     and ct.id          =  cr.CONHECTRANSP_ID
     and par.empresa_id = ct.empresa_id
     and par.cfop_id    = cr.cfop_id
     --
     and (nvl(par.codst_id,0) <> 0 and par.codst_id =  cr.codst_id)
     and (nvl(par.aliq_icms,0) <> 0 and par.aliq_icms = cr.aliq_icms)
      and (nvl(par.orig,999) <> 999 and par.orig = cr.dm_orig_merc)
     --
           and ((ct.dm_ind_emit = 1 and nvl(ct.dt_sai_ent,ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
               or
              (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 0 and ct.dt_hr_emissao between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin))
               or
              (ct.dm_ind_emit = 0 and gn_dm_dt_escr_dfepoe = 1 and nvl(ct.dt_sai_ent,ct.dt_hr_emissao) between trunc(gt_row_subapur_icms.dt_ini) and trunc(gt_row_subapur_icms.dt_fin)));
   --
begin
   --
   vn_fase := 1;
   -- 
   vn_subapur_icms_id := gt_row_subapur_icms.id;
   --
   for rec_nf in c_nf loop
            exit when c_nf%notfound or (c_nf%notfound) is null;
   --
   if nvl(rec_nf.referencia_id,0) > 0 and rec_nf.origem = 'NF' then
   --
   begin
     select id
       into vn_nfinfor_fiscal_id
       from nfinfor_fiscal
      where 1 = 1
        and notafiscal_id = rec_nf.referencia_id; 
   exception
     when others then
       vn_nfinfor_fiscal_id := null;
   end;
   --            
   vn_fase := 2;
   -- 
   -- Limpar os dados das tabelas de apuração c197
   begin
    delete from   inf_prov_docto_fiscal where nfinforfisc_id = vn_nfinfor_fiscal_id;
   exception 
      when others then
        null;
   end;   
   --
   vn_fase := 3;
   --
   begin
   -- Limpar os dados das tabelas de apuração c195 
   delete from   nfinfor_fiscal where  id = vn_nfinfor_fiscal_id;
      exception 
      when others then
        null;
   end;   
   --
   end if;
   --
   if nvl(rec_nf.referencia_id,0) > 0 and rec_nf.origem = 'CT' then
     --
     begin
       select id
         into vn_ctinfor_fiscal_id
         from ctinfor_fiscal
        where 1 = 1
          and conhectransp_id = rec_nf.referencia_id; 
     exception
       when others then
         vn_ctinfor_fiscal_id := null;
     end;
     --   
   vn_fase := 4;
   --
   --d197
   begin
   delete from ct_inf_prov where ctinforfiscal_id = vn_ctinfor_fiscal_id;  
      exception 
      when others then
        null;
   end; 
   --
   vn_fase := 5;
   -- 
   --d195
   begin
   delete from ctinfor_fiscal where id = vn_ctinfor_fiscal_id;
      exception 
      when others then
        null;
   end; 
   --
   end if;
   --
    vn_fase := 6;
    --
    if nvl(vn_subapur_icms_id,0) > 0 and nvl (rec_nf.codajsaldoapuricms_id,0) > 0 then
    --1923
    begin
      delete from inf_ajust_subapur_icms_nf where REFERENCIA_ID = rec_nf.referencia_id;     
    exception 
      when others then
        null;
   end; 
   --
    end if;
    --
    vn_fase := 7;
     --1921
     begin
      delete from ajust_subapur_icms where subapuricms_id = vn_subapur_icms_id and codajsaldoapuricms_id = rec_nf.codajsaldoapuricms_id;
     exception 
      when others then
        null;
   end; 
   --
   commit;
   --
   end loop;
   --
exception
   when others then
      --
      gv_resumo_log := 'Erro na pk_apur_icms.pkb_limpa_c190_d190_1920 fase ('||vn_fase||'): '||sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico.id%TYPE;
      begin
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id  => vn_loggenerico_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_resumo_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => gn_referencia_id
                                     , ev_obj_referencia  => gv_obj_referencia );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_resumo_log);
      --
end pkb_limpa_c190_d190_1920;
-------------------------------------------------------------------------------------------------------
--| Procedure para recuperar os dados da sub-apuração de imposto de ICMS
-------------------------------------------------------------------------------------------------------
procedure pkb_dados_subapur_icms( en_subapuricms_id in subapur_icms.id%type )
is
   --
   vn_fase             number := 0;
   vt_log_generico     dbms_sql.number_table;
   vn_loggenerico_id   log_generico.id%type;
   --
   cursor c_subapur_icms is
   select si.*
     from subapur_icms si
    where si.id = en_subapuricms_id;
   --
begin
   --
   vn_fase := 1;
   --
   gt_row_subapur_icms := null;
   --
   if nvl(en_subapuricms_id,0) > 0 then
      --
      vn_fase := 2;
      --
      open c_subapur_icms;
      fetch c_subapur_icms into gt_row_subapur_icms;
      close c_subapur_icms;
      --
      vn_fase := 3;
      --
      if nvl(gt_row_subapur_icms.id,0) > 0 then
         --
         vn_fase := 4;
         --
         gn_referencia_id  := gt_row_subapur_icms.id;
         gv_obj_referencia := 'SUBAPUR_ICMS';
         --
         vn_fase := 5;
         -- monta mensagem para o log da Sub-Apuração de ICMS
         gv_mensagem_log := 'Sub-Apuração de ICMS com Data Inicial '||to_char(gt_row_subapur_icms.dt_ini,'dd/mm/rrrr')||
                            ' até Data Final '||to_char(gt_row_subapur_icms.dt_fin,'dd/mm/rrrr');
         --
         gn_dm_dt_escr_dfepoe := pk_csf.fkg_dmdtescrdfepoe_empresa( en_empresa_id => gt_row_subapur_icms.empresa_id );
         --
      else
         --
         vn_fase := 6;
         --
         gn_referencia_id  := null;
         gv_obj_referencia := null;
         --
      end if;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro em pk_subapur_icms.pkb_dados_subapur_icms fase( '||vn_fase||' ):'||sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico.id%type;
      begin
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                     , ev_mensagem       => gv_mensagem_log
                                     , ev_resumo         => null
                                     , en_tipo_log       => erro_de_sistema
                                     , en_referencia_id  => null
                                     , ev_obj_referencia => gv_obj_referencia );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_dados_subapur_icms;
-------------------------------------------------------------------------------------------------------
--| Procedimento para calcular a Sub-Apuração do ICMS
-------------------------------------------------------------------------------------------------------
procedure pkb_calcular( en_subapuricms_id in subapur_icms.id%type )
is
   --
   vn_fase             number := 0;
   vt_log_generico     dbms_sql.number_table;
   vn_loggenerico_id   log_generico.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(en_subapuricms_id,0) > 0 then
      --
      vn_fase := 2;
      -- recupera os dados da apuração de imposto
      pkb_dados_subapur_icms( en_subapuricms_id => en_subapuricms_id );
      --
      vn_fase := 3;
      --
      if nvl(gt_row_subapur_icms.id,0) > 0 then
         --
         vn_fase := 4;
         --
         --Automação na geração dos registros c195 c197 d195 d197 1921 1923
         pkb_criar_c195_c197;
         pkb_criar_d195_d197;
         pkb_criar_1921_1923;
         --
         if nvl(gt_row_subapur_icms.dm_situacao,0) = 0 then -- 0-Em aberto; 1-Calculada; 2-Erro de Calculo; 2-Processada; 4-Erro de validação
            --
            vn_fase := 5;
            --
            -- Campo 02-VL_TOT_TRANSF_DEBITOS_OA: Valor total dos débitos por "Saídas e prestações com débito do imposto"
            -- Validação: Os citados registros C197 e D197 devem ser originados em documentos fiscais de saídas que geraram débitos de ICMS de operações próprias.
            -- Ficam excluídos os documentos extemporâneos (COD_SIT = ‘01’) e os documentos complementares extemporâneos (COD_SIT = ‘07’).
            -- Serão considerados os registros cujos documentos estejam compreendidos no período informado no registro 1910 utilizando, para tanto, o campo DT_E_S (C100) e
            -- DT_DOC ou DT_A_P (D100). Quando o campo DT_E_S ou DT_A_P do registro C100 não for informado, utilizar o campo DT_DOC.
            -- campo 02-IND_APUR_ICMS = “3” - somar os valores do campo 07-VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “2” e “3”
            -- campo 02-IND_APUR_ICMS = “4” - somar os valores do campo 07-VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “2” e “4”;
            -- campo 02-IND_APUR_ICMS = “5” - somar os valores do campo 07-VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “2” e “5”;
            -- campo 02-IND_APUR_ICMS = “6” - somar os valores do campo 07-VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “2” e “6”;
            -- campo 02-IND_APUR_ICMS = “7” - somar os valores do campo 07-VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “2” e “7”;
            -- campo 02-IND_APUR_ICMS = “8” - somar os valores do campo 07-VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “2” e “8”.
            --
            gt_row_subapur_icms.vl_tot_transf_debitos_oa := nvl(fkg_soma_debporsaida_c197_d197,0);
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 6;
            --
            -- Campo 03-VL_TOT_AJ_DEBITOS_OA: Valor total de "Ajustes a débito"
            -- Validação: o valor informado deve corresponder ao somatório do campo VL_AJ_APUR dos registros 1921,
            -- se o terceiro caractere for igual a ‘0’ e o quarto caractere do campo COD_AJ_APUR do registro 1921 for igual a ‘0’.
            --
            gt_row_subapur_icms.vl_tot_aj_debitos_oa := nvl(fkg_soma_tot_aj_debitos,0);
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 7;
            --
            -- Campo 04-VL_ESTORNOS_CRED_OA: Valor total de Ajustes “Estornos de créditos”
            -- Validação: o valor informado deve corresponder ao somatório do campo VL_AJ_APUR dos registros 1921,
            -- se o terceiro caractere for igual a ‘0’ e o quarto caractere do campo COD_AJ_APUR do registro 1921 for igual a ‘1’.
            --
            gt_row_subapur_icms.vl_estornos_cred_oa := nvl(fkg_soma_estornos_cred,0);
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 8;
            --
            -- Campo 05-VL_TOT_TRANSF_CREDITOS_OA: Valor total dos créditos por "Entradas e aquisições com crédito do imposto"
            -- Validação: Os citados registros C197 e D197 devem ser originados em documentos fiscais de entradas que geraram créditos de ICMS de operações próprias.
            -- Ficam excluídos os documentos extemporâneos (COD_SIT = ‘01’) e os documentos complementares extemporâneos (COD_SIT = ‘07’).
            -- Serão considerados os registros cujos documentos estejam compreendidos no período informado no registro 1910, utilizando para tanto o campo
            -- DT_E_S (C100) e DT_DOC ou DT_A_P (D100). Quando o campo DT_E_S ou DT_A_P do registro C100 não for informado, utilizar o campo DT_DOC.
            -- campo 02-IND_APUR_ICMS = “3” - somar os valores do campo 07- VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “5” e “3”;
            -- campo 02-IND_APUR_ICMS = “4” - somar os valores do campo 07- VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “5” e “4”;
            -- campo 02-IND_APUR_ICMS = “5” - somar os valores do campo 07- VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “5” e “5”;
            -- campo 02-IND_APUR_ICMS = “6” - somar os valores do campo 07- VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “2” e “6”;
            -- campo 02-IND_APUR_ICMS = “7” - somar os valores do campo 07- VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “2” e “7”;
            -- campo 02-IND_APUR_ICMS = “8” - somar os valores do campo 07- VL_ICMS dos registros C197 e D197 onde o terceiro e quarto caracteres do código de ajuste forem iguais a “2” e “8”.
            --
            gt_row_subapur_icms.vl_tot_transf_creditos_oa := nvl(fkg_soma_credporentr_c197_d197,0);
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 9;
            --
            -- Campo 06-VL_TOT_AJ_CREDITOS_OA: Valor total de "Ajustes a crédito"
            -- Validação: o valor informado deve corresponder ao somatório dos valores constantes dos registros 1921,
            -- quando o terceiro caractere for igual a ‘0’ e o quarto caractere for igual a ‘2’, do COD_AJ_APUR do registro 1921.
            --
            gt_row_subapur_icms.vl_tot_aj_creditos_oa := nvl(fkg_soma_tot_aj_credito,0);
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 10;
            --
            -- Campo 07-VL_ESTORNOS_DEB_OA: Valor total de Ajustes “Estornos de Débitos”
            -- Validação: o valor informado deve corresponder ao somatório do VL_AJ_APUR dos registros 1921,
            -- quando o terceiro caractere for igual a ‘0’ e o quarto caractere for igual a ‘3’, do COD_AJ_APUR do registro 1921.
            --
            gt_row_subapur_icms.vl_estornos_deb_oa := nvl(fkg_soma_estorno_deb,0);
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 11;
            --
            -- Campo 08-VL_SLD_CREDOR_ANT_OA: Valor total de "Saldo credor do período anterior"
            -- Validação: Informar o saldo credor do período anterior da respectiva apuração em separado (sub-apuração).
            --
            if nvl(gt_row_subapur_icms.vl_sld_credor_ant_oa,0) <= 0 then
               --
               gt_row_subapur_icms.vl_sld_credor_ant_oa := nvl(fkg_saldo_credor_ant,0);
               --
            end if;
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 12;
            --
            -- Campo 09-VL_SLD_APURADO_OA: Valor do saldo devedor apurado
            -- Validação: o valor informado deve ser preenchido com base na expressão:
            -- soma do total de débitos transferidos (VL_TOT_TRANSF_DEBITOS_OA) com total de ajustes a débito (VL_TOT_AJ_DEBITOS_OA) com
            -- total de estorno de crédito (VL_ESTORNOS_CRED_OA) menos a soma do total de créditos transferidos (VL_TOT_TRANSF_CREDITOS_OA) com
            -- total de ajustes a crédito (VL_TOT_AJ_CREDITOS_OA) com total de estorno de débito (VL_ESTORNOS_DEB_OA) com
            -- saldo credor do período anterior (VL_SLD_CREDOR_ANT_OA).
            -- Se o valor da expressão for maior ou igual a “0” (zero), então este valor deve ser informado neste campo e o campo 12 (VL_SLD_CREDOR_TRANSP_OA)
            -- deve ser igual a “0” (zero). Se o valor da expressão for menor que “0” (zero), então este campo deve ser preenchido com “0” (zero) e o valor
            -- absoluto da expressão deve ser informado no campo VL_SLD_CREDOR_TRANSP_OA.
            --
            gt_row_subapur_icms.vl_sld_apurado_oa := ( (nvl(gt_row_subapur_icms.vl_tot_transf_debitos_oa,0) + nvl(gt_row_subapur_icms.vl_tot_aj_debitos_oa,0) +
                                                        nvl(gt_row_subapur_icms.vl_estornos_cred_oa,0)) -
                                                       (nvl(gt_row_subapur_icms.vl_tot_transf_creditos_oa,0) + nvl(gt_row_subapur_icms.vl_tot_aj_creditos_oa,0) +
                                                        nvl(gt_row_subapur_icms.vl_estornos_deb_oa,0) + nvl(gt_row_subapur_icms.vl_sld_credor_ant_oa,0)) );
            --
            vn_fase := 13;
            --
            if nvl(gt_row_subapur_icms.vl_sld_apurado_oa,0) < 0 then
               --
               gt_row_subapur_icms.vl_sld_apurado_oa := 0;
               --
            end if;
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 14;
            --
            -- Campo 10-VL_TOT_DED: Valor total de "Deduções"
            -- Validação: o valor informado deve corresponder ao somatório do campo VL_ICMS dos registros C197 e D197, se o terceiro caractere do código de
            -- ajuste dos registros C197 e D197, for “6” e o quarto caractere for “3”, “4” ou “5”, somado ao valor total informado nos registros 1921, quando
            -- o terceiro caractere for igual a ‘0’ e o quarto caractere for igual a ‘4’, do campo COD_AJ_APUR do registro 1921.
            -- Para o somatório do campo VL_ICMS dos registros C197 e D197 devem ser considerados os documentos fiscais compreendidos no período informado no
            -- registro 1910, comparando com a data constante no campo DT_E_S do registro C100 e DT_DOC ou DT_A_P do registro D100, exceto se COD_SIT do registro
            -- C100 for igual a ‘01’ (extemporâneo) ou igual a ‘07’ (Complementar extemporânea), cujo valor deve ser somado no primeiro período de apuração
            -- informado no registro 1910, quando houver mais de um período de apuração. Quando o campo DT_E_S não for informado, utilizar o campo DT_DOC.
            --
            gt_row_subapur_icms.vl_tot_ded := nvl(fkg_soma_tot_ded_c197_d197,0) + nvl(fkg_soma_tot_ded_e111,0);
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 15;
            --
            -- Campo 11-VL_ICMS_RECOLHER_OA: Valor total de "ICMS a recolher (09-10)
            -- Validação: o valor informado deve corresponder à diferença entre o campo VL_SLD_APURADO_OA e o campo VL_TOT_DED. O valor da soma deste campo
            -- com o campo DEB_ESP_OA deve ser igual à soma dos valores do campo VL_OR do registro 1926.
            --
            gt_row_subapur_icms.vl_icms_recolher_oa := nvl(gt_row_subapur_icms.vl_sld_apurado_oa,0) - nvl(gt_row_subapur_icms.vl_tot_ded,0);
            --
            vn_fase := 16;
            --
            if nvl(gt_row_subapur_icms.vl_icms_recolher_oa,0) < 0 then
               --
               gt_row_subapur_icms.vl_icms_recolher_oa := 0;
               --
            end if;
            --
            -------------------------------------------------------------------------------------------------------
            --
            vn_fase := 17;
            --
            -- Campo 12-VL_SLD_CREDOR_TRANSP_OA: Valor total de "Saldo credor a transportar para o período seguinte”
            -- Validação: se o valor da expressão: “soma do total de débitos (VL_TOT_TRANSF_DEBITOS_OA) mais total de ajustes a débito (VL_AJ_DEBITOS_OA) mais
            -- total de estorno de crédito (VL_ESTORNOS_CRED_OA)” menos “a soma do total de créditos transferidos (VL_TOT_TRANSF_CREDITOS_OA) mais total de
            -- ajuste a crédito (VL_AJ_CREDITOS_OA) mais total de estorno de débito (VL_ESTORNOS_DEB_OA) mais saldo credor do período anterior
            -- (VL_SLD_CREDOR_ANT_OA)”, for maior que ZERO, este campo deve ser preenchido com “0” (zero) e o campo 11 (VL_SLD_APURADO) deve ser igual ao valor
            -- do resultado. Se for menor que “0” (zero), o valor absoluto do resultado deve ser informado neste campo e o campo VL_SLD_APURADO deve ser
            -- informado com “0” (zero).
            --
            gt_row_subapur_icms.vl_sld_credor_transp_oa := ((nvl(gt_row_subapur_icms.vl_tot_transf_debitos_oa,0) +
                                                             nvl(gt_row_subapur_icms.vl_tot_aj_debitos_oa,0) +
                                                             nvl(gt_row_subapur_icms.vl_estornos_cred_oa,0)) -
                                                            (nvl(gt_row_subapur_icms.vl_tot_transf_creditos_oa,0) +
                                                             nvl(gt_row_subapur_icms.vl_tot_aj_creditos_oa,0) +
                                                             nvl(gt_row_subapur_icms.vl_estornos_deb_oa,0) +
                                                             nvl(gt_row_subapur_icms.vl_sld_credor_ant_oa,0)));
            --
            vn_fase := 18;
            --
            if nvl(gt_row_subapur_icms.vl_sld_credor_transp_oa,0) > 0 then
               --
               gt_row_subapur_icms.vl_sld_apurado_oa       := nvl(gt_row_subapur_icms.vl_sld_credor_transp_oa,0);
               gt_row_subapur_icms.vl_sld_credor_transp_oa := 0;
               --
            elsif nvl(gt_row_subapur_icms.vl_sld_credor_transp_oa,0) < 0 then
                  --
                  gt_row_subapur_icms.vl_sld_credor_transp_oa := (nvl(gt_row_subapur_icms.vl_sld_credor_transp_oa,0) * (-1));
                  gt_row_subapur_icms.vl_sld_apurado_oa       := 0;
                  --
            end if;
            --
            vn_fase := 19;
            --
            -- Campo 13-DEB_ESP_OA: Valores recolhidos ou a recolher, extraapuração
            -- Preenchimento: Informar o correspondente ao somatório dos valores:
            -- a) de ICMS correspondentes aos doctos fiscais extemporâneos (COD_SIT = “01”) e dos doctos fiscais complementares extemporâneos (COD_SIT = “07”),
            -- referentes às apurações em separado;
            -- b) de ajustes do campo VL_ICMS dos registros C197 e D197, se o terceiro caractere do código informado no campo COD_AJ dos registros C197 e D197
            -- for igual a “7” (débitos especiais) e o quarto caractere for igual a “3”, “4” ou “5” (“Apuração 1 – Bloco 1900” ou “Apuração 2 – Bloco 1900” ou
            -- “Apuração 3 – Bloco 1900”) referente aos documentos compreendidos no período a que se refere a escrituração; e
            -- c) de ajustes do campo VL_AJ_APUR do registro 1921, se o terceiro caractere do código informado no campo COD_AJ_APUR do registro 1921 for igual
            -- a “0” (apuração ICMS próprio) e o quarto caractere for igual a “5”(débito especial).
            -- Validação: O valor da soma deste campo com o campo VL_ICMS_RECOLHER_OA deve ser igual à soma dos valores do campo VL_OR do registro 1926.
            --
            gt_row_subapur_icms.vl_deb_esp_oa := (nvl(fkg_soma_cred_ext_op_c,0) + nvl(fkg_soma_cred_ext_op_d,0) +
                                                  nvl(fkg_soma_dep_esp_c197_d197,0)  + nvl(fkg_soma_dep_esp_e111,0));
            --
            vn_fase := 20;
            --

            --
            begin
               update subapur_icms si
                  set si.dm_situacao               = 1 -- Calculada
                    , si.vl_tot_transf_debitos_oa  = nvl(gt_row_subapur_icms.vl_tot_transf_debitos_oa,0)
                    , si.vl_tot_aj_debitos_oa      = nvl(gt_row_subapur_icms.vl_tot_aj_debitos_oa,0)
                    , si.vl_estornos_cred_oa       = nvl(gt_row_subapur_icms.vl_estornos_cred_oa,0)
                    , si.vl_tot_transf_creditos_oa = nvl(gt_row_subapur_icms.vl_tot_transf_creditos_oa,0)
                    , si.vl_tot_aj_creditos_oa     = nvl(gt_row_subapur_icms.vl_tot_aj_creditos_oa,0)
                    , si.vl_estornos_deb_oa        = nvl(gt_row_subapur_icms.vl_estornos_deb_oa,0)
                    , si.vl_sld_credor_ant_oa      = nvl(gt_row_subapur_icms.vl_sld_credor_ant_oa,0)
                    , si.vl_sld_apurado_oa         = nvl(gt_row_subapur_icms.vl_sld_apurado_oa,0)
                    , si.vl_tot_ded                = nvl(gt_row_subapur_icms.vl_tot_ded,0)
                    , si.vl_icms_recolher_oa       = nvl(gt_row_subapur_icms.vl_icms_recolher_oa,0)
                    , si.vl_sld_credor_transp_oa   = nvl(gt_row_subapur_icms.vl_sld_credor_transp_oa,0)
                    , si.vl_deb_esp_oa             = nvl(gt_row_subapur_icms.vl_deb_esp_oa,0)
                where si.id = gt_row_subapur_icms.id;
            exception
               when others then
                  raise_application_error (-20101, 'Problemas ao atualizar os valores da sub-apuração. Erro = '||sqlerrm);
            end;
            --
            commit;
            --
            vn_fase := 21;
            --
            gv_resumo_log := 'Cálculo da Sub-Apuração de ICMS realizado com sucesso!';
            --
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                        , ev_mensagem       => gv_mensagem_log
                                        , ev_resumo         => gv_resumo_log
                                        , en_tipo_log       => info_subapur_icms
                                        , en_referencia_id  => gn_referencia_id
                                        , ev_obj_referencia => gv_obj_referencia );
            --
         else -- situação da sub-apuração <> 0-em aberto
            --
            vn_fase := 22;
            --
            begin
               update subapur_icms si
                  set si.dm_situacao = 2 -- Erro de cálculo
                where si.id = gt_row_subapur_icms.id;
            exception
               when others then
                  raise_application_error (-20101, 'Problemas ao atualizar situação = 2-Erro de cálculo devido a situação da sub-apuração. Erro = '||sqlerrm);
            end;
            --
            vn_fase := 23;
            --
            commit;
            --
            vn_fase := 24;
            --
            gv_resumo_log := 'Situação da Sub-Apuração incorreta, deveria estar com "0-Em Aberto" para efetuar o cálculo. Processo não realizado. '||
                             'Desfaça os processos.';
            --
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                        , ev_mensagem       => gv_mensagem_log
                                        , ev_resumo         => gv_resumo_log
                                        , en_tipo_log       => erro_de_validacao
                                        , en_referencia_id  => gn_referencia_id
                                        , ev_obj_referencia => gv_obj_referencia );
            --
         end if;
         --
      else -- identificador da sub-apuração inválido
         --
         vn_fase := 25;
         --
         begin
            update subapur_icms si
               set si.dm_situacao = 2 -- Erro de cálculo
             where si.id = gt_row_subapur_icms.id;
         exception
            when others then
               raise_application_error (-20101, 'Problemas ao atualizar situação = 2-Erro de cálculo devido a falta do identificador da sub-apuração. '||
                                                'Erro = '||sqlerrm);
         end;
         --
         vn_fase := 26;
         --
         commit;
         --
         vn_fase := 27;
         --
         gv_resumo_log := 'Identificador da Sub-Apuração não encontrado para efetuar o cálculo. Processo não realizado!';
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                     , ev_mensagem       => gv_mensagem_log
                                     , ev_resumo         => gv_resumo_log
                                     , en_tipo_log       => erro_de_validacao
                                     , en_referencia_id  => gn_referencia_id
                                     , ev_obj_referencia => gv_obj_referencia );
         --
      end if;
      --
   end if;
   --
exception
   when others then
      --
      update subapur_icms si
         set si.dm_situacao = 2 -- Erro no Calculo
       where si.id = en_subapuricms_id;
      --
      commit;
      --
      gv_mensagem_log := 'Erro em pk_subapur_icms.pkb_calcular fase ( '||vn_fase||' ):'||sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico.id%type;
      begin
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                     , ev_mensagem       => gv_mensagem_log
                                     , ev_resumo         => null
                                     , en_tipo_log       => erro_de_sistema
                                     , en_referencia_id  => null
                                     , ev_obj_referencia => gv_obj_referencia );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_calcular;
-------------------------------------------------------------------------------------------------------
--| Procedimento para limpar os caracteres especiais dos campos das descrições do Bloco 1900
-------------------------------------------------------------------------------------------------------
procedure pkb_limpa_carac_bloco_1900
is
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   -- No registro 1921 - Ajuste/benefício/incentivo da sub-apuração do icms
   update ajust_subapur_icms ai
      set ai.descr_compl_aj = trim(pk_csf.fkg_converte(ai.descr_compl_aj))
    where ai.subapuricms_id = gt_row_subapur_icms.id;
   --
   vn_fase := 2;
   -- No registro 1922 - Informações adicionais dos ajustes da sub-apuração do icms
   update inf_ajust_subapur_icms ia
      set ia.descr_proc = trim(pk_csf.fkg_converte(ia.descr_proc))
        , ia.txt_compl  = trim(pk_csf.fkg_converte(ia.txt_compl))
    where ia.ajustsubapuricms_id in ( select ai.id
                                        from ajust_subapur_icms ai
                                       where ai.subapuricms_id = gt_row_subapur_icms.id );
   --
   vn_fase := 3;
   -- No registro 1925 - Informações adicionais da sub-apuração – valores declaratórios
   update infadic_subapur_icms ii
      set ii.descr_compl_aj = trim(pk_csf.fkg_converte(ii.descr_compl_aj))
    where ii.subapuricms_id = gt_row_subapur_icms.id;
   --
   vn_fase := 4;
   -- No registro 1926 - Obrigações do icms a recolher – operações referentes à sub-apuração
   update obrig_rec_subapur_icms os
      set os.descr_proc = trim(pk_csf.fkg_converte(os.descr_proc))
        , os.txt_compl  = trim(pk_csf.fkg_converte(os.txt_compl))
    where os.subapuricms_id = gt_row_subapur_icms.id;
   --
   vn_fase := 5;
   --
   commit;
   --
exception
   when others then
      --
      gv_resumo_log := 'Erro na pkb_limpa_carac_bloco_1900 fase ( '||vn_fase||' ):'||sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico.id%type;
      begin
         --
         pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                    , ev_mensagem       => gv_mensagem_log
                                    , ev_resumo         => gv_resumo_log
                                    , en_tipo_log       => erro_de_sistema
                                    , en_referencia_id  => gn_referencia_id
                                    , ev_obj_referencia => gv_obj_referencia );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_limpa_carac_bloco_1900;
-------------------------------------------------------------------------------------------------------
--| Valida os dados a Sub-Apuração de ICMS
-------------------------------------------------------------------------------------------------------
procedure pkb_processar_dados( est_log_generico in out nocopy dbms_sql.number_table )
is
   --
   vn_fase                      number := 0;
   vn_loggenerico_id            log_generico.id%type;
   vn_vl_tot_transf_debitos_oa  subapur_icms.vl_tot_transf_debitos_oa%type  := 0;
   vn_vl_tot_aj_debitos_oa      subapur_icms.vl_tot_aj_debitos_oa%type      := 0;
   vn_vl_estornos_cred_oa       subapur_icms.vl_estornos_cred_oa%type       := 0;
   vn_vl_tot_transf_creditos_oa subapur_icms.vl_tot_transf_creditos_oa%type := 0;
   vn_vl_tot_aj_creditos_oa     subapur_icms.vl_tot_aj_creditos_oa%type     := 0;
   vn_vl_estornos_deb_oa        subapur_icms.vl_estornos_deb_oa%type        := 0;
   vn_vl_sld_credor_ant_oa      subapur_icms.vl_sld_credor_ant_oa%type      := 0;
   vn_vl_sld_apurado_oa         subapur_icms.vl_sld_apurado_oa%type         := 0;
   vn_vl_tot_ded                subapur_icms.vl_tot_ded%type                := 0;
   vn_vl_icms_recolher_oa       subapur_icms.vl_icms_recolher_oa%type       := 0;
   vn_vl_sld_credor_transp_oa   subapur_icms.vl_sld_credor_transp_oa%type   := 0;
   vn_vl_deb_esp_oa             subapur_icms.vl_deb_esp_oa%type             := 0;
   vn_vl_or                     obrig_rec_subapur_icms.vl_or%type           := 0;
   vn_vl_aj_apur_gia            ajust_subapur_icms_gia.vl_aj_apur%type      := 0;
   --
   cursor c_aj_subapur is
      select ai.id ajustsubapuricms_id
           , ai.codajsaldoapuricms_id
           , nvl(sum(nvl(ai.vl_aj_apur,0)),0) vl_aj_apur
        from ajust_subapur_icms ai
       where ai.subapuricms_id = gt_row_subapur_icms.id
       group by ai.id
           , ai.codajsaldoapuricms_id;
   --
   cursor c_aj_gia( en_ajustsubapuricms_id in ajust_subapur_icms.id%type ) is
      select nvl(sum(nvl(ag.vl_aj_apur,0)),0) vl_aj_apur_gia
        from ajust_subapur_icms_gia ag
       where ag.ajustsubapuricms_id = en_ajustsubapuricms_id;
   --
begin
   --
   vn_fase := 1;
   --
   -- Campo 02-VL_TOT_TRANSF_DEBITOS_OA: Valor total dos débitos por "Saídas e prestações com débito do imposto"
   -- Validação: Os citados registros C197 e D197 devem ser originados em documentos fiscais de saídas que geraram débitos de ICMS de operações próprias.
   -- Ficam excluídos os documentos extemporâneos (COD_SIT = ‘01’) e os documentos complementares extemporâneos (COD_SIT = ‘07’).
   -- Serão considerados os registros cujos documentos estejam compreendidos no período informado no registro 1910 utilizando, para tanto, o campo DT_E_S (C100)
   -- e DT_DOC ou DT_A_P (D100). Quando o campo DT_E_S ou DT_A_P do registro C100 não for informado, utilizar o campo DT_DOC.
   -- campo 02-IND_APUR_ICMS = “3” - somar valores do campo 07-VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “2” e “3”;
   -- campo 02-IND_APUR_ICMS = “4” - somar valores do campo 07-VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “2” e “4”;
   -- campo 02-IND_APUR_ICMS = “5” - somar valores do campo 07-VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “2” e “5”;
   -- campo 02-IND_APUR_ICMS = “6” - somar valores do campo 07-VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “2” e “6”;
   -- campo 02-IND_APUR_ICMS = “7” - somar valores do campo 07-VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “2” e “7”;
   -- campo 02-IND_APUR_ICMS = “8” - somar valores do campo 07-VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “2” e “8”.
   --
   vn_vl_tot_transf_debitos_oa := nvl(fkg_soma_debporsaida_c197_d197,0);
   --
   vn_fase := 2;
   --
   if nvl(gt_row_subapur_icms.vl_tot_transf_debitos_oa,0) <> nvl(vn_vl_tot_transf_debitos_oa,0) then
      --
      vn_fase := 2.1;
      --
      gv_resumo_log := 'O Valor total dos débitos por "Saídas e prestações com débito do imposto" na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_tot_transf_debitos_oa,0),'9999G999G999G990D00'))||') está divergente da "Soma do Valor do '||
                       'ICMS nos Doctos Fiscais referente aos débitos" ('||trim(to_char(nvl(vn_vl_tot_transf_debitos_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 3;
   --
   -- Campo 03-VL_TOT_AJ_DEBITOS_OA: Valor total de "Ajustes a débito"
   -- Validação: o valor informado deve corresponder ao somatório do campo VL_AJ_APUR dos registros 1921,
   -- se o terceiro caractere for igual a ‘0’ e o quarto caractere do campo COD_AJ_APUR do registro 1921 for igual a ‘0’.
   --
   vn_vl_tot_aj_debitos_oa := nvl(fkg_soma_tot_aj_debitos,0);
   --
   vn_fase := 4;
   --
   if nvl(gt_row_subapur_icms.vl_tot_aj_debitos_oa,0) <> nvl(vn_vl_tot_aj_debitos_oa,0) then
      --
      vn_fase := 4.1;
      --
      gv_resumo_log := 'O Valor total de "Ajustes a débito" na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_tot_aj_debitos_oa,0),'9999G999G999G990D00'))||') está divergente da "Soma dos lançamentos '||
                       'de Ajustes a débitos do ICMS" ('||trim(to_char(nvl(vn_vl_tot_aj_debitos_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 5;
   --
   -- Campo 04-VL_ESTORNOS_CRED_OA: Valor total de Ajustes “Estornos de créditos”
   -- Validação: o valor informado deve corresponder ao somatório do campo VL_AJ_APUR dos registros 1921,
   -- se o terceiro caractere for igual a ‘0’ e o quarto caractere do campo COD_AJ_APUR do registro 1921 for igual a ‘1’.
   --
   vn_vl_estornos_cred_oa := nvl(fkg_soma_estornos_cred,0);
   --
   vn_fase := 6;
   --
   if nvl(gt_row_subapur_icms.vl_estornos_cred_oa,0) <> nvl(vn_vl_estornos_cred_oa,0) then
      --
      vn_fase := 6.1;
      --
      gv_resumo_log := 'O Valor total de Ajustes "Estornos de créditos" na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_estornos_cred_oa,0),'9999G999G999G990D00'))||') está divergente da "Soma dos lançamentos de '||
                       'Ajustes a Estornos de Créditos" ('||trim(to_char(nvl(vn_vl_estornos_cred_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 7;
   --
   -- Campo 05-VL_TOT_TRANSF_CREDITOS_OA: Valor total dos créditos por "Entradas e aquisições com crédito do imposto"
   -- Validação: Os citados registros C197 e D197 devem ser originados em documentos fiscais de entradas que geraram créditos de ICMS de operações próprias.
   -- Ficam excluídos os documentos extemporâneos (COD_SIT = ‘01’) e os documentos complementares extemporâneos (COD_SIT = ‘07’).
   -- Serão considerados os registros cujos documentos estejam compreendidos no período informado no registro 1910, utilizando para tanto o campo
   -- DT_E_S (C100) e DT_DOC ou DT_A_P (D100). Quando o campo DT_E_S ou DT_A_P do registro C100 não for informado, utilizar o campo DT_DOC.
   -- campo 02-IND_APUR_ICMS = “3” - somar valores do campo 07- VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “5” e “3”;
   -- campo 02-IND_APUR_ICMS = “4” - somar valores do campo 07- VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “5” e “4”;
   -- campo 02-IND_APUR_ICMS = “5” - somar valores do campo 07- VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “5” e “5”;
   -- campo 02-IND_APUR_ICMS = “6” - somar valores do campo 07- VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “2” e “6”;
   -- campo 02-IND_APUR_ICMS = “7” - somar valores do campo 07- VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “2” e “7”;
   -- campo 02-IND_APUR_ICMS = “8” - somar valores do campo 07- VL_ICMS dos regs C197 e D197 onde o terceiro e quarto caracteres do cód de ajuste sejam “2” e “8”.
   --
   vn_vl_tot_transf_creditos_oa := nvl(fkg_soma_credporentr_c197_d197,0);
   --
   vn_fase := 8;
   --
   if nvl(gt_row_subapur_icms.vl_tot_transf_creditos_oa,0) <> nvl(vn_vl_tot_transf_creditos_oa,0) then
      --
      vn_fase := 8.1;
      --
      gv_resumo_log := 'O Valor total dos créditos por "Entradas e aquisições com crédito do imposto" na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_tot_transf_creditos_oa,0),'9999G999G999G990D00'))||') está divergente da "Soma do Valor de '||
                       'ICMS nos Doctos Fiscais referente ao crédito" ('||trim(to_char(nvl(vn_vl_tot_transf_creditos_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 9;
   --
   -- Campo 06-VL_TOT_AJ_CREDITOS_OA: Valor total de "Ajustes a crédito"
   -- Validação: o valor informado deve corresponder ao somatório dos valores constantes dos registros 1921,
   -- quando o terceiro caractere for igual a ‘0’ e o quarto caractere for igual a ‘2’, do COD_AJ_APUR do registro 1921.
   --
   vn_vl_tot_aj_creditos_oa := nvl(fkg_soma_tot_aj_credito,0);
   --
   vn_fase := 10;
   --
   if nvl(gt_row_subapur_icms.vl_tot_aj_creditos_oa,0) <> nvl(vn_vl_tot_aj_creditos_oa,0) then
      --
      vn_fase := 10.1;
      --
      gv_resumo_log := 'O Valor total de "Ajustes a crédito" na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_tot_aj_creditos_oa,0),'9999G999G999G990D00'))||') está divergente da "Soma dos Lançamentos '||
                       'de Ajuste a Crédito" ('||trim(to_char(nvl(vn_vl_tot_aj_creditos_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 11;
   --
   -- Campo 07-VL_ESTORNOS_DEB_OA: Valor total de Ajustes “Estornos de Débitos”
   -- Validação: o valor informado deve corresponder ao somatório do VL_AJ_APUR dos registros 1921,
   -- quando o terceiro caractere for igual a ‘0’ e o quarto caractere for igual a ‘3’, do COD_AJ_APUR do registro 1921.
   --
   vn_vl_estornos_deb_oa := nvl(fkg_soma_estorno_deb,0);
   --
   vn_fase := 12;
   --
   if nvl(gt_row_subapur_icms.vl_estornos_deb_oa,0) <> nvl(vn_vl_estornos_deb_oa,0) then
      --
      vn_fase := 12.1;
      --
      gv_resumo_log := 'O Valor total de Ajustes "Estornos de Débitos" na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_estornos_deb_oa,0),'9999G999G999G990D00'))||') está divergente da "Soma dos lançamentos de '||
                       'Ajustes Estornos de Débitos" ('||trim(to_char(nvl(vn_vl_estornos_deb_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 13;
   --
   -- Campo 08-VL_SLD_CREDOR_ANT_OA: Valor total de "Saldo credor do período anterior"
   -- Validação: Informar o saldo credor do período anterior da respectiva apuração em separado (sub-apuração).
   --
   vn_vl_sld_credor_ant_oa := nvl(fkg_saldo_credor_ant,0);
   --
   vn_fase := 14;
   --
   if nvl(gt_row_subapur_icms.vl_sld_credor_ant_oa,0) > 0 and
      nvl(vn_vl_sld_credor_ant_oa,0) > 0 and
      nvl(gt_row_subapur_icms.vl_sld_credor_ant_oa,0) <> nvl(vn_vl_sld_credor_ant_oa,0) then
      --
      vn_fase := 14.1;
      --
      gv_resumo_log := 'O Valor total de "Saldo credor do período anterior" na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_sld_credor_ant_oa,0),'9999G999G999G990D00'))||') está divergente da "Cálculo do Valor Credor '||
                       'do Mês Anterior" ('||trim(to_char(nvl(vn_vl_sld_credor_ant_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 15;
   --
   -- Campo 09-VL_SLD_APURADO_OA: Valor do saldo devedor apurado
   -- Validação: o valor informado deve ser preenchido com base na expressão:
   -- soma do total de débitos transferidos (VL_TOT_TRANSF_DEBITOS_OA) com total de ajustes a débito (VL_TOT_AJ_DEBITOS_OA) com total de estorno de crédito
   -- (VL_ESTORNOS_CRED_OA) menos a soma do total de créditos transferidos (VL_TOT_TRANSF_CREDITOS_OA) com total de ajustes a crédito (VL_TOT_AJ_CREDITOS_OA)
   -- com total de estorno de débito (VL_ESTORNOS_DEB_OA) com saldo credor do período anterior (VL_SLD_CREDOR_ANT_OA).
   -- Se o valor da expressão for maior ou igual a “0” (zero), então este valor deve ser informado neste campo e o campo 12 (VL_SLD_CREDOR_TRANSP_OA)
   -- deve ser igual a “0” (zero). Se o valor da expressão for menor que “0” (zero), então este campo deve ser preenchido com “0” (zero) e o valor
   -- absoluto da expressão deve ser informado no campo VL_SLD_CREDOR_TRANSP_OA.
   --
   vn_vl_sld_apurado_oa := ( (nvl(gt_row_subapur_icms.vl_tot_transf_debitos_oa,0) + nvl(gt_row_subapur_icms.vl_tot_aj_debitos_oa,0) +
                              nvl(gt_row_subapur_icms.vl_estornos_cred_oa,0)) -
                             (nvl(gt_row_subapur_icms.vl_tot_transf_creditos_oa,0) + nvl(gt_row_subapur_icms.vl_tot_aj_creditos_oa,0) +
                              nvl(gt_row_subapur_icms.vl_estornos_deb_oa,0) + nvl(gt_row_subapur_icms.vl_sld_credor_ant_oa,0)) );
   --
   vn_fase := 16;
   --
   if nvl(vn_vl_sld_apurado_oa,0) < 0 then
      --
      vn_vl_sld_apurado_oa := 0;
      --
   end if;
   --
   -- O teste de validação do saldo apurado será efetuado no final desta rotina junto com saldo credor a transportar
   --
   vn_fase := 17;
   --
   -- Campo 10-VL_TOT_DED: Valor total de "Deduções"
   -- Validação: o valor informado deve corresponder ao somatório do campo VL_ICMS dos registros C197 e D197, se o terceiro caractere do código de
   -- ajuste dos registros C197 e D197, for “6” e o quarto caractere for “3”, “4” ou “5”, somado ao valor total informado nos registros 1921, quando
   -- o terceiro caractere for igual a ‘0’ e o quarto caractere for igual a ‘4’, do campo COD_AJ_APUR do registro 1921.
   -- Para o somatório do campo VL_ICMS dos registros C197 e D197 devem ser considerados os documentos fiscais compreendidos no período informado no
   -- registro 1910, comparando com a data constante no campo DT_E_S do registro C100 e DT_DOC ou DT_A_P do registro D100, exceto se COD_SIT do registro
   -- C100 for igual a ‘01’ (extemporâneo) ou igual a ‘07’ (Complementar extemporânea), cujo valor deve ser somado no primeiro período de apuração
   -- informado no registro 1910, quando houver mais de um período de apuração. Quando o campo DT_E_S não for informado, utilizar o campo DT_DOC.
   --
   vn_vl_tot_ded := nvl(fkg_soma_tot_ded_c197_d197,0) + nvl(fkg_soma_tot_ded_e111,0);
   --
   vn_fase := 18;
   --
   if nvl(gt_row_subapur_icms.vl_tot_ded,0) <> nvl(vn_vl_tot_ded,0) then
      --
      vn_fase := 18.1;
      --
      gv_resumo_log := 'O Valor total de "Deduções" na Sub-Apuração do ICMS ('||trim(to_char(nvl(gt_row_subapur_icms.vl_tot_ded,0),'9999G999G999G990D00'))||
                       ') está divergente da "Soma das Deduções" no período ('||trim(to_char(nvl(vn_vl_tot_ded,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 19;
   --
   -- Campo 12-VL_SLD_CREDOR_TRANSP_OA: Valor total de "Saldo credor a transportar para o período seguinte”
   -- Validação: se o valor da expressão: “soma do total de débitos (VL_TOT_TRANSF_DEBITOS_OA) mais total de ajustes a débito (VL_AJ_DEBITOS_OA) mais
   -- total de estorno de crédito (VL_ESTORNOS_CRED_OA)” menos “a soma do total de créditos transferidos (VL_TOT_TRANSF_CREDITOS_OA) mais total de ajuste a
   -- crédito (VL_AJ_CREDITOS_OA) mais total de estorno de débito (VL_ESTORNOS_DEB_OA) mais saldo credor do período anterior (VL_SLD_CREDOR_ANT_OA)”, for maior
   -- que ZERO, este campo deve ser preenchido com “0” (zero) e o campo 11 (VL_SLD_APURADO) deve ser igual ao valor do resultado. Se for menor que “0” (zero),
   -- o valor absoluto do resultado deve ser informado neste campo e o campo VL_SLD_APURADO deve ser informado com “0” (zero).
   --
   vn_vl_sld_credor_transp_oa := ((nvl(vn_vl_tot_transf_debitos_oa,0) + nvl(vn_vl_tot_aj_debitos_oa,0) + nvl(vn_vl_estornos_cred_oa,0)) -
                                  (nvl(vn_vl_tot_transf_creditos_oa,0) + nvl(vn_vl_tot_aj_creditos_oa,0) + nvl(vn_vl_estornos_deb_oa,0) +
                                   nvl(vn_vl_sld_credor_ant_oa,0)));
   --
   vn_fase := 20;
   --
   if nvl(vn_vl_sld_credor_transp_oa,0) > 0 then
      --
      vn_vl_sld_apurado_oa       := nvl(vn_vl_sld_credor_transp_oa,0);
      vn_vl_sld_credor_transp_oa := 0;
      --
   elsif nvl(vn_vl_sld_credor_transp_oa,0) < 0 then
         --
         vn_vl_sld_credor_transp_oa := (nvl(vn_vl_sld_credor_transp_oa,0) * (-1));
         vn_vl_sld_apurado_oa       := 0;
         --
   end if;
   --
   vn_fase := 21;
   --
   if nvl(gt_row_subapur_icms.vl_sld_apurado_oa,0) <> nvl(vn_vl_sld_apurado_oa,0) then
      --
      vn_fase := 21.1;
      --
      gv_resumo_log := 'O Valor do saldo devedor apurado na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_sld_apurado_oa,0),'9999G999G999G990D00'))||') está divergente da "Cálculo do Saldo Apurado" ('||
                       trim(to_char(nvl(vn_vl_sld_apurado_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 22;
   --
   if nvl(gt_row_subapur_icms.vl_sld_credor_transp_oa,0) <> nvl(vn_vl_sld_credor_transp_oa,0) then
      --
      vn_fase := 22.1;
      --
      gv_resumo_log := 'O Valor total de "Saldo credor a transportar para o período seguinte" na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_sld_credor_transp_oa,0),'9999G999G999G990D00'))||') está divergente do "Cálculo do Saldo '||
                       'Credor" no período ('||trim(to_char(nvl(vn_vl_sld_credor_transp_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 23;
   --
   -- Campo 11-VL_ICMS_RECOLHER_OA: Valor total de "ICMS a recolher (09-10)
   -- Validação: o valor informado deve corresponder à diferença entre o campo VL_SLD_APURADO_OA e o campo VL_TOT_DED. O valor da soma deste campo
   -- com o campo DEB_ESP_OA deve ser igual à soma dos valores do campo VL_OR do registro 1926.
   --
   vn_vl_icms_recolher_oa := nvl(vn_vl_sld_apurado_oa,0) - nvl(vn_vl_tot_ded,0);
   --
   vn_fase := 24;
   --
   if nvl(vn_vl_icms_recolher_oa,0) < 0 then
      --
      vn_vl_icms_recolher_oa := 0;
      --
   end if;
   --
   vn_fase := 25;
   --
   if nvl(gt_row_subapur_icms.vl_icms_recolher_oa,0) <> nvl(vn_vl_icms_recolher_oa,0) then
      --
      vn_fase := 25.1;
      --
      gv_resumo_log := 'O Valor total de "ICMS a recolher" na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_icms_recolher_oa,0),'9999G999G999G990D00'))||') está divergente do "Cálculo do ICMS a '||
                       'Recolher" no período ('||trim(to_char(nvl(vn_vl_icms_recolher_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 26;
   --
   -- Campo 13-DEB_ESP_OA: Valores recolhidos ou a recolher, extraapuração
   -- Preenchimento: Informar o correspondente ao somatório dos valores:
   -- a) de ICMS correspondentes aos doctos fiscais extemporâneos (COD_SIT = “01”) e dos doctos fiscais complementares extemporâneos (COD_SIT = “07”),
   -- referentes às apurações em separado;
   -- b) de ajustes do campo VL_ICMS dos registros C197 e D197, se o terceiro caractere do código informado no campo COD_AJ dos registros C197 e D197
   -- for igual a “7” (débitos especiais) e o quarto caractere for igual a “3”, “4” ou “5” (“Apuração 1 – Bloco 1900” ou “Apuração 2 – Bloco 1900” ou
   -- “Apuração 3 – Bloco 1900”) referente aos documentos compreendidos no período a que se refere a escrituração; e
   -- c) de ajustes do campo VL_AJ_APUR do registro 1921, se o terceiro caractere do código informado no campo COD_AJ_APUR do registro 1921 for igual
   -- a “0” (apuração ICMS próprio) e o quarto caractere for igual a “5”(débito especial).
   --
   vn_vl_deb_esp_oa := (nvl(fkg_soma_cred_ext_op_c,0) + nvl(fkg_soma_cred_ext_op_d,0) + nvl(fkg_soma_dep_esp_c197_d197,0) + nvl(fkg_soma_dep_esp_e111,0));
   --
   vn_fase := 27;
   --
   if nvl(gt_row_subapur_icms.vl_deb_esp_oa,0) <> nvl(vn_vl_deb_esp_oa,0) then
      --
      vn_fase := 27.1;
      --
      gv_resumo_log := 'Os Valores recolhidos ou a recolher - extraapuração na Sub-Apuração do ICMS ('||
                       trim(to_char(nvl(gt_row_subapur_icms.vl_deb_esp_oa,0),'9999G999G999G990D00'))||') está divergente do "Cálculo dos Valores Recolhidos '||
                       'ou a recolher, extra-apuração" no período ('||trim(to_char(nvl(vn_vl_deb_esp_oa,0),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 28;
   -- Busca o valor da obrigação a recolher
   Begin
      select nvl(sum(nvl(os.vl_or,0)),0)
        into vn_vl_or
        from obrig_rec_subapur_icms os
       where os.subapuricms_id = gt_row_subapur_icms.id;
   exception
      when others then
         vn_vl_or := 0;
   end;
   --
   vn_fase := 29;
   -- Validação: O valor da soma do campo DEB_ESP_OA com o campo VL_ICMS_RECOLHER_OA deve ser igual à soma dos valores do campo VL_OR do registro 1926.
   if (nvl(gt_row_subapur_icms.vl_icms_recolher_oa,0) + nvl(gt_row_subapur_icms.vl_deb_esp_oa,0)) <> nvl(vn_vl_or,0) then
      --
      vn_fase := 29.1;
      --
      gv_resumo_log := 'O "Valor da Obrigação a recolher" em Obrigações de ICMS a Recolher ('||trim(to_char(nvl(vn_vl_or,0),'9999G999G999G990D00'))||
                       ') está divergente do "Cálculo do Valor da Obrigação a recolher" na Apuração de ICMS ('||
                       trim(to_char((nvl(gt_row_subapur_icms.vl_icms_recolher_oa,0) + nvl(gt_row_subapur_icms.vl_deb_esp_oa,0)),'9999G999G999G990D00'))||').';
      --
      vn_loggenerico_id := null;
      --
      pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                 , ev_mensagem       => gv_mensagem_log
                                 , ev_resumo         => gv_resumo_log
                                 , en_tipo_log       => erro_de_validacao
                                 , en_referencia_id  => gn_referencia_id
                                 , ev_obj_referencia => gv_obj_referencia );
      --
      -- Armazena o "loggenerico_id" na memória
      pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                    , est_log_generico => est_log_generico );
      --
   end if;
   --
   vn_fase := 30;
   -- Caso exista registro na tabela "AJUST_SUBAPUR_ICMS_GIA", a soma dos valores deve ser igual ao campo VL_AJ_APUR da tabela AJUST_SUBAPUR_ICMS
   for r_aj_subapur in c_aj_subapur
   loop
      --
      exit when c_aj_subapur%notfound or (c_aj_subapur%notfound) is null;
      --
      vn_fase := 30.1;
      --
      open c_aj_gia(en_ajustsubapuricms_id => r_aj_subapur.ajustsubapuricms_id);
      fetch c_aj_gia into vn_vl_aj_apur_gia;
      close c_aj_gia;
      --
      vn_fase := 30.2;
      --
      if nvl(vn_vl_aj_apur_gia,0) > 0 and
         nvl(r_aj_subapur.vl_aj_apur,0) <> nvl(vn_vl_aj_apur_gia,0) then
         --
         vn_fase := 30.3;
         --
         gv_resumo_log := 'Código de Ajuste da SubApuração = '||pk_csf_efd.fkg_cod_codajsaldoapuricms(r_aj_subapur.codajsaldoapuricms_id)||'. O Valor de '||
                          'ajuste ('||trim(to_char(nvl(r_aj_subapur.vl_aj_apur,0),'9999G999G999G990D00'))||'), está diferente do Valor de ajuste referente '||
                          'a GIA ('||trim(to_char(nvl(vn_vl_aj_apur_gia,0),'9999G999G999G990D00'))||').';
         --
         vn_loggenerico_id := null;
         --
         pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                    , ev_mensagem       => gv_mensagem_log
                                    , ev_resumo         => gv_resumo_log
                                    , en_tipo_log       => erro_de_validacao
                                    , en_referencia_id  => gn_referencia_id
                                    , ev_obj_referencia => gv_obj_referencia );
         --
         -- Armazena o "loggenerico_id" na memória
         pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                       , est_log_generico => est_log_generico );
         --
      end if;
      --
   end loop;
   --
exception
   when others then
      --
      gv_resumo_log := 'Erro na pk_subapur_icms.pkb_processar_dados fase ('||vn_fase||'): '||sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico.id%type;
      begin
         --
         pk_log_generico.pkb_log_generico( sn_loggenerico_id => vn_loggenerico_id
                                    , ev_mensagem       => gv_mensagem_log
                                    , ev_resumo         => gv_resumo_log
                                    , en_tipo_log       => erro_de_sistema
                                    , en_referencia_id  => gn_referencia_id
                                    , ev_obj_referencia => gv_obj_referencia );
         --
         -- Armazena o "loggenerico_id" na memória
         pk_log_generico.pkb_gt_log_generico( en_loggenerico   => vn_loggenerico_id
                                       , est_log_generico => est_log_generico );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_processar_dados;
-------------------------------------------------------------------------------------------------------
--| Procedimento para processar/validar as informações da Sub-Apuração de ICMS
-------------------------------------------------------------------------------------------------------
procedure pkb_processar( en_subapuricms_id in subapur_icms.id%type )
is
   --
   vn_fase            number := 0;
   vt_log_generico    dbms_sql.number_table;
   vn_loggenerico_id  log_generico.id%type;
   --
begin
   --
   vn_fase := 1;
   -- recupera os dados da apuração de imposto
   pkb_dados_subapur_icms( en_subapuricms_id => en_subapuricms_id );
   --
   vn_fase := 2;
   --
   if nvl(gt_row_subapur_icms.id,0) > 0 then
      --
      vn_fase := 3;
      -- Limpar os logs
      delete log_generico lg
      where lg.obj_referencia = gv_obj_referencia
        and lg.referencia_id  = gt_row_subapur_icms.id;
      --
      vn_fase := 4;
      --
      commit;
      --
      vn_fase := 5;
      --
      if nvl(gt_row_subapur_icms.dm_situacao,0) = 1 then -- 0-Em aberto; 1-Calculada; 2-Erro de Calculo; 2-Processada; 4-Erro de validação
         --
         vn_fase := 6;
         -- Inicia processo de validação da sub-apuração do ICMS
         pkb_processar_dados( est_log_generico => vt_log_generico );
         --
         vn_fase := 7;
         --
         if nvl(vt_log_generico.count,0) <= 0 then
            --
            vn_fase := 8;
            -- Como não há erros de validação limpar os caracteres numa única vez.
            pkb_limpa_carac_bloco_1900;
            --
            vn_fase := 9;
            --  Atualiza status para 3-processada
            update subapur_icms si
               set si.dm_situacao = 3
             where si.id = gt_row_subapur_icms.id;
            --
            gv_resumo_log := 'Sub-Apuração de ICMS processada/validada com sucesso!';
            --
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                        , ev_mensagem       => gv_mensagem_log
                                        , ev_resumo         => gv_resumo_log
                                        , en_tipo_log       => info_subapur_icms
                                        , en_referencia_id  => gn_referencia_id
                                        , ev_obj_referencia => gv_obj_referencia );
            --
         else
            --
            vn_fase := 10;
            --  Atualiza status para 4-Erro de validação
            update subapur_icms si
               set si.dm_situacao = 4
             where si.id = gt_row_subapur_icms.id;
            --
            gv_resumo_log := 'Processo/Validação da Sub-Apuração de ICMS possui erros! Verifique.';
            --
            pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                        , ev_mensagem       => gv_mensagem_log
                                        , ev_resumo         => gv_resumo_log
                                        , en_tipo_log       => erro_de_validacao
                                        , en_referencia_id  => gn_referencia_id
                                        , ev_obj_referencia => gv_obj_referencia );
            --
         end if;
         --
      else
         --
         vn_fase := 11;
         --
         gv_resumo_log := 'Sub-Apuração de ICMS não está com situação = 1-Calculada, portanto o processo de validação não será efetuado. Verifique.';
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                     , ev_mensagem       => gv_mensagem_log
                                     , ev_resumo         => gv_resumo_log
                                     , en_tipo_log       => info_subapur_icms
                                     , en_referencia_id  => gn_referencia_id
                                     , ev_obj_referencia => gv_obj_referencia );
         --
      end if;
      --
      vn_fase := 12;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro em pk_subapur_icms.pkb_processar fase ( '||vn_fase||' ):'||sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico.id%type;
      begin
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                     , ev_mensagem       => gv_mensagem_log
                                     , ev_resumo         => null
                                     , en_tipo_log       => erro_de_sistema
                                     , en_referencia_id  => null
                                     , ev_obj_referencia => gv_obj_referencia );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_processar;
-------------------------------------------------------------------------------------------------------
--| Procedimento para desfazer a situação da Sub-Apuração de ICMS
-------------------------------------------------------------------------------------------------------
procedure pkb_desfazer( en_subapuricms_id in subapur_icms.id%type )
is
   --
   vn_fase               number := 0;
   vt_log_generico       dbms_sql.number_table;
   vv_descr_dm_situacao  dominio.dominio%type;
   vn_loggenerico_id     log_generico.id%type;
   --
begin
   --
   vn_fase := 1;
   -- recupera os dados da sub-apuração do icms
   pkb_dados_subapur_icms ( en_subapuricms_id => en_subapuricms_id );
   --
   vn_fase := 2;
   --
   if nvl(gt_row_subapur_icms.id,0) > 0 then
      --
      vn_fase := 3;
      -- Limpar os logs
      delete log_generico lg
      where lg.obj_referencia = 'SUBAPUR_ICMS'
        and lg.referencia_id  = gt_row_subapur_icms.id;
      --
      vn_fase := 4;
      -- Se o DM_SITUACAO = 3-Processada ou 4-Erro de Validação, alterar para 1-Calculado
      if gt_row_subapur_icms.dm_situacao in (3, 4) then
         --
         vn_fase := 5;
         --
         update subapur_icms si
            set si.dm_situacao = 1
          where si.id = gt_row_subapur_icms.id;
         --
         vn_fase := 6;
         --
         vv_descr_dm_situacao := pk_csf.fkg_dominio( ev_dominio => 'SUBAPUR_ICMS.DM_SITUACAO'
                                                   , ev_vl      => 1 );
         --
      elsif gt_row_subapur_icms.dm_situacao in (1, 2) then
            -- Se o DM_SITUACAO = 1-Calculado ou 2-Erro no Cálculo, alterar para 0-Aberto
            vn_fase := 7;
            --
            update subapur_icms si
               set si.dm_situacao               = 0
                 , si.vl_tot_transf_debitos_oa  = 0
                 , si.vl_tot_aj_debitos_oa      = 0
                 , si.vl_estornos_cred_oa       = 0
                 , si.vl_tot_transf_creditos_oa = 0
                 , si.vl_tot_aj_creditos_oa     = 0
                 , si.vl_estornos_deb_oa        = 0
                 , si.vl_sld_credor_ant_oa      = 0
                 , si.vl_sld_apurado_oa         = 0
                 , si.vl_tot_ded                = 0
                 , si.vl_icms_recolher_oa       = 0
                 , si.vl_sld_credor_transp_oa   = 0
                 , si.vl_deb_esp_oa             = 0
             where si.id = gt_row_subapur_icms.id;
            --
            vn_fase := 8;
            --
            vv_descr_dm_situacao := pk_csf.fkg_dominio( ev_dominio => 'SUBAPUR_ICMS.DM_SITUACAO'
                                                      , ev_vl      => 0 );
            --
            pkb_limpa_c190_d190_1920;            
            --
      end if;
      --
      vn_fase := 9;
      --
      commit;
      --
      vn_fase := 10;
      --
      gv_resumo_log := 'Desfeito a situação de "'||pk_csf.fkg_dominio(ev_dominio => 'SUBAPUR_ICMS.DM_SITUACAO', ev_vl => gt_row_subapur_icms.dm_situacao)||
                       '" para a situação "'||vv_descr_dm_situacao||'"';
      --
      pk_log_generico.pkb_log_generico ( sn_loggenerico_id  => vn_loggenerico_id
                                  , ev_mensagem        => gv_mensagem_log
                                  , ev_resumo          => gv_resumo_log
                                  , en_tipo_log        => info_subapur_icms
                                  , en_referencia_id   => gn_referencia_id
                                  , ev_obj_referencia  => gv_obj_referencia );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro em pk_subapur_icms.pkb_desfazer fase ( '||vn_fase||' ):'||sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico.id%type;
      begin
         --
         pk_log_generico.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                     , ev_mensagem       => gv_mensagem_log
                                     , ev_resumo         => null
                                     , en_tipo_log       => erro_de_sistema
                                     , en_referencia_id  => null
                                     , ev_obj_referencia => gv_obj_referencia );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_desfazer;

-------------------------------------------------------------------------------------------------------

end pk_subapur_icms;
/
