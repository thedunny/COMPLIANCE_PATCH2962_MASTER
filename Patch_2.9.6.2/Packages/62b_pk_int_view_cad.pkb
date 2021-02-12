create or replace package body csf_own.pk_int_view_cad is

-------------------------------------------------------------------------------------------------------
--| Corpo do pacote de procedimentos de integração e validação de Cadastros
-------------------------------------------------------------------------------------------------------

--| Função para montar o processo de FROM para os selects
function fkg_monta_from ( ev_obj in varchar2 )
         return varchar2
is
   --
   vv_from  varchar2(4000) := null;
   vv_obj   varchar2(4000) := null;
   --
begin
   --
   vv_obj := ev_obj;
   --
   if GV_NOME_DBLINK is not null then
      --
      vv_from := vv_from || trim(GV_ASPAS) || vv_obj || trim(GV_ASPAS) || '@' || GV_NOME_DBLINK;
      --
   else
      --
      vv_from := vv_from || trim(GV_ASPAS) || vv_obj || trim(GV_ASPAS);
      --
   end if;
   --
   if trim(GV_OWNER_OBJ) is not null then
      vv_from := trim(GV_OWNER_OBJ) || '.' || vv_from;
   end if;
   --
   vv_from := ' from ' || vv_from;
   --
   return vv_from;
   --
end fkg_monta_from;

-------------------------------------------------------------------------------------------------------

--| Procedimento para recuperar os dados da empresa - parâmetros de banco
procedure pkb_dados_bco_empr( ev_cpf_cnpj  in  varchar2 ) is
   --
   cursor c_dados is
   select e.*
     from empresa e
    order by 1;
   --
begin
   --
   gv_formato_data := pk_csf.fkg_param_global_csf_form_data;
   --
   if ev_cpf_cnpj is not null then
      --
      for rec in c_dados loop
         exit when c_dados%notfound or (c_dados%notfound) is null;
         --
         if pk_csf.fkg_cnpj_ou_cpf_empresa ( rec.id ) = ev_cpf_cnpj then
            --
            gv_nome_dblink    := rec.nome_dblink;
            --
            if rec.dm_util_aspa = 1 then
               gv_aspas          := '"';
            else
               gv_aspas          := null;
            end if;
            --
            gv_owner_obj      := rec.owner_obj;
            --
            if trim(rec.formato_dt_erp) is null then
               gv_formato_dt_erp := gv_formato_data;
            else
               gv_formato_dt_erp := trim(rec.formato_dt_erp);
            end if;
            --
            gn_multorg_id     := rec.multorg_id;
            --
         else
            --
            gv_nome_dblink    := null;
            gv_aspas          := null;
            gv_owner_obj      := null;
            gv_formato_dt_erp := gv_formato_data;
            gn_multorg_id     := pk_csf.fkg_multorg_id(ev_multorg_cd => '1');
            --
         end if;
         --
         gv_multorg_cd := pk_csf.fkg_multorg_cd ( en_multorg_id => gn_multorg_id );
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      raise_application_error (-20101, 'Problemas em pk_int_view_cad.pkb_dados_bco_empr (cnpj = '||ev_cpf_cnpj||'). Erro = '||sqlerrm);
end pkb_dados_bco_empr;

-------------------------------------------------------------------------------------------------------

--| Procedimento para limpar as variáveis dos parâmetros de banco da empresa
procedure pkb_limpa_dados_bco_empr is
begin
   --
   gv_aspas          := null;
   gv_nome_dblink    := null;
   gv_owner_obj      := null;
   gv_formato_dt_erp := null;
   gn_multorg_id     := null;
   gv_multorg_cd     := null;
   --
end pkb_limpa_dados_bco_empr;

-------------------------------------------------------------------------------------------------------
-- Procedimento de Leitura dos Processos Administrativos do EFD-REINF de Informações Tributárias
procedure pkb_ler_procadmefdreinfinftrib ( est_log_generico         in out nocopy dbms_sql.number_table
                                         , en_procadmefdreinf_id    in            number
                                         , en_empresa_id            in            empresa.id%type
                                         , en_multorg_id            in            mult_org.id%type
                                         , ev_cpf_cnpj              in            varchar2
                                         , ed_dt_ini                in            date
                                         , ed_dt_fin                in            date
                                         , en_dm_tp_proc            in            number
                                         , ev_nro_proc              in            varchar2
                                         )
is
   --
   vn_fase                               number;
   vv_teste                              varchar2(2000);
   --
begin
   --
   vn_fase := 1;
   gv_sql := null;
   vt_tab_procadmefdreinfinftrib.delete;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PROCADMEFDREINFINFTRIB') = 0 then
      --
      return;
      --
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) ||') ';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_TP_PROC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'NRO_PROC' || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_SUSP' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CD_IND_SUSP_EXIG' || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_DECISAO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'DM_IND_DEPOSITO' || trim(GV_ASPAS)||') ';
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PROCADMEFDREINFINFTRIB');
   --
   vn_fase := 1.3;
   --
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || ' DM_TP_PROC'|| trim(GV_ASPAS) || ' = ' || '''' ||en_dm_tp_proc||'''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || ' NRO_PROC'|| trim(GV_ASPAS) || ' = ' || '''' ||ev_nro_proc||'''';
   --
   vn_fase := 2;
   --
   vv_teste := gv_sql;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_procadmefdreinfinftrib;
      --
   exception
      when others then
         --
         pk_csf_api_fci.gv_mensagem_log := 'Erro na pk_int_view_fci.pkb_ler_procadmefdreinfinftrib fase ('||vn_fase||'): '||sqlerrm;
         --
         declare
            vn_loggenericocad_id  log_generico_cad.id%TYPE;
         begin
            --
            pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id    => vn_loggenericocad_id
                                                , ev_mensagem             => pk_csf_api_cad.gv_mensagem_log
                                                , ev_resumo               => pk_csf_api_cad.gv_mensagem_log
                                                , en_tipo_log             => pk_csf_api_cad.erro_de_sistema
                                                , en_referencia_id        => null
                                                , ev_obj_referencia       => gv_obj_referencia
                                                , en_empresa_id           => gn_empresa_id
                                                );
            --
         exception
            when others then
               null;
         end;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_procadmefdreinfinftrib.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_procadmefdreinfinftrib.first..vt_tab_procadmefdreinfinftrib.last loop
         --
         vn_fase := 4;
         --
         pk_csf_api_cad.gt_row_inf_item_fci := null;
         --
         pk_csf_api_cad.gt_row_procadmefdreinfinftrib.procadmefdreinf_id := en_procadmefdreinf_id;
         pk_csf_api_cad.gt_row_procadmefdreinfinftrib.cod_susp           := vt_tab_procadmefdreinfinftrib(i).cod_susp;
         pk_csf_api_cad.gt_row_procadmefdreinfinftrib.dt_decisao         := vt_tab_procadmefdreinfinftrib(i).dt_decisao;
         pk_csf_api_cad.gt_row_procadmefdreinfinftrib.dm_ind_deposito    := vt_tab_procadmefdreinfinftrib(i).dm_ind_deposito;
         --
         vn_fase := 4.1;
         --
         pk_csf_api_cad.pkb_integr_procadmefdreinftrib ( est_log_generico                => est_log_generico
                                                       , est_row_procadmefdreinfinftrib  => pk_csf_api_cad.gt_row_procadmefdreinfinftrib
                                                       , en_empresa_id                   => en_empresa_id
                                                       , ev_ind_susp_exig                => vt_tab_procadmefdreinfinftrib(i).cd_ind_susp_exig
                                                       );
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_procadmefdreinfinftrib fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => 'CNPJ: ' || ev_cpf_cnpj || 'NRO_PROC: ' || ev_nro_proc
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_pessoa.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_ler_procadmefdreinfinftrib;

-------------------------------------------------------------------------------------------------------
-- Procedimento de Leitura da Flex-Field dos Processos Administrativos do EFD-REINF
procedure pkb_ler_proc_adm_efd_reinf_ff( est_log_generico in out nocopy dbms_sql.number_table
                                       , ev_cpf_cnpj      in            varchar2
                                       , ed_dt_ini        in            date
                                       , ed_dt_fin        in            date
                                       , en_dm_tp_proc    in            number
                                       , ev_nro_proc      in            varchar2
                                       , sn_multorg_id    in out nocopy number
                                       )
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   vv_teste              varchar2(2000);
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PROC_ADM_EFD_REINF_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PROC_ADM_EFD_REINF';
   --
   gv_sql := null;
   --
   vt_tab_proc_adm_efd_reinf_ff.delete;
   --
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) ||') ';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_TP_PROC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'NRO_PROC' || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PROC_ADM_EFD_REINF_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'DM_TP_PROC' || trim(GV_ASPAS) || ' = ' ||''''||en_dm_tp_proc||'''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'NRO_PROC' || trim(GV_ASPAS) || ' = ' ||''''||ev_nro_proc||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_proc_adm_efd_reinf_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_proc_adm_efd_reinf_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => 'CNPJ: ' || ev_cpf_cnpj || 'NRO_PROC: ' || ev_nro_proc
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_proc_adm_efd_reinf_ff.count > 0 then
      --
      for i in vt_tab_proc_adm_efd_reinf_ff.first..vt_tab_proc_adm_efd_reinf_ff.last loop
         --
         vn_fase := 4;
         --
         vv_teste := vt_tab_proc_adm_efd_reinf_ff(i).atributo;
         --
         if vt_tab_proc_adm_efd_reinf_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Pessoa - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            --
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_PROC_ADM_EFD_REINF_FF'
                                                 , ev_atributo          => vt_tab_proc_adm_efd_reinf_ff(i).atributo
                                                 , ev_valor             => vt_tab_proc_adm_efd_reinf_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Pessoa cadastrada com Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'CNPJ: ' || ev_cpf_cnpj || 'NRO_PROC: ' || ev_nro_proc
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_proc_adm_efd_reinf_ff fase('||vn_fase||') cod_part('||pk_csf_api_cad.gt_row_pessoa.cod_part||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => 'CNPJ: ' || ev_cpf_cnpj || 'NRO_PROC: ' || ev_nro_proc
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_pessoa.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_ler_proc_adm_efd_reinf_ff;

-------------------------------------------------------------------------------------------------------
-- Procedimento de Leitura da Flex-Field dos Parametros do DIPAM-GIA
procedure pkb_ler_proc_adm_efd_reinf ( ev_cpf_cnpj in varchar2
                                     )
is
   --
   vn_fase                           number;
   vt_log_generico_cad               dbms_sql.number_table;
   vn_multorg_id                     mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PROC_ADM_EFD_REINF') = 0 then
      --
      return;
      --
   end if;
   --
   pk_csf_api_secf.pkb_seta_obj_ref ( ev_objeto => 'PROC_ADM_EFD_REINF' );
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_proc_adm_efd_reinf.delete;
   --
   gv_sql := 'select ';
   --
   gv_sql := gv_sql ||         ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CPF_CNPJ'         || trim(GV_ASPAS) ||') ';
   gv_sql := gv_sql || ', '                            || trim(GV_ASPAS) || 'DM_TP_PROC'       || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'NRO_PROC'         || trim(GV_ASPAS) ||') ';
   gv_sql := gv_sql || ', '                            || trim(GV_ASPAS) || 'DT_INI'           || trim(GV_ASPAS);
   gv_sql := gv_sql || ', '                            || trim(GV_ASPAS) || 'DT_FIN'           || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'IBGE_CIDADE'      || trim(GV_ASPAS) ||') ';
   gv_sql := gv_sql || ', ' || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_IDENT_VARA'   || trim(GV_ASPAS) ||') ';
   gv_sql := gv_sql || ', '                            || trim(GV_ASPAS) || 'DM_IND_AUDITORIA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', '                            || trim(GV_ASPAS) || 'DM_REINF_LEGADO'  || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PROC_ADM_EFD_REINF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   vn_fase := 2;
   --
   gv_cabec_log := 'Inconsistência de dados no leiaute VW_CSF_PROC_ADM_EFD_REINF (empresa: '||ev_cpf_cnpj||').';
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_proc_adm_efd_reinf;
      --
   exception
      when others then
         --
         gv_cabec_log := gv_mensagem_log||' Erro na pk_int_view_cad.pkb_ler_proc_adm_efd_reinf fase ('||vn_fase||'): '||sqlerrm;
         --
         declare
            vn_loggenericocad_id  log_generico_cad.id%TYPE;
         begin
            --
            pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                , ev_mensagem           => gv_mensagem_log
                                                , ev_resumo             => gv_cabec_log
                                                , en_tipo_log           => erro_de_sistema
                                                , en_referencia_id      => null
                                                , ev_obj_referencia     => 'PROC_ADM_EFD_REINF'
                                                , en_empresa_id         => gn_empresa_id );
            --
         exception
            when others then
               null;
         end;
         --
         --goto sair_geral;
         raise_application_error (-20101, gv_mensagem_log);
   end;
   --
   vn_fase := 3;
   -- Calcular a quantidade de registros
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_proc_adm_efd_reinf.count,0);
   exception
      when others then
      null;
   end;
   --
   vn_fase := 4;
   --
   if nvl(vt_tab_proc_adm_efd_reinf.count,0) > 0 then
      --
      vn_fase := 4.1;
      --
      for i in vt_tab_proc_adm_efd_reinf.first..vt_tab_proc_adm_efd_reinf.last loop
         --
         vt_log_generico_cad.delete;
         --
         vn_fase := 4.2;
         --
         -- informações de Pessoa
         pk_csf_api_cad.gt_row_proc_adm_efd_reinf := null;
         --
         pk_csf_api_cad.gt_row_proc_adm_efd_reinf.dt_ini             := vt_tab_proc_adm_efd_reinf(i).dt_ini;
         pk_csf_api_cad.gt_row_proc_adm_efd_reinf.dt_fin             := vt_tab_proc_adm_efd_reinf(i).dt_fin;
         pk_csf_api_cad.gt_row_proc_adm_efd_reinf.dm_tp_proc         := vt_tab_proc_adm_efd_reinf(i).dm_tp_proc;
         pk_csf_api_cad.gt_row_proc_adm_efd_reinf.nro_proc           := vt_tab_proc_adm_efd_reinf(i).nro_proc;
         pk_csf_api_cad.gt_row_proc_adm_efd_reinf.cod_ident_vara     := vt_tab_proc_adm_efd_reinf(i).cod_ident_vara;
         pk_csf_api_cad.gt_row_proc_adm_efd_reinf.dm_ind_auditoria   := vt_tab_proc_adm_efd_reinf(i).dm_ind_auditoria;
         pk_csf_api_cad.gt_row_proc_adm_efd_reinf.dm_reinf_legado    := vt_tab_proc_adm_efd_reinf(i).dm_reinf_legado;
         pk_csf_api_cad.gt_row_proc_adm_efd_reinf.dm_situacao        := 0;
         --
         vn_multorg_id := gn_multorg_id;
         --
         pkb_ler_proc_adm_efd_reinf_ff( est_log_generico  => vt_log_generico_cad
                                      , ev_cpf_cnpj       => vt_tab_proc_adm_efd_reinf(i).cpf_cnpj
                                      , ed_dt_ini         => vt_tab_proc_adm_efd_reinf(i).dt_ini    
                                      , ed_dt_fin         => vt_tab_proc_adm_efd_reinf(i).dt_fin    
                                      , en_dm_tp_proc     => vt_tab_proc_adm_efd_reinf(i).dm_tp_proc
                                      , ev_nro_proc       => vt_tab_proc_adm_efd_reinf(i).nro_proc
                                      , sn_multorg_id     => vn_multorg_id
                                      );
         --
         vn_fase := 4.3;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         vn_fase := 4.4;
         -- chama API de integração de pessoa
         pk_csf_api_cad.pkb_integr_proc_adm_efd_reinf ( est_log_generico            => vt_log_generico_cad
                                                      , est_row_proc_adm_efd_reinf  => pk_csf_api_cad.gt_row_proc_adm_efd_reinf
                                                      , en_multorg_id               => vn_multorg_id
                                                      , ev_cpf_cnpj                 => vt_tab_proc_adm_efd_reinf(i).cpf_cnpj
                                                      , ev_ibge_cidade              => vt_tab_proc_adm_efd_reinf(i).ibge_cidade
                                                      );
         --
         if nvl(pk_csf_api_cad.gt_row_proc_adm_efd_reinf.id,0) > 0 then
            --
            pkb_ler_procadmefdreinfinftrib ( est_log_generico         => vt_log_generico_cad
                                           , en_procadmefdreinf_id    => pk_csf_api_cad.gt_row_proc_adm_efd_reinf.id
                                           , en_empresa_id            => pk_csf_api_cad.gt_row_proc_adm_efd_reinf.empresa_id
                                           , en_multorg_id            => vn_multorg_id
                                           , ev_cpf_cnpj              => vt_tab_proc_adm_efd_reinf(i).cpf_cnpj
                                           , ed_dt_ini                => vt_tab_proc_adm_efd_reinf(i).dt_ini               
                                           , ed_dt_fin                => vt_tab_proc_adm_efd_reinf(i).dt_fin               
                                           , en_dm_tp_proc            => vt_tab_proc_adm_efd_reinf(i).dm_tp_proc           
                                           , ev_nro_proc              => vt_tab_proc_adm_efd_reinf(i).nro_proc
                                           );
            --
         end if;
         --
         if nvl(vt_log_generico_cad.count,0) > 0 then
            --
            update proc_adm_efd_reinf
               set dm_situacao = 2 -- Erro de Validação
             where id = pk_csf_api_cad.gt_row_proc_adm_efd_reinf.id;
            --
         else
            --
            update proc_adm_efd_reinf
               set dm_situacao = 1 -- Validado
             where id = pk_csf_api_cad.gt_row_proc_adm_efd_reinf.id;
            --
         end if;
         --
         vn_fase := 7.2;
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(vt_log_generico_cad.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         vn_fase := 7.3;
         --
         commit;
         --
         <<sair_geral>>
         --
         null;
         --
      end loop;
      --
   end if;
   --
exception
   when others then
     --
     gv_cabec_log := 'Erro na pk_int_view_ddo.pkb_ler_proc_adm_efd_reinf fase ('||vn_fase||'):'||sqlerrm;
     --
     declare
       vn_loggenericocad_id   log_generico_cad.id%type;
     begin
       --
       pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id => vn_loggenericocad_id
                                           , ev_mensagem          => gv_mensagem_log
                                           , ev_resumo            => gv_cabec_log
                                           , en_tipo_log          => erro_de_sistema
                                           , en_referencia_id     => null
                                           , ev_obj_referencia    => 'PROC_ADM_EFD_REINF'
                                           , en_empresa_id        => gn_empresa_id );
       --
     exception
        when others then
           raise_application_error(-20101, gv_cabec_log);
     end;
     --
end pkb_ler_proc_adm_efd_reinf;

-------------------------------------------------------------------------------------------------------
-- Procedimento de Leitura da Flex-Field dos Parametros do DIPAM-GIA
procedure pkb_ler_param_dipamgia_ff( est_log_generico  in out nocopy dbms_sql.number_table
                                   , ev_cpf_cnpj       in            varchar2
                                   , ev_ibge_estado    in            varchar2
                                   , ev_cd_dipamgia    in            varchar2
                                   , en_cd_cfop        in            number
                                   , ev_cod_item       in            varchar2
                                   , ev_cod_ncm        in            varchar2
                                   , sn_multorg_id        out nocopy mult_org.id%type
                                   )
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PARAM_DIPAMGIA_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PARAM_DIPAMGIA';
   --
   gv_sql := null;
   --
   vt_tab_param_dipamgia_ff.delete;
   --
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) ||') ';
   gv_sql := gv_sql || ', ' ||' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'IBGE_ESTADO' || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' ||' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CD_DIPAMGIA' || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' ||trim(GV_ASPAS) || 'CD_CFOP' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' ||' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' ||' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_NCM' || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PARAM_DIPAMGIA_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'IBGE_ESTADO' || trim(GV_ASPAS) || ' = ' ||''''||ev_ibge_estado||'''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'CD_DIPAMGIA' || trim(GV_ASPAS) || ' = ' ||''''||ev_cd_dipamgia||'''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'CD_CFOP' || trim(GV_ASPAS)     || ' = ' ||''''||en_cd_cfop||'''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS)    || ' = ' ||''''||ev_cod_item||'''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_NCM' || trim(GV_ASPAS)     || ' = ' ||''''||ev_cod_ncm||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_param_dipamgia_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_param_dipamgia_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => 'CNPJ: ' || ev_cpf_cnpj || 'CD_DIPAMGIA: ' || ev_cd_dipamgia
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_param_dipamgia_ff.count > 0 then
      --
      for i in vt_tab_param_dipamgia_ff.first..vt_tab_param_dipamgia_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_param_dipamgia_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Pessoa - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            --
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_PARAM_DIPAMGIA_FF'
                                                 , ev_atributo          => vt_tab_param_dipamgia_ff(i).atributo
                                                 , ev_valor             => vt_tab_param_dipamgia_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Pessoa cadastrada com Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'CNPJ: ' || ev_cpf_cnpj || 'CD_DIPAMGIA: ' || ev_cd_dipamgia
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_param_dipamgia_ff fase('||vn_fase||') cod_part('||pk_csf_api_cad.gt_row_pessoa.cod_part||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => 'CNPJ: ' || ev_cpf_cnpj || 'CD_DIPAMGIA: ' || ev_cd_dipamgia
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_pessoa.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_ler_param_dipamgia_ff;

-------------------------------------------------------------------------------------------------------
-- Procedimento de Leitura dos Parametros do DIPAM-GIA
procedure pkb_ler_param_dipamgia ( ev_cpf_cnpj in varchar2)
is
   --
   vn_fase         number;
   vn_multorg_id   mult_org.id%type;
   vt_log_generico dbms_sql.number_table;
   --
begin
   --
   vn_fase := 1;
   --
   gv_sql := null;
   vt_tab_param_dipamgia.delete;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PARAM_DIPAMGIA') = 0 then
      --
      return;
      --
   end if;
   --
   vn_fase := 2;
   --
   pk_csf_api_secf.pkb_seta_obj_ref ( ev_objeto => 'PARAM_DIPAMGIA' );
   --
   vn_fase := 1.1;
   -- Montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql ||        ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CPF_CNPJ'         || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' ||' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'IBGE_ESTADO'      || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' ||' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CD_DIPAMGIA'      || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' ||                           trim(GV_ASPAS) || 'CD_CFOP'          || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' ||' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_ITEM'         || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' ||' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_NCM'          || trim(GV_ASPAS)||') ';
   gv_sql := gv_sql || ', ' ||                           trim(GV_ASPAS) || 'PERC_RATEIO_ITEM' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PARAM_DIPAMGIA' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   --
   vn_fase := 2;
   --
   gv_cabec_log := 'Inconsistência de dados no leiaute VW_CSF_PARAM_DIPAMGIA (empresa: '||ev_cpf_cnpj||').';
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_param_dipamgia;
      --
   exception
      when others then
         --
         gv_cabec_log := gv_mensagem_log||' Erro na pk_csf_api_secf.pkb_ler_param_dipamgia fase ('||vn_fase||'): '||sqlerrm;
         --
         declare
            vn_loggenerico_id  log_generico_cad.id%TYPE;
         begin
            --
            pk_csf_api_secf.pkb_log_generico ( sn_loggenerico_id => vn_loggenerico_id
                                             , ev_mensagem       => gv_mensagem_log
                                             , ev_resumo         => gv_cabec_log
                                             , en_tipo_log       => erro_de_sistema
                                             , en_referencia_id  => null
                                             , ev_obj_referencia => 'PARAM_DIPAMGIA'
                                             , en_empresa_id     => gn_empresa_id );
            --
         exception
            when others then
               null;
         end;
         --
         --goto sair_geral;
         raise_application_error (-20101, gv_mensagem_log);
   end;
   --
   vn_fase := 3;
   -- Calcular a quantidade de registros
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_param_dipamgia.count,0);
   exception
      when others then
      null;
   end;
   --
   vn_fase := 4;
   --
   if nvl(vt_tab_param_dipamgia.count,0) > 0 then
      --
      vn_fase := 4.1;
      --
      for i in vt_tab_param_dipamgia.first..vt_tab_param_dipamgia.last loop
         --
         vt_log_generico.delete;
         --
         vn_fase := 4.2;
         --
         -- informações de Pessoa
         pk_csf_api_cad.gt_row_param_dipamgia := null;
         --
         vn_multorg_id := gn_multorg_id;
         --
         pkb_ler_param_dipamgia_ff( est_log_generico  => vt_log_generico
                                  , ev_cpf_cnpj       => vt_tab_param_dipamgia(i).cpf_cnpj
                                  , ev_ibge_estado    => vt_tab_param_dipamgia(i).ibge_estado
                                  , ev_cd_dipamgia    => vt_tab_param_dipamgia(i).cd_dipamgia
                                  , en_cd_cfop        => vt_tab_param_dipamgia(i).cd_cfop    
                                  , ev_cod_item       => vt_tab_param_dipamgia(i).cod_item   
                                  , ev_cod_ncm        => vt_tab_param_dipamgia(i).cod_ncm
                                  , sn_multorg_id     => vn_multorg_id);
         --
         vn_fase := 3.4;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         vn_fase := 4;
         --
         pk_csf_api_cad.gt_row_param_dipamgia.perc_rateio_item := vt_tab_param_dipamgia(i).perc_rateio_item;
         -- chama API de integração de pessoa
         pk_csf_api_cad.pkb_integr_param_dipamgia ( est_log_generico        => vt_log_generico
                                                    , est_row_param_dipamgia  => pk_csf_api_cad.gt_row_param_dipamgia
                                                    , en_multorg_id           => vn_multorg_id
                                                    , ev_cpf_cnpj             => vt_tab_param_dipamgia(i).cpf_cnpj
                                                    , ev_ibge_estado          => vt_tab_param_dipamgia(i).ibge_estado
                                                    , ev_cd_dipamgia          => vt_tab_param_dipamgia(i).cd_dipamgia
                                                    , en_cd_cfop              => vt_tab_param_dipamgia(i).cd_cfop    
                                                    , ev_cod_item             => vt_tab_param_dipamgia(i).cod_item   
                                                    , ev_cod_ncm              => vt_tab_param_dipamgia(i).cod_ncm
                                                    );
         --
         vn_fase := 7.2;
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         vn_fase := 7.3;
         --
         commit;
         --
         --<<sair_geral>>
         --
         null;
         --
      end loop;
      --
   end if;
   --
exception
   when others then
     --
     gv_cabec_log := 'Erro na pk_int_view_ddo.pkb_ler_param_dipamgia fase ('||vn_fase||'):'||sqlerrm;
     --
     declare
       vn_loggenerico_id   log_generico.id%type;
     begin
       --
       pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id => vn_loggenerico_id
                                             , ev_mensagem          => gv_mensagem_log
                                             , ev_resumo            => gv_cabec_log
                                             , en_tipo_log          => erro_de_sistema
                                             , en_referencia_id     => null
                                             , ev_obj_referencia    => 'PARAM_DIPAMGIA'
                                             , en_empresa_id        => gn_empresa_id );
       --
     exception
        when others then
           raise_application_error(-20101, gv_cabec_log);
     end;
     --
end pkb_ler_param_dipamgia;

-------------------------------------------------------------------------------------------------------
-- Processo de leitura do Retorno dos dados da Ficha de Conteudo de Importação
procedure pkb_ler_retorno_fci ( est_log_generico     in out nocopy dbms_sql.number_table
                              , en_aberturafciarq_id in            abertura_fci_arq.id%type
                              , ev_cnpj_empr         in            varchar2
                              , ev_mes_ref           in            varchar2
                              , en_ano_ref           in            number
                              )
is
   --
   vn_fase                    number := null;
   vn_multorg_id             mult_org.id%type;
   vn_empresa_id             empresa.id%type;
   vv_teste                  varchar2(200);
   --
begin
   --
   vn_fase := 1;
   gv_sql := null;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_RETORNO_FCI') = 0 then
      --
      return;
      --
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CNPJ_EMPR' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'MES_REF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ANO_REF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COEFIC_IMPORT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NRO_FCI' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_SAIDA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_ENTR_PERC' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_RETORNO_FCI');
   --
   vn_fase := 1.3;
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CNPJ_EMPR' || trim(GV_ASPAS) || ' = ' || '''' || ev_cnpj_empr || '''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || ' MES_REF'|| trim(GV_ASPAS) || ' = ' || '''' ||ev_mes_ref||'''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'ANO_REF' || trim(GV_ASPAS) || ' = ' || en_ano_ref;
   --
   vn_fase := 2;
   --
   vv_teste := gv_sql;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_retorno_fci;
      --
   exception
      when others then
         --
         vv_teste := sqlerrm;
         --
         pk_csf_api_fci.gv_mensagem_log := 'Erro na pk_int_view_fci.pkb_ler_retorno_fci fase ('||vn_fase||'): '||sqlerrm;
         --
         declare
            vn_loggenerico_id  log_generico_cad.id%TYPE;
         begin
            --
            pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id    => vn_loggenerico_id
                                                , ev_mensagem             => pk_csf_api_cad.gv_mensagem_log
                                                , ev_resumo               => pk_csf_api_cad.gv_mensagem_log
                                                , en_tipo_log             => pk_csf_api_cad.erro_de_sistema
                                                , en_referencia_id        => null
                                                , ev_obj_referencia       => gv_obj_referencia
                                                , en_empresa_id           => gn_empresa_id
                                                );
            --
         exception
            when others then
               null;
         end;
   end;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_retorno_fci.count,0);
   exception
      when others then
      null;
   end;
   --
   vn_fase := 3;
   --
    if nvl(vt_tab_retorno_fci.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_retorno_fci.first..vt_tab_retorno_fci.last loop
         --
         vn_fase := 3.2;
         --
         vn_multorg_id := gn_multorg_id;
         --
         vn_empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id => vn_multorg_id
                                                              , ev_cpf_cnpj   => vt_tab_retorno_fci(i).cnpj_empr );
         --
         vn_fase := 4;
         --
         pk_csf_api_cad.gt_row_inf_item_fci := null;
         --
         pk_csf_api_cad.gt_row_inf_item_fci.aberturafciarq_id := en_aberturafciarq_id;
         pk_csf_api_cad.gt_row_inf_item_fci.vl_saida          := vt_tab_retorno_fci(i).vl_saida;
         pk_csf_api_cad.gt_row_inf_item_fci.vl_entr_tot       := vt_tab_retorno_fci(i).vl_entr_tot;
         pk_csf_api_cad.gt_row_inf_item_fci.coef_import       := vt_tab_retorno_fci(i).coef_import;
         pk_csf_api_cad.gt_row_inf_item_fci.dm_situacao       := 8;
         --
         vn_fase := 4.1;
         --
         pk_csf_api_cad.pkb_integr_infitemfci ( est_log_generico    => est_log_generico
                                              , est_row_infitemfci  => pk_csf_api_cad.gt_row_inf_item_fci
                                              , en_cnpj_empr        => vt_tab_retorno_fci(i).cnpj_empr
                                              , en_multorg_id       => pk_csf.fkg_multorg_id_empresa ( en_empresa_id => vn_empresa_id )
                                              , ev_cod_item         => vt_tab_retorno_fci(i).cod_item
                                              );
         --
         if nvl(pk_csf_api_cad.gt_row_inf_item_fci.id,0) > 0 then
            --
            vn_fase := 5;
            -- Integrar o Numero que foi Retornado do FCI
            pk_csf_api_cad.gt_row_retorno_fci.infitemfci_id := pk_csf_api_cad.gt_row_inf_item_fci.id;
            pk_csf_api_cad.gt_row_retorno_fci.item_id       := pk_csf_api_cad.gt_row_inf_item_fci.item_id;
            pk_csf_api_cad.gt_row_retorno_fci.nro_fci       := vt_tab_retorno_fci(i).nro_fci;
            pk_csf_api_cad.gt_row_retorno_fci.dm_tipo       := 2; -- Legado
            --
            vn_fase := 5.1;
            --
            pk_csf_api_cad.pkb_integr_retornofci ( est_log_generico    => est_log_generico
                                                 , est_row_retornofci  => pk_csf_api_cad.gt_row_retorno_fci
                                                 , en_cnpj_empr        => vt_tab_retorno_fci(i).cnpj_empr
                                                 , en_multorg_id       => pk_csf.fkg_multorg_id_empresa ( en_empresa_id => vn_empresa_id )
                                                 , ev_cod_item         => vt_tab_retorno_fci(i).cod_item
                                                 );
            --
         end if;
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_retorno_fci fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => erro_de_sistema
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia 
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_ler_retorno_fci;

-------------------------------------------------------------------------------------------------------
-- Processo que ira ler todos os registros da VW_CSF_AGLUT_CONTABIL
procedure pkb_aglut_contabil ( ev_cpf_cnpj in varchar2 ) is
   --
   vn_fase                   number := null;
   vn_multorg_id             mult_org.id%type;
   vt_log_generico           dbms_sql.number_table;
   vv_integr_indiv           varchar2(1) := null;
   vn_empresa_id             empresa.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   gv_sql := null;
   --
--   pkb_limpa_array;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_AGLUT_CONTABIL') = 0 then
      --
      return;
      --
   end if;
   --
   vn_fase := 1.1;
   --
   gv_obj_referencia := 'AGLUT_CONTABIL';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ_EMIT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_NAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_AGL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DESCR_AGL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NIVEL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_IND_CTA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'AR_COD_AGL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_INI' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_FIN' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_AGLUT_CONTABIL');
   --
   vn_fase := 1.3;
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ_EMIT' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' ORDER BY NIVEL ';
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_aglut_contabil;
      --
   exception
      when others then
         --
         vn_fase := 3.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_aglut_contabil fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => erro_de_sistema
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_aglut_contabil.count,0);
   exception
      when others then
      null;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_aglut_contabil.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_aglut_contabil.first..vt_tab_csf_aglut_contabil.last loop
         --
         vn_fase := 3.2;
         --
         vt_log_generico.delete;
         --
         vn_fase := 3.3;
         --
         vn_multorg_id := gn_multorg_id;
         --
         vn_empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id => vn_multorg_id
                                                              , ev_cpf_cnpj   => vt_tab_csf_aglut_contabil(i).cpf_cnpj_emit );
         --
         pk_csf_api_cad.gt_row_aglut_contabil.cod_agl     := vt_tab_csf_aglut_contabil(i).cod_agl;
         pk_csf_api_cad.gt_row_aglut_contabil.descr_agl   := vt_tab_csf_aglut_contabil(i).descr_agl;
         pk_csf_api_cad.gt_row_aglut_contabil.nivel       := vt_tab_csf_aglut_contabil(i).nivel;
         pk_csf_api_cad.gt_row_aglut_contabil.dm_ind_cta  := vt_tab_csf_aglut_contabil(i).dm_ind_cta;
         pk_csf_api_cad.gt_row_aglut_contabil.dt_ini      := vt_tab_csf_aglut_contabil(i).dt_ini;
         pk_csf_api_cad.gt_row_aglut_contabil.dt_fin      := vt_tab_csf_aglut_contabil(i).dt_fin;
         pk_csf_api_cad.gt_row_aglut_contabil.dm_st_proc  := 1;
         --
         pk_csf_api_cad.pkb_integr_aglutcontabil ( est_log_generico      => vt_log_generico
                                                 , est_row_aglutcontabil => pk_csf_api_cad.gt_row_aglut_contabil
                                                 , ev_cnpj_empr          => vt_tab_csf_aglut_contabil(i).cpf_cnpj_emit
                                                 , en_multorg_id         => vn_multorg_id
                                                 , ev_cod_nat            => vt_tab_csf_aglut_contabil(i).cod_nat
                                                 , ev_ar_cod_agl         => vt_tab_csf_aglut_contabil(i).ar_cod_agl
                                                 , en_loteintws_id       => null
                                                 );

         --
         vn_fase := 5.3;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         commit;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 6;
   --
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_aglut_contabil fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => erro_de_sistema
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_aglut_contabil;

-------------------------------------------------------------------------------------------------------
--| Processo de leitura dos Parâmetros DE-PARA de Item de Fornecedor para Emp. Usuária
procedure pkb_ler_item_fornc_eu ( ev_cpf_cnpj in varchar2)
is
   --
   vn_fase         number;
   vt_log_generico dbms_sql.number_table;
   --
   vn_empresa_id  empresa.id%type;
   vn_multorg_id  mult_org.id%type;
   --
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   --
   i pls_integer;
   --
begin
   --
   vn_fase := 1;
   --
   gv_sql := null;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PARAM_ITEM_ENTR') = 0 then
      --
      return;
      --
   end if;
   --
   vn_fase := 1.1;
   --
   gv_obj_referencia := 'PARAM_ITEM_ENTR';
   --
   vn_fase := 2;
   --
   gv_sql := 'select';
   gv_sql := gv_sql || ' '  || trim(gv_aspas) || 'cpf_cnpj_emit' || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cnpj_orig'     || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_ncm_orig'  || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_item_orig' || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_item_dest' || trim(gv_aspas);
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PARAM_ITEM_ENTR');
   --
   gv_sql := gv_sql || ' where cpf_cnpj_emit = ' || trim(gv_aspas) || ev_cpf_cnpj || trim(gv_aspas);
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_param_item_entr;
      --
   exception
      when others then
         --
         if sqlcode = -942 then
            --
            null;
            --
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_item_fornc_eu fase('||vn_fase||'):'||sqlerrm;
            --
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => erro_de_sistema
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => vn_empresa_id
                                                   );
               --
            exception
               when others then
                  --
                  null;
                  --
            end;
            --
         end if;
         --
   end;
   --
   vn_fase:= 3;
   --
   if nvl(vt_tab_csf_param_item_entr.count, 0) > 0 then
      --
      vn_multorg_id := gn_multorg_id;
      --
      vn_empresa_id := gn_empresa_id;
      --
      vn_fase := 3.1;
      --
      if vn_multorg_id is null or vn_empresa_id is null then
         --
         begin
            --
            select e.multorg_id, e.id
              into vn_multorg_id, vn_empresa_id
              from empresa e
              join pessoa  p on(p.id = e.pessoa_id)
             where p.cod_part = ev_cpf_cnpj;
            --
         exception
            when others then
               --
               null;
               --
         end;
         --
      end if;
      --
      vn_fase := 3.2;
      --
      for i in vt_tab_csf_param_item_entr.first..vt_tab_csf_param_item_entr.last loop
         --
         vn_fase := 4;
         --
         vt_log_generico.delete;
         --
         pk_csf_api_cad.gt_row_param_item_entr := null;
         --
         vn_fase := 5;
         --
         pk_csf_api_cad.gt_row_param_item_entr.empresa_id := vn_empresa_id;
         pk_csf_api_cad.gt_row_param_item_entr.cnpj_orig  := vt_tab_csf_param_item_entr(i).cnpj_orig;
         --
         vn_fase := 6;
         --
         pk_csf_api_cad.gt_row_param_item_entr.ncm_id_orig := pk_csf.fkg_Ncm_id (ev_cod_ncm => vt_tab_csf_param_item_entr(i).cod_ncm_orig);
         --
         vn_fase := 7;
         --
         pk_csf_api_cad.gt_row_param_item_entr.cod_item_orig := vt_tab_csf_param_item_entr(i).cod_item_orig;
         --
         vn_fase := 8;
         --
         begin
            --
            select id
              into pk_csf_api_cad.gt_row_param_item_entr.item_id_dest
              from item
             where cod_item   = vt_tab_csf_param_item_entr(i).cod_item_dest
               and empresa_id = vn_empresa_id;
            --
         exception
            when others then
               --
               pk_csf_api_cad.gt_row_param_item_entr.item_id_dest := null;
               --
         end;
         --
         vn_fase := 9;
         --
         --Integra os dados na tabela fixa do processo.
         pk_csf_api_cad.pkb_integr_param_item_entr ( est_log_generico      => vt_log_generico
                                                   , est_row_paramitementr => pk_csf_api_cad.gt_row_param_item_entr
                                                   );
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_item_fornc_eu fase('||vn_fase||'):'||sqlerrm;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => gv_mensagem_log
                                          , en_tipo_log           => erro_de_sistema
                                          , en_referencia_id      => null
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => vn_empresa_id
                                          );
      --
end pkb_ler_item_fornc_eu;

-------------------------------------------------------------------------------------------------------
-- Procedimento Parâmetros de Conversão de NFe
procedure pkb_ler_oper_fiscal_ent(ev_cpf_cnpj in varchar2)
is
   --
   vn_fase         number;
   vt_log_generico dbms_sql.number_table;
   --
   vn_empresa_id  empresa.id%type;
   vn_multorg_id  mult_org.id%type;
   --
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   --
   i pls_integer;
   --
begin
   --
   vn_fase := 1;
   --
   gv_sql := null;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PARAM_OPER_FISCAL_ENTR') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PARAM_OPER_FISCAL_ENTR';
   --
   vn_fase := 2;
   --
   gv_sql := 'select';
   gv_sql := gv_sql || ' '  || trim(gv_aspas) || 'cpf_cnpj_emit '     || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cfop_orig'          || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cnpj_orig'          || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'dm_raiz_cnpj_orig'  || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_ncm_orig'       || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_item_orig'      || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_st_icms_orig'   || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_st_ipi_orig'    || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cfop_dest'          || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'dm_rec_icms'        || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_st_icms_dest'   || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'dm_rec_ipi'         || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_st_ipi_dest'    || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'dm_rec_pis'         || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_st_pis_dest'    || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'dm_rec_cofins'      || trim(gv_aspas);
   gv_sql := gv_sql || ', ' || trim(gv_aspas) || 'cod_st_cofins_dest' || trim(gv_aspas);
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PARAM_OPER_FISCAL_ENTR');
   --
   gv_sql := gv_sql || ' where cpf_cnpj_emit = ' || trim(gv_aspas) || ev_cpf_cnpj || trim(gv_aspas);
   --
   vn_fase := 3;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_param_oper_fiscal_entr;
      --
   exception
      when others then
         --
         if sqlcode = -942 then
            --
            null;
            --
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_oper_fiscal_ent fase('||vn_fase||'):'||sqlerrm;
            --
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => erro_de_sistema
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => vn_empresa_id
                                                   );
               --
            exception
               when others then
                  --
                  null;
                  --
            end;
            --
         end if;
         --
   end;
   --
   vn_fase := 4;
   --
   if (vt_tab_param_oper_fiscal_entr.count) > 0 then
      --
      vn_multorg_id := gn_multorg_id;
      --
      vn_empresa_id := gn_empresa_id;
      --
      vn_fase := 4.1;
      --
      if vn_multorg_id is null or vn_empresa_id is null then
         --
         begin
            --
            select e.multorg_id, e.id
              into vn_multorg_id, vn_empresa_id
              from empresa e
              join pessoa  p on(p.id = e.pessoa_id)
             where p.cod_part = ev_cpf_cnpj;
            --
         exception
            when others then
               --
               null;
               --
         end;
         --
      end if;
      --
      vn_fase := 5;
      --
      for i in vt_tab_param_oper_fiscal_entr.first..vt_tab_param_oper_fiscal_entr.last loop
         --
         vn_fase := 6;
         --
         vt_log_generico.delete;
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr := null;
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.empresa_id        := vn_empresa_id;
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.cfop_id_orig      := pk_csf.fkg_cfop_id (en_cd => vt_tab_param_oper_fiscal_entr(i).cfop_orig);
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.cnpj_orig         := vt_tab_param_oper_fiscal_entr(i).cnpj_orig;
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.dm_raiz_cnpj_orig := vt_tab_param_oper_fiscal_entr(i).dm_raiz_cnpj_orig;
         --
         vn_fase := 7;
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.ncm_id_orig := pk_csf.fkg_Ncm_id (ev_cod_ncm => vt_tab_param_oper_fiscal_entr(i).cod_ncm_orig);
         --

         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.item_id_orig := pk_csf.fkg_Item_id_conf_empr ( en_empresa_id => vn_empresa_id
                                                                                        , ev_cod_item   => vt_tab_param_oper_fiscal_entr(i).cod_item_orig);
         --
         vn_fase := 8;
         --
         begin
            --
            select cs.id
              into pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_icms_orig
              from cod_st cs
             where cs.cod_st     = vt_tab_param_oper_fiscal_entr(i).cod_st_icms_orig
               and cs.tipoimp_id = (select id from tipo_imposto where cd = '1');
            --
         exception
            when others then
               --
               pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_icms_orig := null;
               --
         end;
         --
         vn_fase := 9;
         --
         begin
            --
            select cs.id
              into pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_ipi_orig
              from cod_st cs
             where cs.cod_st     = vt_tab_param_oper_fiscal_entr(i).cod_st_ipi_orig
               and cs.tipoimp_id = (select id from tipo_imposto where cd = '3');
            --
         exception
            when others then
               --
               pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_ipi_orig := null;
               --
         end;
         --
         vn_fase := 10;
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.cfop_id_dest := pk_csf.fkg_cfop_id (en_cd => vt_tab_param_oper_fiscal_entr(i).cfop_dest);
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.dm_rec_icms  := vt_tab_param_oper_fiscal_entr(i).dm_rec_icms;
         --
         begin
            --
            select cs.id
              into pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_icms_dest
              from cod_st cs
             where cs.cod_st = vt_tab_param_oper_fiscal_entr(i).cod_st_icms_dest
               and cs.tipoimp_id = (select id from tipo_imposto where cd = '1');
            --
         exception
            when others then
               --
               pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_icms_dest := null;
               --
         end;
         --
         vn_fase := 11;
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.dm_rec_ipi  := vt_tab_param_oper_fiscal_entr(i).dm_rec_ipi;
         --
         vn_fase := 12;
         --
         begin
            --
            select cs.id
              into pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_ipi_dest
              from cod_st cs
             where cs.cod_st     = vt_tab_param_oper_fiscal_entr(i).cod_st_ipi_dest
               and cs.tipoimp_id = (select id from tipo_imposto where cd = '3');
            --
         exception
            when others then
               --
               pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_ipi_dest := null;
               --
         end;
         --
         vn_fase := 13;
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.dm_rec_pis  := vt_tab_param_oper_fiscal_entr(i).dm_rec_pis;
         --
         vn_fase := 14;
         --
         begin
            --
            select cs.id
              into pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_pis_dest
              from cod_st cs
             where cs.cod_st     = vt_tab_param_oper_fiscal_entr(i).cod_st_pis_dest
               and cs.tipoimp_id = (select id from tipo_imposto where cd = '4');
            --
         exception
            when others then
               --
               pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_pis_dest := null;
               --
         end;
         --
         vn_fase := 15;
         --
         pk_csf_api_cad.gt_row_param_oper_fiscal_entr.dm_rec_cofins := vt_tab_param_oper_fiscal_entr(i).dm_rec_cofins;
         --
         vn_fase := 16;
         --
         begin
            --
            select cs.id
              into pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_cofins_dest
              from cod_st cs
             where cs.cod_st     = vt_tab_param_oper_fiscal_entr(i).cod_st_cofins_dest
               and cs.tipoimp_id = (select id from tipo_imposto where cd = '5');
            --
         exception
            when others then
               --
               pk_csf_api_cad.gt_row_param_oper_fiscal_entr.codst_id_cofins_dest := null;
               --
         end;
         --
         vn_fase := 17;
         --
         pk_csf_api_cad.pkb_integr_param_oper_entr ( est_log_generico      => vt_log_generico
                                                   , est_row_paramoperentr => pk_csf_api_cad.gt_row_param_oper_fiscal_entr
                                                   );
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_oper_fiscal_ent fase('||vn_fase||'):'||sqlerrm;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => gv_mensagem_log
                                          , en_tipo_log           => erro_de_sistema
                                          , en_referencia_id      => null
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => vn_empresa_id
                                          );
      --
end pkb_ler_oper_fiscal_ent;

-------------------------------------------------------------------------------------------------------
-- Processo que ira ler todos os registros da VW_CSF_RETORNO_FCI
procedure pkb_legado_fci ( ev_cpf_cnpj in varchar2 ) is
   --
   vn_fase                   number := null;
   vn_multorg_id             mult_org.id%type;
   vv_integr_indiv           varchar2(1) := null;
   vt_log_generico           dbms_sql.number_table;
   vn_empresa_id             empresa.id%type;
   vv_teste                  varchar2(1000);
   --
begin
   --
   vn_fase := 1;
   gv_sql := null;
   --
--   pkb_limpa_array;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ABERTURA_FCI') = 0 then
      --
      return;
      --
   end if;
   --
   vn_fase := 1.1;
   --
   gv_obj_referencia := 'ABERTURA_FCI';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CNPJ_EMPR' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'MES_REF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ANO_REF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NRO_PROT' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ABERTURA_FCI');
   --
   vn_fase := 1.3;
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CNPJ_EMPR' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_abertura_fci;
      --
   exception
      when others then
         --
         vn_fase := 3.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_legado_fci fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => erro_de_sistema
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_abertura_fci.count,0);
   exception
      when others then
      null;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_abertura_fci.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_abertura_fci.first..vt_tab_abertura_fci.last loop
         --
         vn_fase := 3.2;
         --
         vt_log_generico.delete;
         --
         vn_fase := 3.3;
         --
         vn_multorg_id := gn_multorg_id;
         --
         vn_empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id => vn_multorg_id
                                                              , ev_cpf_cnpj   => vt_tab_abertura_fci(i).cnpj_empr );
         --
         vn_fase := 4;
         --
         pk_csf_api_cad.gt_row_abertura_fci := null;
         pk_csf_api_cad.gt_row_abertura_fci_arq := null;
         --
         pk_csf_api_cad.gt_row_abertura_fci.dt_ini := trunc(to_date(vt_tab_abertura_fci(i).mes_ref||'/'||vt_tab_abertura_fci(i).ano_ref,'mm/yyyy'),'month');
         pk_csf_api_cad.gt_row_abertura_fci.dt_fin := last_day(to_date(vt_tab_abertura_fci(i).mes_ref||'/'||vt_tab_abertura_fci(i).ano_ref,'mm/yyyy'));
         --
         vn_fase := 4.1;
         --
         pk_csf_api_cad.pkb_integr_aberturafci ( est_log_generico    => vt_log_generico
                                               , est_row_aberturafci => pk_csf_api_cad.gt_row_abertura_fci
                                               , en_multorg_id       => gn_multorg_id
                                               , ev_cpf_cnpj_emit    => vt_tab_abertura_fci(i).cnpj_empr
                                               );
         --
         vn_fase := 4.2;
         --
         if nvl(pk_csf_api_cad.gt_row_abertura_fci.id,0) > 0 then
            --
            vn_fase := 5;
            --
            pk_csf_api_cad.gt_row_abertura_fci_arq.aberturafci_id := pk_csf_api_cad.gt_row_abertura_fci.id;
            --
            pk_csf_api_cad.gt_row_abertura_fci_arq.nro_prot       := vt_tab_abertura_fci(i).nro_prot;
            pk_csf_api_cad.gt_row_abertura_fci_arq.nro_sequencia  := 1;
            pk_csf_api_cad.gt_row_abertura_fci_arq.dm_situacao    := 8; -- Finalizado
            --
            vn_fase := 5.1;
            --
            pk_csf_api_cad.pkb_integr_aberturafciarq ( est_log_generico       => vt_log_generico
                                                     , est_row_aberturafciarq => pk_csf_api_cad.gt_row_abertura_fci_arq
                                                     );
            --
            vn_fase := 5.2;
            --
            if nvl(pk_csf_api_cad.gt_row_abertura_fci_arq.id,0) > 0 then
               --
               pkb_ler_retorno_fci ( est_log_generico     => vt_log_generico
                                   , en_aberturafciarq_id => pk_csf_api_cad.gt_row_abertura_fci_arq.id
                                   , ev_cnpj_empr         => vt_tab_abertura_fci(i).cnpj_empr
                                   , ev_mes_ref           => vt_tab_abertura_fci(i).mes_ref
                                   , en_ano_ref           => vt_tab_abertura_fci(i).ano_ref
                                   );
               --
            end if;
            --
         end if;
         --
         vn_fase := 5.3;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         commit;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 6;
   --
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_legado_fci fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => erro_de_sistema
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_legado_fci;
-------------------------------------------------------------------------------------------------------

--| Procedimento de integração dos dados de Item Componente/Insumo - Bloco K - Sped Fiscal

procedure pkb_item_insumo ( est_log_generico in out nocopy dbms_sql.number_table
                          , ev_cpf_cnpj      in            varchar2
                          , ev_cod_item      in            varchar2
                          , en_item_id       in            item.id%type 
                          )
is
   --
   vn_fase              number := 0;
   vn_loggenericocad_id log_generico_cad.id%type;
   vv_integr_indiv      varchar2(1) := 'N';
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITEM_INSUMO') = 0 then
      --
      return;
      --
   end if;
   --
   pk_csf_api_cad.gv_obj_referencia := 'ITEM_INSUMO';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   --if gv_formato_dt_erp is null then
   --   vv_integr_indiv := 'S';
   --   pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   --end if;
   --
   vt_tab_csf_item_insumo.delete;
   --
   gv_sql := 'select ';
   gv_sql := gv_sql || 'pk_csf.fkg_converte(' ||trim(GV_ASPAS) || 'CPF_CNPJ_EMIT' || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_ITEM'      || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_ITEM_COMP' || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'QTD_COMP'      || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'PERDA'         || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITEM_INSUMO' );
   --
   vn_fase := 2;
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ_EMIT' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || ' COD_ITEM'|| trim(GV_ASPAS) || ' = ' || '''' || ev_cod_item ||'''';
   --
   VN_FASE := 3;
   -- recupera os dados
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_item_insumo;
      --
   exception
      when others then
         --
         vn_fase := 3.1;
         --
         -- não registra erro caso a view não exista   
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_insumo fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => erro_de_sistema
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 4;
   --
   if nvl(vt_tab_csf_item_insumo.count,0) > 0 then
      --
      for i in vt_tab_csf_item_insumo.first .. vt_tab_csf_item_insumo.last loop
         --
         vn_fase := 5;
         --
         pk_csf_api_cad.gt_row_item_insumo := null;
         --
         vn_fase := 5.1;
         --
         pk_csf_api_cad.gt_row_item_insumo.qtd_comp := vt_tab_csf_item_insumo(i).qtd_comp;
         pk_csf_api_cad.gt_row_item_insumo.perda    := vt_tab_csf_item_insumo(i).perda;
         pk_csf_api_cad.gt_row_item_insumo.item_id  := en_item_id;
         --
         vn_fase := 5.2;
         --
         pk_csf_api_cad.pkb_integr_item_insumo ( est_log_generico    => est_log_generico
                                               , est_item_insumo     => pk_csf_api_cad.gt_row_item_insumo
                                               , en_multorg_id       => gn_multorg_id
                                               , ev_cpf_cnpj_emit    => ev_cpf_cnpj
                                               , ev_cod_item         => vt_tab_csf_item_insumo(i).cod_item
                                               , ev_cod_item_insumo  => vt_tab_csf_item_insumo(i).cod_item_comp
                                               );
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_insumo fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => erro_de_sistema
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_item_insumo;

-------------------------------------------------------------------------------------------------------

--| Procedimento de integração do Controle de Versão Contábil

procedure pkb_ctrl_ver_contab ( ev_cpf_cnpj  in varchar2 )
is
   --
   vn_fase             number := 0;
   vt_log_generico     dbms_sql.number_table;
   vn_loggenericocad_id   log_generico_cad.id%TYPE;
   vv_integr_indiv     varchar2(1) := 'N';
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_CTRL_VERSAO_CONTABIL') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'CTRL_VERSAO_CONTABIL';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vt_tab_csf_ctrl_ver_contab.delete;
   --
   gv_sql := 'select ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ_EMIT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DESCR' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_TIPO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_INI' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_FIN' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_CTRL_VERSAO_CONTABIL' );
   --
   vn_fase := 2;
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ_EMIT' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   --
   VN_FASE := 3;
   -- recupera os dados
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_ctrl_ver_contab;
      --
   exception
      when others then
         --
         vn_fase := 3.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ctrl_ver_contab fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 4;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_ctrl_ver_contab.count,0);
   exception
      when others then
      null;
   end;
   --
   if nvl(vt_tab_csf_ctrl_ver_contab.count,0) > 0 then
      --
      for i in vt_tab_csf_ctrl_ver_contab.first .. vt_tab_csf_ctrl_ver_contab.last loop
         --
         vn_fase := 5;
         --
         VT_LOG_GENERICO.delete;
         --
         pk_csf_api_cad.gt_row_ctrl_ver_contab := null;
         --
         vn_fase := 5.1;
         --
         pk_csf_api_cad.gt_row_ctrl_ver_contab.cd       := vt_tab_csf_ctrl_ver_contab(i).cd;
         pk_csf_api_cad.gt_row_ctrl_ver_contab.descr    := vt_tab_csf_ctrl_ver_contab(i).descr;
         pk_csf_api_cad.gt_row_ctrl_ver_contab.dm_tipo  := vt_tab_csf_ctrl_ver_contab(i).dm_tipo;
         pk_csf_api_cad.gt_row_ctrl_ver_contab.dt_ini   := vt_tab_csf_ctrl_ver_contab(i).dt_ini;
         pk_csf_api_cad.gt_row_ctrl_ver_contab.dt_fin   := vt_tab_csf_ctrl_ver_contab(i).dt_fin;
         --
         vn_fase := 5.2;
         --
         pk_csf_api_cad.pkb_integr_ctrl_ver_contab ( est_log_generico     => vt_log_generico
                                                   , est_ctrl_ver_contab  => pk_csf_api_cad.gt_row_ctrl_ver_contab
                                                   , en_multorg_id        => gn_multorg_id
                                                   , ev_cpf_cnpj_emit     => ev_cpf_cnpj
                                                   );
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 6;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ctrl_ver_contab fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_ctrl_ver_contab;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field do Histórico Padrão
procedure pkb_hist_padrao_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                            , ev_cpf_cnpj        in  varchar2
                            , ev_cod_hist       in  varchar2
                            , sn_multorg_id     in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_HIST_PADRAO_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'HIST_PADRAO';
   --
   gv_sql := null;
   --
   vt_tab_csf_hist_padrao_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_HIST' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_HIST_PADRAO_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_HIST' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_hist||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_HIST' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_hist_padrao_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_hist_padrao_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Historico padrão: ' || ev_cod_hist
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_hist_padrao_ff.count > 0 then
      --
      for i in vt_tab_csf_hist_padrao_ff.first..vt_tab_csf_hist_padrao_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_hist_padrao_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da  Plano de contas - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_HIST_PADRAO_FF'
                                                 , ev_atributo          => vt_tab_csf_hist_padrao_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_hist_padrao_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Historico padrão cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Historico padrão: ' || ev_cod_hist
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_hist_padrao_ff fase('||vn_fase||') cod_hist('||pk_csf_api_cad.gt_row_hist_padrao.cod_hist||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => 'Historico padrão: ' || ev_cod_hist
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => pk_csf_api_cad.gt_row_hist_padrao.id
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_hist_padrao_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração do Histórico Padrão
procedure pkb_hist_padrao ( ev_cpf_cnpj  in  varchar2 )
is
   --
   vn_fase            number := 0;
   vt_log_generico    dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv    varchar2(1) := 'N';
   vn_multorg_id      mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_empresa_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   else
      --
      gn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => gn_empresa_id );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_HIST_PADRAO') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'HIST_PADRAO';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_hist_padrao.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_HIST' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DESCR_HIST' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_HIST_PADRAO' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_hist_padrao;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_hist_padrao fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_hist_padrao.count,0);
   exception
      when others then
      null;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_hist_padrao.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_hist_padrao.first .. vt_tab_csf_hist_padrao.last loop
         --
         vn_fase := 3.2;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.3;
         --
         pk_csf_api_cad.gt_row_hist_padrao := null;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            --
            vn_multorg_id := gn_multorg_id;
            --
         end if;
         --
         pkb_hist_padrao_ff( est_log_generico  => vt_log_generico
                           , ev_cpf_cnpj => vt_tab_csf_hist_padrao(i).cpf_cnpj
                           , ev_cod_hist => vt_tab_csf_hist_padrao(i).cod_hist
                           , sn_multorg_id  => vn_multorg_id);
         --
         vn_fase := 3.4;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pk_csf_api_cad.gt_row_hist_padrao.empresa_id  := pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id    => vn_multorg_id
                                                                                              , ev_cpf_cnpj      => vt_tab_csf_hist_padrao(i).cpf_cnpj );
         --
         pk_csf_api_cad.gt_row_hist_padrao.cod_hist    := vt_tab_csf_hist_padrao(i).cod_hist;
         pk_csf_api_cad.gt_row_hist_padrao.descr_hist  := vt_tab_csf_hist_padrao(i).descr_hist;
         --
         vn_fase := 3.5;
         --
         pk_csf_api_cad.pkb_integr_Hist_Padrao ( est_log_generico     => vt_log_generico
                                               , est_row_Hist_Padrao  => pk_csf_api_cad.gt_row_hist_padrao );
         --
         vn_fase := 3.6;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         commit;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_hist_padrao fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_hist_padrao;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field do centro de custo
procedure pkb_centro_custo_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                            , ev_cpf_cnpj        in  varchar2
                            , ev_cod_ccus        in  varchar2
                            , sn_multorg_id      in  out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_CENTRO_CUSTO_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'CENTRO_CUSTO';
   --
   gv_sql := null;
   --
   vt_tab_csf_centro_custo_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select pk_csf.fkg_converte(';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS)|| ')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_CENTRO_CUSTO_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ccus||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_centro_custo_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_centro_custo_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Centro custo: ' || ev_cod_ccus
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_centro_custo_ff.count > 0 then
      --
      for i in vt_tab_csf_centro_custo_ff.first..vt_tab_csf_centro_custo_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_centro_custo_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da  Plano de contas - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_CENTRO_CUSTO_FF'
                                                 , ev_atributo          => vt_tab_csf_centro_custo_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_centro_custo_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Centro custo cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Centro custo: ' || ev_cod_ccus
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_centro_custo_ff fase('||vn_fase||') cod_ccus('||pk_csf_api_cad.gt_row_centro_custo.cod_ccus||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => 'Centro custo: ' || ev_cod_ccus
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => pk_csf_api_cad.gt_row_centro_custo.id
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_centro_custo_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração do centro de custo
procedure pkb_centro_custo ( ev_cpf_cnpj  in  varchar2 )
is
   --
   vn_fase            number := 0;
   vt_log_generico    dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv    varchar2(1) := 'N';
   vn_multorg_id      mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_empresa_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   else
      --
      gn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => gn_empresa_id );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_CENTRO_CUSTO') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'CENTRO_CUSTO';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_centro_custo.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select pk_csf.fkg_converte(';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS)||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_INC_ALT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'DESCR_CCUS' || trim(GV_ASPAS) ||')';
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_CENTRO_CUSTO' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_centro_custo;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_centro_custo fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 3;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_centro_custo.count,0);
   exception
      when others then
      null;
   end;
   --
   if nvl(vt_tab_csf_centro_custo.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_centro_custo.first .. vt_tab_csf_centro_custo.last loop
         --
         vn_fase := 3.2;
         --
         vt_log_generico.delete;
         --
         vn_fase := 3.3;
         --
         pk_csf_api_cad.gt_row_centro_custo := null;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            --
            vn_multorg_id := gn_multorg_id;
            --
         end if;
         --
         pkb_centro_custo_ff( est_log_generico  => vt_log_generico
                            , ev_cpf_cnpj    => vt_tab_csf_centro_custo(i).cpf_cnpj
                            , ev_cod_ccus    => vt_tab_csf_centro_custo(i).cod_ccus
                            , sn_multorg_id  => vn_multorg_id);
         --
         vn_fase := 3.4;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pk_csf_api_cad.gt_row_centro_custo.empresa_id  := pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id    => vn_multorg_id
                                                                                               , ev_cpf_cnpj      => vt_tab_csf_centro_custo(i).cpf_cnpj );
         --
         pk_csf_api_cad.gt_row_centro_custo.dt_inc_alt  := vt_tab_csf_centro_custo(i).dt_inc_alt;
         pk_csf_api_cad.gt_row_centro_custo.cod_ccus    := vt_tab_csf_centro_custo(i).cod_ccus;
         pk_csf_api_cad.gt_row_centro_custo.descr_ccus  := vt_tab_csf_centro_custo(i).descr_ccus;
         --
         vn_fase := 3.5;
         --
         pk_csf_api_cad.pkb_integr_Centro_Custo ( est_log_generico      => vt_log_generico
                                                , est_row_Centro_Custo  => pk_csf_api_cad.gt_row_centro_custo
                                                , ed_dt_fim_reg_0000    => sysdate );
         --
         vn_fase := 3.6;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         commit;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   --
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_centro_custo fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_centro_custo;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração de Aglutinação Contábil
procedure pkb_pc_aglut_contabil ( est_log_generico in out nocopy dbms_sql.number_table
                                , ev_cpf_cnpj      in            varchar2
                                , ev_cod_cta       in            varchar2
                                , en_planoconta_id in            plano_conta.id%type
                                , en_multorg_id    in            mult_org.id%type
                                )
is
   --
   vn_fase                       number := null;
   vn_loggenericocad_id             log_generico_cad.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PC_AGLUT_CONTABIL') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PC_AGLUT_CONTABIL';
   --
   gv_sql := null;
   --
   vt_tab_csf_subconta_correlata.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ_EMIT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_AGL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PC_AGLUT_CONTABIL' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ_EMIT' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_cta || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_pc_aglut_contabil;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pc_aglut_contabil fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_pc_aglut_contabil.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_pc_aglut_contabil.first..vt_tab_csf_pc_aglut_contabil.last loop
         --
         vn_fase := 3.3;
         --
         pk_csf_api_cad.gt_row_pc_aglut_contabil.planoconta_id := en_planoconta_id;
         --
         pk_csf_api_cad.pkb_integr_pcaglutcontabil ( est_log_generico        => est_log_generico
                                                   , est_row_pcaglutcontabil => pk_csf_api_cad.gt_row_pc_aglut_contabil
                                                   , en_cnpj_empr            => vt_tab_csf_pc_aglut_contabil(i).cpf_cnpj_emit
                                                   , en_multorg_id           => en_multorg_id
                                                   , ev_cod_agl              => vt_tab_csf_pc_aglut_contabil(i).cod_agl
                                                   , ev_cod_ccus             => vt_tab_csf_pc_aglut_contabil(i).cod_ccus
                                                   );
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pc_aglut_contabil fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => gv_mensagem_log
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => null       
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_pc_aglut_contabil;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração SubConta correlata
procedure pkb_subconta_correlata ( est_log_generico in out nocopy dbms_sql.number_table
                                 , ev_cpf_cnpj      in            varchar2
                                 , ev_cod_cta       in            varchar2
                                 , en_planoconta_id in            plano_conta.id%type
                                 , en_multorg_id    in            mult_org.id%type
                                 )
is
   --
   vn_fase                       number := null;
   vn_loggenerico_id             log_generico_cad.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_SUBCONTA_CORRELATA') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'SUBCONTA_CORRELATA';
   --
   gv_sql := null;
   --
   vt_tab_csf_subconta_correlata.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IDT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA_CORR' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_NATSUBCNT' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_SUBCONTA_CORRELATA' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_cta || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_subconta_correlata;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_subconta_correlata fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_subconta_correlata.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_subconta_correlata.first .. vt_tab_csf_subconta_correlata.last loop
         --
         vn_fase := 3.3;
         --
         pk_csf_api_cad.gt_subconta_correlata := null;
         --
         pk_csf_api_cad.gt_subconta_correlata.planoconta_id := en_planoconta_id;
         pk_csf_api_cad.gt_subconta_correlata.cod_idt       := vt_tab_csf_subconta_correlata(i).cod_idt;
         --
         pk_csf_api_cad.pkb_integr_subconta_correlata ( est_log_generico           => est_log_generico
                                                      , est_row_subconta_correlata => pk_csf_api_cad.gt_subconta_correlata
                                                      , en_empresa_id              => pk_csf.fkg_empresa_id_cpf_cnpj ( en_multorg_id  => en_multorg_id
                                                                                                                     , ev_cpf_cnpj    => vt_tab_csf_subconta_correlata(i).cpf_cnpj )
                                                      , ev_cod_cta_corr            => vt_tab_csf_subconta_correlata(i).cod_cta_corr
                                                      , ev_cd_natsubcnt            => vt_tab_csf_subconta_correlata(i).cd_natsubcnt
                                                      );
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_subconta_correlata fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => gv_mensagem_log
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => null       
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_subconta_correlata;
-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex field do plano de contas referenciado

procedure pkb_pc_referen_multorg_ff ( est_log_generico  in out nocopy  dbms_sql.number_table
                                    , ev_cpf_cnpj       in varchar2
                                    , ev_cod_cta        in varchar2
                                    , ev_cod_ent_ref    in varchar2
                                    , ev_cod_cta_ref    in varchar2
                                    , sn_multorg_id     in out mult_org.id%type
                                    , ev_cod_ccus       in varchar2
                                    )
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PC_REFEREN_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PC_REFEREN';
   --
   gv_sql := null;
   --
   vt_tab_csf_pc_referen_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql         || trim(GV_ASPAS) || 'CPF_CNPJ'     || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA'      || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ENT_REF'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA_REF'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CCUS'     || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO'     || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR'        || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PC_REFEREN_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_cta||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_ENT_REF' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ent_ref||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_CTA_REF' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_cta_ref||'''';
   --
   if ev_cod_ccus is not null then
      --
      gv_sql := gv_sql || ' AND nvl(' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS) || ',' ||''''|| ev_cod_ccus||''''|| ') = ' ||''''|| ev_cod_ccus||'''';
      --
   else
      --
      gv_sql := gv_sql || ' AND nvl(' || trim(gv_aspas) || 'COD_CCUS' || trim(gv_aspas) || ',' ||''''||'0'||''''||') = '|| '0'; 
      --
   end if;
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_ENT_REF' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_CTA_REF' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_pc_referen_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_int.pkb_pc_referen_multorg_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
      end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_pc_referen_ff.count > 0 then
      --
      for i in vt_tab_csf_pc_referen_ff.first..vt_tab_csf_pc_referen_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_pc_referen_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_PC_REFEREN_FF'
                                                 , ev_atributo          => vt_tab_csf_pc_referen_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_pc_referen_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         sn_multorg_id := vn_multorg_id;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pc_referen_multorg_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => gv_mensagem_log
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => gn_referencia_id
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_pc_referen_multorg_ff;

-------------------------------------------------------------------------------------------------------
/*
--| Procedimento de integração Flex field do plano de contas referenciado

procedure pkb_pc_referen_ff ( est_log_generico  in  out nocopy  dbms_sql.number_table
                            , en_pcreferen_id   in  pc_referen.id%type
                            , ev_cpf_cnpj       in  varchar2
                            , ev_cod_cta        in  varchar2
                            , ev_cod_ent_ref    in  varchar2
                            , ev_cod_cta_ref    in  varchar2
                            , en_multorg_id     in  mult_org.id%type )
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PC_REFEREN_FF') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PC_REFEREN';
   --
   gv_sql := null;
   --
   vt_tab_csf_pc_referen_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ENT_REF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA_REF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PC_REFEREN_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_cta||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_ENT_REF' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ent_ref||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_CTA_REF' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_cta_ref||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_ENT_REF' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_CTA_REF' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_pc_referen_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_int.pkb_pc_referen_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
      end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_pc_referen_ff.count > 0 then
      --
      for i in vt_tab_csf_pc_referen_ff.first..vt_tab_csf_pc_referen_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_pc_referen_ff(i).atributo not in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;                                                      
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            --
            pk_csf_api_cad.pkb_integr_pc_referen_ff ( est_log_generico    => est_log_generico
                                                    , en_pcreferen_id     => en_pcreferen_id
                                                    , ev_atributo         => vt_tab_csf_pc_referen_ff(i).atributo
                                                    , ev_valor            => vt_tab_csf_pc_referen_ff(i).valor
                                                    );
           --
           vn_fase := 6;
           --
        end if;
        --
      end loop;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pc_referen_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => gn_referencia_id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_pc_referen_ff;*/

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração do plano de contas referenciado por Periodo
procedure pkb_pc_referen_period ( est_log_generico  in  out nocopy  dbms_sql.number_table
                                , ev_cpf_cnpj       in  varchar2
                                , ev_cod_cta        in  plano_conta.cod_cta%type
                                , en_planoconta_id  in  plano_conta.id%type
                                , en_multorg_id     in  mult_org.id%type)
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   vn_multorg_id := en_multorg_id;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PC_REFEREN_PERIOD') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PLANO_CONTA';
   --
   gv_sql := null;
   --
   vt_tab_csf_pc_referen_period.delete;
   --
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ENT_REF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA_REF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_INI' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_FIN' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PC_REFEREN_PERIOD' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_cta || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_pc_referen_period;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pc_referen_period fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id      => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_pc_referen_period.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_pc_referen_period.first .. vt_tab_csf_pc_referen_period.last loop
         --
         vn_fase := 3.3;
         --
         pk_csf_api_cad.gt_row_pc_referen := null;
         --
         pk_csf_api_cad.gt_row_pc_referen.planoconta_id := en_planoconta_id;
         pk_csf_api_cad.gt_row_pc_referen.dt_ini        := vt_tab_csf_pc_referen_period(i).dt_ini;
         pk_csf_api_cad.gt_row_pc_referen.dt_fin        := vt_tab_csf_pc_referen_period(i).dt_fin;
         --
         pk_csf_api_cad.pkb_integr_pc_referen_period ( est_log_generico    => est_log_generico
                                                     , est_row_pc_referen  => pk_csf_api_cad.gt_row_pc_referen
                                                     , en_empresa_id       => pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id  => en_multorg_id
                                                                                                                  , ev_cpf_cnpj    => vt_tab_csf_pc_referen_period(i).cpf_cnpj )
                                                     , ev_cod_ent_ref      => trim(vt_tab_csf_pc_referen_period(i).cod_ent_ref)
                                                     , ev_cod_cta_ref      => trim(vt_tab_csf_pc_referen_period(i).cod_cta_ref)
                                                     , ev_cod_ccus         => trim(vt_tab_csf_pc_referen_period(i).cod_ccus) 
                                                     );
         --
         vn_fase := 3.5;
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
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pc_referen_period fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => gv_mensagem_log
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => null
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_pc_referen_period;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração do plano de contas referenciado
procedure pkb_pc_referen ( est_log_generico  in  out nocopy  dbms_sql.number_table
                         , ev_cpf_cnpj       in  varchar2
                         , ev_cod_cta        in  plano_conta.cod_cta%type
                         , en_planoconta_id  in  plano_conta.id%type
                         , en_multorg_id     in  mult_org.id%type
                         )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_multorg_id         mult_org.id%type; 
   --
begin
   --
   vn_fase := 1;
   vn_multorg_id := en_multorg_id;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PC_REFEREN') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PLANO_CONTA';
   --
   gv_sql := null;
   --
   vt_tab_csf_pc_referen.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql         || trim(GV_ASPAS) || 'CPF_CNPJ'    || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA'     || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ENT_REF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA_REF' || trim(GV_ASPAS);
   --gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CCUS'    || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || ' pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS)||') ';
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PC_REFEREN' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_cta || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_pc_referen;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pc_referen fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_pc_referen.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_pc_referen.first .. vt_tab_csf_pc_referen.last loop
         --
         vn_fase := 3.3;
         --
         pkb_pc_referen_multorg_ff ( est_log_generico  => est_log_generico
                                   , ev_cpf_cnpj       => vt_tab_csf_pc_referen(i).cpf_cnpj
                                   , ev_cod_cta        => vt_tab_csf_pc_referen(i).cod_cta
                                   , ev_cod_ent_ref    => vt_tab_csf_pc_referen(i).cod_ent_ref
                                   , ev_cod_cta_ref    => vt_tab_csf_pc_referen(i).cod_cta_ref
                                   , sn_multorg_id     => vn_multorg_id
                                   , ev_cod_ccus       => vt_tab_csf_pc_referen(i).cod_ccus
                                   );
         --
         --if nvl(vn_multorg_id, 0) = nvl(en_multorg_id, 0) or
         --   nvl(vn_multorg_id, 0) = 0 then
            --
            pk_csf_api_cad.gt_row_pc_referen := null;
            --
            pk_csf_api_cad.gt_row_pc_referen.planoconta_id := en_planoconta_id;
            --
            vn_fase := 3.4;
            --
            pk_csf_api_cad.pkb_integr_pc_referen ( est_log_generico    => est_log_generico
                                                 , est_row_pc_referen  => pk_csf_api_cad.gt_row_pc_referen
                                                 , en_empresa_id       => pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id  => en_multorg_id
                                                                                                              , ev_cpf_cnpj    => vt_tab_csf_pc_referen(i).cpf_cnpj )
                                                 , ev_cod_ent_ref      => trim(vt_tab_csf_pc_referen(i).cod_ent_ref)
                                                 , ev_cod_cta_ref      => trim(vt_tab_csf_pc_referen(i).cod_cta_ref)
                                                 , ev_cod_ccus         => trim(vt_tab_csf_pc_referen(i).cod_ccus) );
            --
            vn_fase := 3.5;
            --
            commit;
            --
            /*if nvl(vn_multorg_id, 0) = 0 then
               --
               gv_cabec_log := 'Mult Org do plano de contas referenciado '||vt_tab_csf_pc_referen(i).cod_cta_ref||' do plano de conta '||vt_tab_csf_pc_referen(i).cod_cta|| ' não informado.';
               --
               gv_mensagem_log := 'O plano de contas referenciado '||vt_tab_csf_pc_referen(i).cod_cta_ref||' do plano de conta '||vt_tab_csf_pc_referen(i).cod_cta||' foi registrado com o Mult Org do plano de conta ' ||vt_tab_csf_pc_referen(i).cod_cta || '('||en_multorg_id||') por falta de informação.';
               --
               declare
                  vn_loggenericocad_id  log_generico_cad.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                      , ev_mensagem        => gv_mensagem_log
                                                      , ev_resumo          => gv_cabec_log
                                                      , en_tipo_log        => informacao
                                                      , en_referencia_id   => null
                                                      , ev_obj_referencia  => gv_obj_referencia
                                                      , en_empresa_id         => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
            end if;*/
            --
         /*else
            --
            gv_mensagem_log := 'O plano de contas referenciado '||vt_tab_csf_pc_referen(i).cod_cta_ref||' do plano de conta '||vt_tab_csf_pc_referen(i).cod_cta|| ' não pertence ao mesmo Mult Org do plano de conta '||vt_tab_csf_pc_referen(i).cod_cta || '.'
                               ||'Mult Org do plano de contas referenciado: '||vn_multorg_id||'Mult Org do plano de contas: '||en_multorg_id;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => informacao
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         end if;*/
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pc_referen fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_pc_referen;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field do plano de contas
procedure pkb_plano_conta_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                            , ev_cpf_cnpj       in  varchar2
                            , ev_cod_cta        in  varchar2
                            , sn_multorg_id     in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PLANO_CONTA_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PLANO_CONTA';
   --
   gv_sql := null;
   --
   vt_tab_csf_plano_conta_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select pk_csf.fkg_converte(';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS)||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PLANO_CONTA_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_cta||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_plano_conta_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_plano_conta_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => ' Plano de contas: ' || ev_cod_cta
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_plano_conta_ff.count > 0 then
      --
      for i in vt_tab_csf_plano_conta_ff.first..vt_tab_csf_plano_conta_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_plano_conta_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da  Plano de contas - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_PLANO_CONTA_FF'
                                                 , ev_atributo          => vt_tab_csf_plano_conta_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_plano_conta_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := ' Plano de contas cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Plano de contas: ' || ev_cod_cta
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_plano_conta_ff fase('||vn_fase||') cod_cta('||pk_csf_api_cad.gt_row_plano_conta.cod_cta||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => 'Plano de contas: ' || ev_cod_cta
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => pk_csf_api_cad.gt_row_plano_conta.id
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_plano_conta_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração do plano de contas
procedure pkb_plano_conta ( ev_cpf_cnpj  in  varchar2 )
is
   --
   vn_fase            number := 0;
   vt_log_generico    dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv    varchar2(1) := 'N';
   vn_multorg_id      mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_empresa_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   else
      --
      gn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => gn_empresa_id );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PLANO_CONTA') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PLANO_CONTA';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_plano_conta.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select pk_csf.fkg_converte(';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS)||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_INC_ALT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_NAT_PC' || trim(GV_ASPAS)||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'DM_IND_CTA' || trim(GV_ASPAS)||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NIVEL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_CTA_SUP' || trim(GV_ASPAS)||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'DESCR_CTA' || trim(GV_ASPAS)||')';
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PLANO_CONTA' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   --
   -- Monta a condição de ordenação
   gv_sql := gv_sql || ' order by ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ' , ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'NIVEL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ' , ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ' , ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'DT_INC_ALT' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_plano_conta;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_plano_conta fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 3;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_plano_conta.count,0);
   exception
      when others then
      null;
   end;
   --
   if nvl(vt_tab_csf_plano_conta.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_plano_conta.first .. vt_tab_csf_plano_conta.last loop
         --
         vn_fase := 3.2;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.3;
         --
         pk_csf_api_cad.gt_row_plano_conta := null;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            --
            vn_multorg_id := gn_multorg_id;
            --
         end if;
         --
         pkb_plano_conta_ff( est_log_generico  => vt_log_generico
                           , ev_cpf_cnpj       => vt_tab_csf_plano_conta(i).cpf_cnpj
                           , ev_cod_cta        => vt_tab_csf_plano_conta(i).cod_cta
                           , sn_multorg_id     => vn_multorg_id);
         --
         --
         vn_fase := 3.4;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pk_csf_api_cad.gt_row_plano_conta.empresa_id  := pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id   => vn_multorg_id
                                                                                              , ev_cpf_cnpj     => vt_tab_csf_plano_conta(i).cpf_cnpj );
         --
         pk_csf_api_cad.gt_row_plano_conta.dt_inc_alt  := vt_tab_csf_plano_conta(i).dt_inc_alt;
         pk_csf_api_cad.gt_row_plano_conta.dm_ind_cta  := vt_tab_csf_plano_conta(i).dm_ind_cta;
         pk_csf_api_cad.gt_row_plano_conta.nivel       := vt_tab_csf_plano_conta(i).nivel;
         pk_csf_api_cad.gt_row_plano_conta.cod_cta     := trim(vt_tab_csf_plano_conta(i).cod_cta);
         pk_csf_api_cad.gt_row_plano_conta.descr_cta   := trim(vt_tab_csf_plano_conta(i).descr_cta);
         --
         vn_fase := 3.5;
         --
         pk_csf_api_cad.pkb_integr_Plano_Conta ( est_log_generico     => vt_log_generico
                                               , est_row_Plano_Conta  => pk_csf_api_cad.gt_row_plano_conta
                                               , ev_cod_nat           => trim(vt_tab_csf_plano_conta(i).cod_nat_pc)
                                               , ev_cod_cta_sup       => trim(vt_tab_csf_plano_conta(i).cod_cta_sup)
                                               , ed_dt_fim_reg_0000   => sysdate );
         --
         vn_fase := 3.6;
         --
         pkb_pc_referen ( est_log_generico  => vt_log_generico
                        , ev_cpf_cnpj       => vt_tab_csf_plano_conta(i).cpf_cnpj
                        , ev_cod_cta        => trim(vt_tab_csf_plano_conta(i).cod_cta)
                        , en_planoconta_id  => pk_csf_api_cad.gt_row_plano_conta.id
                        , en_multorg_id     => vn_multorg_id);
         --
         vn_fase := 3.7;
         --
         pkb_pc_referen_period ( est_log_generico  => vt_log_generico
                               , ev_cpf_cnpj       => vt_tab_csf_plano_conta(i).cpf_cnpj
                               , ev_cod_cta        => trim(vt_tab_csf_plano_conta(i).cod_cta)
                               , en_planoconta_id  => pk_csf_api_cad.gt_row_plano_conta.id
                               , en_multorg_id     => vn_multorg_id);
         --
         vn_fase := 3.8;
         --
         pkb_subconta_correlata( est_log_generico  => vt_log_generico
                               , ev_cpf_cnpj       => vt_tab_csf_plano_conta(i).cpf_cnpj
                               , ev_cod_cta        => trim(vt_tab_csf_plano_conta(i).cod_cta)
                               , en_planoconta_id  => pk_csf_api_cad.gt_row_plano_conta.id
                               , en_multorg_id     => vn_multorg_id);
         --
         vn_fase := 3.9;
         --
         pkb_pc_aglut_contabil( est_log_generico  => vt_log_generico
                              , ev_cpf_cnpj       => vt_tab_csf_plano_conta(i).cpf_cnpj
                              , ev_cod_cta        => trim(vt_tab_csf_plano_conta(i).cod_cta)
                              , en_planoconta_id  => pk_csf_api_cad.gt_row_plano_conta.id
                              , en_multorg_id     => vn_multorg_id);
         --
         vn_fase := 4;
         --
         if nvl(vt_log_generico.count,0) > 0 then -- Erro de validação
            --
            update plano_conta
               set dm_st_proc = 2 -- Erro de Validação
             where id = nvl(pk_csf_api_cad.gt_row_plano_conta.id,0);
            --
         else
            --
            update plano_conta
               set dm_st_proc = 1 -- Validado
             where id = nvl(pk_csf_api_cad.gt_row_plano_conta.id,0);
            --
         end if;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(vt_log_generico.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         commit;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_plano_conta fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_plano_conta;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field de Observação do Lançamento Fiscal

procedure pkb_obs_lancto_fiscal_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                                  , ev_cod_obs        in  varchar2
                                  , sn_multorg_id     in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_OBS_LANCTO_FISCAL_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'OBS_LANCTO_FISCAL';
   --
   gv_sql := null;
   --
   vt_tab_obs_lancto_fiscal_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'COD_OBS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_OBS_LANCTO_FISCAL_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'COD_OBS' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_obs||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'COD_OBS' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_obs_lancto_fiscal_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_obs_lancto_fiscal_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Observação do Lançamento Fiscal: ' || ev_cod_obs
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => pk_csf_api_cad.gt_row_obs_lancto_fiscal.id
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_obs_lancto_fiscal_ff.count > 0 then
      --
      for i in vt_tab_obs_lancto_fiscal_ff.first..vt_tab_obs_lancto_fiscal_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_obs_lancto_fiscal_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Observação do Lançamento Fiscal - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_OBS_LANCTO_FISCAL_FF'
                                                 , ev_atributo          => vt_tab_obs_lancto_fiscal_ff(i).atributo
                                                 , ev_valor             => vt_tab_obs_lancto_fiscal_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Observação do Lançamento Fiscal cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Observação do Lançamento Fiscal: ' || ev_cod_obs
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_obs_lancto_fiscal_ff fase('||vn_fase||') cod_obs('||pk_csf_api_cad.gt_row_obs_lancto_fiscal.cod_obs||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => 'Observação do Lançamento Fiscal: ' || ev_cod_obs
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => pk_csf_api_cad.gt_row_obs_lancto_fiscal.id
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_obs_lancto_fiscal_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração de Observação do Lançamento Fiscal
procedure pkb_obs_lancto_fiscal
is
   --
   vn_fase            number := 0;
   vt_log_generico    dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   vn_fase := 1.1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_OBS_LANCTO_FISCAL') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'OBS_LANCTO_FISCAL';
   --
   gv_sql := null;
   --
   vt_tab_obs_lancto_fiscal.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select o.';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'COD_OBS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', o.' || trim(GV_ASPAS) || 'TXT' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   if trim(gv_sistema_em_nuvem) = 'SIM' then
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_OBS_LANCTO_FISCAL' ) || ' o, ';
      gv_sql := gv_sql || trim(replace(fkg_monta_from ( ev_obj => 'VW_CSF_OBS_LANCTO_FISCAL_FF' ), 'from', '')) || ' f';
      --
      gv_sql := gv_sql || ' WHERE f.' || trim(GV_ASPAS) || 'COD_OBS' || trim(GV_ASPAS) || ' = o.' || trim(GV_ASPAS) || 'COD_OBS' || trim(GV_ASPAS);
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS) || ' = ' || '''' || 'COD_MULT_ORG' || '''';
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS) || ' = ' || '''' || trim(gv_multorg_cd) || '''';
      --
   else
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_OBS_LANCTO_FISCAL' ) || ' o';
      --
   end if;
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_obs_lancto_fiscal;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_obs_lancto_fiscal fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_obs_lancto_fiscal.count,0);
   exception
      when others then
      null;
   end;
   --
   if nvl(vt_tab_obs_lancto_fiscal.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_obs_lancto_fiscal.first .. vt_tab_obs_lancto_fiscal.last loop
         --
         vn_fase := 3.2;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.3;
         --
         pk_csf_api_cad.gt_row_obs_lancto_fiscal := null;
         --
         pk_csf_api_cad.gt_row_obs_lancto_fiscal.cod_obs    := vt_tab_obs_lancto_fiscal(i).cod_obs;
         pk_csf_api_cad.gt_row_obs_lancto_fiscal.txt        := vt_tab_obs_lancto_fiscal(i).txt;
         --
         vn_multorg_id := gn_multorg_id;
         --
         pkb_obs_lancto_fiscal_ff( est_log_generico  => vt_log_generico
                                 , ev_cod_obs        => vt_tab_obs_lancto_fiscal(i).cod_obs
                                 , sn_multorg_id     => vn_multorg_id );
         --
         vn_fase := 3.4;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pk_csf_api_cad.gt_row_obs_lancto_fiscal.multorg_id := vn_multorg_id;
         --
         vn_fase := 3.5;
         --
         pk_csf_api_cad.pkb_integr_obs_lancto_fiscal ( est_log_generico       => vt_log_generico
                                                     , est_obs_lancto_fiscal  => pk_csf_api_cad.gt_row_obs_lancto_fiscal
                                                     , en_empresa_id          => gn_empresa_id
                                                     );
         --
         vn_fase := 3.6;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
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
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_obs_lancto_fiscal fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id      => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_obs_lancto_fiscal;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field de informações complementar do documento fiscal
procedure pkb_infor_comp_dcto_fiscal_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                                       , ev_cod_infor      in  varchar2
                                       , sn_multorg_id     in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_INFORCOMP_DCTOFISCAL_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'INFOR_COMP_DCTO_FISCAL';
   --
   gv_sql := null;
   --
   vt_tab_csf_inf_comp_dcto_fi_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'COD_INFOR' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_INFORCOMP_DCTOFISCAL_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'COD_INFOR' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_infor||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'COD_INFOR' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_inf_comp_dcto_fi_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_infor_comp_dcto_fiscal_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'informações complementar do documento fiscal: ' || ev_cod_infor
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => pk_csf_api_cad.gt_row_infor_comp_dcto_fiscal.id
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_inf_comp_dcto_fi_ff.count > 0 then
      --
      for i in vt_tab_csf_inf_comp_dcto_fi_ff.first..vt_tab_csf_inf_comp_dcto_fi_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_inf_comp_dcto_fi_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da informações complementar do documento fiscal - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_INFORCOMP_DCTOFISCAL_FF'
                                                 , ev_atributo          => vt_tab_csf_inf_comp_dcto_fi_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_inf_comp_dcto_fi_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Informações complementar do documento fiscal cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'informações complementar do documento fiscal: ' || ev_cod_infor
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_infor_comp_dcto_fiscal_ff fase('||vn_fase||') cod_infor('||pk_csf_api_cad.gt_row_infor_comp_dcto_fiscal.cod_infor||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => 'informações complementar do documento fiscal: ' || ev_cod_infor
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => pk_csf_api_cad.gt_row_infor_comp_dcto_fiscal.id
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_infor_comp_dcto_fiscal_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração de informações complementar do documento fiscal
procedure pkb_inf_comp_dcto_fis
is
   --
   vn_fase               number := 0;
   vt_log_generico       dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   vn_fase := 1.1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_INFOR_COMP_DCTO_FISCAL') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'INFOR_COMP_DCTO_FISCAL';
   --
   gv_sql := null;
   --
   vt_tab_csf_inf_comp_dcto_fis.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select i.';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'COD_INFOR' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', i.' || trim(GV_ASPAS) || 'TXT' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   if trim(gv_sistema_em_nuvem) = 'SIM' then
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_INFOR_COMP_DCTO_FISCAL' ) || ' i, ';
      gv_sql := gv_sql || trim(replace(fkg_monta_from ( ev_obj => 'VW_CSF_INFORCOMP_DCTOFISCAL_FF' ), 'from', '')) || ' f';
      --
      gv_sql := gv_sql || ' WHERE f.' || trim(GV_ASPAS) || 'COD_INFOR' || trim(GV_ASPAS) || ' = i.' || trim(GV_ASPAS) || 'COD_INFOR' || trim(GV_ASPAS);
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS) || ' = ' || '''' || 'COD_MULT_ORG' || '''';
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS) || ' = ' || '''' || trim(gv_multorg_cd) || '''';
      --
   else
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_INFOR_COMP_DCTO_FISCAL' ) || ' i';
      --
   end if;
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_inf_comp_dcto_fis;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_inf_comp_dcto_fis fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_inf_comp_dcto_fis.count,0);
   exception
      when others then
      null;
   end;
   --
   if nvl(vt_tab_csf_inf_comp_dcto_fis.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_inf_comp_dcto_fis.first .. vt_tab_csf_inf_comp_dcto_fis.last loop
         --
         vn_fase := 3.2;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.3;
         --
         pk_csf_api_cad.gt_row_infor_comp_dcto_fiscal := null;
         --
         pk_csf_api_cad.gt_row_infor_comp_dcto_fiscal.cod_infor  := vt_tab_csf_inf_comp_dcto_fis(i).cod_infor;
         pk_csf_api_cad.gt_row_infor_comp_dcto_fiscal.txt        := vt_tab_csf_inf_comp_dcto_fis(i).txt;
         --
         vn_multorg_id := gn_multorg_id;
         --
         pkb_infor_comp_dcto_fiscal_ff( est_log_generico  => vt_log_generico
                                      , ev_cod_infor      => vt_tab_csf_inf_comp_dcto_fis(i).cod_infor
                                      , sn_multorg_id     => vn_multorg_id);
         --
         vn_fase := 3.4;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pk_csf_api_cad.gt_row_infor_comp_dcto_fiscal.multorg_id := vn_multorg_id;
         --
         vn_fase := 3.4;
         --
         pk_csf_api_cad.pkb_integr_inf_comp_dcto_fis ( est_log_generico            => vt_log_generico
                                                     , est_infor_comp_dcto_fiscal  => pk_csf_api_cad.gt_row_infor_comp_dcto_fiscal 
                                                     , en_empresa_id               => gn_empresa_id
                                                     );
         --
         vn_fase := 3.5;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
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
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_inf_comp_dcto_fis fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id      => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_inf_comp_dcto_fis;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field de Natureza da Operação
procedure pkb_nat_oper_ff( est_log_generico  in    out nocopy  dbms_sql.number_table
                         , ev_cod_nat        in  varchar2
                         , sn_multorg_id     in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_NAT_OPER_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'NAT_OPER';
   --
   gv_sql := null;
   --
   vt_tab_csf_nat_oper_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select pk_csf.fkg_converte(';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'COD_NAT' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_NAT_OPER_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'COD_NAT' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_nat||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'COD_NAT' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_nat_oper_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_nat_oper_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Natureza da Operação: ' || ev_cod_nat
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_nat_oper_ff.count > 0 then
      --
      for i in vt_tab_csf_nat_oper_ff.first..vt_tab_csf_nat_oper_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_nat_oper_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Natureza da Operação - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_NAT_OPER_FF'
                                                 , ev_atributo          => vt_tab_csf_nat_oper_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_nat_oper_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Natureza da Operação cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Natureza da Operação: ' || ev_cod_nat
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_nat_oper_ff fase('||vn_fase||') cod_nat('||ev_cod_nat||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => 'Natureza da Operação: ' || ev_cod_nat
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_nat_oper_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração de Natureza da Operação
procedure pkb_nat_oper
is
   --
   vn_fase               number := 0;
   vt_log_generico       dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_natoper_id         Nat_oper.id%type;
   vn_multorg_id         mult_org.id%type;
   vn_dm_st_proc         Nat_oper.dm_st_proc%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   vn_fase := 1.1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_NAT_OPER') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'NAT_OPER';
   --
   gv_sql := null;
   --
   vt_tab_csf_nat_oper.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select pk_csf.fkg_converte(n.';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'COD_NAT' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(n.' || trim(GV_ASPAS) || 'DESCR_NAT' || trim(GV_ASPAS) || ')';
   --
   vn_fase := 1.1;
   --
   if trim(gv_sistema_em_nuvem) = 'SIM' then
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_NAT_OPER' ) || ' n, ';
      gv_sql := gv_sql || trim(replace(fkg_monta_from ( ev_obj => 'VW_CSF_NAT_OPER_FF' ), 'from', '')) || ' f';
      --
      gv_sql := gv_sql || ' WHERE f.' || trim(GV_ASPAS) || 'COD_NAT' || trim(GV_ASPAS) || ' = n.' || trim(GV_ASPAS) || 'COD_NAT' || trim(GV_ASPAS);
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS) || ' = ' || '''' || 'COD_MULT_ORG' || '''';
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS) || ' = ' || '''' || trim(gv_multorg_cd) || '''';
      --
   else
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_NAT_OPER' ) || ' n';
      --
   end if;
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_nat_oper;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_nat_oper fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_nat_oper.count,0);
   exception
      when others then
      null;
   end;
   --
   if nvl(vt_tab_csf_nat_oper.count,0) > 0 then
      --
      for i in vt_tab_csf_nat_oper.first .. vt_tab_csf_nat_oper.last loop
         --
         vn_fase := 3.1;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.2;
         --
         vn_multorg_id := gn_multorg_id;
         --
         pkb_nat_oper_ff( est_log_generico  => vt_log_generico
                        , ev_cod_nat => vt_tab_csf_nat_oper(i).cod_nat
                        , sn_multorg_id  => vn_multorg_id);
         --
         vn_fase := 3.3;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         if nvl(vt_log_generico.count,0) > 0 then
            --
            vn_dm_st_proc := 2;
            --
         else
            --
            vn_dm_st_proc := 1;
            --
         end if;
         --
         vn_fase := 3.4;
         --
         pk_csf_api_cad.pkb_cria_nat_oper( ev_cod_nat    => vt_tab_csf_nat_oper(i).cod_nat
                                         , ev_descr_nat  => vt_tab_csf_nat_oper(i).descr_nat
                                         , en_multorg_id => vn_multorg_id
                                         , en_dm_st_proc => vn_dm_st_proc);
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
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_nat_oper fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_nat_oper;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração flex field dos Impostos do Bem
procedure pkb_rec_imp_bem_ativo_imob_ff( est_log_generico  in out nocopy  dbms_sql.number_table
                                       , ev_cpf_cnpj       varchar2
                                       , ev_cod_ind_bem    varchar2
                                       , en_cd_tipo_imp    number
                                       , sn_multorg_id     in out mult_org.id%type )
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_RECIMP_BEMATIVO_IMOB_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   gv_sql := null;
   --
   vt_tab_csf_recimp_bem_ativo_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_TIPO_IMP' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_RECIMP_BEMATIVO_IMOB_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ind_bem||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'CD_TIPO_IMP' || trim(GV_ASPAS) || ' = ' ||en_cd_tipo_imp;
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'CD_TIPO_IMP' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_recimp_bem_ativo_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_rec_imp_bem_ativo_imob_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Imposto: '|| en_cd_tipo_imp ||' do Bem: ' || ev_cod_ind_bem
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_recimp_bem_ativo_ff.count > 0 then
      --
      for i in vt_tab_csf_recimp_bem_ativo_ff.first..vt_tab_csf_recimp_bem_ativo_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_recimp_bem_ativo_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_RECIMP_BEMATIVO_IMOB_FF'
                                                 , ev_atributo          => vt_tab_csf_recimp_bem_ativo_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_recimp_bem_ativo_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_rec_imp_bem_ativo_imob_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => 'Imposto: '|| en_cd_tipo_imp ||' do Bem: ' || ev_cod_ind_bem
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => gn_referencia_id
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_rec_imp_bem_ativo_imob_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração dos Impostos do Bem
procedure pkb_rec_imp_bem_ativo_imob ( est_log_generico in out nocopy  dbms_sql.number_table
                                     , ev_cpf_cnpj      in varchar2
                                     , ev_cod_ind_bem   in bem_ativo_imob.cod_ind_bem%type
                                     , en_multorg_id    in out mult_org.id%type )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv    varchar2(1) := 'N';
   vn_empresa_id      empresa.id%type := 0;
   vv_cd_tipo_imp     tipo_imposto.cd%type;
   vn_multorg_id      mult_org.id%type;
   --
   cursor c_rec_imp (en_empresa_id in empresa.id%type ) is
      select s.aliq         ALIQ
           , s.qtde_mes     QTDE_MES
           , s.tipoimp_id   TIPOIMP_ID
        from rec_imp_subgrupo_pat s
           , bem_ativo_imob b
       where b.empresa_id = en_empresa_id
         and b.cod_ind_bem = ev_cod_ind_bem
         and b.subgrupopat_id = s.subgrupopat_id;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_REC_IMP_BEM_ATIVO_IMOB') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_rec_imp_bem_ativo.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_TIPO_IMP' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ALIQ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'QTDE_MES' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'QTDE_MES_REAL' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_REC_IMP_BEM_ATIVO_IMOB' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_ind_bem || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_rec_imp_bem_ativo;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_rec_imp_bem_ativo_imob fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_rec_imp_bem_ativo.count,0) > 0 then
      --
      for i in vt_tab_csf_rec_imp_bem_ativo.first .. vt_tab_csf_rec_imp_bem_ativo.last loop
         --
         pk_csf_api_cad.gt_row_rec_imp_bem_ativo_imob := null;
         --
         vn_fase := 3.1;
         --
         pkb_rec_imp_bem_ativo_imob_ff( est_log_generico  => est_log_generico
                                      , ev_cpf_cnpj       => vt_tab_csf_rec_imp_bem_ativo(i).cpf_cnpj
                                      , ev_cod_ind_bem    => vt_tab_csf_rec_imp_bem_ativo(i).cod_ind_bem
                                      , en_cd_tipo_imp    => vt_tab_csf_rec_imp_bem_ativo(i).cd_tipo_imp
                                      , sn_multorg_id     => vn_multorg_id );
         --
         if nvl(vn_multorg_id, 0) = nvl(en_multorg_id, 0) or
            nvl(vn_multorg_id, 0) = 0 then
            --
            pk_csf_api_cad.gt_row_rec_imp_bem_ativo_imob.aliq          := vt_tab_csf_rec_imp_bem_ativo(i).aliq;
            pk_csf_api_cad.gt_row_rec_imp_bem_ativo_imob.qtde_mes      := vt_tab_csf_rec_imp_bem_ativo(i).qtde_mes;
            pk_csf_api_cad.gt_row_rec_imp_bem_ativo_imob.qtde_mes_real := vt_tab_csf_rec_imp_bem_ativo(i).qtde_mes_real;
            --
            vn_fase := 3.2;
            --
            pk_csf_api_cad.pkb_integr_rec_imp_bem_ativo ( est_log_generico            => est_log_generico
                                                        , est_rec_imp_bem_ativo_imob  => pk_csf_api_cad.gt_row_rec_imp_bem_ativo_imob
                                                        , en_multorg_id               => en_multorg_id
                                                        , ev_cpf_cnpj                 => vt_tab_csf_rec_imp_bem_ativo(i).cpf_cnpj
                                                        , ev_cod_ind_bem              => vt_tab_csf_rec_imp_bem_ativo(i).cod_ind_bem
                                                        , ev_cd_tipo_imp              => vt_tab_csf_rec_imp_bem_ativo(i).cd_tipo_imp );
            --
            commit;
            --
            if nvl(vn_multorg_id, 0) = 0 then
               --
               gv_cabec_log := 'Mult Org do Imposto '||vt_tab_csf_rec_imp_bem_ativo(i).cd_tipo_imp|| ' do Bem: '||vt_tab_csf_rec_imp_bem_ativo(i).cod_ind_bem||'não informado.';
               --
               gv_mensagem_log := 'O Imposto '||vt_tab_csf_rec_imp_bem_ativo(i).cd_tipo_imp|| ' do Bem: '||vt_tab_csf_rec_imp_bem_ativo(i).cod_ind_bem||' foi registrado com o Mult Org do Bem: '||vt_tab_csf_rec_imp_bem_ativo(i).cod_ind_bem || '('||en_multorg_id||') por falta de informação.';
               --
               declare
                  vn_loggenericocad_id  log_generico_cad.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                      , ev_mensagem        => gv_mensagem_log
                                                      , ev_resumo          => gv_cabec_log
                                                      , en_tipo_log        => informacao
                                                      , en_referencia_id   => null
                                                      , ev_obj_referencia  => gv_obj_referencia
                                                      , en_empresa_id         => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
            end if;
            --
         else
            --
            gv_mensagem_log := 'O Imposto '||vt_tab_csf_rec_imp_bem_ativo(i).cd_tipo_imp|| ' do Bem: '||vt_tab_csf_rec_imp_bem_ativo(i).cod_ind_bem||' não pertence ao mesmo Mult Org do Bem: '||vt_tab_csf_rec_imp_bem_ativo(i).cod_ind_bem || '.'
                               ||'Mult Org da Imposto: '||vn_multorg_id||'Mult Org do Bem: '||en_multorg_id;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => informacao
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         end if;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_rec_imp_bem_ativo_imob fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_rec_imp_bem_ativo_imob;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração flex field dos documentos fiscais do bem
procedure pkb_itnf_bem_ativo_imob_ff( est_log_generico     in  out nocopy  dbms_sql.number_table
                                    , ev_cpf_cnpj          in  varchar2
                                    , ev_cod_ind_bem       in  varchar2
                                    , en_dm_ind_emit       in  number
                                    , ev_cod_part          in  varchar2
                                    , ev_cod_mod           in  varchar2
                                    , ev_serie             in  varchar2
                                    , en_num_doc           in  number
                                    , en_num_item          in  number
                                    , sn_multorg_id        in out mult_org.id%type
                                    , sv_valor             out number  ) 
                                    -- , 
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   vv_vl_dif_aliq       itnf_bem_ativo_imob.vl_dif_aliq%type;
   --
  -- ev_valor number;
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITNF_BEM_ATIVO_IMOB_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   gv_sql := null;
   --
   vt_tab_itnf_bem_ativo_imob_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_IND_EMIT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_MOD' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NUM_DOC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NUM_ITEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITNF_BEM_ATIVO_IMOB_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ind_bem||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'DM_IND_EMIT' || trim(GV_ASPAS) || ' = ' ||en_dm_ind_emit;
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_part||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_MOD' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_mod||'''';
   --
   if trim(ev_serie) is not null then
      --
      gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS) || ' = ' ||''''||ev_serie||'''';
      --
   else
      --
      gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS) || ' is null';
      --
   end if;
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'NUM_DOC' || trim(GV_ASPAS) || ' = ' ||en_num_doc;
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'NUM_ITEM' || trim(GV_ASPAS) || ' = ' ||en_num_item;
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'DM_IND_EMIT' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_MOD' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'NUM_DOC' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'NUM_ITEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_itnf_bem_ativo_imob_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_itnf_bem_ativo_imob_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Item: '||en_num_item||'da Nota: '||en_num_doc||' do Bem: '|| ev_cod_ind_bem
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_itnf_bem_ativo_imob_ff.count > 0 then
      --
      for i in vt_tab_itnf_bem_ativo_imob_ff.first..vt_tab_itnf_bem_ativo_imob_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_itnf_bem_ativo_imob_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_ITNF_BEM_ATIVO_IMOB_FF'
                                                 , ev_atributo          => vt_tab_itnf_bem_ativo_imob_ff(i).atributo
                                                 , ev_valor             => vt_tab_itnf_bem_ativo_imob_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
           --
           vn_fase := 6.1;
           --                                             
        if vt_tab_itnf_bem_ativo_imob_ff(i).atributo in ('VL_DIF_ALIQ') then
            --
            vn_fase := 6.2; 
            --
            vv_vl_dif_aliq := null;
            pk_csf_api_cad.pkb_val_atrib_bem_ativo ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_ITNF_BEM_ATIVO_IMOB_FF'
                                                 , ev_atributo          => vt_tab_itnf_bem_ativo_imob_ff(i).atributo
                                                 , ev_valor             => vt_tab_itnf_bem_ativo_imob_ff(i).valor
                                                 , sv_vl_dif_aliq       => vv_vl_dif_aliq
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6.3;
           --
           if vv_vl_dif_aliq is not null then
              sv_valor := vv_vl_dif_aliq;
           end if;
            --
           -- sv_valor    := vt_tab_itnf_bem_ativo_imob_ff(i).valor;
         --
        end if; 
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_itnf_bem_ativo_imob_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => 'Item: '||en_num_item||'da Nota: '||en_num_doc||' do Bem: '|| ev_cod_ind_bem
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => gn_referencia_id
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_itnf_bem_ativo_imob_ff;
-------------------------------------------------------------------------------------------------------
--| Procedimento de integração dos documentos fiscais do bem
procedure pkb_itnf_bem_ativo_imob ( est_log_generico in  out nocopy  dbms_sql.number_table
                                  , ev_cpf_cnpj      in  varchar2
                                  , ev_cod_ind_bem   in  bem_ativo_imob.cod_ind_bem%type
                                  , en_dm_ind_emit   in  nf_bem_ativo_imob.dm_ind_emit%type
                                  , ev_cod_part      in  pessoa.cod_part%type
                                  , ev_cod_mod       in  mod_fiscal.cod_mod%type
                                  , ev_serie         in  nf_bem_ativo_imob.serie%type
                                  , en_num_doc       in  nf_bem_ativo_imob.num_doc%type
                                  , en_multorg_id    in  mult_org.id%type
                                  )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv    varchar2(1) := 'N';
   vn_num_item        number;
   vn_multorg_id      mult_org.id%type;
   vn_valor number;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITNF_BEM_ATIVO_IMOB') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_itnf_bem_ativo_imob.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_IND_EMIT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_MOD' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NUM_DOC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NUM_ITEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_ITEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_ICMS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_BC_PIS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_BC_COFINS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_FRETE' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_ICMS_ST' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITNF_BEM_ATIVO_IMOB' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_ind_bem || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'DM_IND_EMIT' || trim(GV_ASPAS) || ' = ' || '''' || en_dm_ind_emit || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_part || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_MOD' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_mod || '''';
   --
   if ev_serie is not null then
      --
      gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS) || ' = ' || '''' || ev_serie || '''';
      --
   else
      --
      gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS) || ' is null';
      --
   end if;
   --
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'NUM_DOC' || trim(GV_ASPAS) || ' = ' || '''' || en_num_doc || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_itnf_bem_ativo_imob;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_itnf_bem_ativo_imob fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_itnf_bem_ativo_imob.count,0) > 0 then
      --
      vn_num_item := 0;
      --
      for i in vt_tab_csf_itnf_bem_ativo_imob.first .. vt_tab_csf_itnf_bem_ativo_imob.last loop
         --
         vn_fase := 3.2;
         --
         pk_csf_api_cad.gt_row_itnf_bem_ativo_imob := null;
         --
         pkb_itnf_bem_ativo_imob_ff( est_log_generico  => est_log_generico
                                   , ev_cpf_cnpj       => vt_tab_csf_itnf_bem_ativo_imob(i).cpf_cnpj
                                   , ev_cod_ind_bem    => vt_tab_csf_itnf_bem_ativo_imob(i).cod_ind_bem
                                   , en_dm_ind_emit    => vt_tab_csf_itnf_bem_ativo_imob(i).dm_ind_emit
                                   , ev_cod_part       => vt_tab_csf_itnf_bem_ativo_imob(i).cod_part
                                   , ev_cod_mod        => vt_tab_csf_itnf_bem_ativo_imob(i).cod_mod
                                   , ev_serie          => vt_tab_csf_itnf_bem_ativo_imob(i).serie
                                   , en_num_doc        => vt_tab_csf_itnf_bem_ativo_imob(i).num_doc
                                   , en_num_item       => vt_tab_csf_itnf_bem_ativo_imob(i).num_item
                                   , sn_multorg_id     => vn_multorg_id 
                                   , sv_valor          => vn_valor);
         --
         if nvl(vn_multorg_id, 0) = nvl(en_multorg_id, 0) or
            nvl(vn_multorg_id, 0) = 0 then
            --
            vn_num_item := nvl(vn_num_item,0) + 1;
            --
            pk_csf_api_cad.gt_row_itnf_bem_ativo_imob.num_item     := vn_num_item; --vt_tab_csf_itnf_bem_ativo_imob(i).num_item;
            pk_csf_api_cad.gt_row_itnf_bem_ativo_imob.vl_item      := vt_tab_csf_itnf_bem_ativo_imob(i).vl_item;
            pk_csf_api_cad.gt_row_itnf_bem_ativo_imob.vl_icms      := vt_tab_csf_itnf_bem_ativo_imob(i).vl_icms;
            pk_csf_api_cad.gt_row_itnf_bem_ativo_imob.vl_bc_pis    := vt_tab_csf_itnf_bem_ativo_imob(i).vl_bc_pis;
            pk_csf_api_cad.gt_row_itnf_bem_ativo_imob.vl_bc_cofins := vt_tab_csf_itnf_bem_ativo_imob(i).vl_bc_cofins;
            pk_csf_api_cad.gt_row_itnf_bem_ativo_imob.vl_frete     := vt_tab_csf_itnf_bem_ativo_imob(i).vl_frete;
            pk_csf_api_cad.gt_row_itnf_bem_ativo_imob.vl_icms_st   := vt_tab_csf_itnf_bem_ativo_imob(i).vl_icms_st;
            --
            vn_fase := 3.3;
            --
            pk_csf_api_cad.pkb_integr_itnf_bem_ativo_imob ( est_log_generico        => est_log_generico
                                                          , est_itnf_bem_ativo_imob => pk_csf_api_cad.gt_row_itnf_bem_ativo_imob
                                                          , en_multorg_id           => en_multorg_id
                                                          , ev_cpf_cnpj             => vt_tab_csf_itnf_bem_ativo_imob(i).cpf_cnpj
                                                          , ev_cod_ind_bem          => vt_tab_csf_itnf_bem_ativo_imob(i).cod_ind_bem
                                                          , en_dm_ind_emit          => vt_tab_csf_itnf_bem_ativo_imob(i).dm_ind_emit
                                                          , ev_cod_part             => vt_tab_csf_itnf_bem_ativo_imob(i).cod_part
                                                          , ev_cod_mod              => vt_tab_csf_itnf_bem_ativo_imob(i).cod_mod
                                                          , ev_serie                => vt_tab_csf_itnf_bem_ativo_imob(i).serie
                                                          , en_num_doc              => vt_tab_csf_itnf_bem_ativo_imob(i).num_doc
                                                          , ev_cod_item             => vt_tab_csf_itnf_bem_ativo_imob(i).cod_item
                                                          , ev_valor                => vn_valor
                                                          );
            --

            vn_fase := 3.4;
            --
            commit;
            if nvl(vn_multorg_id, 0) = 0 then
               --
               gv_cabec_log := 'Mult Org do Item '||vt_tab_csf_itnf_bem_ativo_imob(i).cod_item|| ' da Nota: '||vt_tab_csf_itnf_bem_ativo_imob(i).num_doc||' do Bem: '||vt_tab_csf_itnf_bem_ativo_imob(i).cod_ind_bem||'não informado.';
               --
               gv_mensagem_log := 'O Item '||vt_tab_csf_itnf_bem_ativo_imob(i).cod_item|| ' da Nota: '||vt_tab_csf_itnf_bem_ativo_imob(i).num_doc||' do Bem: '||vt_tab_csf_itnf_bem_ativo_imob(i).cod_ind_bem||' foi registrado com o Mult Org da Nota: '||vt_tab_csf_itnf_bem_ativo_imob(i).num_doc||' do Bem: '||vt_tab_csf_itnf_bem_ativo_imob(i).cod_ind_bem || '('||en_multorg_id||') por falta de informação.';
               --
               declare
                  vn_loggenericocad_id  log_generico_cad.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                      , ev_mensagem        => gv_mensagem_log
                                                      , ev_resumo          => gv_cabec_log
                                                      , en_tipo_log        => informacao
                                                      , en_referencia_id   => null
                                                      , ev_obj_referencia  => gv_obj_referencia
                                                      , en_empresa_id      => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
            end if;
            --
         else
            --
            gv_mensagem_log := 'O Item '||vt_tab_csf_itnf_bem_ativo_imob(i).cod_item|| ' da Nota: '||vt_tab_csf_itnf_bem_ativo_imob(i).num_doc||' do Bem: '||vt_tab_csf_itnf_bem_ativo_imob(i).cod_ind_bem||' não pertence ao mesmo Mult Org da Nota: '||vt_tab_csf_itnf_bem_ativo_imob(i).num_doc||' do Bem: '||vt_tab_csf_itnf_bem_ativo_imob(i).cod_ind_bem || '.'
                               ||'Mult Org do Item: '||vn_multorg_id||'Mult Org da Nota: '||en_multorg_id;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => informacao
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id      => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         end if;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_itnf_bem_ativo_imob fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_itnf_bem_ativo_imob;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração flex field dos documentos fiscais do bem
procedure pkb_nf_bem_ativo_imob_ff( est_log_generico  in out nocopy  dbms_sql.number_table
                                  , ev_cpf_cnpj       in varchar2
                                  , ev_cod_ind_bem    in varchar2
                                  , en_dm_ind_emit    in number
                                  , ev_cod_part       in varchar2
                                  , ev_cod_mod        in varchar2
                                  , ev_serie          in varchar2
                                  , en_num_doc        in number
                                  , sn_multorg_id     in out mult_org.id%type )
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_NF_BEM_ATIVO_IMOB_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   gv_sql := null;
   --
   vt_tab_csf_nf_bemativo_imob_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_IND_EMIT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_MOD' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NUM_DOC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_NF_BEM_ATIVO_IMOB_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ind_bem||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'DM_IND_EMIT' || trim(GV_ASPAS) || ' = ' ||en_dm_ind_emit;
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_part||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_MOD' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_mod||'''';
   --
   if trim(ev_serie) is not null then
      --
      gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS) || ' = ' ||''''||ev_serie||'''';
      --
   else
      --
      gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS) || ' is null';
      --
   end if;
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'NUM_DOC' || trim(GV_ASPAS) || ' = ' ||en_num_doc;
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'DM_IND_EMIT' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_MOD' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'NUM_DOC' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_nf_bemativo_imob_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_nf_bem_ativo_imob_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Nota: '||en_num_doc||' do Bem: '|| ev_cod_ind_bem
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
   end;
   --
   vn_fase := 3;
   --
   --
   if vt_tab_csf_nf_bemativo_imob_ff.count > 0 then
      --
      for i in vt_tab_csf_nf_bemativo_imob_ff.first..vt_tab_csf_nf_bemativo_imob_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_nf_bemativo_imob_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_NF_BEM_ATIVO_IMOB_FF'
                                                 , ev_atributo          => vt_tab_csf_nf_bemativo_imob_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_nf_bemativo_imob_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_nf_bem_ativo_imob_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => 'Nota: '||en_num_doc||' do Bem: '|| ev_cod_ind_bem
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => gn_referencia_id
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_nf_bem_ativo_imob_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração dos documentos fiscais do bem
procedure pkb_nf_bem_ativo_imob ( est_log_generico in out nocopy  dbms_sql.number_table
                                , ev_cpf_cnpj      in  varchar2
                                , ev_cod_ind_bem   in  bem_ativo_imob.cod_ind_bem%type
                                , en_multorg_id    in out mult_org.id%type )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv    varchar2(1) := 'N';
   vn_multorg_id      mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_NF_BEM_ATIVO_IMOB') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_nf_bem_ativo_imob.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_IND_EMIT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_MOD' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'SERIE' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NUM_DOC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CHV_NFE_CTE' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_DOC' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_NF_BEM_ATIVO_IMOB' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_ind_bem || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_nf_bem_ativo_imob;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_nf_bem_ativo_imob fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_nf_bem_ativo_imob.count,0) > 0 then
      --
      for i in vt_tab_csf_nf_bem_ativo_imob.first .. vt_tab_csf_nf_bem_ativo_imob.last loop
         --
         vn_fase := 3.2;
         --
         pk_csf_api_cad.gt_row_nf_bem_ativo_imob := null;
         --
         pkb_nf_bem_ativo_imob_ff( est_log_generico  => est_log_generico
                                 , ev_cpf_cnpj       => vt_tab_csf_nf_bem_ativo_imob(i).cpf_cnpj
                                 , ev_cod_ind_bem    => vt_tab_csf_nf_bem_ativo_imob(i).cod_ind_bem
                                 , en_dm_ind_emit    => vt_tab_csf_nf_bem_ativo_imob(i).dm_ind_emit
                                 , ev_cod_part       => vt_tab_csf_nf_bem_ativo_imob(i).cod_part
                                 , ev_cod_mod        => vt_tab_csf_nf_bem_ativo_imob(i).cod_mod
                                 , ev_serie          => vt_tab_csf_nf_bem_ativo_imob(i).serie
                                 , en_num_doc        => vt_tab_csf_nf_bem_ativo_imob(i).num_doc
                                 , sn_multorg_id     => vn_multorg_id);
         --
         if nvl(vn_multorg_id, 0) = nvl(en_multorg_id, 0) or
            nvl(vn_multorg_id, 0) = 0 then
            --
            pk_csf_api_cad.gt_row_nf_bem_ativo_imob.dm_ind_emit   := vt_tab_csf_nf_bem_ativo_imob(i).dm_ind_emit;
            pk_csf_api_cad.gt_row_nf_bem_ativo_imob.serie         := vt_tab_csf_nf_bem_ativo_imob(i).serie;
            pk_csf_api_cad.gt_row_nf_bem_ativo_imob.num_doc       := vt_tab_csf_nf_bem_ativo_imob(i).num_doc;
            pk_csf_api_cad.gt_row_nf_bem_ativo_imob.chv_nfe_cte   := vt_tab_csf_nf_bem_ativo_imob(i).chv_nfe_cte;
            pk_csf_api_cad.gt_row_nf_bem_ativo_imob.dt_doc        := vt_tab_csf_nf_bem_ativo_imob(i).dt_doc;
            --
            vn_fase := 3.3;
            --
            pk_csf_api_cad.pkb_integr_nf_bem_ativo_imob ( est_log_generico        => est_log_generico
                                                        , est_nf_bem_ativo_imob   => pk_csf_api_cad.gt_row_nf_bem_ativo_imob
                                                        , en_multorg_id           => en_multorg_id
                                                        , ev_cpf_cnpj             => vt_tab_csf_nf_bem_ativo_imob(i).cpf_cnpj
                                                        , ev_cod_ind_bem          => vt_tab_csf_nf_bem_ativo_imob(i).cod_ind_bem
                                                        , ev_cod_part             => vt_tab_csf_nf_bem_ativo_imob(i).cod_part
                                                        , ev_cod_mod              => vt_tab_csf_nf_bem_ativo_imob(i).cod_mod );
            --
            vn_fase := 3.4;
            --
            -- Verifica se foi integrado com sucesso o documento fiscal bem ativo antes de integrar os itens
            if pk_csf.fkg_existe_nf_bem_ativo_imob ( en_nfbemativoimob_id => pk_csf_api_cad.gt_row_nf_bem_ativo_imob.id ) = true then
               --
               vn_fase := 3.5;
               -- Chama o procedimento de integração da Utilização do Bem
               pkb_itnf_bem_ativo_imob ( est_log_generico => est_log_generico
                                       , ev_cpf_cnpj      => vt_tab_csf_nf_bem_ativo_imob(i).cpf_cnpj
                                       , ev_cod_ind_bem   => vt_tab_csf_nf_bem_ativo_imob(i).cod_ind_bem
                                       , en_dm_ind_emit   => vt_tab_csf_nf_bem_ativo_imob(i).dm_ind_emit
                                       , ev_cod_part      => vt_tab_csf_nf_bem_ativo_imob(i).cod_part
                                       , ev_cod_mod       => vt_tab_csf_nf_bem_ativo_imob(i).cod_mod
                                       , ev_serie         => vt_tab_csf_nf_bem_ativo_imob(i).serie
                                       , en_num_doc       => vt_tab_csf_nf_bem_ativo_imob(i).num_doc
                                       , en_multorg_id    => en_multorg_id
                                       );
            --
            end if;
            --
            commit;
            --
            if nvl(vn_multorg_id, 0) = 0 then
               --
               gv_cabec_log := 'Mult Org da Nota '||vt_tab_csf_nf_bem_ativo_imob(i).num_doc|| ' do Bem: '||vt_tab_csf_nf_bem_ativo_imob(i).cod_ind_bem||'não informado.';
               --
               gv_mensagem_log := 'A Nota'||vt_tab_csf_nf_bem_ativo_imob(i).num_doc|| ' do Bem: '||vt_tab_csf_nf_bem_ativo_imob(i).cod_ind_bem||' foi registrado com o Mult Org do Bem ' || vt_tab_csf_nf_bem_ativo_imob(i).cod_ind_bem || '('||en_multorg_id||') por falta de informação.';
               --
               declare
                  vn_loggenericocad_id  log_generico_cad.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                      , ev_mensagem        => gv_mensagem_log
                                                      , ev_resumo          => gv_cabec_log
                                                      , en_tipo_log        => informacao
                                                      , en_referencia_id   => null
                                                      , ev_obj_referencia  => gv_obj_referencia
                                                      , en_empresa_id         => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
            end if;
            --
         else
            --
            gv_mensagem_log := 'A Conversão da Nota '||vt_tab_csf_nf_bem_ativo_imob(i).num_doc|| ' do Bem: '||vt_tab_csf_nf_bem_ativo_imob(i).cod_ind_bem||' não pertence ao mesmo Mult Org do Bem ' || vt_tab_csf_nf_bem_ativo_imob(i).cod_ind_bem || '.'
                               ||'Mult Org da Conversão da Unidade: '||vn_multorg_id||'Mult Org do Item: '||en_multorg_id;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => informacao
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         end if;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_nf_bem_ativo_imob fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_nf_bem_ativo_imob;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração flex field complementar de Bens do ativo Imobilizado
procedure pkb_bem_ativo_imob_compl_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                                     , ev_cpf_cnpj       in  varchar2
                                     , ev_cod_ind_bem    in  varchar2
                                     , sn_multorg_id     in  out mult_org.id%type)
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_BEM_ATIVO_IMOB_COMPL_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   gv_sql := null;
   --
   vt_tab_bem_ativo_imob_comp_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_BEM_ATIVO_IMOB_COMPL_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ind_bem||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_bem_ativo_imob_comp_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_bem_ativo_imob_compl_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Complemento do Bem: '||ev_cod_ind_bem
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_bem_ativo_imob_comp_ff.count > 0 then
      --
      for i in vt_tab_bem_ativo_imob_comp_ff.first..vt_tab_bem_ativo_imob_comp_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_bem_ativo_imob_comp_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_BEM_ATIVO_IMOB_COMPL_FF'
                                                 , ev_atributo          => vt_tab_bem_ativo_imob_comp_ff(i).atributo
                                                 , ev_valor             => vt_tab_bem_ativo_imob_comp_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_bem_ativo_imob_compl_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => 'Complemento do Bem: '||ev_cod_ind_bem
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => gn_referencia_id
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_bem_ativo_imob_compl_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração complementar de Bens do ativo Imobilizado
procedure pkb_bem_ativo_imob_compl ( est_log_generico    in  out nocopy  dbms_sql.number_table
                                   , ev_cpf_cnpj         in  varchar2
                                   , ev_cod_ind_bem      in  bem_ativo_imob.cod_ind_bem%type
                                   , en_bemativoimob_id  in  bem_ativo_imob.id%type
                                   , en_multorg_id       in  mult_org.id%type)
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv    varchar2(1) := 'N';
   vn_multorg_id      mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_BEM_ATIVO_IMOB_COMPL') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_bem_ativo_imob_comp.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VIDA_UTIL_FISCAL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VIDA_UTIL_REAL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_AQUIS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_AQUIS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_INI_FORM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_FIN_FORM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_DEPRECIA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_SITUACAO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_TIPO_REC_PIS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_TIPO_REC_COFINS' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_BEM_ATIVO_IMOB_COMPL' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_ind_bem || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_bem_ativo_imob_comp;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_bem_ativo_imob_compl fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_bem_ativo_imob_comp.count,0) > 0 then
      --
      for i in vt_tab_csf_bem_ativo_imob_comp.first .. vt_tab_csf_bem_ativo_imob_comp.last loop
         --
         vn_fase := 3.2;
         --
         pkb_bem_ativo_imob_compl_ff( est_log_generico  => est_log_generico
                                    , ev_cpf_cnpj       => vt_tab_csf_bem_ativo_imob_comp(i).cpf_cnpj
                                    , ev_cod_ind_bem    => vt_tab_csf_bem_ativo_imob_comp(i).cod_ind_bem
                                    , sn_multorg_id     => vn_multorg_id);
         --
         if nvl(vn_multorg_id, 0) = nvl(en_multorg_id, 0) or
            nvl(vn_multorg_id, 0) = 0 then
            --
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl := null;
            --
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.cod_ind_bem            := vt_tab_csf_bem_ativo_imob_comp(i).cod_ind_bem;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.vida_util_fiscal       := vt_tab_csf_bem_ativo_imob_comp(i).vida_util_fiscal;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.vida_util_real         := vt_tab_csf_bem_ativo_imob_comp(i).vida_util_real;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.dt_aquis               := vt_tab_csf_bem_ativo_imob_comp(i).dt_aquis;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.vl_aquis               := vt_tab_csf_bem_ativo_imob_comp(i).vl_aquis;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.dt_ini_form            := vt_tab_csf_bem_ativo_imob_comp(i).dt_ini_form;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.dt_fin_form            := vt_tab_csf_bem_ativo_imob_comp(i).dt_fin_form;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.dm_deprecia            := vt_tab_csf_bem_ativo_imob_comp(i).dm_deprecia;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.dm_situacao            := vt_tab_csf_bem_ativo_imob_comp(i).dm_situacao;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.dm_tipo_rec_pis        := vt_tab_csf_bem_ativo_imob_comp(i).dm_tipo_rec_pis;
            pk_csf_api_cad.gt_row_bem_ativo_imob_compl.dm_tipo_rec_cofins     := vt_tab_csf_bem_ativo_imob_comp(i).dm_tipo_rec_cofins;
            --
            vn_fase := 3.3;
            --
            pk_csf_api_cad.pkb_integr_bem_ativo_imob_comp ( est_log_generico         => est_log_generico
                                                          , est_bem_ativo_imob_comp  => pk_csf_api_cad.gt_row_bem_ativo_imob_compl
                                                          , en_bemativoimob_id       => en_bemativoimob_id
                                                          , en_multorg_id            => en_multorg_id
                                                          , ev_cpf_cnpj              => vt_tab_csf_bem_ativo_imob_comp(i).cpf_cnpj
                                                          , ev_cod_item              => vt_tab_csf_bem_ativo_imob_comp(i).cod_item
                                                          , ev_cod_subgrupopat       => vt_tab_csf_bem_ativo_imob_comp(i).cod_subgrupopat
                                                          , ev_cod_grupopat          => vt_tab_csf_bem_ativo_imob_comp(i).cod_grupopat
                                                          );
            --

            vn_fase := 3.4;
            --
            commit;
            --
            if nvl(vn_multorg_id, 0) = 0 then
               --
               gv_cabec_log := 'Mult Org do Complemento do Bem '||vt_tab_csf_bem_ativo_imob_comp(i).cod_ind_bem||'não informado.';
               --
               gv_mensagem_log := 'O Complemento do Bem '||vt_tab_csf_bem_ativo_imob_comp(i).cod_ind_bem||' foi registrado com o Mult Org do Bem ' || vt_tab_csf_bem_ativo_imob_comp(i).cod_ind_bem || '('||en_multorg_id||') por falta de informação.';
               --
               declare
                  vn_loggenericocad_id  log_generico_cad.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                      , ev_mensagem        => gv_mensagem_log
                                                      , ev_resumo          => gv_cabec_log
                                                      , en_tipo_log        => informacao
                                                      , en_referencia_id   => null
                                                      , ev_obj_referencia  => gv_obj_referencia
                                                      , en_empresa_id         => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
            end if;
            --
         else
            --
            gv_mensagem_log := 'O Complemento do Bem '||vt_tab_csf_bem_ativo_imob_comp(i).cod_ind_bem||' não pertence ao mesmo Mult Org do Bem ' || vt_tab_csf_bem_ativo_imob_comp(i).cod_ind_bem || '.'
                               ||'Mult Org do Complemento do Bem : '||vn_multorg_id||'Mult Org do Bem: '||en_multorg_id;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => informacao
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         end if;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_bem_ativo_imob_compl fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_bem_ativo_imob_compl;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field da Utilização do Bem
procedure pkb_infor_util_bem_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                               , ev_cpf_cnpj       in  varchar2
                               , ev_cod_ind_bem    in  varchar2
                               , ev_cod_ccus       in  varchar2
                               , sn_multorg_id     in out mult_org.id%type)
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_INFOR_UTIL_BEM_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   gv_sql := null;
   --
   vt_tab_csf_util_bem_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_INFOR_UTIL_BEM_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ind_bem||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ccus||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_util_bem_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_infor_util_bem_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => 'Centro de custo: '||ev_cod_ccus||', Bem: '|| ev_cod_ind_bem
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_util_bem_ff.count > 0 then
      --
      for i in vt_tab_csf_util_bem_ff.first..vt_tab_csf_util_bem_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_util_bem_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_INFOR_UTIL_BEM_FF'
                                                 , ev_atributo          => vt_tab_csf_util_bem_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_util_bem_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_infor_util_bem_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => 'Centro de custo: '||ev_cod_ccus||', Bem: '|| ev_cod_ind_bem
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => gn_referencia_id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_infor_util_bem_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração da Utilização do Bem
procedure pkb_infor_util_bem ( est_log_generico    in out nocopy  dbms_sql.number_table
                             , ev_cpf_cnpj         in  varchar2
                             , ev_cod_ind_bem      in  bem_ativo_imob.cod_ind_bem%type
                             , en_bemativoimob_id  in  bem_ativo_imob.id%type
                             , en_multorg_id       in  mult_org.id%type )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_INFOR_UTIL_BEM') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   gv_sql := null;
   --
   vt_tab_csf_util_bem.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql ||         trim(GV_ASPAS) || 'CPF_CNPJ'    || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CCUS'    || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'FUNC'        || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VIDA_UTIL'   || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_INFOR_UTIL_BEM' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_ind_bem || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_util_bem;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_infor_util_bem fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_util_bem.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      delete from infor_util_bem
       where bemativoimob_id = en_bemativoimob_id;
      --
      vn_fase := 3.2;
      --
      for i in vt_tab_csf_util_bem.first .. vt_tab_csf_util_bem.last loop
         --
         vn_fase := 3.4;
         --
         pkb_infor_util_bem_ff( est_log_generico  => est_log_generico
                              , ev_cpf_cnpj       => vt_tab_csf_util_bem(i).cpf_cnpj
                              , ev_cod_ind_bem    => vt_tab_csf_util_bem(i).cod_ind_bem
                              , ev_cod_ccus       => vt_tab_csf_util_bem(i).cod_ccus
                              , sn_multorg_id     => vn_multorg_id);
         --
         if nvl(vn_multorg_id, 0) = nvl(en_multorg_id, 0) or
            nvl(vn_multorg_id, 0) = 0 then

            pk_csf_api_cad.gt_row_infor_util_bem := null;
            --
            pk_csf_api_cad.gt_row_infor_util_bem.bemativoimob_id := en_bemativoimob_id;
            pk_csf_api_cad.gt_row_infor_util_bem.cod_ccus        := vt_tab_csf_util_bem(i).cod_ccus;
            --
            vn_fase := 3.5;
            pk_csf_api_cad.gt_row_infor_util_bem.func            := vt_tab_csf_util_bem(i).func;
            pk_csf_api_cad.gt_row_infor_util_bem.vida_util       := vt_tab_csf_util_bem(i).vida_util;
            --
            vn_fase := 3.6;
            --
            pk_csf_api_cad.pkb_integr_infor_util_bem ( est_log_generico    => est_log_generico
                                                     , est_infor_util_bem  => pk_csf_api_cad.gt_row_infor_util_bem
                                                     , en_multorg_id       => en_multorg_id
                                                     , ev_cpf_cnpj         => ev_cpf_cnpj
                                                     , ev_cod_ind_bem      => ev_cod_ind_bem );
            --
            vn_fase := 3.7;
            --
            commit;
            --
            if nvl(vn_multorg_id, 0) = 0 then
               --
               gv_cabec_log := 'Mult Org do Centro de Custo '||vt_tab_csf_util_bem(i).cod_ccus|| ' do Bem: '||vt_tab_csf_util_bem(i).cod_ind_bem||'não informado.';
               --
               gv_mensagem_log := 'A do Centro de Custo '||vt_tab_csf_util_bem(i).cod_ccus|| ' do Bem: '||vt_tab_csf_util_bem(i).cod_ind_bem||' foi registrado com o Mult Org do Bem '||vt_tab_csf_util_bem(i).cod_ind_bem || '('||en_multorg_id||') por falta de informação.';
               --
               declare
                  vn_loggenericocad_id  log_generico_cad.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                      , ev_mensagem        => gv_mensagem_log
                                                      , ev_resumo          => gv_cabec_log
                                                      , en_tipo_log        => informacao
                                                      , en_referencia_id   => null
                                                      , ev_obj_referencia  => gv_obj_referencia
                                                      , en_empresa_id         => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
            end if;
            --
         else
            --
            gv_mensagem_log := 'O Centro de Custo '||vt_tab_csf_util_bem(i).cod_ccus|| ' do Bem: '||vt_tab_csf_util_bem(i).cod_ind_bem||' não pertence ao mesmo Mult Org do Bem '||vt_tab_csf_util_bem(i).cod_ind_bem || '.'
                               ||'Mult Org do Centro de Custo: '||vn_multorg_id||'Mult Org do Bem: '||en_multorg_id;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => informacao
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         end if;
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_infor_util_bem fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_infor_util_bem;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field de Bens do ativo Imobilizado

procedure pkb_bem_ativo_imob_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                               , ev_cpf_cnpj       in  varchar2
                               , ev_cod_ind_bem    in  varchar2
                               , sn_multorg_id     in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_BEM_ATIVO_IMOB_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   gv_sql := null;
   --
   vt_tab_csf_bem_ativo_imob_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_BEM_ATIVO_IMOB_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_ind_bem||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_bem_ativo_imob_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_bem_ativo_imob_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Bens do ativo Imobilizado: ' || ev_cod_ind_bem
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_bem_ativo_imob_ff.count > 0 then
      --
      for i in vt_tab_csf_bem_ativo_imob_ff.first..vt_tab_csf_bem_ativo_imob_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_bem_ativo_imob_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Bens do ativo Imobilizado - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_BEM_ATIVO_IMOB_FF'
                                                 , ev_atributo          => vt_tab_csf_bem_ativo_imob_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_bem_ativo_imob_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Bens do ativo Imobilizado cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Bens do ativo Imobilizado: ' || ev_cod_ind_bem
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_bem_ativo_imob_ff fase('||vn_fase||') cod_ind_bem('||pk_csf_api_cad.gt_row_bem_ativo_imob.cod_ind_bem||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => 'Bens do ativo Imobilizado: ' || ev_cod_ind_bem
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => pk_csf_api_cad.gt_row_bem_ativo_imob.id
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_bem_ativo_imob_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração de Bens do ativo Imobilizado
procedure pkb_bem_ativo_imob ( ev_cpf_cnpj in varchar2 )
is
   --
   vn_fase               number := 0;
   vt_log_generico       dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv       varchar2(1) := 'N';
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_empresa_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   else
      --
      gn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => gn_empresa_id );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_BEM_ATIVO_IMOB') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'BEM_ATIVO_IMOB';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_bem_ativo_imob.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_IND_BEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_IDENT_MERC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DESCR_ITEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_PRNC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CTA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NR_PARC' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_BEM_ATIVO_IMOB' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   --
   -- Monta a condição de ordenação
   gv_sql := gv_sql || ' order by ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ' , ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'DM_IDENT_MERC' || trim(GV_ASPAS); -- para que recuperem primeiro os BENS e depois os COMPONENTES
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_bem_ativo_imob;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_bem_ativo_imob fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 3;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_bem_ativo_imob.count,0);
   exception
      when others then
      null;
   end;
   --
   if nvl(vt_tab_csf_bem_ativo_imob.count,0) > 0 then
      --
      for i in vt_tab_csf_bem_ativo_imob.first .. vt_tab_csf_bem_ativo_imob.last loop
         --
         vn_fase := 3.1;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.2;
         --
         pk_csf_api_cad.gt_row_bem_ativo_imob := null;
         --
         pk_csf_api_cad.gt_row_bem_ativo_imob.cod_ind_bem    := vt_tab_csf_bem_ativo_imob(i).cod_ind_bem;
         pk_csf_api_cad.gt_row_bem_ativo_imob.dm_ident_merc  := vt_tab_csf_bem_ativo_imob(i).dm_ident_merc;
         pk_csf_api_cad.gt_row_bem_ativo_imob.descr_item     := vt_tab_csf_bem_ativo_imob(i).descr_item;
         pk_csf_api_cad.gt_row_bem_ativo_imob.cod_cta        := vt_tab_csf_bem_ativo_imob(i).cod_cta;
         pk_csf_api_cad.gt_row_bem_ativo_imob.nr_parc        := vt_tab_csf_bem_ativo_imob(i).nr_parc;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            --
            vn_multorg_id := gn_multorg_id;
            --
         end if;
         --
         pkb_bem_ativo_imob_ff( est_log_generico  => vt_log_generico
                              , ev_cpf_cnpj       => vt_tab_csf_bem_ativo_imob(i).cpf_cnpj
                              , ev_cod_ind_bem    => vt_tab_csf_bem_ativo_imob(i).cod_ind_bem
                              , sn_multorg_id     => vn_multorg_id);
         --
         vn_fase := 3.3;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pk_csf_api_cad.pkb_integr_bem_ativo_imob ( est_log_generico    => vt_log_generico
                                                  , est_bem_ativo_imob  => pk_csf_api_cad.gt_row_bem_ativo_imob
                                                  , en_multorg_id       => vn_multorg_id
                                                  , ev_cpf_cnpj         => vt_tab_csf_bem_ativo_imob(i).cpf_cnpj
                                                  , ev_cod_prnc         => vt_tab_csf_bem_ativo_imob(i).cod_prnc );
         --
         -- Verifica se foi integrado com sucesso o bem ativo antes de integrar as informações e complementos
         if pk_csf.fkg_existe_bem_ativo_imob ( en_bemativoimob_id => pk_csf_api_cad.gt_row_bem_ativo_imob.id ) = true then
            --
            vn_fase := 3.4;
            -- Chama o procedimento de integração da Utilização do Bem
            pkb_infor_util_bem ( est_log_generico    => vt_log_generico
                               , ev_cpf_cnpj         => ev_cpf_cnpj
                               , ev_cod_ind_bem      => vt_tab_csf_bem_ativo_imob(i).cod_ind_bem
                               , en_bemativoimob_id  => pk_csf_api_cad.gt_row_bem_ativo_imob.id
                               , en_multorg_id       => vn_multorg_id );
            --
            vn_fase := 3.5;
            -- Chama o procedimento de integração complementar do bem ativo imobilizado
            pkb_bem_ativo_imob_compl ( est_log_generico    => vt_log_generico
                                     , ev_cpf_cnpj         => ev_cpf_cnpj
                                     , ev_cod_ind_bem      => vt_tab_csf_bem_ativo_imob(i).cod_ind_bem
                                     , en_bemativoimob_id  => pk_csf_api_cad.gt_row_bem_ativo_imob.id
                                     , en_multorg_id       => vn_multorg_id );
            --
            vn_fase := 3.6;
            -- Chama o procedimento de integração dos documentos fiscais do bem ativo imobilizado
            pkb_nf_bem_ativo_imob ( est_log_generico  => vt_log_generico
                                  , ev_cpf_cnpj       => ev_cpf_cnpj
                                  , ev_cod_ind_bem    => vt_tab_csf_bem_ativo_imob(i).cod_ind_bem
                                  , en_multorg_id       => vn_multorg_id );
            --
            vn_fase := 3.7;
            -- Chama o procedimento de integração dos impostos do bem ativo imobilizado
            pkb_rec_imp_bem_ativo_imob ( est_log_generico  => vt_log_generico
                                       , ev_cpf_cnpj       => ev_cpf_cnpj
                                       , ev_cod_ind_bem    => vt_tab_csf_bem_ativo_imob(i).cod_ind_bem
                                       , en_multorg_id     => vn_multorg_id);
            --
            vn_fase := 3.8;
            -- Chama o procedimento que verifica se existe os dados de "Informações de Utilização do Bem" e caso não exista,
            -- recupera a partir do SUB-GRUPO.
            pk_csf_api_cad.pkb_rec_infor_util_bem ( en_bemativoimob_id => pk_csf_api_cad.gt_row_bem_ativo_imob.id
                                                  , en_multorg_id      => vn_multorg_id
                                                  , ev_cpf_cnpj        => ev_cpf_cnpj
                                                  , ev_cod_ind_bem     => vt_tab_csf_bem_ativo_imob(i).cod_ind_bem );
            --
            vn_fase := 3.9;
            -- Chama o procedimento que verifica se existe os dados do "Impostos do bem ativo" e caso não exista,
            -- recupera a partir do REC_IMP_SUBGRUPO_PAT.
            pk_csf_api_cad.pkb_rec_imp_bem_ativo ( en_bemativoimob_id => pk_csf_api_cad.gt_row_bem_ativo_imob.id
                                                 , en_multorg_id      => vn_multorg_id
                                                 , ev_cpf_cnpj        => ev_cpf_cnpj
                                                 , ev_cod_ind_bem     => vt_tab_csf_bem_ativo_imob(i).cod_ind_bem );
            --
            if nvl(vt_log_generico.count,0) > 0 then
               -- Erro de validação
               update bem_ativo_imob set dm_st_proc = 2
                where id = pk_csf_api_cad.gt_row_bem_ativo_imob.id;
               --
            else
               -- Validado
               update bem_ativo_imob set dm_st_proc = 1
                where id = pk_csf_api_cad.gt_row_bem_ativo_imob.id;
               --
            end if;
            --
         end if;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         vn_fase := 3.10;
         --
         commit;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_bem_ativo_imob fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_bem_ativo_imob;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field dos Impostos dos Subgrupos de Patrimonio
procedure pkb_subgrupo_pat_ff ( est_log_generico  in out  nocopy  dbms_sql.number_table
                              , ev_cd_grupopat    in      varchar2
                              , ev_cd_subgrupopat in      varchar2
                              , en_cd_tipo_imp    in      number
                              , sn_multorg_id     in out  mult_org.id%type )
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_REC_IMP_SUBGRUPO_PAT_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'REC_IMP_SUBGRUPO_PAT';
   --
   gv_sql := null;
   --
   vt_tab_csf_imp_subgrupo_pat_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_TIPO_IMP' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_REC_IMP_SUBGRUPO_PAT_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS) || ' = ' ||''''||ev_cd_grupopat||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS) || ' = ' ||''''||ev_cd_subgrupopat||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'CD_TIPO_IMP' || trim(GV_ASPAS) || ' = ' ||en_cd_tipo_imp;
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'CD_TIPO_IMP' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_imp_subgrupo_pat_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_int.pkb_subgrupo_pat_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Imposto: '||en_cd_tipo_imp||', SubGrupo: '|| ev_cd_subgrupopat
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_imp_subgrupo_pat_ff.count > 0 then
      --
      for i in vt_tab_csf_imp_subgrupo_pat_ff.first..vt_tab_csf_imp_subgrupo_pat_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_imp_subgrupo_pat_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_REC_IMP_SUBGRUPO_PAT_FF'
                                                 , ev_atributo          => vt_tab_csf_imp_subgrupo_pat_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_imp_subgrupo_pat_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_subgrupo_pat_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => 'Imposto: '||en_cd_tipo_imp||', SubGrupo: '|| ev_cd_subgrupopat
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => gn_referencia_id
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_subgrupo_pat_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração dos Impostos dos Subgrupos de Patrimonio
procedure pkb_rec_imp_subgrupo_pat ( est_log_generico  in out nocopy  dbms_sql.number_table
                                   , ev_cpf_cnpj       in varchar2
                                   , ev_cd_grupopat    in grupo_pat.cd%type
                                   , ev_cd_subgrupopat in subgrupo_pat.cd%type
                                   , en_multorg_id     in mult_org.id%type )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv    varchar2(1) := 'N';
   vn_multorg_id      mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_REC_IMP_SUBGRUPO_PAT') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'GRUPO_PAT';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_imp_subgrupo_pat.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_TIPO_IMP' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ALIQ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'QTDE_MES' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_REC_IMP_SUBGRUPO_PAT' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS) || ' = ' || '''' || ev_cd_grupopat || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS) || ' = ' || '''' || ev_cd_subgrupopat || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_imp_subgrupo_pat;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_rec_imp_subgrupo_pat fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_imp_subgrupo_pat.count,0) > 0 then
      --
      for i in vt_tab_csf_imp_subgrupo_pat.first .. vt_tab_csf_imp_subgrupo_pat.last loop
         --
         vn_fase := 3.2;
         --
         pkb_subgrupo_pat_ff ( est_log_generico  => est_log_generico
                             , ev_cd_grupopat    => vt_tab_csf_imp_subgrupo_pat(i).cd_grupopat
                             , ev_cd_subgrupopat => vt_tab_csf_imp_subgrupo_pat(i).cd_subgrupopat
                             , en_cd_tipo_imp    => vt_tab_csf_imp_subgrupo_pat(i).cd_tipo_imp
                             , sn_multorg_id     => vn_multorg_id);
         --
         if nvl(vn_multorg_id, 0) = nvl(en_multorg_id, 0) or
            nvl(vn_multorg_id, 0) = 0 then

            pk_csf_api_cad.gt_row_rec_imp_subgrupo_pat := null;
            --
            pk_csf_api_cad.gt_row_rec_imp_subgrupo_pat.aliq         := vt_tab_csf_imp_subgrupo_pat(i).aliq;
            pk_csf_api_cad.gt_row_rec_imp_subgrupo_pat.qtde_mes     := vt_tab_csf_imp_subgrupo_pat(i).qtde_mes;
            --
            vn_fase := 3.3;
            --
            pk_csf_api_cad.pkb_integr_imp_subgrupo_pat ( est_log_generico          => est_log_generico
                                                       , est_rec_imp_subgrupo_pat  => pk_csf_api_cad.gt_row_rec_imp_subgrupo_pat
                                                       , ev_cd_grupopat            => vt_tab_csf_imp_subgrupo_pat(i).cd_grupopat
                                                       , ev_cd_subgrupopat         => vt_tab_csf_imp_subgrupo_pat(i).cd_subgrupopat
                                                       , ev_cd_tipo_imp            => vt_tab_csf_imp_subgrupo_pat(i).cd_tipo_imp
                                                       , en_multorg_id             => en_multorg_id
                                                       , en_empresa_id             => gn_empresa_id
                                                       );
            --
            commit;
            --
            if nvl(vn_multorg_id, 0) = 0 then
               --
               gv_cabec_log := 'Mult Org do Imposto '||vt_tab_csf_imp_subgrupo_pat(i).cd_tipo_imp||' do SubGrupo '||vt_tab_csf_imp_subgrupo_pat(i).cd_subgrupopat|| ' não informado.';
               --
               gv_mensagem_log := 'O Imposto '||vt_tab_csf_imp_subgrupo_pat(i).cd_tipo_imp||' do SubGrupo '||vt_tab_csf_imp_subgrupo_pat(i).cd_subgrupopat||' foi registrado com o Mult Org do Grupo ' || vt_tab_csf_imp_subgrupo_pat(i).cd_subgrupopat || '('||en_multorg_id||') por falta de informação.';
               --
               declare
                  vn_loggenericocad_id  log_generico_cad.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                      , ev_mensagem        => gv_mensagem_log
                                                      , ev_resumo          => gv_cabec_log
                                                      , en_tipo_log        => informacao
                                                      , en_referencia_id   => null
                                                      , ev_obj_referencia  => gv_obj_referencia
                                                      , en_empresa_id         => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
            end if;
            --
         else
            --
            gv_mensagem_log := 'O Imposto '||vt_tab_csf_imp_subgrupo_pat(i).cd_tipo_imp||' do SubGrupo '||vt_tab_csf_imp_subgrupo_pat(i).cd_subgrupopat||' não pertence ao mesmo Mult Org do SubGrupo ' || vt_tab_csf_imp_subgrupo_pat(i).cd_subgrupopat || '.'
                               ||'Mult Org do SubGrupo: '||vn_multorg_id||'Mult Org do Grupo: '||en_multorg_id;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => informacao
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         end if;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_rec_imp_subgrupo_pat fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_rec_imp_subgrupo_pat;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração dos dados flex field dos Subgrupos de Patrimonio
procedure pkb_subgrupo_pat_ff ( est_log_generico  in out  nocopy  dbms_sql.number_table
                              , ev_cd_grupopat    in      varchar2
                              , ev_cd_subgrupopat in      varchar2
                              , sn_multorg_id     in out  mult_org.id%type )
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_SUBGRUPO_PAT_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'SUBGRUPO_PAT';
   --
   gv_sql := null;
   --
   vt_tab_csf_subgrupo_pat_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_SUBGRUPO_PAT_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS) || ' = ' ||''''||ev_cd_grupopat||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS) || ' = ' ||''''||ev_cd_subgrupopat||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_subgrupo_pat_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_int.pkb_subgrupo_pat_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'SubGrupo: '|| ev_cd_subgrupopat
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_subgrupo_pat_ff.count > 0 then
      --
      for i in vt_tab_csf_subgrupo_pat_ff.first..vt_tab_csf_subgrupo_pat_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_subgrupo_pat_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_SUBGRUPO_PAT_FF'
                                                 , ev_atributo          => vt_tab_csf_subgrupo_pat_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_subgrupo_pat_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_subgrupo_pat_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem        => gv_mensagem_log
                                             , ev_resumo          => 'SubGrupo: '|| ev_cd_subgrupopat
                                             , en_tipo_log        => ERRO_DE_SISTEMA
                                             , en_referencia_id   => gn_referencia_id
                                             , ev_obj_referencia  => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_subgrupo_pat_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração dos Subgrupos de Patrimonio
procedure pkb_subgrupo_pat ( est_log_generico in out nocopy  dbms_sql.number_table
                           , ev_cpf_cnpj      in varchar2
                           , ev_cd_grupopat   in grupo_pat.cd%type
                           , en_multorg_id    in mult_org.id%type )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv    varchar2(1) := 'N';
   vn_multorg_id      mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_SUBGRUPO_PAT') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'GRUPO_PAT';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_subgrupo_pat.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_SUBGRUPOPAT' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DESCR' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VIDA_UTIL_FISCAL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VIDA_UTIL_REAL' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_FORMACAO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_DEPRECIA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_TIPO_REC_PIS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_TIPO_REC_COFINS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_CCUS' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_SUBGRUPO_PAT' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CD_GRUPOPAT' || trim(GV_ASPAS) || ' = ' || '''' || ev_cd_grupopat || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_subgrupo_pat;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_subgrupo_pat fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_subgrupo_pat.count,0) > 0 then
      --
      for i in vt_tab_csf_subgrupo_pat.first .. vt_tab_csf_subgrupo_pat.last loop
         --
         vn_fase := 3.2;
         --
         pk_csf_api_cad.gt_row_subgrupo_pat := null;
         --
         pk_csf_api_cad.gt_row_subgrupo_pat.cd                    := vt_tab_csf_subgrupo_pat(i).cd_subgrupopat;
         pk_csf_api_cad.gt_row_subgrupo_pat.descr                 := vt_tab_csf_subgrupo_pat(i).descr;
         pk_csf_api_cad.gt_row_subgrupo_pat.vida_util_fiscal      := vt_tab_csf_subgrupo_pat(i).vida_util_fiscal;
         pk_csf_api_cad.gt_row_subgrupo_pat.vida_util_real        := vt_tab_csf_subgrupo_pat(i).vida_util_real;
         pk_csf_api_cad.gt_row_subgrupo_pat.dm_formacao           := vt_tab_csf_subgrupo_pat(i).dm_formacao;
         pk_csf_api_cad.gt_row_subgrupo_pat.dm_deprecia           := vt_tab_csf_subgrupo_pat(i).dm_deprecia;
         pk_csf_api_cad.gt_row_subgrupo_pat.dm_tipo_rec_pis       := vt_tab_csf_subgrupo_pat(i).dm_tipo_rec_pis;
         pk_csf_api_cad.gt_row_subgrupo_pat.dm_tipo_rec_cofins    := vt_tab_csf_subgrupo_pat(i).dm_tipo_rec_cofins;
         pk_csf_api_cad.gt_row_subgrupo_pat.cod_ccus              := vt_tab_csf_subgrupo_pat(i).cod_ccus;
         --
         vn_fase := 3.3;
         --
         pkb_subgrupo_pat_ff ( est_log_generico  => est_log_generico
                             , ev_cd_grupopat    => vt_tab_csf_subgrupo_pat(i).cd_grupopat
                             , ev_cd_subgrupopat => vt_tab_csf_subgrupo_pat(i).cd_subgrupopat
                             , sn_multorg_id     => vn_multorg_id);
         --
         if nvl(vn_multorg_id, 0) = nvl(en_multorg_id, 0) or
            nvl(vn_multorg_id, 0) = 0 then
            --
            pk_csf_api_cad.pkb_integr_subgrupo_pat ( est_log_generico  => est_log_generico
                                                   , est_subgrupo_pat  => pk_csf_api_cad.gt_row_subgrupo_pat
                                                   , ev_cd_grupopat    => vt_tab_csf_subgrupo_pat(i).cd_grupopat
                                                   , en_multorg_id     => en_multorg_id
                                                   , en_empresa_id     => gn_empresa_id
                                                   );
            --
            -- Verifica se foi integrado com sucesso o subgrupo antes de integrar os impostos
            if pk_csf.fkg_existe_subgrupo_pat ( en_subgrupopat_id => pk_csf_api_cad.gt_row_subgrupo_pat.id ) = true then
               --
               vn_fase := 3.4;
               -- Chama o procedimento de integração dos impostos do subgrupo
               pkb_rec_imp_subgrupo_pat ( est_log_generico  => est_log_generico
                                        , ev_cpf_cnpj       => ev_cpf_cnpj
                                        , ev_cd_grupopat    => vt_tab_csf_subgrupo_pat(i).cd_grupopat
                                        , ev_cd_subgrupopat => vt_tab_csf_subgrupo_pat(i).cd_subgrupopat
                                        , en_multorg_id     => en_multorg_id );

            --
            end if;
            --
            commit;
            --
            if nvl(vn_multorg_id, 0) = 0 then
               --
               gv_cabec_log := 'Mult Org do SubGrupo '||vt_tab_csf_subgrupo_pat(i).cd_grupopat|| ' não informado.';
               --
               gv_mensagem_log := 'O SubGrupo '||vt_tab_csf_subgrupo_pat(i).cd_grupopat|| ' foi registrado com o Mult Org do Grupo ' || vt_tab_csf_subgrupo_pat(i).cd_grupopat || '('||en_multorg_id||') por falta de informação.';
               --
               declare
                  vn_loggenericocad_id  log_generico_cad.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                      , ev_mensagem        => gv_mensagem_log
                                                      , ev_resumo          => gv_cabec_log
                                                      , en_tipo_log        => informacao
                                                      , en_referencia_id   => null
                                                      , ev_obj_referencia  => gv_obj_referencia
                                                      , en_empresa_id         => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
            end if;
            --
         else
            --
            gv_mensagem_log := 'O SubGrupo '||vt_tab_csf_subgrupo_pat(i).cd_grupopat|| ' não pertence ao mesmo Mult Org do Grupo ' || vt_tab_csf_subgrupo_pat(i).cd_grupopat || '.'
                               ||'Mult Org do SubGrupo: '||vn_multorg_id||'Mult Org do Grupo: '||en_multorg_id;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => gv_mensagem_log
                                                   , en_tipo_log        => informacao
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         end if;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_subgrupo_pat fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_subgrupo_pat;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração de dados Flex Field dos Grupos de Patrimonio

procedure pkb_grupo_pat_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                          , ev_cd             in  varchar2
                          , sn_multorg_id     in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_GRUPO_PAT_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'GRUPO_PAT';
   --
   gv_sql := null;
   --
   vt_tab_csf_grupo_pat_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CD' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_GRUPO_PAT_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CD' || trim(GV_ASPAS) || ' = ' ||''''||ev_cd||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CD' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_grupo_pat_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_grupo_pat_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem        => gv_mensagem_log
                                                   , ev_resumo          => 'Grupos de Patrimonio: ' || ev_cd
                                                   , en_tipo_log        => ERRO_DE_SISTEMA
                                                   , en_referencia_id   => null
                                                   , ev_obj_referencia  => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_grupo_pat_ff.count > 0 then
      --
      for i in vt_tab_csf_grupo_pat_ff.first..vt_tab_csf_grupo_pat_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_grupo_pat_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Grupos de Patrimonio - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_GRUPO_PAT_FF'
                                                 , ev_atributo          => vt_tab_csf_grupo_pat_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_grupo_pat_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Grupos de Patrimonio cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Grupos de Patrimonio: ' || ev_cd
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_grupo_pat_ff fase('||vn_fase||') cd('||pk_csf_api_cad.gt_row_grupo_pat.cd||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => 'Grupos de Patrimonio: ' || ev_cd
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => pk_csf_api_cad.gt_row_grupo_pat.id
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_grupo_pat_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração dos Grupos de Patrimonio
procedure pkb_grupo_pat ( ev_cpf_cnpj in varchar2 )
is
   --
   vn_fase               number := 0;
   vt_log_generico       dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv       varchar2(1) := 'N';
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   vn_fase := 1.1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_GRUPO_PAT') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'GRUPO_PAT';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_grupo_pat.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select g.';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CD' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', g.' || trim(GV_ASPAS) || 'DESCR' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   if trim(gv_sistema_em_nuvem) = 'SIM' then
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_GRUPO_PAT' ) || ' g, ';
      gv_sql := gv_sql || trim(replace(fkg_monta_from ( ev_obj => 'VW_CSF_GRUPO_PAT_FF' ), 'from', '')) || ' f';
      --
      gv_sql := gv_sql || ' WHERE f.' || trim(GV_ASPAS) || 'CD' || trim(GV_ASPAS) || ' = g.' || trim(GV_ASPAS) || 'CD' || trim(GV_ASPAS);
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS) || ' = ' || '''' || 'COD_MULT_ORG' || '''';
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS) || ' = ' || '''' || trim(gv_multorg_cd) || '''';
      --
   else
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_GRUPO_PAT' ) || ' g';
      --
   end if;
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_grupo_pat;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_grupo_pat fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_grupo_pat.count,0);
   exception
      when others then
      null;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_grupo_pat.count,0) > 0 then
      --
      for i in vt_tab_csf_grupo_pat.first .. vt_tab_csf_grupo_pat.last loop
         --
         vn_fase := 3.1;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.2;
         --
         pk_csf_api_cad.gt_row_grupo_pat := null;
         --
         pk_csf_api_cad.gt_row_grupo_pat.cd            := vt_tab_csf_grupo_pat(i).cd;
         pk_csf_api_cad.gt_row_grupo_pat.descr         := vt_tab_csf_grupo_pat(i).descr;
         --
         vn_multorg_id := gn_multorg_id;
         --
         pkb_grupo_pat_ff( est_log_generico  => vt_log_generico
                         , ev_cd             => vt_tab_csf_grupo_pat(i).cd
                         , sn_multorg_id     => vn_multorg_id);
         --
         vn_fase := 3.3;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pk_csf_api_cad.gt_row_grupo_pat.multorg_id    := vn_multorg_id;
         --
         vn_fase := 3.4;
         --
         pk_csf_api_cad.pkb_integr_grupo_pat ( est_log_generico  => vt_log_generico
                                             , est_grupo_pat     => pk_csf_api_cad.gt_row_grupo_pat
                                             , en_empresa_id     => gn_empresa_id
                                             );
         --
         vn_fase := 3.5;
         -- Verifica se foi integrado com sucesso o grupo antes de integrar os subgrupos
         if pk_csf.fkg_existe_grupo_pat ( en_grupopat_id => pk_csf_api_cad.gt_row_grupo_pat.id ) = true then
            --
            vn_fase := 3.6;
            -- Chama o procedimento de integração dos subgrupos dos patrimonios
            pkb_subgrupo_pat ( est_log_generico => vt_log_generico
                             , ev_cpf_cnpj      => ev_cpf_cnpj
                             , ev_cd_grupopat   => vt_tab_csf_grupo_pat(i).cd
                             , en_multorg_id    => pk_csf_api_cad.gt_row_grupo_pat.multorg_id );
         --
         end if;
         --
         if nvl(vt_log_generico.count,0) > 0 then
            -- Erro de validação
            update grupo_pat set dm_st_proc = 2
             where id = pk_csf_api_cad.gt_row_grupo_pat.id;
            --
         else
            -- Validado
            update grupo_pat set dm_st_proc = 1
             where id = pk_csf_api_cad.gt_row_grupo_pat.id;
            --
         end if;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         commit;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 4;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_grupo_pat fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_grupo_pat;

-------------------------------------------------------------------------------------------------------

--| Executa procedure softfacil
procedure pkb_softfacil ( ev_cpf_cnpj in varchar2
                        , ed_dt_ini   in date
                        , ed_dt_fin   in date ) is
   --
   vn_fase       number := 0;
   vv_cod_matriz empresa.cod_matriz%type;
   vv_cod_filial empresa.cod_filial%type;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'PB_SF_CIAP_TEMP') = 0 then
      --
      return;
      --
   end if;
   --
   if length(ev_cpf_cnpj) in (11, 14) then
      --
      vn_fase := 2;
      --
      begin
         --
         select cod_matriz
              , cod_filial
           into vv_cod_matriz
              , vv_cod_filial
           from empresa
          where id = pk_csf.fkg_empresa_id_pelo_cpf_cnpj(gn_multorg_id, ev_cpf_cnpj );
         --
      exception
         when others then
            vv_cod_matriz := null;
            vv_cod_filial := null;
      end;
      --
      vn_fase := 3;
      --
      if trim(vv_cod_matriz) is not null
         and trim(vv_cod_filial) is not null then
         --
         gv_sql := 'begin PB_SF_CIAP_TEMP(' ||
                              vv_cod_matriz || ', ' ||
                              vv_cod_filial || ', ' ||
                              '''' || to_date(ed_dt_ini, GV_FORMATO_DT_ERP) || '''' || ', ' ||
                              '''' || to_date(ed_dt_fin, GV_FORMATO_DT_ERP) || '''' || ' ); end;';
         --
         begin
            --
            execute immediate gv_sql;
            --
         exception
            when others then
               -- não registra erro caso a view não exista
               if sqlcode = -942 then
                  null;
               else
                  --
                  gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_softfacil fase ('||vn_fase||'): '||sqlerrm;
                  --
                  declare
                     vn_loggenericocad_id  log_generico_cad.id%TYPE;
                  begin
                     --
                     pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                 , ev_mensagem        => gv_mensagem_log
                                                 , ev_resumo          => gv_mensagem_log
                                                 , en_tipo_log        => ERRO_DE_SISTEMA
                                                 , en_referencia_id   => null
                                                 , ev_obj_referencia  => gv_obj_referencia
                                                 , en_empresa_id         => gn_empresa_id
                                                 );
                     --
                  exception
                     when others then
                        null;
                  end;
                  --
                  raise_application_error (-20101, gv_mensagem_log);
                  --
               end if;
         end;
         --
      end if;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_softfacil fase ('||vn_fase||'): '||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_softfacil;

-------------------------------------------------------------------------------------------------------

--| Procedimento de integração de informações de Códigos de Grupos por Marca Comercial/Refrigerantes
procedure pkb_item_marca_comerc ( est_log_generico in out nocopy  dbms_sql.number_table
                                , ev_cpf_cnpj      in varchar2
                                , ev_cod_item      in item.cod_item%type
                                , en_item_id       in item.id%type )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITEM_MARCA_COMERC') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'ITEM';
   --
   gv_sql := null;
   --
   vt_tab_csf_item_marca_comerc.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || 'pk_csf.fkg_converte('||trim(GV_ASPAS) || 'CPF_CNPJ'   || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_ITEM'   || trim(GV_ASPAS)|| ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'DM_COD_TAB' || trim(GV_ASPAS)|| ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_GRU'    || trim(GV_ASPAS)|| ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'MARCA_COM'  || trim(GV_ASPAS)|| ')';
   --
   vn_fase := 2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITEM_MARCA_COMERC' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_item || '''';
   --
   vn_fase := 3;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_item_marca_comerc;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_marca_comerc fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 4;
   --
   if nvl(vt_tab_csf_item_marca_comerc.count,0) > 0 then
      --
      for i in vt_tab_csf_item_marca_comerc.first .. vt_tab_csf_item_marca_comerc.last loop
         --
         vn_fase := 6;
         --
         pk_csf_api_cad.gt_row_item_marca_comerc := null;
         --
         pk_csf_api_cad.gt_row_item_marca_comerc.item_id    := en_item_id;
         pk_csf_api_cad.gt_row_item_marca_comerc.dm_cod_tab := vt_tab_csf_item_marca_comerc(i).dm_cod_tab;
         pk_csf_api_cad.gt_row_item_marca_comerc.cod_gru    := vt_tab_csf_item_marca_comerc(i).cod_gru;
         pk_csf_api_cad.gt_row_item_marca_comerc.marca_com  := vt_tab_csf_item_marca_comerc(i).marca_com;
         --
         vn_fase := 7;
         --
         pk_csf_api_cad.pkb_integr_item_marca_comerc ( est_log_generico      => est_log_generico
                                                     , est_item_marca_comerc => pk_csf_api_cad.gt_row_item_marca_comerc
                                                     , en_empresa_id         => gn_empresa_id
                                                     );
         --
         vn_fase := 8;
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
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_marca_comerc fase('||vn_fase||') item_id ('||en_item_id||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                     , ev_mensagem        => gv_mensagem_log
                                     , ev_resumo          => gv_mensagem_log
                                     , en_tipo_log        => ERRO_DE_SISTEMA
                                     , en_referencia_id   => null
                                     , ev_obj_referencia  => gv_obj_referencia
                                     , en_empresa_id         => gn_empresa_id
                                     );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_item_marca_comerc;

-------------------------------------------------------------------------------------------------------

--| Procedimento de integração de informações de complementos do item
procedure pkb_item_compl ( est_log_generico in out nocopy  dbms_sql.number_table
                         , ev_cpf_cnpj      in varchar2
                         , ev_cod_item      in item.cod_item%type
                         , en_item_id       in item.id%type )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITEM_COMPL') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'ITEM';
   --
   gv_sql := null;
   --
   vt_tab_csf_item_compl.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || 'pk_csf.fkg_converte('   ||   trim(GV_ASPAS) || 'CPF_CNPJ'   || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_ITEM'   || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CSOSN'      || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CST_ICMS'   || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'PER_RED_BC_ICMS'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'BC_ICMS_ST'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CST_IPI_ENTRADA'  || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CST_IPI_SAIDA'  || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ALIQ_IPI'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CST_PIS_ENTRADA'  || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CST_PIS_SAIDA'  || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NAT_REC_PIS'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ALIQ_PIS'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CST_COFINS_ENTRADA'  || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CST_COFINS_SAIDA'  || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NAT_REC_COFINS'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ALIQ_COFINS'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ALIQ_ISS'  || trim(GV_ASPAS);
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_CTA'  || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'OBSERVACAO'  || trim(GV_ASPAS) ||')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VL_EST_VENDA'  || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITEM_COMPL' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_item || '''';
   --
   vn_fase := 3;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_item_compl;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_compl fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                           , ev_mensagem        => gv_mensagem_log
                                           , ev_resumo          => gv_mensagem_log
                                           , en_tipo_log        => ERRO_DE_SISTEMA
                                           , en_referencia_id   => null
                                           , ev_obj_referencia  => gv_obj_referencia
                                           , en_empresa_id         => gn_empresa_id
                                           );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 4;
   --
   if nvl(vt_tab_csf_item_compl.count,0) > 0 then
      --
      for i in vt_tab_csf_item_compl.first .. vt_tab_csf_item_compl.last loop
         --
         vn_fase := 6;
         --
         pk_csf_api_cad.gt_row_item_compl := null;
         --
         pk_csf_api_cad.gt_row_item_compl.per_red_bc_icms  := vt_tab_csf_item_compl(i).per_red_bc_icms;
         pk_csf_api_cad.gt_row_item_compl.vl_bc_icms_st    := vt_tab_csf_item_compl(i).bc_icms_st;
         vn_fase := 6.1;
         pk_csf_api_cad.gt_row_item_compl.aliq_ipi         := vt_tab_csf_item_compl(i).aliq_ipi;
         pk_csf_api_cad.gt_row_item_compl.aliq_pis         := vt_tab_csf_item_compl(i).aliq_pis;
         vn_fase := 6.2;
         pk_csf_api_cad.gt_row_item_compl.aliq_iss         := vt_tab_csf_item_compl(i).aliq_iss;
         pk_csf_api_cad.gt_row_item_compl.aliq_cofins      := vt_tab_csf_item_compl(i).aliq_cofins;
         vn_fase := 6.3;
         pk_csf_api_cad.gt_row_item_compl.cod_cta          := vt_tab_csf_item_compl(i).cod_cta;
         pk_csf_api_cad.gt_row_item_compl.observacao       := vt_tab_csf_item_compl(i).observacao;
         vn_fase := 6.4;
         pk_csf_api_cad.gt_row_item_compl.vl_est_venda     := vt_tab_csf_item_compl(i).vl_est_venda;
         --
         vn_fase := 7;
         --
         pk_csf_api_cad.pkb_integr_item_compl ( est_log_generico         => est_log_generico
                                              , est_item_compl           => pk_csf_api_cad.gt_row_item_compl
                                              , en_item_id               => en_item_id
                                              , ev_codst_csosn           => vt_tab_csf_item_compl(i).csosn
                                              , ev_codst_icms            => vt_tab_csf_item_compl(i).cst_icms
                                              , ev_codst_ipi_entrada     => vt_tab_csf_item_compl(i).cst_ipi_entrada
                                              , ev_codst_ipi_saida       => vt_tab_csf_item_compl(i).cst_ipi_saida
                                              , ev_codst_pis_entrada     => vt_tab_csf_item_compl(i).cst_pis_entrada
                                              , ev_codst_pis_saida       => vt_tab_csf_item_compl(i).cst_pis_saida
                                              , ev_codst_cofins_entrada  => vt_tab_csf_item_compl(i).cst_cofins_entrada
                                              , ev_codst_cofins_saida    => vt_tab_csf_item_compl(i).cst_cofins_saida
                                              , ev_natrecpc_pis          => vt_tab_csf_item_compl(i).nat_rec_pis
                                              , ev_natrecpc_cofins       => vt_tab_csf_item_compl(i).nat_rec_cofins
                                              , en_multorg_id            => gn_multorg_id
                                              );
         --
         vn_fase := 8;
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
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_compl fase('||vn_fase||') item_id ('||en_item_id||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_item_compl;

-------------------------------------------------------------------------------------------------------
--| Procedimento Flex Field de conversão de Unidade do Item
procedure pkb_conv_unid_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                          , ev_cpf_cnpj       in  varchar2
                          , ev_cod_item       in  varchar2
                          , ev_sigla_unid     in  varchar2
                          , sn_multorg_id     in out mult_org.id%type)
is
   --
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   --
begin
   --
   vn_fase := 1;
   --
   vn_multorg_id := sn_multorg_id;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_CONV_UNID_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'CONV_UNID';
   --
   gv_sql := null;
   --
   vt_tab_csf_conv_unid_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || 'pk_csf.fkg_converte( ' ||trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte( ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS)|| ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte( ' || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS)|| ')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_CONV_UNID_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ' = ' ||''''|| ev_cod_item ||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS) || ' = ' ||''''|| ev_sigla_unid ||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_conv_unid_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_conv_unid_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => 'Unidade: '||ev_sigla_unid||', Item: '|| ev_cod_item
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         raise_application_error (-20101, gv_mensagem_log);
         --
         end if;
      --
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_conv_unid_ff.count > 0 then
      --
      for i in vt_tab_csf_conv_unid_ff.first..vt_tab_csf_conv_unid_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_conv_unid_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Inventario - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_CONV_UNID_FF'
                                                 , ev_atributo          => vt_tab_csf_conv_unid_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_conv_unid_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   end if;
   --
exception
   --
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_conv_unid_ff fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => 'Unidade: '||ev_sigla_unid||', Item: '|| ev_cod_item
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => gn_referencia_id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
   --
end pkb_conv_unid_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de conversão de Unidade do Item
procedure pkb_conv_unid ( est_log_generico in out nocopy  dbms_sql.number_table
                        , ev_cpf_cnpj      in varchar2
                        , ev_cod_item      in item.cod_item%type
                        , en_item_id       in item.id%type
                        , en_multorg_id    in mult_org.id%type )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   vn_multorg_id := en_multorg_id;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_CONV_UNID') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'ITEM';
   --
   gv_sql := null;
   --
   vt_tab_csf_conv_unid.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || 'pk_csf.fkg_converte( ' ||trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte( ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte( ' || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'FAT_CONV' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_CONV_UNID' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   gv_sql := gv_sql || ' and ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_item || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_conv_unid;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_conv_unid fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_conv_unid.count,0) > 0 then
      --
      for i in vt_tab_csf_conv_unid.first .. vt_tab_csf_conv_unid.last loop
         --
         vn_fase := 3.2;
         --
         pkb_conv_unid_ff( est_log_generico  => est_log_generico
                         , ev_cpf_cnpj       => vt_tab_csf_conv_unid(i).cpf_cnpj
                         , ev_cod_item       => vt_tab_csf_conv_unid(i).cod_item
                         , ev_sigla_unid     => vt_tab_csf_conv_unid(i).sigla_unid
                         , sn_multorg_id     => vn_multorg_id );
         --
         if nvl(vn_multorg_id, 0) = nvl(en_multorg_id, 0) or
            nvl(vn_multorg_id, 0) = 0 then

            pk_csf_api_cad.gt_row_conversao_unidade := null;
            --
            pk_csf_api_cad.gt_row_conversao_unidade.item_id     := en_item_id;
            pk_csf_api_cad.gt_row_conversao_unidade.fat_conv    := vt_tab_csf_conv_unid(i).fat_conv;
            --
            vn_fase := 3.3;
            --
            pk_csf_api_cad.pkb_integr_conv_unid ( est_log_generico       => est_log_generico
                                                , est_conversao_unidade  => pk_csf_api_cad.gt_row_conversao_unidade
                                                , ev_sigla_unid          => vt_tab_csf_conv_unid(i).sigla_unid
                                                , en_multorg_id          => en_multorg_id
                                                , en_empresa_id          => gn_empresa_id
                                                );
            --
            vn_fase := 3.4;
            --
            commit;
            --
            if nvl(vn_multorg_id, 0) = 0 then
               --
               gv_cabec_log := 'Mult Org da Conversão da Unidade '||vt_tab_csf_conv_unid(i).sigla_unid|| ' do Item: '||vt_tab_csf_conv_unid(i).cod_item||'não informado.';
               --
               gv_mensagem_log := 'A Conversão da Unidade '||vt_tab_csf_conv_unid(i).sigla_unid|| ' do Item: '||vt_tab_csf_conv_unid(i).cod_item||' foi registrado com o Mult Org do Item ' || vt_tab_csf_conv_unid(i).cod_item || '('||en_multorg_id||') por falta de informação.';
               --
               declare
                  vn_loggenericocad_id  log_generico_cad.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                      , ev_mensagem           => gv_mensagem_log
                                                      , ev_resumo             => gv_cabec_log
                                                      , en_tipo_log           => informacao
                                                      , en_referencia_id      => null
                                                      , ev_obj_referencia     => gv_obj_referencia
                                                      , en_empresa_id         => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
            end if;
            --
         else
            --
            gv_mensagem_log := 'A Conversão da Unidade '||vt_tab_csf_conv_unid(i).sigla_unid|| ' do Item: '||vt_tab_csf_conv_unid(i).cod_item||' não pertence ao mesmo Mult Org do Item ' || vt_tab_csf_conv_unid(i).cod_item || '.'
                               ||'Mult Org da Conversão da Unidade: '||vn_multorg_id||'Mult Org do Item: '||en_multorg_id;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => informacao
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
         end if;
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_conv_unid fase('||vn_fase||') item_id ('||en_item_id||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_conv_unid;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field de Item (Produtos/Serviços)
procedure pkb_ler_item_ff ( est_log_generico  in  out nocopy  dbms_sql.number_table
                          , en_item_id        in  item.id%type
                          , ev_cpf_cnpj       in  varchar2
                          , ev_cod_item       in  varchar2
                          , sn_multorg_id     in  out mult_org.id%type
                          )
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITEM_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'ITEM';
   --
   gv_sql := null;
   --
   vt_tab_csf_item_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || 'pk_csf.fkg_converte (' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte (' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITEM_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_item||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_item_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_item_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_item_ff.count > 0 then
      --
      for i in vt_tab_csf_item_ff.first..vt_tab_csf_item_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_item_ff(i).atributo not in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            -- Procedimento integra as informações do Item
            pk_csf_api_cad.pkb_integr_item_ff ( est_log_generico    => est_log_generico
                                              , en_item_id          => en_item_id
                                              , ev_atributo         => vt_tab_csf_item_ff(i).atributo
                                              , ev_valor            => vt_tab_csf_item_ff(i).valor
                                             );
            --
         end if;
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_ler_item_ff fase('||vn_fase||') cod_item('||pk_csf_api_cad.gt_row_item.cod_item||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_item.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_ler_item_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração Flex Field de Item (Produtos/Serviços)

procedure pkb_item_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                     , ev_cpf_cnpj       in  varchar2
                     , ev_cod_item       in  varchar2
                     , sn_multorg_id     in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITEM_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'ITEM';
   --
   gv_sql := null;
   --
   vt_tab_csf_item_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || 'pk_csf.fkg_converte (' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte (' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITEM_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_item||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_item_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => 'Item: ' || ev_cod_item
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_item_ff.count > 0 then
      --
      for i in vt_tab_csf_item_ff.first..vt_tab_csf_item_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_item_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Item - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_ITEM_FF'
                                                 , ev_atributo          => vt_tab_csf_item_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_item_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Item cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Item: ' || ev_cod_item
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_ff fase('||vn_fase||') cod_item('||pk_csf_api_cad.gt_row_item.cod_item||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => 'Item: ' || ev_cod_item
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_item.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_item_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração de Item (Produtos/Serviços)
procedure pkb_item  ( ev_cpf_cnpj in varchar2 )
is
   --
   vn_fase               number := 0;
   vt_log_generico       dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_integr_indiv       varchar2(1) := 'N';
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_empresa_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   else
      --
      gn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => gn_empresa_id );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITEM') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'ITEM';
   --
   -- A variável de formato de Data do Banco deve estar sempre com valor, seja dos parâmetros da empresa ou valor default, alimentada na integração geral.
   -- Quando esta variável estiver nula significa que o processo está sendo executado pela integração de dados fiscais - individual, e
   -- neste caso, os dados devem ser recuperados dentro de cada processo individual.
   if gv_formato_dt_erp is null then
      vv_integr_indiv := 'S';
      pkb_dados_bco_empr( ev_cpf_cnpj => ev_cpf_cnpj );
   end if;
   --
   vn_fase := 1.1;
   --
   gv_sql := null;
   --
   vt_tab_csf_item.delete;
   --
   -- inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || 'pk_csf.fkg_converte('||trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'DESCR_ITEM' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_ORIG_MERC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'TIPO_ITEM' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_NCM' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'EX_TIPI' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_BARRA' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_ANT_ITEM' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'TIPO_SERVICO' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ALIQ_ICMS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_PROD_ANP' || trim(GV_ASPAS);
   --
   vn_fase := 1.2;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITEM' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_item;
      --
   exception
      when others then
         --
         vn_fase := 2.1;
         -- Inicializar as variáveis devido a tela permanecer com os dados em default.
         if vv_integr_indiv = 'S' then
            pkb_limpa_dados_bco_empr;
         end if;
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
         --
   end;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_item.count,0);
   exception
      when others then
      null;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_item.count,0) > 0 then
      --
      for i in vt_tab_csf_item.first .. vt_tab_csf_item.last loop
         --
         vn_fase := 3.1;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.2;
         --
         pk_csf_api_cad.gt_row_item := null;
         --
         pk_csf_api_cad.gt_row_item.cod_item      := vt_tab_csf_item(i).cod_item;
         pk_csf_api_cad.gt_row_item.descr_item    := vt_tab_csf_item(i).descr_item;
         pk_csf_api_cad.gt_row_item.dm_orig_merc  := vt_tab_csf_item(i).dm_orig_merc;
         pk_csf_api_cad.gt_row_item.cod_barra     := vt_tab_csf_item(i).cod_barra;
         pk_csf_api_cad.gt_row_item.cod_ant_item  := vt_tab_csf_item(i).cod_ant_item;
         pk_csf_api_cad.gt_row_item.aliq_icms     := vt_tab_csf_item(i).aliq_icms;
         --
         vn_fase := 3.3;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            --
            vn_multorg_id := gn_multorg_id;
            --
         end if;
         --
         vn_fase := 3.4;
         --
         pkb_item_ff( est_log_generico  => vt_log_generico
                    , ev_cpf_cnpj       => vt_tab_csf_item(i).cpf_cnpj
                    , ev_cod_item       => vt_tab_csf_item(i).cod_item
                    , sn_multorg_id     => vn_multorg_id);
         --
         vn_fase := 3.5;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         vn_fase := 3.6;
         --
         pk_csf_api_cad.pkb_integr_item ( est_log_generico  => vt_log_generico
                                        , est_item          => pk_csf_api_cad.gt_row_item
                                        , en_multorg_id     => vn_multorg_id
                                        , ev_cpf_cnpj       => vt_tab_csf_item(i).cpf_cnpj
                                        , ev_sigla_unid     => vt_tab_csf_item(i).sigla_unid
                                        , ev_tipo_item      => vt_tab_csf_item(i).tipo_item
                                        , ev_cod_ncm        => vt_tab_csf_item(i).cod_ncm
                                        , ev_cod_ex_tipi    => vt_tab_csf_item(i).ex_tipi
                                        , ev_tipo_servico   => vt_tab_csf_item(i).tipo_servico
                                        , ev_cest_cd        => null
                                        );
         --
         vn_fase := 3.7;
         --
         commit;
         --
         vn_fase := 4;
         --
         if nvl(pk_csf_api_cad.gt_row_item.id,0) > 0 and
            pk_csf.fkg_item_id_valido ( en_item_id => pk_csf_api_cad.gt_row_item.id ) = true then
            --
            vn_fase := 5;
            --
            --
            pkb_ler_item_ff ( est_log_generico  => vt_log_generico
                            , en_item_id        => pk_csf_api_cad.gt_row_item.id
                            , ev_cpf_cnpj       => vt_tab_csf_item(i).cpf_cnpj
                            , ev_cod_item       => vt_tab_csf_item(i).cod_item
                            , sn_multorg_id     => vn_multorg_id
                            );
            --
            vn_fase := 5.01;
            --
            if nvl(vt_tab_csf_item(i).cod_prod_anp,0) > 0 then
               --
               vn_fase := 5.1;
               --
               pk_csf_api_cad.gt_row_item_anp := null;
               --
               pk_csf_api_cad.gt_row_item_anp.item_id       := pk_csf_api_cad.gt_row_item.id;
               pk_csf_api_cad.gt_row_item_anp.cod_prod_anp  := vt_tab_csf_item(i).cod_prod_anp;
               --
               vn_fase := 5.2;
               --
               pk_csf_api_cad.pkb_integr_item_anp ( est_log_generico  => vt_log_generico
                                                  , est_item_anp      => pk_csf_api_cad.gt_row_item_anp
                                                  , en_empresa_id     => pk_csf_api_cad.gt_row_item.empresa_id
                                                  );
               --
               vn_fase := 5.3;
               --
               commit;
               --
            end if;
            --
            vn_fase := 6;
            --
            if nvl(vn_multorg_id, 0) <= 0 then
               vn_multorg_id := gn_multorg_id;
            end if;
            -- Chama procedimento de integração da conversão de unidade do item
            pkb_conv_unid ( est_log_generico => vt_log_generico
                          , ev_cpf_cnpj      => vt_tab_csf_item(i).cpf_cnpj
                          , ev_cod_item      => vt_tab_csf_item(i).cod_item
                          , en_item_id       => pk_csf_api_cad.gt_row_item.id
                          , en_multorg_id    => vn_multorg_id );
            --
            vn_fase := 6.1;
            --
            commit;
            --
            vn_fase := 7;
            -- Chama procedimento de integração de informações de Códigos de Grupos por Marca Comercial/Refrigerantes
            pkb_item_marca_comerc ( est_log_generico => vt_log_generico
                                  , ev_cpf_cnpj      => vt_tab_csf_item(i).cpf_cnpj
                                  , ev_cod_item      => vt_tab_csf_item(i).cod_item
                                  , en_item_id       => pk_csf_api_cad.gt_row_item.id );
            --
            vn_fase := 7.1;
            --
            commit;
            --
            vn_fase := 8;
            --
            -- Chama Integracao dos complementos do item
            pkb_item_compl ( est_log_generico => vt_log_generico
                           , ev_cpf_cnpj      => vt_tab_csf_item(i).cpf_cnpj
                           , ev_cod_item      => vt_tab_csf_item(i).cod_item
                           , en_item_id       => pk_csf_api_cad.gt_row_item.id ) ;
            --
            commit;
            --
            vn_fase := 8.1;
            --
            -- Chama Integração de Itens de Insumo
            pkb_item_insumo ( est_log_generico => vt_log_generico
                            , ev_cpf_cnpj      => vt_tab_csf_item(i).cpf_cnpj
                            , ev_cod_item      => vt_tab_csf_item(i).cod_item
                            , en_item_id       => pk_csf_api_cad.gt_row_item.id);
            --
            commit;
            --
         end if;
         --
         vn_fase := 9;
         --
         if nvl(vt_log_generico.count,0) > 0 then
            -- Erro de validação
            update item set dm_st_proc = 2
             where id = pk_csf_api_cad.gt_row_item.id;
            --
         else
            -- Validado
            update item set dm_st_proc = 1
             where id = pk_csf_api_cad.gt_row_item.id;
            --
         end if;
         --
         vn_fase := 10;
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         commit;
         --
      end loop;
      --
   end if;
   --
   vn_fase := 10;
   -- Inicializar as variáveis devido a tela permanecer com os dados em default.
   if vv_integr_indiv = 'S' then
      pkb_limpa_dados_bco_empr;
   end if;
   --
exception
   when others then
      -- Inicializar as variáveis devido a tela permanecer com os dados em default.
      if nvl(vv_integr_indiv,'N') = 'S' then
         pkb_limpa_dados_bco_empr;
      end if;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item fase('||vn_fase||') item_id ('||pk_csf_api_cad.gt_row_item.id||') código do item ('||
                         pk_csf_api_cad.gt_row_item.cod_item||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_item;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração de Unidades de Medidas Flex Field
procedure pkb_unidade_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                        , ev_sigla_unid     in  varchar2
                        , sn_multorg_id     in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_UNIDADE_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'UNIDADE';
   --
   gv_sql := null;
   --
   vt_tab_csf_unidade_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || 'pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_UNIDADE_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS) || ' = ' ||''''||ev_sigla_unid||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_unidade_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_unidade_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => 'Unidade: ' || ev_sigla_unid
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_csf_unidade_ff.count > 0 then
      --
      for i in vt_tab_csf_unidade_ff.first..vt_tab_csf_unidade_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_unidade_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da Unidade - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_UNIDADE_FF'
                                                 , ev_atributo          => vt_tab_csf_unidade_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_unidade_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Unidade cadastrada com Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Unidade: ' || ev_sigla_unid
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_unidade_ff fase('||vn_fase||') sigla_unid('||pk_csf_api_cad.gt_row_unidade.sigla_unid||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => 'Unidade: ' || ev_sigla_unid
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_unidade.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_unidade_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento de integração de Unidades de Medidas
procedure pkb_unidade
is
   --
   vn_fase            number := 0;
   vt_log_generico    dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_UNIDADE') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'UNIDADE';
   --
   gv_sql := null;
   --
   vt_tab_csf_unidade.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select pk_csf.fkg_converte(u.';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(u.' || trim(GV_ASPAS) || 'DESCR' || trim(GV_ASPAS) || ') ';
   --
   vn_fase := 1.1;
   --
   if trim(gv_sistema_em_nuvem) = 'SIM' then
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_UNIDADE' ) || ' u, ';
      gv_sql := gv_sql || trim(replace(fkg_monta_from ( ev_obj => 'VW_CSF_UNIDADE_FF' ), 'from', '')) || ' f';
      --
      gv_sql := gv_sql || ' WHERE f.' || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS) || ' = u.' || trim(GV_ASPAS) || 'SIGLA_UNID' || trim(GV_ASPAS);
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS) || ' = ' || '''' || 'COD_MULT_ORG' || '''';
      gv_sql := gv_sql || ' and f.' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS) || ' = ' || '''' || trim(gv_multorg_cd) || '''';
      --
   else
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_UNIDADE' ) || ' u';
      --
   end if;
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_unidade;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_unidade fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_unidade.count,0);
   exception
      when others then
      null;
   end;
   --
   if nvl(vt_tab_csf_unidade.count,0) > 0 then
      --
      for i in vt_tab_csf_unidade.first .. vt_tab_csf_unidade.last loop
         --
         vn_fase := 3.1;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.2;
         --
         pk_csf_api_cad.gt_row_unidade := null;
         --
         pk_csf_api_cad.gt_row_unidade.sigla_unid  := vt_tab_csf_unidade(i).sigla_unid;
         pk_csf_api_cad.gt_row_unidade.descr       := vt_tab_csf_unidade(i).descr;
         --
         vn_fase := 3.3;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pkb_unidade_ff( est_log_generico  => vt_log_generico
                      , ev_sigla_unid => vt_tab_csf_unidade(i).sigla_unid
                      , sn_multorg_id  => vn_multorg_id);
         --
         vn_fase := 3.4;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pk_csf_api_cad.gt_row_unidade.multorg_id      := vn_multorg_id;
         --
         vn_fase := 3.5;
         --
         pk_csf_api_cad.pkb_integr_unid_med ( est_log_generico  => vt_log_generico
                                            , est_unidade       => pk_csf_api_cad.gt_row_unidade
                                            , en_empresa_id     => gn_empresa_id
                                            );
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         vn_fase := 3.6;
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
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_unidade fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_unidade;

-------------------------------------------------------------------------------------------------------

--| Procedimento de integração de de Informações de pagamentos de impostos retidos/SPED REINF
procedure pkb_pessoa_info_pir ( est_log_generico    in out nocopy  dbms_sql.number_table
                              , ev_cod_part         in             varchar2
                              , en_pessoa_id        in             number
                              )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PESSOA_INFO_PIR') = 0 then
      --
      return;
      --
   end if;
   --
   vt_tab_csf_pessoa_tipo_param.delete;
   --
   --
   gv_obj_referencia := 'PESSOA';
   --
   gv_sql := null;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql ||         trim(GV_ASPAS) || 'COD_PART'             || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_IND_NIF'           || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'NIF_BENEF'            || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CD_FONTE_PAGAD_REINF' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_LAUDO_MOLESTIA'    || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PESSOA_INFO_PIR' );
   --
   gv_sql := gv_sql || ' where ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_part || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_pessoa_info_pir;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pessoa_info_pir fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => en_pessoa_id
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_pessoa_info_pir.count,0) > 0 then
      --
      for i in vt_tab_csf_pessoa_info_pir.first .. vt_tab_csf_pessoa_info_pir.last loop
         --
         vn_fase := 3.1;
         --
         pk_csf_api_cad.gt_row_pessoa_info_pir.pessoa_id         := en_pessoa_id;
         pk_csf_api_cad.gt_row_pessoa_info_pir.dm_ind_nif        := vt_tab_csf_pessoa_info_pir(i).dm_ind_nif;
         pk_csf_api_cad.gt_row_pessoa_info_pir.nif_benef         := vt_tab_csf_pessoa_info_pir(i).nif_benef;
         pk_csf_api_cad.gt_row_pessoa_info_pir.dt_laudo_molestia := vt_tab_csf_pessoa_info_pir(i).dt_laudo_molestia;
         --
         pk_csf_api_cad.pkb_integr_pessoa_info_pir ( est_log_generico      => est_log_generico
                                                   , est_pessoa_info_pir   => pk_csf_api_cad.gt_row_pessoa_info_pir
                                                   , ev_cd_font_pag_reinf  => vt_tab_csf_pessoa_info_pir(i).cd_fonte_pagad_reinf
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pessoa_info_pir fase('||vn_fase||') cod_part('||pk_csf_api_cad.gt_row_pessoa.cod_part||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_pessoa.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_pessoa_info_pir;

-------------------------------------------------------------------------------------------------------

--| Procedimento de integração de Parâmetros Fiscais de Pessoa
procedure pkb_pessoa_tipo_param ( est_log_generico    in out nocopy  dbms_sql.number_table
                                , ev_cod_part         in             varchar2
                                , en_pessoa_id        in             number
                                )
is
   --
   vn_fase            number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PESSOA_TIPO_PARAM') = 0 then
      --
      return;
      --
   end if;
   --
   vt_tab_csf_pessoa_tipo_param.delete;
   --
   --
   gv_obj_referencia := 'PESSOA';
   --
   gv_sql := null;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || 'pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'CD_TIPO_PARAM' || trim(GV_ASPAS)|| ')';
   gv_sql := gv_sql || ', pk_csf.fkg_converte(' || trim(GV_ASPAS) || 'VALOR_TIPO_PARAM' || trim(GV_ASPAS)|| ')';
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PESSOA_TIPO_PARAM' );
   --
   gv_sql := gv_sql || ' where ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ' = ' || '''' || ev_cod_part || '''';
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_pessoa_tipo_param;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pessoa_tipo_param fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => en_pessoa_id
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_pessoa_tipo_param.count,0) > 0 then
      --
      for i in vt_tab_csf_pessoa_tipo_param.first .. vt_tab_csf_pessoa_tipo_param.last loop
         --
         vn_fase := 3.1;
         --
         pk_csf_api_cad.gt_row_pessoa_tipo_param.pessoa_id := en_pessoa_id;
         --
         pk_csf_api_cad.pkb_integr_pessoa_tipo_param ( est_log_generico       => est_log_generico
                                                     , est_pessoa_tipo_param  => pk_csf_api_cad.gt_row_pessoa_tipo_param
                                                     , ev_cd_tipo_param       => vt_tab_csf_pessoa_tipo_param(i).cd_tipo_param
                                                     , ev_valor_tipo_param    => vt_tab_csf_pessoa_tipo_param(i).valor_tipo_param
                                                     , en_empresa_id          => gn_empresa_id
                                                     );
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pessoa_tipo_param fase('||vn_fase||') cod_part('||pk_csf_api_cad.gt_row_pessoa.cod_part||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_pessoa.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_pessoa_tipo_param;

-------------------------------------------------------------------------------------------------------

--| Procedimento de integração de campos Flex-Field de Pessoa

procedure pkb_pessoa_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                       , ev_cod_part       in  varchar2
                       , sn_multorg_id     in  out mult_org.id%type
                       , sv_cod_nif        in  out pessoa.cod_nif%type )
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
   vn_existe_multorg     number := 0;
   vv_cod_nif            pessoa.cod_nif%type;
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PESSOA_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PESSOA';
   --
   gv_sql := null;
   --
   vt_tab_csf_pessoa_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql ||         trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR'    || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PESSOA_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_part||'''';
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_pessoa_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pessoa_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => 'Pessoa cod_part: ' || ev_cod_part
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   -- A variavel q identifica se houve integracao do id multorg
   vn_existe_multorg := 0;
   --
   if vt_tab_csf_pessoa_ff.count > 0 then
      --
      for i in vt_tab_csf_pessoa_ff.first..vt_tab_csf_pessoa_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_csf_pessoa_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_existe_multorg := vn_existe_multorg + 1;
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação do multorg - campos flex field.
            vv_cod_ret  := null;
            vv_hash_ret := null;
            --
            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_PESSOA_FF'
                                                 , ev_atributo          => vt_tab_csf_pessoa_ff(i).atributo
                                                 , ev_valor             => vt_tab_csf_pessoa_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
            --
            vn_fase := 6;
            --
            if vv_cod_ret is not null then
               vv_cod := vv_cod_ret;
            end if;
            --
            if vv_hash_ret is not null then
               vv_hash := vv_hash_ret;
            end if;
            --
            if nvl(est_log_generico.count, 0) <= 0 then
               --
               vn_fase := 7;
               --
               vn_multorg_id := sn_multorg_id;
               pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                                , ev_cod_mult_org    => vv_cod
                                                , ev_hash_mult_org   => vv_hash
                                                , sn_multorg_id      => vn_multorg_id
                                                , en_referencia_id   => gn_referencia_id
                                                , ev_obj_referencia  => gv_obj_referencia );
            end if;
            --
            vn_fase := 8;
            --
            sn_multorg_id := vn_multorg_id;
            --
         elsif vt_tab_csf_pessoa_ff(i).atributo in ('COD_NIF') then
            --
            vn_fase := 9;
            --
            vv_cod_nif := null;
            --
            -- Chama procedimento que faz a validação do cod_nif - campos flex field.
            pk_csf_api_cad.pkb_val_atrib_nif ( est_log_generico  => est_log_generico
                                             , ev_obj_name       => 'VW_CSF_PESSOA_FF'
                                             , ev_atributo       => vt_tab_csf_pessoa_ff(i).atributo
                                             , ev_valor          => vt_tab_csf_pessoa_ff(i).valor
                                             , ev_cod_part       => vt_tab_csf_pessoa_ff(i).cod_part
                                             , sv_cod_nif        => vv_cod_nif
                                             , en_referencia_id  => gn_referencia_id
                                             , ev_obj_referencia => gv_obj_referencia );
            --
            vn_fase := 10;
            --
            sv_cod_nif := vv_cod_nif;
            --
         elsif vt_tab_csf_pessoa_ff(i).atributo in ('NAT_SETOR_PESSOA') then			
            -- Chama procedimento que faz a validação e inclusão do nat_setor_pessoa - campos flex field.
            if nvl(vn_existe_multorg,0) <= 0 then
               sn_multorg_id := 1;
            end if;
            --			
            pk_csf_api_cad.pkb_integr_nat_set_pessoa ( est_log_generico  => est_log_generico
                                                     , ev_obj_name       => 'VW_CSF_PESSOA_FF'
                                                     , ev_atributo       => vt_tab_csf_pessoa_ff(i).atributo
                                                     , ev_valor          => vt_tab_csf_pessoa_ff(i).valor
                                                     , ev_cod_part       => vt_tab_csf_pessoa_ff(i).cod_part
                                                     , en_multorg_id     => sn_multorg_id													 
                                                     , en_referencia_id  => gn_referencia_id
                                                     , ev_obj_referencia => gv_obj_referencia );
            --			
         end if;
        --
      end loop;
      --
   end if;
   --
   -- Verifica se houve integracao do id multorg, do contrário insere log de informacao
   if nvl(vn_existe_multorg,0) <= 0 then
      --
      gv_mensagem_log := 'Pessoa cadastrada com Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Pessoa cod_part: ' || ev_cod_part
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          , en_empresa_id         => gn_empresa_id
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pessoa_ff fase('||vn_fase||') cod_part('||pk_csf_api_cad.gt_row_pessoa.cod_part||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => 'Pessoa cod_part: ' || ev_cod_part
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_pessoa.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_pessoa_ff;

-------------------------------------------------------------------------------------------------------

--| Procedimento de integração de Pessoa
procedure pkb_pessoa
is
   --
   vn_fase               number := 0;
   vt_log_generico       dbms_sql.number_table;
   vn_qtde_empresa       number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_multorg_id         mult_org.id%type;
   vv_cod_nif            pessoa.cod_nif%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   vn_fase := 1.1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_PESSOA') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'PESSOA';
   --
   gv_sql := null;
   --
   vt_tab_csf_pessoa.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select pk_csf.fkg_converte(p.';
   --#75771
   gv_sql := gv_sql ||                               trim(GV_ASPAS) || 'COD_PART'          || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.'                     || trim(GV_ASPAS) || 'DM_TIPO_PESSOA'    || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'NOME'              || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'FANTASIA'          || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'LOGRAD'            || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'NRO'               || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'CX_POSTAL'         || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'COMPL'             || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'BAIRRO'            || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'CIDADE_IBGE'       || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.'                     || trim(GV_ASPAS) || 'CEP'               || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'FONE'              || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'FAX'               || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'EMAIL'             || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.'                     || trim(GV_ASPAS) || 'COD_SISCOMEX_PAIS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'CPF_CNPJ'          || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'RG_IE'             || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'IEST'              || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'IM'                || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'SUFRAMA'           || trim(GV_ASPAS);
   gv_sql := gv_sql || ', p.' || trim(GV_ASPAS) || 'INSCR_PROD'        || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   if trim(gv_sistema_em_nuvem) = 'SIM' then
      --
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PESSOA' ) || ' p, ';
      gv_sql := gv_sql || trim(replace(fkg_monta_from ( ev_obj => 'VW_CSF_PESSOA_FF' ), 'from', '')) || ' f';
      --
      gv_sql := gv_sql || ' WHERE p.' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ' is not null ';
      gv_sql := gv_sql || ' and f.'   || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ' = p.' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
      gv_sql := gv_sql || ' and f.'   || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS) || ' = '   || '''' || 'COD_MULT_ORG' || '''';
      gv_sql := gv_sql || ' and f.'   || trim(GV_ASPAS) || 'VALOR'    || trim(GV_ASPAS) || ' = '   || '''' || trim(gv_multorg_cd) || '''';
      --
   else
      --
      gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_PESSOA' ) || ' p';
      --
      gv_sql := gv_sql || ' WHERE p.' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS) || ' is not null ';
      --
   end if;
   --
   gv_sql := gv_sql || ' ORDER BY p.' || trim(GV_ASPAS) || 'COD_PART' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   --insert into erro values (gv_sql); commit;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_pessoa;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pessoa fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_pessoa.count,0);
   exception
      when others then
      null;
   end;
   --
   if nvl(vt_tab_csf_pessoa.count,0) > 0 then
      --
      for i in vt_tab_csf_pessoa.first .. vt_tab_csf_pessoa.last loop
         --
         vn_fase := 3.1;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.2;
         -- informações de Pessoa
         pk_csf_api_cad.gt_row_pessoa := null;
         --#75771
         pk_csf_api_cad.gt_row_pessoa.cod_part        := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).cod_part);
         pk_csf_api_cad.gt_row_pessoa.nome            := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).nome);
         pk_csf_api_cad.gt_row_pessoa.dm_tipo_pessoa  := vt_tab_csf_pessoa(i).dm_tipo_pessoa;
         pk_csf_api_cad.gt_row_pessoa.fantasia        := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).fantasia);
         pk_csf_api_cad.gt_row_pessoa.lograd          := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).lograd);
         pk_csf_api_cad.gt_row_pessoa.nro             := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).nro);
         pk_csf_api_cad.gt_row_pessoa.cx_postal       := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).cx_postal);
         pk_csf_api_cad.gt_row_pessoa.compl           := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).compl);
         pk_csf_api_cad.gt_row_pessoa.bairro          := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).bairro);
         pk_csf_api_cad.gt_row_pessoa.cep             := vt_tab_csf_pessoa(i).cep;
         pk_csf_api_cad.gt_row_pessoa.fone            := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).fone);
         pk_csf_api_cad.gt_row_pessoa.fax             := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).fax);
         pk_csf_api_cad.gt_row_pessoa.email           := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).email);
         --
         vn_fase := 3.3;
         --
         vn_multorg_id := gn_multorg_id;
         --
         pkb_pessoa_ff( est_log_generico  => vt_log_generico
                      , ev_cod_part       => vt_tab_csf_pessoa(i).cod_part
                      , sn_multorg_id     => vn_multorg_id
                      , sv_cod_nif        => vv_cod_nif );
         --
         vn_fase := 3.4;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         -- Array de dados de pessoa recebe os valores da integracao flex-field
         pk_csf_api_cad.gt_row_pessoa.multorg_id := vn_multorg_id;
         pk_csf_api_cad.gt_row_pessoa.cod_nif    := vv_cod_nif;
         --
         begin
            --
            select count(1)
              into vn_qtde_empresa
              from pessoa p
                 , empresa e
             where p.cod_part    = trim(pk_csf_api_cad.gt_row_pessoa.cod_part)
               and e.pessoa_id   = p.id
               and e.multorg_id  = vn_multorg_id;
            --
         exception
            when others then
               vn_qtde_empresa := 0;
         end;
         --
         vn_fase := 3.5;
         --
         if nvl(vn_qtde_empresa,0) > 0 then
            --
            goto proximo;
            --
         end if;
         --
         vn_fase := 4;
         -- chama API de integração de pessoa
         pk_csf_api_cad.pkb_ins_atual_pessoa ( est_log_generico  => vt_log_generico
                                             , est_pessoa        => pk_csf_api_cad.gt_row_pessoa
                                             , ev_ibge_cidade    => vt_tab_csf_pessoa(i).cidade_ibge
                                             , en_cod_siscomex   => vt_tab_csf_pessoa(i).cod_siscomex_pais
                                             , en_empresa_id     => gn_empresa_id
                                             );
         --
         vn_fase := 5;
         if pk_csf_api_cad.gt_row_pessoa.dm_tipo_pessoa = 0
            and nvl(pk_csf_api_cad.gt_row_pessoa.id,0) > 0
            then -- Pessoa Física
            --
            vn_fase := 5.1;
            --
            pk_csf_api_cad.gt_row_fisica := null;
            --
            pk_csf_api_cad.gt_row_fisica.pessoa_id  := pk_csf_api_cad.gt_row_pessoa.id;
            --
            if pk_csf.fkg_is_numerico(replace(vt_tab_csf_pessoa(i).cpf_cnpj, '.', '')) then
               pk_csf_api_cad.gt_row_fisica.num_cpf    := to_number(substr(lpad(trim(pk_csf.fkg_converte(replace(vt_tab_csf_pessoa(i).cpf_cnpj, '.', ''))), 11, '0'), 1, 9));
               pk_csf_api_cad.gt_row_fisica.dig_cpf    := to_number(substr(lpad(trim(pk_csf.fkg_converte(replace(vt_tab_csf_pessoa(i).cpf_cnpj, '.', ''))), 11, '0'), 10, 2));
            else
               pk_csf_api_cad.gt_row_fisica.num_cpf    := 0;
               pk_csf_api_cad.gt_row_fisica.dig_cpf    := 0;
            end if;
            --
            pk_csf_api_cad.gt_row_fisica.rg         := vt_tab_csf_pessoa(i).rg_ie;
            pk_csf_api_cad.gt_row_fisica.inscr_prod := vt_tab_csf_pessoa(i).inscr_prod;
            --
            vn_fase := 5.2;
            --
            pk_csf_api_cad.pkb_ins_atual_fisica ( est_log_generico  => vt_log_generico
                                                , est_fisica        => pk_csf_api_cad.gt_row_fisica
                                                , en_empresa_id     => gn_empresa_id
                                                );
            --
            vn_fase := 5.3;
            --| Atualiza os dados de tabelas dependentes de Pessoa
            pk_csf_api_cad.pkb_atual_dep_pessoa ( en_multorg_id  => vn_multorg_id
                                                , ev_cpf_cnpj    => lpad(vt_tab_csf_pessoa(i).cpf_cnpj, 11, '0')
                                                , en_empresa_id  => gn_empresa_id
                                                );
            --
         elsif pk_csf_api_cad.gt_row_pessoa.dm_tipo_pessoa = 1
            and nvl(pk_csf_api_cad.gt_row_pessoa.id,0) > 0
            then -- Pessoa Jurídica
            --
            vn_fase := 6;
            --
            pk_csf_api_cad.gt_row_juridica := null;
            --
            pk_csf_api_cad.gt_row_juridica.pessoa_id   := pk_csf_api_cad.gt_row_pessoa.id;
            vn_fase := 6.1;
            if pk_csf.fkg_is_numerico(replace(vt_tab_csf_pessoa(i).cpf_cnpj, '.', '')) then
               pk_csf_api_cad.gt_row_juridica.num_cnpj    := to_number(substr(lpad(trim(pk_csf.fkg_converte(replace(vt_tab_csf_pessoa(i).cpf_cnpj, '.', ''))), 14, '0'), 1, 8));
               vn_fase := 6.2;
               pk_csf_api_cad.gt_row_juridica.num_filial  := to_number(substr(lpad(trim(pk_csf.fkg_converte(replace(vt_tab_csf_pessoa(i).cpf_cnpj, '.', ''))), 14, '0'), 9, 4));
               vn_fase := 6.3;
               pk_csf_api_cad.gt_row_juridica.dig_cnpj    := to_number(substr(lpad(trim(pk_csf.fkg_converte(replace(vt_tab_csf_pessoa(i).cpf_cnpj, '.', ''))), 14, '0'), 13, 2));
            else
               pk_csf_api_cad.gt_row_juridica.num_cnpj    := 0;
               pk_csf_api_cad.gt_row_juridica.num_filial  := 0;
               pk_csf_api_cad.gt_row_juridica.dig_cnpj    := 0;
            end if;
            --
            vn_fase := 6.4;
            pk_csf_api_cad.gt_row_juridica.ie          := pk_csf.fkg_converte(vt_tab_csf_pessoa(i).rg_ie);
            pk_csf_api_cad.gt_row_juridica.iest        := trim(vt_tab_csf_pessoa(i).iest);
            pk_csf_api_cad.gt_row_juridica.im          := trim(vt_tab_csf_pessoa(i).im);
            vn_fase := 6.5;
            pk_csf_api_cad.gt_row_juridica.suframa     := substr(replace(replace(replace(replace(pk_csf.fkg_converte(trim(vt_tab_csf_pessoa(i).suframa)),'.',''),'-',''),',',''),'/',''),1,9);
            --
            pk_csf_api_cad.pkb_ins_atual_juridica ( est_log_generico  => vt_log_generico
                                                  , est_juridica      => pk_csf_api_cad.gt_row_juridica
                                                  , en_empresa_id     => gn_empresa_id
                                                  );
            --
            vn_fase := 6.6;
            --| Atualiza os dados de tabelas dependentes de Pessoa
            pk_csf_api_cad.pkb_atual_dep_pessoa ( en_multorg_id  => vn_multorg_id
                                                , ev_cpf_cnpj    => lpad(vt_tab_csf_pessoa(i).cpf_cnpj, 14, '0')
                                                , en_empresa_id  => gn_empresa_id
                                                );
            --
         end if;
         --
         vn_fase := 7;
         --
         --| Leitura de integração de Parâmetros Fiscais de Pessoa
         pkb_pessoa_tipo_param ( est_log_generico    => vt_log_generico
                               , ev_cod_part         => pk_csf_api_cad.gt_row_pessoa.cod_part
                               , en_pessoa_id        => pk_csf_api_cad.gt_row_pessoa.id
                               );
         --
         vn_fase := 7.1;
         --
         --| Atualiza cadastro de e-mails conforme CPF/CNPJ
         pk_csf_api_cad.pkb_atual_email_pessoa ( en_multorg_id => vn_multorg_id
                                               , ev_cpf_cnpj   => vt_tab_csf_pessoa(i).cpf_cnpj
                                               , ev_email      => vt_tab_csf_pessoa(i).email
                                               );
         --
         vn_fase := 7.2;
         --
         --| Leitura de integração de informações de pagamentos de impostos retidos/SPED REINF
         pkb_pessoa_info_pir ( est_log_generico    => vt_log_generico
                             , ev_cod_part         => pk_csf_api_cad.gt_row_pessoa.cod_part
                             , en_pessoa_id        => pk_csf_api_cad.gt_row_pessoa.id
                             );
         --
         vn_fase := 7.3;
         --
         if nvl(VT_LOG_GENERICO.count,0) > 0 then
            --
            update pessoa set dm_st_proc = 2 -- Erro de Validação
             where id = pk_csf_api_cad.gt_row_pessoa.id;
            --
         else
            --
            update pessoa set dm_st_proc = 1 -- Validado
             where id = pk_csf_api_cad.gt_row_pessoa.id;
            --
         end if;
         --
         vn_fase := 7.4;
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
         --
         vn_fase := 7.5;
         --
         commit;
         --
         <<proximo>>
         --
         null;
         --
      end loop;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_pessoa fase('||vn_fase||') cod_part('||pk_csf_api_cad.gt_row_pessoa.cod_part||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_pessoa.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_pessoa;

-------------------------------------------------------------------------------------------------------
--| Procedimento integra os dados Flex Field de Parâmetros de Cálculo de ICMS-ST
procedure pkb_item_param_icmsst_ff( est_log_generico    in  out nocopy  dbms_sql.number_table
                                  , ev_cpf_cnpj         varchar2
                                  , ev_cod_item         varchar2
                                  , ev_sigla_uf_dest    varchar2
                                  , en_cfop_orig        number
                                  , ed_dt_ini           date
                                  , ed_dt_fin           date
                                  , sn_multorg_id       in out mult_org.id%type)
is
   vn_fase               number := 0;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vv_cod                mult_org.cd%type;
   vv_hash               mult_org.hash%type;
   vv_cod_ret            mult_org.cd%type;
   vv_hash_ret           mult_org.hash%type;
   vn_multorg_id         mult_org.id%type := 0;
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_multorg_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITEM_PARAM_ICMSST_FF') = 0 then
      --
      sn_multorg_id := vn_multorg_id;
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'ITEM_PARAM_ICMSST';
   --
   gv_sql := null;
   --
   vt_tab_item_param_icmsst_ff.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'SIGLA_UF_DEST' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CFOP_ORIG' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_INI' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_FIN' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'VALOR' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITEM_PARAM_ICMSST_FF' );
   --
   gv_sql := gv_sql || ' WHERE ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' ||''''||ev_cpf_cnpj||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS) || ' = ' ||''''||ev_cod_item||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'SIGLA_UF_DEST' || trim(GV_ASPAS) || ' = ' ||''''||ev_sigla_uf_dest||'''';
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'CFOP_ORIG' || trim(GV_ASPAS) || ' = ' ||en_cfop_orig;
   --
   gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'DT_INI' || trim(GV_ASPAS) || ' = to_date(' ||''''||ed_dt_ini||''')';
   --
   if ed_dt_fin is not null then
      --
      gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'DT_FIN' || trim(GV_ASPAS) || ' = to_date(' ||''''||ed_dt_fin||''')';
      --
   else
      --
      gv_sql := gv_sql || ' AND ' || trim(GV_ASPAS) || 'DT_FIN' || trim(GV_ASPAS) || ' is null ';
      --
   end if;
   --
   gv_sql := gv_sql || ' ORDER BY ' || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'SIGLA_UF_DEST' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'CFOP_ORIG' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'DT_INI' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'DT_FIN' || trim(GV_ASPAS);
   --
   gv_sql := gv_sql || ', '|| trim(GV_ASPAS) || 'ATRIBUTO' || trim(GV_ASPAS);
   --
   vn_fase := 2;
   -- recupera as Notas Fiscais não integradas
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_item_param_icmsst_ff;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_param_icmsst_ff fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => 'Parâmetros de Cálculo de ICMS-ST: ' || ev_cod_item
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => pk_csf_api_cad.gt_row_item_param_icmsst.id
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   vn_fase := 3;
   --
   if vt_tab_item_param_icmsst_ff.count > 0 then
      --
      for i in vt_tab_item_param_icmsst_ff.first..vt_tab_item_param_icmsst_ff.last loop
         --
         vn_fase := 4;
         --
         if vt_tab_item_param_icmsst_ff(i).atributo in ('COD_MULT_ORG', 'HASH_MULT_ORG') then
            --
            vn_fase := 5;
            -- Chama procedimento que faz a validação dos itens da  Plano de contas - campos flex field.
            vv_cod_ret := null;
            vv_hash_ret := null;

            pk_csf_api_cad.pkb_val_atrib_multorg ( est_log_generico     => est_log_generico
                                                 , ev_obj_name          => 'VW_CSF_ITEM_PARAM_ICMSST_FF'
                                                 , ev_atributo          => vt_tab_item_param_icmsst_ff(i).atributo
                                                 , ev_valor             => vt_tab_item_param_icmsst_ff(i).valor
                                                 , sv_cod_mult_org      => vv_cod_ret
                                                 , sv_hash_mult_org     => vv_hash_ret
                                                 , en_referencia_id     => gn_referencia_id
                                                 , ev_obj_referencia    => gv_obj_referencia);
           --
           vn_fase := 6;
           --
           if vv_cod_ret is not null then
              vv_cod := vv_cod_ret;
           end if;
           --
           if vv_hash_ret is not null then
              vv_hash := vv_hash_ret;
           end if;
           --
        end if;
        --
      end loop;
      --
      vn_fase := 7;
      --
      if nvl(est_log_generico.count, 0) <= 0 then
         --
         vn_fase := 8;
         --
         vn_multorg_id := sn_multorg_id;
         --
         pk_csf_api_cad.pkb_ret_multorg_id( est_log_generico   => est_log_generico
                                          , ev_cod_mult_org    => vv_cod
                                          , ev_hash_mult_org   => vv_hash
                                          , sn_multorg_id      => vn_multorg_id
                                          , en_referencia_id   => gn_referencia_id
                                          , ev_obj_referencia  => gv_obj_referencia
                                          );
         --
      end if;
      --
      vn_fase := 9;
      --
      sn_multorg_id := vn_multorg_id;
      --
   else
      --
      gv_mensagem_log := 'Parâmetros de Cálculo de ICMS-ST cadastrada a partir do Mult Org default (codigo = 1), pois não foram passados o codigo e a hash do multorg.';
      --
      vn_loggenericocad_id := null;
      --
      vn_fase := 10;
      --
      pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                          , ev_mensagem           => gv_mensagem_log
                                          , ev_resumo             => 'Parâmetros de Cálculo de ICMS-ST: ' || ev_cod_item
                                          , en_tipo_log           => INFORMACAO
                                          , en_referencia_id      => gn_referencia_id
                                          , ev_obj_referencia     => gv_obj_referencia
                                          );
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_param_icmsst_ff fase('||vn_fase||') item_id('||pk_csf_api_cad.gt_row_item_param_icmsst.item_id||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => 'Parâmetros de Cálculo de ICMS-ST: ' || ev_cod_item
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => pk_csf_api_cad.gt_row_item_param_icmsst.id
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_item_param_icmsst_ff;

-------------------------------------------------------------------------------------------------------
--| Procedimento integra os dados de Parâmetros de Cálculo de ICMS-ST
procedure pkb_item_param_icmsst ( ev_cpf_cnpj  in  varchar2 )
is
   --
   vn_fase            number := 0;
   vt_log_generico    dbms_sql.number_table;
   vn_loggenericocad_id  log_generico_cad.id%TYPE;
   vn_multorg_id         mult_org.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_empresa_id, 0) <= 0 then
      --
      gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
      --
   else
      --
      gn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => gn_empresa_id );
      --
   end if;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'VW_CSF_ITEM_PARAM_ICMSST') = 0 then
      --
      return;
      --
   end if;
   --
   gv_obj_referencia := 'ITEM_PARAM_ICMSST';
   pk_csf_api_ecd.pkb_seta_tipo_integr_ecd ( en_tipo_integr_ecd => 1 );
   --
   gv_sql := null;
   --
   vt_tab_csf_item_param_icmsst.delete;
   --
   --  inicia montagem da query
   gv_sql := 'select ';
   --
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ITEM' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'SIGLA_UF_DEST' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CFOP_ORIG' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_MOD_BASE_CALC_ST' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_INI' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DT_FIN' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'ALIQ_DEST' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_OBS' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'CFOP_DEST' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'COD_ST' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'INDICE' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'PERC_REDUC_BC' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_AJUSTA_MVA' || trim(GV_ASPAS);
   gv_sql := gv_sql || ', ' || trim(GV_ASPAS) || 'DM_EFEITO' || trim(GV_ASPAS);
   --
   vn_fase := 1.1;
   --
   gv_sql := gv_sql || fkg_monta_from ( ev_obj => 'VW_CSF_ITEM_PARAM_ICMSST' );
   --
   -- Monta a condição do where
   gv_sql := gv_sql || ' where ';
   gv_sql := gv_sql || trim(GV_ASPAS) || 'CPF_CNPJ' || trim(GV_ASPAS) || ' = ' || '''' || ev_cpf_cnpj || '''';
   --
   vn_fase := 2;
   --
   begin
      --
      execute immediate gv_sql bulk collect into vt_tab_csf_item_param_icmsst;
      --
   exception
      when others then
         -- não registra erro caso a view não exista
         if sqlcode = -942 then
            null;
         else
            --
            gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_param_icmsst fase('||vn_fase||'):'||sqlerrm;
            --
            declare
               vn_loggenericocad_id  log_generico_cad.id%TYPE;
            begin
               --
               pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                                   , ev_mensagem           => gv_mensagem_log
                                                   , ev_resumo             => gv_mensagem_log
                                                   , en_tipo_log           => ERRO_DE_SISTEMA
                                                   , en_referencia_id      => null
                                                   , ev_obj_referencia     => gv_obj_referencia
                                                   , en_empresa_id         => gn_empresa_id
                                                   );
               --
            exception
               when others then
                  null;
            end;
            --
            raise_application_error (-20101, gv_mensagem_log);
            --
         end if;
   end;
   --
   -- Calcula a quantidade de registros buscados no ERP
   -- para ser mostrado na tela de agendamento.
   --
   begin
      pk_agend_integr.gvtn_qtd_erp(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erp(gv_cd_obj),0) + nvl(vt_tab_csf_item_param_icmsst.count,0);
   exception
      when others then
      null;
   end;
   --
   vn_fase := 3;
   --
   if nvl(vt_tab_csf_item_param_icmsst.count,0) > 0 then
      --
      vn_fase := 3.1;
      --
      for i in vt_tab_csf_item_param_icmsst.first .. vt_tab_csf_item_param_icmsst.last loop
         --
         vn_fase := 3.2;
         --
         VT_LOG_GENERICO.delete;
         --
         vn_fase := 3.3;
         --
         pk_csf_api_cad.gt_row_item_param_icmsst := null;
         --
         pk_csf_api_cad.gt_row_item_param_icmsst.dm_mod_base_calc_st  := vt_tab_csf_item_param_icmsst(i).dm_mod_base_calc_st;
         pk_csf_api_cad.gt_row_item_param_icmsst.dt_ini           := vt_tab_csf_item_param_icmsst(i).dt_ini;
         pk_csf_api_cad.gt_row_item_param_icmsst.dt_fin           := vt_tab_csf_item_param_icmsst(i).dt_fin;
         pk_csf_api_cad.gt_row_item_param_icmsst.aliq_dest        := vt_tab_csf_item_param_icmsst(i).aliq_dest;
         pk_csf_api_cad.gt_row_item_param_icmsst.indice           := vt_tab_csf_item_param_icmsst(i).indice;
         pk_csf_api_cad.gt_row_item_param_icmsst.perc_reduc_bc       := vt_tab_csf_item_param_icmsst(i).perc_reduc_bc;
         pk_csf_api_cad.gt_row_item_param_icmsst.dm_ajusta_mva       := vt_tab_csf_item_param_icmsst(i).dm_ajusta_mva;
         pk_csf_api_cad.gt_row_item_param_icmsst.dm_efeito        := vt_tab_csf_item_param_icmsst(i).dm_efeito;
         --
         vn_fase := 3.4;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            --
            vn_multorg_id := gn_multorg_id;
            --
         end if;
         --
         pkb_item_param_icmsst_ff( est_log_generico  => vt_log_generico
                                 , ev_cpf_cnpj       => vt_tab_csf_item_param_icmsst(i).cpf_cnpj
                                 , ev_cod_item       => vt_tab_csf_item_param_icmsst(i).cod_item
                                 , ev_sigla_uf_dest  => vt_tab_csf_item_param_icmsst(i).sigla_uf_dest
                                 , en_cfop_orig      => vt_tab_csf_item_param_icmsst(i).cfop_orig
                                 , ed_dt_ini         => vt_tab_csf_item_param_icmsst(i).dt_ini
                                 , ed_dt_fin         => vt_tab_csf_item_param_icmsst(i).dt_fin
                                 , sn_multorg_id     => vn_multorg_id);
         --
         vn_fase := 3.5;
         --
         if nvl(vn_multorg_id, 0) <= 0 then
            vn_multorg_id := gn_multorg_id;
         end if;
         --
         pk_csf_api_cad.pkb_integr_item_param_icmsst ( est_log_generico       =>  vt_log_generico
                                                     , est_item_param_icmsst  =>  pk_csf_api_cad.gt_row_item_param_icmsst
                                                     , en_multorg_id          =>  vn_multorg_id
                                                     , ev_cpf_cnpj            =>  vt_tab_csf_item_param_icmsst(i).cpf_cnpj
                                                     , ev_cod_item            =>  vt_tab_csf_item_param_icmsst(i).cod_item
                                                     , ev_sigla_uf_dest       =>  vt_tab_csf_item_param_icmsst(i).sigla_uf_dest
                                                     , en_cfop_orig           =>  vt_tab_csf_item_param_icmsst(i).cfop_orig
                                                     , ev_cod_obs             =>  vt_tab_csf_item_param_icmsst(i).cod_obs
                                                     , en_cfop_dest           =>  vt_tab_csf_item_param_icmsst(i).cfop_dest
                                                     , ev_cod_st              =>  vt_tab_csf_item_param_icmsst(i).cod_st 
                                                     );
         --
         vn_fase := 3.6;
         --
         -- Calcula a quantidade de registros integrados com sucesso
         -- e com erro para ser mostrado na tela de agendamento.
         begin
            --
            if pk_agend_integr.gvtn_qtd_total(gv_cd_obj) >
               (pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) + pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj)) then
               --
               if nvl(VT_LOG_GENERICO.count,0) > 0 then -- Erro de validação
                  --
                  pk_agend_integr.gvtn_qtd_erro(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_erro(gv_cd_obj),0) + 1;
                  --
               else
                  --
                  pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_sucesso(gv_cd_obj),0) + 1;
                  --
               end if;
               --
            end if;
            --
         exception
            when others then
            null;
         end;
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
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_item_param_icmsst fase('||vn_fase||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_item_param_icmsst;

-------------------------------------------------------------------------------------------------------

-- executa procedure Stafe
procedure pkb_stafe ( ev_cpf_cnpj in varchar2
                    , ed_dt_ini   in date
                    , ed_dt_fin   in date 
                    )
is
   --
   vn_fase number := 0;
   --
begin
   --
   vn_fase := 1;
   --
   if pk_csf.fkg_existe_obj_util_integr ( ev_obj_name => 'PK_INT_CAD_STAFE_CSF') = 0 then
      --
      return;
      --
   end if;
   --
   if length(ev_cpf_cnpj) in (11, 14) then
      --
      vn_fase := 2;
      --
      gv_sql := 'begin PK_INT_CAD_STAFE_CSF.PB_GERA(' ||
                           ev_cpf_cnpj || ', ' ||
                           '''' || to_date(ed_dt_ini, gv_formato_dt_erp) || '''' || ', ' ||
                           '''' || to_date(ed_dt_fin, gv_formato_dt_erp) || '''' || ' ); end;';
      --
      begin
         --
         execute immediate gv_sql;
         --
      exception
         when others then
            -- não registra erro casa a view não exista
            if sqlcode = -942 then
               null;
            else
               --
               gv_mensagem_log := 'Erro na pkb_stafe fase(' || vn_fase || '):' || sqlerrm;
               --
               declare
                  vn_loggenerico_id  Log_Generico.id%TYPE;
               begin
                  --
                  pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenerico_id
                                                      , ev_mensagem           => gv_mensagem_log
                                                      , ev_resumo             => gv_mensagem_log
                                                      , en_tipo_log           => ERRO_DE_SISTEMA
                                                      , en_referencia_id      => null
                                                      , ev_obj_referencia     => gv_obj_referencia
                                                      , en_empresa_id         => gn_empresa_id
                                                      );
                  --
               exception
                  when others then
                     null;
               end;
               --
               raise_application_error (-20101, gv_mensagem_log);
            --
            end if;
      end;
      --
   end if;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pkb_stafe fase(' || vn_fase || '):' || sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenerico_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_referencia_id      => null
                                             , ev_obj_referencia     => gv_obj_referencia
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_stafe;

-------------------------------------------------------------------------------------------------------------------------------

--| Procedimento que inicia a integração de cadastros
procedure pkb_integracao ( en_empresa_id  in  empresa.id%type
                         , ed_dt_ini      in  date
                         , ed_dt_fin      in  date
                         , en_nro_linha   in  number default 1 --#68800 
                         )
is
   --
   vn_fase number := 0;
   --
   vv_teste    varchar2(1000);
   vv_cpf_cnpj varchar2(14);
   --
   cursor c_empr is
   select e.id empresa_id
        , e.dt_ini_integr
        , eib.owner_obj
        , eib.nome_dblink
        , eib.dm_util_aspa
        , eib.dm_ret_infor_integr
        , eib.formato_dt_erp
        , eib.dm_form_dt_erp
     from empresa e
        , empresa_integr_banco eib
    where e.id             = en_empresa_id
      and e.dm_tipo_integr in (3, 4) -- Integração por view
      and e.dm_situacao    = 1 -- Ativa
      and eib.empresa_id   = e.id
    order by 1;
   --
begin
   -- Inicia os contadores de registros a serem integrados
   pk_agend_integr.pkb_inicia_cont(ev_cd_obj => gv_cd_obj);
   --
   vn_fase := 1;
   --
   gv_formato_data := pk_csf.fkg_param_global_csf_form_data;
   --
   gn_multorg_id := pk_csf.fkg_multorg_id_empresa ( en_empresa_id => en_empresa_id );
   --
   gv_multorg_cd := pk_csf.fkg_multorg_cd ( en_multorg_id => gn_multorg_id );
   --
   vn_fase := 1.1;
   --
   gn_empresa_id := en_empresa_id;
   --
   vn_fase := 1.2;
   --
   vv_cpf_cnpj := pk_csf.fkg_cnpj_ou_cpf_empresa ( en_empresa_id => en_empresa_id );
   --
   vn_fase := 1.3;
   --
   gv_sistema_em_nuvem := pk_csf.fkg_vlr_param_global_csf ( ev_paramglobalcsf_cd => 'SISTEMA_EM_NUVEM' );
   --
   for rec in c_empr loop
      exit when c_empr%notfound or (c_empr%notfound) is null;
      --
      vn_fase := 2;
      -- Se ta o DBLink
      GV_NOME_DBLINK := rec.nome_dblink;
      GV_OWNER_OBJ   := rec.owner_obj;
      --
      vn_fase := 3;
      -- Verifica se utiliza GV_ASPAS dupla
      if rec.dm_util_aspa = 1 then
         --
         GV_ASPAS := '"';
         --
      else
         --
         GV_ASPAS := null;
         --
      end if;
      --  Seta formata da data para os procedimentos de retorno
      if trim(rec.formato_dt_erp) is not null then
         gv_formato_dt_erp := rec.formato_dt_erp;
      else
         gv_formato_dt_erp := gv_formato_data;
      end if;
      --
      vn_fase := 4;
      --
      pkb_stafe ( ev_cpf_cnpj => vv_cpf_cnpj
                , ed_dt_ini   => ed_dt_ini
                , ed_dt_fin   => ed_dt_fin
                );
      --
      vn_fase := 5;
      --
      --#68800 so executa uma vez por multiorg    
      if en_nro_linha = 1 then
        --
        vn_fase := 6;
        --
        pkb_pessoa;
        --
        vn_fase := 7;
        --
        pkb_unidade;
        --
        vn_fase := 8;
        --
        pkb_inf_comp_dcto_fis;
        --
        vn_fase := 9;
        --
        pkb_obs_lancto_fiscal;
        --
        vn_fase := 10;
        --
        pkb_nat_oper;
        --
        vn_fase := 11;
        --
      end if;
      --
      vn_fase := 12;
      --
      pkb_item ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 13;
      -- Executa procedure Softfacil para geração dos dados de cadastro de Bens Imobilizados
      pkb_softfacil ( ev_cpf_cnpj => vv_cpf_cnpj
                    , ed_dt_ini   => ed_dt_ini
                    , ed_dt_fin   => ed_dt_fin );
      --
      vn_fase := 14;
      --
      pkb_grupo_pat ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 15;
      --
      pkb_bem_ativo_imob ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 16;
      --
      pkb_plano_conta ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 17;
      --
      pkb_centro_custo ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 18;
      --
      pkb_hist_padrao ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 19;
      --
      pkb_item_param_icmsst ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 20;
      --
      pkb_ctrl_ver_contab ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 21;
      --
      pkb_legado_fci ( ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 22;
      --
      pkb_aglut_contabil ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 23;
      --
      pkb_ler_item_fornc_eu (ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 24;
      --
      pkb_ler_oper_fiscal_ent ( ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 25;
      --
      gn_empresa_id := en_empresa_id;
      --
      pkb_ler_param_dipamgia ( ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 26;
      --
      pkb_ler_proc_adm_efd_reinf ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      commit;
      --
   end loop;
   --
exception
   when others then
      --
      vv_teste := sqlerrm;
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_integracao fase('||vn_fase||') CNPJ/CPF('||vv_cpf_cnpj||'):'||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_empresa_id         => en_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_integracao;

-------------------------------------------------------------------------------------------------------------------------------

--| Procedimento que inicia a integração de cadastros Normal, com todas as empresas

procedure pkb_integracao_normal ( en_multorg_id in mult_org.id%type
                                , ed_dt_ini     in  date
                                , ed_dt_fin     in  date
                                )
is
   --
   vn_fase number := 0;
   --
   vv_cpf_cnpj           varchar2(14);
   --
   cursor c_empr is
   select e.id empresa_id
        , rownum   nro_linha --#68800
     from empresa e
    where e.multorg_id = en_multorg_id
      and e.dm_tipo_integr in (3, 4) -- Integração por view
      and e.dm_situacao    = 1 -- Ativa
    order by 1;
   --
begin
   -- Inicia os contadores de registros a serem integrados
   pk_agend_integr.pkb_inicia_cont(ev_cd_obj => gv_cd_obj);
   --
   vn_fase := 1;
   --
   for rec in c_empr loop
      exit when c_empr%notfound or (c_empr%notfound) is null;
      --
      vn_fase := 2;
      --
      vv_cpf_cnpj := pk_csf.fkg_cnpj_ou_cpf_empresa ( en_empresa_id => rec.empresa_id );
      --
      vn_fase := 3;
      --
      pkb_integracao ( en_empresa_id => rec.empresa_id
                     , ed_dt_ini   => ed_dt_ini
                     , ed_dt_fin   => ed_dt_fin
                     , en_nro_linha  => rec.nro_linha --#68800
                     );
      --
   end loop;
   --
exception
   when others then
      --
      gv_mensagem_log := 'Erro na pk_int_view_cad.pkb_integracao_normal fase('||vn_fase||'): '||sqlerrm;
      --
      declare
         vn_loggenericocad_id  log_generico_cad.id%TYPE;
      begin
         --
         pk_csf_api_cad.pkb_log_generico_cad ( sn_loggenericocad_id  => vn_loggenericocad_id
                                             , ev_mensagem           => gv_mensagem_log
                                             , ev_resumo             => gv_mensagem_log
                                             , en_tipo_log           => ERRO_DE_SISTEMA
                                             , en_empresa_id         => gn_empresa_id
                                             );
         --
      exception
         when others then
            null;
      end;
      --
      raise_application_error (-20101, gv_mensagem_log);
      --
end pkb_integracao_normal;

-------------------------------------------------------------------------------------------------------

-- Processo de integração informando todas as empresas matrizes
procedure pkb_integr_cad_geral ( en_multorg_id in mult_org.id%type
                               , ed_dt_ini     in  date
                               , ed_dt_fin     in  date )
is
   --
   vn_fase      number := 0;
   vv_cpf_cnpj  varchar2(14);
   --
   cursor c_emp is
   select e.id empresa_id
        , e.dt_ini_integr
        , e.multorg_id
        , eib.owner_obj
        , eib.nome_dblink
        , eib.dm_util_aspa
        , eib.dm_ret_infor_integr
        , eib.formato_dt_erp
        , eib.dm_form_dt_erp
     from empresa e
        , empresa_integr_banco eib
    where e.dm_situacao     = 1 -- Ativo
      and e.multorg_id      = en_multorg_id
      and e.dm_tipo_integr  in (3, 4) -- Integração por view
      and eib.empresa_id    = e.id
    order by 1;

   cursor c_multorg is
   select distinct e.multorg_id
        , e.dt_ini_integr
        , e.id empresa_id
        , eib.owner_obj
        , eib.nome_dblink
        , eib.dm_util_aspa
        , eib.dm_ret_infor_integr
        , eib.formato_dt_erp
        , eib.dm_form_dt_erp
		, rownum   nro_linha --#75771
     from empresa e
        , empresa_integr_banco eib
       where e.dm_situacao     = 1 -- Ativo
      and e.multorg_id      = en_multorg_id
      and e.dm_tipo_integr  in (3, 4) -- Integração por view
      and eib.empresa_id    = e.id
    order by 1;
   --
begin
   -- Inicia os contadores de registros a serem integrados
   pk_agend_integr.pkb_inicia_cont(ev_cd_obj => gv_cd_obj);
   --
   gv_formato_data := pk_csf.fkg_param_global_csf_form_data;
   --
   vn_fase := 1;
   -- Se ta o DBLink
   GV_NOME_DBLINK    := null;
   GV_OWNER_OBJ      := null;
   GV_ASPAS          := null;
   gv_formato_dt_erp := gv_formato_data;
   gv_sistema_em_nuvem := pk_csf.fkg_vlr_param_global_csf ( ev_paramglobalcsf_cd => 'SISTEMA_EM_NUVEM' );
   --
  -- gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
   --
   vn_fase := 1.1;
   --
   for rec_multorg in c_multorg loop
      exit when c_multorg%notfound or (c_multorg%notfound) is null;
      --
      vn_fase := 1.2;
      --
      -- Se ta o DBLink
      GV_NOME_DBLINK := rec_multorg.nome_dblink;
      GV_OWNER_OBJ   := rec_multorg.owner_obj;
      --
      -- Verifica se utiliza GV_ASPAS dupla
      if rec_multorg.dm_util_aspa = 1 then
         --
         GV_ASPAS := '"';
         --
      else
         --
         GV_ASPAS := null;
         --
      end if;
      --  Seta formata da data para os procedimentos de retorno
      if trim(rec_multorg.formato_dt_erp) is not null then
         gv_formato_dt_erp := rec_multorg.formato_dt_erp;
      else
         gv_formato_dt_erp := gv_formato_data;
      end if;
      --
      vn_fase := 1.3;
      --
      gn_multorg_id := rec_multorg.multorg_id;
      --
      gv_multorg_cd := pk_csf.fkg_multorg_cd ( en_multorg_id => gn_multorg_id );
      --
      begin
         --
         select min(id)
           into gn_empresa_id
           from empresa
          where multorg_id = en_multorg_id
            and dm_situacao = 1;
         --
      exception
         when others then
            gn_empresa_id := null;
      end;
      --
      vn_fase := 1.4;
      --
      vv_cpf_cnpj := pk_csf.fkg_cnpj_ou_cpf_empresa ( en_empresa_id => gn_empresa_id );
      --
      vn_fase := 1.5;
      -- Será executada apenas nesse primeiro cursor, pois já recupera todas as empresas e monta todos os processos de integração de cadastro
      pkb_stafe ( ev_cpf_cnpj => vv_cpf_cnpj
                , ed_dt_ini   => ed_dt_ini
                , ed_dt_fin   => ed_dt_fin
                );
      --    
      vn_fase := 2;
	  --
      --#75771 
      if rec_multorg.nro_linha = 1 then 
          --
          vn_fase := 2;
          --
          pkb_pessoa;
          --
          vn_fase := 3;
          --
          pkb_unidade;
          --
          vn_fase := 4;
          --
          pkb_nat_oper;
          --
          vn_fase := 5;
          --
          pkb_obs_lancto_fiscal;
          --
          vn_fase := 6;
          --
          pkb_inf_comp_dcto_fis;
          --
          vn_fase := 6.1;
          --
          commit;
          --
      end if;
      --
      pkb_grupo_pat ( ev_cpf_cnpj => null );
      --
      commit;
      --
   end loop;
   --
   vn_fase := 7;
   --
   --gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
   --
   vn_fase := 8;
   --
   for rec in c_emp loop
      exit when c_emp%notfound or (c_emp%notfound) is null;
      --
      gn_empresa_id := rec.empresa_id;
      --
      vn_fase := 8.1;
      -- Se ta o DBLink
      GV_NOME_DBLINK := rec.nome_dblink;
      GV_OWNER_OBJ   := rec.owner_obj;
      --
      vn_fase := 8.2;
      -- Verifica se utiliza GV_ASPAS dupla
      if rec.dm_util_aspa = 1 then
         --
         GV_ASPAS := '"';
         --
      else
         --
         GV_ASPAS := null;
         --
      end if;
      --  Seta formata da data para os procedimentos de retorno
      if trim(rec.formato_dt_erp) is not null then
         gv_formato_dt_erp := rec.formato_dt_erp;
      else
         gv_formato_dt_erp := gv_formato_data;
      end if;
      --
      vn_fase := 9;
      --
      vv_cpf_cnpj := pk_csf.fkg_cnpj_ou_cpf_empresa ( en_empresa_id => rec.empresa_id );
      --
      gn_multorg_id := rec.multorg_id;
      --
      gv_multorg_cd := pk_csf.fkg_multorg_cd ( en_multorg_id => gn_multorg_id );
      --
      vn_fase := 10;
      -- Será executada apenas no primeiro cursor, pois já recupera todas as empresas e monta todos os processos de integração de cadastro
      --pkb_stafe ( ev_cpf_cnpj => vv_cpf_cnpj
      --          , ed_dt_ini   => ed_dt_ini
      --          , ed_dt_fin   => ed_dt_fin
      --          );
      --
      vn_fase := 10.1;
      --
      pkb_item ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 11;
      --
      pkb_bem_ativo_imob ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 12;
      --
      pkb_plano_conta ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 13;
      --
      pkb_centro_custo ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 14;
      --
      pkb_hist_padrao ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 15;
      --
      pkb_item_param_icmsst ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 16;
      --
      pkb_ctrl_ver_contab ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 17;
      --
      pkb_legado_fci ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 18;
      --
      pkb_aglut_contabil ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 19;
      --
      pkb_ler_item_fornc_eu ( ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 20;
      --
      pkb_ler_oper_fiscal_ent ( ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 21;
      --
      pkb_ler_param_dipamgia ( ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 22;
      --
      pkb_ler_proc_adm_efd_reinf ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      commit;
      --
   end loop;
   --
   vn_fase := 20;
   --
   commit;
   --
exception
   when others then
      raise_application_error (-20101, 'Erro na pk_int_view_cad.pkb_integr_cad_geral fase('||vn_fase||'): '||sqlerrm);
end pkb_integr_cad_geral;

-------------------------------------------------------------------------------------------------------

-- Processo de integração informando todas as empresas matrizes
procedure pkb_integr_empresa_geral ( en_paramintegrdados_id  in  param_integr_dados.id%type 
                                   , en_empresa_id          in empresa.id%type
                                   )
is
   --
   vn_fase      number := 0;
   vv_cpf_cnpj  varchar2(14);
   --
   cursor c_emp is
   select p.*, e.multorg_id
     from param_integr_dados_empresa p
        , empresa e
    where p.paramintegrdados_id = en_paramintegrdados_id
      and p.empresa_id          = nvl(en_empresa_id, p.empresa_id)
      and e.id                  = p.empresa_id
      and e.dm_situacao         = 1 -- Ativo
    order by 1;
    --
   cursor c_multorg is
   select distinct e.multorg_id
        , rownum   nro_linha --#75771
     from param_integr_dados_empresa p
        , empresa e
    where p.paramintegrdados_id = en_paramintegrdados_id
      and e.id                  = p.empresa_id
      and e.dm_situacao         = 1 -- Ativo
    order by 1;
   --
begin
   --
   gv_formato_data := pk_csf.fkg_param_global_csf_form_data;
   --
   vn_fase := 1;
   -- Se ta o DBLink
   GV_NOME_DBLINK    := null;
   GV_OWNER_OBJ      := null;
   GV_ASPAS          := null;
   gv_formato_dt_erp := gv_formato_data;
   --
   gv_sistema_em_nuvem := pk_csf.fkg_vlr_param_global_csf ( ev_paramglobalcsf_cd => 'SISTEMA_EM_NUVEM' );
  -- gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
   --
   for rec_multorg in c_multorg loop
      exit when c_multorg%notfound or (c_multorg%notfound) is null;
      --
      vn_fase := 2;
      --
      gn_multorg_id := rec_multorg.multorg_id;
      --
      gv_multorg_cd := pk_csf.fkg_multorg_cd ( en_multorg_id => gn_multorg_id );
      --
      --#75771 
      if rec_multorg.nro_linha = 1 then 
        --
        pkb_pessoa;
        --
        vn_fase := 3;
        --
        pkb_unidade;
        --
        vn_fase := 4;
        --
        pkb_nat_oper;
        --
        vn_fase := 5;
        --
        pkb_obs_lancto_fiscal;
        --
        vn_fase := 6;
        --
        pkb_inf_comp_dcto_fis;
        --
        commit;
        --
      end if;
      --
      vn_fase := 7;
      --
      pkb_grupo_pat ( ev_cpf_cnpj => null );
      --
      commit;
      --
   end loop;
   --
   vn_fase := 8;
   --
   --gn_multorg_id := pk_csf.fkg_multorg_id ( ev_multorg_cd => '1' );
   --
   for rec in c_emp loop
      exit when c_emp%notfound or (c_emp%notfound) is null;
      --
      vn_fase := 9;
      --
      vv_cpf_cnpj := pk_csf.fkg_cnpj_ou_cpf_empresa ( en_empresa_id => rec.empresa_id );
      --
      gn_multorg_id := rec.multorg_id;
      --
      gv_multorg_cd := pk_csf.fkg_multorg_cd ( en_multorg_id => gn_multorg_id );
      --
      vn_fase := 9.1;
      --
      gn_empresa_id := rec.empresa_id;
      --
      vn_fase := 10;
      --
      pkb_item ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 11;
      --
      pkb_bem_ativo_imob ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 12;
      --
      pkb_plano_conta ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 13;
      --
      pkb_centro_custo ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 14;
      --
      pkb_hist_padrao ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 15;
      --
      pkb_item_param_icmsst ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 16;
      --
      pkb_ctrl_ver_contab ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 17;
      --
      pkb_legado_fci ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 18;
      --
      pkb_aglut_contabil ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      vn_fase := 19;
      --
      pkb_ler_item_fornc_eu ( ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 20;
      --
      pkb_ler_oper_fiscal_ent ( ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 21;
      --
      pkb_ler_param_dipamgia ( ev_cpf_cnpj => vv_cpf_cnpj);
      --
      vn_fase := 22;
      --
      pkb_ler_proc_adm_efd_reinf ( ev_cpf_cnpj => vv_cpf_cnpj );
      --
      commit;
      --
   end loop;
   --
   vn_fase := 20;
   --
   commit;
   --
exception
   when others then
      raise_application_error (-20101, 'Erro na pk_int_view_cad.pkb_integr_empresa_geral fase('||vn_fase||'): '||sqlerrm);
end pkb_integr_empresa_geral;

-------------------------------------------------------------------------------------------------------

end pk_int_view_cad;
/
