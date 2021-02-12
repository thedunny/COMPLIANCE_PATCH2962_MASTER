create or replace package body csf_own.pk_valida_ambiente_ct is

-------------------------------------------------------------------------------------------------------
-- Corpo do pacote da API para ler os Conhecimentos de Transportes com DM_ST_PROC = 0 (Não validada)
-- e chamar os procedimentos para validar os dados
-- E Conhecimento de Transporte Legado
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações relativas aos Impostos de complemento                               

procedure pkb_ler_Ctcompltado_Imp ( est_log_generico             in out nocopy  dbms_sql.number_table
                                  , en_conhectranspcompltado_id  in             Conhec_Transp_Compltado.id%TYPE
                                  , en_conhectransp_id           in             Conhec_Transp.id%TYPE )
is

   cursor c_Ctcompltado_Imp is
   select ad.*
        , ti.cd      cd
        , cs.cod_st  cod_st
     from Ctcompltado_Imp  ad
        , Tipo_imposto     ti
        , Cod_st           cs
    where ad.conhectranspcompltado_id = en_conhectranspcompltado_id
      and ad.tipoimp_id = ti.id
      and ad.codst_id   = cs.id
      and cs.tipoimp_id = ti.id
      order by ad.id;

   vn_fase  number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctcompltado_Imp loop
      exit when c_Ctcompltado_Imp%notfound or c_Ctcompltado_Imp%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctcompltado_imp := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctcompltado_imp.id                       := rec.id;
      pk_csf_api_ct.gt_row_ctcompltado_imp.conhectranspcompltado_id := rec.conhectranspcompltado_id;
      pk_csf_api_ct.gt_row_ctcompltado_imp.tipoimp_id               := rec.tipoimp_id;
      pk_csf_api_ct.gt_row_ctcompltado_imp.codst_id                 := rec.codst_id;
      pk_csf_api_ct.gt_row_ctcompltado_imp.vl_base_calc             := rec.vl_base_calc;
      pk_csf_api_ct.gt_row_ctcompltado_imp.aliq_apli                := rec.aliq_apli;
      pk_csf_api_ct.gt_row_ctcompltado_imp.vl_imp_trib              := rec.vl_imp_trib;
      pk_csf_api_ct.gt_row_ctcompltado_imp.perc_reduc               := rec.perc_reduc;
      pk_csf_api_ct.gt_row_ctcompltado_imp.vl_cred                  := rec.vl_cred;
      pk_csf_api_ct.gt_row_ctcompltado_imp.dm_inf_imp               := nvl(rec.dm_inf_imp,0);
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações relativas aos Impostos de complemento
      pk_csf_api_ct.pkb_integr_ctcompltado_imp( est_log_generico   => est_log_generico
                                              , est_row_imp_comct  => pk_csf_api_ct.gt_row_ctcompltado_imp
                                              , en_conhectransp_id => en_conhectransp_id
                                              , en_cd_imp => rec.cd
                                              , ev_cod_st => rec.cod_st);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctcompltado_Imp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctcompltado_Imp;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Impressoras do CTe

procedure pkb_ler_Conhec_Transp_Impr ( est_log_generico    in out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id  in             Conhec_Transp.id%TYPE
                                     )
is

   cursor c_Conhec_Transp_Impr is
   select ad.*
     from Conhec_Transp_Impr  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Impr loop
      exit when c_Conhec_Transp_Impr%notfound or c_Conhec_Transp_Impr%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_impr := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_impr.id                 := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_impr.conhectransp_id    := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_impr.DM_TIPO_IMPR       := rec.DM_TIPO_IMPR;
      pk_csf_api_ct.gt_row_conhec_transp_impr.DESCR_IMPR         := rec.DESCR_IMPR;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações
      pk_csf_api_ct.pkb_integr_conhec_transp_impr ( est_log_generico   => est_log_generico
                                                  , est_row_ct_impr    => pk_csf_api_ct.gt_row_conhec_transp_impr
                                                  );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Impr fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Impr;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Detalhamento do CT-e do tipo Anulação de Valores

procedure pkb_ler_Conhec_Transp_Anul ( est_log_generico    in out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id  in             Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Anul is
   select ad.*
     from Conhec_Transp_Anul  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Anul loop
      exit when c_Conhec_Transp_Anul%notfound or c_Conhec_Transp_Anul%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_anul := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_anul.id                 := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_anul.conhectransp_id    := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_anul.nro_chave_cte_anul := rec.nro_chave_cte_anul;
      pk_csf_api_ct.gt_row_conhec_transp_anul.dt_emissao         := rec.dt_emissao;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações relativas aos Impostos de complemento
     pk_csf_api_ct.pkb_integr_conhec_transp_anul( est_log_generico   => est_log_generico
                                                , est_row_ct_anul    => pk_csf_api_ct.gt_row_conhec_transp_anul
                                                , en_conhectransp_id => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Anul fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Anul;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura dos Componentes do Valor da Prestação de complemento

procedure pkb_ler_Ctcompltado_Comp ( est_log_generico             in out nocopy  dbms_sql.number_table
                                   , en_conhectranspcompltado_id  in             Conhec_Transp_Compltado.id%TYPE
                                   , en_conhectransp_id           in             Conhec_Transp.id%TYPE)
is

   cursor c_Ctcompltado_Comp is
   select ad.*
     from Ctcompltado_Comp  ad
    where ad.conhectranspcompltado_id = en_conhectranspcompltado_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctcompltado_Comp loop
      exit when c_Ctcompltado_Comp%notfound or c_Ctcompltado_Comp%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctcompltado_comp := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctcompltado_comp.id                       := rec.id;
      pk_csf_api_ct.gt_row_ctcompltado_comp.conhectranspcompltado_id := rec.conhectranspcompltado_id;
      pk_csf_api_ct.gt_row_ctcompltado_comp.nome                     := rec.nome;
      pk_csf_api_ct.gt_row_ctcompltado_comp.valor                    := rec.valor;
      --
      vn_fase := 4;
      -- Chama procedimento que valida os Componentes do Valor da Prestação de complemento
      pk_csf_api_ct.pkb_integr_ctcompltado_comp( est_log_generico   => est_log_generico
                                               , est_row_comp_ct    => pk_csf_api_ct.gt_row_ctcompltado_comp
                                               , en_conhectransp_id => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctcompltado_Comp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctcompltado_Comp;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura do Detalhamento do CT-e complementado

procedure pkb_ler_Ct_Compltado ( est_log_generico      in out nocopy  dbms_sql.number_table
                               , en_conhectransp_id    in             Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Compltado is
   select ad.*
     from conhec_transp_compltado  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Compltado loop
      exit when c_Ct_Compltado%notfound or c_Ct_Compltado%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_compltado := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_compltado.id                 := rec.id;      
      pk_csf_api_ct.gt_row_conhec_transp_compltado.conhectransp_id    := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_compltado.nro_chave_cte_comp := rec.nro_chave_cte_comp;
      pk_csf_api_ct.gt_row_conhec_transp_compltado.vl_total_prest     := rec.vl_total_prest;
      pk_csf_api_ct.gt_row_conhec_transp_compltado.inf_ad_fiscal      := rec.inf_ad_fiscal;
      --
      vn_fase := 4;
      -- Chama procedimento que valida o Detalhamento do CT-e complementado
      pk_csf_api_ct.pkb_integr_ct_compltado( est_log_generico     => est_log_generico
                                           , est_row_ct_compltado => pk_csf_api_ct.gt_row_conhec_transp_compltado
                                           , en_conhectransp_id   => en_conhectransp_id);
      --
      vn_fase := 5;
      -- Lê as Informações relativas aos Impostos de complemento
      pkb_ler_Ctcompltado_Imp ( est_log_generico             => est_log_generico
                              , en_conhectranspcompltado_id  => rec.id
                              , en_conhectransp_id           => en_conhectransp_id );
      --
      vn_fase := 6;
      --
      pkb_ler_Ctcompltado_Comp ( est_log_generico            => est_log_generico
                               , en_conhectranspcompltado_id => rec.id
                               , en_conhectransp_id          => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Compltado fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Compltado;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do CT-e de substituição

procedure pkb_ler_Conhec_Transp_Subst ( est_log_generico      in out nocopy  dbms_sql.number_table
                                      , en_conhectransp_id    in             Conhec_Transp.id%TYPE)
is
   --
   cursor c_Conhec_Transp_Subst is
   select ad.*
     from conhec_transp_subst  ad
    where ad.conhectransp_id = en_conhectransp_id;
   --
   vn_fase               number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Subst loop
      exit when c_Conhec_Transp_Subst%notfound or c_Conhec_Transp_Subst%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_subst := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_subst.id                 := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_subst.conhectransp_id    := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_subst.nro_chave_cte_sub  := rec.nro_chave_cte_sub;
      pk_csf_api_ct.gt_row_conhec_transp_subst.nro_chave_nfe_tom  := rec.nro_chave_nfe_tom;
      pk_csf_api_ct.gt_row_conhec_transp_subst.cnpj               := rec.cnpj;
      pk_csf_api_ct.gt_row_conhec_transp_subst.cod_mod            := rec.cod_mod;
      pk_csf_api_ct.gt_row_conhec_transp_subst.serie              := rec.serie;
      pk_csf_api_ct.gt_row_conhec_transp_subst.subserie           := rec.subserie;
      pk_csf_api_ct.gt_row_conhec_transp_subst.nro                := rec.nro;
      pk_csf_api_ct.gt_row_conhec_transp_subst.vl_doc_fiscal      := rec.vl_doc_fiscal;
      pk_csf_api_ct.gt_row_conhec_transp_subst.dt_emissao         := rec.dt_emissao;
      pk_csf_api_ct.gt_row_conhec_transp_subst.nro_chave_cte_tom  := rec.nro_chave_cte_tom;
      pk_csf_api_ct.gt_row_conhec_transp_subst.nro_chave_cte_anul := rec.nro_chave_cte_anul;
      pk_csf_api_ct.gt_row_conhec_transp_subst.dm_ind_alt_toma    := rec.dm_ind_alt_toma;  --Atualização CTe 3.0
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do CT-e de substituição
      pk_csf_api_ct.pkb_integr_conhec_transp_subst( est_log_generico   => est_log_generico
                                                  , est_row_ct_subst   => pk_csf_api_ct.gt_row_conhec_transp_subst
                                                  , en_conhectransp_id => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Subst fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Subst;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das informações dos veículos transportados

procedure pkb_ler_Conhec_Transp_Veic ( est_log_generico      in out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id    in             Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Veic is
   select ad.*
     from Conhec_Transp_Veic  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Veic loop
      exit when c_Conhec_Transp_Veic%notfound or c_Conhec_Transp_Veic%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_veic := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_veic.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_veic.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_veic.chassi          := rec.chassi;
      pk_csf_api_ct.gt_row_conhec_transp_veic.cod_cod         := rec.cod_cod;
      pk_csf_api_ct.gt_row_conhec_transp_veic.descr_cor       := rec.descr_cor;
      pk_csf_api_ct.gt_row_conhec_transp_veic.cod_modelo      := rec.cod_modelo;
      pk_csf_api_ct.gt_row_conhec_transp_veic.vl_unit         := rec.vl_unit;
      pk_csf_api_ct.gt_row_conhec_transp_veic.vl_frete        := rec.vl_frete;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as informações dos veículos transportados
      pk_csf_api_ct.pkb_integr_conhec_transp_veic( est_log_generico   => est_log_generico
                                                 , est_row_ct_veic    => pk_csf_api_ct.gt_row_conhec_transp_veic
                                                 , en_conhectransp_id => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Veic fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Veic;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das transporte de produtos classificados pela ONU como perigosos. Não deve ser preenchido para modais aéreo e dutoviário

procedure pkb_ler_Conhec_Transp_Peri ( est_log_generico      in out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id    in             Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Peri is
   select ad.*
     from Conhec_Transp_Peri  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Peri loop
      exit when c_Conhec_Transp_Peri%notfound or c_Conhec_Transp_Peri%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_peri := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_peri.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_peri.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_peri.nro_onu         := rec.nro_onu;
      pk_csf_api_ct.gt_row_conhec_transp_peri.nome_aprop      := rec.nome_aprop;
      pk_csf_api_ct.gt_row_conhec_transp_peri.classe_risco    := rec.classe_risco;
      pk_csf_api_ct.gt_row_conhec_transp_peri.grupo_emb       := rec.grupo_emb;
      pk_csf_api_ct.gt_row_conhec_transp_peri.qtde_total_prod := rec.qtde_total_prod;
      pk_csf_api_ct.gt_row_conhec_transp_peri.qtde_vol_tipo   := rec.qtde_vol_tipo;
      pk_csf_api_ct.gt_row_conhec_transp_peri.ponto_fulgor    := rec.ponto_fulgor;
      --
      vn_fase := 4;
      -- Chama procedimento que valida das transporte de produtos classificados pela ONU como perigosos. Não deve ser preenchido para modais aéreo e dutoviário
      pk_csf_api_ct.pkb_integr_conhec_transp_peri( est_log_generico   => est_log_generico
                                                 , est_row_ct_peri    => pk_csf_api_ct.gt_row_conhec_transp_peri
                                                 , en_conhectransp_id => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Peri fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Peri;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do modal Dutoviário

procedure pkb_ler_Conhec_Transp_Duto ( est_log_generico      in out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id    in             Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Duto is
   select ad.*
     from conhec_transp_duto  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Duto loop
      exit when c_Conhec_Transp_Duto%notfound or c_Conhec_Transp_Duto%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_duto := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_duto.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_duto.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_duto.vl_tarifa       := rec.vl_tarifa;
      pk_csf_api_ct.gt_row_conhec_transp_duto.dt_ini          := rec.dt_ini;
      pk_csf_api_ct.gt_row_conhec_transp_duto.dt_fin          := rec.dt_fin;
      --
      vn_fase := 4;
      -- Chama procedimento que valida das Informações do modal Dutoviário
      pk_csf_api_ct.pkb_integr_conhec_transp_duto( est_log_generico   => est_log_generico
                                                 , est_row_ct_duto    => pk_csf_api_ct.gt_row_conhec_transp_duto
                                                 , en_conhectransp_id => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Duto fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Duto;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das informações dos containeres contidos no vagão com DCL;

procedure pkb_ler_Ctferrovdcldetvag_Cont ( est_log_generico        in     out nocopy  dbms_sql.number_table
                                         , en_ctferrovdcldetvag_id in     Ctferrovdcl_Detvag.id%TYPE
                                         , en_conhectransp_id      in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctferrovdcldetvag_Cont is
   select ad.*
     from Ctferrovdcldetvag_Cont  ad
    where ad.ctferrovdcldetvag_id = en_ctferrovdcldetvag_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctferrovdcldetvag_Cont loop
      exit when c_Ctferrovdcldetvag_Cont%notfound or c_Ctferrovdcldetvag_Cont%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_cont := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_cont.id                   := rec.id;
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_cont.ctferrovdcldetvag_id := rec.ctferrovdcldetvag_id;
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_cont.nro_cont             := rec.nro_cont;
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_cont.dt_prev              := rec.dt_prev;
      --
      vn_fase := 4;
      -- Chama procedimento que valida das informações dos containeres contidos no vagão com DCL
      pk_csf_api_ct.pkb_integr_ctferr_cont( est_log_generico    => est_log_generico
                                          , est_row_ctferr_cont => pk_csf_api_ct.gt_row_ctferrovdcldetvag_cont
                                          , en_conhectransp_id  => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ctferrovdcldetvag_cont fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ctferrovdcldetvag_cont;
                    
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das informações de conteiners dos vagões.

procedure pkb_ler_Ct_Ferrov_Detvag_Cont ( est_log_generico        in     out nocopy  dbms_sql.number_table
                                        , en_ctferrovdcldetvag_id in     Ctferrovdcl_Detvag.id%TYPE
                                        , en_conhectransp_id      in     Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Ferrov_Detvag_Cont is
   select ad.*
     from Ct_Ferrov_Detvag_Cont  ad
    where ad.ctferrovdetvag_id = en_ctferrovdcldetvag_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Ferrov_Detvag_Cont loop
      exit when c_Ct_Ferrov_Detvag_Cont%notfound or c_Ct_Ferrov_Detvag_Cont%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_cont := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_cont.id                   := rec.id;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_cont.ctferrovdetvag_id    := rec.ctferrovdetvag_id;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_cont.nro_cont             := rec.nro_cont;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_cont.dt_prev              := rec.dt_prev;
      --
      vn_fase := 4;
      -- Chama procedimento que valida das informações dos containeres contidos no vagão.
      pk_csf_api_ct.pkb_integr_ct_fer_detvag_cont( est_log_generico    => est_log_generico
                                                 , est_row_ct_ferrov_detvag_cont => pk_csf_api_ct.gt_row_ct_ferrov_detvag_cont
                                                 , en_conhectransp_id  => en_conhectransp_id);  
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Ferrov_Detvag_Cont fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Ferrov_Detvag_Cont;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura dos Lacres dos vagões do DCL

procedure pkb_ler_ctferr_lacre ( est_log_generico        in     out nocopy  dbms_sql.number_table
                               , en_ctferrovdcldetvag_id in     Ctferrovdcl_Detvag.id%TYPE
                               , en_conhectransp_id      in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctferrovdcldetvag_Lacre is
   select ad.*
     from Ctferrovdcldetvag_Lacre  ad
    where ad.ctferrovdcldetvag_id = en_ctferrovdcldetvag_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctferrovdcldetvag_Lacre loop
      exit when c_Ctferrovdcldetvag_Lacre%notfound or c_Ctferrovdcldetvag_Lacre%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_lacre.id                   := rec.id;
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_lacre.ctferrovdcldetvag_id := rec.ctferrovdcldetvag_id;
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_lacre.nro_lacre            := rec.nro_lacre;
      --
      vn_fase := 4;
      -- Chama procedimento que valida das informações dos containeres contidos no vagão com DCL
      pk_csf_api_ct.pkb_integr_ct_fer_detvag_cont( est_log_generico    => est_log_generico
                                                 , est_row_ct_ferrov_detvag_cont => pk_csf_api_ct.gt_row_ct_ferrov_detvag_cont
                                                 , en_conhectransp_id  => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ctferr_lacre fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ctferr_lacre;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura dos Lacres dos vagões do DCL

procedure pkb_ler_ct_ferrov_detvag_lacre ( est_log_generico        in     out nocopy  dbms_sql.number_table
                                         , en_ctferrovdcldetvag_id in     Ctferrovdcl_Detvag.id%TYPE
                                         , en_conhectransp_id      in     Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Ferrov_Detvag_Lacre is
   select ad.*
     from Ct_Ferrov_Detvag_Lacre ad
    where ad.ctferrovdetvag_id = en_ctferrovdcldetvag_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Ferrov_Detvag_Lacre loop
      exit when c_Ct_Ferrov_Detvag_Lacre%notfound or c_Ct_Ferrov_Detvag_Lacre%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_lacre.id                := rec.id;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_lacre.ctferrovdetvag_id := rec.ctferrovdetvag_id;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_lacre.nro_lacre         := rec.nro_lacre;
      --
      vn_fase := 4;
      -- Chama procedimento que valida das informações dos lacres contidos no vagão.
      pk_csf_api_ct.pkb_integr_ct_fer_detvag_lacre( est_log_generico    => est_log_generico
                                                  , est_row_ct_ferrov_detvag_lacre => pk_csf_api_ct.gt_row_ct_ferrov_detvag_lacre
                                                  , en_conhectransp_id  => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_ferrov_detvag_lacre fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_ferrov_detvag_lacre;


-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das informações de detalhes dos Vagões

procedure pkb_ler_Ctferrovdcl_Detvag ( est_log_generico        in     out nocopy  dbms_sql.number_table
                                     , en_ctferrovdcl_id       in     Ctferrov_Dcl.id%TYPE
                                     , en_conhectransp_id      in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctferrovdcl_Detvag is
   select ad.*
     from Ctferrovdcl_Detvag  ad
    where ad.ctferrovdcl_id = en_ctferrovdcl_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctferrovdcl_Detvag loop
      exit when c_Ctferrovdcl_Detvag%notfound or c_Ctferrovdcl_Detvag%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctferrovdcldetvag_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctferrovdcl_detvag.id              := rec.id;
      pk_csf_api_ct.gt_row_ctferrovdcl_detvag.ctferrovdcl_id  := 1;
      pk_csf_api_ct.gt_row_ctferrovdcl_detvag.nro_vagao       := 1;
      pk_csf_api_ct.gt_row_ctferrovdcl_detvag.cap_ton         := 1;
      pk_csf_api_ct.gt_row_ctferrovdcl_detvag.tipo_vagao      := null;
      pk_csf_api_ct.gt_row_ctferrovdcl_detvag.peso_real       := 1;
      pk_csf_api_ct.gt_row_ctferrovdcl_detvag.peso_bc_frete   := 1;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as informações de detalhes dos Vagões
      pk_csf_api_ct.pkb_integr_ctferrovdcl_detvag( est_log_generico      => est_log_generico
                                                 , est_row_ctferr_detvag => pk_csf_api_ct.gt_row_ctferrovdcl_detvag
                                                 , en_conhectransp_id    => en_conhectransp_id);
      --
      vn_fase := 5;
      -- Lê as Informações as informações de detalhes dos Vagões
      pkb_ler_Ctferrovdcldetvag_Cont ( est_log_generico        => est_log_generico
                                     , en_ctferrovdcldetvag_id => rec.id
                                     , en_conhectransp_id      => en_conhectransp_id );
      --
      vn_fase := 6;
      pkb_ler_ctferr_lacre ( est_log_generico        => est_log_generico
                           , en_ctferrovdcldetvag_id => rec.id
                           , en_conhectransp_id      => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctferrovdcl_Detvag fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctferrovdcl_Detvag;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do Rateio das NFe de Vagões.

procedure pkb_ler_Ct_Ferrov_Detvag_Nfe ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                       , en_conhectransprem_id   in  Conhec_Transp_Rem.id%TYPE
                                       , en_conhectransp_id      in  Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Ferrov_Detvag_Nfe is
   select ad.*
     from Ct_Ferrov_Detvag_Nfe  ad
    where ad.ctferrovdetvag_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Ferrov_Detvag_Nfe loop
      exit when c_Ct_Ferrov_Detvag_Nfe%notfound or c_Ct_Ferrov_Detvag_Nfe%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nfe := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nfe.id                 := rec.id;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nfe.ctferrovdetvag_id  := rec.ctferrovdetvag_id;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nfe.nro_chave_nfe      := rec.nro_chave_nfe;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nfe.peso_rat           := rec.peso_rat;

      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações da NFe do remetente
      pk_csf_api_ct.pkb_integr_ct_fer_detvag_nfe( est_log_generico             => est_log_generico
                                                , est_row_ct_ferrov_detvag_nfe => pk_csf_api_ct.gt_row_ct_ferrov_detvag_nfe
                                                , en_conhectransp_id           => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Ferrov_Detvag_Nfe fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Ferrov_Detvag_Nfe;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das informações de detalhes dos vagões.

procedure pkb_ler_Ct_Ferrov_Detvag ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                   , en_conhectranspferrov_id  in     Conhec_Transp_Ferrov.id%TYPE
                                   , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Ferrov_Detvag is
   select ad.*
     from Ct_ferrov_Detvag  ad
    where ad.conhectranspferrov_id = en_conhectranspferrov_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Ferrov_Detvag loop
      exit when c_Ct_Ferrov_Detvag%notfound or c_Ct_Ferrov_Detvag%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag.id                     := rec.id;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag.conhectranspferrov_id  := 1;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag.nro_vagao              := 1;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag.cap_ton                := 1;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag.tipo_vagao             := null;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag.peso_real              := 1;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag.peso_bc_frete          := 1;
      --
      vn_fase := 4;
      -- Chama procedimento que valida das informações dos containeres contidos no vagão com DCL
      pk_csf_api_ct.pkb_integr_ct_fer_detvag_cont( est_log_generico    => est_log_generico
                                                 , est_row_ct_ferrov_detvag_cont => pk_csf_api_ct.gt_row_ct_ferrov_detvag_cont
                                                 , en_conhectransp_id  => en_conhectransp_id);
      --
      vn_fase := 5;
      -- Lê as Informações de detalhes dos Vagões
      pkb_ler_Ct_ferrov_detvag_Cont ( est_log_generico        => est_log_generico
                                    , en_ctferrovdcldetvag_id => rec.id
                                    , en_conhectransp_id      => en_conhectransp_id );
      --
      vn_fase := 6;
      --pkb_ler_ct_ferrov_detvag_lacre ( est_log_generico        => est_log_generico
        --                             , en_ctferrovdetvag_id    => rec.id
          --                           , en_conhectransp_id      => en_conhectransp_id );
      --
      pkb_ler_Ct_Ferrov_Detvag_Nfe ( est_log_generico        => est_log_generico
                                   , en_conhectransprem_id   => rec.id            
                                   , en_conhectransp_id      => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Ferrov_Detvag fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Ferrov_Detvag;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações da DCL

procedure pkb_ler_Ctferrov_Dcl ( est_log_generico          in     out nocopy  dbms_sql.number_table
                               , en_conhectranspferrov_id  in     Conhec_Transp_Ferrov.id%TYPE
                               , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctferrov_Dcl is
   select ad.*
     from Ctferrov_Dcl  ad
    where ad.conhectranspferrov_id = en_conhectranspferrov_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctferrov_Dcl loop
      exit when c_Ctferrov_Dcl%notfound or c_Ctferrov_Dcl%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctferrov_dcl := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctferrov_dcl.id                    := rec.id;
      pk_csf_api_ct.gt_row_ctferrov_dcl.conhectranspferrov_id := rec.conhectranspferrov_id;
      pk_csf_api_ct.gt_row_ctferrov_dcl.serie                 := rec.serie;
      pk_csf_api_ct.gt_row_ctferrov_dcl.nro_dcl               := rec.nro_dcl;
      pk_csf_api_ct.gt_row_ctferrov_dcl.dt_emissao            := rec.dt_emissao;
      pk_csf_api_ct.gt_row_ctferrov_dcl.qtde_vagao            := rec.qtde_vagao;
      pk_csf_api_ct.gt_row_ctferrov_dcl.peso_calc_ton         := rec.peso_calc_ton;
      pk_csf_api_ct.gt_row_ctferrov_dcl.vl_tarifa             := rec.vl_tarifa;
      pk_csf_api_ct.gt_row_ctferrov_dcl.vl_frete              := rec.vl_frete;
      pk_csf_api_ct.gt_row_ctferrov_dcl.vl_serv_aces          := rec.vl_serv_aces;
      pk_csf_api_ct.gt_row_ctferrov_dcl.vl_total_serv         := rec.vl_total_serv;
      pk_csf_api_ct.gt_row_ctferrov_dcl.id_trem               := rec.id_trem;

      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações da DCL
      pk_csf_api_ct.pkb_integr_ctferrov_dcl( est_log_generico   => est_log_generico
                                           , est_row_ctferr_dcl => pk_csf_api_ct.gt_row_ctferrov_dcl
                                           , en_conhectransp_id => en_conhectransp_id );
      --
      vn_fase := 5;
      -- Lê as Informações as informações as Informações da DCL
      pkb_ler_Ctferrovdcl_Detvag ( est_log_generico     => est_log_generico
                                 , en_ctferrovdcl_id    => rec.id
                                 , en_conhectransp_id  => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctferrov_Dcl fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctferrov_Dcl;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura dos endereço da ferrovia substituída

procedure pkb_ler_Ctferrov_Subst ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                 , en_conhectranspferrov_id  in     Conhec_Transp_Ferrov.id%TYPE
                                 , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctferrov_Subst is
   select ad.*
     from Ctferrov_Subst  ad
    where ad.conhectranspferrov_id = en_conhectranspferrov_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctferrov_Subst loop
      exit when c_Ctferrov_Subst%notfound or c_Ctferrov_Subst%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctferrov_subst := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctferrov_subst.id                    := rec.id;
      pk_csf_api_ct.gt_row_ctferrov_subst.conhectranspferrov_id := rec.conhectranspferrov_id;
      pk_csf_api_ct.gt_row_ctferrov_subst.cnpj                  := rec.cnpj;
      pk_csf_api_ct.gt_row_ctferrov_subst.cod_int               := rec.cod_int;
      pk_csf_api_ct.gt_row_ctferrov_subst.ie                    := rec.ie;
      pk_csf_api_ct.gt_row_ctferrov_subst.nome                  := rec.nome;
      pk_csf_api_ct.gt_row_ctferrov_subst.lograd                := rec.lograd;
      pk_csf_api_ct.gt_row_ctferrov_subst.nro                   := rec.nro;
      pk_csf_api_ct.gt_row_ctferrov_subst.compl                 := rec.compl;
      pk_csf_api_ct.gt_row_ctferrov_subst.bairro                := rec.bairro;
      pk_csf_api_ct.gt_row_ctferrov_subst.ibge_cidade           := rec.ibge_cidade;
      pk_csf_api_ct.gt_row_ctferrov_subst.descr_cidade          := rec.descr_cidade;
      pk_csf_api_ct.gt_row_ctferrov_subst.cep                   := rec.cep;
      pk_csf_api_ct.gt_row_ctferrov_subst.uf                    := rec.uf;
      --
      vn_fase := 4;
      -- Chama procedimento que valida os endereço da ferrovia substituída
      pk_csf_api_ct.pkb_integr_ctferrov_subst( est_log_generico     => est_log_generico
                                             , est_row_ctferr_subst => pk_csf_api_ct.gt_row_ctferrov_subst
                                             , en_conhectransp_id   => en_conhectransp_id );
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctferrov_Subst fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctferrov_Subst;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do modal Ferroviário

procedure pkb_ler_Conhec_Transp_Ferrov ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                       , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is
   --
   cursor c_Conhec_Transp_Ferrov is
   select ad.*
     from Conhec_Transp_Ferrov  ad
    where ad.conhectransp_id = en_conhectransp_id;
   --
   vn_fase               number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Ferrov loop
      exit when c_Conhec_Transp_Ferrov%notfound or c_Conhec_Transp_Ferrov%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_ferrov := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_ferrov.id                 := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_ferrov.conhectransp_id    := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_ferrov.dm_tp_traf         := rec.dm_tp_traf;
      pk_csf_api_ct.gt_row_conhec_transp_ferrov.fluxo_ferrov       := rec.fluxo_ferrov;
      pk_csf_api_ct.gt_row_conhec_transp_ferrov.id_trem            := rec.id_trem;
      pk_csf_api_ct.gt_row_conhec_transp_ferrov.vl_frete           := rec.vl_frete;
      pk_csf_api_ct.gt_row_conhec_transp_ferrov.nro_chave_cte_orig := rec.nro_chave_cte_orig; --Atualização CTe 3.0
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do modal Ferroviário
      pk_csf_api_ct.pkb_integr_ct_ferrov( est_log_generico   => est_log_generico
                                        , est_row_ct_ferrov  => pk_csf_api_ct.gt_row_conhec_transp_ferrov
                                        , en_conhectransp_id => en_conhectransp_id );
      --
      vn_fase := 5;
      -- Lê as Informações as informações do modal Ferroviário
      pkb_ler_Ctferrov_Dcl ( est_log_generico          => est_log_generico
                           , en_conhectranspferrov_id  => rec.id
                           , en_conhectransp_id        => en_conhectransp_id );
      --
      vn_fase := 6;
      pkb_ler_Ctferrov_Subst ( est_log_generico          => est_log_generico
                             , en_conhectranspferrov_id  => rec.id
                             , en_conhectransp_id        => en_conhectransp_id );
      --
      pkb_ler_Ct_Ferrov_Detvag ( est_log_generico         => est_log_generico
                               , en_conhectranspferrov_id => rec.id
                               , en_conhectransp_id       => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Ferrov fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Ferrov;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das informações dos lacres dos cointainers da qtde da carga

procedure pkb_ler_Ctaquav_Lacre ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                , en_conhectranspaquav_id   in     Conhec_Transp_Aquav.id%TYPE
                                , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctaquav_Lacre is
   select ad.*
     from ctaquav_lacre  ad
    where ad.conhectranspaquav_id = en_conhectranspaquav_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctaquav_Lacre loop
      exit when c_Ctaquav_Lacre%notfound or c_Ctaquav_Lacre%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctaquav_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctaquav_lacre.id                     := rec.id;
      pk_csf_api_ct.gt_row_ctaquav_lacre.conhectranspaquav_id   := rec.conhectranspaquav_id;
      pk_csf_api_ct.gt_row_ctaquav_lacre.nro_lacre              := rec.nro_lacre;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as informações dos lacres dos cointainers da qtde da carga
      pk_csf_api_ct.pkb_integr_ctaquav_lacre( est_log_generico      => est_log_generico
                                            , est_row_ctaquav_lacre => pk_csf_api_ct.gt_row_ctaquav_lacre
                                            , en_conhectransp_id    => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctaquav_Lacre fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctaquav_Lacre;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das informações de Balsas do modal Aquaviário.

procedure pkb_ler_Ct_Aquav_Balsa ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                 , en_conhectranspaquav_id   in     Conhec_Transp_Aquav.id%TYPE
                                 , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Aquav_Balsa is
   select ad.*
     from ct_Aquav_Balsa  ad
    where ad.conhectranspaquav_id = en_conhectranspaquav_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Aquav_Balsa loop
      exit when c_Ct_Aquav_Balsa%notfound or c_Ct_Aquav_Balsa%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_Aquav_Balsa := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_Aquav_Balsa.id                     := rec.id;
      pk_csf_api_ct.gt_row_ct_Aquav_Balsa.conhectranspaquav_id   := rec.conhectranspaquav_id;
      pk_csf_api_ct.gt_row_ct_Aquav_Balsa.balsa                  := rec.balsa;
      --                                                                                          
      vn_fase := 4;
      -- Chama procedimento que valida as informações da balsa
      pk_csf_api_ct.pkb_integr_ct_aquav_balsa( est_log_generico       => est_log_generico
                                             , est_row_ct_aquav_balsa => pk_csf_api_ct.gt_row_ct_Aquav_Balsa
                                             , en_conhectransp_id      => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Aquav_Balsa fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Aquav_Balsa;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das informações de Lacres de Conteiners do modal Aquaviário.

procedure pkb_ler_Ct_Aquav_Cont_Lacre ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                      , en_ctaquavcont_id         in     ct_aquav_cont.id%TYPE
                                      , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Aquav_Cont_Lacre is
   select ad.*
     from ct_Aquav_Cont_Lacre  ad
    where ad.ctaquavcont_id = en_ctaquavcont_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Aquav_Cont_Lacre loop
      exit when c_Ct_Aquav_Cont_Lacre%notfound or c_Ct_Aquav_Cont_Lacre%notfound is null;
      --
        vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_aquav_cont_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_aquav_cont_lacre.id                   := rec.id;
      pk_csf_api_ct.gt_row_ct_aquav_cont_lacre.ctaquavcont_id       := rec.ctaquavcont_id;
      pk_csf_api_ct.gt_row_ct_aquav_cont_lacre.lacre                := rec.lacre;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as informações dos lacres dos cointainers da qtde da carga
      pk_csf_api_ct.pkb_integr_ct_aquav_cont_lacre( est_log_generico             => est_log_generico
                                                  , est_row_ct_aquav_cont_lacre  => pk_csf_api_ct.gt_row_ct_aquav_cont_lacre
                                                  , en_conhectransp_id           => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Aquav_Cont_Lacre fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Aquav_Cont_Lacre;

-------------------------------------------------------------------------------------------------------
-- Procedimento de leitura das informações de Notas de Conteiners do modal Aquaviário - Atualização CTe 3.0

procedure pkb_ler_ct_aquav_cont_nf ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                   , en_ctaquavcont_id         in     ct_aquav_cont.id%TYPE
                                   , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is
   --
   cursor c_dados is
   select *
     from ct_aquav_cont_nf
    where ctaquavcont_id = en_ctaquavcont_id;
   --
   vn_fase               number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or c_dados%notfound is null;
      --
        vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_aquav_cont_nf := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_aquav_cont_nf := rec;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as informações das notas dos cointainers da qtde da carga
      pk_csf_api_ct.pkb_integr_ct_aquav_cont_nf ( est_log_generico         => est_log_generico
                                                , est_row_ct_aquav_cont_nf => pk_csf_api_ct.gt_row_ct_aquav_cont_nf
                                                , en_conhectransp_id       => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_aquav_cont_nf fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_aquav_cont_nf;

-------------------------------------------------------------------------------------------------------
--Procedimento de leitura das informações de Notas fiscais eletronicas de Conteiners do modal Aquaviário - Atualização CTe 3.0

procedure pkb_ler_ct_aquav_cont_nfe ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                    , en_ctaquavcont_id         in     ct_aquav_cont.id%TYPE
                                    , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is
   --
   cursor c_dados is
   select *
     from ct_aquav_cont_nfe
    where ctaquavcont_id = en_ctaquavcont_id;
   --
   vn_fase               number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or c_dados%notfound is null;
      --
        vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_aquav_cont_nfe := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_aquav_cont_nfe := rec;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as informações das notas dos cointainers da qtde da carga
      pk_csf_api_ct.pkb_integr_ct_aquav_cont_nfe ( est_log_generico          => est_log_generico
                                                 , est_row_ct_aquav_cont_nfe => pk_csf_api_ct.gt_row_ct_aquav_cont_nfe
                                                 , en_conhectransp_id        => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_aquav_cont_nfe fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_aquav_cont_nfe;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das informações de Conteiners do modal Aquaviário.

procedure pkb_ler_Ct_Aquav_Cont ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                , en_conhectranspaquav_id   in     Conhec_Transp_Aquav.id%TYPE
                                , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Aquav_Cont is
   select ad.*
     from ct_Aquav_Cont  ad
    where ad.conhectranspaquav_id = en_conhectranspaquav_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Aquav_Cont loop
      exit when c_Ct_Aquav_Cont%notfound or c_Ct_Aquav_Cont%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_Aquav_Cont := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_Aquav_Cont.id                         := rec.id;
      pk_csf_api_ct.gt_row_ct_Aquav_Cont.conhectranspaquav_id       := rec.conhectranspaquav_id;
      pk_csf_api_ct.gt_row_ct_Aquav_Cont.conteiner                  := rec.conteiner;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as informações dos cointainers da qtde da carga
      pk_csf_api_ct.pkb_integr_ct_aquav_cont( est_log_generico      => est_log_generico
                                            , est_row_ct_aquav_cont => pk_csf_api_ct.gt_row_ct_Aquav_Cont
                                            , en_conhectransp_id    => en_conhectransp_id );
      --
      pkb_ler_Ct_Aquav_Cont_Lacre ( est_log_generico     => est_log_generico
                                  , en_ctaquavcont_id    => pk_csf_api_ct.gt_row_ct_Aquav_Cont.id
                                  , en_conhectransp_id   => en_conhectransp_id );
      -- Atualização CTe 3.0
      pkb_ler_Ct_Aquav_Cont_Nf ( est_log_generico     => est_log_generico
                               , en_ctaquavcont_id    => pk_csf_api_ct.gt_row_ct_Aquav_Cont.id
                               , en_conhectransp_id   => en_conhectransp_id );
      -- Atualização CTe 3.0
      pkb_ler_Ct_Aquav_Cont_NFe ( est_log_generico     => est_log_generico
                                , en_ctaquavcont_id    => pk_csf_api_ct.gt_row_ct_Aquav_Cont.id
                                , en_conhectransp_id   => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Aquav_Cont fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Aquav_Cont;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do modal Aquaviário

procedure pkb_ler_Conhec_Transp_Aquav ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                      , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Aquav is
   select ad.*
     from Conhec_Transp_Aquav  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Aquav loop
      exit when c_Conhec_Transp_Aquav%notfound or c_Conhec_Transp_Aquav%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_aquav := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_aquav.id                := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.conhectransp_id   := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.vl_prest_bc_afrmm := rec.vl_prest_bc_afrmm;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.vl_afrmm          := rec.vl_afrmm;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.nro_booking       := rec.nro_booking;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.nro_ctrl          := rec.nro_ctrl;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.ident_navio       := rec.ident_navio;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.nro_viagem        := rec.nro_viagem;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.dm_direcao        := rec.dm_direcao;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.port_emb          := rec.port_emb;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.port_transb       := rec.port_transb;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.port_dest         := rec.port_dest;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.dm_tp_nav         := rec.dm_tp_nav;
      pk_csf_api_ct.gt_row_conhec_transp_aquav.irin              := rec.irin;
      --
      vn_fase := 4;
      -- Chama procedimento que valida das Informações do modal Aquaviário
      pk_csf_api_ct.pkb_integr_conhec_transp_aquav( est_log_generico   => est_log_generico
                                                  , est_row_ct_aquav   => pk_csf_api_ct.gt_row_conhec_transp_aquav
                                                  , en_conhectransp_id => en_conhectransp_id );
      --
      vn_fase := 5;
      -- Lê as Informações as informações do modal Aquaviário
      pkb_ler_Ctaquav_Lacre ( est_log_generico        => est_log_generico
                            , en_conhectranspaquav_id => rec.id
                            , en_conhectransp_id      => en_conhectransp_id );
      --
      pkb_ler_Ct_Aquav_Balsa ( est_log_generico        => est_log_generico
                             , en_conhectranspaquav_id => rec.id
                             , en_conhectransp_id      => en_conhectransp_id );
      --
      pkb_ler_Ct_Aquav_Cont ( est_log_generico        => est_log_generico
                            , en_conhectranspaquav_id => rec.id
                            , en_conhectransp_id      => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Aquav fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Aquav;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de dimensões da carga do modal Aéreo.

procedure pkb_ler_Ct_Aereo_Dimen ( est_log_generico        in     out nocopy  dbms_sql.number_table
                                 , en_conhectranspaereo_id in     conhec_transp_aereo.id%TYPE
                                 , en_conhectransp_id      in     Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Aereo_Dimen is
   select ad.*
     from Ct_aereo_dimen  ad
    where ad.conhectranspaereo_id = en_conhectranspaereo_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Aereo_Dimen loop
      exit when c_Ct_Aereo_Dimen%notfound or c_Ct_Aereo_Dimen%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_aereo_dimen := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_aereo_dimen.id                   := rec.id;
      pk_csf_api_ct.gt_row_ct_aereo_dimen.conhectranspaereo_id := rec.conhectranspaereo_id;
      pk_csf_api_ct.gt_row_ct_aereo_dimen.dimensao             := rec.dimensao;
      --
      vn_fase := 4;
      -- Chama procedimento que integra as informações do modal Aéreo.
      --
      pk_csf_api_ct.pkb_integr_ct_aereo_dimen ( est_log_generico         => est_log_generico
                                              , est_row_ct_aereo_dimen   => pk_csf_api_ct.gt_row_ct_aereo_dimen
                                              , en_conhectransp_id       => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Aereo_Dimen fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Aereo_Dimen;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de manuseio da carga do modal Aéreo.

procedure pkb_ler_Ct_Aereo_Inf_Man ( est_log_generico        in     out nocopy  dbms_sql.number_table
                                   , en_conhectranspaereo_id in     conhec_transp_aereo.id%TYPE
                                   , en_conhectransp_id      in     Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Aereo_Inf_Man is
   select ad.*
     from Ct_aereo_inf_man  ad
    where ad.conhectranspaereo_id = en_conhectranspaereo_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Aereo_Inf_Man loop
      exit when c_Ct_Aereo_Inf_Man%notfound or c_Ct_Aereo_Inf_Man%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_aereo_inf_man := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_aereo_inf_man.id                   := rec.id;
      pk_csf_api_ct.gt_row_ct_aereo_inf_man.conhectranspaereo_id := rec.conhectranspaereo_id;
      pk_csf_api_ct.gt_row_ct_aereo_inf_man.dm_manuseio          := rec.dm_manuseio;
      --
      vn_fase := 4;
      --Chama procedimento que valida as Informações do modal Aéreo
      pk_csf_api_ct.pkb_integr_ct_aereo_inf_man( est_log_generico           => est_log_generico
                                               , est_row_ct_aereo_inf_man   => pk_csf_api_ct.gt_row_ct_aereo_inf_man
                                               , en_conhectransp_id         => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Aereo_Inf_Man fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Aereo_Inf_Man;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de carga especial do modal Aéreo.

procedure pkb_ler_Ct_Aereo_Carg_Esp ( est_log_generico        in     out nocopy  dbms_sql.number_table
                                    , en_conhectranspaereo_id in     conhec_transp_aereo.id%TYPE
                                    , en_conhectransp_id      in     Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Aereo_Carg_Esp is
   select ad.*
     from Ct_aereo_carg_esp  ad
    where ad.conhectranspaereo_id = en_conhectranspaereo_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Aereo_Carg_Esp loop
      exit when c_Ct_Aereo_Carg_Esp%notfound or c_Ct_Aereo_Carg_Esp%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_aereo_carg_esp := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_aereo_carg_esp.id                   := rec.id;
      pk_csf_api_ct.gt_row_ct_aereo_carg_esp.conhectranspaereo_id := rec.conhectranspaereo_id;
      pk_csf_api_ct.gt_row_ct_aereo_carg_esp.cod_imp              := rec.cod_imp;
      --
      vn_fase := 4;
      --Chama procedimento que valida as Informações do modal Aéreo
      pk_csf_api_ct.pkb_integr_ct_aereo_carg_esp( est_log_generico            => est_log_generico
                                                , est_row_ct_aereo_carg_esp   => pk_csf_api_ct.gt_row_ct_aereo_carg_esp
                                                , en_conhectransp_id          => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Aereo_Carg_Esp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Aereo_Carg_Esp;

-------------------------------------------------------------------------------------------------------
-- Procedimento de leitura de Transporte de produtos classificados pela ONU como perigosos. - Atualização 3.0

procedure pkb_ler_ct_aereo_peri ( est_log_generico        in     out nocopy  dbms_sql.number_table
                                , en_conhectranspaereo_id in     conhec_transp_aereo.id%TYPE
                                , en_conhectransp_id      in     Conhec_Transp.id%TYPE)
is
   --
   cursor c_dados is
   select *
     from ct_aereo_peri
    where conhectranspaereo_id = en_conhectranspaereo_id;
   --
   vn_fase               number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or c_dados%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_aereo_peri := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_aereo_peri := rec;
      --
      vn_fase := 4;
      -- Chama procedimento que integra as informações de Transporte de produtos classificados pela ONU como perigosos.
      pk_csf_api_ct.pkb_integr_ct_aereo_peri( est_log_generico        => est_log_generico
                                            , est_row_ct_aereo_peri   => pk_csf_api_ct.gt_row_ct_aereo_peri
                                            , en_conhectransp_id      => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_aereo_peri fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_aereo_peri;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do modal Aéreo

procedure pkb_ler_Conhec_Transp_Aereo ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                      , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Aereo is
   select ad.*
     from Conhec_Transp_Aereo  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Aereo loop
      exit when c_Conhec_Transp_Aereo%notfound or c_Conhec_Transp_Aereo%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_aereo := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_aereo.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.nro_minuta      := rec.nro_minuta;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.nro_oper        := rec.nro_oper;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.dt_prev_entr    := rec.dt_prev_entr;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.loja_ag_emiss   := rec.loja_ag_emiss;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.cod_iata        := rec.cod_iata;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.trecho          := rec.trecho;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.cl              := rec.cl;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.cod_tarifa      := rec.cod_tarifa;
      pk_csf_api_ct.gt_row_conhec_transp_aereo.vl_tarifa       := rec.vl_tarifa;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do modal Aéreo
      pk_csf_api_ct.pkb_integr_conhec_transp_aereo( est_log_generico   => est_log_generico
                                                  , est_row_ct_aereo   => pk_csf_api_ct.gt_row_conhec_transp_aereo
                                                  , en_conhectransp_id => en_conhectransp_id );
      --
      pkb_ler_Ct_Aereo_Dimen ( est_log_generico         => est_log_generico
                             , en_conhectranspaereo_id  => rec.id
                             , en_conhectransp_id       => en_conhectransp_id );
      --
      pkb_ler_Ct_Aereo_Inf_Man ( est_log_generico         => est_log_generico
                               , en_conhectranspaereo_id  => rec.id
                               , en_conhectransp_id       => en_conhectransp_id );
      --
      pkb_ler_Ct_Aereo_Carg_Esp ( est_log_generico        => est_log_generico
                                , en_conhectranspaereo_id => rec.id               
                                , en_conhectransp_id      => en_conhectransp_id );
      -- Atualização CTe 3.0
      pkb_ler_ct_aereo_peri ( est_log_generico        => est_log_generico
                            , en_conhectranspaereo_id => rec.id
                            , en_conhectransp_id      => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Aereo fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Aereo;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do(s) Motorista(s)

procedure pkb_ler_Ctrodo_Moto ( est_log_generico          in     out nocopy  dbms_sql.number_table
                              , en_conhectransprodo_id    in     conhec_transp_rodo.id%TYPE
                              , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctrodo_Moto is
   select ad.*
     from Ctrodo_Moto  ad
    where ad.conhectransprodo_id = en_conhectransprodo_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrodo_Moto loop
      exit when c_Ctrodo_Moto%notfound or c_Ctrodo_Moto%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrodo_moto := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrodo_moto.id                  := rec.id;
      pk_csf_api_ct.gt_row_ctrodo_moto.conhectransprodo_id := rec.conhectransprodo_id;
      pk_csf_api_ct.gt_row_ctrodo_moto.nome                := rec.nome;
      pk_csf_api_ct.gt_row_ctrodo_moto.cpf                 := rec.cpf;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do(s) Motorista(s)
      pk_csf_api_ct.pkb_integr_ctrodo_moto( est_log_generico    => est_log_generico
                                          , est_row_ctrodo_moto => pk_csf_api_ct.gt_row_ctrodo_moto
                                          , en_conhectransp_id  => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrodo_Moto fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrodo_Moto;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações Dados dos Veículos

procedure pkb_ler_Ctrodo_Lacre ( est_log_generico          in     out nocopy  dbms_sql.number_table
                               , en_conhectransprodo_id    in     conhec_transp_rodo.id%TYPE
                               , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctrodo_Lacre is
   select ad.*
     from Ctrodo_Lacre  ad
    where ad.conhectransprodo_id = en_conhectransprodo_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrodo_Lacre loop
      exit when c_Ctrodo_Lacre%notfound or c_Ctrodo_Lacre%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrodo_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrodo_lacre.id                  := rec.id;
      pk_csf_api_ct.gt_row_ctrodo_lacre.conhectransprodo_id := rec.conhectransprodo_id;
      pk_csf_api_ct.gt_row_ctrodo_lacre.nro_lacre           := rec.nro_lacre;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações  Dados dos Veículos
      pk_csf_api_ct.pkb_integr_ctrodo_lacre( est_log_generico     => est_log_generico
                                           , est_row_ctrodo_lacre => pk_csf_api_ct.gt_row_ctrodo_lacre
                                           , en_conhectransp_id   => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrodo_Lacre fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrodo_Lacre;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações dos Proprietários do Veículo

procedure pkb_ler_Ctrodo_Veic_Prop ( est_log_generico          in     out nocopy  dbms_sql.number_table
                                   , en_ctrodoveic_id          in     ctrodo_veic.id%TYPE
                                   , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctrodo_Veic_Prop is
   select ad.*
     from Ctrodo_Veic_Prop  ad
    where ad.ctrodoveic_id = en_ctrodoveic_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrodo_Veic_Prop loop
      exit when c_Ctrodo_Veic_Prop%notfound or c_Ctrodo_Veic_Prop%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrodo_veic_prop := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrodo_veic_prop.id            := rec.id;
      pk_csf_api_ct.gt_row_ctrodo_veic_prop.ctrodoveic_id := rec.ctrodoveic_id;
      pk_csf_api_ct.gt_row_ctrodo_veic_prop.cpf           := rec.cpf;
      pk_csf_api_ct.gt_row_ctrodo_veic_prop.cnpj          := rec.cnpj;
      pk_csf_api_ct.gt_row_ctrodo_veic_prop.rntrc         := rec.rntrc;
      pk_csf_api_ct.gt_row_ctrodo_veic_prop.nome          := rec.nome;
      pk_csf_api_ct.gt_row_ctrodo_veic_prop.ie            := rec.ie;
      pk_csf_api_ct.gt_row_ctrodo_veic_prop.uf            := rec.uf;
      pk_csf_api_ct.gt_row_ctrodo_veic_prop.dm_tp_prop    := rec.dm_tp_prop;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações dos Proprietários do Veículo
      pk_csf_api_ct.pkb_integr_ctrodo_veic_prop( est_log_generico         => est_log_generico
                                               , est_row_ctrodo_veic_prop => pk_csf_api_ct.gt_row_ctrodo_veic_prop
                                               , en_conhectransp_id       => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrodo_Veic_Prop fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrodo_Veic_Prop;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações dos Veículos

procedure pkb_ler_Ctrodo_Veic ( est_log_generico          in     out nocopy  dbms_sql.number_table
                              , en_conhectransprodo_id    in     Conhec_Transp_Rodo.id%TYPE
                              , en_conhectransp_id        in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctrodo_Veic is
   select ad.*
     from Ctrodo_Veic  ad
    where ad.conhectransprodo_id = en_conhectransprodo_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrodo_Veic loop
      exit when c_Ctrodo_Veic%notfound or c_Ctrodo_Veic%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrodo_veic := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrodo_veic.id                  := rec.id;
      pk_csf_api_ct.gt_row_ctrodo_veic.conhectransprodo_id := rec.conhectransprodo_id;
      pk_csf_api_ct.gt_row_ctrodo_veic.cod_int_veic        := rec.cod_int_veic;
      pk_csf_api_ct.gt_row_ctrodo_veic.renavam             := rec.renavam;
      pk_csf_api_ct.gt_row_ctrodo_veic.placa               := rec.placa;
      pk_csf_api_ct.gt_row_ctrodo_veic.tara                := rec.tara;
      pk_csf_api_ct.gt_row_ctrodo_veic.cap_kg              := rec.cap_kg;
      pk_csf_api_ct.gt_row_ctrodo_veic.cap_m3              := rec.cap_m3;
      pk_csf_api_ct.gt_row_ctrodo_veic.dm_tp_prop          := rec.dm_tp_prop;
      pk_csf_api_ct.gt_row_ctrodo_veic.dm_tp_veic          := rec.dm_tp_veic;
      pk_csf_api_ct.gt_row_ctrodo_veic.dm_tp_rod           := rec.dm_tp_rod;
      pk_csf_api_ct.gt_row_ctrodo_veic.dm_tp_car           := rec.dm_tp_car;
      pk_csf_api_ct.gt_row_ctrodo_veic.uf                  := rec.uf;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações dos Veículos
      pk_csf_api_ct.pkb_integr_ctrodo_veic( est_log_generico    => est_log_generico
                                          , est_row_ctrodo_veic => pk_csf_api_ct.gt_row_ctrodo_veic
                                          , en_conhectransp_id  => en_conhectransp_id );
      --
      vn_fase := 5;
      -- Lê as Informações dos Veículos
      pkb_ler_Ctrodo_Veic_Prop ( est_log_generico     => est_log_generico
                               , en_ctrodoveic_id     => rec.id
                               , en_conhectransp_id   => en_conhectransp_id );
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrodo_Veic fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrodo_Veic;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações dos dispositivos do Vale Pedágio

procedure pkb_ler_Ctrodo_Valeped_Disp ( est_log_generico       in    out nocopy  dbms_sql.number_table
                                      , en_ctrodovaleped_id    in    Ctrodo_Valeped.id%TYPE
                                      , en_conhectransp_id     in    Conhec_Transp.id%TYPE)
is

   cursor c_Ctrodo_Valeped_Disp is
   select ad.*
     from Ctrodo_Valeped_Disp  ad
    where ad.ctrodovaleped_id = en_ctrodovaleped_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrodo_Valeped_Disp loop
      exit when c_Ctrodo_Valeped_Disp%notfound or c_Ctrodo_Valeped_Disp%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrodo_valeped_disp := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrodo_valeped_disp.id               := rec.id;
      pk_csf_api_ct.gt_row_ctrodo_valeped_disp.ctrodovaleped_id := rec.ctrodovaleped_id;
      pk_csf_api_ct.gt_row_ctrodo_valeped_disp.dm_tp_disp       := rec.dm_tp_disp;
      pk_csf_api_ct.gt_row_ctrodo_valeped_disp.empr_forn        := rec.empr_forn;
      pk_csf_api_ct.gt_row_ctrodo_valeped_disp.dt_vig           := rec.dt_vig;
      pk_csf_api_ct.gt_row_ctrodo_valeped_disp.nro_disp         := rec.nro_disp;
      pk_csf_api_ct.gt_row_ctrodo_valeped_disp.nro_comp         := rec.nro_comp;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações dos dispositivos do Vale Pedágio
      pk_csf_api_ct.pkb_integr_ctrodo_valeped_disp( est_log_generico            => est_log_generico
                                                  , est_row_ctrodo_valeped_disp => pk_csf_api_ct.gt_row_ctrodo_valeped_disp
                                                  , en_conhectransp_id          => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrodo_Valeped_Disp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrodo_Valeped_Disp;
-------------------------------------------------------------------------------------------------------

-- Procedimento faz a leitura das Informações de Vale Pedágio

procedure pkb_ler_Ctrodo_Valeped ( est_log_generico       in     out nocopy  dbms_sql.number_table
                                 , en_conhectransprodo_id in     conhec_transp_rodo.id%TYPE
                                 , en_conhectransp_id     in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctrodo_Valeped is
   select ad.*
     from Ctrodo_Valeped  ad
    where ad.conhectransprodo_id = en_conhectransprodo_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrodo_Valeped loop
      exit when c_Ctrodo_Valeped%notfound or c_Ctrodo_Valeped%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrodo_valeped := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrodo_valeped.id                  := rec.id;
      pk_csf_api_ct.gt_row_ctrodo_valeped.conhectransprodo_id := rec.conhectransprodo_id;
      pk_csf_api_ct.gt_row_ctrodo_valeped.nro_reg             := rec.nro_reg;
      pk_csf_api_ct.gt_row_ctrodo_valeped.vl_total_valeped    := rec.vl_total_valeped;
      pk_csf_api_ct.gt_row_ctrodo_valeped.dm_resp_pagto       := rec.dm_resp_pagto;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de Vale Pedágio
      pk_csf_api_ct.pkb_integr_ctrodo_valeped( est_log_generico       => est_log_generico
                                             , est_row_ctrodo_valeped => pk_csf_api_ct.gt_row_ctrodo_valeped
                                             , en_conhectransp_id     => en_conhectransp_id);
      --
      vn_fase := 5;
      -- Lê as Informações de Vale Pedágio
      pkb_ler_Ctrodo_Valeped_Disp ( est_log_generico    => est_log_generico
                                  , en_ctrodovaleped_id => rec.id
                                  , en_conhectransp_id  => en_conhectransp_id );
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrodo_Valeped fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrodo_Valeped;

-------------------------------------------------------------------------------------------------------

-- Procedimento faz a leitura das Informações de Vale Pedágio

procedure pkb_ler_Ctrodo_inf_Valeped ( est_log_generico       in     out nocopy  dbms_sql.number_table
                                     , en_conhectransprodo_id in     conhec_transp_rodo.id%TYPE
                                     , en_conhectransp_id     in     Conhec_Transp.id%TYPE
                                     )
is

   cursor c_dados is
   select ad.*
     from Ctrodo_inf_Valeped  ad
    where ad.conhectransprodo_id = en_conhectransprodo_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or c_dados%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrodo_inf_valeped := rec;
      --
      vn_fase := 3;
      --
      -- Chama procedimento que integra as informações de Vale Pedágio.
      pk_csf_api_ct.pkb_integr_ctrodo_inf_valeped ( est_log_generico               => est_log_generico
                                                  , est_row_ctrodo_inf_valeped     => pk_csf_api_ct.gt_row_ctrodo_inf_valeped
                                                  , en_conhectransp_id             => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrodo_inf_Valeped fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrodo_inf_Valeped;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Ordens de Coleta associados

procedure pkb_ler_Ctrodo_Occ ( est_log_generico       in     out nocopy  dbms_sql.number_table
                             , en_conhectransprodo_id in     conhec_transp_rodo.id%TYPE
                             , en_conhectransp_id     in     Conhec_Transp.id%TYPE)
is

   cursor c_Ctrodo_Occ is
   select ad.*
     from Ctrodo_Occ  ad
    where ad.conhectransprodo_id = en_conhectransprodo_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrodo_Occ loop
      exit when c_Ctrodo_Occ%notfound or c_Ctrodo_Occ%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrodo_occ := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrodo_occ.id                  := rec.id;
      pk_csf_api_ct.gt_row_ctrodo_occ.conhectransprodo_id := rec.conhectransprodo_id;
      pk_csf_api_ct.gt_row_ctrodo_occ.serie               := rec.serie;
      pk_csf_api_ct.gt_row_ctrodo_occ.nro_occ             := rec.nro_occ;
      pk_csf_api_ct.gt_row_ctrodo_occ.dt_emissao          := rec.dt_emissao;
      pk_csf_api_ct.gt_row_ctrodo_occ.cnpj                := rec.cnpj;
      pk_csf_api_ct.gt_row_ctrodo_occ.cod_int             := rec.cod_int;
      pk_csf_api_ct.gt_row_ctrodo_occ.ie                  := rec.ie;
      pk_csf_api_ct.gt_row_ctrodo_occ.uf                  := rec.uf;
      pk_csf_api_ct.gt_row_ctrodo_occ.fone                := rec.fone;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de Ordens de Coleta associados
      pk_csf_api_ct.pkb_integr_ctrodo_occ( est_log_generico => est_log_generico
                                         , est_row_ctrodo_occ => pk_csf_api_ct.gt_row_ctrodo_occ
                                         , en_conhectransp_id => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrodo_Occ fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrodo_Occ;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações modal Rodoviário

procedure pkb_ler_Conhec_Transp_Rodo ( est_log_generico    in   out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id  in   Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Rodo is
   select ad.*
     from Conhec_Transp_Rodo  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Rodo loop
      exit when c_Conhec_Transp_Rodo%notfound or c_Conhec_Transp_Rodo%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_rodo := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_rodo.id               := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_rodo.conhectransp_id  := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_rodo.rntrc            := rec.rntrc;
      pk_csf_api_ct.gt_row_conhec_transp_rodo.dt_prev_entr     := rec.dt_prev_entr;
      pk_csf_api_ct.gt_row_conhec_transp_rodo.dm_lotacao       := rec.dm_lotacao;
      pk_csf_api_ct.gt_row_conhec_transp_rodo.serie_ctrb       := rec.serie_ctrb;
      pk_csf_api_ct.gt_row_conhec_transp_rodo.nro_ctrb         := rec.nro_ctrb;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações modal Rodoviário
      pk_csf_api_ct.pkb_integr_conhec_transp_rodo( est_log_generico           => est_log_generico
                                                 , est_row_conhec_transp_rodo => pk_csf_api_ct.gt_row_conhec_transp_rodo
                                                 , en_conhectransp_id         => en_conhectransp_id);
      --
      vn_fase := 5;
      --Lê as informaçoes do Modal Rodoviário
      pkb_ler_Ctrodo_Moto ( est_log_generico        => est_log_generico
                          , en_conhectransprodo_id  => rec.id
                          , en_conhectransp_id      => en_conhectransp_id);
      --
      pkb_ler_Ctrodo_Lacre ( est_log_generico       => est_log_generico
                           , en_conhectransprodo_id => rec.id
                           , en_conhectransp_id     => en_conhectransp_id);
      --
      pkb_ler_Ctrodo_Veic ( est_log_generico        => est_log_generico
                          , en_conhectransprodo_id  => rec.id
                          , en_conhectransp_id      => en_conhectransp_id);
      --
      pkb_ler_Ctrodo_inf_Valeped ( est_log_generico         => est_log_generico
                                 , en_conhectransprodo_id   => rec.id
                                 , en_conhectransp_id       => en_conhectransp_id
                                 );
      --
      pkb_ler_Ctrodo_Occ ( est_log_generico        => est_log_generico
                         , en_conhectransprodo_id  => rec.id
                         , en_conhectransp_id      => en_conhectransp_id);
   --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Rodo fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Rodo;

-------------------------------------------------------------------------------------------------------
-- Procedimento de leitura das informações dos documentos referenciados CTe Outros Serviços. - Atualização CTe 3.0

procedure pkb_ler_ct_rodo_os ( est_log_generico    in   out nocopy  dbms_sql.number_table
                             , en_conhectransp_id  in   Conhec_Transp.id%TYPE)
is
   --
   cursor c_dados is
   select *
     from ct_rodo_os
    where conhectransp_id = en_conhectransp_id;
   --
   vn_fase               number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or c_dados%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_rodo_os := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_rodo_os := rec;
      --
      vn_fase := 4;
      -- Chama procedimento que integra as Informações dos documentos referenciados CTe Outros Serviços.
      pk_csf_api_ct.pkb_integr_ct_rodo_os ( est_log_generico    => est_log_generico
                                          , est_row_ct_rodo_os  => pk_csf_api_ct.gt_row_ct_rodo_os
                                          , en_conhectransp_id  => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_rodo_os fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_rodo_os;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Seguro da Carga

procedure pkb_ler_Conhec_Transp_Seg ( est_log_generico    in   out nocopy  dbms_sql.number_table
                                    , en_conhectransp_id  in   Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Seg is
   select ad.*
     from Conhec_Transp_Seg  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Seg loop
      exit when c_Conhec_Transp_Seg%notfound or c_Conhec_Transp_Seg%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_seg := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_seg.id               := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_seg.conhectransp_id  := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_seg.dm_resp_seg      := rec.dm_resp_seg;
      pk_csf_api_ct.gt_row_conhec_transp_seg.descr_seguradora := rec.descr_seguradora;
      pk_csf_api_ct.gt_row_conhec_transp_seg.nro_apolice      := rec.nro_apolice;
      pk_csf_api_ct.gt_row_conhec_transp_seg.nro_averb        := rec.nro_averb;
      pk_csf_api_ct.gt_row_conhec_transp_seg.vl_merc          := rec.vl_merc;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de Seguro da Carga
      pk_csf_api_ct.pkb_integr_conhec_transp_seg( est_log_generico          => est_log_generico
                                                , est_row_conhec_transp_seg => pk_csf_api_ct.gt_row_conhec_transp_seg
                                                , en_conhectransp_id        => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Seg fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Seg;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações Documentos de transporte anterior eletrônicos

procedure pkb_ler_Ctdocant_Eletr ( est_log_generico         in   out nocopy  dbms_sql.number_table
                                 , en_conhectranspdocant_id in   conhec_transp_docant.id%TYPE
                                 , en_conhectransp_id       in   Conhec_Transp.id%TYPE)
is

   cursor c_Ctdocant_Eletr is
   select ad.*
     from Ctdocant_Eletr  ad
    where ad.conhectranspdocant_id = en_conhectranspdocant_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctdocant_Eletr loop
      exit when c_Ctdocant_Eletr%notfound or c_Ctdocant_Eletr%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctdocant_eletr := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctdocant_eletr.id                    := rec.id;
      pk_csf_api_ct.gt_row_ctdocant_eletr.conhectranspdocant_id := rec.conhectranspdocant_id;
      pk_csf_api_ct.gt_row_ctdocant_eletr.nro_chave_cte         := rec.nro_chave_cte;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações Documentos de transporte anterior eletrônicos
      pk_csf_api_ct.pkb_integr_ctdocant_eletr( est_log_generico       => est_log_generico
                                             , est_row_ctdocant_eletr => pk_csf_api_ct.gt_row_ctdocant_eletr
                                             , en_conhectransp_id     => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctdocant_Eletr fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctdocant_Eletr;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de transporte anterior em papel

procedure pkb_ler_Ctdocant_Papel ( est_log_generico         in   out nocopy  dbms_sql.number_table
                                 , en_conhectranspdocant_id in   conhec_transp_docant.id%TYPE
                                 , en_conhectransp_id       in   Conhec_Transp.id%TYPE)
is

   cursor c_Ctdocant_Papel is
   select ad.*
     from Ctdocant_Papel  ad
    where ad.conhectranspdocant_id = en_conhectranspdocant_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctdocant_Papel loop
      exit when c_Ctdocant_Papel%notfound or c_Ctdocant_Papel%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctdocant_papel := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctdocant_papel.id                    := rec.id;
      pk_csf_api_ct.gt_row_ctdocant_papel.conhectranspdocant_id := rec.conhectranspdocant_id;
      pk_csf_api_ct.gt_row_ctdocant_papel.dm_tp_doc             := rec.dm_tp_doc;
      pk_csf_api_ct.gt_row_ctdocant_papel.serie                 := rec.serie;
      pk_csf_api_ct.gt_row_ctdocant_papel.sub_serie             := rec.sub_serie;
      pk_csf_api_ct.gt_row_ctdocant_papel.nro_docto             := rec.nro_docto;
      pk_csf_api_ct.gt_row_ctdocant_papel.dt_emissao            := rec.dt_emissao;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de transporte anterior em papel
      pk_csf_api_ct.pkb_integr_ctdocant_papel( est_log_generico       => est_log_generico
                                             , est_row_ctdocant_papel => pk_csf_api_ct.gt_row_ctdocant_papel
                                             , en_conhectransp_id     => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctdocant_Papel fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctdocant_Papel;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Documentos de Transporte Anterior

procedure pkb_ler_Conhec_Transp_Docant ( est_log_generico         in   out nocopy  dbms_sql.number_table
                                       , en_conhectransp_id       in   Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Docant is
   select ad.*
     from Conhec_Transp_Docant  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Docant loop
      exit when c_Conhec_Transp_Docant%notfound or c_Conhec_Transp_Docant%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_docant := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctdocant_papel.id                    := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_docant.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_docant.cnpj            := rec.cnpj;
      pk_csf_api_ct.gt_row_conhec_transp_docant.cpf             := rec.cpf;
      pk_csf_api_ct.gt_row_conhec_transp_docant.ie              := rec.ie;
      pk_csf_api_ct.gt_row_conhec_transp_docant.uf              := rec.uf;
      pk_csf_api_ct.gt_row_conhec_transp_docant.nome            := rec.nome;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de Documentos de Transporte Anterior
      pk_csf_api_ct.pkb_integr_conhectransp_docant( est_log_generico            => est_log_generico
                                                  , est_row_conhectransp_docant => pk_csf_api_ct.gt_row_conhec_transp_docant
                                                  , en_conhectransp_id          => en_conhectransp_id);
      --
      vn_fase := 5;
      --Lê as informaçoes dos Documentos de Transporte Anterior
      pkb_ler_Ctdocant_Eletr ( est_log_generico         => est_log_generico
                             , en_conhectranspdocant_id => rec.id
                             , en_conhectransp_id       => en_conhectransp_id);
      --
      pkb_ler_Ctdocant_Papel ( est_log_generico         => est_log_generico
                             , en_conhectranspdocant_id => rec.id
                             , en_conhectransp_id       => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Docant fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Docant;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Lacres dos containers

procedure pkb_ler_Ctcont_Lacre ( est_log_generico         in   out nocopy  dbms_sql.number_table
                               , en_conhectranspcont_id   in   conhec_transp_cont.id%TYPE
                               , en_conhectransp_id       in   Conhec_Transp.id%TYPE)
is

   cursor c_Ctcont_Lacre is
   select ad.*
     from Ctcont_Lacre  ad
    where ad.conhectranspcont_id = en_conhectranspcont_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctcont_Lacre loop
      exit when c_Ctcont_Lacre%notfound or c_Ctcont_Lacre%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctcont_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctcont_lacre.id                    := rec.id;
      pk_csf_api_ct.gt_row_ctcont_lacre.conhectranspcont_id   := rec.conhectranspcont_id;
      pk_csf_api_ct.gt_row_ctcont_lacre.nro_lacre             := rec.nro_lacre;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de Lacres dos containers
      pk_csf_api_ct.pkb_integr_ctcont_lacre( est_log_generico     => est_log_generico
                                           , est_row_ctcont_lacre => pk_csf_api_ct.gt_row_ctcont_lacre
                                           , en_conhectransp_id   => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctcont_Lacre fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctcont_Lacre;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações dos containers

procedure pkb_ler_Conhec_Transp_Cont ( est_log_generico         in   out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id       in   Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Cont is
   select ad.*
     from Conhec_Transp_Cont  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Cont loop
      exit when c_Conhec_Transp_Cont%notfound or c_Conhec_Transp_Cont%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_cont := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_cont.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_cont.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_cont.nro_cont        := rec.nro_cont;
      pk_csf_api_ct.gt_row_conhec_transp_cont.dt_prevista     := rec.dt_prevista;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações dos containers
      pk_csf_api_ct.pkb_integr_conhec_transp_cont( est_log_generico           => est_log_generico
                                                 , est_row_conhec_transp_cont => pk_csf_api_ct.gt_row_conhec_transp_cont
                                                 , en_conhectransp_id         => en_conhectransp_id);
      vn_fase := 5;
      --Lé as informações dos containers
      pkb_ler_Ctcont_Lacre ( est_log_generico         => est_log_generico
                           , en_conhectranspcont_id   => rec.id
                           , en_conhectransp_id       => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Cont fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Cont;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de quantidades da Carga do CT

procedure pkb_ler_Ctinfcarga_Qtde ( est_log_generico             in   out nocopy  dbms_sql.number_table
                                  , en_conhectranspinfcarga_id   in   conhec_transp_infcarga.id%TYPE
                                  , en_conhectransp_id           in   Conhec_Transp.id%TYPE)
is

   cursor c_Ctinfcarga_Qtde is
   select ad.*
     from Ctinfcarga_Qtde  ad
    where ad.conhectranspinfcarga_id = en_conhectranspinfcarga_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctinfcarga_Qtde loop
      exit when c_Ctinfcarga_Qtde%notfound or c_Ctinfcarga_Qtde%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctinfcarga_qtde := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctinfcarga_qtde.id                      := rec.id;
      pk_csf_api_ct.gt_row_ctinfcarga_qtde.conhectranspinfcarga_id := rec.conhectranspinfcarga_id;
      pk_csf_api_ct.gt_row_ctinfcarga_qtde.dm_cod_unid             := rec.dm_cod_unid;
      pk_csf_api_ct.gt_row_ctinfcarga_qtde.tipo_medida             := rec.tipo_medida;
      pk_csf_api_ct.gt_row_ctinfcarga_qtde.qtde_carga              := rec.qtde_carga;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de quantidades da Carga do CT
      pk_csf_api_ct.pkb_integr_ctinfcarga_qtde( est_log_generico        => est_log_generico
                                              , est_row_ctinfcarga_qtde => pk_csf_api_ct.gt_row_ctinfcarga_qtde
                                              , en_conhectransp_id      => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctinfcarga_Qtde fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctinfcarga_Qtde;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações da Carga do CT-e

procedure pkb_ler_Conhec_Transp_Infcarga ( est_log_generico             in   out nocopy  dbms_sql.number_table
                                         , en_conhectransp_id           in   Conhec_Transp.id%TYPE)
is
   --
   cursor c_Conhec_Transp_Infcarga is
   select ad.*
     from Conhec_Transp_Infcarga  ad
    where ad.conhectransp_id = en_conhectransp_id;
   --
   vn_fase               number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Infcarga loop
      exit when c_Conhec_Transp_Infcarga%notfound or c_Conhec_Transp_Infcarga%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_infcarga := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_infcarga.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_infcarga.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_infcarga.vl_total_merc   := rec.vl_total_merc;
      pk_csf_api_ct.gt_row_conhec_transp_infcarga.prod_predom     := rec.prod_predom;
      pk_csf_api_ct.gt_row_conhec_transp_infcarga.outra_caract    := rec.outra_caract;
      pk_csf_api_ct.gt_row_conhec_transp_infcarga.vl_carga_averb  := rec.vl_carga_averb; --Atualização CTe 3.0
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações da Carga do CT-e
      pk_csf_api_ct.pkb_integr_ct_infcarga( est_log_generico    => est_log_generico
                                          , est_row_ct_infcarga => pk_csf_api_ct.gt_row_conhec_transp_infcarga
                                          , en_conhectransp_id  => en_conhectransp_id);
      --
      vn_fase := 5;
      --Lê as informações da Carga do CT-e
      pkb_ler_Ctinfcarga_Qtde ( est_log_generico             => est_log_generico
                              , en_conhectranspinfcarga_id   => rec.id
                              , en_conhectransp_id           => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Infcarga fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Infcarga;
--
-- ===================================================================================================================== --
-- Procedimento faz a leitura das Informações Relativas aos Impostos
--
procedure pkb_ler_Conhec_Transp_Imp ( est_log_generico             in   out nocopy  dbms_sql.number_table
                                    , en_conhectransp_id           in   Conhec_Transp.id%TYPE)
is
   --
   cursor c_Conhec_Transp_Imp is
   select ad.*
        , ti.cd      cd
        , cs.cod_st  cod_st
     from Conhec_Transp_Imp  ad
        , Tipo_imposto       ti
        , Cod_st             cs
    where ad.conhectransp_id = en_conhectransp_id
      and ad.tipoimp_id = ti.id
      and ad.codst_id   = cs.id
      and cs.tipoimp_id = ti.id
      order by ad.id;
   --
   vn_fase               number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Imp loop
      exit when c_Conhec_Transp_Imp%notfound or c_Conhec_Transp_Imp%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_imp := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_imp.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_imp.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_imp.tipoimp_id      := rec.tipoimp_id;
      pk_csf_api_ct.gt_row_conhec_transp_imp.codst_id        := rec.codst_id;
      pk_csf_api_ct.gt_row_conhec_transp_imp.vl_base_calc    := rec.vl_base_calc;
      pk_csf_api_ct.gt_row_conhec_transp_imp.aliq_apli       := rec.aliq_apli;
      pk_csf_api_ct.gt_row_conhec_transp_imp.vl_imp_trib     := rec.vl_imp_trib;
      pk_csf_api_ct.gt_row_conhec_transp_imp.perc_reduc      := rec.perc_reduc;
      pk_csf_api_ct.gt_row_conhec_transp_imp.vl_cred         := rec.vl_cred;
      pk_csf_api_ct.gt_row_conhec_transp_imp.dm_inf_imp      := nvl(rec.dm_inf_imp,0);
      pk_csf_api_ct.gt_row_conhec_transp_imp.dm_outra_uf     := rec.dm_outra_uf; --Atualização CTe 3.0
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações Relativas aos Impostos
      pk_csf_api_ct.pkb_integr_conhec_transp_imp( est_log_generico          => est_log_generico
                                                , est_row_conhec_transp_imp => pk_csf_api_ct.gt_row_conhec_transp_imp
                                                , en_conhectransp_id        => en_conhectransp_id
                                                , en_cd_imp => rec.cd
                                                , ev_cod_st => rec.cod_st );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Imp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Imp;
--
-- ============================================================================================================================== --
-- Procedimento faz a leitura das Informações Relativas aos Outros Impostos
-- ============================================================================================================================== --
--
procedure pkb_ler_conhec_transp_imp_out ( est_log_generico    in  out nocopy  dbms_sql.number_table
                                        , en_conhectransp_id  in  Conhec_Transp.id%type
                                        , en_empresa_id       in  empresa.id%type ) is
   --
   vn_fase  number := 0;
   vv_cnpj_cpf     varchar2(14) := null;
   --
   cursor c_Conhec_Transp_Imp_Out is
       select *
         from ( select 4 cod_imp -- Pis
                     , a.id
                     , a.conhectransp_id
                     , a.dm_ind_nat_frt
                     , a.vl_item
                     , a.codst_id
                     , a.basecalccredpc_id
                     , a.vl_bc_pis
                     , a.aliq_pis
                     , a.vl_pis
                     , null  vl_bc_cofins
                     , null  aliq_cofins
                     , null  vl_cofins
                     , a.planoconta_id
                     , a.natrecpc_id
                     , cs1.cod_st
                  from ct_comp_doc_pis a
                     , cod_st          cs1
                 where cs1.id             = a.codst_id
                   and a.conhectransp_id  = en_conhectransp_id
                 union all
                select 5 cod_imp -- Cofins
                     , b.id
                     , b.conhectransp_id
                     , b.dm_ind_nat_frt
                     , b.vl_item
                     , b.codst_id
                     , b.basecalccredpc_id
                     , null  vl_bc_pis
                     , null  aliq_pis
                     , null  vl_pis
                     , b.vl_bc_cofins
                     , b.aliq_cofins
                     , b.vl_cofins
                     , b.planoconta_id
                     , b.natrecpc_id
                     , cs2.cod_st
                  from ct_comp_doc_cofins b
                     , cod_st             cs2
                 where cs2.id             = b.codst_id
                   and b.conhectransp_id  = en_conhectransp_id )
       order by id;
   --
begin
   --
   vn_fase := 1;
   --
   vv_cnpj_cpf := pk_csf.fkg_cnpj_ou_cpf_empresa (en_empresa_id);
   --
   for rec in c_Conhec_Transp_Imp_Out loop
      exit when c_Conhec_Transp_Imp_Out%notfound or c_Conhec_Transp_Imp_Out%notfound is null;
      --
      -- Verifica se o imposto é PIS para chamar a rotina
      if rec.cod_imp = 4 then
         --
         vn_fase := 2;
         --
          pk_csf_api_ct.gt_row_ct_compdoc_pis                    := null;
          pk_csf_api_ct.gt_row_ct_compdoc_pis.conhectransp_id    := en_conhectransp_id;
          pk_csf_api_ct.gt_row_ct_compdoc_pis.dm_ind_nat_frt     := rec.dm_ind_nat_frt;
          pk_csf_api_ct.gt_row_ct_compdoc_pis.vl_item            := rec.vl_item;
          pk_csf_api_ct.gt_row_ct_compdoc_pis.vl_bc_pis          := rec.vl_bc_pis;
          pk_csf_api_ct.gt_row_ct_compdoc_pis.aliq_pis           := rec.aliq_pis;
          pk_csf_api_ct.gt_row_ct_compdoc_pis.vl_pis             := rec.vl_pis;
          --
          vn_fase := 8;
          --
          -- Chama procedimento que integra as informações relativas ao Imposto PIS
          pk_csf_api_ct.pkb_integr_ctimpout_pis ( est_log_generico            => est_log_generico
                                                , est_row_ct_comp_doc_pis     => pk_csf_api_ct.gt_row_ct_compdoc_pis
                                                , ev_cpf_cnpj_emit            => vv_cnpj_cpf
                                                , ev_cod_st                   => rec.cod_st
                                                , ev_cod_bc_cred_pc           => pk_csf_efd_pc.fkg_base_calc_cred_pc_id(rec.basecalccredpc_id) -- rec.vl_bc_pis
                                                , ev_cod_cta                  => pk_csf.fkg_cd_plano_conta (rec.planoconta_id)
                                                , en_multorg_id               => gn_multorg_id );
         --
      -- Verifica se o imposto é COFINS para chamar a rotina
      elsif rec.cod_imp = 5 then
         --
         vn_fase := 9;
         -- Chama procedimento que integra as informações relativas ao Imposto COFINS
         pk_csf_api_ct.gt_row_ct_compdoc_cofins                    := null;
         pk_csf_api_ct.gt_row_ct_compdoc_cofins.conhectransp_id    := en_conhectransp_id;
         pk_csf_api_ct.gt_row_ct_compdoc_cofins.dm_ind_nat_frt     := rec.dm_ind_nat_frt;
         pk_csf_api_ct.gt_row_ct_compdoc_cofins.vl_item            := rec.vl_item;
         pk_csf_api_ct.gt_row_ct_compdoc_cofins.vl_bc_cofins       := rec.vl_bc_cofins;
         pk_csf_api_ct.gt_row_ct_compdoc_cofins.aliq_cofins        := rec.aliq_cofins;
         pk_csf_api_ct.gt_row_ct_compdoc_cofins.vl_cofins          := rec.vl_cofins;
         --
         vn_fase := 10;
         --
         pk_csf_api_ct.pkb_integr_ctimpout_cofins ( est_log_generico         => est_log_generico
                                                  , est_ct_comp_doc_cofins   => pk_csf_api_ct.gt_row_ct_compdoc_cofins
                                                  , ev_cpf_cnpj_emit         => vv_cnpj_cpf
                                                  , ev_cod_st                => rec.cod_st
                                                  , ev_cod_bc_cred_pc        => pk_csf_efd_pc.fkg_base_calc_cred_pc_id(rec.basecalccredpc_id) -- rec.vl_bc_cofins
                                                  , ev_cod_cta               => pk_csf.fkg_cd_plano_conta (rec.planoconta_id)
                                                  , en_multorg_id            => gn_multorg_id );
      --
      -- Os outros impostos integrados pela VW_CSF_CONHEC_TRANSP_IMP_OUT não tratados geram log p análise
      end if;
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pk_valida_ambiente.pkb_ler_conhec_transp_imp_out fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_conhec_transp_imp_out;
--
-- ============================================================================================================================== --
--
-- Procedimento faz a leitura das Informações dos Componentes do Valor da Prestação

procedure pkb_ler_Ctvlprest_Comp ( est_log_generico             in   out nocopy  dbms_sql.number_table
                                 , en_conhectranspvlprest_id    in   Conhec_Transp_Vlprest.id%TYPE
                                 , en_conhectransp_id           in   Conhec_Transp.id%TYPE)
is

   cursor c_Ctvlprest_Comp is
   select ad.*
     from Ctvlprest_Comp  ad
    where ad.conhectranspvlprest_id = en_conhectranspvlprest_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctvlprest_Comp loop
      exit when c_Ctvlprest_Comp%notfound or c_Ctvlprest_Comp%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_imp := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_imp.id                  := rec.id;
      pk_csf_api_ct.gt_row_ctvlprest_comp.conhectranspvlprest_id := rec.conhectranspvlprest_id;
      pk_csf_api_ct.gt_row_ctvlprest_comp.nome                   := rec.nome;
      pk_csf_api_ct.gt_row_ctvlprest_comp.valor                  := rec.valor;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações dos Componentes do Valor da Prestação
      pk_csf_api_ct.pkb_integr_ctvlprest_comp( est_log_generico       => est_log_generico
                                             , est_row_ctvlprest_comp => pk_csf_api_ct.gt_row_ctvlprest_comp
                                             , en_conhectransp_id     => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctvlprest_Comp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctvlprest_Comp;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações dos Valores da Prestação de Serviço

procedure pkb_ler_Conhec_Transp_Vlprest ( est_log_generico             in   out nocopy  dbms_sql.number_table
                                        , en_conhectransp_id           in   Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Vlprest is
   select ad.*
     from Conhec_Transp_Vlprest  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Vlprest loop
      exit when c_Conhec_Transp_Vlprest%notfound or c_Conhec_Transp_Vlprest%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_vlprest := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_vlprest.id                  := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_vlprest.conhectransp_id     := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_vlprest.vl_prest_serv       := rec.vl_prest_serv;
      pk_csf_api_ct.gt_row_conhec_transp_vlprest.vl_receb            := rec.vl_receb;
      pk_csf_api_ct.gt_row_conhec_transp_vlprest.vl_docto_fiscal     := rec.vl_docto_fiscal;
      pk_csf_api_ct.gt_row_conhec_transp_vlprest.vl_desc             := rec.vl_desc;
      pk_csf_api_ct.gt_row_conhec_transp_vlprest.vl_tot_trib         := rec.vl_tot_trib;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações dos Valores da Prestação de Serviço
      pk_csf_api_ct.pkb_integr_ct_vlprest( est_log_generico   => est_log_generico
                                         , est_row_ct_vlprest => pk_csf_api_ct.gt_row_conhec_transp_vlprest
                                         , en_conhectransp_id => en_conhectransp_id );
      vn_fase := 5;
      --Lê as informações referentes aos Valores da Prestação de Serviço
      pkb_ler_Ctvlprest_Comp ( est_log_generico           => est_log_generico
                             , en_conhectranspvlprest_id  => rec.id
                             , en_conhectransp_id         => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Vlprest fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Vlprest;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do Local de Entrega constante na Nota Fiscal

procedure pkb_ler_Ctdest_Locent ( est_log_generico        in   out nocopy  dbms_sql.number_table
                                , en_conhectranspdest_id  in   Conhec_Transp_Dest.id%TYPE
                                , en_conhectransp_id      in   Conhec_Transp.id%TYPE)
is

   cursor c_Ctdest_Locent is
   select ad.*
     from Ctdest_Locent  ad
    where ad.conhectranspdest_id = en_conhectranspdest_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctdest_Locent loop
      exit when c_Ctdest_Locent%notfound or c_Ctdest_Locent%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctdest_locent := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctdest_locent.id                  := rec.id;
      pk_csf_api_ct.gt_row_ctdest_locent.conhectranspdest_id := rec.conhectranspdest_id;
      pk_csf_api_ct.gt_row_ctdest_locent.cnpj                := rec.cnpj;
      pk_csf_api_ct.gt_row_ctdest_locent.cpf                 := rec.cpf;
      pk_csf_api_ct.gt_row_ctdest_locent.nome                := rec.nome;
      pk_csf_api_ct.gt_row_ctdest_locent.lograd              := rec.lograd;
      pk_csf_api_ct.gt_row_ctdest_locent.nro                 := rec.nro;
      pk_csf_api_ct.gt_row_ctdest_locent.compl               := rec.compl;
      pk_csf_api_ct.gt_row_ctdest_locent.bairro              := rec.bairro;
      pk_csf_api_ct.gt_row_ctdest_locent.ibge_cidade         := rec.ibge_cidade;
      pk_csf_api_ct.gt_row_ctdest_locent.descr_cidade        := rec.descr_cidade;
      pk_csf_api_ct.gt_row_ctdest_locent.uf                  := rec.uf;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do Local de Entrega constante na Nota Fiscal
      pk_csf_api_ct.pkb_integr_ctdest_locent( est_log_generico      => est_log_generico
                                            , est_row_ctdest_locent => pk_csf_api_ct.gt_row_ctdest_locent
                                            , en_conhectransp_id    => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctdest_Locent fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctdest_Locent;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do Destinatário do CT

procedure pkb_ler_Conhec_Transp_Dest ( est_log_generico        in   out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id      in   Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Dest is
   select ad.*
     from Conhec_Transp_Dest  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Dest loop
      exit when c_Conhec_Transp_Dest%notfound or c_Conhec_Transp_Dest%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_dest := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_dest.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_dest.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_dest.cnpj            := rec.cnpj;
      pk_csf_api_ct.gt_row_conhec_transp_dest.cpf             := rec.cpf;
      pk_csf_api_ct.gt_row_conhec_transp_dest.ie              := rec.ie;
      pk_csf_api_ct.gt_row_conhec_transp_dest.nome            := rec.nome;
      pk_csf_api_ct.gt_row_conhec_transp_dest.fone            := rec.fone;
      pk_csf_api_ct.gt_row_conhec_transp_dest.suframa         := rec.suframa;
      pk_csf_api_ct.gt_row_conhec_transp_dest.lograd          := rec.lograd;
      pk_csf_api_ct.gt_row_conhec_transp_dest.nro             := rec.nro;
      pk_csf_api_ct.gt_row_conhec_transp_dest.compl           := rec.compl;
      pk_csf_api_ct.gt_row_conhec_transp_dest.bairro          := rec.bairro;
      pk_csf_api_ct.gt_row_conhec_transp_dest.ibge_cidade     := rec.ibge_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_dest.descr_cidade    := rec.descr_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_dest.cep             := rec.cep;
      pk_csf_api_ct.gt_row_conhec_transp_dest.uf              := rec.uf;
      pk_csf_api_ct.gt_row_conhec_transp_dest.cod_pais        := rec.cod_pais;
      pk_csf_api_ct.gt_row_conhec_transp_dest.descr_pais      := rec.descr_pais;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do Local de Entrega constante na Nota Fiscal
      pk_csf_api_ct.pkb_integr_conhec_transp_dest( est_log_generico           => est_log_generico
                                                 , est_row_conhec_transp_dest => pk_csf_api_ct.gt_row_conhec_transp_dest
                                                 , en_conhectransp_id         => en_conhectransp_id );
      --
      vn_fase := 5;
      --Lê as informações referente ao Local de Entrega constante na Nota Fiscal
      pkb_ler_Ctdest_Locent ( est_log_generico        => est_log_generico
                            , en_conhectranspdest_id  => rec.id
                            , en_conhectransp_id      => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Dest fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Dest;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do Recebedor da Carga

procedure pkb_ler_Conhec_Transp_Receb ( est_log_generico        in   out nocopy  dbms_sql.number_table
                                      , en_conhectransp_id      in   Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Receb is
   select ad.*
     from Conhec_Transp_Receb  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Receb loop
      exit when c_Conhec_Transp_Receb%notfound or c_Conhec_Transp_Receb%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_receb := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_receb.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_receb.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_receb.cnpj            := rec.cnpj;
      pk_csf_api_ct.gt_row_conhec_transp_receb.cpf             := rec.cpf;
      pk_csf_api_ct.gt_row_conhec_transp_receb.ie              := rec.ie;
      pk_csf_api_ct.gt_row_conhec_transp_receb.nome            := rec.nome;
      pk_csf_api_ct.gt_row_conhec_transp_receb.nome_fant       := rec.nome_fant;
      pk_csf_api_ct.gt_row_conhec_transp_receb.fone            := rec.fone;
      pk_csf_api_ct.gt_row_conhec_transp_receb.lograd          := rec.lograd;
      pk_csf_api_ct.gt_row_conhec_transp_receb.nro             := rec.nro;
      pk_csf_api_ct.gt_row_conhec_transp_receb.compl           := rec.compl;
      pk_csf_api_ct.gt_row_conhec_transp_receb.bairro          := rec.bairro;
      pk_csf_api_ct.gt_row_conhec_transp_receb.ibge_cidade     := rec.ibge_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_receb.descr_cidade    := rec.descr_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_receb.cep             := rec.cep;
      pk_csf_api_ct.gt_row_conhec_transp_receb.uf              := rec.uf;
      pk_csf_api_ct.gt_row_conhec_transp_receb.cod_pais        := rec.cod_pais;
      pk_csf_api_ct.gt_row_conhec_transp_receb.descr_pais      := rec.descr_pais;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do Recebedor da Carga
      pk_csf_api_ct.pkb_integr_conhec_transp_receb( est_log_generico            => est_log_generico
                                                  , est_row_conhec_transp_receb => pk_csf_api_ct.gt_row_conhec_transp_receb
                                                  , en_conhectransp_id          => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Receb fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Receb;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do Expedidor da Carga

procedure pkb_ler_Conhec_Transp_Exped ( est_log_generico        in   out nocopy  dbms_sql.number_table
                                      , en_conhectransp_id      in   Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Exped is
   select ad.*
     from Conhec_Transp_Exped  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Exped loop
      exit when c_Conhec_Transp_Exped%notfound or c_Conhec_Transp_Exped%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_exped := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_exped.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_exped.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_exped.cnpj            := rec.cnpj;
      pk_csf_api_ct.gt_row_conhec_transp_exped.cpf             := rec.cpf;
      pk_csf_api_ct.gt_row_conhec_transp_exped.ie              := rec.ie;
      pk_csf_api_ct.gt_row_conhec_transp_exped.nome            := rec.nome;
      pk_csf_api_ct.gt_row_conhec_transp_exped.nome_fant       := rec.nome_fant;
      pk_csf_api_ct.gt_row_conhec_transp_exped.fone            := rec.fone;
      pk_csf_api_ct.gt_row_conhec_transp_exped.lograd          := rec.lograd;
      pk_csf_api_ct.gt_row_conhec_transp_exped.nro             := rec.nro;
      pk_csf_api_ct.gt_row_conhec_transp_exped.compl           := rec.compl;
      pk_csf_api_ct.gt_row_conhec_transp_exped.bairro          := rec.bairro;
      pk_csf_api_ct.gt_row_conhec_transp_exped.ibge_cidade     := rec.ibge_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_exped.descr_cidade    := rec.descr_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_exped.cep             := rec.cep;
      pk_csf_api_ct.gt_row_conhec_transp_exped.uf              := rec.uf;
      pk_csf_api_ct.gt_row_conhec_transp_exped.cod_pais        := rec.cod_pais;
      pk_csf_api_ct.gt_row_conhec_transp_exped.descr_pais      := rec.descr_pais;

      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do Expedidor da Carga
      pk_csf_api_ct.pkb_integr_conhec_transp_exped( est_log_generico            => est_log_generico
                                                  , est_row_conhec_transp_exped => pk_csf_api_ct.gt_row_conhec_transp_exped
                                                  , en_conhectransp_id          => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Exped fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Exped;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do Expedidor da Carga

procedure pkb_ler_Ctrem_Inf_Outro ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                  , en_conhectransprem_id   in  Conhec_Transp_Rem.id%TYPE
                                  , en_conhectransp_id      in  Conhec_Transp.id%TYPE)
is

   cursor c_Ctrem_Inf_Outro is
   select ad.*
     from Ctrem_Inf_Outro  ad
    where ad.conhectransprem_id = en_conhectransprem_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrem_Inf_Outro loop
      exit when c_Ctrem_Inf_Outro%notfound or c_Ctrem_Inf_Outro%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrem_inf_outro := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrem_inf_outro.id                 := rec.id;
      pk_csf_api_ct.gt_row_ctrem_inf_outro.conhectransprem_id := rec.conhectransprem_id;
      pk_csf_api_ct.gt_row_ctrem_inf_outro.dm_tipo_doc        := rec.dm_tipo_doc;
      pk_csf_api_ct.gt_row_ctrem_inf_outro.descr_outros       := rec.descr_outros;
      pk_csf_api_ct.gt_row_ctrem_inf_outro.nro_docto          := rec.nro_docto;
      pk_csf_api_ct.gt_row_ctrem_inf_outro.dt_emissao         := rec.dt_emissao;
      pk_csf_api_ct.gt_row_ctrem_inf_outro.vl_doc_fisc        := rec.vl_doc_fisc;

      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do Expedidor da Carga
      pk_csf_api_ct.pkb_integr_ctrem_inf_outro( est_log_generico        => est_log_generico
                                              , est_row_ctrem_inf_outro => pk_csf_api_ct.gt_row_ctrem_inf_outro
                                              , en_conhectransp_id      => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrem_Inf_Outro fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrem_Inf_Outro;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações da NFe do remetente

procedure pkb_ler_Ctrem_Inf_Nfe ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                , en_conhectransprem_id   in  Conhec_Transp_Rem.id%TYPE
                                , en_conhectransp_id      in  Conhec_Transp.id%TYPE)
is

   cursor c_Ctrem_Inf_Nfe is
   select ad.*
     from Ctrem_Inf_Nfe  ad
    where ad.conhectransprem_id = en_conhectransprem_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrem_Inf_Nfe loop
      exit when c_Ctrem_Inf_Nfe%notfound or c_Ctrem_Inf_Nfe%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrem_inf_nfe := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrem_inf_nfe.id                 := rec.id;
      pk_csf_api_ct.gt_row_ctrem_inf_nfe.conhectransprem_id := rec.conhectransprem_id;
      pk_csf_api_ct.gt_row_ctrem_inf_nfe.nro_chave_nfe      := rec.nro_chave_nfe;
      pk_csf_api_ct.gt_row_ctrem_inf_nfe.pin                := rec.pin;

      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações da NFe do remetente
      pk_csf_api_ct.pkb_integr_ctrem_inf_nfe( est_log_generico      => est_log_generico
                                            , est_row_ctrem_inf_nfe => pk_csf_api_ct.gt_row_ctrem_inf_nfe
                                            , en_conhectransp_id    => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrem_Inf_Nfe fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrem_Inf_Nfe;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do Local de retirada constante na NF

procedure pkb_ler_Ctrem_Inf_Nf_Locret ( est_log_generico     in  out nocopy  dbms_sql.number_table
                                      , en_ctreminfnf_id     in  Ctrem_Inf_Nf.id%TYPE
                                      , en_conhectransp_id   in  Conhec_Transp.id%TYPE)
is

   cursor c_Ctrem_Inf_Nf_Locret is
   select ad.*
     from Ctrem_Inf_Nf_Locret  ad
    where ad.ctreminfnf_id = en_ctreminfnf_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrem_Inf_Nf_Locret loop
      exit when c_Ctrem_Inf_Nf_Locret%notfound or c_Ctrem_Inf_Nf_Locret%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.id            := rec.id;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.ctreminfnf_id := rec.ctreminfnf_id;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.cnpj          := rec.cnpj;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.cpf           := rec.cpf;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.nome          := rec.nome;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.lograd        := rec.lograd;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.nro           := rec.nro;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.compl         := rec.compl;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.bairro        := rec.bairro;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.ibge_cidade   := rec.ibge_cidade;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.descr_cidade  := rec.descr_cidade;
      pk_csf_api_ct.gt_row_ctrem_inf_nf_locret.uf            := rec.uf;

      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do Local de retirada constante na NF
      pk_csf_api_ct.pkb_integr_ctrem_inf_nf_locret( est_log_generico            => est_log_generico
                                                  , est_row_ctrem_inf_nf_locret => pk_csf_api_ct.gt_row_ctrem_inf_nf_locret
                                                  , en_conhectransp_id          => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrem_Inf_Nf_Locret fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrem_Inf_Nf_Locret;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações das NF do remetente

procedure pkb_ler_Ctrem_Inf_Nf ( est_log_generico       in  out nocopy  dbms_sql.number_table
                               , en_conhectransprem_id  in  Conhec_Transp_Rem.id%TYPE
                               , en_conhectransp_id     in  Conhec_Transp.id%TYPE)
is

   cursor c_Ctrem_Inf_Nf is
   select ad.*
        , mf.cod_mod
     from Ctrem_Inf_Nf  ad
        , mod_fiscal mf
    where ad.conhectransprem_id = en_conhectransprem_id
      and mf.id = ad.modfiscal_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ctrem_Inf_Nf loop
      exit when c_Ctrem_Inf_Nf%notfound or c_Ctrem_Inf_Nf%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrem_inf_nf := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ctrem_inf_nf.id                 := rec.id;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.conhectransprem_id := rec.conhectransprem_id;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.nro_roma_nf        := rec.nro_roma_nf;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.nro_ped_nf         := rec.nro_ped_nf;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.serie              := rec.serie;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.nro_nf             := rec.nro_nf;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.dt_emissao         := rec.dt_emissao;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.vl_bc_icms         := rec.vl_bc_icms;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.vl_icms            := rec.vl_icms;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.vl_bc_icmsst       := rec.vl_bc_icmsst;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.vl_icmsst          := rec.vl_icmsst;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.vl_total_prod      := rec.vl_total_prod;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.vl_total_nf        := rec.vl_total_nf;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.cfop               := rec.cfop;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.peso_kg            := rec.peso_kg;
      pk_csf_api_ct.gt_row_ctrem_inf_nf.pin                := rec.pin;
      --pk_csf_api_ct.gt_row_ctrem_inf_nf.modfiscal_id       := rec.modfiscal_id;

      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações das NF do remetente
      pk_csf_api_ct.pkb_integr_ctrem_inf_nf ( est_log_generico      =>  est_log_generico
                                            , est_row_ctrem_inf_nf  =>  pk_csf_api_ct.gt_row_ctrem_inf_nf
                                            , en_conhectransp_id    =>  en_ConhecTransp_id 
                                            , ev_cod_mod            =>  rec.cod_mod
                                            );
      --
      vn_fase := 5;
      --
      --Lê as referente as informações das NF do remetente
      pkb_ler_Ctrem_Inf_Nf_Locret ( est_log_generico     => est_log_generico
                                  , en_ctreminfnf_id     => rec.id
                                  , en_conhectransp_id   => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ctrem_Inf_Nf fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ctrem_Inf_Nf;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do Rateio das NF de Vagões.

procedure pkb_ler_Ct_Ferrov_Detvag_Nf ( est_log_generico       in  out nocopy  dbms_sql.number_table
                                      , ctferrovdetvag_id      in  Conhec_Transp_Rem.id%TYPE
                                      , en_conhectransp_id     in  Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Ferrov_Detvag_Nf is
   select ad.*
     from Ct_Ferrov_Detvag_Nf ad
    where ad.ctferrovdetvag_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Ferrov_Detvag_Nf loop
      exit when c_Ct_Ferrov_Detvag_Nf%notfound or c_Ct_Ferrov_Detvag_Nf%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nf := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nf.id                 := rec.id;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nf.ctferrovdetvag_id  := rec.ctferrovdetvag_id;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nf.serie              := rec.serie;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nf.nro_nf             := rec.nro_nf;
      pk_csf_api_ct.gt_row_ct_ferrov_detvag_nf.peso_rat           := rec.peso_rat;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações das NF do remetente
      pk_csf_api_ct.pkb_integr_ct_ferrov_detvag_nf( est_log_generico            => est_log_generico
                                                  , est_row_ct_ferrov_detvag_nf => pk_csf_api_ct.gt_row_ct_ferrov_detvag_nf
                                                  , en_conhectransp_id          => en_conhectransp_id);
      --
      vn_fase := 5;
      --
      --Lê as referente as informações das NF do remetente
      pkb_ler_Ctrem_Inf_Nf_Locret ( est_log_generico     => est_log_generico
                                  , en_ctreminfnf_id     => rec.id
                                  , en_conhectransp_id   => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Ferrov_Detvag_Nf fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Ferrov_Detvag_Nf;

-------------------------------------------------------------------------------------------------------

-- Procedimento faz a leitura do Local de Coleta do Remetente

procedure pkb_ler_ctrem_loc_colet ( est_log_generico       in  out nocopy  dbms_sql.number_table
                                  , en_conhectransprem_id  in  Conhec_Transp_Rem.id%type
                                  , en_conhectransp_id     in  Conhec_Transp.id%TYPE
                                  )
is
   --
   vn_fase               number := 0;
   --
   cursor c_lc is
   select ad.*
     from ctrem_loc_colet  ad
    where ad.conhectransprem_id = en_conhectransprem_id;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_lc loop
      exit when c_lc%notfound or (c_lc%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ctrem_loc_colet := null;
      --
      vn_fase := 2.1;
      --
      pk_csf_api_ct.gt_row_ctrem_loc_colet := rec;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.pkb_integr_ctrem_loc_colet ( est_log_generico         => est_log_generico
                                               , est_row_ctrem_loc_colet  => pk_csf_api_ct.gt_row_ctrem_loc_colet
                                               , en_conhectransp_id       => en_conhectransp_id
                                               );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ctrem_loc_colet fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ctrem_loc_colet;

-------------------------------------------------------------------------------------------------------

-- Procedimento faz a leitura das Informações do Remetente das mercadorias transportadas pelo CT

procedure pkb_ler_Conhec_Transp_Rem ( est_log_generico       in  out nocopy  dbms_sql.number_table
                                    , en_conhectransp_id     in  Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Rem is
   select ad.*
     from Conhec_Transp_Rem  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Rem loop
      exit when c_Conhec_Transp_Rem%notfound or c_Conhec_Transp_Rem%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_rem := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_rem.id                 := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_rem.conhectransp_id    := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_rem.cnpj               := rec.cnpj;
      pk_csf_api_ct.gt_row_conhec_transp_rem.cpf                := rec.cpf;
      pk_csf_api_ct.gt_row_conhec_transp_rem.ie                 := rec.ie;
      pk_csf_api_ct.gt_row_conhec_transp_rem.nome               := rec.nome;
      pk_csf_api_ct.gt_row_conhec_transp_rem.nome_fant          := rec.nome_fant;
      pk_csf_api_ct.gt_row_conhec_transp_rem.fone               := rec.fone;
      pk_csf_api_ct.gt_row_conhec_transp_rem.lograd             := rec.lograd;
      pk_csf_api_ct.gt_row_conhec_transp_rem.nro                := rec.nro;
      pk_csf_api_ct.gt_row_conhec_transp_rem.compl              := rec.compl;
      pk_csf_api_ct.gt_row_conhec_transp_rem.bairro             := rec.bairro;
      pk_csf_api_ct.gt_row_conhec_transp_rem.ibge_cidade        := rec.ibge_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_rem.descr_cidade       := rec.descr_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_rem.cep                := rec.cep;
      pk_csf_api_ct.gt_row_conhec_transp_rem.uf                 := rec.uf;
      pk_csf_api_ct.gt_row_conhec_transp_rem.cod_pais           := rec.cod_pais;
      pk_csf_api_ct.gt_row_conhec_transp_rem.descr_pais         := rec.descr_pais;


      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do Remetente das mercadorias transportadas pelo CT
      pk_csf_api_ct.pkb_integr_conhec_transp_rem( est_log_generico          => est_log_generico
                                                , est_row_conhec_transp_rem => pk_csf_api_ct.gt_row_conhec_transp_rem
                                                , en_conhectransp_id        => en_conhectransp_id);
      --
      vn_fase := 5;
      --Lê as informações referente ao Remetente das mercadorias transportadas pelo CT
      pkb_ler_Ctrem_Inf_Outro ( est_log_generico       => est_log_generico
                              , en_conhectransprem_id  => rec.id
                              , en_conhectransp_id     => en_conhectransp_id);
      --
      vn_fase := 5.1;
      --
      pkb_ler_Ctrem_Inf_Nfe ( est_log_generico        => est_log_generico
                            , en_conhectransprem_id   => rec.id
                            , en_conhectransp_id      => en_conhectransp_id);
      --
      vn_fase := 5.2;
      --
      pkb_ler_Ctrem_Inf_Nf ( est_log_generico       => est_log_generico
                           , en_conhectransprem_id  => rec.id
                           , en_conhectransp_id     => en_conhectransp_id);
      --
      vn_fase := 5.3;
      --
      pkb_ler_ctrem_loc_colet ( est_log_generico       => est_log_generico
                              , en_conhectransprem_id  => rec.id
                              , en_conhectransp_id     => en_conhectransp_id
                              );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Rem fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Rem;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do Emitente do CT

procedure pkb_ler_Conhec_Transp_Emit ( est_log_generico       in  out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id     in  Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Emit is
   select ad.*
     from Conhec_Transp_Emit  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Emit loop
      exit when c_Conhec_Transp_Emit%notfound or c_Conhec_Transp_Emit%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_emit := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_emit.id                := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_emit.conhectransp_id   := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_emit.cnpj              := rec.cnpj;
      pk_csf_api_ct.gt_row_conhec_transp_emit.ie                := rec.ie;
      pk_csf_api_ct.gt_row_conhec_transp_emit.nome              := rec.nome;
      pk_csf_api_ct.gt_row_conhec_transp_emit.nome_fant         := rec.nome_fant;
      pk_csf_api_ct.gt_row_conhec_transp_emit.lograd            := rec.lograd;
      pk_csf_api_ct.gt_row_conhec_transp_emit.nro               := rec.nro;
      pk_csf_api_ct.gt_row_conhec_transp_emit.compl             := rec.compl;
      pk_csf_api_ct.gt_row_conhec_transp_emit.bairro            := rec.bairro;
      pk_csf_api_ct.gt_row_conhec_transp_emit.ibge_cidade       := rec.ibge_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_emit.descr_cidade      := rec.descr_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_emit.cep               := rec.cep;
      pk_csf_api_ct.gt_row_conhec_transp_emit.uf                := rec.uf;
      pk_csf_api_ct.gt_row_conhec_transp_emit.cod_pais          := rec.cod_pais;
      pk_csf_api_ct.gt_row_conhec_transp_emit.descr_pais        := rec.descr_pais;
      pk_csf_api_ct.gt_row_conhec_transp_emit.fone              := rec.fone;


      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do Emitente do CT
      pk_csf_api_ct.pkb_integr_conhec_transp_emit( est_log_generico           => est_log_generico
                                                 , est_row_conhec_transp_emit => pk_csf_api_ct.gt_row_conhec_transp_emit
                                                 , en_conhectransp_id         => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Emit fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Emit;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações das Observações do Contribuinte/Fiscal

procedure pkb_ler_Ct_Compl_Obs ( est_log_generico        in  out nocopy  dbms_sql.number_table
                               , en_conhectranspcompl_id in Conhec_Transp_Compl.id%TYPE
                               , en_conhectransp_id      in  Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Compl_Obs is
   select ad.*
     from Ct_Compl_Obs  ad
    where ad.conhectranspcompl_id = en_conhectranspcompl_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Compl_Obs loop
      exit when c_Ct_Compl_Obs%notfound or c_Ct_Compl_Obs%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_compl_obs := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_compl_obs.id                   := rec.id;
      pk_csf_api_ct.gt_row_ct_compl_obs.conhectranspcompl_id := rec.conhectranspcompl_id;
      pk_csf_api_ct.gt_row_ct_compl_obs.dm_tipo              := rec.dm_tipo;
      pk_csf_api_ct.gt_row_ct_compl_obs.campo                := rec.campo;
      pk_csf_api_ct.gt_row_ct_compl_obs.texto                := rec.texto;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações das Observações do Contribuinte/Fiscal
      pk_csf_api_ct.pkb_integr_ct_compl_obs ( est_log_generico     => est_log_generico
                                            , est_row_ct_compl_obs => pk_csf_api_ct.gt_row_ct_compl_obs
                                            , en_conhectransp_id   => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Compl_Obs fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Compl_Obs;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Sigla ou código interno da Filial/Porto/Estação/Aeroporto de Passagem

procedure pkb_ler_Ct_Compl_Pass ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                , en_conhectranspcompl_id in Conhec_Transp_Compl.id%TYPE
                                , en_conhectransp_id      in  Conhec_Transp.id%TYPE)
is

   cursor c_Ct_Compl_Pass is
   select ad.*
     from Ct_Compl_Pass  ad
    where ad.conhectranspcompl_id = en_conhectranspcompl_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Ct_Compl_Pass loop
      exit when c_Ct_Compl_Pass%notfound or c_Ct_Compl_Pass%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_compl_pass := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_compl_pass.id                   := rec.id;
      pk_csf_api_ct.gt_row_ct_compl_pass.conhectranspcompl_id := rec.conhectranspcompl_id;
      pk_csf_api_ct.gt_row_ct_compl_pass.pass                 := rec.pass;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de Sigla ou código interno da Filial/Porto/Estação/Aeroporto de Passagem
      pk_csf_api_ct.pkb_integr_ct_compl_pass( est_log_generico      => est_log_generico
                                            , est_row_ct_compl_pass => pk_csf_api_ct.gt_row_ct_compl_pass
                                            , en_conhectransp_id    => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Ct_Compl_Pass fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Ct_Compl_Pass;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Dados complementares do CT-e para fins operacionais ou comerciais

procedure pkb_ler_Conhec_Transp_Compl ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                      , en_conhectransp_id      in  Conhec_Transp.id%TYPE)
is
   --
   cursor c_Conhec_Transp_Compl is
   select ad.*
     from Conhec_Transp_Compl  ad
    where ad.conhectransp_id = en_conhectransp_id;
   --
   vn_fase               number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Compl loop
      exit when c_Conhec_Transp_Compl%notfound or c_Conhec_Transp_Compl%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_compl := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_compl.id                := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_compl.conhectransp_id   := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_compl.carac_adic_transp := rec.carac_adic_transp;
      pk_csf_api_ct.gt_row_conhec_transp_compl.carac_adic_serv   := rec.carac_adic_serv;
      pk_csf_api_ct.gt_row_conhec_transp_compl.emitente          := rec.emitente;
      pk_csf_api_ct.gt_row_conhec_transp_compl.orig_fluxo        := rec.orig_fluxo;
      pk_csf_api_ct.gt_row_conhec_transp_compl.dest_fluxo        := rec.dest_fluxo;
      pk_csf_api_ct.gt_row_conhec_transp_compl.rota_fluxo        := rec.rota_fluxo;
      pk_csf_api_ct.gt_row_conhec_transp_compl.dm_tp_per_entr    := rec.dm_tp_per_entr;
      pk_csf_api_ct.gt_row_conhec_transp_compl.dt_prog           := rec.dt_prog;
      pk_csf_api_ct.gt_row_conhec_transp_compl.dt_ini            := rec.dt_ini;
      pk_csf_api_ct.gt_row_conhec_transp_compl.dt_fim            := rec.dt_fim;
      pk_csf_api_ct.gt_row_conhec_transp_compl.dm_tp_hor_entr    := rec.dm_tp_hor_entr;
      pk_csf_api_ct.gt_row_conhec_transp_compl.hora_prog         := rec.hora_prog;
      pk_csf_api_ct.gt_row_conhec_transp_compl.hora_ini          := rec.hora_ini;
      pk_csf_api_ct.gt_row_conhec_transp_compl.hora_fim          := rec.hora_fim;
      pk_csf_api_ct.gt_row_conhec_transp_compl.orig_calc_frete   := rec.orig_calc_frete;
      pk_csf_api_ct.gt_row_conhec_transp_compl.dest_calc_frete   := rec.dest_calc_frete;
      pk_csf_api_ct.gt_row_conhec_transp_compl.obs_geral         := rec.obs_geral;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de Dados complementares do CT-e para fins operacionais ou comerciais
      pk_csf_api_ct.pkb_integr_conhec_transp_compl( est_log_generico            => est_log_generico
                                                  , est_row_conhec_transp_compl => pk_csf_api_ct.gt_row_conhec_transp_compl
                                                  , en_conhectransp_id          => en_conhectransp_id);
      --
      vn_fase := 5;
      --Lê as informações referentes aos Dados complementares do CT-e para fins operacionais ou comerciais
      pkb_ler_Ct_Compl_Obs ( est_log_generico        => est_log_generico
                           , en_conhectranspcompl_id => rec.id
                           , en_conhectransp_id      => en_conhectransp_id);
      --
      pkb_ler_Ct_Compl_Pass ( est_log_generico        => est_log_generico
                            , en_conhectranspcompl_id => rec.id
                            , en_conhectransp_id      => en_conhectransp_id);
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Compl fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Compl;
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do "papel" do tomador do serviço no CT-e, pessoa que o serviço foi prestado

procedure pkb_ler_Conhec_Transp_Tomador ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                        , en_conhectransp_id      in  Conhec_Transp.id%TYPE)
is

   cursor c_Conhec_Transp_Tomador is
   select ad.*
     from Conhec_Transp_Tomador  ad
    where ad.conhectransp_id = en_conhectransp_id;

   vn_fase               number := 0;

begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Tomador loop
      exit when c_Conhec_Transp_Tomador%notfound or c_Conhec_Transp_Tomador%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_tomador := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_tomador.id                := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.conhectransp_id   := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.cnpj              := rec.cnpj;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.cpf               := rec.cpf;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.ie                := rec.ie;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.nome              := rec.nome;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.nome_fant         := rec.nome_fant;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.fone              := rec.fone;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.lograd            := rec.lograd;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.nro               := rec.nro;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.compl             := rec.compl;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.bairro            := rec.bairro;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.ibge_cidade       := rec.ibge_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.descr_cidade      := rec.descr_cidade;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.cep               := rec.cep;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.uf                := rec.uf;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.cod_pais          := rec.cod_pais;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.descr_pais        := rec.descr_pais;
      pk_csf_api_ct.gt_row_conhec_transp_tomador.email             := rec.email;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do "papel" do tomador do serviço no CT-e, pessoa que o serviço foi prestado
      pk_csf_api_ct.pkb_integr_ct_tomador( est_log_generico   => est_log_generico
                                         , est_row_ct_tomador => pk_csf_api_ct.gt_row_conhec_transp_tomador
                                         , en_conhectransp_id => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Tomador fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Tomador;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações dos dados das Duplicatas do CTe.

procedure pkb_ler_conhec_transp_dup ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                    , en_conhectransp_id      in  conhec_transp.id%TYPE)
is
   --
   cursor c_conhectranspdup is
   select ctd.*
     from conhec_transp_dup  ctd
    where ctd.conhectransp_id = en_conhectransp_id;
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_conhectranspdup loop
      exit when c_conhectranspdup%notfound or (c_conhectranspdup%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_dup := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_dup.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_dup.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_dup.nro_dup         := rec.nro_dup;
      pk_csf_api_ct.gt_row_conhec_transp_dup.dt_venc         := rec.dt_venc;
      pk_csf_api_ct.gt_row_conhec_transp_dup.vl_dup          := rec.vl_dup;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do "papel" do tomador do serviço no CT-e, pessoa que o serviço foi prestado
      pk_csf_api_ct.pkb_integr_conhec_transp_dup ( est_log_generico          => est_log_generico
                                                 , est_row_conhec_transp_dup => pk_csf_api_ct.gt_row_conhec_transp_dup );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_conhec_transp_dup fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_conhec_transp_dup;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações dos dados da fatura CT-e

procedure pkb_ler_conhec_transp_fat ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                    , en_conhectransp_id      in  conhec_transp.id%TYPE)
is
   --
   cursor c_conhectranspfat is
   select ctf.*
     from conhec_transp_fat  ctf
    where ctf.conhectransp_id = en_conhectransp_id;
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_conhectranspfat loop
      exit when c_conhectranspfat%notfound or (c_conhectranspfat%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_fat := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_fat.id              := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_fat.conhectransp_id := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_fat.nro_fat         := rec.nro_fat;
      pk_csf_api_ct.gt_row_conhec_transp_fat.vl_orig         := rec.vl_orig;
      pk_csf_api_ct.gt_row_conhec_transp_fat.vl_desc         := rec.vl_desc;
      pk_csf_api_ct.gt_row_conhec_transp_fat.vl_liq          := rec.vl_liq;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações do "papel" do tomador do serviço no CT-e, pessoa que o serviço foi prestado
      pk_csf_api_ct.pkb_integr_conhec_transp_fat ( est_log_generico          => est_log_generico
                                                 , est_row_conhec_transp_fat => pk_csf_api_ct.gt_row_conhec_transp_fat );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_conhec_transp_fat fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_conhec_transp_fat;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações dos dados participantes autorizados a fazer downloado do XML

procedure pkb_ler_ct_aut_xml ( est_log_generico        in  out nocopy  dbms_sql.number_table
                             , en_conhectransp_id      in  conhec_transp.id%TYPE
                             )
is
   --
   cursor c_dados is
   select ctf.*
     from ct_aut_xml  ctf
    where ctf.conhectransp_id = en_conhectransp_id;
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_aut_xml := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_aut_xml := rec;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_aut_xml ( est_log_generico      => est_log_generico
                                          , est_row_ct_aut_xml    => pk_csf_api_ct.gt_row_ct_aut_xml
                                          );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_aut_xml fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_aut_xml;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do relaacionamento da NF com Unidade de Carga

procedure pkb_ler_r_nf_infunidcarga ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                    , en_ctinfnf_id           in  ct_inf_nf.id%type
                                    , en_conhectransp_id      in  conhec_transp.id%TYPE
                                    )
is
   --
   cursor c_dados is
   select *
     from r_ctinfnf_ctinfunidcarga
    where ctinfnf_id = en_ctinfnf_id;
   --
   vn_fase       number := 0;
   --
   vv_cod_mod_nf               mod_fiscal.cod_mod%type;
   vv_serie_nf                 ct_inf_nf.serie%type;
   vn_nro_nf                   ct_inf_nf.nro_nf%type;
   vn_dm_tp_unid_carga         ct_inf_unid_carga.dm_tp_unid_carga%type;
   vv_ident_unid_carga         ct_inf_unid_carga.ident_unid_carga%type;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_r_ctinfnf_ctinfuc := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_r_ctinfnf_ctinfuc := rec;
      --
      vn_fase := 3.1;
      --
      begin
         --
         select mf.cod_mod
              , inf.serie
              , inf.nro_nf
           into vv_cod_mod_nf
              , vv_serie_nf
              , vn_nro_nf
           from ct_inf_nf   inf
              , mod_fiscal  mf
          where inf.id      = rec.ctinfnf_id
            and mf.id       = inf.modfiscal_id;
         --
      exception
         when others then 
            vv_cod_mod_nf  := null;
            vv_serie_nf    := null;
            vn_nro_nf      := null;
      end;
      --
      vn_fase := 3.2;
      --
      begin
         --
         select dm_tp_unid_carga
              , ident_unid_carga
           into vn_dm_tp_unid_carga
              , vv_ident_unid_carga
           from ct_inf_unid_carga
          where id = rec.ctinfunidcarga_id;
         --
      exception
         when others then
            vn_dm_tp_unid_carga  := null;
            vv_ident_unid_carga  := null;
      end;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_r_nf_infunidcarga ( est_log_generico            => est_log_generico
                                                 , est_row_r_nf_infunidcarga   => pk_csf_api_ct.gt_row_r_ctinfnf_ctinfuc
                                                 , en_conhectransp_id          => en_conhectransp_id
                                                 , ev_cod_mod_nf               => vv_cod_mod_nf
                                                 , ev_serie_nf                 => vv_serie_nf
                                                 , en_nro_nf                   => vn_nro_nf
                                                 , en_dm_tp_unid_carga         => vn_dm_tp_unid_carga
                                                 , ev_ident_unid_carga         => vv_ident_unid_carga
                                                 );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_r_nf_infunidcarga fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_r_nf_infunidcarga;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do relaacionamento da NF com Unidade de Tranporte

procedure pkb_ler_r_nf_infunidtransp ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                     , en_ctinfnf_id           in  ct_inf_nf.id%type
                                     , en_conhectransp_id      in  conhec_transp.id%TYPE
                                     )
is
   --
   cursor c_dados is
   select *
     from r_ctinfnf_ctinfunidtransp
    where ctinfnf_id = en_ctinfnf_id;
   --
   vn_fase       number := 0;
   --
   vv_cod_mod_nf               mod_fiscal.cod_mod%type;
   vv_serie_nf                 ct_inf_nf.serie%type;
   vn_nro_nf                   ct_inf_nf.nro_nf%type;
   vn_dm_tp_unid_transp        ct_inf_unid_transp.dm_tp_unid_transp%type;
   vv_ident_unid_transp        ct_inf_unid_transp.ident_unid_transp%type;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_r_ctinfnf_ctinfut := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_r_ctinfnf_ctinfut := rec;
      --
      vn_fase := 3.1;
      --
      begin
         --
         select mf.cod_mod
              , inf.serie
              , inf.nro_nf
           into vv_cod_mod_nf
              , vv_serie_nf
              , vn_nro_nf
           from ct_inf_nf   inf
              , mod_fiscal  mf
          where inf.id      = rec.ctinfnf_id
            and mf.id       = inf.modfiscal_id;
         --
      exception
         when others then 
            vv_cod_mod_nf  := null;
            vv_serie_nf    := null;
            vn_nro_nf      := null;
      end;
      --
      vn_fase := 3.2;
      --
      begin
         --
         select dm_tp_unid_transp
              , ident_unid_transp
           into vn_dm_tp_unid_transp
              , vv_ident_unid_transp
           from ct_inf_unid_transp
          where id = rec.ctinfunidtransp_id;
         --
      exception
         when others then
            vn_dm_tp_unid_transp  := null;
            vv_ident_unid_transp  := null;
      end;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_r_nf_infunidtransp ( est_log_generico            => est_log_generico
                                                  , est_row_r_nf_infunidtransp  => pk_csf_api_ct.gt_row_r_ctinfnf_ctinfut
                                                  , en_conhectransp_id          => en_conhectransp_id
                                                  , ev_cod_mod_nf               => vv_cod_mod_nf
                                                  , ev_serie_nf                 => vv_serie_nf
                                                  , en_nro_nf                   => vn_nro_nf
                                                  , en_dm_tp_unid_transp        => vn_dm_tp_unid_transp
                                                  , ev_ident_unid_transp        => vv_ident_unid_transp
                                                  );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_r_nf_infunidtransp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_r_nf_infunidtransp;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de NOta Fiscal

procedure pkb_ler_ct_inf_nf ( est_log_generico        in  out nocopy  dbms_sql.number_table
                            , en_conhectransp_id      in  conhec_transp.id%TYPE
                            )
is
   --
   cursor c_dados is
   select ctf.*
     from ct_inf_nf  ctf
    where ctf.conhectransp_id = en_conhectransp_id;
   --
   vn_fase       number := 0;
   vv_cod_mod    Mod_Fiscal.cod_mod%type;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_inf_nf := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_inf_nf := rec;
      --
      vn_fase := 3.1;
      --
      vv_cod_mod := pk_csf.fkg_cod_mod_id ( en_modfiscal_id => rec.modfiscal_id );
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_inf_nf ( est_log_generico      => est_log_generico
                                         , est_row_ct_inf_nf     => pk_csf_api_ct.gt_row_ct_inf_nf
                                         , ev_cod_mod            => vv_cod_mod
                                         );
      --
      vn_fase := 5;
      --
      pkb_ler_r_nf_infunidtransp ( est_log_generico    => est_log_generico
                                 , en_ctinfnf_id       => rec.id
                                 , en_conhectransp_id  => en_conhectransp_id
                                 );
      --
      vn_fase := 6;
      --
      pkb_ler_r_nf_infunidcarga ( est_log_generico    => est_log_generico
                                , en_ctinfnf_id       => rec.id
                                , en_conhectransp_id  => en_conhectransp_id
                                );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_inf_nf fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_inf_nf;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do relaacionamento da NF com Unidade de Carga

procedure pkb_ler_r_nfe_infunidcarga ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                     , en_ctinfnfe_id          in  ct_inf_nfe.id%type
                                     , en_conhectransp_id      in  conhec_transp.id%TYPE
                                     )
is
   --
   cursor c_dados is
   select *
     from r_ctinfnfe_ctinfunidcarga
    where ctinfnfe_id = en_ctinfnfe_id;
   --
   vn_fase       number := 0;
   --
   vv_nro_chave_nfe            ct_inf_nfe.nro_chave_nfe%type;
   vn_dm_tp_unid_carga         ct_inf_unid_carga.dm_tp_unid_carga%type;
   vv_ident_unid_carga         ct_inf_unid_carga.ident_unid_carga%type;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_r_ctinfnfe_ctinfuc := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_r_ctinfnfe_ctinfuc := rec;
      --
      vn_fase := 3.1;
      --
      begin
         --
         select inf.nro_chave_nfe
           into vv_nro_chave_nfe
           from ct_inf_nfe   inf
          where inf.id      = rec.ctinfnfe_id;
         --
      exception
         when others then 
            vv_nro_chave_nfe  := null;
      end;
      --
      vn_fase := 3.2;
      --
      begin
         --
         select dm_tp_unid_carga
              , ident_unid_carga
           into vn_dm_tp_unid_carga
              , vv_ident_unid_carga
           from ct_inf_unid_carga
          where id = rec.ctinfunidcarga_id;
         --
      exception
         when others then
            vn_dm_tp_unid_carga  := null;
            vv_ident_unid_carga  := null;
      end;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_r_nfe_infunidcarga ( est_log_generico            => est_log_generico
                                                  , est_row_r_nfe_infunidcarga  => pk_csf_api_ct.gt_row_r_ctinfnfe_ctinfuc
                                                  , en_conhectransp_id          => en_conhectransp_id
                                                  , ev_nro_chave_nfe            => vv_nro_chave_nfe
                                                  , en_dm_tp_unid_carga         => vn_dm_tp_unid_carga
                                                  , ev_ident_unid_carga         => vv_ident_unid_carga
                                                  );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_r_nfe_infunidcarga fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_r_nfe_infunidcarga;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do relaacionamento da NFe com Unidade de Tranporte

procedure pkb_ler_r_nfe_infunidtransp ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                      , en_ctinfnfe_id          in  ct_inf_nfe.id%type
                                      , en_conhectransp_id      in  conhec_transp.id%TYPE
                                      )
is
   --
   cursor c_dados is
   select *
     from r_ctinfnfe_ctinfunidtransp
    where ctinfnfe_id = en_ctinfnfe_id;
   --
   vn_fase       number := 0;
   --
   vv_nro_chave_nfe            ct_inf_nfe.nro_chave_nfe%type;
   vn_dm_tp_unid_transp        ct_inf_unid_transp.dm_tp_unid_transp%type;
   vv_ident_unid_transp        ct_inf_unid_transp.ident_unid_transp%type;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_r_ctinfnfe_ctinfut := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_r_ctinfnfe_ctinfut := rec;
      --
      vn_fase := 3.1;
      --
      begin
         --
         select inf.nro_chave_nfe
           into vv_nro_chave_nfe
           from ct_inf_nfe   inf
          where inf.id      = rec.ctinfnfe_id;
         --
      exception
         when others then 
            vv_nro_chave_nfe  := null;
      end;
      --
      vn_fase := 3.2;
      --
      begin
         --
         select dm_tp_unid_transp
              , ident_unid_transp
           into vn_dm_tp_unid_transp
              , vv_ident_unid_transp
           from ct_inf_unid_transp
          where id = rec.ctinfunidtransp_id;
         --
      exception
         when others then
            vn_dm_tp_unid_transp  := null;
            vv_ident_unid_transp  := null;
      end;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_r_nfe_infunidtransp ( est_log_generico              => est_log_generico
                                                   , est_row_r_nfe_infunidtransp   => pk_csf_api_ct.gt_row_r_ctinfnfe_ctinfut
                                                   , en_conhectransp_id            => en_conhectransp_id
                                                   , ev_nro_chave_nfe              => vv_nro_chave_nfe
                                                   , en_dm_tp_unid_transp          => vn_dm_tp_unid_transp
                                                   , ev_ident_unid_transp          => vv_ident_unid_transp
                                                   );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_r_nfe_infunidtransp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_r_nfe_infunidtransp;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de NFe

procedure pkb_ler_ct_inf_nfe ( est_log_generico        in  out nocopy  dbms_sql.number_table
                             , en_conhectransp_id      in  conhec_transp.id%TYPE
                             )
is
   --
   cursor c_dados is
   select ctf.*
     from ct_inf_nfe  ctf
    where ctf.conhectransp_id = en_conhectransp_id;
   --
   vn_fase       number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_inf_nfe := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_inf_nfe := rec;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_inf_nfe ( est_log_generico       => est_log_generico
                                          , est_row_ct_inf_nfe     => pk_csf_api_ct.gt_row_ct_inf_nfe
                                          );
      --
      vn_fase := 5;
      --
      pkb_ler_r_nfe_infunidtransp ( est_log_generico        => est_log_generico
                                  , en_ctinfnfe_id          => rec.id
                                  , en_conhectransp_id      => en_conhectransp_id
                                  );
      --
      vn_fase := 6;
      --
      pkb_ler_r_nfe_infunidcarga ( est_log_generico        => est_log_generico
                                 , en_ctinfnfe_id          => rec.id
                                 , en_conhectransp_id      => en_conhectransp_id
                                 );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_inf_nfe fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_inf_nfe;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do relaacionamento da Outros Documentos com Unidade de Carga

procedure pkb_ler_r_outro_infunidcarga ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                       , en_ctinfoutro_id        in  ct_inf_outro.id%type
                                       , en_conhectransp_id      in  conhec_transp.id%TYPE
                                       )
is
   --
   cursor c_dados is
   select *
     from r_ctinfoutro_ctinfunidcarga
    where ctinfoutro_id = en_ctinfoutro_id;
   --
   vn_fase number := 0;
   --
   vv_dm_tipo_doc              ct_inf_outro.dm_tipo_doc%type;
   vv_nro_docto                ct_inf_outro.nro_docto%type;
   vn_dm_tp_unid_carga         ct_inf_unid_carga.dm_tp_unid_carga%type;
   vv_ident_unid_carga         ct_inf_unid_carga.ident_unid_carga%type;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_r_ctinfoutro_ctinfuc := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_r_ctinfoutro_ctinfuc := rec;
      --
      vn_fase := 3.1;
      --
      begin
         --
         select dm_tipo_doc
              , nro_docto
           into vv_dm_tipo_doc
              , vv_nro_docto
           from ct_inf_outro
          where id = rec.ctinfoutro_id;
         --
      exception
         when others then 
            vv_dm_tipo_doc  := null;
            vv_nro_docto    := null;
      end;
      --
      vn_fase := 3.2;
      --
      begin
         --
         select dm_tp_unid_carga
              , ident_unid_carga
           into vn_dm_tp_unid_carga
              , vv_ident_unid_carga
           from ct_inf_unid_carga
          where id = rec.ctinfunidcarga_id;
         --
      exception
         when others then
            vn_dm_tp_unid_carga  := null;
            vv_ident_unid_carga  := null;
      end;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_r_outro_infuc ( est_log_generico              => est_log_generico
                                             , est_row_r_outro_infunidcarga  => pk_csf_api_ct.gt_row_r_ctinfoutro_ctinfuc
                                             , en_conhectransp_id            => en_conhectransp_id
                                             , ev_dm_tipo_doc                => vv_dm_tipo_doc
                                             , ev_nro_docto                  => vv_nro_docto
                                             , en_dm_tp_unid_carga           => vn_dm_tp_unid_carga
                                             , ev_ident_unid_carga           => vv_ident_unid_carga
                                             );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_r_outro_infunidcarga fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_r_outro_infunidcarga;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações do relaacionamento da Outros Documentos com Unidade de Tranporte

procedure pkb_ler_r_outro_infunidtransp ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                        , en_ctinfoutro_id        in  ct_inf_outro.id%type
                                        , en_conhectransp_id      in  conhec_transp.id%TYPE
                                        )
is
   --
   cursor c_dados is
   select *
     from r_ctinfoutro_ctinfunidtransp
    where ctinfoutro_id = en_ctinfoutro_id;
   --
   vn_fase  number := 0;
   --
   vv_dm_tipo_doc              ct_inf_outro.dm_tipo_doc%type;
   vv_nro_docto                ct_inf_outro.nro_docto%type;
   vn_dm_tp_unid_transp        ct_inf_unid_transp.dm_tp_unid_transp%type;
   vv_ident_unid_transp        ct_inf_unid_transp.ident_unid_transp%type;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_r_ctinfoutro_ctinfut := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_r_ctinfoutro_ctinfut := rec;
      --
      vn_fase := 3.1;
      --
      begin
         --
         select dm_tipo_doc
              , nro_docto
           into vv_dm_tipo_doc
              , vv_nro_docto
           from ct_inf_outro
          where id = rec.ctinfoutro_id;
         --
      exception
         when others then 
            vv_dm_tipo_doc  := null;
            vv_nro_docto    := null;
      end;
      --
      vn_fase := 3.2;
      --
      begin
         --
         select dm_tp_unid_transp
              , ident_unid_transp
           into vn_dm_tp_unid_transp
              , vv_ident_unid_transp
           from ct_inf_unid_transp
          where id = rec.ctinfunidtransp_id;
         --
      exception
         when others then
            vn_dm_tp_unid_transp  := null;
            vv_ident_unid_transp  := null;
      end;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_r_outro_infut ( est_log_generico                => est_log_generico
                                             , est_row_r_outro_infunidtransp   => pk_csf_api_ct.gt_row_r_ctinfoutro_ctinfut
                                             , en_conhectransp_id              => en_conhectransp_id
                                             , ev_dm_tipo_doc                  => vv_dm_tipo_doc
                                             , ev_nro_docto                    => vv_nro_docto
                                             , en_dm_tp_unid_transp            => vn_dm_tp_unid_transp
                                             , ev_ident_unid_transp            => vv_ident_unid_transp
                                             );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_r_outro_infunidtransp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_r_outro_infunidtransp;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Outros Documentos

procedure pkb_ler_ct_inf_outro ( est_log_generico        in  out nocopy  dbms_sql.number_table
                               , en_conhectransp_id      in  conhec_transp.id%TYPE
                               )
is
   --
   cursor c_dados is
   select ctf.*
     from ct_inf_outro  ctf
    where ctf.conhectransp_id = en_conhectransp_id;
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_inf_outro := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_inf_outro := rec;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_inf_outro ( est_log_generico       => est_log_generico
                                            , est_row_ct_inf_outro   => pk_csf_api_ct.gt_row_ct_inf_outro
                                            );
      --
      vn_fase := 5;
      --
      pkb_ler_r_outro_infunidtransp ( est_log_generico        => est_log_generico
                                    , en_ctinfoutro_id        => rec.id
                                    , en_conhectransp_id      => en_conhectransp_id
                                    );
      --
      vn_fase := 6;
      --
      pkb_ler_r_outro_infunidcarga ( est_log_generico        => est_log_generico
                                   , en_ctinfoutro_id        => rec.id
                                   , en_conhectransp_id      => en_conhectransp_id
                                   );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_inf_outro fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_inf_outro;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Lacres da Carga da Unidade de Transporte

procedure pkb_ler_ct_iut_carga_lacre ( est_log_generico             in  out nocopy  dbms_sql.number_table
                                     , en_ctinfunidtranspcarga_id   in  ct_inf_unid_transp.id%type
                                     , en_conhectransp_id           in  conhec_transp.id%TYPE
                                     )
is
   --
   cursor c_dados is
   select *
     from ct_iut_carga_lacre
    where ctinfunidtranspcarga_id = en_ctinfunidtranspcarga_id;
   --
   vn_fase       number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_iut_carga_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_iut_carga_lacre := rec;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_iut_carga_lacre ( est_log_generico               => est_log_generico
                                                  , est_row_ct_iut_carga_lacre     => pk_csf_api_ct.gt_row_ct_iut_carga_lacre
                                                  , en_conhectransp_id             => en_conhectransp_id
                                                  );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_iut_carga_lacre fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_iut_carga_lacre;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Cargas da Unidade de Transporte

procedure pkb_ler_ct_iut_carga ( est_log_generico        in  out nocopy  dbms_sql.number_table
                               , en_ctinfunidtransp_id   in  ct_inf_unid_transp.id%type
                               , en_conhectransp_id      in  conhec_transp.id%TYPE
                               )
is
   --
   cursor c_dados is
   select *
     from ct_inf_unid_transp_carga
    where ctinfunidtransp_id = en_ctinfunidtransp_id;
   --
   vn_fase       number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_inf_ut_carga := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_inf_ut_carga := rec;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_iut_carga ( est_log_generico         => est_log_generico
                                            , est_row_ct_iut_carga     => pk_csf_api_ct.gt_row_ct_inf_ut_carga
                                            , en_conhectransp_id       => en_conhectransp_id
                                            );
      --
      vn_fase := 5;
      --
      pkb_ler_ct_iut_carga_lacre ( est_log_generico             => est_log_generico
                                 , en_ctinfunidtranspcarga_id   => rec.id
                                 , en_conhectransp_id           => en_conhectransp_id
                                 );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_iut_carga fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_iut_carga;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de LAcres da Unidade de Transporte

procedure pkb_ler_ct_iut_lacre ( est_log_generico        in  out nocopy  dbms_sql.number_table
                               , en_ctinfunidtransp_id   in  ct_inf_unid_transp.id%type
                               , en_conhectransp_id      in  conhec_transp.id%TYPE
                               )
is
   --
   cursor c_dados is
   select *
     from ct_inf_unid_transp_lacre
    where ctinfunidtransp_id = en_ctinfunidtransp_id;
   --
   vn_fase       number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_inf_ut_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_inf_ut_lacre := rec;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_iut_lacre ( est_log_generico         => est_log_generico
                                            , est_row_ct_iut_lacre     => pk_csf_api_ct.gt_row_ct_inf_ut_lacre
                                            , en_conhectransp_id       => en_conhectransp_id
                                            );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_iut_lacre fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_iut_lacre;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Unidade de Transporte

procedure pkb_ler_ct_inf_unid_transp ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                     , en_conhectransp_id      in  conhec_transp.id%TYPE
                                     )
is
   --
   cursor c_dados is
   select *
     from ct_inf_unid_transp
    where conhectransp_id = en_conhectransp_id;
   --
   vn_fase       number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_inf_unid_transp := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_inf_unid_transp := rec;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_inf_unid_transp ( est_log_generico             => est_log_generico
                                                  , est_row_ct_inf_unid_transp   => pk_csf_api_ct.gt_row_ct_inf_unid_transp
                                                  );
      --
      vn_fase := 5;
      --
      pkb_ler_ct_iut_lacre ( est_log_generico        => est_log_generico
                           , en_ctinfunidtransp_id   => rec.id
                           , en_conhectransp_id      => en_conhectransp_id
                           );
      --
      vn_fase := 6;
      --
      pkb_ler_ct_iut_carga ( est_log_generico        => est_log_generico
                           , en_ctinfunidtransp_id   => rec.id
                           , en_conhectransp_id      => en_conhectransp_id
                           );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_inf_unid_transp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_inf_unid_transp;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Unidade de Carga

procedure pkb_ler_ct_iuc_carga ( est_log_generico        in  out nocopy  dbms_sql.number_table
                               , en_ctinfunidcarga_id    in  ct_inf_unid_carga.id%type
                               , en_conhectransp_id      in  conhec_transp.id%TYPE
                               )
is
   --
   cursor c_dados is
   select *
     from ct_inf_unid_carga_lacre
    where ctinfunidcarga_id = en_ctinfunidcarga_id;
   --
   vn_fase       number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_inf_uc_lacre := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_inf_uc_lacre := rec;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_ct_iuc_lacre ( est_log_generico         => est_log_generico
                                               , est_row_ct_iuc_lacre     => pk_csf_api_ct.gt_row_ct_inf_uc_lacre
                                               , en_conhectransp_id       => en_conhectransp_id
                                               );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_iuc_carga fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_iuc_carga;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Unidade de Carga

procedure pkb_ler_ct_inf_unid_carga ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                    , en_conhectransp_id      in  conhec_transp.id%TYPE
                                    )
is
   --
   cursor c_dados is
   select *
     from ct_inf_unid_carga
    where conhectransp_id = en_conhectransp_id;
   --
   vn_fase       number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_inf_unid_carga := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_inf_unid_carga := rec;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_inf_unid_carga ( est_log_generico            => est_log_generico
                                                 , est_row_ct_inf_unid_carga   => pk_csf_api_ct.gt_row_ct_inf_unid_carga
                                                 );
      --
      vn_fase := 5;
      --
      pkb_ler_ct_iuc_carga ( est_log_generico        => est_log_generico
                           , en_ctinfunidcarga_id    => rec.id
                           , en_conhectransp_id      => en_conhectransp_id
                           );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_inf_unid_carga fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_inf_unid_carga;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações de Multimodal

procedure pkb_ler_ct_multimodal ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                , en_conhectransp_id      in  conhec_transp.id%TYPE
                                )
is
   --
   cursor c_dados is
   select *
     from ct_multimodal
    where conhectransp_id = en_conhectransp_id;
   --
   vn_fase            number := 0;
   vv_cod_part_consg  pessoa.cod_part%type;
   vv_cod_part_red    pessoa.cod_part%type;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_multimodal := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_multimodal := rec;
      --
      vn_fase := 3.1;
      --
      vv_cod_part_consg := pk_csf.fkg_pessoa_id_cod_part ( en_multorg_id => gn_multorg_id
                                                         , ev_cod_part   => rec.pessoa_id_consg );
      --
      vn_fase := 3.2;
      --
      vv_cod_part_red := pk_csf.fkg_pessoa_id_cod_part ( en_multorg_id => gn_multorg_id
                                                       , ev_cod_part   => rec.pessoa_id_red );
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_integr_ct_multimodal ( est_log_generico      => est_log_generico
                                             , est_row_ct_multimodal => pk_csf_api_ct.gt_row_ct_multimodal
                                             , ev_cod_part_consg     => vv_cod_part_consg
                                             , ev_cod_part_red       => vv_cod_part_red
                                             , en_multorg_id         => gn_multorg_id
                                             );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_multimodal fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => en_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_multimodal;

-------------------------------------------------------------------------------------------------------
-- Procedimento de leitura das Informações do ICMS de partilha com a UF de término do serviço de transporte na operação interestadual. - Atualização CTe 3.0

procedure pkb_ler_ct_part_icms ( est_log_generico        in  out nocopy  dbms_sql.number_table
                               , en_conhectransp_id      in  conhec_transp.id%TYPE
                               )
is
   --
   cursor c_dados is
   select *
     from conhec_transp_part_icms
    where conhectransp_id = en_conhectransp_id;
   --
   vn_fase            number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_part_icms := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_part_icms := rec;
      --
      vn_fase := 4;
      --
      -- Chama procedimento que integra as Informações do ICMS de partilha com a UF de término do serviço de transporte na operação interestadual
      pk_csf_api_ct.pkb_integr_ct_part_icms ( est_log_generico      => est_log_generico
                                            , est_row_ct_part_icms  => pk_csf_api_ct.gt_row_conhec_transp_part_icms
                                            , en_conhectransp_id    => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_part_icms fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_part_icms;

-------------------------------------------------------------------------------------------------------
-- Procedimento de leitura das Informações do CT-e multimodal vinculado. - Atualização CTe 3.0

procedure pkb_ler_ct_inf_vinc_mult ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                   , en_conhectransp_id      in  conhec_transp.id%TYPE
                                   )
is
   --
   cursor c_dados is
   select *
     from ct_inf_vinc_mult
    where conhectransp_id = en_conhectransp_id;
   --
   vn_fase            number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_inf_vinc_mult := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_inf_vinc_mult := rec;
      --
      vn_fase := 4;
      --
      -- Chama procedimento que integra as Informações do CT-e multimodal vinculado
      pk_csf_api_ct.pkb_integr_ct_inf_vinc_mult ( est_log_generico          => est_log_generico
                                                , est_row_ct_inf_vinc_mult  => pk_csf_api_ct.gt_row_ct_inf_vinc_mult
                                                , en_conhectransp_id        => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_inf_vinc_mult fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_inf_vinc_mult;

-------------------------------------------------------------------------------------------------------
-- Procedimento de leitura das Informações do Percurso do CT-e Outros Serviços. - Atualização CTe 3.0

procedure pkb_ler_conhec_transp_percurso ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                         , en_conhectransp_id      in  conhec_transp.id%TYPE
                                         )
is
   --
   cursor c_dados is
   select *
     from conhec_transp_percurso
    where conhectransp_id = en_conhectransp_id;
   --
   vn_fase            number := 0;
   vv_sigla_estado    estado.sigla_estado%type;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_percurso := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_percurso := rec;
      --
      vn_fase := 4;
      --
      vv_sigla_estado := pk_csf.fkg_estado_id_sigla (rec.estado_id);
      --
      vn_fase := 5;
      --
      -- Chama procedimento que integra as Informações do Percurso do CT-e Outros Serviços
      pk_csf_api_ct.pkb_integr_ct_transp_percurso ( est_log_generico            => est_log_generico
                                                  , est_row_ct_transp_percurso  => pk_csf_api_ct.gt_row_conhec_transp_percurso
                                                  , ev_sigla_estado             => vv_sigla_estado
                                                  , en_conhectransp_id          => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_conhec_transp_percurso fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_conhec_transp_percurso;

-------------------------------------------------------------------------------------------------------
-- Procedimento de leitura das Informações dos documentos referenciados CTe Outros Serviços. - Atualização CTe 3.0

procedure pkb_ler_ct_doc_ref_os ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                , en_conhectransp_id      in  conhec_transp.id%TYPE
                                )
is
   --
   cursor c_dados is
   select *
     from ct_doc_ref_os
    where conhectransp_id = en_conhectransp_id;
   --
   vn_fase            number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_ct_doc_ref_os := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_ct_doc_ref_os := rec;
      --
      vn_fase := 4;
      --
      -- Chama procedimento que integra as Informações dos documentos referenciados CTe Outros Serviços
      pk_csf_api_ct.pkb_integr_ct_doc_ref_os ( est_log_generico       => est_log_generico
                                             , est_row_ct_doc_ref_os  => pk_csf_api_ct.gt_row_ct_doc_ref_os
                                             , en_conhectransp_id     => en_conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_doc_ref_os fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_doc_ref_os;
--
-- ====================================================================================================== --
-- Procedimento faz a leitura informações de envio de e-mail do CTe
--
procedure pkb_ler_conhec_transp_email ( est_log_generico      in out nocopy  dbms_sql.number_table
                                      , en_conhectransp_id    in             Conhec_Transp.id%TYPE) is
   --
   cursor c_Conhec_Transp_email is
      select ad.*
        from conhec_transp_email ad
       where ad.conhectransp_id = en_conhectransp_id;
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_email loop
      exit when c_Conhec_Transp_email%notfound or c_Conhec_Transp_email%notfound is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_conhec_transp_email := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_email.conhectransp_id  := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_email.dm_origem        := rec.dm_origem;
      pk_csf_api_ct.gt_row_conhec_transp_email.email            := rec.email;
      pk_csf_api_ct.gt_row_conhec_transp_email.dm_tipo_anexo    := rec.dm_tipo_anexo;
      pk_csf_api_ct.gt_row_conhec_transp_email.dm_st_email      := rec.dm_st_email;
      --
      vn_fase := 4;
      -- Chama procedimento que valida as Informações de email do CTE
      pk_csf_api_ct.pkb_integr_conhec_transp_email ( est_log_generico   => est_log_generico
                                                   , est_row_ct_email   => pk_csf_api_ct.gt_row_conhec_transp_email
                                                   );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_email fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_email;
--
-- ====================================================================================================== --
-- Procedimento faz a leitura das Informações dos registros de Conhecimento de Transporte
procedure pkb_ler_Conhec_Transp ( en_conhectransp_id  in conhec_transp.id%type
                                , en_loteintws_id     in lote_int_ws.id%type default 0
                                )
is
   --
   cursor c_Conhec_Transp is
   select ct.*
        , mf.cod_mod
        , so.sigla      sist_orig
        , uo.cd         unid_org
     from Conhec_Transp ct
        , Mod_Fiscal    mf
        , sist_orig     so
        , unid_org      uo
    where ct.id          = en_conhectransp_id
      and mf.id          = ct.modfiscal_id
      and so.id(+)       = ct.sistorig_id
      and uo.id(+)       = ct.unidorg_id
      and not exists ( select 1 
                         from Conhec_Transp_Canc ctc
                        where ctc.conhectransp_id = ct.id 
                          and ctc.dm_canc_servico = 1)
    order by ct.id;
   --
   vn_fase               number := 0;
   vt_log_generico       dbms_sql.number_table;
   vn_conhectransp_id    Conhec_Transp.id%TYPE;
   vn_dm_st_proc         conhec_transp.dm_st_proc%type;
   vn_integra            number := 1;
   --
begin
   --
   vn_fase := 1;
   -- Lê as CT-e e faz o processo de validação encadeado
   for rec in c_Conhec_Transp loop
      exit when c_Conhec_Transp%notfound or c_Conhec_Transp%notfound is null;
      --
      vn_fase := 2;
      --
      vn_dm_st_proc := null;
      --
      gn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => rec.empresa_id );
      -- limpa o array quando inicia um novo CT-e
      vt_log_generico.delete;
      --
      pk_csf_api_ct.gt_row_conhec_transp := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.pkb_seta_referencia_id ( en_id => rec.id );
      --
      vn_fase := 3.1;
      --
      pk_csf_api_ct.gt_row_conhec_transp.id  := rec.id;
      --
      vn_conhectransp_id := rec.id;
      --
      pk_csf_api_ct.gt_row_conhec_transp.dt_hr_ent_sist               := rec.dt_hr_ent_sist;
      pk_csf_api_ct.gt_row_conhec_transp.empresa_id                   := rec.empresa_id;
      pk_csf_api_ct.gt_row_conhec_transp.lotecte_id                   := rec.lotecte_id;
      pk_csf_api_ct.gt_row_conhec_transp.inutilizaconhectransp_id     := rec.inutilizaconhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp.pessoa_id                    := rec.pessoa_id;
      pk_csf_api_ct.gt_row_conhec_transp.sitdocto_id                  := rec.sitdocto_id;
      pk_csf_api_ct.gt_row_conhec_transp.versao                       := rec.versao;
      pk_csf_api_ct.gt_row_conhec_transp.id_tag_cte                   := rec.id_tag_cte;
      pk_csf_api_ct.gt_row_conhec_transp.uf_ibge_emit                 := rec.uf_ibge_emit;
      pk_csf_api_ct.gt_row_conhec_transp.cct_cte                      := rec.cct_cte;
      pk_csf_api_ct.gt_row_conhec_transp.cfop                         := rec.cfop;
      pk_csf_api_ct.gt_row_conhec_transp.cfop_id                      := rec.cfop_id;
      pk_csf_api_ct.gt_row_conhec_transp.nat_oper                     := rec.nat_oper;
      pk_csf_api_ct.gt_row_conhec_transp.dm_for_pag                   := rec.dm_for_pag;
      pk_csf_api_ct.gt_row_conhec_transp.modfiscal_id                 := rec.modfiscal_id;
      pk_csf_api_ct.gt_row_conhec_transp.serie                        := rec.serie;
      pk_csf_api_ct.gt_row_conhec_transp.subserie                     := rec.subserie;
      pk_csf_api_ct.gt_row_conhec_transp.nro_ct                       := rec.nro_ct;
      pk_csf_api_ct.gt_row_conhec_transp.dt_hr_emissao                := rec.dt_hr_emissao;
      pk_csf_api_ct.gt_row_conhec_transp.dm_tp_imp                    := rec.dm_tp_imp;
      pk_csf_api_ct.gt_row_conhec_transp.dm_forma_emiss               := rec.dm_forma_emiss;
      pk_csf_api_ct.gt_row_conhec_transp.dig_verif_chave              := rec.dig_verif_chave;
      pk_csf_api_ct.gt_row_conhec_transp.nro_chave_cte                := rec.nro_chave_cte;
      pk_csf_api_ct.gt_row_conhec_transp.dm_tp_amb                    := rec.dm_tp_amb;
      pk_csf_api_ct.gt_row_conhec_transp.dm_tp_cte                    := rec.dm_tp_cte;
      pk_csf_api_ct.gt_row_conhec_transp.dm_proc_emiss                := rec.dm_proc_emiss;
      pk_csf_api_ct.gt_row_conhec_transp.vers_apl_cte                 := rec.vers_apl_cte;
      pk_csf_api_ct.gt_row_conhec_transp.chave_cte_ref                := rec.chave_cte_ref;
      pk_csf_api_ct.gt_row_conhec_transp.ibge_cidade_emit             := rec.ibge_cidade_emit;
      --
      --recupera dados para a rec.descr_cidade_emit e rec.sigla_uf_emit
      begin
       select c.descr descr_cidade_emit
            , uf.sigla_estado sigla_uf_emit
         into pk_csf_api_ct.gt_row_conhec_transp.descr_cidade_emit
             ,pk_csf_api_ct.gt_row_conhec_transp.sigla_uf_emit
         from cidade c, estado uf
        where c.estado_id = uf.id
          and c.ibge_cidade = rec.ibge_cidade_emit;
      exception
        when others then
          --
      pk_csf_api_ct.gt_row_conhec_transp.descr_cidade_emit            := rec.descr_cidade_emit;
      pk_csf_api_ct.gt_row_conhec_transp.sigla_uf_emit                := rec.sigla_uf_emit;
          --
          pk_csf_api_ct.gv_cabec_log    := 'Não encontrada a descrição e uf da cidade do emitente com base no IBGE_CIDADE_EMIT: '|| rec.ibge_cidade_emit ||', pkb_ler_Conhec_Transp fase(' || vn_fase || '): ' || sqlerrm;
          pk_csf_api_ct.gv_mensagem_log := 'Não encontrada a descrição e uf da cidade do emitente com base no IBGE_CIDADE_EMIT: '|| rec.ibge_cidade_emit ||', pkb_ler_Conhec_Transp fase(' || vn_fase || '): ' || sqlerrm;
          --
          declare
             vn_loggenerico_id  log_generico_ct.id%TYPE;
          begin
             --
             pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                            , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                            , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                            , en_tipo_log        => pk_csf_api_ct.INFORMACAO
                                            , en_referencia_id   => vn_conhectransp_id
                                            , ev_obj_referencia  => 'CONHEC_TRANSP' );
             --
          exception
             when others then
                null;
          end;
      end;
      --
      pk_csf_api_ct.gt_row_conhec_transp.dm_modal                     := rec.dm_modal;
      pk_csf_api_ct.gt_row_conhec_transp.dm_tp_serv                   := rec.dm_tp_serv;
      pk_csf_api_ct.gt_row_conhec_transp.ibge_cidade_ini              := rec.ibge_cidade_ini;
      pk_csf_api_ct.gt_row_conhec_transp.descr_cidade_ini             := rec.descr_cidade_ini;
      pk_csf_api_ct.gt_row_conhec_transp.sigla_uf_ini                 := rec.sigla_uf_ini;
      pk_csf_api_ct.gt_row_conhec_transp.ibge_cidade_fim              := rec.ibge_cidade_fim;
      pk_csf_api_ct.gt_row_conhec_transp.descr_cidade_fim             := rec.descr_cidade_fim;
      pk_csf_api_ct.gt_row_conhec_transp.sigla_uf_fim                 := rec.sigla_uf_fim;
      pk_csf_api_ct.gt_row_conhec_transp.dm_retira                    := rec.dm_retira;
      pk_csf_api_ct.gt_row_conhec_transp.det_retira                   := rec.det_retira;
      pk_csf_api_ct.gt_row_conhec_transp.dm_tomador                   := rec.dm_tomador;
      pk_csf_api_ct.gt_row_conhec_transp.inf_adic_fisco               := rec.inf_adic_fisco;
      pk_csf_api_ct.gt_row_conhec_transp.dm_st_proc                   := rec.dm_st_proc;
      pk_csf_api_ct.gt_row_conhec_transp.dt_st_proc                   := rec.dt_st_proc;
      pk_csf_api_ct.gt_row_conhec_transp.dm_impressa                  := rec.dm_impressa;
      pk_csf_api_ct.gt_row_conhec_transp.dm_st_email                  := rec.dm_st_email;
      pk_csf_api_ct.gt_row_conhec_transp.dm_st_integra                := rec.dm_st_integra;
      pk_csf_api_ct.gt_row_conhec_transp.dm_aut_sefaz                 := rec.dm_aut_sefaz;
      pk_csf_api_ct.gt_row_conhec_transp.dt_aut_sefaz                 := rec.dt_aut_sefaz;
      pk_csf_api_ct.gt_row_conhec_transp.id_usuario_erp               := rec.id_usuario_erp;
      pk_csf_api_ct.gt_row_conhec_transp.usuario_id                   := rec.usuario_id;
      pk_csf_api_ct.gt_row_conhec_transp.impressora_id                := rec.impressora_id;
      pk_csf_api_ct.gt_row_conhec_transp.vias_dacte_custom            := rec.vias_dacte_custom;
      pk_csf_api_ct.gt_row_conhec_transp.nro_tentativas_impr          := rec.nro_tentativas_impr;
      pk_csf_api_ct.gt_row_conhec_transp.dt_ult_tenta_impr            := rec.dt_ult_tenta_impr;
      pk_csf_api_ct.gt_row_conhec_transp.vers_apl                     := rec.vers_apl;
      pk_csf_api_ct.gt_row_conhec_transp.dt_hr_recbto                 := rec.dt_hr_recbto;
      pk_csf_api_ct.gt_row_conhec_transp.nro_protocolo                := rec.nro_protocolo;
      pk_csf_api_ct.gt_row_conhec_transp.digest_value                 := rec.digest_value;
      pk_csf_api_ct.gt_row_conhec_transp.msgwebserv_id                := rec.msgwebserv_id;
      pk_csf_api_ct.gt_row_conhec_transp.cod_msg                      := rec.cod_msg;
      pk_csf_api_ct.gt_row_conhec_transp.motivo_resp                  := rec.motivo_resp;
      pk_csf_api_ct.gt_row_conhec_transp.cte_proc_xml                 := rec.cte_proc_xml;
      pk_csf_api_ct.gt_row_conhec_transp.dm_ind_oper                  := rec.dm_ind_oper;
      pk_csf_api_ct.gt_row_conhec_transp.dm_ind_emit                  := rec.dm_ind_emit;
      pk_csf_api_ct.gt_row_conhec_transp.dm_ind_frt                   := rec.dm_ind_frt;
      pk_csf_api_ct.gt_row_conhec_transp.inforcompdctofiscal_id       := rec.inforcompdctofiscal_id;
      pk_csf_api_ct.gt_row_conhec_transp.cod_cta                      := rec.cod_cta;
      pk_csf_api_ct.gt_row_conhec_transp.dt_sai_ent                   := rec.dt_sai_ent;
      pk_csf_api_ct.gt_row_conhec_transp.dm_arm_cte_terc              := rec.dm_arm_cte_terc;
      pk_csf_api_ct.gt_row_conhec_transp.nro_carreg                   := rec.nro_carreg;
      pk_csf_api_ct.gt_row_conhec_transp.dm_legado                    := rec.dm_legado;
      pk_csf_api_ct.gt_row_conhec_transp.dm_global                    := rec.dm_global;      --Atualização CTe 3.0
      pk_csf_api_ct.gt_row_conhec_transp.dm_ind_ie_toma               := rec.dm_ind_ie_toma; --Atualização CTe 3.0
      pk_csf_api_ct.gt_row_conhec_transp.vl_tot_trib                  := rec.vl_tot_trib;    --Atualização CTe 3.0
      pk_csf_api_ct.gt_row_conhec_transp.obs_global                   := rec.obs_global;     --Atualização CTe 3.0
      pk_csf_api_ct.gt_row_conhec_transp.descr_serv                   := rec.descr_serv;     --Atualização CTe 3.0
      pk_csf_api_ct.gt_row_conhec_transp.qtde_carga_os                := rec.qtde_carga_os;  --Atualização CTe 3.0
      --
      vn_fase := 4;
      --
      -- Chama procedimento que valida as Informações dos registros de Conhecimento de Transporte
      pk_csf_api_ct.pkb_integr_conhec_transp( est_log_generico         => vt_log_generico
                                            , est_row_conhec_transp    => pk_csf_api_ct.gt_row_conhec_transp
                                            , ev_cod_mod               => rec.cod_mod
                                            , ev_cod_matriz            => null
                                            , ev_cod_filial            => null
                                            , ev_empresa_cpf_cnpj      => null
                                            , ev_cod_part              => null
                                            , ev_cd_sitdocto           => null
                                            , ev_cod_infor             => null
                                            , ev_sist_orig             => rec.sist_orig
                                            , ev_cod_unid_org          => rec.unid_org
                                            , en_multorg_id            => gn_multorg_id
                                            , en_empresaintegrbanco_id => null
                                            , en_loteintws_id          => en_loteintws_id
                                            , en_integra               => vn_integra
                                            );
      --
      -- Se o valor do parâmetro "vn_integra" for igual a "1" então integra as tabelas filhas, sendo "0" sai da rotina de integração
      if nvl(vn_integra,1) = 0 then
         --
         goto sair_integr;
         --
      end if;
      --
       vn_fase := 5;
       --Lê as informações referentes aos registros de Conhecimento de Transporte
       pkb_ler_Conhec_Transp_Emit ( est_log_generico   => vt_log_generico
                                  , en_conhectransp_id => rec.id);
       --
       vn_fase := 6;
       pkb_ler_Conhec_Transp_Rem ( est_log_generico   => vt_log_generico
                                 , en_conhectransp_id => rec.id);
       --
       vn_fase := 7;
       pkb_ler_Conhec_Transp_Exped ( est_log_generico   => vt_log_generico
                                   , en_conhectransp_id => rec.id);
       --
       vn_fase := 8;
       pkb_ler_Conhec_Transp_Receb ( est_log_generico   => vt_log_generico
                                   , en_conhectransp_id => rec.id);
       --
       vn_fase := 9;
       pkb_ler_Conhec_Transp_Dest ( est_log_generico   => vt_log_generico
                                  , en_conhectransp_id => rec.id);
       --
       pkb_ler_Conhec_Transp_Compl ( est_log_generico   => vt_log_generico
                                   , en_conhectransp_id => rec.id);
       --
       vn_fase := 10;
       pkb_ler_Conhec_Transp_Vlprest ( est_log_generico   => vt_log_generico
                                     , en_conhectransp_id => rec.id);
       --
       vn_fase := 11;
       pkb_ler_Conhec_Transp_Imp ( est_log_generico   => vt_log_generico
                                 , en_conhectransp_id => rec.id);
       --
       vn_fase := 12;
       pkb_ler_Conhec_Transp_Infcarga ( est_log_generico   => vt_log_generico
                                      , en_conhectransp_id => rec.id);
       --
       vn_fase := 13;
       pkb_ler_Conhec_Transp_Cont ( est_log_generico    => vt_log_generico
                                  , en_conhectransp_id  => rec.id);
       --
       vn_fase := 14;
       pkb_ler_Conhec_Transp_Docant ( est_log_generico   => vt_log_generico
                                    , en_conhectransp_id => rec.id);
       --
       vn_fase := 15;
       pkb_ler_Conhec_Transp_Seg ( est_log_generico   => vt_log_generico
                                 , en_conhectransp_id => rec.id);
       --
       vn_fase := 16;
       pkb_ler_Conhec_Transp_Rodo ( est_log_generico   => vt_log_generico
                                  , en_conhectransp_id => rec.id);
       --
       vn_fase := 17;
       -- Atualização CTe 3.0
       pkb_ler_ct_rodo_os ( est_log_generico   => vt_log_generico
                          , en_conhectransp_id => rec.id);
       --
       vn_fase := 18;
       pkb_ler_Conhec_Transp_Aereo ( est_log_generico   => vt_log_generico
                                   , en_conhectransp_id => rec.id);
       --
       vn_fase := 19;
       pkb_ler_Conhec_Transp_Aquav ( est_log_generico   => vt_log_generico
                                   , en_conhectransp_id => rec.id);
       --
       vn_fase := 20;
       pkb_ler_Conhec_Transp_Ferrov ( est_log_generico   => vt_log_generico
                                    , en_conhectransp_id => rec.id);
       --
       vn_fase := 21;
       pkb_ler_Conhec_Transp_Duto ( est_log_generico   => vt_log_generico
                                  , en_conhectransp_id => rec.id);
       --
       vn_fase := 22;
       pkb_ler_Conhec_Transp_Peri ( est_log_generico   => vt_log_generico
                                  , en_conhectransp_id => rec.id);
       --
       vn_fase := 23;
       pkb_ler_Conhec_Transp_Veic ( est_log_generico   => vt_log_generico
                                  , en_conhectransp_id => rec.id);
       --
       vn_fase := 24;
       pkb_ler_Conhec_Transp_Subst ( est_log_generico   => vt_log_generico
                                   , en_conhectransp_id => rec.id);
       --
       vn_fase := 25;
       pkb_ler_Conhec_Transp_Anul ( est_log_generico   => vt_log_generico
                                  , en_conhectransp_id => rec.id);
       --
       vn_fase := 26;
       pkb_ler_Conhec_Transp_Impr ( est_log_generico   => vt_log_generico
                                  , en_conhectransp_id => rec.id);
       --
       vn_fase := 27;
       pkb_ler_Ct_Compltado ( est_log_generico    => vt_log_generico
                            , en_conhectransp_id  => rec.id);
       --
       vn_fase := 28;
       pkb_ler_ct_aut_xml ( est_log_generico    => vt_log_generico
                          , en_conhectransp_id  => rec.id);
       --
       vn_fase := 29;
       pkb_ler_ct_inf_nf ( est_log_generico    => vt_log_generico
                         , en_conhectransp_id  => rec.id);
       --
       vn_fase := 30;
       pkb_ler_ct_inf_nfe ( est_log_generico    => vt_log_generico
                          , en_conhectransp_id  => rec.id);
       --
       vn_fase := 31;
       pkb_ler_ct_inf_outro ( est_log_generico    => vt_log_generico
                            , en_conhectransp_id  => rec.id);
       --
       vn_fase := 32;
       pkb_ler_ct_inf_unid_transp ( est_log_generico    => vt_log_generico
                                  , en_conhectransp_id  => rec.id);
       --
       vn_fase := 33;
       pkb_ler_ct_inf_unid_carga ( est_log_generico    => vt_log_generico
                                 , en_conhectransp_id  => rec.id);
       --
       vn_fase := 34;
       pkb_ler_ct_multimodal ( est_log_generico    => vt_log_generico
                             , en_conhectransp_id  => rec.id);
       --
       vn_fase := 35;
       -- Atualização CTe 3.0
       pkb_ler_ct_part_icms ( est_log_generico    => vt_log_generico
                            , en_conhectransp_id  => rec.id);
       --
       vn_fase := 36;
       -- Atualização CTe 3.0
       pkb_ler_ct_inf_vinc_mult ( est_log_generico    => vt_log_generico
                                , en_conhectransp_id  => rec.id);
       --
       vn_fase := 37;
       -- Atualização CTe 3.0
       pkb_ler_conhec_transp_percurso ( est_log_generico    => vt_log_generico
                                      , en_conhectransp_id  => rec.id);
       --
       vn_fase := 38;
       -- Atualização CTe 3.0
       pkb_ler_ct_doc_ref_os ( est_log_generico    => vt_log_generico
                             , en_conhectransp_id  => rec.id);
       --
       vn_fase := 39;
       pkb_ler_Conhec_Transp_Imp_Out ( est_log_generico   => vt_log_generico
                                     , en_conhectransp_id => rec.id
                                     , en_empresa_id      => rec.empresa_id);
       --
       vn_fase := 40;
       pkb_ler_conhec_transp_email ( est_log_generico    => vt_log_generico
                                   , en_conhectransp_id  => rec.id);
       --
       vn_fase := 41;
       pkb_ler_conhec_transp_tomador ( est_log_generico    => vt_log_generico
                                     , en_conhectransp_id  => rec.id);
       --
       vn_fase := 42;
       pkb_ler_conhec_transp_fat ( est_log_generico    => vt_log_generico
                                 , en_conhectransp_id  => rec.id);
       --
       vn_fase := 43;
       pkb_ler_conhec_transp_dup ( est_log_generico    => vt_log_generico
                                 , en_conhectransp_id  => rec.id);
       --
       vn_fase := 99;
       --
       ---------------------------------------------------------------------------------------
       -- Processos que consistem a informação do conhecimento de transporte
       ---------------------------------------------------------------------------------------
       pk_csf_api_ct.pkb_consistem_ct ( est_log_generico     => vt_log_generico
                                      , en_conhectransp_id   => rec.id );
       --
       if rec.dm_ind_emit = 0 then -- Emissão Própria
          -- Se registrou algum log, altera o CT-e para dm_st_proc = 10 - "Erro de Validação"
          if nvl(vt_log_generico.count,0) > 0 then
             --
             vn_fase := 99.1;
             --
             begin
                --
                vn_fase := 99.2;
                --
                update Conhec_Transp
                   set dm_st_proc = 10
                     , dt_st_proc = sysdate
                 where id = rec.id;
                --
                commit;
                --
             exception
                when others then
                   --
                   pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp fase(' || vn_fase || '): ' || sqlerrm;
                   --
                   declare
                   vn_loggenerico_id  log_generico_ct.id%TYPE;

                   begin
                     --
                     pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                                       , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                                       , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                                       , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                                       , en_referencia_id   => vn_conhectransp_id
                                                       , ev_obj_referencia  => 'CONHEC_TRANSP' );
                     --
                   exception
                      when others then
                         null;
                   end;
                --
                raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
                --
             end;
          else
             -- Se não houve nenhum registro de ocorrência
             -- então atualiza o dm_st_proc para 1-Aguardando Envio
             vn_fase := 99.3;
             --
             if rec.dm_legado = 1 then --Legado Autorizado
                vn_dm_st_proc := 4;
             elsif rec.dm_legado = 2 then --Legado Denegado
                vn_dm_st_proc := 6;
             elsif rec.dm_legado = 3 then --Legado Cancelado
                vn_dm_st_proc := 7;
             elsif rec.dm_legado = 4 then --Legado Inutilizado
                vn_dm_st_proc := 8;
             else
                --
                if rec.dm_st_proc in (4, 5, 6, 7, 8) then
                   vn_dm_st_proc := rec.dm_st_proc;
                else
                   vn_dm_st_proc := 1;
                end if;
                --
             end if;
             --
             update Conhec_Transp
                set dm_st_proc = vn_dm_st_proc
                  , dt_st_proc = sysdate
              where id = rec.id;
             --
             commit;
             --
          end if;
          --
       else
          --| CT-e por terceiros, somente registra os erros de validação
          --| e regitra a Ct-e como Autorizada
          vn_fase := 99.4;
          --
          update Conhec_Transp
             set dm_st_proc = 4
               , dt_st_proc = sysdate
           where id = rec.id;
          --
          commit;
          --
       end if;
       --
   end loop;
   --
   <<sair_integr>>
   --
   pk_csf_api_ct.pkb_seta_referencia_id ( en_id => null );
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => vn_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp;
--
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura das Informações dos registros de Conhecimento de Transporte a serem validados
--
procedure pkb_ler_ct_integrados ( en_multorg_id in mult_org.id%type )
is
   --
   cursor c_Conhec_Transp ( en_multorg_id in mult_org.id%type ) is
      select ct.id conhectransp_id
        from empresa       em
           , Conhec_Transp ct
           , Mod_Fiscal    mf
           , sist_orig     so
           , unid_org      uo
       where em.multorg_id       = en_multorg_id
         and ct.empresa_id       = em.id
         and ct.dm_st_proc       = 0 -- Aguardando Validação
         and nvl(ct.dm_legado,0) = 0 -- Não é Legado
         and ct.dm_ind_emit      = 0 -- Emissão própria
         and ct.dm_arm_cte_terc  = 0
         and mf.id               = ct.modfiscal_id
         and so.id(+)            = ct.sistorig_id
         and uo.id(+)            = ct.unidorg_id
         and not exists ( select 1 from Conhec_Transp_Canc ctc
                           where ctc.conhectransp_id = ct.id );
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   -- Lê as CT-e e faz o processo de validação encadeado
   for rec in c_Conhec_Transp ( en_multorg_id => en_multorg_id ) loop
      --
      exit when c_Conhec_Transp%notfound or c_Conhec_Transp%notfound is null;
      --
      vn_fase := 2;
      --
      pkb_ler_Conhec_Transp ( en_conhectransp_id => rec.conhectransp_id );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_ct_integrados fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_ct_integrados;
--
-------------------------------------------------------------------------------------------------------
-- Procedimento faz a leitura dos CT-e Cancelados que estão com o dm_st_proc = 0
-- e valida a informação do cancelamento

procedure pkb_ler_Conhec_Transp_Canc ( en_multorg_id   in mult_org.id%type default 0
                                     , en_loteintws_id in lote_int_ws.id%type default 0 )
is
   --
   cursor c_Conhec_Transp_Canc ( en_multorg_id in mult_org.id%type default 0 ) is
      select ctc.*
           , ct.empresa_id
           , ct.nro_ct
           , ct.serie
           , mf.cod_mod
           , ct.dt_hr_emissao
        from empresa            em
           , Conhec_Transp      ct
           , Conhec_Transp_Canc ctc
           , Mod_Fiscal         mf
       where em.multorg_id                = nvl(en_multorg_id,em.multorg_id)
         and ct.empresa_id                = em.id
         and ct.dm_st_proc               in (0, 4) -- Integradas
         and ct.dm_ind_emit               = 0      -- Emissão Própria
         and nvl(ct.dm_legado,0)          = 0      -- Não Legado
         and (sysdate - ct.dt_hr_recbto)  < 160
         and ctc.conhectransp_id          = ct.id
         and nvl(ctc.dm_canc_servico,0)  <> 1
         and mf.id               = ct.modfiscal_id;
   --
   vn_fase               number := 0;
   vt_log_generico       dbms_sql.number_table;
   vn_conhectransp_id    Conhec_Transp.id%TYPE;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_Conhec_Transp_Canc ( en_multorg_id => en_multorg_id )
   loop
      --
      exit when c_Conhec_Transp_Canc%notfound or c_Conhec_Transp_Canc%notfound is null;
      --
      vn_fase := 2;
      --
      vt_log_generico.delete;
      --
      vn_fase := 3;
      --
      -- Cancelamento do Ct-e
      pk_csf_api_ct.gt_row_conhec_transp_canc := null;
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_seta_referencia_id ( en_id => rec.conhectransp_id );
      --
      vn_fase := 4.1;
      --
      pk_csf_api_ct.gt_row_conhec_transp_canc.id               := rec.id;
      pk_csf_api_ct.gt_row_conhec_transp_canc.conhectransp_id  := rec.conhectransp_id;
      pk_csf_api_ct.gt_row_conhec_transp_canc.dt_canc          := rec.dt_canc;
      pk_csf_api_ct.gt_row_conhec_transp_canc.justif           := rec.justif;
      pk_csf_api_ct.gt_row_conhec_transp_canc.dm_st_integra    := rec.dm_st_integra;
      pk_csf_api_ct.gt_row_conhec_transp_canc.eventocte_id     := rec.eventocte_id;
      --
      vn_fase := 5;
      -- Chama o procedimento de integração de Cancelamento do CT-e
      pk_csf_api_ct.pkb_integr_Conhec_Transp_Canc ( est_log_generico            => vt_log_generico
                                                  , est_row_Conhec_Transp_Canc  => pk_csf_api_ct.gt_row_conhec_transp_canc 
                                                  , en_loteintws_id             => en_loteintws_id
                                                  );
      --
      vn_fase := 99;
      -- Se registrou algum log, altera o CT-e para dm_st_proc = 10 - "Erro de Validação"
      if nvl(vt_log_generico.count,0) > 0 then
         --
         vn_fase := 99.1;
         --
         begin
            --
            vn_fase := 99.2;
            --
            update Conhec_Transp set dm_st_proc = 10
                                   , dt_st_proc = sysdate
             where id = rec.id;
            --
            commit;
            --
         exception
            when others then
               --
               pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Canc fase(' || vn_fase || '):' || sqlerrm;
               --
               declare
                  vn_loggenerico_id  log_generico_ct.id%TYPE;
               begin
                  --
                  pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                                 , ev_mensagem        => pk_csf_api_ct.gv_mensagem_log
                                                 , ev_resumo          => null
                                                 , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                                 , en_referencia_id   => rec.id
                                                 , ev_obj_referencia  => 'CONHEC_TRANSP' );
                  --
               exception
                  when others then
                     null;
               end;
               --
               raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
               --
         end;
         --
      else
         -- Se não houve nenhum nenhum registro de ocorrência
         -- então atualiza o dm_st_proc para 1-Aguardando Envio
         vn_fase := 99.3;
         --
         update Conhec_Transp set dm_st_proc = 1
                                , dt_st_proc = sysdate
          where id = rec.id;
         --
         commit;
         --
      end if;
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_Conhec_Transp_Canc fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                        , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                        , en_referencia_id   => vn_conhectransp_id
                                        , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_Conhec_Transp_Canc;

-------------------------------------------------------------------------------------------------------
-- Procedimento que integra as Informações do Evento de CTe GTV (Grupo de Transporte de Valores) - Espécies Transportadas - Atualização CTe 3.0

procedure pkb_ler_evento_cte_gtv_esp ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                     , en_eventoctegtv_id      in  evento_cte_gtv.id%TYPE
                                     , en_conhectransp_id      in  conhec_transp.id%TYPE
                                     )
is
   --
   cursor c_dados is
   select *
     from evento_cte_gtv_esp
    where eventoctegtv_id = en_eventoctegtv_id;
   --
   vn_fase            number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_evento_cte_gtv_esp := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_evento_cte_gtv_esp := rec;
      --
      vn_fase := 4;
      --
      -- Chama procedimento que integra as Informações do Evento de CTe GTV (Grupo de Transporte de Valores) - Espécies Transportadas
      pk_csf_api_ct.pkb_integr_evento_cte_gtv_esp ( est_log_generico            => est_log_generico
                                                  , est_row_evento_cte_gtv_esp  => pk_csf_api_ct.gt_row_evento_cte_gtv_esp
                                                  , en_conhectransp_id          => en_conhectransp_id
                                                  );
      --
      vn_fase := 99;
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_evento_cte_gtv_esp fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_evento_cte_gtv_esp;

-------------------------------------------------------------------------------------------------------
-- Procedimento de leitura das Informações do Evento de CTe GTV (Grupo de Transporte de Valores) - Atualização CTe 3.0

procedure pkb_ler_evento_cte_gtv ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                 , en_eventocte_id         in  evento_cte.id%TYPE
                                 , en_conhectransp_id      in  conhec_transp.id%TYPE
                                 )
is
   --
   cursor c_dados is
   select *
     from evento_cte_gtv
    where eventocte_id = en_eventocte_id;
   --
   vn_fase            number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_evento_cte_gtv := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_evento_cte_gtv := rec;
      --
      vn_fase := 4;
      --
      -- Chama procedimento que integra as Informações do Evento de CTe GTV (Grupo de Transporte de Valores)
      pk_csf_api_ct.pkb_integr_evento_cte_gtv ( est_log_generico        => est_log_generico
                                              , est_row_evento_cte_gtv  => pk_csf_api_ct.gt_row_evento_cte_gtv
                                              , en_conhectransp_id      => en_conhectransp_id
                                              );
      --
      vn_fase := 5;
      -- Atualização CTe 3.0
      pkb_ler_evento_cte_gtv_esp ( est_log_generico   => est_log_generico
                                 , en_eventoctegtv_id => rec.id
                                 , en_conhectransp_id => en_conhectransp_id
                                 );
      --
      vn_fase := 99;
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_evento_cte_gtv fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_evento_cte_gtv;

-------------------------------------------------------------------------------------------------------
-- Procedimento de leitura das Informações do Evento Prestação de Serviço em Desacordo do CTe por parte do Tomador - Atualização CTe 3.0

procedure pkb_ler_evento_cte_desac ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                   , en_eventocte_id         in  evento_cte.id%TYPE
                                   , en_conhectransp_id      in  conhec_transp.id%TYPE
                                   )
is
   --
   cursor c_dados is
   select *
     from evento_cte_desac
    where eventocte_id = en_eventocte_id;
   --
   vn_fase            number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_evento_cte_desac := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_evento_cte_desac := rec;
      --
      vn_fase := 4;
      --
      -- Chama procedimento que integra as Informações do Evento Prestação de Serviço em Desacordo do CTe por parte do Tomador
      pk_csf_api_ct.pkb_integr_evento_cte_desac ( est_log_generico          => est_log_generico
                                                , est_row_evento_cte_desac  => pk_csf_api_ct.gt_row_evento_cte_desac
                                                , en_conhectransp_id        => en_conhectransp_id
                                                );
      --
      vn_fase := 99;
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_evento_cte_desac fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_evento_cte_desac;
--
-- ====================================================================================================================== --
-- Procedimento de leitura das informações de Eventos do CTe EPEC
--
procedure pkb_ler_evento_cte_epec ( est_log_generico        in  out nocopy  dbms_sql.number_table
                                  , en_eventocte_id         in  evento_cte.id%TYPE
                                  , en_conhectransp_id      in  conhec_transp.id%TYPE
                                  ) is
   --
   cursor c_dados is
      select *
        from evento_cte_epec
       where eventocte_id = en_eventocte_id;
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   for rec in c_dados loop
      exit when c_dados%notfound or (c_dados%notfound) is null;
      --
      vn_fase := 2;
      --
      pk_csf_api_ct.gt_row_evento_cte_epec := null;
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.gt_row_evento_cte_epec := rec;
      --
      vn_fase := 4;
      --
      -- Chama procedimento que integra as Informações
      pk_csf_api_ct.pkb_integr_evento_cte_epec ( est_log_generico        => est_log_generico
                                               , est_row_evento_cte_epec => pk_csf_api_ct.gt_row_evento_cte_epec
                                               , en_conhectransp_id      => en_conhectransp_id
                                               );
      --
      vn_fase := 99;
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_evento_cte_epec fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_conhectransp_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP' );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_evento_cte_epec;
--
-- ====================================================================================================================== --
--
-- Processo de Evento de CTe
procedure pkb_ler_evento_cte ( en_multorg_id in mult_org.id%type )
is
   --
   vn_fase number := 0;
   vn_eventocte_id  evento_cte.id%type;
   --
   vt_log_generico         dbms_sql.number_table;
   vv_tipoeventosefaz_cd   tipo_evento_sefaz.cd%type;
   vv_estrutcte_grupo      estrut_cte.campo%type;
   vv_estrutcte_campo      estrut_cte.campo%type;
   vn_dm_st_proc           evento_cte.dm_st_proc%type;
   --
   cursor c_ev ( en_multorg_id in mult_org.id%type ) is
   select ec.*
     from empresa       em
        , conhec_transp ct
        , evento_cte    ec
    where em.multorg_id       = en_multorg_id
      and ct.empresa_id       = em.id
      and ec.conhectransp_id  = ct.id
      and ec.dm_st_proc       = 0
      and nvl(ct.dm_legado,0) = 0 -- Não Legado
    order by 1;
   --
   cursor c_cce ( en_eventocte_id evento_cte.id%Type ) is
   select *
     from evento_cte_cce
    where eventocte_id = en_eventocte_id
    order by 1;
   --
   cursor c_mult ( en_eventocte_id evento_cte.id%Type ) is
   select *
     from evento_cte_multimodal
    where eventocte_id = en_eventocte_id
    order by 1;
   --
begin
   --
   vn_fase := 1;
   --
   for rec_ev in c_ev ( en_multorg_id => en_multorg_id )
   loop
      --
      exit when c_ev%notfound or (c_ev%notfound) is null;
      --
      vn_fase := 2;
      --
      vt_log_generico.delete;
      --
      vn_fase := 2.1;
      --
      pk_csf_api_ct.gt_row_evento_cte := null;
      pk_csf_api_ct.gt_row_evento_cte := rec_ev;
      --
      vn_fase := 2.2;
      --
      vv_tipoeventosefaz_cd := pk_csf.fkg_tipoeventosefaz_cd( en_tipoeventosefaz_id => rec_ev.tipoeventosefaz_id );
      --
      vn_fase := 2.3;
      --
      pk_csf_api_ct.pkb_integr_evento_cte ( est_log_generico              => vt_log_generico
                                          , est_row_evento_cte            => pk_csf_api_ct.gt_row_evento_cte
                                          , ev_tipoeventosefaz_cd         => vv_tipoeventosefaz_cd
                                          );
      --
      if vv_tipoeventosefaz_cd = '110110' then -- Carta de Correção
         --
         vn_fase := 3;
         --
         for rec_cce in c_cce(rec_ev.id) loop
            exit when c_cce%notfound or (c_cce%notfound) is null;
            --
            vn_fase := 3.1;
            --
            pk_csf_api_ct.gt_row_evento_cte_cce := rec_cce;
            --
            vn_fase := 3.2;
            --
            vv_estrutcte_grupo := pk_csf_ct.fkg_estrutcte_campo ( en_estrutcte_id => rec_cce.estrutcte_id_grupo );
            --
            vn_fase := 3.3;
            --
            vv_estrutcte_campo := pk_csf_ct.fkg_estrutcte_campo ( en_estrutcte_id => rec_cce.estrutcte_id_campo );
            --
            vn_fase := 3.4;
            --
            pk_csf_api_ct. pkb_integr_evento_cte_cce ( est_log_generico              => vt_log_generico
                                                     , est_row_evento_cte_cce        => pk_csf_api_ct.gt_row_evento_cte_cce
                                                     , en_conhectransp_id            => rec_ev.conhectransp_id
                                                     , ev_estrutcte_grupo            => vv_estrutcte_grupo
                                                     , ev_estrutcte_campo            => vv_estrutcte_campo
                                                     );
            --
         end loop;
         --
      elsif vv_tipoeventosefaz_cd = '110160' then -- Registros do Multimodal
         --
         vn_fase := 4;
         --
         for rec_mult in c_mult(rec_ev.id) loop
            exit when c_mult%notfound or (c_mult%notfound) is null;
            --
            vn_fase := 4.1;
            --
            pk_csf_api_ct.gt_row_evento_cte_multimodal := rec_mult;
            --
            vn_fase := 4.2;
            --
            pk_csf_api_ct.pkb_integr_evento_cte_mmodal ( est_log_generico              => vt_log_generico
                                                       , est_row_evento_cte_multimodal => pk_csf_api_ct.gt_row_evento_cte_multimodal
                                                       , en_conhectransp_id            => rec_ev.conhectransp_id
                                                       );
            --
         end loop;
         --
      end if;
      --
      vn_fase := 5;
      -- Atualização CTe 3.0
      pkb_ler_evento_cte_gtv ( est_log_generico   => vt_log_generico
                             , en_eventocte_id    => rec_ev.id
                             , en_conhectransp_id => rec_ev.conhectransp_id
                             );
      --
      vn_fase := 6;
      -- Atualização CTe 3.0
      pkb_ler_evento_cte_desac ( est_log_generico   => vt_log_generico
                               , en_eventocte_id    => rec_ev.id
                               , en_conhectransp_id => rec_ev.conhectransp_id
                               );
      --
      vn_fase := 7;
      pkb_ler_evento_cte_epec ( est_log_generico   => vt_log_generico
                              , en_eventocte_id    => rec_ev.id
                              , en_conhectransp_id => rec_ev.conhectransp_id
                              ) ;
      --
      vn_fase := 99;
      --
      if nvl(vt_log_generico.count,0) > 0 then
         --
         vn_dm_st_proc := 4; -- Erro de validação
         --
      else
         --
         vn_dm_st_proc := 1; -- Validado
         --
      end if;
      --
      vn_Fase := 99.1;
      --
      update evento_cte set dm_st_proc = vn_dm_st_proc
       where id = rec_ev.id;
      --
      commit;
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_evento_cte fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => vn_eventocte_id
                                           , ev_obj_referencia  => 'EVENTO_CCE'
                                           );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_evento_cte;
--
-- ====================================================================================================================== --
-- Processo de Conhecimento Transporte CCE
procedure pkb_ler_conhec_transp_cce ( en_multorg_id in mult_org.id%type )
is
   --
   vn_fase                number := 0;
   vn_conhectranspcce_id  conhec_transp_cce.id%type;
   vt_log_generico        dbms_sql.number_table;
   vv_tipoeventosefaz_cd  tipo_evento_sefaz.cd%type;
   --
   cursor c_cce ( en_multorg_id in mult_org.id%type ) is
   select ct.*
     from conhec_transp_cce ct
        , conhec_transp     c
        , empresa           em
    where c.id                = ct.conhectransp_id
      and c.empresa_id        = em.id
      and em.multorg_id       = en_multorg_id
      and ct.dm_st_proc       = 0
    order by 1;
   --
begin
   --
   vn_fase := 1;
   --
   for rec_cce in c_cce ( en_multorg_id => en_multorg_id )
   loop
      --
      exit when c_cce%notfound or (c_cce%notfound) is null;
      --
      vn_fase := 2;
      --
      vt_log_generico.delete;
      --
      vn_fase := 2.1;
      --
      pk_csf_api_ct.gt_row_conhec_transp_cce := null;
      --
      vn_fase := 2.2;
      --
      vn_conhectranspcce_id := rec_cce.id;
      --
      vn_fase := 2.3;
      --
      pk_csf_api_ct.gt_row_conhec_transp_cce := rec_cce;
      --
      vn_fase := 2.4;
      --
      vv_tipoeventosefaz_cd := pk_csf.fkg_tipoeventosefaz_cd( en_tipoeventosefaz_id => rec_cce.tipoeventosefaz_id );
      --
      vn_fase := 99;
      --
      pk_csf_api_ct.pkb_integr_conhec_transp_cce ( est_log_generico          => vt_log_generico
                                                 , est_row_conhec_transp_cce => pk_csf_api_ct.gt_row_conhec_transp_cce
                                                 , ev_tipoeventosefaz_cd     => vv_tipoeventosefaz_cd
                                                 );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_ler_conhec_transp_cce fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => vn_conhectranspcce_id
                                           , ev_obj_referencia  => 'CONHEC_TRANSP_CCE'
                                           );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_ler_conhec_transp_cce;
--
-- =================================================================================================================== --
--| Procedimento que inicia a validação de Conhecimentos de Transportes
procedure pkb_integracao
is
   --
   vn_fase number := 0;
   --
   cursor c_mo is
   select mo.*
     from mult_org mo
    where 1 = 1
      and mo.dm_situacao = 1 -- 0-Inativa, 1-Ativa
    order by 1;
   --
begin
   --
   vn_fase := 1;
   --
   for rec_mo in c_mo
   loop
      --
      exit when c_mo%notfound or (c_mo%notfound) is null;
      --
      vn_fase := 2;
      -- seta o tipo de integração que será feito
      -- 0 - Somente valida os dados e registra o Log de ocorrência
      -- 1 - valida os dados e registra o Log de ocorrência e insere a informação
      -- Todos os procedimentos de integração fazem referência a ele
      pk_csf_api_ct.pkb_seta_tipo_integr ( en_tipo_integr => 0 );
      --
      vn_fase := 3;
      pk_csf_api_ct.pkb_seta_obj_ref ( ev_objeto => 'CONHEC_TRANSP' );
      --
      vn_fase := 4;
      -- inicia a leitura para validação dos dados do CT-e
      pkb_ler_ct_integrados ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 5;
      pk_csf_api_ct.pkb_gera_lote_cte ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 6;
      -- Inicia a leitura do Conhec. Transp. Cancelados para validação
      pkb_ler_Conhec_Transp_Canc ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 7;
      -- Inicia a leitura das Inutilizações "Não Validadas"
      pk_csf_api_ct.pkb_consit_inutilizacao ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 8;
      -- Processo de atualização da inutilização
      pk_csf_api_ct.pkb_atual_cte_inut ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 9;
      -- Processo de Evento de CTe
      pkb_ler_evento_cte ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 10;
      -- Processo de Conhecimento Transporte CCE
      pkb_ler_conhec_transp_cce ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 11;
      pk_csf_api_ct.pkb_ajusta_lote_cte ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 12;
      -- Relaciona a Consulta da Situação da CTe com a CTe em si
      pk_csf_api_ct.pkb_relac_cte_cons_sit ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 13;
      pk_csf_api_ct.PKB_CONS_CTE_TERC ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 14;
      -- Atualiza Situação do Conhecimento de Transporte
      pk_csf_api_ct.pkb_atual_sit_docto ( en_multorg_id => rec_mo.id );
      --
      vn_fase := 15;
      -- Finaliza o log genérico para a integração dos Conhecimentos de Transportes no CSF
      pk_csf_api_ct.pkb_finaliza_log_generico_ct;
      --
      vn_fase := 16;
      pk_csf_api_ct.pkb_seta_tipo_integr ( en_tipo_integr => null );
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pk_valida_ambiente_ct.pkb_integracao fase(' || vn_fase || '):' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id => vn_loggenerico_id
                                           , ev_mensagem       => pk_csf_api_ct.gv_mensagem_log
                                           , ev_resumo         => null
                                           , en_tipo_log       => pk_csf_api_ct.ERRO_DE_SISTEMA );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_integracao;
--
-- =================================================================================================================== --
--| Procedimento que inicia a Validação de Conhecimento de Transporte Emissão através do Mult-Org.
--| Esse processo estará sendo executado por JOB SCHEDULER, especifícamente para Ambiente Amazon.
--| A rotina deverá executar o mesmo procedimento da rotina pkb_integracao, porém com a identificação da mult-org.
procedure pkb_integracao_mo ( en_multorg_id in mult_org.id%type )
is
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   -- seta o tipo de integração que será feito
   -- 0 - Somente valida os dados e registra o Log de ocorrência
   -- 1 - valida os dados e registra o Log de ocorrência e insere a informação
   -- Todos os procedimentos de integração fazem referência a ele
   pk_csf_api_ct.pkb_seta_tipo_integr ( en_tipo_integr => 0 );
   --
   vn_fase := 2;
   pk_csf_api_ct.pkb_seta_obj_ref ( ev_objeto => 'CONHEC_TRANSP' );
   --
   vn_fase := 3;
   -- inicia a leitura para validação dos dados do CT-e
   pkb_ler_ct_integrados ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 4;
   pk_csf_api_ct.pkb_gera_lote_cte ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 5;
   -- Inicia a leitura do Conhec. Transp. Cancelados para validação
   pkb_ler_conhec_transp_canc ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 6;
   -- Inicia a leitura das Inutilizações "Não Validadas"
   pk_csf_api_ct.pkb_consit_inutilizacao ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 7;
   -- Processo de atualização da inutilização
   pk_csf_api_ct.pkb_atual_cte_inut ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 8;
   -- Processo de Evento de CTe
   pkb_ler_evento_cte ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 9;
   -- Processo de Conhecimento Transporte CCE
   pkb_ler_conhec_transp_cce ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 10;
   pk_csf_api_ct.pkb_ajusta_lote_cte ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 11;
   -- Relaciona a Consulta da Situação da CTe com a CTe em si
   pk_csf_api_ct.pkb_relac_cte_cons_sit ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 12;
   pk_csf_api_ct.PKB_CONS_CTE_TERC ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 13;
   -- Atualiza Situação do Conhecimento de Transporte
   pk_csf_api_ct.pkb_atual_sit_docto ( en_multorg_id => en_multorg_id );
   --
   vn_fase := 14;
   -- Finaliza o log genérico para a integração dos Conhecimentos de Transportes no CSF
   pk_csf_api_ct.pkb_finaliza_log_generico_ct;
   --
   vn_fase := 15;
   pk_csf_api_ct.pkb_seta_tipo_integr ( en_tipo_integr => null );
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pk_valida_ambiente_ct.pkb_integracao_mo fase(' || vn_fase || '):' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                        , ev_mensagem        => pk_csf_api_ct.gv_mensagem_log
                                        , ev_resumo          => null
                                        , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_integracao_mo;
--
-- =================================================================================================================================
-- Procedimento faz a validação das Inutilizações de Conhecimentos de Transporte, solicitadas por Webservice
procedure pkb_vld_ict ( en_inutilizaconhectransp_id  in      inutiliza_conhec_transp.id%type
                      , sn_erro                      in out  number         -- 0-Não; 1-Sim
                      , en_loteintws_id              in      lote_int_ws.id%type
                      ) is
   --
   vn_fase               number := 0;
   vn_qtde               number := 0;
   --
   vv_cod_mod                 mod_fiscal.cod_mod%type;
   vt_inutiliza_conhec_transp inutiliza_conhec_transp%rowtype;
   vt_log_generico_ct         dbms_sql.number_table;
   --
begin
   --
   vn_fase := 1;
   --
   vt_inutiliza_conhec_transp   := null;
   vt_log_generico_ct.delete;
   pk_csf_api.gv_obj_referencia := 'INUTILIZA_CONHEC_TRANSP';
   pk_csf_api.gn_referencia_id  := en_inutilizaconhectransp_id;
   --
   begin
      --
      select * 
        into vt_inutiliza_conhec_transp
        from inutiliza_conhec_transp
       where id = en_inutilizaconhectransp_id;
      --
   exception
      when others then
         vt_inutiliza_conhec_transp := null;
   end;
   --
   vn_fase := 1.1;
   --
   vv_cod_mod := pk_csf.fkg_cod_mod_id ( en_modfiscal_id => vt_inutiliza_conhec_transp.modfiscal_id );
   --
   vn_fase := 1.2;
   --
   pk_csf_api_ct.pkb_integr_inutilizact ( est_log_generico     => vt_log_generico_ct
                                        , est_row_Inutiliza_Ct => vt_inutiliza_conhec_transp
                                        , ev_cod_mod           => vv_cod_mod
                                        );
   --
   vn_fase := 2;
   --
   begin
      --
      -- 3 - Erro ao enviar Inutilização a SEFAZ
      -- 4 - Erro ao obter o retorno da SEFAZ
      -- 6 - Erro de validação
      select count(1)
        into vn_qtde
        from inutiliza_conhec_transp
       where id           = en_inutilizaconhectransp_id
         and dm_situacao in (3, 4, 6);
      --
   exception
      when others then
         vn_qtde := 0;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vn_qtde,0) > 0 then
      sn_erro := 1;
   end if;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pkb_vld_ict fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_inutilizaconhectransp_id
                                           , ev_obj_referencia  => 'INUTILIZA_NOTA_FISCAL' );
         --
      exception
         when others then
            null;
      end;
      --
end pkb_vld_ict;
--
-- =================================================================================================================================
-- Procedimento faz a leitura das Cartas de Correções das Notas Fiscais
procedure pkb_vld_conhec_transp_cce( en_conhectranspcce_id in     conhec_transp_cce.id%type
                                   , sn_erro               in out number         -- 0-Não; 1-Sim
                                   , en_loteintws_id       in     lote_int_ws.id%type
                                   )
is
   --
   vn_fase               number := 0;
   vt_log_generico_ct    dbms_sql.number_table;
   vv_tipoeventosefaz_cd tipo_evento_sefaz.cd%type;
   vn_conhectranspcce_id conhec_transp_cce.id%type;
   --
   cursor c_cce is
   select cce.*
     from conhec_transp_cce cce
    where cce.id = en_conhectranspcce_id
    order by cce.id;
   --
begin
   --
   vn_fase := 1;
   --
   for r_cce in c_cce
   loop
      --
      exit when c_cce%notfound or (c_cce%notfound) is null;
      --
      vn_fase := 2;
      --
      vt_log_generico_ct.delete;
      --
      -- seta o tipo de integração que será feito
      -- 0 - Válida e Atualiza os dados
      -- 1 - Válida os dados e registra o Log de ocorrência e insere a informação
      -- Todos os procedimentos de integração fazem referência a ele
      --
      pk_csf_api_ct.pkb_seta_tipo_integr ( en_tipo_integr => 0 );
      --
      vn_fase := 3;
      --
      pk_csf_api_ct.pkb_seta_obj_ref ( ev_objeto => 'CONHEC_TRANSP_CCE' );
      --
      vn_fase := 4;
      --
      pk_csf_api_ct.pkb_seta_referencia_id ( en_id => r_cce.id );
      --
      vn_fase := 5;
      --
      pk_csf_api_ct.gt_row_conhec_transp_cce := r_cce;
      --
      vn_fase := 6;
      --
      vv_tipoeventosefaz_cd := pk_csf.fkg_tipoeventosefaz_cd( pk_csf_api_ct.gt_row_conhec_transp_cce.tipoeventosefaz_id);
      --
      pk_csf_api_ct.pkb_integr_conhec_transp_cce( est_log_generico          => vt_log_generico_ct
                                                , est_row_conhec_transp_cce => pk_csf_api_ct.gt_row_conhec_transp_cce
                                                , ev_tipoeventosefaz_cd     => vv_tipoeventosefaz_cd
                                                );
      --
      vn_fase := 7;
      --
      if nvl(vt_log_generico_ct.count,0) > 0 then
         --
         vn_fase := 8;
         --
         sn_erro := 1; -- Sim contém erros
         --
      end if;
      --
      vn_fase := 9;
      --
      commit;
      --
   end loop;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pk_valida_ambiente_ct.pkb_vld_conhec_transp_cce fase(' || vn_fase || '): ' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id   => vn_loggenerico_id
                                           , ev_mensagem         => pk_csf_api_ct.gv_cabec_log
                                           , ev_resumo           => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log         => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id    => en_conhectranspcce_id
                                           , ev_obj_referencia   => 'CONHEC_TRANSP_CCE'
				           );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_vld_conhec_transp_cce;
--
-- =================================================================================================================================
-- Procedimento para recuperar dados dos Conhecimento de Transporte de Emissão Propria a serem validados de origem da Integração por
-- Web-Service
procedure pkb_ler_ct_int_ws ( en_loteintws_id      in      lote_int_ws.id%type
                            , en_tipoobjintegr_id  in      tipo_obj_integr.id%type
                            , ev_tipoobjintegr_cd  in      tipo_obj_integr.cd%type
                            , sn_erro              in out  number         -- 0-Não; 1-Sim
                            , sn_aguardar          out     number         -- 0-Não; 1-Sim
                            )
is
   --
   vn_fase number;
   vn_qtde               number := 0;
   vn_qtde_pend    number;
   --
   cursor c_ct is
   select r.*
     from r_loteintws_ct  r
        , conhec_transp   ct
    where r.loteintws_id      = en_loteintws_id
      and ct.id               = r.conhectransp_id
      and ct.dm_ind_emit      = 0 -- Emissão Propria
      and ct.dm_arm_cte_terc  = 0 -- Não é de armazenamento fiscal
      and ct.dm_legado        = 0 -- recuperar ct-e que não seja legado. O legado será recuperado na pk_csf_api_d100
      and not exists ( select 1
                         from Conhec_Transp_Canc ctc
                        where ctc.conhectransp_id = ct.id
                          and ctc.dm_canc_servico = 1)
    order by r.conhectransp_id;
   --
   --
   cursor c_ict is
   select r.inutilizaconhectransp_id
        , ict.dm_situacao
     from r_loteintws_ict         r
        , inutiliza_conhec_transp ict
    where r.loteintws_id      = en_loteintws_id
      and ict.id              = r.inutilizaconhectransp_id
    order by r.inutilizaconhectransp_id;
   --
   -- Carta de Correção
   cursor c_cce is
   select rl.conhectransp_id
        , cc.id conhectranspcce_id
     from r_loteintws_ct    rl
        , conhec_transp_cce cc
    where cc.conhectransp_id = rl.conhectransp_id
      and rl.loteintws_id    = en_loteintws_id
      and cc.dm_st_proc     in (0,4) -- 0-Não validado, 4-Erro de validação -- Não considerar: 1-Validado, 2-Aguardando Envio, 3-Processado ou 5-Rejeitada
    order by rl.conhectransp_id;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(en_loteintws_id,0) > 0 then
      --
      vn_fase := 2;
      --
      -- 1 - Emissão Própria de Conhecimento de Transporte
      -- 3 - Cancelamento de Emissão Própria de Conhec. de Transporte
      if ev_tipoobjintegr_cd in ('1', '3') then
          --
          for rec in c_ct loop
             exit when c_ct%notfound or (c_ct%notfound) is null;
             --
             vn_fase := 2.1;
             --
             if ev_tipoobjintegr_cd = '1' then -- Emissão Própria de Conhecimento de Transporte
                --
                    vn_fase := 3;
                    --
                pkb_ler_Conhec_Transp ( en_conhectransp_id => rec.conhectransp_id
                                      , en_loteintws_id    => en_loteintws_id );
                --
             elsif ev_tipoobjintegr_cd = '3' then -- Cancelamento de Emissão Própria de Conhec. de Transporte
                --
                    vn_fase := 4;
                --
                pkb_ler_Conhec_Transp_Canc ( en_loteintws_id => en_loteintws_id ) ;
                --
             end if;
             --
             begin
                --
                select count(1)
                  into vn_qtde
                  from conhec_transp
                 where id = rec.conhectransp_id
                   and dm_st_proc = 10;
                --
             exception
                when others then
                   vn_qtde := 0;
             end;
             --
                 vn_fase := 4.1;
             --
             if nvl(vn_qtde,0) > 0 then
                sn_erro := 1;
             end if;
             --
          end loop;
          --
      elsif ev_tipoobjintegr_cd = '4' then -- Inutilização de Emissão Própria de Conhec. de Transporte
         --
         vn_fase := 5;
         --
         for rec_ict in c_ict loop
            exit when c_ict%notfound or (c_ict%notfound) is null;
            --
            vn_fase := 5.1;
            --
            if rec_ict.dm_situacao = 5 then -- 5-Não validada
               --
               vn_fase := 5.2;
               -- chama procedimento de validação
               pkb_vld_ict ( en_inutilizaconhectransp_id => rec_ict.inutilizaconhectransp_id
                           , sn_erro                     => sn_erro
                           , en_loteintws_id             => en_loteintws_id
                           );
               --
            end if;
            --
            commit;
            --
            vn_fase := 5.3;
            -- verifica se há CT Pendentes
            begin
               select count(1)
                 into vn_qtde_pend
                 from r_loteintws_ict          r
                    , inutiliza_conhec_transp  ict
                where r.loteintws_id      = en_loteintws_id
                  and ict.id              = r.inutilizaconhectransp_id
                  and ict.dm_situacao     in (0, 1, 5);
            exception
               when others then
                  vn_qtde_pend := 0;
            end;
            --
            vn_fase := 5.4;
            --
            if nvl(vn_qtde_pend,0) > 0 and sn_erro = 0 then -- 1979
               sn_aguardar := 1; -- Sim ainda está sendo processado - Em Processamento - aguardar
            else
               sn_aguardar := 0; -- Não tem mais nada para ser processado - Processado ou Processado com Erro - Status final do lote
            end if;
            --
         end loop;
         --
      elsif ev_tipoobjintegr_cd = '5' then -- Carta de Correção Emissão Própria de Conhec. de Transporte
         --
         vn_fase := 6;
         --
         for rec_cce in c_cce loop
            exit when c_cce%notfound or (c_cce%notfound) is null;
            --
            vn_fase := 6.1;
            --
            pkb_vld_conhec_transp_cce( en_conhectranspcce_id => rec_cce.conhectranspcce_id
                                     , sn_erro               => sn_erro
                                     , en_loteintws_id       => en_loteintws_id
                                     );
            --
            commit;
            --
            vn_fase := 6.2;
            -- verifica se há CCE Pendentes
            begin
               select count(1) qtd
                 into vn_qtde_pend
                 from r_loteintws_ct rl
                    , conhec_transp_cce cc
                where rl.loteintws_id    = en_loteintws_id
                  and cc.conhectransp_id = rl.conhectransp_id
                  and cc.dm_st_proc      = 4; -- 4-Erro validação
            exception
               when others then
                  vn_qtde_pend := 0;
            end;
            --
            vn_fase := 6.3;
            --
            if nvl(vn_qtde_pend,0) > 0 and sn_erro = 0 then
               sn_aguardar := 1; -- Sim ainda está sendo processado - Em Processamento - aguardar
            else
               sn_aguardar := 0; -- Não tem mais nada para ser processado - Processado ou Processado com Erro - Status final do lote
            end if;
            --
         end loop;
         --
      end if;
      --
    end if;
    --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pk_valida_ambiente_ct.pkb_ler_ct_int_ws fase(' || vn_fase || '):' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_mensagem_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , EN_REFERENCIA_ID   => en_loteintws_id
                                           , EV_OBJ_REFERENCIA  => 'LOTE_INT_WS'
                                           );
         --
      exception
         when others then
            null;
      end;
      --
end pkb_ler_ct_int_ws;
--
-- =================================================================================================================================
-- Procedimento de validação de dados de Conhecimento de Transporte Emissão Própria, oriundos de Integração por Web-Service
procedure pkb_int_ws ( en_loteintws_id      in     lote_int_ws.id%type
                     , en_tipoobjintegr_id  in     tipo_obj_integr.id%type
                     , sn_erro              in out number
                     , sn_aguardar          out    number         -- 0-Não; 1-Sim
                     )
is
   --
   vn_fase number;
   vn_qtde_pend number;
   vv_tipoobjintegr_cd  tipo_obj_integr.cd%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(en_loteintws_id,0) > 0
      and nvl(en_tipoobjintegr_id,0) > 0
      then
      --
      vn_fase := 2;
      --
      -- Verifica o tipo de inventario para realizar a validação
      vv_tipoobjintegr_cd := pk_csf.fkg_tipoobjintegr_cd ( en_tipoobjintegr_id => en_tipoobjintegr_id );
      --
      vn_fase := 2.1;
      --
      pkb_ler_ct_int_ws ( en_loteintws_id      => en_loteintws_id
                        , en_tipoobjintegr_id  => en_tipoobjintegr_id
                        , ev_tipoobjintegr_cd  => vv_tipoobjintegr_cd
                        , sn_erro              => sn_erro
                        , sn_aguardar          => sn_aguardar
                        );
      --
      vn_fase := 3;
      -- verifica se há Conhec. Transp. Pendentes
      begin
         --
         select count(1) 
           into vn_qtde_pend
           from r_loteintws_ct  r
              , conhec_transp   ct
          where r.loteintws_id      = en_loteintws_id
            and ct.id               = r.conhectransp_id
            and ct.dm_arm_cte_terc  = 0 -- Não é de armazenamento fiscal
            and ct.dm_st_proc       in (0, 1, 2, 3);
         --
      exception
         when others then
            vn_qtde_pend := 0;
      end;
      --
      vn_fase := 3.1;
      --
      if nvl(vn_qtde_pend,0) > 0 then
         --
         sn_aguardar := 1; -- Sim aguardar fechamento do lote
         --
      else
         --
         sn_aguardar := 0; -- Não aguardar fechamento do lote
         --
      end if;
      --
   end if;
   --
exception
   when others then
      --
      pk_csf_api_ct.gv_mensagem_log := 'Erro na pk_valida_ambiente_ct.pkb_int_ws fase(' || vn_fase || '):' || sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ct.id%TYPE;
      begin
         --
         pk_csf_api_ct.pkb_log_generico_ct ( sn_loggenerico_id  => vn_loggenerico_id
                                           , ev_mensagem        => pk_csf_api_ct.gv_mensagem_log
                                           , ev_resumo          => pk_csf_api_ct.gv_mensagem_log
                                           , en_tipo_log        => pk_csf_api_ct.ERRO_DE_SISTEMA
                                           , en_referencia_id   => en_loteintws_id
                                           , ev_obj_referencia  => 'LOTE_INT_WS'
                                           );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, pk_csf_api_ct.gv_mensagem_log);
      --
end pkb_int_ws;

-------------------------------------------------------------------------------------------------------

end pk_valida_ambiente_ct;
/
