create or replace package body csf_own.pk_csf_api_ddo is

-------------------------------------------------------------------------------
-- Procedimento para gravar o log/alteração das Deduções Diversas - Bloco F700
-------------------------------------------------------------------------------
procedure pkb_inclui_log_deddiversapc( en_deducaodiversapc_id in deducao_diversa_pc.id%type
                                     , ev_resumo              in log_deducao_diversa_pc.resumo%type
                                     , ev_mensagem            in log_deducao_diversa_pc.mensagem%type
                                     , en_usuario_id          in neo_usuario.id%type
                                     , ev_maquina             in varchar2 ) is
   --
begin
   --
   insert into log_deducao_diversa_pc( id
                                     , deducaodiversapc_id
                                     , dt_hr_log
                                     , resumo
                                     , mensagem
                                     , usuario_id
                                     , maquina )
                               values( logdeducaodiversapc_seq.nextval
                                     , en_deducaodiversapc_id
                                     , sysdate
                                     , ev_resumo
                                     , ev_mensagem
                                     , en_usuario_id
                                     , ev_maquina );
   --
   commit;
   --
exception
   when others then
      raise_application_error (-20101, 'Problemas ao incluir log/alteração - pkb_inclui_log_deddiversapc (en_deducaodiversapc_id = '||en_deducaodiversapc_id||
                                       '). Erro = '||sqlerrm);
end pkb_inclui_log_deddiversapc;

--------------------------------------------------------------------------------------------------------------------------------
-- Procedimento para gravar o log/alteração dos Demais Documentos e Operações Geradoras de Contribuição e Créditos - Bloco F100
--------------------------------------------------------------------------------------------------------------------------------
procedure pkb_inclui_log_demdocopergercc( en_demdocopergercc_id in dem_doc_oper_ger_cc.id%type
                                        , ev_resumo             in log_dem_doc_oper_ger_cc.resumo%type
                                        , ev_mensagem           in log_dem_doc_oper_ger_cc.mensagem%type
                                        , en_usuario_id         in neo_usuario.id%type
                                        , ev_maquina            in varchar2 ) is
   --
begin
   --
   insert into log_dem_doc_oper_ger_cc( id
                                      , demdocopergercc_id
                                      , dt_hr_log
                                      , resumo
                                      , mensagem
                                      , usuario_id
                                      , maquina )
                                values( logdemdocopergercc_seq.nextval
                                      , en_demdocopergercc_id
                                      , sysdate
                                      , ev_resumo
                                      , ev_mensagem
                                      , en_usuario_id
                                      , ev_maquina );
   --
   commit;
   --
exception
   when others then
      raise_application_error (-20101, 'Problemas ao incluir log/alteração - pkb_inclui_log_demdocopergercc (en_demdocopergercc_id = '||en_demdocopergercc_id||
                                       '). Erro = '||sqlerrm);
end pkb_inclui_log_demdocopergercc;

-----------------------------------------
--| Procedimento finaliza o Log Genérico
-----------------------------------------
procedure pkb_finaliza_log_generico_ddo is
begin
   --
   gn_processo_id := null;
   --
exception
   when others then
      --
      gv_resumo := 'Erro na pk_csf_api_ddo.pkb_finaliza_log_generico_ddo: '||sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico.id%TYPE;
      begin
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => 'Finalizar processo de Log Genérico - DDO - Blocos F'
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_sistema
                              , en_empresa_id        => gn_empresa_id );
         --
      exception
         when others then
            null;
      end;
      --
end pkb_finaliza_log_generico_ddo;
------------------------------------------------------
--| Procedimento armazena o valor do "loggenerico_id"
------------------------------------------------------
procedure pkb_gt_log_generico_ddo ( en_loggenericoddo_id  in             log_generico_ddo.id%type
                                  , est_log_generico_ddo  in out nocopy  dbms_sql.number_table
                                  ) is
   --
   i pls_integer;
   --
begin
   --
   if nvl(en_loggenericoddo_id,0) > 0 then
      --
      i := nvl(est_log_generico_ddo.count,0) + 1;
      --
      est_log_generico_ddo(i) := en_loggenericoddo_id;
      --
   end if;
   --
exception
   when others then
      --
      gv_resumo := 'Erro na pk_csf_api_ddo.pkb_gt_log_generico_ddo: '||sqlerrm;
      --
      declare
         vn_loggenerico_id  Log_Generico_ddo.id%TYPE;
      begin
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => 'Registrar logs genéricos com erro de validação - DDO - Blocos F'
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_sistema
                              , en_empresa_id        => gn_empresa_id );
         --
      exception
         when others then
            null;
      end;
      --
end pkb_gt_log_generico_ddo;
--
-------------------------------------------------------------------------------------------------------
-- Corpo do pacote de integração de Bloco F DDO(Demais Documentos e Operações).
-------------------------------------------------------------------------------------------------------
procedure pkb_log_generico_ddo( sn_loggenericoddo_id   out nocopy    log_generico_ddo.id%type
                              , ev_mensagem            in            log_generico_ddo.mensagem%type
                              , ev_resumo              in            log_generico_ddo.resumo%type
                              , en_tipo_log            in            csf_tipo_log.cd_compat%type      default 1
                              , en_referencia_id       in            Log_Generico_ddo.referencia_id%TYPE  default null
                              , ev_obj_referencia      in            Log_Generico_ddo.obj_referencia%TYPE default null
                              , en_empresa_id          in            Empresa.Id%type                  default null
                              , en_dm_impressa         in            Log_Generico_ddo.dm_impressa%type    default 0 )is
   --
   vn_fase           number := 0;
   vn_loggenerico_id log_generico_ddo.id%type;
   vn_csftipolog_id  csf_tipo_log.id%type;
   --
begin
   --
   vn_fase := 1;
   --
   if nvl(gn_processo_id,0) = 0 then
      select processo_seq.nextval
        into gn_processo_id
        from dual;
   end if;
   --
   if nvl(en_tipo_log,0) > 0 and ev_mensagem is not null then
      --
      vn_fase := 2;
      --
      vn_csftipolog_id := pk_csf.fkg_csf_tipo_log_id ( en_tipo_log => en_tipo_log );
      --
      vn_fase := 3;
      --
      select loggenericoddo_seq.nextval
        into vn_loggenerico_id
        from dual;
      --
      sn_loggenericoddo_id := vn_loggenerico_id;
      --
      vn_fase := 4;
      --
      insert into log_generico_ddo ( id
                                   , processo_id
                                   , dt_hr_log
                                   , referencia_id
                                   , obj_referencia
                                   , resumo
                                   , dm_impressa
                                   , dm_env_email
                                   , csftipolog_id
                                   , empresa_id
                                   , mensagem )
                            values ( vn_loggenerico_id
                                   , gn_processo_id
                                   , sysdate
                                   , en_referencia_id
                                   , ev_obj_referencia
                                   , ev_resumo
                                   , nvl(en_dm_impressa,0)
                                   , 0
                                   , vn_csftipolog_id
                                   , nvl(en_empresa_id, gn_empresa_id)
                                   , ev_mensagem
                                   );
      --
      vn_fase := 5;
      --
      commit;
      --
   end if;
   --
exception
   when others then
   --
   gv_resumo := 'Erro na pkb_log_generico_ddo fase ('||vn_fase||'):'||sqlerrm;
   --
   declare
      vn_loggnerico_id   log_generico_ddo.id%type;
   begin
      --
      pkb_log_generico_ddo( sn_loggenericoddo_id => vn_loggenerico_id
                          , ev_mensagem          => 'Registrar logs genéricos - DDO - Blocos F'
                          , ev_resumo            => gv_resumo
                          , en_tipo_log          => erro_de_sistema
                          , en_empresa_id        => gn_empresa_id );
   exception
      when others then
        null;
   end;
   --
end pkb_log_generico_ddo;
--
----------------------------------------------------------------------------------
-- Procedimento que limpa a tabela log_generico_ddo
----------------------------------------------------------------------------------
procedure pkb_limpar_loggenericoddo( en_empresa_id     in      Empresa.Id%type ) is
   --
begin
   --
   delete from log_generico_ddo l
    where nvl(l.empresa_id,0) = nvl(en_empresa_id,0)
	  and l.empresa_id is not null;
   --
   commit;
   --
exception
   when others then
      --
      gv_resumo := 'Erro na pkb_limpar_loggenericoddo:'||sqlerrm;
      --
      declare
         vn_loggenerico_id   log_generico_ddo.id%type;
      begin
      --
      pkb_log_generico_ddo( sn_loggenericoddo_id => vn_loggenerico_id
                          , ev_mensagem          => 'Limpar tabela de logs genéricos - DDO - Blocos F'
                          , ev_resumo            => gv_resumo
                          , en_tipo_log          => erro_de_sistema
                          , en_empresa_id        => gn_empresa_id );
      exception
         when others then
           null;
      end;
end pkb_limpar_loggenericoddo;
--
----------------------------------------------------------------------------------
--| Procedimento seta o objeto de referencia utilizado na Validação da Informação
----------------------------------------------------------------------------------
procedure pkb_seta_obj_ref ( ev_objeto in varchar2
                           ) is
begin
   --
   gv_obj_referencia := upper(ev_objeto);
   --
end pkb_seta_obj_ref;
----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------
--| Procedimento seta o tipo de integração que será feito
--| 0 - Somente válida os dados e registra o Log de ocorrência
--| 1 - Válida os dados e registra o Log de ocorrência e insere a informação
--| Todos os procedimentos de integração fazem referência a ele
-----------------------------------------------------------------------------
procedure pkb_seta_tipo_integr ( en_tipo_integr in number
                               ) is
begin
   --
   gn_tipo_integr := en_tipo_integr;
   --
end pkb_seta_tipo_integr;
--
--------------------------------------------
-- Procedimento de integração do Bloco F800
--------------------------------------------
procedure pkb_integr_creddecoreventopc ( est_log_generico_ddo      in out nocopy dbms_sql.number_table
                                       , est_row_creddecoreventopc in out nocopy cred_decor_evento_pc%rowtype
                                       , en_multorg_id             in            mult_org.id%TYPE
                                       , ev_cnpj_empr              in            varchar2
                                       , ev_tipocredpc_cd          in            varchar2
                                       ) is
   --
   vn_fase                 number := null;
   vn_loggenerico_id       log_generico_ddo.id%type;
   vn_doct_valido          number(1);
   vn_id                   cred_decor_evento_pc.id%type := null;
   vn_creddecoreventopc_id cred_decor_evento_pc.id%type := null;
   vn_dm_st_proc           cred_decor_evento_pc.dm_st_proc%type := null;
   --
begin
   --
   vn_fase := 1;
   --
   est_row_creddecoreventopc.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id => en_multorg_id
                                                                               , ev_cpf_cnpj   => ev_cnpj_empr
                                                                               );
   --
   vn_fase := 1.1;
   --| Montar o cabeçalho do log
   gv_mensagem := null;
   gv_mensagem := 'BLOCO F800 - Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa ( en_empresa_id => est_row_creddecoreventopc.empresa_id );
   gv_mensagem := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'CRED_DECOR_EVENTO_PC'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_creddecoreventopc
   if nvl(est_row_creddecoreventopc.tipocredpc_id,0) = 0 then
      est_row_creddecoreventopc.tipocredpc_id :=  pk_csf_ddo.fkb_cd_tipocredpc_id( ev_tipocredpc_cd => ev_tipocredpc_cd);
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_creddecoreventopc ( en_empresa_id          => est_row_creddecoreventopc.empresa_id
                                       , ev_dm_ind_nat_even     => est_row_creddecoreventopc.dm_ind_nat_even
                                       , ed_dt_evento           => est_row_creddecoreventopc.dt_evento
                                       , en_tipocredpc_id       => est_row_creddecoreventopc.tipocredpc_id
                                       , ev_cnpj_suced          => est_row_creddecoreventopc.cnpj_suced
                                       , en_pa_cont_cred        => est_row_creddecoreventopc.pa_cont_cred
                                       , sn_creddecoreventop_id => vn_creddecoreventopc_id
                                       , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_creddecoreventopc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.2;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_creddecoreventopc.id,0) <= 0 and nvl(vn_creddecoreventopc_id,0) <= 0 then
      -- cred_decor_evento_pc
      select creddecoreventopc_seq.nextval
        into est_row_creddecoreventopc.id
        from dual;
      --
      vn_id := est_row_creddecoreventopc.id;
      --
   elsif nvl(est_row_creddecoreventopc.id,0) <= 0 and nvl(vn_creddecoreventopc_id,0) > 0 then
      --
      est_row_creddecoreventopc.id := vn_creddecoreventopc_id;
      --
   elsif nvl(est_row_creddecoreventopc.id,0) > 0 and nvl(est_row_creddecoreventopc.id,0) <> nvl(vn_creddecoreventopc_id,0) then
       --
       vn_fase := 1.3;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_creddecoreventopc.id||') está diferente do id encontrado ('||vn_creddecoreventopc_id||') para o registro na tabela CRED_DECOR_EVENTO_PC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_creddecoreventopc.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   gn_referencia_id := est_row_creddecoreventopc.id;
   --
   vn_fase := 1.4;
   --
   if nvl(est_row_creddecoreventopc.empresa_id,0) = 0 then
      --
      vn_fase := 1.5;
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da empresa não encontrado na base Compliance:" ('||trim(ev_cnpj_empr)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.6;
   --
   if nvl(est_row_creddecoreventopc.tipocredpc_id,0) = 0 and trim(ev_tipocredpc_cd) is not null then
      --
      vn_fase := 1.7;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código do Tipo de Credito de Pis/Cofins inválido:" ('||trim(ev_tipocredpc_cd)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_creddecoreventopc.tipocredpc_id,0) = 0 then
      --
      vn_fase := 1.9;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Código do Tipo de Credito de Pis/Cofins nao informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.10;
   --
   if nvl(est_row_creddecoreventopc.dm_ind_nat_even,0) not in ('01','02','03','04','99') then
      --
      vn_fase := 1.11;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Dominio Indicador da Natureza do Evento de Sucesso" informado incorretamente. ('||est_row_creddecoreventopc.dm_ind_nat_even||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2;
   --
   if trim(est_row_creddecoreventopc.dt_evento) is null then
      --
      vn_fase := 2.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Data do Evento" informado incorretamente.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.2;
   --
   if trim(est_row_creddecoreventopc.cnpj_suced) is not null then
      --
      vn_fase := 2.3;
      --
      vn_doct_valido := null;
      --
      vn_doct_valido := pk_valida_docto.fkg_valida_cpf_cgc(ev_numero => est_row_creddecoreventopc.cnpj_suced );
      --
      if nvl(vn_doct_valido,0) = 0 then
         --
         vn_fase := 2.4;
         --
         gv_resumo := '"CNPJ da Pessoa Juridica Sucedida" Inválido, Favor inserir Identificador(CPF/CNPJ) valido."';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      end if;
      --
   else
      --
      vn_fase := 2.5;
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da Pessoa Juridica Sucedida" não foi informado (Campo obrigatório).';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.6;
   --
   if nvl(est_row_creddecoreventopc.pa_cont_cred,0) = 0 then
      --
      vn_fase := 2.7;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Periodo de Apuracão do Credito" não foi informado(Campo obrigatório).';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.8;
   --
   if nvl(est_row_creddecoreventopc.vl_cred_pis,-1) < 0 then
      --
      vn_fase := 2.9;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Valor do Credito Transferido de PIS/Pasep" não pode ser negativo ou nulo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3;
   --
   if nvl(est_row_creddecoreventopc.vl_cred_cofins,-1) < 0 then
      --
      vn_fase := 3.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Valor do Credito Transferido de COFINS" não pode ser negativo ou nulo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.2;
   --
   if nvl(est_row_creddecoreventopc.per_cred_cisao,0) < 0 then
      --
      vn_fase := 3.3;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Percentual do credito original transferido" não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.4;
   --
   if nvl( est_row_creddecoreventopc.id,0 )             > 0 and
      nvl(vn_id,0)                                      > 0 and
      nvl(est_row_creddecoreventopc.empresa_id,0)      <> 0 and
      nvl(est_row_creddecoreventopc.dm_ind_nat_even,0) in ('01','02','03','04','99') and
      est_row_creddecoreventopc.dt_evento              is not null and
      nvl(est_row_creddecoreventopc.tipocredpc_id,0)   <> 0 then
      --
      vn_fase := 3.5;
      --
      begin
         pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
      exception
         when others then
            null;
      end;
      --
      vn_fase := 3.6;
      --
      insert into cred_decor_evento_pc ( id
                                          , empresa_id
                                          , dm_ind_nat_even
                                          , dt_evento
                                          , cnpj_suced
                                          , pa_cont_cred
                                          , tipocredpc_id
                                          , vl_cred_pis
                                          , vl_cred_cofins
                                          , per_cred_cisao
                                          , dm_st_proc
                                          , dm_st_integra )
                                    values( est_row_creddecoreventopc.id
                                          , est_row_creddecoreventopc.empresa_id
                                          , est_row_creddecoreventopc.dm_ind_nat_even
                                          , est_row_creddecoreventopc.dt_evento
                                          , est_row_creddecoreventopc.cnpj_suced
                                          , est_row_creddecoreventopc.pa_cont_cred
                                          , est_row_creddecoreventopc.tipocredpc_id
                                          , est_row_creddecoreventopc.vl_cred_pis
                                          , est_row_creddecoreventopc.vl_cred_cofins
                                          , est_row_creddecoreventopc.per_cred_cisao
                                          , est_row_creddecoreventopc.dm_st_proc
                                          , est_row_creddecoreventopc.dm_st_integra );
      --
      commit;
      --
   else
      --
      vn_fase := 3.8;
      --
      update cred_decor_evento_pc pc
         set pc.pa_cont_cred    = est_row_creddecoreventopc.pa_cont_cred
           , pc.vl_cred_pis     = est_row_creddecoreventopc.vl_cred_pis
           , pc.vl_cred_cofins  = est_row_creddecoreventopc.vl_cred_cofins
           , pc.per_cred_cisao  = est_row_creddecoreventopc.per_cred_cisao
           , pc.dm_st_integra   = est_row_creddecoreventopc.dm_st_integra
       where pc.id              = est_row_creddecoreventopc.id
         and pc.dm_st_proc      not in (1); -- validada;
      --
      commit;
      --
   end if;
   --
exception
   when others then
      --
      gv_resumo := 'Erro na pkb_integr_creddecoreventopc fase ('||vn_fase||'): '||sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ddo.id%TYPE;
      begin
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_sistema
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      exception
         when others then
            null;
      end;
      --
end pkb_integr_creddecoreventopc;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela DEDUCAO_DIVERSA_PC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_deducaodiversapc ( est_log_generico_ddo         in out nocopy dbms_sql.number_table
                                      , est_row_deducaodiversaspc    in out nocopy deducao_diversa_pc%rowtype
                                      , ev_cnpj_empr                 in varchar2
                                      , en_multorg_id                in mult_org.id%type
                                      ) is
   --
   vn_docto_valido         number                     := 1; -- default 1 - valido pois a coluna é opcional;
   vn_fase                 number                     := null;
   vn_loggenerico_id       log_generico_ddo.id%Type;
   vn_id                   deducao_diversa_pc.id%type := null;
   vn_deducaodiversaspc_id deducao_diversa_pc.id%type := null;
   vn_dm_st_proc           deducao_diversa_pc.dm_st_proc%type := null;
   --
begin
   --
   vn_fase := 1;
   --
   est_row_deducaodiversaspc.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id  =>  en_multorg_id
                                                                               , ev_cpf_cnpj    =>  ev_cnpj_empr
                                                                               );
   --
   vn_fase := 1.1;
   --
   --| Montar o cabeçalho do log
   gv_mensagem       := null;
   gv_mensagem       := 'Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa( en_empresa_id => est_row_deducaodiversaspc.empresa_id );
   gv_mensagem       := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'DEDUCAO_DIVERSA_PC'; end if;
   --
   vn_fase := 1.2;
   --
   -- Se a data fechamento não foi carregada busca a data para validação
   if pk_int_view_ddo.gd_dt_ult_fecha is null then
      --
      pk_int_view_ddo.gd_dt_ult_fecha := pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id   => est_row_deducaodiversaspc.empresa_id
                                                                             , en_objintegr_id => pk_csf.fkg_recup_objintegr_id( ev_cd => '50' )); -- Demais Documentos e Operações - Bloco F EFD Contribuições
      --
   end if ;
   --
   vn_fase := 1.3;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_deducaodiversaspc ( en_empresa_id          => est_row_deducaodiversaspc.empresa_id
                                       , en_ano_ref             => est_row_deducaodiversaspc.ano_ref
                                       , en_mes_ref             => est_row_deducaodiversaspc.mes_ref
                                       , ev_dm_ind_ori_ded      => est_row_deducaodiversaspc.dm_ind_ori_ded
                                       , en_dm_ind_nat_ded      => est_row_deducaodiversaspc.dm_ind_nat_ded
                                       , ev_cnpj                => est_row_deducaodiversaspc.cnpj
                                       , sn_deducaodiversapc_id => vn_deducaodiversaspc_id
                                       , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_deducaodiversaspc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_deducaodiversaspc.id,0) <= 0 and nvl(vn_deducaodiversaspc_id,0) <= 0 then
      -- deducao_diversa_pc
      select deducaodiversapc_seq.nextval
        into est_row_deducaodiversaspc.id
        from dual;
      --
      vn_id := est_row_deducaodiversaspc.id;
      --
   elsif nvl(est_row_deducaodiversaspc.id,0) <= 0 and nvl(vn_deducaodiversaspc_id,0) > 0 then
      --
      est_row_deducaodiversaspc.id := vn_deducaodiversaspc_id;
      --
   elsif nvl(est_row_deducaodiversaspc.id,0) > 0 and nvl(est_row_deducaodiversaspc.id,0) <> nvl(vn_deducaodiversaspc_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_deducaodiversaspc.id||') está diferente do id encontrado '||vn_deducaodiversaspc_id||' para o registro na tabela DEDUCAO_DIVERSA_PC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_deducaodiversaspc.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   gn_referencia_id := est_row_deducaodiversaspc.id;
   --
   vn_fase := 1.51;
   --
   -- Se o registro já estiver VALIDADO nem entra na rotina de validação e gera log de INFORMAÇÃO
   if nvl(est_row_deducaodiversaspc.id,0) > 0 and nvl(vn_dm_st_proc,0) in (0,2) then
      --
      --| Validar Registros
      if trim(ev_cnpj_empr) is null then
         --
         vn_fase := 1.6;
         --
         gv_resumo := null;
         --
         gv_resumo := '"CNPJ da empresa não encontrado na base Compliance:" ('||trim(ev_cnpj_empr)||').';
         --
         vn_loggenerico_id := null;
          --
          pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                               , ev_mensagem          => gv_mensagem
                               , ev_resumo            => gv_resumo
                               , en_tipo_log          => erro_de_validacao
                               , en_referencia_id     => gn_referencia_id
                               , ev_obj_referencia    => gv_obj_referencia
                               , en_empresa_id        => gn_empresa_id
                               );
          --
          -- Armazena o "loggenerico_id" na memória
          pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                  , est_log_generico_ddo => est_log_generico_ddo );
          --
       end if;
       --
       vn_fase := 1.7;
       --
       if trim(est_row_deducaodiversaspc.dm_ind_ori_ded) not in ('01','02','03','04','99') then
          --
          vn_fase := 1.8;
          --
          gv_resumo := null;
          --
          gv_resumo := '"Indicador de Origem de Deduções Diversas" informado incorretamente: ('||trim(est_row_deducaodiversaspc.dm_ind_ori_ded)||').';
          --
          vn_loggenerico_id := null;
          --
          pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                               , ev_mensagem          => gv_mensagem
                               , ev_resumo            => gv_resumo
                               , en_tipo_log          => erro_de_validacao
                               , en_referencia_id     => gn_referencia_id
                               , ev_obj_referencia    => gv_obj_referencia
                               , en_empresa_id        => gn_empresa_id
                               );
          --
          -- Armazena o "loggenerico_id" na memória
          pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                  , est_log_generico_ddo => est_log_generico_ddo );
          --
       end if;
       --
       vn_fase := 1.9;
       --
       if nvl(est_row_deducaodiversaspc.dm_ind_nat_ded,-1) not in (0,1) then
          --
          vn_fase := 1.10;
          --
          gv_resumo := null;
          --
          gv_resumo := '"Indicador da Natureza da Dedução" informado incorretamente: ('||trim(est_row_deducaodiversaspc.dm_ind_nat_ded)||').';
          --
          vn_loggenerico_id := null;
          --
          pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                               , ev_mensagem          => gv_mensagem
                               , ev_resumo            => gv_resumo
                               , en_tipo_log          => erro_de_validacao
                               , en_referencia_id     => gn_referencia_id
                               , ev_obj_referencia    => gv_obj_referencia
                               , en_empresa_id        => gn_empresa_id
                               );
          --
          -- Armazena o "loggenerico_id" na memória
          pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                  , est_log_generico_ddo => est_log_generico_ddo );
          --
       end if;
       --
       vn_fase := 1.11;
       --
       if nvl(est_row_deducaodiversaspc.vl_ded_pis,0) <= 0 then
          --
          vn_fase := 1.12;
          --
          gv_resumo := null;
          --
          gv_resumo := '"Valor a Deduzir - PIS/PASEP(VL_DED_PIS)" não pode ser negativa ou nula ('||trim(est_row_deducaodiversaspc.vl_ded_pis)||').';
          --
          vn_loggenerico_id := null;
          --
          pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                               , ev_mensagem          => gv_mensagem
                               , ev_resumo            => gv_resumo
                               , en_tipo_log          => erro_de_validacao
                               , en_referencia_id     => gn_referencia_id
                               , ev_obj_referencia    => gv_obj_referencia
                               , en_empresa_id        => gn_empresa_id
                               );
          --
          -- Armazena o "loggenerico_id" na memória
          pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                  , est_log_generico_ddo => est_log_generico_ddo );
          --
       end if;
       --
       vn_fase := 1.13;
       --
       if nvl(est_row_deducaodiversaspc.vl_ded_cofins,0) <= 0 then
          --
          vn_fase := 14;
          --
          gv_resumo := null;
          --
          gv_resumo := '"Valor a Deduzir - COFINS(VL_DED_COFINS)" não pode ser negativa ou nula ('||trim(est_row_deducaodiversaspc.vl_ded_cofins)||').';
          --
          vn_loggenerico_id := null;
          --
          pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                               , ev_mensagem          => gv_mensagem
                               , ev_resumo            => gv_resumo
                               , en_tipo_log          => erro_de_validacao
                               , en_referencia_id     => gn_referencia_id
                               , ev_obj_referencia    => gv_obj_referencia
                               , en_empresa_id        => gn_empresa_id
                               );
          --
          -- Armazena o "loggenerico_id" na memória
          pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                  , est_log_generico_ddo => est_log_generico_ddo );
          --
       end if;
       --
       vn_fase := 1.15;
       --
       if nvl(est_row_deducaodiversaspc.vl_bc_oper,0) <= 0 then
          --
          vn_fase := 1.16;
          --
          gv_resumo := null;
          --
          gv_resumo := '"Valor da Base de Cálc. da Oper. que ensejou o Valor a Ded. inf. nos Campos VL_DED_PIS e VL_DED_COFINS(VL_BC_OPER)" não pode ser negativa '||
                       'ou nula ('||trim(est_row_deducaodiversaspc.vl_ded_cofins)||').';
          --
          vn_loggenerico_id := null;
          --
          pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                               , ev_mensagem          => gv_mensagem
                               , ev_resumo            => gv_resumo
                               , en_tipo_log          => erro_de_validacao
                               , en_referencia_id     => gn_referencia_id
                               , ev_obj_referencia    => gv_obj_referencia
                               , en_empresa_id        => gn_empresa_id
                               );
          --
          -- Armazena o "loggenerico_id" na memória
          pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                  , est_log_generico_ddo => est_log_generico_ddo );
          --
       end if;
       --
       vn_fase := 1.17;
       --
       if trim(est_row_deducaodiversaspc.cnpj) is not null then
          --
          vn_fase := 1.18;
          --
          vn_docto_valido := 0; -- invalido.
          --
          vn_docto_valido := pk_valida_docto.fkg_valida_cpf_cgc(ev_numero => est_row_deducaodiversaspc.cnpj ); -- valida o cnpj que for integrado: 0 - inválido 1 - cnpj valido.
          --
          if nvl(vn_docto_valido,0) = 0 then
             --
             vn_fase := 1.19;
             --
             gv_resumo := null;
             --
             gv_resumo := '"CNPJ da Pessoa Jurídica relacionada a Operação que ensejou o Valor a Deduzir informado(CNPJ)" inválido, favor verificar: ('||
                          trim(est_row_deducaodiversaspc.cnpj)||').';
             --
             vn_loggenerico_id := null;
             --
             pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                                  , ev_mensagem          => gv_mensagem
                                  , ev_resumo            => gv_resumo
                                  , en_tipo_log          => erro_de_validacao
                                  , en_referencia_id     => gn_referencia_id
                                  , ev_obj_referencia    => gv_obj_referencia
                                  , en_empresa_id        => gn_empresa_id
                                  );
             --
             -- Armazena o "loggenerico_id" na memória
             pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                     , est_log_generico_ddo => est_log_generico_ddo );
             --
          end if;
          --
       end if;
       --
       vn_fase := 1.20;
       --
       if (pk_int_view_ddo.gd_dt_ult_fecha is null) or (to_date((lpad(est_row_deducaodiversaspc.mes_ref,2,'0')||est_row_deducaodiversaspc.ano_ref),'mm/rrrr') < pk_int_view_ddo.gd_dt_ult_fecha) then
             --
             gv_resumo := null;
             --
             gv_resumo := 'Período informado para integração de Demais Documentos e Operações - Bloco F EFD-'||
                          'Contribuições (Bloco F700), está fechado para a data do registro. Data de fechamento fiscal '||
                          to_char(pk_int_view_ddo.gd_dt_ult_fecha,'dd/mm/yyyy')||' - CNPJ/CPF: '||ev_cnpj_empr||'.';
             --
             vn_loggenerico_id := null;
             --
             pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                                  ev_mensagem          => gv_mensagem,
                                  ev_resumo            => gv_resumo,
                                  en_tipo_log          => erro_de_validacao,
                                  en_referencia_id     => gn_referencia_id,
                                  ev_obj_referencia    => gv_obj_referencia,
                                  en_empresa_id        => gn_empresa_id
                                 );

             --
             -- Armazena o "loggenerico_id" na memória
             pkb_gt_log_generico_ddo( en_loggenericoddo_id => vn_loggenerico_id,
                                      est_log_generico_ddo => est_log_generico_ddo);
             --
       end if;
       --
       vn_fase := 99;
       --
       if nvl( est_row_deducaodiversaspc.id,0 )           >  0 and
          nvl(vn_id,0)                                    >  0 and
          nvl(est_row_deducaodiversaspc.empresa_id,0)     >  0 and
          trim(est_row_deducaodiversaspc.ano_ref)         is not null and
          trim(est_row_deducaodiversaspc.mes_ref)         is not null and
          nvl(est_row_deducaodiversaspc.dm_ind_ori_ded,0) >  0 and
          nvl(est_row_deducaodiversaspc.dm_ind_nat_ded,0) >= 0 and
          nvl(est_row_deducaodiversaspc.vl_ded_pis,0)     >  0 and
          nvl(est_row_deducaodiversaspc.vl_ded_cofins,0)  >  0 and
          nvl(est_row_deducaodiversaspc.vl_bc_oper,0)     >  0 then
          --
          vn_fase := 99.1;
          --
          begin
             pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
          exception
             when others then
                null;
          end;
          --
          vn_fase := 99.2;
          --
          insert into deducao_diversa_pc ( id
                                         , empresa_id
                                         , ano_ref
                                         , mes_ref
                                         , dm_ind_ori_ded
                                         , dm_ind_nat_ded
                                         , vl_ded_pis
                                         , vl_ded_cofins
                                         , vl_bc_oper
                                         , cnpj
                                         , inf_comp
                                         , dm_st_proc
                                         , dm_st_integra )
                                  values ( est_row_deducaodiversaspc.id
                                         , est_row_deducaodiversaspc.empresa_id
                                         , est_row_deducaodiversaspc.ano_ref
                                         , est_row_deducaodiversaspc.mes_ref
                                         , est_row_deducaodiversaspc.dm_ind_ori_ded
                                         , est_row_deducaodiversaspc.dm_ind_nat_ded
                                         , est_row_deducaodiversaspc.vl_ded_pis
                                         , est_row_deducaodiversaspc.vl_ded_cofins
                                         , est_row_deducaodiversaspc.vl_bc_oper
                                         , est_row_deducaodiversaspc.cnpj
                                         , est_row_deducaodiversaspc.inf_comp
                                         , est_row_deducaodiversaspc.dm_st_proc
                                         , est_row_deducaodiversaspc.dm_st_integra
                                         );
          --
          commit;
          --
       else
          --
          vn_fase :=  99.3;
          --
          update deducao_diversa_pc dd
             set dd.dm_ind_ori_ded  = est_row_deducaodiversaspc.dm_ind_ori_ded
               , dd.dm_ind_nat_ded  = est_row_deducaodiversaspc.dm_ind_nat_ded
               , dd.vl_bc_oper      = est_row_deducaodiversaspc.vl_bc_oper
               , dd.cnpj            = est_row_deducaodiversaspc.cnpj
               , dd.inf_comp        = est_row_deducaodiversaspc.inf_comp
               , dd.dm_st_proc      = est_row_deducaodiversaspc.dm_st_proc
               , dd.dm_st_integra   = est_row_deducaodiversaspc.dm_st_integra
           where dd.id              = est_row_deducaodiversaspc.id
             and dd.dm_st_proc      not in (1); -- validada
          --
          commit;
          --
       end if;
       --
   end if;
   --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_deducaodiversapc fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );

      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_deducaodiversapc;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CONTR_RET_FONTE_PC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_contrretfontepc ( est_log_generico_ddo       in out nocopy dbms_sql.number_table
                                     , est_row_contr_ret_fonte_pc in out nocopy contr_ret_fonte_pc%rowtype
                                     , en_multorg_id              in            mult_org.id%type
                                     , ev_cnpj_empr               in            varchar2
                                     ) is
   --
   vn_fase                  number := null;
   vn_loggenerico_id        log_generico_ddo.id%type;
   vn_docto_valido          number := null;
   vn_contr_ret_fonte_pc_id contr_ret_fonte_pc.id%type := null;
   vn_dm_st_proc            contr_ret_fonte_pc.dm_st_proc%type := null;
   --
   vn_id_existe             contr_ret_fonte_pc.id%type := null; --#71316
   --
begin
   --
   vn_fase := 1;
   --
   -- #69214 alteracao de posicao da atualicao da qtd total
   begin
      pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
   exception
     when others then
       null;
   end;
   --
   --#69214 alteracao limpa variavel
   gn_referencia_id := null;
   --
   est_row_contr_ret_fonte_pc.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj ( en_multorg_id => en_multorg_id
                                                                                , ev_cpf_cnpj   => ev_cnpj_empr
                                                                                );
   --
   vn_fase := 1.1;
   --
   --| Montar o cabeçalho do log
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa ( en_empresa_id => est_row_contr_ret_fonte_pc.empresa_id );
   gv_mensagem := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'CONTR_RET_FONTE_PC'; end if;
   --
   vn_fase := 1.2;
   --
   -- Se a data fechamento não foi carregada busca a data para validação
   if pk_int_view_ddo.gd_dt_ult_fecha is null then
      --
      pk_int_view_ddo.gd_dt_ult_fecha := pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id   => est_row_contr_ret_fonte_pc.empresa_id
                                                                             , en_objintegr_id => pk_csf.fkg_recup_objintegr_id( ev_cd => '50' )); -- Demais Documentos e Operações - Bloco F EFD Contribuições
      --
   end if ;
   --
   vn_fase := 1.3;
   -- 
   -- verifica se existe na tabela o registro e retorna o id da tabela
   begin
      --
      pk_csf_ddo.pkb_contrretfontepc ( en_empresa_id          => est_row_contr_ret_fonte_pc.empresa_id
                                     , ev_dm_ind_nat_ret      => est_row_contr_ret_fonte_pc.dm_ind_nat_ret
                                     , ed_dt_ret              => est_row_contr_ret_fonte_pc.dt_ret
                                     , ev_cod_rec             => est_row_contr_ret_fonte_pc.cod_rec
                                     , en_dm_ind_nat_rec      => est_row_contr_ret_fonte_pc.dm_ind_nat_rec
                                     , ev_cnpj                => est_row_contr_ret_fonte_pc.cnpj
                                     , sn_contrretfontepc_id  => vn_contr_ret_fonte_pc_id
                                     , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_contr_ret_fonte_pc_id := null;
         vn_dm_st_proc            := null;
   end;
   --
   vn_fase := 1.4;
   -------------------------------------------------------------------------------------------------
   --#69214 alteracao da validacao do id.
   -- Se o id for nulo e nao encontrar na tabela final, cria o id pela sequence, 
   -- se encontrar na tabela, atribui a variavel que fara o update(vn_contr_ret_fonte_pc_id),
   --  e se o id ja estiver preechido atribui na variavel pra insert(est_row_contr_ret_fonte_pc.id)
   -------------------------------------------------------------------------------------------------
   --
   --se id nao veio preenchido
   if (nvl(est_row_contr_ret_fonte_pc.id,0) <= 0 or est_row_contr_ret_fonte_pc.id is null ) then
      --
      vn_fase := 1.5;
      -- se nao encontrou nada na tabela
      if (nvl(vn_contr_ret_fonte_pc_id,0) <= 0 or vn_contr_ret_fonte_pc_id is null) then
        --
        vn_fase := 1.6;
        --  gera a sequence
        select contrretfontepc_seq.nextval
          into est_row_contr_ret_fonte_pc.id
          from dual;
        --
        gn_referencia_id := est_row_contr_ret_fonte_pc.id;--nao existe id
        --
      else
         --
         vn_fase := 1.7;
         --  atribui o que foi encontrado
         gn_referencia_id              := vn_contr_ret_fonte_pc_id;--ja existe o id
         est_row_contr_ret_fonte_pc.id := vn_contr_ret_fonte_pc_id;
         -- 
      end if;     
      --
   else--se id ja veio preeechido
    --
    vn_fase := 1.8;
     -- verifica se encontrou alguem na tabela 
     if nvl(vn_contr_ret_fonte_pc_id,0) > 0 then
       -- se os ids forem diferentes, gera erro.
       if (nvl(vn_contr_ret_fonte_pc_id,0) <> nvl(est_row_contr_ret_fonte_pc.id,0)) then 
         --
         vn_fase := 1.9;
         --
         gv_resumo := null;
         --
         gv_resumo := '"O id integrado ('||est_row_contr_ret_fonte_pc.id||') está diferente do id encontrado '||vn_contr_ret_fonte_pc_id||' para o registro na tabela CONTR_RET_FONTE_PC. Verifique os registros';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => est_row_contr_ret_fonte_pc.id 
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --      
       else
         -- se os dis forem iguais, atribui
         gn_referencia_id := vn_contr_ret_fonte_pc_id; 
         -- 
       end if;
     else
       --
       vn_fase := 1.10;
       --
       gn_referencia_id := est_row_contr_ret_fonte_pc.id;
       --
     end if; 
    --
   end if;
   --
   vn_fase := 2;
   --
   --| Validar Registros
   if trim(ev_cnpj_empr) is null then
      --
      vn_fase := 2.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da empresa não encontrado na base Compliance:" ('||trim(ev_cnpj_empr)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3;
   --
   if trim(est_row_contr_ret_fonte_pc.dm_ind_nat_ret) not in ('01','02','03','04','05','99') then
      --
      vn_fase := 3.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Indicador de Natureza da Retenção na Fonte" inválido, favor verificar: ('||trim(est_row_contr_ret_fonte_pc.dm_ind_nat_ret)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4;
   --
   if nvl(est_row_contr_ret_fonte_pc.dm_ind_nat_rec,0) not in (0,1) then
      --
      vn_fase := 4.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Indicador da Natureza da Receita" inválido, favor verificar: ('||trim(est_row_contr_ret_fonte_pc.dm_ind_nat_rec)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --   
      --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
      goto sair_integracao;
      --
   end if;
   --
   vn_fase := 5;
   --
   if nvl(est_row_contr_ret_fonte_pc.dm_ind_dec,-1) not in (0,1) then
      --
      vn_fase := 5.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Indicador da condição da pessoa declarante" inválido, favor verificar: ('||trim(est_row_contr_ret_fonte_pc.dm_ind_dec)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
      --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
      goto sair_integracao;
      --
   end if;
   --
   vn_fase := 6;
   --
   if nvl(est_row_contr_ret_fonte_pc.vl_bc_ret,0) <= 0 then
      --
      vn_fase := 6.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Base de cálculo da retenção ou do recolhimento (sociedade cooperativa)(VL_BC_RET), não pode ser negativa ou nula."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
      --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
      goto sair_integracao;
      --
   end if;
   --
   vn_fase := 7;
   --
   if trim(est_row_contr_ret_fonte_pc.cnpj) is not null then
      --
      vn_fase := 7.1;
      --
      vn_docto_valido := null;
      --
      vn_docto_valido := pk_valida_docto.fkg_valida_cpf_cgc(ev_numero => est_row_contr_ret_fonte_pc.cnpj );
      --
      vn_fase := 7.2;
      --
      if nvl(vn_docto_valido,0) = 0 then
         --
         vn_fase := 7.3;
         gv_resumo := null;
         --
         gv_resumo := '"O CNPJ da Pessoa Jurídica relacionada a Operação que ensejou o Valor a Deduzir informado(CNPJ)" é inválido, favor verificar: ('||
                      trim(est_row_contr_ret_fonte_pc.cnpj)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      end if;
      --
   else
      --
      vn_fase := 7.4;
      --
      vn_docto_valido := 0;
      --
      gv_resumo := null;
      --
      gv_resumo := '"O CNPJ referente a: Fonte Pagadora Responsavel pela Ret./Rec. ou Pessoa Juridica Beneficiaria da Ret./Recolhimento(CNPJ)", esta nulo, porem o campo é obrigatório, favor informar.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
      --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
      goto sair_integracao;
      --
   end if;
   --
   vn_fase := 8;
   --
   if nvl(est_row_contr_ret_fonte_pc.vl_rec,0) <= 0 then
      --
      vn_fase := 8.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Valor Total Retido na Fonte / Recolhido sociedade cooperativa(VL_REC), não pode ser menor ou igual a zero e nem nullo."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 9;
   --
   if nvl(est_row_contr_ret_fonte_pc.vl_ret_pis,0) <= 0 then
      --
      vn_fase := 9.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Valor Retido na Fonte - Parcela Referente ao PIS/Pasep(VL_RET_PIS), não pode ser menor ou igual a zero e nem nullo."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 10;
   --
   if nvl(est_row_contr_ret_fonte_pc.vl_ret_cofins,0) <= 0 then
      --
      vn_fase := 10.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Valor Retido na Fonte - Parcela Referente a COFINS(VL_RET_COFINS), não pode ser menor ou igual a zero e nem nullo."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 11;
   --
   if length(est_row_contr_ret_fonte_pc.cod_rec) > 4 then
      --
      vn_fase := 11.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Quantidade de caractere maior que a permitida do campo "Codigo da Receita", favor verificar.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 12;
   --
   if (pk_int_view_ddo.gd_dt_ult_fecha is null) or (trunc(est_row_contr_ret_fonte_pc.dt_ret) < pk_int_view_ddo.gd_dt_ult_fecha) then
     --
     gv_resumo := null;
     --
     gv_resumo := 'Período informado para integração de Demais Documentos e Operações - Bloco F EFD-'||
                  'Contribuições (Bloco F600), está fechado para a data do registro. Data de fechamento fiscal '||
                  to_char(pk_int_view_ddo.gd_dt_ult_fecha,'dd/mm/yyyy')||' - CNPJ/CPF: '||ev_cnpj_empr||'.';
     --
     vn_loggenerico_id := null;
     --
     pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                          ev_mensagem          => gv_mensagem,
                          ev_resumo            => gv_resumo,
                          en_tipo_log          => erro_de_validacao,
                          en_referencia_id     => gn_referencia_id,
                          ev_obj_referencia    => gv_obj_referencia,
                          en_empresa_id        => gn_empresa_id
                           );
     --
     -- Armazena o "loggenerico_id" na memória
     pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                             est_log_generico_ddo => est_log_generico_ddo);
     --
   end if;
   --
   vn_fase := 13;
   --
   --#69214 alteracao de validacao do id pela gn_referencia_id
   if gn_referencia_id                                   >  0 and
      nvl(est_row_contr_ret_fonte_pc.empresa_id,0)       >  0 and
      nvl(est_row_contr_ret_fonte_pc.dm_ind_nat_ret,' ') in ('01','02','03','04','05','99') and
      est_row_contr_ret_fonte_pc.dt_ret                  is not null and
      est_row_contr_ret_fonte_pc.cnpj                    is not null then
      --
      vn_fase := 13.1;
      --
      -- #71316 validar se nao existe                                                
      if nvl(vn_contr_ret_fonte_pc_id,0) <> nvl(est_row_contr_ret_fonte_pc.id,0) then
        --
        vn_fase := 13.4;
        --
        begin
          insert into contr_ret_fonte_pc ( id
                                         , empresa_id
                                         , dm_ind_nat_ret
                                         , dt_ret
                                         , vl_bc_ret
                                         , vl_rec
                                         , cod_rec
                                         , dm_ind_nat_rec
                                         , cnpj
                                         , vl_ret_pis
                                         , vl_ret_cofins
                                         , dm_ind_dec
                                         , dm_st_proc
                                         , dm_st_integra )
                                  values ( est_row_contr_ret_fonte_pc.id
                                         , est_row_contr_ret_fonte_pc.empresa_id
                                         , est_row_contr_ret_fonte_pc.dm_ind_nat_ret
                                         , est_row_contr_ret_fonte_pc.dt_ret
                                         , est_row_contr_ret_fonte_pc.vl_bc_ret
                                         , est_row_contr_ret_fonte_pc.vl_rec
                                         , est_row_contr_ret_fonte_pc.cod_rec
                                         , est_row_contr_ret_fonte_pc.dm_ind_nat_rec
                                         , est_row_contr_ret_fonte_pc.cnpj
                                         , est_row_contr_ret_fonte_pc.vl_ret_pis
                                         , est_row_contr_ret_fonte_pc.vl_ret_cofins
                                         , est_row_contr_ret_fonte_pc.dm_ind_dec
                                         , est_row_contr_ret_fonte_pc.dm_st_proc
                                         , est_row_contr_ret_fonte_pc.dm_st_integra
                                         );
             --
             commit;
             --   
        exception
           when others then  
             --
             vn_fase := 13.5;
             --
             gv_resumo := null;
             --
             gv_resumo := 'Erro ao tentar inserir registro na tabela CONTR_RET_FONTE_PC.'    ||
                          '(Id = '              || est_row_contr_ret_fonte_pc.id             || --#71316
                          ' / empresa_id = '    || est_row_contr_ret_fonte_pc.empresa_id     ||
                          ' / dm_ind_nat_ret = '|| est_row_contr_ret_fonte_pc.dm_ind_nat_ret ||
                          ' / dt_ret = '        || est_row_contr_ret_fonte_pc.dt_ret         ||
                          ' / vl_bc_ret = '     || est_row_contr_ret_fonte_pc.vl_bc_ret      ||
                          ' / vl_rec = '        || est_row_contr_ret_fonte_pc.vl_rec         ||
                          ' / cod_rec = '       || est_row_contr_ret_fonte_pc.cod_rec        ||
                          ' / dm_ind_nat_rec = '|| est_row_contr_ret_fonte_pc.dm_ind_nat_rec ||
                          ' / cnpj = '          || est_row_contr_ret_fonte_pc.cnpj           ||
                          ' / vl_ret_pis = '    || est_row_contr_ret_fonte_pc.vl_ret_pis     ||
                          ' / vl_ret_cofins = ' || est_row_contr_ret_fonte_pc.vl_ret_cofins  ||
                          ' / dm_ind_dec = '    || est_row_contr_ret_fonte_pc.dm_ind_dec     ||
                          ' / dm_st_proc = '    || est_row_contr_ret_fonte_pc.dm_st_proc     ||
                          ' / dm_st_integra = ' || est_row_contr_ret_fonte_pc.dm_st_integra  ||
                          ' ) - ' || sqlerrm ;
             --
             vn_loggenerico_id := null;
             --
             pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                                  ev_mensagem          => gv_mensagem,
                                  ev_resumo            => gv_resumo,
                                  en_tipo_log          => erro_de_validacao,
                                  en_referencia_id     => gn_referencia_id,
                                  ev_obj_referencia    => gv_obj_referencia,
                                  en_empresa_id        => gn_empresa_id
                                   );
             --
             -- Armazena o "loggenerico_id" na memória
             pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                                     est_log_generico_ddo => est_log_generico_ddo);
             --
        end;
        --
      else
        --
         vn_fase := 13.6;
         --
         begin
           update contr_ret_fonte_pc cr
              set cr.dm_ind_nat_ret    = est_row_contr_ret_fonte_pc.dm_ind_nat_ret
                , cr.vl_rec            = est_row_contr_ret_fonte_pc.vl_rec
                , cr.cod_rec           = est_row_contr_ret_fonte_pc.cod_rec
                , cr.dm_ind_nat_rec    = est_row_contr_ret_fonte_pc.dm_ind_nat_rec
                , cr.cnpj              = est_row_contr_ret_fonte_pc.cnpj
                , cr.vl_ret_pis        = est_row_contr_ret_fonte_pc.vl_ret_pis
                , cr.vl_ret_cofins     = est_row_contr_ret_fonte_pc.vl_ret_cofins
                , cr.dm_ind_dec        = est_row_contr_ret_fonte_pc.dm_ind_dec
                , cr.dm_st_proc        = est_row_contr_ret_fonte_pc.dm_st_proc
                , cr.dm_st_integra     = est_row_contr_ret_fonte_pc.dm_st_integra
            where cr.id                = vn_contr_ret_fonte_pc_id --est_row_contr_ret_fonte_pc.id --#69214 se for update usa esta variavel
              and cr.dm_st_proc        not in (1); -- Validada
           --
           commit;
           --
           -- #69214 - atribui o id ja alterado
           est_row_contr_ret_fonte_pc.id := vn_contr_ret_fonte_pc_id;
           --
         exception
           when others then  
             --
             vn_fase := 13.7;
             --
             gv_resumo := null;
             --
             gv_resumo := 'Erro ao tentar alterar registro na tabela CONTR_RET_FONTE_PC.'    ||
                          '( id = '             || vn_contr_ret_fonte_pc_id                  ||
                          ' / dm_ind_nat_ret = '|| est_row_contr_ret_fonte_pc.dm_ind_nat_ret ||
                          ' / vl_rec = '        || est_row_contr_ret_fonte_pc.vl_rec         ||
                          ' / cod_rec = '       || est_row_contr_ret_fonte_pc.cod_rec        ||
                          ' / dm_ind_nat_rec = '|| est_row_contr_ret_fonte_pc.dm_ind_nat_rec ||
                          ' / cnpj = '          || est_row_contr_ret_fonte_pc.cnpj           ||
                          ' / vl_ret_pis = '    || est_row_contr_ret_fonte_pc.vl_ret_pis     ||
                          ' / vl_ret_cofins = ' || est_row_contr_ret_fonte_pc.vl_ret_cofins  ||
                          ' / dm_ind_dec = '    || est_row_contr_ret_fonte_pc.dm_ind_dec     ||
                          ' / dm_st_proc = '    || est_row_contr_ret_fonte_pc.dm_st_proc     ||
                          ' / dm_st_integra = ' || est_row_contr_ret_fonte_pc.dm_st_integra  ||
                          ' ) - ' || sqlerrm ;
             --
             vn_loggenerico_id := null;
             --
             pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                                  ev_mensagem          => gv_mensagem,
                                  ev_resumo            => gv_resumo,
                                  en_tipo_log          => erro_de_validacao,
                                  en_referencia_id     => vn_contr_ret_fonte_pc_id, --gn_referencia_id,
                                  ev_obj_referencia    => gv_obj_referencia,
                                  en_empresa_id        => gn_empresa_id
                                   );
             --
             -- Armazena o "loggenerico_id" na memória
             pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                                     est_log_generico_ddo => est_log_generico_ddo);
             --
         end; 
         --
      end if;
      --
   end if;
   --
   -- Sair da Integração quando a erro de campo obrigatorio
   <<sair_integracao>>
   --
   null;
   --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_intgr_contrretfontepc fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_contrretfontepc;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela PR_CONS_OP_INS_PCRCOAUM
----------------------------------------------------------------------------------------------------
procedure pkb_integr_prconsopinspcrcoaum ( est_log_generico_ddo         in out nocopy dbms_sql.number_table
                                         , est_row_prconsopinspcrcoaum  in out nocopy pr_cons_op_ins_pcrcoaum%rowtype
                                         , ev_cpf_cnpj                  in            varchar2
                                         , en_cd_orig                   in            number
                                         ) is
   --
   vn_fase                   number := null;
   vn_loggenerico_id         log_generico_ddo.id%type;
   vn_id                     pr_cons_op_ins_pcrcoaum.id%type := null;
   vn_prconsopinspcrcoaum_id pr_cons_op_ins_pcrcoaum.id%type := null;
   vn_dm_st_proc             number(1) := null;
   --
begin
   --
   vn_fase := 1;
   --
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cpf_cnpj;
   gv_mensagem := gv_mensagem || chr(10);
   gv_mensagem := gv_mensagem || ' Rotina - registros(F569)';
   -- Recebe o id da tabela pai, pq é essa tabela q a tela busca como objetos de referencia
   gn_referencia_id := est_row_prconsopinspcrcoaum.consopinspcrcompaum_id;
   --
   if gv_obj_referencia is null then gv_obj_referencia := 'CONS_OP_INS_PCRCOMP_AUM'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_prconsopinspcrcoaum
   if nvl(est_row_prconsopinspcrcoaum.origproc_id,0) = 0 then
      est_row_prconsopinspcrcoaum.origproc_id := pk_csf.fkg_Orig_Proc_id( en_cd => en_cd_orig );
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_prconsopinspcrcoaum ( en_consopinspcrcompaum_id => est_row_prconsopinspcrcoaum.consopinspcrcompaum_id
                                         , en_origproc_id            => est_row_prconsopinspcrcoaum.origproc_id
                                         , sn_prconsopinspcrcoaum_id => vn_prconsopinspcrcoaum_id
                                         , sn_dm_st_proc             => vn_dm_st_proc );
      --
   exception
      when others then
         vn_prconsopinspcrcoaum_id := null;
         vn_dm_st_proc             := null;
   end;
   --
   vn_fase := 1.2;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_prconsopinspcrcoaum.id,0) <= 0 and nvl(vn_prconsopinspcrcoaum_id,0) <= 0 then
      -- pr_cons_op_ins_pcrcoaum
      select prconsopinspcrcoaum_seq.nextval
        into est_row_prconsopinspcrcoaum.id
        from dual;
      --
      vn_id := est_row_prconsopinspcrcoaum.id;
      --
   elsif nvl(est_row_prconsopinspcrcoaum.id,0) <= 0 and nvl(vn_prconsopinspcrcoaum_id,0) > 0 then
      --
      est_row_prconsopinspcrcoaum.id := vn_prconsopinspcrcoaum_id;
      --
   elsif nvl(est_row_prconsopinspcrcoaum.id,0) > 0 and nvl(est_row_prconsopinspcrcoaum.id,0) <> nvl(vn_prconsopinspcrcoaum_id,0) then
       --
       vn_fase := 1.23;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_prconsopinspcrcoaum.id||') está diferente do id encontrado '||vn_prconsopinspcrcoaum_id||' para o registro na tabela PR_CONS_OP_INS_PCRCOAUM.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   vn_fase := 1.4;
   --
   if nvl(est_row_prconsopinspcrcoaum.origproc_id,0) = 0 and en_cd_orig is not null then
         --
         vn_fase := 1.5;
         --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Origem do Processo não encontrado na base Compliance:" ('|| en_cd_orig ||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   elsif nvl(est_row_prconsopinspcrcoaum.origproc_id,0) = 0 then
      --
      vn_fase := 1.51;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Código da Origem do Processo não informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.52;
   --
   if trim(est_row_prconsopinspcrcoaum.num_proc) is null then
      --
      vn_fase := 1.6;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Identificação do processo ou ato concessório não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.7;
   --
   if nvl(est_row_prconsopinspcrcoaum.id, 0)                    > 0 and
      nvl(vn_id,0)                                              > 0 and
      nvl(est_row_prconsopinspcrcoaum.consopinspcrcompaum_id,0) > 0 and
      trim(est_row_prconsopinspcrcoaum.num_proc)                is not null and
      nvl(est_row_prconsopinspcrcoaum.origproc_id,0)            > 0 then
      --
      vn_fase := 1.8;
      --
      insert into pr_cons_op_ins_pcrcoaum ( id
                                          , consopinspcrcompaum_id
                                          , num_proc
                                          , origproc_id )
                                    values( est_row_prconsopinspcrcoaum.id
                                          , est_row_prconsopinspcrcoaum.consopinspcrcompaum_id
                                          , est_row_prconsopinspcrcoaum.num_proc
                                          , est_row_prconsopinspcrcoaum.origproc_id
                                          );
      --
      commit;
      --
   else
      --
      vn_fase := 2;
      --
      update pr_cons_op_ins_pcrcoaum
         set num_proc    = est_row_prconsopinspcrcoaum.num_proc
       where id          = est_row_prconsopinspcrcoaum.id;
      --
      commit;
      --
   end if;
    --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_prconsopinspcrcoaum fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_prconsopinspcrcoaum;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CONS_OP_INS_PCRCOMP_AUM - F560
----------------------------------------------------------------------------------------------------
procedure pkb_integr_consopinspcrcompaum ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                         , est_row_consopinspcrcompaum in out nocopy cons_op_ins_pcrcomp_aum%rowtype
                                         , ev_cnpj_empr                in            varchar2
                                         , en_multorg_id               in            mult_org.id%type
                                         , ev_cod_st_pis               in            varchar2
                                         , ev_cod_st_cofins            in            varchar2
                                         , ev_cod_mod                  in            varchar2
                                         , ev_cod_cta                  in            varchar2
                                         , en_cfop                     in            number
                                         ) is
   --
   vn_fase                   number := null;
   vn_loggenerico_id         log_generico_ddo.id%type;
   vn_id                     cons_op_ins_pcrcomp_aum.id%type := null;
   vn_consopinspcrcompaum_id cons_op_ins_pcrcomp_aum.id%type := null;
   vn_dm_st_proc             cons_op_ins_pcrcomp_aum.dm_st_proc%type := null;
   --
begin
   --
   vn_fase := 1;
   --
   est_row_consopinspcrcompaum.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj( en_multorg_id => en_multorg_id
                                                                                , ev_cpf_cnpj   => ev_cnpj_empr
                                                                                );
   --
   vn_fase := 1.1;
   --| Montar o cabeçalho do log
   gv_mensagem := null;
   gv_mensagem := 'BLOCO F560 - Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa(en_empresa_id => est_row_consopinspcrcompaum.empresa_id);
   gv_mensagem := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'CONS_OP_INS_PCRCOMP_AUM'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_consopinspcrcompaum
   if nvl(est_row_consopinspcrcompaum.codst_id_pis,0) = 0 then
      est_row_consopinspcrcompaum.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                       , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.codst_id_cofins,0) = 0 then
      est_row_consopinspcrcompaum.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                          , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS

   end if;
   --
   if nvl(est_row_consopinspcrcompaum.modfiscal_id,0) = 0 then
      est_row_consopinspcrcompaum.modfiscal_id  := pk_csf_ddo.fkg_cod_mod_modfiscal_id( ev_cod_mod  => ev_cod_mod );
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.planoconta_id,0) = 0 then
      est_row_consopinspcrcompaum.planoconta_id := pk_csf.fkg_Plano_Conta_id ( ev_cod_cta    =>  ev_cod_cta
                                                                             , en_empresa_id =>  est_row_consopinspcrcompaum.empresa_id );
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.cfop_id,0) = 0 then
      est_row_consopinspcrcompaum.cfop_id := pk_csf.fkg_cfop_id ( en_cd => en_cfop ); -- se o valor for nulo ou não for válido, a função retorna NULL
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_consopinspcrcompaum ( en_empresa_id      => est_row_consopinspcrcompaum.empresa_id
                                         , ed_dt_ref          => est_row_consopinspcrcompaum.dt_ref
                                         , en_codst_id_pis    => est_row_consopinspcrcompaum.codst_id_pis
                                         , en_vl_aliq_pis     => est_row_consopinspcrcompaum.vl_aliq_pis
                                         , en_codst_id_cofins => est_row_consopinspcrcompaum.codst_id_cofins
                                         , en_vl_aliq_cofins  => est_row_consopinspcrcompaum.vl_aliq_cofins
                                         , en_modfiscal_id    => est_row_consopinspcrcompaum.modfiscal_id
                                         , en_planoconta_id   => est_row_consopinspcrcompaum.planoconta_id
                                         , ev_info_compl      => est_row_consopinspcrcompaum.info_compl
                                         , en_cfop_id         => est_row_consopinspcrcompaum.cfop_id
                                         , sn_consopinspcrcompaum_id => vn_consopinspcrcompaum_id
                                         , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_consopinspcrcompaum_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.2;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_consopinspcrcompaum.id,0) <= 0 and nvl(vn_consopinspcrcompaum_id,0) <= 0 then
      -- cons_op_ins_pcrcomp_aum
      select consopinspcrcompaum_seq.nextval
        into est_row_consopinspcrcompaum.id
        from dual;
      --
      vn_id := est_row_consopinspcrcompaum.id;
      --
   elsif nvl(est_row_consopinspcrcompaum.id,0) <= 0 and nvl(vn_consopinspcrcompaum_id,0) > 0 then
      --
      est_row_consopinspcrcompaum.id := vn_consopinspcrcompaum_id;
      --
   elsif nvl(est_row_consopinspcrcompaum.id,0) > 0 and nvl(est_row_consopinspcrcompaum.id,0) <> nvl(vn_consopinspcrcompaum_id,0) then
       --
       vn_fase := 1.3;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_consopinspcrcompaum.id||') está diferente do id encontrado '||vn_consopinspcrcompaum_id||' para o registro na tabela CONS_OP_INS_PCRCOMP_AUM.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_consopinspcrcompaum.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   gn_referencia_id := est_row_consopinspcrcompaum.id;
   --
   vn_fase := 1.4;
   --| Validar Registros
   if nvl(est_row_consopinspcrcompaum.empresa_id,0) <= 0 then
      --
      vn_fase := 1.5;
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da empresa não encontrado na base Compliance, ou não informado:" ('||trim(ev_cnpj_empr)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.6;
   --
   if nvl(est_row_consopinspcrcompaum.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
         --
         vn_fase := 1.7;
         --
         gv_resumo := '"Código da Situação Tributaria do Imposto PIS não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_consopinspcrcompaum.codst_id_pis,0) = 0 then
      --
      vn_fase := 1.8;
      --
      gv_resumo := '"Código da Situação Tributaria do Imposto PIS não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2;
   --
   if nvl(est_row_consopinspcrcompaum.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
         vn_fase := 2.3;
         --
         gv_resumo := '"Código da Situação Tributaria do Imposto COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_consopinspcrcompaum.codst_id_cofins,0) = 0  then
      --
      vn_fase := 2.4;
      --
      gv_resumo := 'Código da Situação Tributaria do Imposto COFINS não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.5;
   --
   if nvl(est_row_consopinspcrcompaum.modfiscal_id,0) = 0  and trim(ev_cod_mod) is not null then
      --
         --
         vn_fase := 2.8;
         --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Modelo de Documento Fiscal não encontrado, favor verificar o código: " ('||trim(ev_cod_mod)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.9;
   --
   if nvl(est_row_consopinspcrcompaum.planoconta_id,0) = 0 and trim(ev_cod_cta) is not null then
      --
      vn_fase := 3;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código do plano de conta não encontrado na base compliance" ('||trim(ev_cod_cta)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   end if;
   --
   vn_fase := 3.3;
   --
   if nvl(est_row_consopinspcrcompaum.vl_aliq_pis,0) < 0 then
      --
      vn_fase := 3.4;
      --
      gv_resumo := '"Alíquota do PIS/PASEP em reais(VL_ALIQ_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.vl_aliq_cofins,0) < 0 then
      --
      vn_fase := 3.5;
      --
      gv_resumo := '"Alíquota do COFINS em reais (VL_ALIQ_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.vl_rec_comp,0) <= 0 then
      --
      vn_fase := 3.6;
      --
      gv_resumo := '"Valor total da receita auferida, ref. à comb. de Alíq.(VL_REC_COMP)" Não pode ser negativo ou nula.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.vl_desc_pis,0) < 0 then
      --
      vn_fase := 3.7;
      --
      gv_resumo := '"Valor do desconto / exclusão da base de cálculo(VL_DESC_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.quant_bc_pis,0) < 0 then
      --
      vn_fase := 3.8;
      --
      gv_resumo := '"Base de cálculo em quantidade - PIS/PASEP(QUANT_BC_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.vl_pis,0) < 0 then
      --
      vn_fase := 3.9;
      --
      gv_resumo := '"Valor do PIS/PASEP(VL_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.vl_desc_cofins,0) < 0 then
      --
      vn_fase := 4;
      --
      gv_resumo := '"Valor do desconto / exclusão da base de cálculo(VL_DESC_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.quant_bc_cofins,0) < 0 then
      --
      vn_fase := 5;
      --
      gv_resumo := '"Base de cálculo em quantidade - COFINS(QUANT_BC_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consopinspcrcompaum.vl_cofins,0) < 0 then
      --
      vn_fase := 6;
      --
      gv_resumo := '"Valor do COFINS(VL_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 7;
   --
   if nvl(est_row_consopinspcrcompaum.cfop_id,0) = 0 and en_cfop is not null then
      --
      vn_fase := 9;
      --
      gv_resumo := '"Código Fiscal de Operação - CFOP" informado está inválido. Código = '||en_cfop||'.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 10;
   --
   if nvl(est_row_consopinspcrcompaum.id, 0)             > 0 and
      nvl(vn_id,0)                                       > 0 and
      nvl(est_row_consopinspcrcompaum.empresa_id,0)      > 0 and
      nvl(est_row_consopinspcrcompaum.codst_id_pis,0)    > 0 and
      nvl(est_row_consopinspcrcompaum.codst_id_cofins,0) > 0 and
      trim(est_row_consopinspcrcompaum.dt_ref)           is not null and
      nvl(est_row_consopinspcrcompaum.vl_rec_comp,0)     > 0 then
      --
      vn_fase := 10.1;
      --
      begin
         pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
      exception
         when others then
            null;
      end;
      --
      vn_fase := 10.2;
      --
         insert into cons_op_ins_pcrcomp_aum ( id
                                             , empresa_id
                                             , dt_ref
                                             , vl_rec_comp
                                             , codst_id_pis
                                             , vl_desc_pis
                                             , quant_bc_pis
                                             , vl_aliq_pis
                                             , vl_pis
                                             , codst_id_cofins
                                             , vl_desc_cofins
                                             , quant_bc_cofins
                                             , vl_aliq_cofins
                                             , vl_cofins
                                             , modfiscal_id
                                             , planoconta_id
                                             , info_compl
                                             , dm_st_proc
                                             , dm_st_integra
                                             , cfop_id )
                                       values( est_row_consopinspcrcompaum.id
                                             , est_row_consopinspcrcompaum.empresa_id
                                             , est_row_consopinspcrcompaum.dt_ref
                                             , est_row_consopinspcrcompaum.vl_rec_comp
                                             , est_row_consopinspcrcompaum.codst_id_pis
                                             , est_row_consopinspcrcompaum.vl_desc_pis
                                             , est_row_consopinspcrcompaum.quant_bc_pis
                                             , est_row_consopinspcrcompaum.vl_aliq_pis
                                             , est_row_consopinspcrcompaum.vl_pis
                                             , est_row_consopinspcrcompaum.codst_id_cofins
                                             , est_row_consopinspcrcompaum.vl_desc_cofins
                                             , est_row_consopinspcrcompaum.quant_bc_cofins
                                             , est_row_consopinspcrcompaum.vl_aliq_cofins
                                             , est_row_consopinspcrcompaum.vl_cofins
                                             , est_row_consopinspcrcompaum.modfiscal_id
                                             , est_row_consopinspcrcompaum.planoconta_id
                                             , est_row_consopinspcrcompaum.info_compl
                                             , est_row_consopinspcrcompaum.dm_st_proc
                                             , est_row_consopinspcrcompaum.dm_st_integra
                                             , est_row_consopinspcrcompaum.cfop_id
                                             );
         --
         commit;
         --
      else
         --
         vn_fase := 10.4;
         --
         update cons_op_ins_pcrcomp_aum co set co.vl_rec_comp       = est_row_consopinspcrcompaum.vl_rec_comp
                                             , co.vl_desc_pis       = est_row_consopinspcrcompaum.vl_desc_pis
                                             , co.quant_bc_pis      = est_row_consopinspcrcompaum.quant_bc_pis
                                             , co.vl_aliq_pis       = est_row_consopinspcrcompaum.vl_aliq_pis
                                             , co.vl_pis            = est_row_consopinspcrcompaum.vl_pis
                                             , co.vl_desc_cofins    = est_row_consopinspcrcompaum.vl_desc_cofins
                                             , co.quant_bc_cofins   = est_row_consopinspcrcompaum.quant_bc_cofins
                                             , co.vl_aliq_cofins    = est_row_consopinspcrcompaum.vl_aliq_cofins
                                             , co.vl_cofins         = est_row_consopinspcrcompaum.vl_cofins
                                             , co.modfiscal_id      = est_row_consopinspcrcompaum.modfiscal_id
                                             , co.planoconta_id     = est_row_consopinspcrcompaum.planoconta_id
                                             , co.info_compl        = est_row_consopinspcrcompaum.info_compl
                                             , co.dm_st_proc        = est_row_consopinspcrcompaum.dm_st_proc
                                             , co.dm_st_integra     = est_row_consopinspcrcompaum.dm_st_integra
                                             , co.cfop_id           = est_row_consopinspcrcompaum.cfop_id
                                         where co.id                = est_row_consopinspcrcompaum.id
                                           and co.dm_st_proc        not in (1); -- validada;
         --
         commit;
         --
      end if;
      --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_consopinspcrcompaum fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_consopinspcrcompaum;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela PR_CONS_OP_INS_PC_RCOMP
----------------------------------------------------------------------------------------------------
procedure pkb_integr_prconsopinspcrcomp( est_log_generico_ddo           in out nocopy dbms_sql.number_table
                                       , est_row_pr_cons_op_ins_pcrcomp in out nocopy pr_cons_op_ins_pc_rcomp%rowtype
                                       , ev_cpf_cnpj                    in            varchar2
                                       , en_cd_orig                     in            number
                                       ) is
   --
   vn_fase                      number := null;
   vn_loggenerico_id            log_generico_ddo.id%type;
   vn_id                        pr_cons_op_ins_pc_rcomp.id%type := null;
   vn_prconsopinspcrcomp_id     pr_cons_op_ins_pc_rcomp.id%type := null;
   vn_dm_st_proc                number(1) := null;
   --
begin
   --
   vn_fase := 1;
   --
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cpf_cnpj;
   gv_mensagem := gv_mensagem || chr(10);
   gv_mensagem := gv_mensagem || ' Rotina - registros(F559)';
   -- Recebe o id da tabela pai, pq é essa tabela q a tela busca como objetos de referencia
   gn_referencia_id := est_row_pr_cons_op_ins_pcrcomp.consoperinspcrcomp_id;
   --
   if gv_obj_referencia is null then gv_obj_referencia := 'CONS_OPER_INS_PC_RCOMP'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_prconsopinspcrcomp
   if nvl(est_row_pr_cons_op_ins_pcrcomp.origproc_id,0) = 0 then
      est_row_pr_cons_op_ins_pcrcomp.origproc_id := pk_csf.fkg_Orig_Proc_id( en_cd => en_cd_orig );
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_prconsopinspcrcomp( en_consoperinspcrcomp_id => est_row_pr_cons_op_ins_pcrcomp.consoperinspcrcomp_id
                                       , en_origproc_id           => est_row_pr_cons_op_ins_pcrcomp.origproc_id
                                       , sn_prconsopinspcrcomp_id => vn_prconsopinspcrcomp_id
                                       , sn_dm_st_proc            => vn_dm_st_proc );
      --
   exception
      when others then
         vn_prconsopinspcrcomp_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.2;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_pr_cons_op_ins_pcrcomp.id,0) <= 0 and nvl(vn_prconsopinspcrcomp_id,0) <= 0 then
      -- pr_cons_op_ins_pc_rcomp
      select prconsopinspcrcomp_seq.nextval
        into est_row_pr_cons_op_ins_pcrcomp.id
        from dual;
      --
      vn_id := est_row_pr_cons_op_ins_pcrcomp.id;
      --
   elsif nvl(est_row_pr_cons_op_ins_pcrcomp.id,0) <= 0 and nvl(vn_prconsopinspcrcomp_id,0) > 0 then
      --
      est_row_pr_cons_op_ins_pcrcomp.id := vn_prconsopinspcrcomp_id;
      --
   elsif nvl(est_row_pr_cons_op_ins_pcrcomp.id,0) > 0 and nvl(est_row_pr_cons_op_ins_pcrcomp.id,0) <> nvl(vn_prconsopinspcrcomp_id,0) then
       --
       vn_fase := 1.3;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_pr_cons_op_ins_pcrcomp.id||') está diferente do id encontrado '||vn_prconsopinspcrcomp_id||' para o registro na tabela PR_CONS_OP_INS_PC_RCOMP.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   vn_fase := 1.4;
   --
   if nvl(est_row_pr_cons_op_ins_pcrcomp.origproc_id, 0) = 0 and en_cd_orig is not null then
      --
         vn_fase := 1.41;
         --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Origem do Processo não encontrado na base Compliance:" ('|| en_cd_orig ||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   elsif nvl(est_row_pr_cons_op_ins_pcrcomp.origproc_id, 0) = 0 then
      --
      vn_fase := 1.42;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Código da Origem do Processo não informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.5;
   --
   if trim(est_row_pr_cons_op_ins_pcrcomp.num_proc) is null then
      --
      vn_fase := 1.6;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Identificação do processo ou ato concessório não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.7;
   --
   if nvl(est_row_pr_cons_op_ins_pcrcomp.id, 0)                   > 0 and
      nvl(vn_id,0)                                                > 0 and
      nvl(est_row_pr_cons_op_ins_pcrcomp.consoperinspcrcomp_id,0) > 0 and
      nvl(est_row_pr_cons_op_ins_pcrcomp.origproc_id,0)           > 0 and
      trim(est_row_pr_cons_op_ins_pcrcomp.num_proc)              is not null then
       --
       vn_fase := 1.8;
       --
          insert into pr_cons_op_ins_pc_rcomp ( id
                                              , consoperinspcrcomp_id
                                              , num_proc
                                              , origproc_id )
                                        values( est_row_pr_cons_op_ins_pcrcomp.id
                                              , est_row_pr_cons_op_ins_pcrcomp.consoperinspcrcomp_id
                                              , est_row_pr_cons_op_ins_pcrcomp.num_proc
                                              , est_row_pr_cons_op_ins_pcrcomp.origproc_id
                                              );
          --
          commit;
          --
       else
          --
          vn_fase := 3;
          --
          update pr_cons_op_ins_pc_rcomp
             set num_proc   = est_row_pr_cons_op_ins_pcrcomp.num_proc
           where id         = est_row_pr_cons_op_ins_pcrcomp.id;
          --
          commit;
          --
       end if;
       --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_prconsopinspcrcomp fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_prconsopinspcrcomp;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CONS_OPER_INS_PC_RCOMP - F550
----------------------------------------------------------------------------------------------------
procedure pkb_integr_consoperinspcrcomp ( est_log_generico_ddo          in out nocopy dbms_sql.number_table
                                        , est_row_consoperinspcrcomp    in out nocopy cons_oper_ins_pc_rcomp%rowtype
                                        , ev_cnpj_empr                  in            varchar2
                                        , en_multorg_id                 in            mult_org.id%type
                                        , ev_cod_st_pis                 in            varchar2
                                        , ev_cod_st_cofins              in            varchar2
                                        , ev_cod_mod                    in            varchar2
                                        , ev_cod_cta                    in            varchar2
                                        , en_cfop                       in            number
                                        ) is
   --
   vn_fase                  number := null;
   vn_loggenerico_id        log_generico_ddo.id%type;
   vn_id                    cons_oper_ins_pc_rcomp.id%type := null;
   vn_consoperinspcrcomp_id cons_oper_ins_pc_rcomp.id%type := null;
   vn_dm_st_proc            cons_oper_ins_pc_rcomp.dm_st_proc%type := null;
   --
begin
   --
   vn_fase := 1;
   --
   est_row_consoperinspcrcomp.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj( en_multorg_id => en_multorg_id
                                                                               , ev_cpf_cnpj   => ev_cnpj_empr
                                                                               );
   --
   vn_fase := 1.1;
   --
   --| Montar o cabeçalho do log
   gv_mensagem       := null;
   gv_mensagem       := 'Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa(en_empresa_id => est_row_consoperinspcrcomp.empresa_id);
   gv_mensagem       := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'CONS_OPER_INS_PC_RCOMP'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_consoperinspcrcomp
   if nvl(est_row_consoperinspcrcomp.codst_id_pis,0) = 0 then
      est_row_consoperinspcrcomp.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                      , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
   end if;
   --
   if nvl(est_row_consoperinspcrcomp.codst_id_cofins,0) = 0 then
      est_row_consoperinspcrcomp.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                         , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS
   end if;
   --
   if nvl(est_row_consoperinspcrcomp.modfiscal_id,0) = 0 then
      est_row_consoperinspcrcomp.modfiscal_id := pk_csf_ddo.fkg_cod_mod_modfiscal_id( ev_cod_mod  => ev_cod_mod );
   end if;
   --
   if nvl(est_row_consoperinspcrcomp.planoconta_id,0) = 0 then
      est_row_consoperinspcrcomp.planoconta_id := pk_csf.fkg_Plano_Conta_id ( ev_cod_cta    =>  ev_cod_cta
                                                                            , en_empresa_id =>  est_row_consoperinspcrcomp.empresa_id );
   end if;
   --
   if nvl(est_row_consoperinspcrcomp.cfop_id,0) = 0 then
      est_row_consoperinspcrcomp.cfop_id := pk_csf.fkg_cfop_id ( en_cd => en_cfop ); -- se o valor for nulo ou não for válido, a função retorna NULL
   end if;
   --
   -- Se a data fechamento não foi carregada busca a data para validação
   if pk_int_view_ddo.gd_dt_ult_fecha is null then
      --
      pk_int_view_ddo.gd_dt_ult_fecha := pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id   => est_row_consoperinspcrcomp.empresa_id
                                                                             , en_objintegr_id => pk_csf.fkg_recup_objintegr_id( ev_cd => '50' )); -- Demais Documentos e Operações - Bloco F EFD Contribuições
      --
   end if ;
   --
   vn_fase := 1.2;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_consoperinspcrcomp ( en_empresa_id          => est_row_consoperinspcrcomp.empresa_id
                                        , ed_dt_ref              => est_row_consoperinspcrcomp.dt_ref
                                        , en_codst_id_pis        => est_row_consoperinspcrcomp.codst_id_pis
                                        , en_aliq_pis            => est_row_consoperinspcrcomp.aliq_pis
                                        , en_codst_id_cofins     => est_row_consoperinspcrcomp.codst_id_cofins
                                        , en_aliq_cofins         => est_row_consoperinspcrcomp.aliq_cofins
                                        , en_modfiscal_id        => est_row_consoperinspcrcomp.modfiscal_id
                                        , en_planoconta_id       => est_row_consoperinspcrcomp.planoconta_id
                                        , ev_info_compl          => est_row_consoperinspcrcomp.info_compl
                                        , en_cfop_id             => est_row_consoperinspcrcomp.cfop_id
                                        , sn_consoperinspcrcomp_id => vn_consoperinspcrcomp_id
                                        , sn_dm_st_proc            => vn_dm_st_proc );
      --
   exception
      when others then
         vn_consoperinspcrcomp_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.3;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_consoperinspcrcomp.id,0) <= 0 and nvl(vn_consoperinspcrcomp_id,0) <= 0 then
      -- cons_oper_ins_pc_rcomp
      select consoperinspcrcomp_seq.nextval
        into est_row_consoperinspcrcomp.id
        from dual;
      --
      vn_id := est_row_consoperinspcrcomp.id;
      --
   elsif nvl(est_row_consoperinspcrcomp.id,0) <= 0 and nvl(vn_consoperinspcrcomp_id,0) > 0 then
      --
      est_row_consoperinspcrcomp.id := vn_consoperinspcrcomp_id;
      --
   elsif nvl(est_row_consoperinspcrcomp.id,0) > 0 and nvl(est_row_consoperinspcrcomp.id,0) <> nvl(vn_consoperinspcrcomp_id,0) then
       --
       vn_fase := 1.4;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_consoperinspcrcomp.id||') está diferente do id encontrado '||vn_consoperinspcrcomp_id||' para o registro na tabela CONS_OPER_INS_PC_RCOMP.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_consoperinspcrcomp.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   gn_referencia_id := est_row_consoperinspcrcomp.id;
   --
   vn_fase := 1.5;
   --| Validar Registros
   if nvl(est_row_consoperinspcrcomp.empresa_id,0) <= 0 then
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da empresa não encontrado na base Compliance, ou não informado:" ('||trim(ev_cnpj_empr)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.51;
   --
   if nvl(est_row_consoperinspcrcomp.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
      --
      vn_fase := 1.52;
      --
         gv_resumo := '"Código da Situação Tributaria do Imposto PIS não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_consoperinspcrcomp.codst_id_pis,0) = 0 then
      --
      vn_fase := 1.8;
      --
      gv_resumo := '"Código da Situação Tributaria do Imposto PIS não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2;
   --
   if nvl(est_row_consoperinspcrcomp.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
      vn_fase := 2.1;
      --
         gv_resumo := '"Código da Situação Tributaria do Imposto COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_consoperinspcrcomp.codst_id_cofins,0) = 0 then
      --
      vn_fase := 2.4;
      --
      gv_resumo := 'Código da Situação Tributaria do Imposto COFINS não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.5;
   --
   if nvl(est_row_consoperinspcrcomp.modfiscal_id,0) = 0 and trim(ev_cod_mod) is not null then
      --
      vn_fase := 2.6;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Modelo de Documento Fiscal não encontrado, favor verificar o código: " ('||trim(ev_cod_mod)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.9;
   --
   if nvl(est_row_consoperinspcrcomp.planoconta_id,0) = 0 and trim(ev_cod_cta) is not null then
      --
      vn_fase := 3;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código do plano de conta não encontrado na base compliance" ('||trim(ev_cod_cta)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.3;
   --
   if nvl(est_row_consoperinspcrcomp.aliq_pis,0) < 0 then
      --
      vn_fase := 3.4;
      --
      gv_resumo := '"Alíquota do PIS/PASEP em percentual(ALIQ_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.5;
   --
   if nvl(est_row_consoperinspcrcomp.aliq_cofins,0) < 0 then
      --
      vn_fase := 3.6;
      --
      gv_resumo := '"Alíquota do COFINS em percentual(ALIQ_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.7;
   --
   if nvl(est_row_consoperinspcrcomp.vl_rec_comp,0) <= 0 then
      --
      vn_fase := 3.8;
      --
      gv_resumo := '"Valor total da receita auferida, ref. à comb. de CST e Alíq.(vl_rec_comp)" Não pode ser negativo ou nulo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.9;
   --
   if nvl(est_row_consoperinspcrcomp.vl_desc_pis,0) < 0 then
      --
      vn_fase := 3.10;
      --
      gv_resumo := '"Valor do desconto / exclusão da base de cálculo(VL_DESC_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4;
   --
   if nvl(est_row_consoperinspcrcomp.vl_bc_pis,0) < 0 then
      --
      vn_fase := 4.1;
      --
      gv_resumo := '"Valor da base de cálculo do PIS/PASEP(VL_BC_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.2;
   --
   if nvl(est_row_consoperinspcrcomp.vl_pis,0) < 0 then
      --
      vn_fase := 4.3;
      --
      gv_resumo := '"Valor do PIS/PASEP(VL_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.4;
   --
   if nvl(est_row_consoperinspcrcomp.vl_desc_cofins,0) < 0 then
      --
      vn_fase := 4.5;
      --
      gv_resumo := '"Valor do desconto / exclusão da base de cálculo(VL_DESC_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.6;
   --
   if nvl(est_row_consoperinspcrcomp.vl_bc_cofins,0) < 0 then
      --
      vn_fase := 4.7;
      --
      gv_resumo := '"Valor da base de cálculo do COFINS(VL_BC_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.8;
   --
   if nvl(est_row_consoperinspcrcomp.vl_cofins,0) < 0 then
      --
      vn_fase := 4.9;
      --
      gv_resumo := '"Valor do COFINS(VL_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.10;
   --
   if nvl(est_row_consoperinspcrcomp.cfop_id,0) = 0 and en_cfop is not null then
      --
      vn_fase := 4.12;
      --
      gv_resumo := '"Código Fiscal de Operação - CFOP" informado está inválido. Código = '||en_cfop||'.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5;
   --
   if (pk_int_view_ddo.gd_dt_ult_fecha is null) or (trunc( est_row_consoperinspcrcomp.dt_ref ) < pk_int_view_ddo.gd_dt_ult_fecha) then
     --
     gv_resumo := null;
     --
     gv_resumo := 'Período informado para integração de Demais Documentos e Operações - Bloco F EFD-'||
                  'Contribuições (Bloco F550), está fechado para a data do registro. Data de fechamento fiscal '||
                  to_char(pk_int_view_ddo.gd_dt_ult_fecha,'dd/mm/yyyy')||' - CNPJ/CPF: '||ev_cnpj_empr||'.';
     --
     vn_loggenerico_id := null;
     --
     pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                          ev_mensagem          => gv_mensagem,
                          ev_resumo            => gv_resumo,
                          en_tipo_log          => erro_de_validacao,
                          en_referencia_id     => gn_referencia_id,
                          ev_obj_referencia    => gv_obj_referencia,
                          en_empresa_id        => gn_empresa_id
                          );
     --
     -- Armazena o "loggenerico_id" na memória
     pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                             est_log_generico_ddo => est_log_generico_ddo);
     --
   end if;
   --
   vn_fase := 99;
   --
   if nvl(est_row_consoperinspcrcomp.id, 0)             > 0 and
      nvl(vn_id,0)                                      > 0 and
      nvl(est_row_consoperinspcrcomp.empresa_id,0)      > 0 and
      trim(est_row_consoperinspcrcomp.dt_ref)           is not null and
      nvl(est_row_consoperinspcrcomp.codst_id_pis,0)    >  0 and
      nvl(est_row_consoperinspcrcomp.codst_id_cofins,0) >  0 and
      nvl(est_row_consoperinspcrcomp.vl_rec_comp,0)     >  0 then
      --
      vn_fase := 5.1;
      --
      begin
         pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
      exception
         when others then
            null;
      end;
      --
      vn_fase := 5.2;
      --
      insert into cons_oper_ins_pc_rcomp ( id
                                             , empresa_id
                                             , dt_ref
                                             , vl_rec_comp
                                             , codst_id_pis
                                             , vl_desc_pis
                                             , vl_bc_pis
                                             , aliq_pis
                                             , vl_pis
                                             , codst_id_cofins
                                             , vl_desc_cofins
                                             , vl_bc_cofins
                                             , aliq_cofins
                                             , vl_cofins
                                             , modfiscal_id
                                             , planoconta_id
                                             , info_compl
                                             , dm_st_proc
                                             , dm_st_integra
                                             , cfop_id )
                                       values( est_row_consoperinspcrcomp.id
                                             , est_row_consoperinspcrcomp.empresa_id
                                             , est_row_consoperinspcrcomp.dt_ref
                                             , est_row_consoperinspcrcomp.vl_rec_comp
                                             , est_row_consoperinspcrcomp.codst_id_pis
                                             , est_row_consoperinspcrcomp.vl_desc_pis
                                             , est_row_consoperinspcrcomp.vl_bc_pis
                                             , est_row_consoperinspcrcomp.aliq_pis
                                             , est_row_consoperinspcrcomp.vl_pis
                                             , est_row_consoperinspcrcomp.codst_id_cofins
                                             , est_row_consoperinspcrcomp.vl_desc_cofins
                                             , est_row_consoperinspcrcomp.vl_bc_cofins
                                             , est_row_consoperinspcrcomp.aliq_cofins
                                             , est_row_consoperinspcrcomp.vl_cofins
                                             , est_row_consoperinspcrcomp.modfiscal_id
                                             , est_row_consoperinspcrcomp.planoconta_id
                                             , est_row_consoperinspcrcomp.info_compl
                                             , est_row_consoperinspcrcomp.dm_st_proc
                                             , est_row_consoperinspcrcomp.dm_st_integra
                                             , est_row_consoperinspcrcomp.cfop_id
                                             );
          --
          commit;
          --
       else
          --
          vn_fase := 5.5;
          --
          update cons_oper_ins_pc_rcomp co
             set co.vl_desc_pis       = est_row_consoperinspcrcomp.vl_desc_pis
               , co.vl_bc_pis         = est_row_consoperinspcrcomp.vl_bc_pis
               , co.aliq_pis          = est_row_consoperinspcrcomp.aliq_pis
               , co.vl_pis            = est_row_consoperinspcrcomp.vl_pis
               , co.codst_id_cofins   = est_row_consoperinspcrcomp.codst_id_cofins
               , co.vl_desc_cofins    = est_row_consoperinspcrcomp.vl_desc_cofins
               , co.vl_bc_cofins      = est_row_consoperinspcrcomp.vl_bc_cofins
               , co.aliq_cofins       = est_row_consoperinspcrcomp.aliq_cofins
               , co.vl_cofins         = est_row_consoperinspcrcomp.vl_cofins
               , co.modfiscal_id      = est_row_consoperinspcrcomp.modfiscal_id
               , co.planoconta_id     = est_row_consoperinspcrcomp.planoconta_id
               , co.info_compl        = est_row_consoperinspcrcomp.info_compl
               , co.dm_st_proc        = est_row_consoperinspcrcomp.dm_st_proc
               , co.dm_st_integra     = est_row_consoperinspcrcomp.dm_st_integra
               , co.cfop_id           = est_row_consoperinspcrcomp.cfop_id
           where co.id                = est_row_consoperinspcrcomp.id
             and co.dm_st_proc        not in (1); -- validada
          --
          commit;
          --
       end if;
    --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_consoperinspcrcomp fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_consoperinspcrcomp;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela COMP_REC_DET_RC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_comp_rec_det_rc ( est_log_generico_ddo     in out nocopy dbms_sql.number_table
                                     , est_row_comp_rec_det_rc  in out nocopy comp_rec_det_rc%rowtype
                                     , ev_cnpj_empr             in            varchar2
                                     , en_multorg_id            in            mult_org.id%type
                                     , ev_cod_part              in            varchar2
                                     , ev_cod_item              in            varchar2
                                     , ev_cod_st_pis            in            varchar2
                                     , ev_cod_st_cofins         in            varchar2
                                     , ev_cod_cta               in            varchar2
                                     ) is
   --
   vn_fase            number                  := null;
   vn_loggenerico_id  log_generico_ddo.id%type;
   vn_id              comp_rec_det_rc.id%type := null;
   vn_comprecdetrc_id comp_rec_det_rc.id%type := null;
   vn_dm_st_proc      comp_rec_det_rc.dm_st_proc%type := null;
   --
begin
   --
   vn_fase := 1;
   --
   est_row_comp_rec_det_rc.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj( en_multorg_id => en_multorg_id
                                                                            , ev_cpf_cnpj   => ev_cnpj_empr
                                                                            );
   --
   vn_fase := 1.1;
   --
   --| Montar o cabeçalho do log
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa(en_empresa_id => est_row_comp_rec_det_rc.empresa_id);
   gv_mensagem := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'COMP_REC_DET_RC'; end if;
   --
   vn_fase := 1.2;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_comprecdetrc
   if nvl(est_row_comp_rec_det_rc.pessoa_id,0) = 0 then
      est_row_comp_rec_det_rc.pessoa_id := pk_csf_ddo.fkb_cod_part_pessoa_id ( ev_cod_part => ev_cod_part);
   end if;
   --
   if nvl(est_row_comp_rec_det_rc.item_id,0) = 0 then
      est_row_comp_rec_det_rc.item_id := pk_csf.fkg_Item_id_conf_empr ( en_empresa_id  => est_row_comp_rec_det_rc.empresa_id
                                                                   , ev_cod_item    => ev_cod_item  );
   end if;
   --
   if nvl(est_row_comp_rec_det_rc.codst_id_pis,0) = 0 then
      est_row_comp_rec_det_rc.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
   end if;
   --
   if nvl(est_row_comp_rec_det_rc.codst_id_cofins,0) = 0 then
      est_row_comp_rec_det_rc.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                   , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS
   end if;
   --
   if nvl(est_row_comp_rec_det_rc.planoconta_id,0) = 0 then
      est_row_comp_rec_det_rc.planoconta_id := pk_csf.fkg_Plano_Conta_id ( ev_cod_cta    =>  ev_cod_cta
                                                                      , en_empresa_id =>  est_row_comp_rec_det_rc.empresa_id );
   end if;
   --
   -- Se a data fechamento não foi carregada busca a data para validação
   if pk_int_view_ddo.gd_dt_ult_fecha is null then
      --
      pk_int_view_ddo.gd_dt_ult_fecha := pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id   => est_row_comp_rec_det_rc.empresa_id
                                                                             , en_objintegr_id => pk_csf.fkg_recup_objintegr_id( ev_cd => '50' )); -- Demais Documentos e Operações - Bloco F EFD Contribuições
      --
   end if ;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_comprecdetrc ( en_empresa_id          => est_row_comp_rec_det_rc.empresa_id
                                  , ed_dt_ref              => est_row_comp_rec_det_rc.dt_ref
                                  , en_dm_ind_rec          => est_row_comp_rec_det_rc.dm_ind_rec
                                  , en_pessoa_id           => est_row_comp_rec_det_rc.pessoa_id
                                  , ev_num_doc             => est_row_comp_rec_det_rc.num_doc
                                  , en_item_id             => est_row_comp_rec_det_rc.item_id
                                  , en_codst_id_pis        => est_row_comp_rec_det_rc.codst_id_pis
                                  , en_codst_id_cofins     => est_row_comp_rec_det_rc.codst_id_cofins
                                  , en_planoconta_id       => est_row_comp_rec_det_rc.planoconta_id
                                  , ev_info_compl          => est_row_comp_rec_det_rc.info_compl
                                  , sn_comprecdetrc_id     => vn_comprecdetrc_id
                                  , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_comprecdetrc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.3;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_comp_rec_det_rc.id,0) <= 0 and nvl(vn_comprecdetrc_id,0) <= 0 then
      -- comp_rec_det_rc
      select comprecdetrc_seq.nextval
        into est_row_comp_rec_det_rc.id
        from dual;
      --
      vn_id := est_row_comp_rec_det_rc.id;
      --
   elsif nvl(est_row_comp_rec_det_rc.id,0) <= 0 and nvl(vn_comprecdetrc_id,0) > 0 then
      --
      est_row_comp_rec_det_rc.id := vn_comprecdetrc_id;
      --
   elsif nvl(est_row_comp_rec_det_rc.id,0) > 0 and nvl(est_row_comp_rec_det_rc.id,0) <> nvl(vn_comprecdetrc_id,0) then
       --
       vn_fase := 1.4;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_comp_rec_det_rc.id||') está diferente do id encontrado '||vn_comprecdetrc_id||' para o registro na tabela COMP_REC_DET_RC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_comp_rec_det_rc.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   gn_referencia_id := est_row_comp_rec_det_rc.id;
   --
   vn_fase := 1.5;
   --| Validar Registros
   if nvl(est_row_comp_rec_det_rc.empresa_id,0) <= 0 then
     --
     vn_fase := 1.6;
     --
     gv_resumo := null;
     --
     gv_resumo := '"CNPJ da empresa não encontrado na base Compliance, ou não foi informado:" ('||trim(ev_cnpj_empr)||').';
     --
     vn_loggenerico_id := null;
     --
     pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                          , ev_mensagem          => gv_mensagem
                          , ev_resumo            => gv_resumo
                          , en_tipo_log          => erro_de_validacao
                          , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );

     --
     -- Armazena o "loggenerico_id" na memória
     pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                             , est_log_generico_ddo => est_log_generico_ddo );
     --
   end if;
   --
   vn_fase := 1.61;
   --
   -- ev_cod_part - não obrigatório
   if nvl(est_row_comp_rec_det_rc.pessoa_id,0) = 0 and trim(ev_cod_part) is not null then
      --
      vn_fase := 1.62;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código do participante cliente/fornecedor" não encontrado na base Compliance, favor verificar: ('||ev_cod_part||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   end if;
   --
   vn_fase := 1.8;
   --
   if nvl(est_row_comp_rec_det_rc.item_id,0) = 0 and trim(ev_cod_item) is not null then
      --
      vn_fase := 1.9;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código do item não encontrado na base Compliance:" ('||trim(ev_cod_item)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.1;
   --
   if nvl(est_row_comp_rec_det_rc.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
      --
      vn_fase := 2.2;
      --
         gv_resumo := '"Código da Situação Tributaria do Imposto PIS não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_comp_rec_det_rc.codst_id_pis,0) = 0 then
      --
      vn_fase := 2.3;
      --
      gv_resumo := 'Código da Situação Tributaria do Imposto PIS não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.4;
   --
   if nvl(est_row_comp_rec_det_rc.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
      vn_fase := 2.5;
      --
         gv_resumo := '"Código da Situação Tributaria do Imposto COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_comp_rec_det_rc.codst_id_cofins,0) = 0 then
      --
      vn_fase := 2.6;
      --
         gv_resumo := 'Código da Situação Tributaria do Imposto COFINS não informado, informação obrigatória.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.8;
   --
   if nvl(est_row_comp_rec_det_rc.planoconta_id,0) = 0 and trim(ev_cod_cta) is not null then
      --
      vn_fase := 2.9;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código do plano de conta não encontrado na base compliance" ('||trim(ev_cod_cta)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.2;
   --
   if nvl(est_row_comp_rec_det_rc.vl_rec,0) <= 0 then
      --
      vn_fase := 3.3;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Valor total da receita recebida(VL_REC)" não pode ser negativa ou nula.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.4;
   --
   if nvl(est_row_comp_rec_det_rc.vl_rec_det,0) < 0 then
       --
       vn_fase := 3.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"Valor da receita detalhada(VL_REC_DET)" não pode ser negativa.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.6;
   --
   if nvl(est_row_comp_rec_det_rc.dm_ind_rec,0) not in (1,2,3,4,5,99,00) then
      --
      vn_fase := 3.7;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Indicador da composição da receita recebida no período(DM_IND_REC)" informado incorretamente:('||est_row_comp_rec_det_rc.dm_ind_rec||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
     --
   end if;
   --
   vn_fase := 3.8;
   --
   if (pk_int_view_ddo.gd_dt_ult_fecha is null) or (trunc( est_row_comp_rec_det_rc.dt_ref ) < pk_int_view_ddo.gd_dt_ult_fecha) then
     --
     gv_resumo := null;
     --
     gv_resumo := 'Período informado para integração de Demais Documentos e Operações - Bloco F EFD-'||
                  'Contribuições (Bloco F525), está fechado para a data do registro. Data de fechamento fiscal '||
                  to_char(pk_int_view_ddo.gd_dt_ult_fecha,'dd/mm/yyyy')||' - CNPJ/CPF: '||ev_cnpj_empr||'.';
     --
     vn_loggenerico_id := null;
     --
     pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                          ev_mensagem          => gv_mensagem,
                          ev_resumo            => gv_resumo,
                          en_tipo_log          => erro_de_validacao,
                          en_referencia_id     => gn_referencia_id,
                          ev_obj_referencia    => gv_obj_referencia,
                          en_empresa_id        => gn_empresa_id
                           );
     --
     -- Armazena o "loggenerico_id" na memória
     pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                             est_log_generico_ddo => est_log_generico_ddo);
     --
   end if;
   --
   vn_fase := 99;
   --
   if nvl(est_row_comp_rec_det_rc.id, 0)              > 0 and
      nvl(vn_id,0)                                    > 0 and
      nvl(est_row_comp_rec_det_rc.empresa_id,0)       > 0 and
      trim(est_row_comp_rec_det_rc.dt_ref)            is not null and
      nvl(est_row_comp_rec_det_rc.dm_ind_rec,0)       in (1,2,3,4,5,99,10) and
      nvl(est_row_comp_rec_det_rc.vl_rec,0)           > 0 then
      --
      vn_fase := 99.1;
      --
      begin
         pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
      exception
         when others then
            null;
      end;
      --
      vn_fase := 99.2;
      --
      insert into comp_rec_det_rc ( id
                                  , empresa_id
                                  , dt_ref
                                  , vl_rec
                                  , dm_ind_rec
                                  , pessoa_id
                                  , num_doc
                                  , item_id
                                  , vl_rec_det
                                  , codst_id_pis
                                  , codst_id_cofins
                                  , planoconta_id
                                  , info_compl
                                  , dm_st_proc
                                  , dm_st_integra )
                            values( est_row_comp_rec_det_rc.id
                                  , est_row_comp_rec_det_rc.empresa_id
                                  , est_row_comp_rec_det_rc.dt_ref
                                  , est_row_comp_rec_det_rc.vl_rec
                                  , est_row_comp_rec_det_rc.dm_ind_rec
                                  , est_row_comp_rec_det_rc.pessoa_id
                                  , est_row_comp_rec_det_rc.num_doc
                                  , est_row_comp_rec_det_rc.item_id
                                  , est_row_comp_rec_det_rc.vl_rec_det
                                  , est_row_comp_rec_det_rc.codst_id_pis
                                  , est_row_comp_rec_det_rc.codst_id_cofins
                                  , est_row_comp_rec_det_rc.planoconta_id
                                  , est_row_comp_rec_det_rc.info_compl
                                  , est_row_comp_rec_det_rc.dm_st_proc
                                  , est_row_comp_rec_det_rc.dm_st_integra
                                  );
       --
       commit;
       --
   else
      --
      vn_fase := 99.3;
      --
      update comp_rec_det_rc cr
         set cr.vl_rec           = est_row_comp_rec_det_rc.vl_rec
           , cr.num_doc          = est_row_comp_rec_det_rc.num_doc
           , cr.item_id          = est_row_comp_rec_det_rc.item_id
           , cr.vl_rec_det       = est_row_comp_rec_det_rc.vl_rec_det
           , cr.codst_id_pis     = est_row_comp_rec_det_rc.codst_id_pis
           , cr.codst_id_cofins  = est_row_comp_rec_det_rc.codst_id_cofins
           , cr.planoconta_id    = est_row_comp_rec_det_rc.planoconta_id
           , cr.info_compl       = est_row_comp_rec_det_rc.info_compl
           , cr.dm_st_proc       = est_row_comp_rec_det_rc.dm_st_proc
           , cr.dm_st_integra    = est_row_comp_rec_det_rc.dm_st_integra
       where cr.id               = est_row_comp_rec_det_rc.id
         and cr.dm_st_proc       not in (1); -- validado
      --
      commit;
      --
    end if;
    --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_comp_rec_det_rc fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_comp_rec_det_rc;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela PR_CONS_OP_INS_PCRC_AUM
----------------------------------------------------------------------------------------------------
procedure pkb_integr_prconsopinspcrcaum(est_log_generico_ddo       in out nocopy dbms_sql.number_table,
                                        est_row_prconsopinspcrcaum in out nocopy pr_cons_op_ins_pcrc_aum%rowtype,
                                        ev_cpf_cnpj                in varchar2,
                                        en_cd_orig                 in number) is
  --
  vn_fase                  number := null;
  vn_loggenerico_id        log_generico_ddo.id%type;
  vn_id                    pr_cons_op_ins_pcrc_aum.id%type := null;
  vn_prconsopinspcrcaum_id pr_cons_op_ins_pcrc_aum.id%type := null;
  vn_dm_st_proc            number(1) := null;
  --
begin
  --
  vn_fase := 1;
  --
  gv_mensagem       := null;
  gv_mensagem       := 'Empresa: ' || ev_cpf_cnpj;
  gv_mensagem       := gv_mensagem || chr(10);
  -- Recebe o id da tabela pai, pq é essa tabela q a tela busca como objetos de referencia
  gn_referencia_id := est_row_prconsopinspcrcaum.consoperinspcrcaum_id;
  --
  if gv_obj_referencia is null then gv_obj_referencia := 'CONS_OPER_INS_PC_RC_AUM'; end if;
  --
  -- Buscando dados para usar na procedure pk_csf_ddo.pkb_prconsopinspcrcaum
  if nvl(est_row_prconsopinspcrcaum.origproc_id,0) = 0 then
     est_row_prconsopinspcrcaum.origproc_id := pk_csf.fkg_Orig_Proc_id(en_cd => en_cd_orig);
  end if;
  --
  -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_prconsopinspcrcaum ( en_consoperinspcrcaum_id => est_row_prconsopinspcrcaum.consoperinspcrcaum_id
                                        , en_origproc_id           => est_row_prconsopinspcrcaum.origproc_id
                                        , sn_prconsopinspcrcaum_id => vn_prconsopinspcrcaum_id
                                        , sn_dm_st_proc            => vn_dm_st_proc );
      --
   exception
      when others then
         vn_prconsopinspcrcaum_id := null;
         vn_dm_st_proc            := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_prconsopinspcrcaum.id,0) <= 0 and nvl(vn_prconsopinspcrcaum_id,0) <= 0 then
      -- pr_cons_op_ins_pcrc_aum
      select prconsopinspcrcaum_seq.nextval
        into est_row_prconsopinspcrcaum.id
        from dual;
      --
      vn_id := est_row_prconsopinspcrcaum.id;
      --
   elsif nvl(est_row_prconsopinspcrcaum.id,0) <= 0 and nvl(vn_prconsopinspcrcaum_id,0) > 0 then
      --
      est_row_prconsopinspcrcaum.id := vn_prconsopinspcrcaum_id;
      --
   elsif nvl(est_row_prconsopinspcrcaum.id,0) > 0 and nvl(est_row_prconsopinspcrcaum.id,0) <> nvl(vn_prconsopinspcrcaum_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_prconsopinspcrcaum.id||') está diferente do id encontrado '||vn_prconsopinspcrcaum_id||' para o registro na tabela PR_CONS_OP_INS_PCRC_AUM.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
  --
  vn_fase := 1.51;
  --
  if trim(est_row_prconsopinspcrcaum.num_proc) is null then
    --
    vn_fase := 1.52;
    --
    gv_resumo := null;
    --
    gv_resumo := '"Identificação do processo ou ato concessório" não pode ser nulo.';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                         );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 1.53;
  --
  if nvl(est_row_prconsopinspcrcaum.origproc_id, 0) = 0 and trim(en_cd_orig) is not null then
    --
    vn_fase := 1.54;
    --
      gv_resumo := null;
      --
      gv_resumo := '"Códigos da origem do processo referenciado" inválidor, favor verificar: (' || trim(en_cd_orig) || ').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );

      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
    --
  elsif nvl(est_row_prconsopinspcrcaum.origproc_id, 0) = 0 then
    --
    vn_fase := 1.55;
    --
    gv_resumo := null;
    --
    gv_resumo := '"Códigos da origem do processo referenciado" informação obrigatória, favor informar.';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 1.6;
  --
  if nvl(est_row_prconsopinspcrcaum.id, 0)                    > 0 and
     nvl(vn_id,0)                                             > 0 and
     nvl(est_row_prconsopinspcrcaum.consoperinspcrcaum_id, 0) > 0 and
     nvl(est_row_prconsopinspcrcaum.origproc_id, 0)           > 0 and
     trim(est_row_prconsopinspcrcaum.num_proc)                is not null then
    --
    vn_fase := 1.7;
    --
      insert into pr_cons_op_ins_pcrc_aum
        (id,
         consoperinspcrcaum_id,
         num_proc,
         origproc_id)
      values
        (est_row_prconsopinspcrcaum.id,
         est_row_prconsopinspcrcaum.consoperinspcrcaum_id,
         est_row_prconsopinspcrcaum.num_proc,
         est_row_prconsopinspcrcaum.origproc_id);
      --
      commit;
      --
    else
      --
      update pr_cons_op_ins_pcrc_aum
         set num_proc    = est_row_prconsopinspcrcaum.num_proc,
             origproc_id = est_row_prconsopinspcrcaum.origproc_id
       where id          = est_row_prconsopinspcrcaum.id;
      --
      commit;
      --
    end if;
    --
exception
  when others then
    --
    gv_resumo := null;
    --
    gv_resumo := 'Erro na pkb_integr_prconsopinspcrcaum fase (' || vn_fase || '): ' || sqlerrm;
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_sistema,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );

    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
end pkb_integr_prconsopinspcrcaum;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CONS_OPER_INS_PC_RC_AUM
----------------------------------------------------------------------------------------------------
procedure pkb_integr_consoperinspcrcaum ( est_log_generico_ddo         in out nocopy dbms_sql.number_table
                                        , est_row_consoperinspcrcaum   in out nocopy cons_oper_ins_pc_rc_aum%rowtype
                                        , ev_cnpj_empr                 in            varchar2
                                        , en_multorg_id                in            mult_org.id%type
                                        , ev_cod_st_pis                in            varchar2
                                        , ev_cod_st_cofins             in            varchar2
                                        , ev_cod_mod                   in            varchar2
                                        , ev_cod_cta                   in            varchar2
                                        , en_cfop                      in            number
                                        )is
   --
   vn_fase                  number := null;
   vn_loggenerico_id        log_generico_ddo.id%type;
   vn_id                    cons_oper_ins_pc_rc_aum.id%type := null;
   vn_consoperinspcrcaum_id cons_oper_ins_pc_rc_aum.id%type := null;
   vn_dm_st_proc            cons_oper_ins_pc_rc_aum.dm_st_proc%type := null;
   --
begin
   --
   vn_fase := 1;
   --
   est_row_consoperinspcrcaum.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj( en_multorg_id => en_multorg_id
                                                                               , ev_cpf_cnpj   => ev_cnpj_empr);
   --
   vn_fase := 1.1;
   --| Montar o cabeçalho do log
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa(en_empresa_id => est_row_consoperinspcrcaum.empresa_id);
   gv_mensagem := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'CONS_OPER_INS_PC_RC_AUM'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_consoperinspcrcaum
   if nvl(est_row_consoperinspcrcaum.codst_id_pis,0) = 0 then
      est_row_consoperinspcrcaum.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                      , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
   end if;
   --
   if nvl(est_row_consoperinspcrcaum.codst_id_cofins,0) = 0 then
      est_row_consoperinspcrcaum.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                         , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS
   end if;
   --
   if nvl(est_row_consoperinspcrcaum.modfiscal_id,0) = 0 then
      est_row_consoperinspcrcaum.modfiscal_id := pk_csf_ddo.fkg_cod_mod_modfiscal_id( ev_cod_mod  => ev_cod_mod );
   end if;
   --
   if nvl(est_row_consoperinspcrcaum.planoconta_id,0) = 0 then
      est_row_consoperinspcrcaum.planoconta_id := pk_csf.fkg_Plano_Conta_id ( ev_cod_cta    =>  ev_cod_cta
                                                                         , en_empresa_id =>  est_row_consoperinspcrcaum.empresa_id );
   end if;
   --
   if nvl(est_row_consoperinspcrcaum.cfop_id,0) = 0 then
      est_row_consoperinspcrcaum.cfop_id := pk_csf.fkg_cfop_id ( en_cd => en_cfop ); -- se o valor for nulo ou não for válido, a função retorna NULL
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_consoperinspcrcaum ( en_empresa_id          => est_row_consoperinspcrcaum.empresa_id
                                           , ed_dt_ref              => est_row_consoperinspcrcaum.dt_ref
                                           , en_codst_id_pis        => est_row_consoperinspcrcaum.codst_id_pis
                                           , en_vl_aliq_pis         => est_row_consoperinspcrcaum.vl_aliq_pis
                                           , en_codst_id_cofins     => est_row_consoperinspcrcaum.codst_id_cofins
                                           , en_vl_aliq_cofins      => est_row_consoperinspcrcaum.vl_aliq_cofins
                                           , en_modfiscal_id        => est_row_consoperinspcrcaum.modfiscal_id
                                           , en_planoconta_id       => est_row_consoperinspcrcaum.planoconta_id
                                           , ev_info_compl          => est_row_consoperinspcrcaum.info_compl
                                           , en_cfop_id             => est_row_consoperinspcrcaum.cfop_id
                                           , sn_consoperinspcrcaum_id => vn_consoperinspcrcaum_id
                                           , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_consoperinspcrcaum_id := null;
         vn_dm_st_proc            := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_consoperinspcrcaum.id,0) <= 0 and nvl(vn_consoperinspcrcaum_id,0) <= 0 then
      -- cons_oper_ins_pc_rc_aum
      select consoperinspcrcaum_seq.nextval
        into est_row_consoperinspcrcaum.id
        from dual;
      --
      vn_id := est_row_consoperinspcrcaum.id;
      --
   elsif nvl(est_row_consoperinspcrcaum.id,0) <= 0 and nvl(vn_consoperinspcrcaum_id,0) > 0 then
      --
      est_row_consoperinspcrcaum.id := vn_consoperinspcrcaum_id;
      --
   elsif nvl(est_row_consoperinspcrcaum.id,0) > 0 and nvl(est_row_consoperinspcrcaum.id,0) <> nvl(vn_consoperinspcrcaum_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_consoperinspcrcaum.id||') está diferente do id encontrado '||vn_consoperinspcrcaum_id||' para o registro na tabela CONS_OPER_INS_PC_RC_AUM.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_consoperinspcrcaum.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   gn_referencia_id := est_row_consoperinspcrcaum.id;
   --
   vn_fase := 1.51;
   --| Validar Registros
   if nvl(est_row_consoperinspcrcaum.empresa_id,0) <= 0 then
      --
      vn_fase := 1.52;
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da empresa não encontrado na base Compliance, ou não foi informado:" ('||trim(ev_cnpj_empr)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );

      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.54;
   --
   if nvl(est_row_consoperinspcrcaum.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
      --
      vn_fase := 1.55;
      --
         gv_resumo := '"Código da Situação Tributaria do Imposto PIS não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_consoperinspcrcaum.codst_id_pis,0) = 0 then
      --
      gv_resumo := '"Não foi informado o Código da Situação Tributaria do imposto do PIS';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.8;
   --
   if nvl(est_row_consoperinspcrcaum.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
      vn_fase := 1.9;
      --
         gv_resumo := '"Código da Situação Tributaria do Imposto COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_consoperinspcrcaum.codst_id_cofins,0) = 0 then
      --
      vn_fase := 2;
      --
      gv_resumo := 'Não foi informado o Código da Situação Tributaria do imposto do COFINS.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.1;
   --
   if nvl(est_row_consoperinspcrcaum.planoconta_id,0) = 0 and trim(ev_cod_cta) is not null then
      --
      vn_fase := 2.2;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código do plano de conta não encontrado na base compliance" ('||trim(ev_cod_cta)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.5;
   --
   if nvl(est_row_consoperinspcrcaum.modfiscal_id,0) = 0 and trim(ev_cod_mod) is not null then
      --
      vn_fase := 2.6;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Modelo de Documento Fiscal não encontrado, favor verificar o código: " ('||trim(ev_cod_mod)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3;
   --
   if nvl(est_row_consoperinspcrcaum.vl_aliq_pis,0) < 0 then
      --
      vn_fase := 3.1;
      --
      gv_resumo := '"Alíquota do PIS/PASEP em reais(VL_ALIQ_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.2;
   --
   if nvl(est_row_consoperinspcrcaum.vl_aliq_cofins,0) < 0 then
      --
      vn_fase := 3.3;
      --
      gv_resumo := '"Alíquota do COFINS em reais(VL_ALIQ_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.4;
   --
   if nvl(est_row_consoperinspcrcaum.vl_rec_caixa,0) <= 0 then
      --
      vn_fase := 3.5;
      --
      gv_resumo := '"Valor total da receita recebida(VL_REC_CAIXA)" Não pode ser negativo ou nulo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.6;
   --
   if nvl(est_row_consoperinspcrcaum.vl_desc_pis,0) < 0 then
      --
      vn_fase := 3.7;
      --
      gv_resumo := '"Valor do desconto / exclusão da base de cálculo(VL_DESC_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consoperinspcrcaum.quant_bc_pis,0) < 0 then
      --
      vn_fase := 3.8;
      --
      gv_resumo := '"Base de cálculo em quantidade - PIS/PASEP(QUANT_BC_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.9;
   --
   if nvl(est_row_consoperinspcrcaum.vl_pis,0) < 0 then
      --
      vn_fase := 4;
      --
      gv_resumo := '"Valor do PIS/PASEP(VL_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.1;
   --
   if nvl(est_row_consoperinspcrcaum.vl_desc_cofins,0) < 0 then
      --
      vn_fase := 4.2;
      --
      gv_resumo := '"Valor do desconto / exclusão da base de cálculo(VL_DESC_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.3;
   --
   if nvl(est_row_consoperinspcrcaum.quant_bc_cofins,0) < 0 then
      --
      vn_fase := 4.4;
      --
      gv_resumo := '"Base de cálculo em quantidade - COFINS(QUANT_BC_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.5;
   --
   if nvl(est_row_consoperinspcrcaum.vl_cofins,0) < 0 then
      --
      vn_fase := 4.6;
      --
      gv_resumo := '"Valor do COFINS(VL_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.7;
   --
   if nvl(est_row_consoperinspcrcaum.cfop_id,0) = 0 and en_cfop is not null then
      --
      vn_fase := 4.9;
      --
      gv_resumo := '"Código Fiscal de Operação - CFOP" informado está inválido. Código = '||en_cfop||'.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.10;
   --
   if nvl(est_row_consoperinspcrcaum.id, 0)               > 0 and
      nvl(vn_id,0)                                        > 0 and
      nvl(est_row_consoperinspcrcaum.empresa_id,0)        > 0 and
      nvl(est_row_consoperinspcrcaum.codst_id_pis,0)      > 0 and
      nvl(est_row_consoperinspcrcaum.codst_id_cofins,0)   > 0 and
      nvl(est_row_consoperinspcrcaum.vl_rec_caixa,0)      > 0 then
      --
      vn_fase := 4.11;
      --
      begin
         pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
      exception
         when others then
            null;
      end;
      --
      vn_fase := 4.12;
      --
         insert into cons_oper_ins_pc_rc_aum ( id
                                             , empresa_id
                                             , dt_ref
                                             , vl_rec_caixa
                                             , codst_id_pis
                                             , vl_desc_pis
                                             , quant_bc_pis
                                             , vl_aliq_pis
                                             , vl_pis
                                             , codst_id_cofins
                                             , vl_desc_cofins
                                             , quant_bc_cofins
                                             , vl_aliq_cofins
                                             , vl_cofins
                                             , modfiscal_id
                                             , planoconta_id
                                             , info_compl
                                             , dm_st_proc
                                             , dm_st_integra
                                             , cfop_id )
                                       values( est_row_consoperinspcrcaum.id
                                             , est_row_consoperinspcrcaum.empresa_id
                                             , est_row_consoperinspcrcaum.dt_ref
                                             , est_row_consoperinspcrcaum.vl_rec_caixa
                                             , est_row_consoperinspcrcaum.codst_id_pis
                                             , est_row_consoperinspcrcaum.vl_desc_pis
                                             , est_row_consoperinspcrcaum.quant_bc_pis
                                             , est_row_consoperinspcrcaum.vl_aliq_pis
                                             , est_row_consoperinspcrcaum.vl_pis
                                             , est_row_consoperinspcrcaum.codst_id_cofins
                                             , est_row_consoperinspcrcaum.vl_desc_cofins
                                             , est_row_consoperinspcrcaum.quant_bc_cofins
                                             , est_row_consoperinspcrcaum.vl_aliq_cofins
                                             , est_row_consoperinspcrcaum.vl_cofins
                                             , est_row_consoperinspcrcaum.modfiscal_id
                                             , est_row_consoperinspcrcaum.planoconta_id
                                             , est_row_consoperinspcrcaum.info_compl
                                             , est_row_consoperinspcrcaum.dm_st_proc
                                             , est_row_consoperinspcrcaum.dm_st_integra
                                             , est_row_consoperinspcrcaum.cfop_id
                                             );
         --
         commit;
         --
      else
         --
         vn_fase := 5.1;
         --
         update cons_oper_ins_pc_rc_aum co
            set co.vl_rec_caixa    = est_row_consoperinspcrcaum.vl_rec_caixa
              , co.vl_desc_pis     = est_row_consoperinspcrcaum.vl_desc_pis
              , co.quant_bc_pis    = est_row_consoperinspcrcaum.quant_bc_pis
              , co.vl_aliq_pis     = est_row_consoperinspcrcaum.vl_aliq_pis
              , co.vl_pis          = est_row_consoperinspcrcaum.vl_pis
              , co.vl_desc_cofins  = est_row_consoperinspcrcaum.vl_desc_cofins
              , co.quant_bc_cofins = est_row_consoperinspcrcaum.quant_bc_cofins
              , co.vl_aliq_cofins  = est_row_consoperinspcrcaum.vl_aliq_cofins
              , co.vl_cofins       = est_row_consoperinspcrcaum.vl_cofins
              , co.modfiscal_id    = est_row_consoperinspcrcaum.modfiscal_id
              , co.planoconta_id   = est_row_consoperinspcrcaum.planoconta_id
              , co.dm_st_proc      = est_row_consoperinspcrcaum.dm_st_proc
              , co.dm_st_integra   = est_row_consoperinspcrcaum.dm_st_integra
              , co.cfop_id         = est_row_consoperinspcrcaum.cfop_id
          where co.id              = est_row_consoperinspcrcaum.id
            and co.dm_st_proc      not in (1); -- validada
         --
         commit;
         --
      end if;
      --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_consoperinspcrcaum fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_consoperinspcrcaum;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela PR_CONS_OPER_INS_PC_RC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_prconsoperinspcrc ( est_log_generico_ddo      in out nocopy dbms_sql.number_table
                                       , est_row_prconsoperinspcrc in out nocopy pr_cons_oper_ins_pc_rc%rowtype
                                       , ev_cpf_cnpj               in            varchar2
                                       , en_cd_orig                in            orig_proc.cd%type
                                       ) is
   --
   vn_fase                 number := null;
   vn_loggenerico_id       log_generico_ddo.id%type;
   vn_id                   pr_cons_oper_ins_pc_rc.id%type := null;
   vn_prconsoperinspcrc_id pr_cons_oper_ins_pc_rc.id%type := null;
   vn_dm_st_proc           number(1) := null;
   --
begin
   --
   vn_fase := 1;
   --
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cpf_cnpj;
   gv_mensagem := gv_mensagem || chr(10);
   -- Recebe o id da tabela pai, pq é essa tabela q a tela busca como objetos de referencia
   gn_referencia_id := est_row_prconsoperinspcrc.consoperinspcrc_id;
   --
   if gv_obj_referencia is null then gv_obj_referencia := 'CONS_OPER_INS_PC_RC'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_prconsoperinspcrc
   if nvl(est_row_prconsoperinspcrc.origproc_id,0) = 0 then
      est_row_prconsoperinspcrc.origproc_id    := pk_csf.fkg_Orig_Proc_id( en_cd    =>   en_cd_orig );
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_prconsoperinspcrc ( en_consoperinspcrc_id  => est_row_prconsoperinspcrc.consoperinspcrc_id
                                       , en_origproc_id         => est_row_prconsoperinspcrc.origproc_id
                                       , sn_prconsoperinspcrc_id => vn_prconsoperinspcrc_id
                                       , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_prconsoperinspcrc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_prconsoperinspcrc.id,0) <= 0 and nvl(vn_prconsoperinspcrc_id,0) <= 0 then
      -- pr_cons_oper_ins_pc_rc
      select prconsoperinspcrc_seq.nextval
        into est_row_prconsoperinspcrc.id
        from dual;
      --
      vn_id := est_row_prconsoperinspcrc.id;
      --
   elsif nvl(est_row_prconsoperinspcrc.id,0) <= 0 and nvl(vn_prconsoperinspcrc_id,0) > 0 then
      --
      est_row_prconsoperinspcrc.id := vn_prconsoperinspcrc_id;
      --
   elsif nvl(est_row_prconsoperinspcrc.id,0) > 0 and nvl(est_row_prconsoperinspcrc.id,0) <> nvl(vn_prconsoperinspcrc_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_prconsoperinspcrc.id||') está diferente do id encontrado '||vn_prconsoperinspcrc_id||' para o registro na tabela PR_CONS_OPER_INS_PC_RC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   vn_fase := 1.51;
   --| Validar Registros
   if nvl(est_row_prconsoperinspcrc.origproc_id, 0) = 0 and en_cd_orig is not null then
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Origem do Processo não encontrado na base Compliance:" ('|| en_cd_orig ||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_prconsoperinspcrc.origproc_id, 0) = 0 then
      --
      vn_fase := 1.53;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Código da Origem do Processo não informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --

   end if;
   --
   vn_fase := 1.54;
   --
   if trim(est_row_prconsoperinspcrc.num_proc) is null then
      --
      vn_fase := 1.55;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Identificação do processo ou ato concessório" não informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.6;
   --
   if nvl(est_row_prconsoperinspcrc.id, 0)                > 0 and
      nvl(vn_id,0)                                        > 0 and
      nvl(est_row_prconsoperinspcrc.consoperinspcrc_id,0) > 0 and
      nvl(est_row_prconsoperinspcrc.origproc_id,0)        > 0 and
      trim(est_row_prconsoperinspcrc.num_proc)            is not null then
      --
      vn_fase := 1.8;
      --
         insert into pr_cons_oper_ins_pc_rc ( id
                                            , consoperinspcrc_id
                                            , num_proc
                                            , origproc_id )
                                      values( est_row_prconsoperinspcrc.id
                                            , est_row_prconsoperinspcrc.consoperinspcrc_id
                                            , est_row_prconsoperinspcrc.num_proc
                                            , est_row_prconsoperinspcrc.origproc_id
                                            );
         --
         commit;
         --
      else
         --
         vn_fase := 2.1;
         --
         update pr_cons_oper_ins_pc_rc
            set num_proc  = est_row_prconsoperinspcrc.num_proc
          where id        = est_row_prconsoperinspcrc.id;
         --
         commit;
         --
      end if;
      --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_prconsoperinspcrc fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
end pkb_integr_prconsoperinspcrc;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CONS_OPER_INS_PC_RC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_consoperinspcrc ( est_log_generico_ddo         in out nocopy  dbms_sql.number_table
                                     , est_row_consoperinspcrc      in out nocopy  cons_oper_ins_pc_rc%rowtype
                                     , ev_cnpj_empr                 in             varchar2
                                     , en_multorg_id                in             mult_org.id%type
                                     , ev_cod_st_pis                in             varchar2
                                     , ev_cod_st_cofins             in             varchar2
                                     , ev_cod_mod                   in             varchar2
                                     , ev_cod_cta                   in             varchar2
                                     , en_cfop                      in             number
                                     ) is
   --
   vn_fase            number                      := null;
   vn_loggenerico_id  log_generico_ddo.id%type;
   vn_id              cons_oper_ins_pc_rc.id%type := null;
   vn_consoperinspcrc_id   cons_oper_ins_pc_rc.id%type := null;
   vn_dm_st_proc           cons_oper_ins_pc_rc.dm_st_proc%type := null;
   --
begin
   --
   vn_fase := 1;
   --
   est_row_consoperinspcrc.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj( en_multorg_id => en_multorg_id
                                                                            , ev_cpf_cnpj   => ev_cnpj_empr
                                                                            );
   --
   vn_fase := 1.1;
   --
   --| Montar o cabeçalho do log
   gv_mensagem       := null;
   gv_mensagem       := 'Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa(en_empresa_id => est_row_consoperinspcrc.empresa_id);
   gv_mensagem       := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'CONS_OPER_INS_PC_RC'; end if;
   --
   vn_fase := 1.2;
   --
   -- Se a data fechamento não foi carregada busca a data para validação
   if pk_int_view_ddo.gd_dt_ult_fecha is null then
      --
      pk_int_view_ddo.gd_dt_ult_fecha := pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id   => est_row_consoperinspcrc.empresa_id
                                                                             , en_objintegr_id => pk_csf.fkg_recup_objintegr_id( ev_cd => '50' )); -- Demais Documentos e Operações - Bloco F EFD Contribuições
      --
   end if ;
   --
   vn_fase := 1.3;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_consoperinspcrc
   if nvl(est_row_consoperinspcrc.codst_id_pis,0) = 0 then
      est_row_consoperinspcrc.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                   , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
   end if;
   --
   if nvl(est_row_consoperinspcrc.codst_id_cofins,0) = 0 then
      est_row_consoperinspcrc.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                      , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS
   end if;
   --
   if nvl(est_row_consoperinspcrc.modfiscal_id,0) = 0 then
      est_row_consoperinspcrc.modfiscal_id := pk_csf_ddo.fkg_cod_mod_modfiscal_id( ev_cod_mod  => ev_cod_mod );
   end if;
   --
   if nvl(est_row_consoperinspcrc.planoconta_id,0) = 0 then
      est_row_consoperinspcrc.planoconta_id := pk_csf.fkg_Plano_Conta_id ( ev_cod_cta    =>  ev_cod_cta
                                                                         , en_empresa_id =>  est_row_consoperinspcrc.empresa_id );
   end if;
   --
   if nvl(est_row_consoperinspcrc.cfop_id,0) = 0 then
      est_row_consoperinspcrc.cfop_id := pk_csf.fkg_cfop_id ( en_cd => en_cfop ); -- se o valor for nulo ou não for válido, a função retorna NULL
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_consoperinspcrc (  en_empresa_id         => est_row_consoperinspcrc.empresa_id
                                      , ed_dt_ref             => est_row_consoperinspcrc.dt_ref
                                      , en_codst_id_pis       => est_row_consoperinspcrc.codst_id_pis
                                      , en_aliq_pis           => est_row_consoperinspcrc.aliq_pis
                                      , en_codst_id_cofins    => est_row_consoperinspcrc.codst_id_cofins
                                      , en_aliq_cofins        => est_row_consoperinspcrc.aliq_cofins
                                      , en_modfiscal_id       => est_row_consoperinspcrc.modfiscal_id
                                      , en_planoconta_id      => est_row_consoperinspcrc.planoconta_id
                                      , ev_info_compl         => est_row_consoperinspcrc.info_compl
                                      , en_cfop_id            => est_row_consoperinspcrc.cfop_id
                                      , sn_consoperinspcrc_id => vn_consoperinspcrc_id
                                      , sn_dm_st_proc         => vn_dm_st_proc );

      --
   exception
      when others then
         vn_consoperinspcrc_id := null;
         vn_dm_st_proc         := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_consoperinspcrc.id,0) <= 0 and nvl(vn_consoperinspcrc_id,0) <= 0 then
      -- cons_oper_ins_pc_rc
      select consoperinspcrc_seq.nextval
        into est_row_consoperinspcrc.id
        from dual;
      --
      vn_id := est_row_consoperinspcrc.id;
      --
   elsif nvl(est_row_consoperinspcrc.id,0) <= 0 and nvl(vn_consoperinspcrc_id,0) > 0 then
      --
      est_row_consoperinspcrc.id := vn_consoperinspcrc_id;
      --
   elsif nvl(est_row_consoperinspcrc.id,0) > 0 and nvl(est_row_consoperinspcrc.id,0) <> nvl(vn_consoperinspcrc_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_consoperinspcrc.id||') está diferente do id encontrado '||vn_consoperinspcrc_id||' para o registro na tabela CONS_OPER_INS_PC_RC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_consoperinspcrc.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   gn_referencia_id := est_row_consoperinspcrc.id;
   --
   vn_fase := 2;
   --
   --| Validar Registros
   if nvl(est_row_consoperinspcrc.empresa_id,0) <= 0 then
      --
      vn_fase := 2.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da empresa não encontrado na base Compliance, ou não foi informado:" ('||trim(ev_cnpj_empr)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.3;
   --
   if nvl(est_row_consoperinspcrc.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
      --
      vn_fase := 2.4;
      --
         gv_resumo := '"Código da Situação Tributaria do Imposto PIS não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_consoperinspcrc.codst_id_pis,0) = 0 then
      --
      gv_resumo := '"Não foi informado o Código da Situação Tributaria do imposto do PIS';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.7;
   --
   if nvl(est_row_consoperinspcrc.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
      vn_fase := 3;
      --
         gv_resumo := '"Código da Situação Tributaria do Imposto COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_consoperinspcrc.codst_id_cofins,0) = 0 then
      --
      vn_fase := 3.1;
      --
      gv_resumo := 'Não foi informado o Código da Situação Tributaria do imposto do COFINS.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4;
   --
   if nvl(est_row_consoperinspcrc.planoconta_id,0) = 0 and trim(ev_cod_cta) is not null then
      --
      vn_fase := 4.1;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código do plano de conta não encontrado na base compliance" ('||trim(ev_cod_cta)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5;
   --
   if nvl(est_row_consoperinspcrc.modfiscal_id,0) = 0 and trim(ev_cod_mod) is not null then
      --
      vn_fase := 5.1;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Modelo de Documento Fiscal não encontrado, favor verificar o código: " ('||trim(ev_cod_mod)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 6;
   --
   if nvl(est_row_consoperinspcrc.aliq_pis,0) < 0 then
      --
      vn_fase := 6.1;
      --
      gv_resumo := '"Alíquota do PIS/PASEP em percentual(ALIQ_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 7;
   --
   if nvl(est_row_consoperinspcrc.aliq_cofins,0) < 0 then
      --
      vn_fase := 7.1;
      --
      gv_resumo := '"Alíquota do COFINS em percentual(ALIQ_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_consoperinspcrc.vl_rec_caixa,0) <= 0 then
      --
      vn_fase := 8.1;
      --
      gv_resumo := '"Valor total da receita recebida(VL_REC_CAIXA)" Não pode ser negativo ou nulo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 9;
   --
   if nvl(est_row_consoperinspcrc.vl_desc_pis,0) < 0 then
      --
      vn_fase := 9.1;
      --
      gv_resumo := '"Valor do desconto / exclusão da base de cálculo(VL_DESC_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 10;
   --
   if nvl(est_row_consoperinspcrc.vl_bc_pis,0) < 0 then
      --
      vn_fase := 10.1;
      --
      gv_resumo := '"Valor da base de cálculo do PIS/PASEP(VL_BC_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 11;
   --
   if nvl(est_row_consoperinspcrc.vl_pis,0) < 0 then
      --
      vn_fase := 11.1;
      --
      gv_resumo := '"Valor do PIS/PASEP(VL_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 12;
   --
   if nvl(est_row_consoperinspcrc.vl_desc_cofins,0) < 0 then
      --
      vn_fase := 12.1;
      --
      gv_resumo := '"Valor do desconto / exclusão da base de cálculo(VL_DESC_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 13;
   --
   if nvl(est_row_consoperinspcrc.vl_bc_cofins,0) < 0 then
      --
      vn_fase := 13.1;
      --
      gv_resumo := '"Valor da base de cálculo do COFINS(VL_BC_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 14;
   --
   if nvl(est_row_consoperinspcrc.vl_cofins,0) < 0 then
      --
      vn_fase := 14.1;
      --
      gv_resumo := '"Valor do COFINS(VL_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 15;
   --
   if nvl(est_row_consoperinspcrc.cfop_id,0) = 0 and en_cfop is not null then
      --
      vn_fase := 15.2;
      --
      gv_resumo := '"Código Fiscal de Operação - CFOP" informado está inválido. Código = '||en_cfop||'.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 16;
   --
   if (pk_int_view_ddo.gd_dt_ult_fecha is null) or (trunc( est_row_consoperinspcrc.dt_ref ) < pk_int_view_ddo.gd_dt_ult_fecha) then
     --
     gv_resumo := null;
     --
     gv_resumo := 'Período informado para integração de Demais Documentos e Operações - Bloco F EFD-'||
                  'Contribuições (Bloco F500), está fechado para a data do registro. Data de fechamento fiscal '||
                  to_char(pk_int_view_ddo.gd_dt_ult_fecha,'dd/mm/yyyy')||' - CNPJ/CPF: '||ev_cnpj_empr||'.';
     --
     vn_loggenerico_id := null;
     --
     pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                          ev_mensagem          => gv_mensagem,
                          ev_resumo            => gv_resumo,
                          en_tipo_log          => erro_de_validacao,
                          en_referencia_id     => gn_referencia_id,
                          ev_obj_referencia    => gv_obj_referencia,
                          en_empresa_id        => gn_empresa_id
                           );
     --
     -- Armazena o "loggenerico_id" na memória
     pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                             est_log_generico_ddo => est_log_generico_ddo);
     --
   end if;
   --
   vn_fase := 99;
   --
   if nvl(est_row_consoperinspcrc.id, 0)             > 0 and
      nvl(vn_id,0)                                   > 0 and
      nvl(est_row_consoperinspcrc.empresa_id,0)      > 0 and
      nvl(est_row_consoperinspcrc.codst_id_pis,0)    > 0 and
      nvl(est_row_consoperinspcrc.codst_id_cofins,0) > 0 and
      nvl(est_row_consoperinspcrc.vl_rec_caixa,0)    > 0 then
      --
      vn_fase := 99.1;
      --
      begin
         pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
      exception
         when others then
            null;
      end;
      --
      vn_fase := 99.2;
      --
      insert into cons_oper_ins_pc_rc ( id
                                         , empresa_id
                                         , dt_ref
                                         , vl_rec_caixa
                                         , codst_id_pis
                                         , vl_desc_pis
                                         , vl_bc_pis
                                         , aliq_pis
                                         , vl_pis
                                         , codst_id_cofins
                                         , vl_desc_cofins
                                         , vl_bc_cofins
                                         , aliq_cofins
                                         , vl_cofins
                                         , modfiscal_id
                                         , planoconta_id
                                         , info_compl
                                         , dm_st_proc
                                         , dm_st_integra
                                         , cfop_id )
                                   values( est_row_consoperinspcrc.id
                                         , est_row_consoperinspcrc.empresa_id
                                         , est_row_consoperinspcrc.dt_ref
                                         , est_row_consoperinspcrc.vl_rec_caixa
                                         , est_row_consoperinspcrc.codst_id_pis
                                         , est_row_consoperinspcrc.vl_desc_pis
                                         , est_row_consoperinspcrc.vl_bc_pis
                                         , est_row_consoperinspcrc.aliq_pis
                                         , est_row_consoperinspcrc.vl_pis
                                         , est_row_consoperinspcrc.codst_id_cofins
                                         , est_row_consoperinspcrc.vl_desc_cofins
                                         , est_row_consoperinspcrc.vl_bc_cofins
                                         , est_row_consoperinspcrc.aliq_cofins
                                         , est_row_consoperinspcrc.vl_cofins
                                         , est_row_consoperinspcrc.modfiscal_id
                                         , est_row_consoperinspcrc.planoconta_id
                                         , est_row_consoperinspcrc.info_compl
                                         , est_row_consoperinspcrc.dm_st_proc
                                         , est_row_consoperinspcrc.dm_st_integra
                                         , est_row_consoperinspcrc.cfop_id
                                         );
         --
         commit;
         --
      else
         --
         vn_fase := 99.3;
         --
         update cons_oper_ins_pc_rc co
              set co.vl_rec_caixa       = est_row_consoperinspcrc.vl_rec_caixa
                , co.vl_desc_pis        = est_row_consoperinspcrc.vl_desc_pis
                , co.vl_bc_pis          = est_row_consoperinspcrc.vl_bc_pis
                , co.aliq_pis           = est_row_consoperinspcrc.aliq_pis
                , co.vl_pis             = est_row_consoperinspcrc.vl_pis
                , co.vl_desc_cofins     = est_row_consoperinspcrc.vl_desc_cofins
                , co.vl_bc_cofins       = est_row_consoperinspcrc.vl_bc_cofins
                , co.aliq_cofins        = est_row_consoperinspcrc.aliq_cofins
                , co.vl_cofins          = est_row_consoperinspcrc.vl_cofins
                , co.modfiscal_id       = est_row_consoperinspcrc.modfiscal_id
                , co.planoconta_id      = est_row_consoperinspcrc.planoconta_id
                , co.info_compl         = est_row_consoperinspcrc.info_compl
                , co.dm_st_proc         = est_row_consoperinspcrc.dm_st_proc
                , co.dm_st_integra      = est_row_consoperinspcrc.dm_st_integra
                , co.cfop_id            = est_row_consoperinspcrc.cfop_id
            where co.id                 = est_row_consoperinspcrc.id
              and co.dm_st_proc         not in (1);  --Validada
         --
         commit;
         --
    end if;
    --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_consoperinspcrc fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_consoperinspcrc;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela OPER_ATIV_IMOB_PROC_REF
----------------------------------------------------------------------------------------------------
procedure pkb_integr_operativimobprocref ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                         , est_row_operativimobprocref in out nocopy oper_ativ_imob_proc_ref%rowtype
                                         , ev_cpf_cnpj                 in            varchar2
                                         )is
   --
   vn_fase                   number := null;
   vn_loggenerico_id         log_generico_ddo.id%type;
   vn_id                     oper_ativ_imob_proc_ref.id%type := null;
   vn_operativimobprocref_id oper_ativ_imob_proc_ref.id%type := null;
   vn_dm_st_proc             number(1) := null;
   --
begin
   --
   vn_fase := 1;
   --
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cpf_cnpj;
   gv_mensagem := gv_mensagem || chr(10);
   -- Recebe o id da tabela pai, pq é essa tabela q a tela busca como objetos de referencia
   gn_referencia_id := est_row_operativimobprocref.operativimobvend_id;
   --
   if gv_obj_referencia is null then gv_obj_referencia := 'OPER_ATIV_IMOB_VEND'; end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_operativimobprocref ( en_operativimobvend_id => est_row_operativimobprocref.operativimobvend_id
                                         , en_dm_ind_proc         => est_row_operativimobprocref.dm_ind_proc
                                         , sn_operativimobprocref_id => vn_operativimobprocref_id
                                         , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_operativimobprocref_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_operativimobprocref.id,0) <= 0 and nvl(vn_operativimobprocref_id,0) <= 0 then
      -- oper_ativ_imob_proc_ref
      select operativimobprocref_seq.nextval
        into est_row_operativimobprocref.id
        from dual;
      --
      vn_id := est_row_operativimobprocref.id;
      --
   elsif nvl(est_row_operativimobprocref.id,0) <= 0 and nvl(vn_operativimobprocref_id,0) > 0 then
      --
      est_row_operativimobprocref.id := vn_operativimobprocref_id;
      --
   elsif nvl(est_row_operativimobprocref.id,0) > 0 and nvl(est_row_operativimobprocref.id,0) <> nvl(vn_operativimobprocref_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_operativimobprocref.id||') está diferente do id encontrado '||vn_operativimobprocref_id||' para o registro na tabela OPER_ATIV_IMOB_PROC_REF.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   vn_fase := 1.51;
   --
   if trim(est_row_operativimobprocref.num_proc) is null then
      --
      vn_fase := 1.52;
      --
      gv_resumo := '"Identificação do processo ou ato concessório" não pode ser nulo(NUM_PROC).';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.53;
   --
   if nvl(est_row_operativimobprocref.dm_ind_proc,0) not in (1,3,9) then
      --
      vn_fase := 1.54;
      --
      gv_resumo := '"Domínio Indicador da origem do processo" inválido favor verificar: ('||est_row_operativimobprocref.dm_ind_proc||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.55;
   --
   if nvl(est_row_operativimobprocref.id, 0)                 > 0 and
      nvl(vn_id,0)                                           > 0 and
      nvl(est_row_operativimobprocref.dm_ind_proc,0)         not in (1,3,9) and
      trim(est_row_operativimobprocref.num_proc)             is not null and
      nvl(est_row_operativimobprocref.operativimobvend_id,0) > 0 then
       --
       vn_fase := 1.7;
       --
          insert into oper_ativ_imob_proc_ref ( id
                                              , operativimobvend_id
                                              , num_proc
                                              , dm_ind_proc )
                                       values ( est_row_operativimobprocref.id
                                              , est_row_operativimobprocref.operativimobvend_id
                                              , est_row_operativimobprocref.num_proc
                                              , est_row_operativimobprocref.dm_ind_proc
                                              );
          --
          commit;
          --
       else
          --
          vn_fase := 1.9;
          --
          update oper_ativ_imob_proc_ref
             set num_proc = est_row_operativimobprocref.num_proc
           where id = est_row_operativimobprocref.id;
          --
          commit;
          --
       end if;
       --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_operativimobprocref fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_operativimobprocref;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela OPER_ATIV_IMOB_CUS_ORC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_operativimobcusorc ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                        , est_row_operativimobcusorc  in out nocopy oper_ativ_imob_cus_orc%rowtype
                                        , ev_cpf_cnpj                 in            varchar2
                                        , ev_cod_st_pis               in            varchar2
                                        , ev_cod_st_cofins            in            varchar2
                                        ) is
   --
   vn_fase                  number := null;
   vn_loggenerico_id        log_generico_ddo.id%type;
   vn_id                    oper_ativ_imob_cus_orc.id%type := null;
   vn_operativimobcusorc_id oper_ativ_imob_cus_orc.id%type := null;
   vn_dm_st_proc            number(1) := null;
   --
begin
   --
   vn_fase := 1;
   --
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cpf_cnpj;
   gv_mensagem := gv_mensagem || chr(10);
   -- Recebe o id da tabela pai, pq é essa tabela q a tela busca como objetos de referencia
   gn_referencia_id := est_row_operativimobcusorc.operativimobvend_id;
   --
   if gv_obj_referencia is null then gv_obj_referencia := 'OPER_ATIV_IMOB_VEND'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_operativimobcusorc
   if nvl(est_row_operativimobcusorc.codst_id_pis,0) = 0 then
      est_row_operativimobcusorc.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                      , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
   end if;
   --
   if nvl(est_row_operativimobcusorc.codst_id_cofins,0) = 0 then
      est_row_operativimobcusorc.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                         , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_operativimobcusorc( en_operativimobvend_id   => est_row_operativimobcusorc.operativimobvend_id
                                       , en_codst_id_pis          => est_row_operativimobcusorc.codst_id_pis
                                       , en_aliq_pis              => est_row_operativimobcusorc.aliq_pis
                                       , en_codst_id_cofins       => est_row_operativimobcusorc.codst_id_cofins
                                       , en_aliq_cofins           => est_row_operativimobcusorc.aliq_cofins
                                       , sn_operativimobcusorc_id => vn_operativimobcusorc_id
                                       , sn_dm_st_proc            => vn_dm_st_proc );
      --
   exception
      when others then
         vn_operativimobcusorc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_operativimobcusorc.id,0) <= 0 and nvl(vn_operativimobcusorc_id,0) <= 0 then
      -- oper_ativ_imob_cus_orc
      select operativimobcusorc_seq.nextval
        into est_row_operativimobcusorc.id
        from dual;
      --
      vn_id := est_row_operativimobcusorc.id;
      --
   elsif nvl(est_row_operativimobcusorc.id,0) <= 0 and nvl(vn_operativimobcusorc_id,0) > 0 then
      --
      est_row_operativimobcusorc.id := vn_operativimobcusorc_id;
      --
   elsif nvl(est_row_operativimobcusorc.id,0) > 0 and nvl(est_row_operativimobcusorc.id,0) <> nvl(vn_operativimobcusorc_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_operativimobcusorc.id||') está diferente do id encontrado '||vn_operativimobcusorc_id||' para o registro na tabela OPER_ATIV_IMOB_CUS_ORC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   vn_fase := 1.51;
   --| Validar Registros
   if nvl(est_row_operativimobcusorc.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
      --
      vn_fase := 1.52;
         --
         gv_resumo := '"Código da Situação Tributaria dos Impostos não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_operativimobcusorc.codst_id_pis,0) = 0 then
      --
      gv_resumo := '"Não foi informado o Código da Situação Tributaria do imposto do PIS';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.53;
   --
   if nvl(est_row_operativimobcusorc.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
      vn_fase := 1.54;
         --
         gv_resumo := '"Código da Situação Tributaria dos Impostos COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_operativimobcusorc.codst_id_cofins,0) = 0 then
      --
      vn_fase := 1.55;
      --
      gv_resumo := 'Não foi informado o Código da Situação Tributaria do imposto do COFINS.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.6;
   --
   if nvl(est_row_operativimobcusorc.vl_cus_orc,0) <= 0 then
      --
      vn_fase := 1.7;
      --
      gv_resumo := '"Valor Total do Custo Orçado para Conclusão da Unidade Vendida(VL_CUS_ORC)" Não pode ser negativo ou nulo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.8;
   --
   if nvl(est_row_operativimobcusorc.vl_exc,0) <= 0 then
      --
      vn_fase := 1.9;
      --
      gv_resumo := '"Valores Referentes a Pagamentos a Pessoas Físicas, Encargos Trabalhistas, Sociais e Previdenciários...(VL_EXC)" Não pode ser negativo ou nulo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2;
   --
   if nvl(est_row_operativimobcusorc.vl_cus_orc_aju,0) <= 0 then
      --
      vn_fase := 2.1;
      --
      gv_resumo := '"Valor da Base de Calculo do Crédito sobre o Custo Orçado Ajustado(VL_CUS_ORC_AJU)" Não pode ser negativo ou nulo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.2;
   --
   if nvl(est_row_operativimobcusorc.vl_bc_cred,0) <= 0 then
      --
      vn_fase := 2.3;
      --
      gv_resumo := '"Valor da Base de Cálculo do Crédito sobre o Custo Orçado referente ao mês da escrituração(VL_BC_CRED)" Não pode ser negativo ou nulo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.4;
   --
   if nvl(est_row_operativimobcusorc.aliq_pis,0) < 0 then
      --
      vn_fase := 2.5;
      --
      gv_resumo := '"Valor da Alíquota do PIS/PASEP em percentual(ALIQ_PIS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.6;
   --
   if nvl(est_row_operativimobcusorc.vl_cred_pis_util,0) < 0 then
      --
      vn_fase := 2.7;
      --
      gv_resumo := '"Valor do Crédito sobre o custo orçado a ser utilizado no período da escrituração PIS/PASEP(VL_CRED_PIS_UTIL)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.8;
   --
   if nvl(est_row_operativimobcusorc.aliq_cofins,0) < 0 then
      --
      vn_fase := 2.9;
      --
      gv_resumo := '"Valor da Alíquota da COFINS em percentual(ALIQ_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.10;
   --
   if nvl(est_row_operativimobcusorc.vl_cred_cofins_util,0) < 0 then
      --
      vn_fase := 2.11;
      --
      gv_resumo := '"Valor do Crédito sobre o custo orçado a ser utilizado no período da escrituração COFINS(VL_CRED_COFINS_UTIL)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.12;
   --
   if nvl(est_row_operativimobcusorc.id, 0)                 > 0 and
      nvl(vn_id,0)                                          > 0 and
      nvl(est_row_operativimobcusorc.operativimobvend_id,0) < 0 then
      --
      vn_fase := 2.13;
      --
         insert into oper_ativ_imob_cus_orc ( id
                                            , operativimobvend_id
                                            , vl_cus_orc
                                            , vl_exc
                                            , vl_cus_orc_aju
                                            , vl_bc_cred
                                            , codst_id_pis
                                            , aliq_pis
                                            , vl_cred_pis_util
                                            , codst_id_cofins
                                            , aliq_cofins
                                            , vl_cred_cofins_util )
                                     values ( est_row_operativimobcusorc.id
                                            , est_row_operativimobcusorc.operativimobvend_id
                                            , est_row_operativimobcusorc.vl_cus_orc
                                            , est_row_operativimobcusorc.vl_exc
                                            , est_row_operativimobcusorc.vl_cus_orc_aju
                                            , est_row_operativimobcusorc.vl_bc_cred
                                            , est_row_operativimobcusorc.codst_id_pis
                                            , est_row_operativimobcusorc.aliq_pis
                                            , est_row_operativimobcusorc.vl_cred_pis_util
                                            , est_row_operativimobcusorc.codst_id_cofins
                                            , est_row_operativimobcusorc.aliq_cofins
                                            , est_row_operativimobcusorc.vl_cred_cofins_util
                                            );
         --
         commit;
         --
      else
         --
         vn_fase := 3.1;
         --
         update oper_ativ_imob_cus_orc op set op.vl_cus_orc           = est_row_operativimobcusorc.vl_cus_orc
                                            , op.vl_exc               = est_row_operativimobcusorc.vl_exc
                                            , op.vl_cus_orc_aju       = est_row_operativimobcusorc.vl_cus_orc_aju
                                            , op.vl_bc_cred           = est_row_operativimobcusorc.vl_bc_cred
                                            , op.aliq_pis             = est_row_operativimobcusorc.aliq_pis
                                            , op.vl_cred_pis_util     = est_row_operativimobcusorc.vl_cred_pis_util
                                            , op.aliq_cofins          = est_row_operativimobcusorc.aliq_cofins
                                            , op.vl_cred_cofins_util  = est_row_operativimobcusorc.vl_cred_cofins_util
                                        where op.id                   = est_row_operativimobcusorc.id;
         --
         commit;
         --
      end if;
      --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_operativimobcusorc fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_operativimobcusorc;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela OPER_ATIV_IMOB_CUS_INC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_operativimobcusinc ( est_log_generico_ddo       in out nocopy dbms_sql.number_table
                                        , est_row_operativimobcusinc in out nocopy oper_ativ_imob_cus_inc%rowtype
                                        , en_multorg_id              in            mult_org.id%type
                                        , ev_cpf_cnpj                in            varchar2
                                        , ev_cod_st_pis              in            varchar2
                                        , ev_cod_st_cofins           in            varchar2
                                        ) is
   --
   vn_fase                  number := null;
   vn_loggenerico_id        log_generico_ddo.id%type;
   vn_id                    oper_ativ_imob_cus_inc.id%type := null;
   vn_operativimobcusinc_id oper_ativ_imob_cus_inc.id%type := null;
   vn_dm_st_proc            number(1) := null;
   --
begin
   --
   vn_fase := 1;
   --
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cpf_cnpj;
   gv_mensagem := gv_mensagem || chr(10);
   -- Recebe o id da tabela pai, pq é essa tabela q a tela busca como objetos de referencia
   gn_referencia_id := est_row_operativimobcusinc.operativimobvend_id;
   --
   if gv_obj_referencia is null then gv_obj_referencia := 'OPER_ATIV_IMOB_VEND'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_operativimobcusinc
   if nvl(est_row_operativimobcusinc.codst_id_pis,0) = 0 then
      est_row_operativimobcusinc.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                      , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
   end if;
   --
   if nvl(est_row_operativimobcusinc.codst_id_cofins,0) = 0 then
      est_row_operativimobcusinc.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                         , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_operativimobcusinc ( en_operativimobvend_id   => est_row_operativimobcusinc.operativimobvend_id
                                        , en_codst_id_pis          => est_row_operativimobcusinc.codst_id_pis
                                        , en_codst_id_cofins       => est_row_operativimobcusinc.codst_id_cofins
                                        , sn_operativimobcusinc_id => vn_operativimobcusinc_id
                                        , sn_dm_st_proc            => vn_dm_st_proc );
      --
   exception
      when others then
         vn_operativimobcusinc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_operativimobcusinc.id,0) <= 0 and nvl(vn_operativimobcusinc_id,0) <= 0 then
      -- oper_ativ_imob_cus_inc
      select operativimobcusinc_seq.nextval
        into est_row_operativimobcusinc.id
        from dual;
      --
      vn_id := est_row_operativimobcusinc.id;
      --
   elsif nvl(est_row_operativimobcusinc.id,0) <= 0 and nvl(vn_operativimobcusinc_id,0) > 0 then
      --
      est_row_operativimobcusinc.id := vn_operativimobcusinc_id;
      --
   elsif nvl(est_row_operativimobcusinc.id,0) > 0 and nvl(est_row_operativimobcusinc.id,0) <> nvl(vn_operativimobcusinc_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_operativimobcusinc.id||') está diferente do id encontrado '||vn_operativimobcusinc_id||' para o registro na tabela OPER_ATIV_IMOB_CUS_INC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   vn_fase := 1.51;
   --| Validar Registros
   if nvl(est_row_operativimobcusinc.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
      --
      vn_fase := 1.52;
      --
         gv_resumo := '"Código da Situação Tributaria dos Impostos não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_operativimobcusinc.codst_id_pis,0) = 0 then
      --
      vn_fase := 1.53;
      --
      gv_resumo := 'Código da Situação Tributaria do Imposto PIS não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   if nvl(est_row_operativimobcusinc.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
      vn_fase := 1.54;
      --
         gv_resumo := '"Código da Situação Tributaria dos Impostos COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_operativimobcusinc.codst_id_cofins,0) = 0 then
      --
      vn_fase := 1.55;
      --
         gv_resumo := '"Código da Situação Tributaria dos Impostos COFINS não informado, informação obrigatória.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.56;
   --
   if nvl(est_row_operativimobcusinc.vl_cus_inc_acum_ant,0) < 0 then
      --
      vn_fase := 1.6;
      --
      gv_resumo := '"Valor Total do Custo Incorrido da unidade imobiliária acumulado(VL_CUS_INC_ACUM_ANT)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.7;
   --
   if nvl(est_row_operativimobcusinc.vl_cus_inc_per_esc,0) < 0 then
      --
      vn_fase := 2;
      --
      gv_resumo := '"Valor Total do Custo Incorrido da unidade imobiliária no mês da escrituração(VL_CUS_INC_PER_ESC)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.1;
   --
   if nvl(est_row_operativimobcusinc.vl_cus_inc_acum,0) < 0 then
      --
      vn_fase := 2.2;
      --
      gv_resumo := '"Valor Total do Custo Incorrido da unidade imobiliária acumulado(VL_CUS_INC_ACUM)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.3;
   --
   if nvl(est_row_operativimobcusinc.vl_exc_bc_cus_inc_acum,0) < 0 then
      --
      vn_fase := 2.4;
      --
      gv_resumo := '"Parcela do Custo Incorrido sem direito ao crédito da atividade imobiliária(VL_EXC_BC_CUS_INC_ACUM)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.5;
   --
   if nvl(est_row_operativimobcusinc.vl_bc_cus_inc,0) < 0 then
      --
      vn_fase := 2.6;
      --
      gv_resumo := '"Valor da Base de Cálculo do Crédito sobre o Custo Incorrido, acumulado até o período da escrituração(VL_BC_CUS_INC)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.7;
   --
   if nvl(est_row_operativimobcusinc.vl_cred_pis_acum,0) < 0 then
      --
      vn_fase := 2.8;
      --
      gv_resumo := '"Valor Total do Crédito Acumulado sobre o custo incorrido - COFINS(VL_CRED_PIS_ACUM)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.9;
   --
   if nvl(est_row_operativimobcusinc.vl_cred_pis_desc_ant,0) < 0 then
      --
      vn_fase := 3;
      --
      gv_resumo := '"Parcela do crédito descontada até o período anterior da escrituração - COFINS(VL_CRED_PIS_DESC_ANT)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.1;
   --
   if nvl(est_row_operativimobcusinc.vl_cred_pis_desc,0) < 0 then
      --
      vn_fase := 3.2;
      --
      gv_resumo := '"Parcela a descontar no período da escrituração - COFINS(VL_CRED_PIS_DESC)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.3;
   --
   if nvl(est_row_operativimobcusinc.vl_cred_pis_desc_fut,0) < 0 then
      --
      vn_fase := 3.4;
      --
      gv_resumo := '"Parcela a descontar em períodos futuros - COFINS(VL_CRED_PIS_DESC_FUT)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.5;
   --
   if nvl(est_row_operativimobcusinc.aliq_cofins,0) < 0 then
      --
      vn_fase := 3.6;
      --
      gv_resumo := '"Valor da Alíquota COFINS em percentual(ALIQ_COFINS)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.7;
   --
   if nvl(est_row_operativimobcusinc.vl_cred_cofins_acum,0) < 0 then
      --
      vn_fase := 3.8;
      --
      gv_resumo := '"Valor Total do Crédito Acumulado sobre o custo incorrido COFINS(VL_CRED_COFINS_ACUM)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.9;
   --
   if nvl(est_row_operativimobcusinc.vl_cred_cofins_acum,0) < 0 then
      --
      vn_fase := 4;
      --
      gv_resumo := '"Parcela do crédito descontada até o período anterior da escrituração COFINS (VL_CRED_COFINS_DESC_ANT)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.1;
   --
   if nvl(est_row_operativimobcusinc.vl_cred_cofins_desc,0) < 0 then
      --
      vn_fase := 4.2;
      --
      gv_resumo := '"Parcela a descontar no período da escrituração COFINS(VL_CRED_COFINS_DESC)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.3;
   --
   if nvl(est_row_operativimobcusinc.vl_cred_cofins_desc_fut,0) < 0 then
      --
      vn_fase := 4.4;
      --
      gv_resumo := '"Parcela a descontar em períodos futuros COFINS(VL_CRED_COFINS_DESC_FUT)" Não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.5;
   --
   if nvl(est_row_operativimobcusinc.id, 0)                 >  0 and
      nvl(vn_id,0)                                          >  0 and
      nvl(est_row_operativimobcusinc.operativimobvend_id,0) <> 0 then
      --
      vn_fase := 4.7;
      --
         insert into oper_ativ_imob_cus_inc ( id
                                            , operativimobvend_id
                                            , vl_cus_inc_acum_ant
                                            , vl_cus_inc_per_esc
                                            , vl_cus_inc_acum
                                            , vl_exc_bc_cus_inc_acum
                                            , vl_bc_cus_inc
                                            , codst_id_pis
                                            , aliq_pis
                                            , vl_cred_pis_acum
                                            , vl_cred_pis_desc_ant
                                            , vl_cred_pis_desc
                                            , vl_cred_pis_desc_fut
                                            , codst_id_cofins
                                            , aliq_cofins
                                            , vl_cred_cofins_acum
                                            , vl_cred_cofins_desc_ant
                                            , vl_cred_cofins_desc
                                            , vl_cred_cofins_desc_fut )
                                     values ( est_row_operativimobcusinc.id
                                            , est_row_operativimobcusinc.operativimobvend_id
                                            , est_row_operativimobcusinc.vl_cus_inc_acum_ant
                                            , est_row_operativimobcusinc.vl_cus_inc_per_esc
                                            , est_row_operativimobcusinc.vl_cus_inc_acum
                                            , est_row_operativimobcusinc.vl_exc_bc_cus_inc_acum
                                            , est_row_operativimobcusinc.vl_bc_cus_inc
                                            , est_row_operativimobcusinc.codst_id_pis
                                            , est_row_operativimobcusinc.aliq_pis
                                            , est_row_operativimobcusinc.vl_cred_pis_acum
                                            , est_row_operativimobcusinc.vl_cred_pis_desc_ant
                                            , est_row_operativimobcusinc.vl_cred_pis_desc
                                            , est_row_operativimobcusinc.vl_cred_pis_desc_fut
                                            , est_row_operativimobcusinc.codst_id_cofins
                                            , est_row_operativimobcusinc.aliq_cofins
                                            , est_row_operativimobcusinc.vl_cred_cofins_acum
                                            , est_row_operativimobcusinc.vl_cred_cofins_desc_ant
                                            , est_row_operativimobcusinc.vl_cred_cofins_desc
                                            , est_row_operativimobcusinc.vl_cred_cofins_desc_fut
                                            );
         --
         commit;
         --
      else
         --
         vn_fase := 5;
         --
         update oper_ativ_imob_cus_inc oa
            set oa.vl_cus_inc_acum_ant     = est_row_operativimobcusinc.vl_cus_inc_acum_ant
              , oa.vl_cus_inc_per_esc      = est_row_operativimobcusinc.vl_cus_inc_per_esc
              , oa.vl_cus_inc_acum         = est_row_operativimobcusinc.vl_cus_inc_acum
              , oa.vl_exc_bc_cus_inc_acum  = est_row_operativimobcusinc.vl_exc_bc_cus_inc_acum
              , oa.vl_bc_cus_inc           = est_row_operativimobcusinc.vl_bc_cus_inc
              , oa.aliq_pis                = est_row_operativimobcusinc.aliq_pis
              , oa.vl_cred_pis_acum        = est_row_operativimobcusinc.vl_cred_pis_acum
              , oa.vl_cred_pis_desc_ant    = est_row_operativimobcusinc.vl_cred_pis_desc_ant
              , oa.vl_cred_pis_desc        = est_row_operativimobcusinc.vl_cred_pis_desc
              , oa.vl_cred_pis_desc_fut    = est_row_operativimobcusinc.vl_cred_pis_desc_fut
              , oa.aliq_cofins             = est_row_operativimobcusinc.aliq_cofins
              , oa.vl_cred_cofins_acum     = est_row_operativimobcusinc.vl_cred_cofins_acum
              , oa.vl_cred_cofins_desc_ant = est_row_operativimobcusinc.vl_cred_cofins_desc_ant
              , oa.vl_cred_cofins_desc     = est_row_operativimobcusinc.vl_cred_cofins_desc
              , oa.vl_cred_cofins_desc_fut = est_row_operativimobcusinc.vl_cred_cofins_desc_fut
          where oa.id         = est_row_operativimobcusinc.id;
         --
         commit;
         --
      end if;
      --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pkb_integr_operativimobcusinc fase ('||vn_fase||'): '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_operativimobcusinc;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela OPER_ATIV_IMOB_VEND
----------------------------------------------------------------------------------------------------
procedure pkb_integr_operativimobvend ( est_log_generico_ddo          in out nocopy dbms_sql.number_table
                                      , est_row_operativimobvend      in out nocopy oper_ativ_imob_vend%rowtype
                                      , en_multorg_id                 in            mult_org.id%type
                                      , ev_cnpj_empr                  in            varchar2
                                      , ev_cod_st_pis                 in            varchar2
                                      , ev_cod_st_cofins              in            varchar2
                                      ) is
   --
   vn_fase            number := null;
   vn_loggenerico_id  log_generico_ddo.id%type;
   vn_tipoimp_id      tipo_imposto.id%type;
   vn_doct_valido     number(1) := null;
   vn_id                   oper_ativ_imob_vend.id%type := null;
   vn_operativimobvend_id  oper_ativ_imob_vend.id%type := null;
   vn_dm_st_proc           oper_ativ_imob_vend.dm_st_proc%type := null;
   --
begin
   --
   vn_fase := 1;
   --
   est_row_operativimobvend.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj( en_multorg_id => en_multorg_id
                                                                             , ev_cpf_cnpj   => ev_cnpj_empr
                                                                             );
   --
   vn_fase := 1.1;
   --| Montar o cabeçalho do log
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa(en_empresa_id => est_row_operativimobvend.empresa_id);
   gv_mensagem := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'OPER_ATIV_IMOB_VEND'; end if;
   --
   if nvl(est_row_operativimobvend.codst_id_pis,0) = 0 then
      est_row_operativimobvend.codst_id_pis := pk_csf.fkg_cod_st_id ( ev_cod_st     => ev_cod_st_pis
                                                                    , en_tipoimp_id => pk_csf.fkg_tipo_imposto_id ( en_cd => 4 ) );
   end if;
   --
   if nvl(est_row_operativimobvend.codst_id_cofins,0) = 0 then
      est_row_operativimobvend.codst_id_cofins  := pk_csf.fkg_cod_st_id ( ev_cod_st     => ev_cod_st_cofins
                                                 , en_tipoimp_id => pk_csf.fkg_tipo_imposto_id ( en_cd => 5 ) );
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_operativimobvend ( en_empresa_id          => est_row_operativimobvend.empresa_id
                                      , en_dm_ind_oper         => est_row_operativimobvend.dm_ind_oper
                                      , en_dm_unid_imob        => est_row_operativimobvend.dm_unid_imob
                                      , en_ident_emp           => est_row_operativimobvend.ident_emp
                                      , en_desc_unid_imob      => est_row_operativimobvend.desc_unid_imob
                                      , ev_cpf_cnpj_adqu       => est_row_operativimobvend.cpf_cnpj_adqu
                                      , ed_dt_oper             => est_row_operativimobvend.dt_oper
                                      , en_codst_id_pis        => est_row_operativimobvend.codst_id_pis
                                      , en_codst_id_cofins     => est_row_operativimobvend.codst_id_cofins
                                      , en_aliq_pis            => est_row_operativimobvend.aliq_pis
                                      , en_aliq_cofins         => est_row_operativimobvend.aliq_cofins
                                      , sn_operativimobvend_id => vn_operativimobvend_id
                                      , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_operativimobvend_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_operativimobvend.id,0) <= 0 and nvl(vn_operativimobvend_id,0) <= 0 then
      -- oper_ativ_imob_vend
      select operativimobvend_seq.nextval
        into est_row_operativimobvend.id
        from dual;
      --
      vn_id := est_row_operativimobvend.id;
      --
   elsif nvl(est_row_operativimobvend.id,0) <= 0 and nvl(vn_operativimobvend_id,0) > 0 then
      --
      est_row_operativimobvend.id := vn_operativimobvend_id;
      --
   elsif nvl(est_row_operativimobvend.id,0) > 0 and nvl(est_row_operativimobvend.id,0) <> nvl(vn_operativimobvend_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_operativimobvend.id||') está diferente do id encontrado '||vn_operativimobvend_id||' para o registro na tabela OPER_ATIV_IMOB_VEND.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_operativimobvend.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   gn_referencia_id := est_row_operativimobvend.id;
   --
   --| Validar Registros
   if nvl(est_row_operativimobvend.empresa_id,0) <= 0 then
      --
      vn_fase := 1.52;
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da empresa não encontrado na base Compliance, ou não foi informado:" ('||trim(ev_cnpj_empr)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.53;
   --
   if nvl(est_row_operativimobvend.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
      --
      vn_fase := 1.54;
         gv_resumo := '"Código da Situação Tributaria dos Impostos não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_operativimobvend.codst_id_pis,0) = 0 then
      --
      gv_resumo := '"Não foi informado o Código da Situação Tributaria do imposto do PIS';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.55;
   --
   if nvl(est_row_operativimobvend.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
      vn_fase := 1.6;
         gv_resumo := '"Código da Situação Tributaria dos Impostos COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_operativimobvend.codst_id_cofins,0) = 0 then
      --
      vn_fase := 2;
      --
      gv_resumo := '"Código da Situação Tributaria do Imposto COFINS não informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   end if;
   --
   vn_fase := 2.1;
   --
   if nvl(est_row_operativimobvend.dm_ind_oper,-1) not in (01,02,03,04,05) then
      --
      vn_fase := 2.2;
      --
      gv_resumo := '"Domínio de indicador do tipo de operação não informado corretamente ou não informado('||est_row_operativimobvend.dm_ind_oper||')."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.3;
   --
   if nvl(est_row_operativimobvend.dm_unid_imob,-1) not in (01,02,03,04,05,06) then
      --
      vn_fase := 2.4;
      --
      gv_resumo := '"Domínio de indicador do tipo de imobiliária Vendida não informado ou não informado corretamente('||est_row_operativimobvend.dm_ind_oper||')."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.5;
   --
   if est_row_operativimobvend.dm_ind_nat_emp is not null then
      --
      vn_fase := 2.6;
      --
      if est_row_operativimobvend.dm_ind_nat_emp not in (1,2,3,4) then
         --
         vn_fase := 2.7;
         --
         gv_resumo := '"Domínio de indicador da Natureza Específica do Empreendimento não informado corretamente('||est_row_operativimobvend.dm_ind_oper||')."';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      end if;
      --
   end if;
   --
   vn_fase := 2.8;
   --
   if trim(est_row_operativimobvend.ident_emp) is null then
      --
      vn_fase := 2.9;
      --
      gv_resumo := '"Identificação/Nome do Empreendimento não pode ser vazio."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3;
   --
   if trim(est_row_operativimobvend.cpf_cnpj_adqu) is not null then
      --
      vn_fase := 3.1;
      --
      vn_doct_valido := null;
      --
      vn_doct_valido := pk_valida_docto.fkg_valida_cpf_cgc(ev_numero => est_row_operativimobvend.cpf_cnpj_adqu );
      --
      if nvl(vn_doct_valido,0) = 0 then
         --
         gv_resumo := '"Identificação da pessoa física(CPF) ou jurídica(CNPJ) adquirente da unidade imobiliária Inválido, Favor inserir Identificador(CPF/CNPJ) valido."';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      end if;
   else
      --
      vn_fase := 3.2;
      --
      gv_resumo := '"Identificação da pessoa física(CPF) ou jurídica(CNPJ) adquirente da unidade imobiliária não informado. Campo obrigatório."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.3;
   --
   if est_row_operativimobvend.dt_oper is null then
      --
      vn_fase := 3.4;
      --
      gv_resumo := '"Data de Operação da venda da unidade imobiliaria" não informada.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.5;
   --
   if nvl(est_row_operativimobvend.vl_tot_vend,-1) < 0 then
      --
      vn_fase := 3.6;
      --
      gv_resumo := '"Valor total da unidade imobiliária vendida atualizado até o período da escrituração" não pode ser negativa ou nula.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.7;
   --
   if nvl(est_row_operativimobvend.vl_rec_acum,0) < 0 then
      --
      vn_fase := 3.8;
      --
      gv_resumo := '"Valor recebido acumulado até o mês anterior ao da escrituração" não pode ser negativa.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.9;
   --
   if nvl(est_row_operativimobvend.vl_tot_rec,-1) < 0 then
      --
      vn_fase := 4;
      --
      gv_resumo := '"Valor total recebido no mês da escrituração" não pode ser negativa ou nula.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.1;
   --
   if nvl(est_row_operativimobvend.vl_bc_pis,0) < 0 then
      --
      vn_fase := 4.2;
      --
      gv_resumo := '"Valor da Base de Cálculo do PIS/PASEP" não pode ser negativa ou nula.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.3;
   --
   if nvl(est_row_operativimobvend.aliq_pis,0) < 0 then
      --
      vn_fase := 4.4;
      --
      gv_resumo := '"Valor da Alíquota do PIS/PASEP (em percentual)" não pode ser negativa.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.5;
   --
   if nvl(est_row_operativimobvend.vl_pis,0) < 0 then
      --
      vn_fase := 4.6;
      --
      gv_resumo := '"Valor do imposto PIS/PASEP" não pode ser negativa.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.7;
   --
   if nvl(est_row_operativimobvend.vl_bc_cofins,0) < 0 then
      --
      vn_fase := 4.8;
      --
      gv_resumo := '"Valor da Base de Cálculo do COFINS" não pode ser negativa.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.9;
   --
   if nvl(est_row_operativimobvend.aliq_cofins,0) < 0 then
      --
      vn_fase := 4.10;
      --
      gv_resumo := '"Valor da Alíquota do COFINS (em percentual)" não pode ser negativa.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5;
   --
   if nvl(est_row_operativimobvend.vl_cofins,0) < 0 then
      --
      vn_fase := 5.1;
      --
      gv_resumo := '"Valor do imposto COFINS" não pode ser negativa.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5.2;
   --
   if nvl(est_row_operativimobvend.perc_rec_receb,0) < 0 then
      --
      vn_fase := 5.3;
      --
      gv_resumo := '"Percentual da receita total recebida até o mês, da unidade imobiliária vendida" não pode ser negativa.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5.4;
   --
   if nvl(est_row_operativimobvend.id, 0)                >  0 and
      nvl(vn_id,0)                                       >  0 and
      est_row_operativimobvend.dm_ind_oper               in (01,02,03,04,05) and
      est_row_operativimobvend.dm_unid_imob              in (01,02,03,04,05,06) and
      est_row_operativimobvend.cpf_cnpj_adqu             is not null and
      est_row_operativimobvend.dt_oper                   is not null and
      nvl(est_row_operativimobvend.codst_id_pis,0)       <> 0 and
      nvl(est_row_operativimobvend.vl_tot_vend,0)        <> 0 and
      nvl(est_row_operativimobvend.codst_id_cofins,0)    <> 0 then
      --
      vn_fase := 5.5;
      --
      begin
         pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
      exception
         when others then
            null;
      end;
      --
        insert into oper_ativ_imob_vend ( id
                                        , empresa_id
                                        , dm_st_proc
                                        , dm_ind_oper
                                        , dm_unid_imob
                                        , ident_emp
                                        , desc_unid_imob
                                        , num_cont
                                        , cpf_cnpj_adqu
                                        , dt_oper
                                        , vl_tot_vend
                                        , vl_rec_acum
                                        , vl_tot_rec
                                        , codst_id_pis
                                        , vl_bc_pis
                                        , aliq_pis
                                        , vl_pis
                                        , codst_id_cofins
                                        , vl_bc_cofins
                                        , aliq_cofins
                                        , vl_cofins
                                        , perc_rec_receb
                                        , dm_ind_nat_emp
                                        , inf_comp )
                                 values ( est_row_operativimobvend.id
                                        , est_row_operativimobvend.empresa_id
                                        , est_row_operativimobvend.dm_st_proc
                                        , est_row_operativimobvend.dm_ind_oper
                                        , est_row_operativimobvend.dm_unid_imob
                                        , est_row_operativimobvend.ident_emp
                                        , est_row_operativimobvend.desc_unid_imob
                                        , est_row_operativimobvend.num_cont
                                        , est_row_operativimobvend.cpf_cnpj_adqu
                                        , est_row_operativimobvend.dt_oper
                                        , est_row_operativimobvend.vl_tot_vend
                                        , est_row_operativimobvend.vl_rec_acum
                                        , est_row_operativimobvend.vl_tot_rec
                                        , est_row_operativimobvend.codst_id_pis
                                        , est_row_operativimobvend.vl_bc_pis
                                        , est_row_operativimobvend.aliq_pis
                                        , est_row_operativimobvend.vl_pis
                                        , est_row_operativimobvend.codst_id_cofins
                                        , est_row_operativimobvend.vl_bc_cofins
                                        , est_row_operativimobvend.aliq_cofins
                                        , est_row_operativimobvend.vl_cofins
                                        , est_row_operativimobvend.perc_rec_receb
                                        , est_row_operativimobvend.dm_ind_nat_emp
                                        , est_row_operativimobvend.inf_comp );
         --
         commit;
         --
      else
         --
         vn_fase := 5.7;
         --
         update oper_ativ_imob_vend oa
            set oa.dm_st_proc      = est_row_operativimobvend.dm_st_proc
              , oa.dm_ind_oper     = est_row_operativimobvend.dm_ind_oper
              , oa.dm_unid_imob    = est_row_operativimobvend.dm_unid_imob
              , oa.ident_emp       = est_row_operativimobvend.ident_emp
              , oa.desc_unid_imob  = est_row_operativimobvend.desc_unid_imob
              , oa.num_cont        = est_row_operativimobvend.num_cont
              , oa.vl_rec_acum     = est_row_operativimobvend.vl_rec_acum
              , oa.vl_tot_rec      = est_row_operativimobvend.vl_tot_rec
              , oa.vl_bc_pis       = est_row_operativimobvend.vl_bc_pis
              , oa.aliq_pis        = est_row_operativimobvend.aliq_pis
              , oa.vl_pis          = est_row_operativimobvend.vl_pis
              , oa.vl_bc_cofins    = est_row_operativimobvend.vl_bc_cofins
              , oa.aliq_cofins     = est_row_operativimobvend.aliq_cofins
              , oa.vl_cofins       = est_row_operativimobvend.vl_cofins
              , oa.perc_rec_receb  = est_row_operativimobvend.perc_rec_receb
              , oa.dm_ind_nat_emp  = est_row_operativimobvend.dm_ind_nat_emp
              , oa.inf_comp        = est_row_operativimobvend.inf_comp
          where oa.id         = est_row_operativimobvend.id
            and oa.dm_st_proc not in (1); -- validada
         --
         commit;
         --
      end if;
      --
exception
   when others then
      --
      gv_resumo := 'Erro na pkb_integr_operativimobvend fase ('||vn_fase||'): '||sqlerrm;
      --
      declare
         vn_loggenerico_id  log_generico_ddo.id%TYPE;
      begin
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => ERRO_DE_SISTEMA
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      exception
         when others then
            null;
      end;
      --
end pkb_integr_operativimobvend;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CRED_PRES_EST_ABERT_PC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_credpresestabertpc ( est_log_generico_ddo          in out nocopy dbms_sql.number_table
                                        , est_row_credpresestabertpc    in out cred_pres_est_abert_pc%rowtype
                                        , en_multorg_id                 in     mult_org.id%type
                                        , ev_cnpj_empr                  in     varchar2
                                        , ev_basecalccredpc_cd          in     varchar2
                                        , ev_cod_st_pis                 in     varchar2
                                        , ev_cod_st_cofins              in     varchar2
                                        , ev_cod_cta                    in     varchar2
                                        ) is
   --
   vn_fase           number := null;
   vn_loggenerico_id log_generico_ddo.id%type;
   vn_tipoimp_id     number;
   vn_id                    cred_pres_est_abert_pc.id%type := null;
   vn_credpresestabertpc_id cred_pres_est_abert_pc.id%type := null;
   vn_dm_st_proc            cred_pres_est_abert_pc.dm_st_proc%type := null;
   --
begin
   --
   vn_fase := 1;
   --
   est_row_credpresestabertpc.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj( en_multorg_id => en_multorg_id
                                                                               , ev_cpf_cnpj   => ev_cnpj_empr
                                                                               );
   --
   vn_fase := 1.1;
   --| Montar o cabeçalho do log
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa(en_empresa_id => est_row_credpresestabertpc.empresa_id);
   gv_mensagem := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'CRED_PRES_EST_ABERT_PC'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_credpresestabertpc
   if nvl(est_row_credpresestabertpc.codst_id_pis,0) = 0 then
      est_row_credpresestabertpc.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                      , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
   end if;
   --
   if nvl(est_row_credpresestabertpc.codst_id_cofins,0) = 0 then
      est_row_credpresestabertpc.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                         , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS
   end if;
   --
   if nvl(est_row_credpresestabertpc.basecalccredpc_id,0) = 0 then
      est_row_credpresestabertpc.basecalccredpc_id := pk_csf_efd_pc.fkg_Base_Calc_Cred_Pc_id ( ev_cd  =>  ev_basecalccredpc_cd );
   end if;
   --
   if nvl(est_row_credpresestabertpc.planoconta_id,0) = 0 then
      est_row_credpresestabertpc.planoconta_id := pk_csf.fkg_Plano_Conta_id ( ev_cod_cta    =>  ev_cod_cta
                                                                            , en_empresa_id =>  est_row_credpresestabertpc.empresa_id );
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_credpresestabertpc ( en_empresa_id            => est_row_credpresestabertpc.empresa_id
                                        , en_codst_id_pis          => est_row_credpresestabertpc.codst_id_pis
                                        , en_ano_ref               => est_row_credpresestabertpc.ano_ref
                                        , en_mes_ref               => est_row_credpresestabertpc.mes_ref
                                        , en_codst_id_cofins       => est_row_credpresestabertpc.codst_id_cofins
                                        , en_basecalccredpc_id     => est_row_credpresestabertpc.basecalccredpc_id
                                        , en_planoconta_id         => est_row_credpresestabertpc.planoconta_id
                                        , sn_credpresestabertpc_id => vn_credpresestabertpc_id
                                        , sn_dm_st_proc            => vn_dm_st_proc );
      --
   exception
      when others then
         vn_credpresestabertpc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_credpresestabertpc.id,0) <= 0 and nvl(vn_credpresestabertpc_id,0) <= 0 then
      -- cred_pres_est_abert_pc
      select credpresestabertpc_seq.nextval
        into est_row_credpresestabertpc.id
        from dual;
      --
      vn_id := est_row_credpresestabertpc.id;
      --
   elsif nvl(est_row_credpresestabertpc.id,0) <= 0 and nvl(vn_credpresestabertpc_id,0) > 0 then
      --
      est_row_credpresestabertpc.id := vn_credpresestabertpc_id;
      --
   elsif nvl(est_row_credpresestabertpc.id,0) > 0 and nvl(est_row_credpresestabertpc.id,0) <> nvl(vn_credpresestabertpc_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_credpresestabertpc.id||') está diferente do id encontrado '||vn_credpresestabertpc_id||' para o registro na tabela CRED_PRES_EST_ABERT_PC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_credpresestabertpc.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   gn_referencia_id := est_row_credpresestabertpc.id;
   --
   vn_fase := 1.52;
   --
   --| Validar Registros
   if nvl(est_row_credpresestabertpc.empresa_id,0) <= 0 then
      --
      vn_fase := 1.53;
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da empresa não encontrado na base Compliance, ou não foi informado:" ('||trim(ev_cnpj_empr)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.54;
   --
   if nvl(est_row_credpresestabertpc.ano_ref,0) < 0 then
      --
      vn_fase := 1.55;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Ano de Referência do lançamento não foi informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2;
   --
   if nvl(est_row_credpresestabertpc.mes_ref,0) <= 0 then
      --
      vn_fase := 2.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Mês de Referência não foi informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.2;
   --
   if nvl(est_row_credpresestabertpc.basecalccredpc_id,0) = 0 and trim(ev_basecalccredpc_cd) is not null then
      --
      vn_fase := 2.4;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Código da Base de Calculo do Credito não encontrado na base Compliance:" ('||trim(ev_basecalccredpc_cd)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 2.5;
   --
   if nvl(est_row_credpresestabertpc.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
      --
         vn_fase := 2.8;
         --
         gv_resumo := '"Código da Situação Tributaria dos Impostos não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_credpresestabertpc.codst_id_pis,0) = 0 then
      --
      vn_fase := 3;
      --
      gv_resumo := '"Não foi informado o Código da Situação Tributaria do imposto do PIS';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 3.1;
   --
   if nvl(est_row_credpresestabertpc.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
      vn_fase := 3.2;
      --
         gv_resumo := '"Código da Situação Tributaria dos Impostos COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_credpresestabertpc.codst_id_cofins,0) = 0 then
      --
      vn_fase := 3.3;
      --
	  if est_row_credpresestabertpc.codst_id_cofins is null then
         --
         gv_resumo := '"Código da Situação Tributaria do Imposto COFINS não informado.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      end if;
      --
   end if;
   --
   vn_fase := 3.4;
   --
   if nvl(est_row_credpresestabertpc.planoconta_id,0) = 0 and trim(ev_cod_cta) is not null then
         --
         vn_fase := 3.7;
         --
         gv_resumo := null;
         --
         gv_resumo := '"Código do plano de conta não encontrado na base compliance" ('||trim(ev_cod_cta)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
   end if;
   --
   vn_fase := 3.8;
   --
   if nvl(est_row_credpresestabertpc.vl_tot_est,-1) < 0 then
      --
      vn_fase := 4;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Valor total do estoque de abertura não pode ser negativo."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.1;
   --
   if nvl(est_row_credpresestabertpc.vl_est_imp,-1) < 0 then
      --
      vn_fase := 4.2;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Campo VL_EST_IMP não pode ser negativo."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.3;
   --
   if nvl(est_row_credpresestabertpc.vl_est_imp,-1) < 0 then
      --
      vn_fase := 4.4;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Campo VL_EST_IMP não pode ser negativo."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.5;
   --
   if nvl(est_row_credpresestabertpc.vl_bc_est,-1) < 0 then
      --
      vn_fase := 4.6;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Valor da Base de Calculo do Credito sobre o Estoque de Abertura não pode ser negativo."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.7;
   --
   if nvl(est_row_credpresestabertpc.vl_bc_men_est,-1) < 0 then
      --
      vn_fase := 4.8;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Valor da Base de Calculo Mensal do Credito sobre o Estoque de Abertura não pode ser negativo."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 4.9;
   --
   if nvl(est_row_credpresestabertpc.aliq_pis,-1) < 0 then
      --
      vn_fase := 5;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Aliquota do PIS/PASEP não pode ser negativo."';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5.1;
   --
   if nvl(est_row_credpresestabertpc.vl_pis,-1) < 0 then
      --
      vn_fase := 5.2;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor Mensal do Credito Presumido Apurado para o Periodo não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5.3;
   --
   if nvl(est_row_credpresestabertpc.vl_pis,-1) < 0 then
      --
      vn_fase := 5.4;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor Mensal do Credito Presumido Apurado para o Periodo não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5.5;
   --
   if nvl(est_row_credpresestabertpc.aliq_cofins,-1) < 0 then
      --
      vn_fase := 5.6;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Aliquota do COFINS (em percentual) não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5.7;
   --
   if nvl(est_row_credpresestabertpc.vl_cofins,-1) < 0 then
      --
      vn_fase := 5.8;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor Mensal do Credito Presumido Apurado para o Periodo não pode ser negativo.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 5.9;
   --
   if nvl(est_row_credpresestabertpc.id, 0)               > 0 and
      nvl(vn_id,0)                                        > 0 and
      nvl(est_row_credpresestabertpc.empresa_id,0)        > 0 and
      nvl(est_row_credpresestabertpc.ano_ref,0)           > 0 and
      nvl(est_row_credpresestabertpc.mes_ref,0)           > 0 and
      nvl(est_row_credpresestabertpc.basecalccredpc_id,0) > 0 and
      nvl(est_row_credpresestabertpc.codst_id_cofins,0)   > 0 and
      nvl(est_row_credpresestabertpc.codst_id_pis,0)      > 0 then
      --
      vn_fase := 6;
      --
      begin
         pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
      exception
         when others then
            null;
      end;
      --
      vn_fase := 6.1;
       --
         insert into cred_pres_est_abert_pc ( id
                                            , empresa_id
                                            , ano_ref
                                            , mes_ref
                                            , basecalccredpc_id
                                            , vl_tot_est
                                            , vl_est_imp
                                            , vl_bc_est
                                            , vl_bc_men_est
                                            , codst_id_pis
                                            , aliq_pis
                                            , vl_pis
                                            , codst_id_cofins
                                            , aliq_cofins
                                            , vl_cofins
                                            , desc_est
                                            , planoconta_id
                                            , dm_st_proc
                                            , dm_st_integra )
                                     values ( est_row_credpresestabertpc.id
                                            , est_row_credpresestabertpc.empresa_id
                                            , est_row_credpresestabertpc.ano_ref
                                            , est_row_credpresestabertpc.mes_ref
                                            , est_row_credpresestabertpc.basecalccredpc_id
                                            , est_row_credpresestabertpc.vl_tot_est
                                            , est_row_credpresestabertpc.vl_est_imp
                                            , est_row_credpresestabertpc.vl_bc_est
                                            , est_row_credpresestabertpc.vl_bc_men_est
                                            , est_row_credpresestabertpc.codst_id_pis
                                            , est_row_credpresestabertpc.aliq_pis
                                            , est_row_credpresestabertpc.vl_pis
                                            , est_row_credpresestabertpc.codst_id_cofins
                                            , est_row_credpresestabertpc.aliq_cofins
                                            , est_row_credpresestabertpc.vl_cofins
                                            , est_row_credpresestabertpc.desc_est
                                            , est_row_credpresestabertpc.planoconta_id
                                            , est_row_credpresestabertpc.dm_st_proc
                                            , est_row_credpresestabertpc.dm_st_integra
                                            );
         --
         commit;
         --
      else
         --
         vn_fase := 6.3;
         --
         update cred_pres_est_abert_pc cp
            set cp.vl_tot_est    = est_row_credpresestabertpc.vl_tot_est
              , cp.vl_est_imp    = est_row_credpresestabertpc.vl_est_imp
              , cp.vl_bc_est     = est_row_credpresestabertpc.vl_bc_est
              , cp.vl_bc_men_est = est_row_credpresestabertpc.vl_bc_men_est
              , cp.codst_id_pis  = est_row_credpresestabertpc.codst_id_pis
              , cp.aliq_pis      = est_row_credpresestabertpc.aliq_pis
              , cp.vl_cofins     = est_row_credpresestabertpc.vl_cofins
              , cp.desc_est      = est_row_credpresestabertpc.desc_est
              , cp.dm_st_proc    = est_row_credpresestabertpc.dm_st_proc
              , cp.dm_st_integra = est_row_credpresestabertpc.dm_st_integra
          where cp.id         = est_row_credpresestabertpc.id
            and cp.dm_st_proc not in (1); -- validada            ;
         --
         commit;
         --
      end if;
      --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pk_csf_api_ddo.pkb_integr_credpresestabertpc fase ('||vn_fase||'): ' || sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_credpresestabertpc;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela PR_BAI_OPER_CRED_PC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_prbaiopercredpc ( est_log_generico_ddo    in out nocopy dbms_sql.number_table
                                     , est_row_prbaiopercredpc in out nocopy pr_bai_oper_cred_pc%rowtype
                                     , ev_cpf_cnpj             in            varchar2
                                     , en_cd_origproc          in            orig_proc.cd%type
                                     ) is
   --
   vn_fase               number := null;
   vn_loggenerico_id     log_generico_ddo.id%type;
   vn_id                 pr_bai_oper_cred_pc.id%type := null;
   vn_prbaiopercredpc_id pr_bai_oper_cred_pc.id%type := null;
   vn_dm_st_proc         number(1) := null;
   --
begin
   --
   vn_fase := 1;
   --
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cpf_cnpj;
   gv_mensagem := gv_mensagem || chr(10);
   -- Recebe o id da tabela pai, pq é essa tabela q a tela busca como objetos de referencia
   gn_referencia_id := est_row_prbaiopercredpc.bemativimobopercredpc_id;
   --
   if gv_obj_referencia is null then gv_obj_referencia := 'BEM_ATIV_IMOB_OPER_CRED_PC'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_prbaiopercredpc
   if nvl(est_row_prbaiopercredpc.origproc_id,0) = 0 then
      est_row_prbaiopercredpc.origproc_id    := pk_csf.fkg_Orig_Proc_id( en_cd    =>   en_cd_origproc );
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_prbaiopercredpc ( en_bemativimobopercredpc_id  => est_row_prbaiopercredpc.bemativimobopercredpc_id
                                     , en_origproc_id               => est_row_prbaiopercredpc.origproc_id
                                     , sn_prbaiopercredpc_id        => vn_prbaiopercredpc_id
                                     , sn_dm_st_proc                => vn_dm_st_proc );
      --
   exception
      when others then
         vn_prbaiopercredpc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_prbaiopercredpc.id,0) <= 0 and nvl(vn_prbaiopercredpc_id,0) <= 0 then
      -- pr_bai_oper_cred_pc
      select prbaiopercredpc_seq.nextval
        into est_row_prbaiopercredpc.id
        from dual;
      --
      vn_id := est_row_prbaiopercredpc.id;
      --
   elsif nvl(est_row_prbaiopercredpc.id,0) <= 0 and nvl(vn_prbaiopercredpc_id,0) > 0 then
      --
      est_row_prbaiopercredpc.id := vn_prbaiopercredpc_id;
      --
   elsif nvl(est_row_prbaiopercredpc.id,0) > 0 and nvl(est_row_prbaiopercredpc.id,0) <> nvl(vn_prbaiopercredpc_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_prbaiopercredpc.id||') está diferente do id encontrado '||vn_prbaiopercredpc_id||' para o registro na tabela PR_BAI_OPER_CRED_PC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   vn_fase := 1.51;
   --
   --| Validar Registros
   if nvl(est_row_prbaiopercredpc.origproc_id, 0) = 0 and en_cd_origproc is not null then
      --
         vn_fase := 1.52;
         --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Origem do Processo não encontrado na base Compliance:" ('|| en_cd_origproc ||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_prbaiopercredpc.origproc_id, 0) = 0 then
      --
      vn_fase := 1.54;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Código da Origem do Processo não informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --

   end if;
   --
   vn_fase := 1.55;
   --
   if nvl(est_row_prbaiopercredpc.num_proc,0) <= 0 then
      --
      vn_fase := 1.6;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Identificação do processo ou ato concessório não pode ser numero negativo.('||est_row_prbaiopercredpc.num_proc||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 1.7;
   --
   if nvl(est_row_prbaiopercredpc.id, 0)                      > 0 and
      nvl(vn_id,0)                                            > 0 and
      nvl(est_row_prbaiopercredpc.bemativimobopercredpc_id,0) > 0 and
      nvl(est_row_prbaiopercredpc.num_proc,0)                 > 0 and
      nvl(est_row_prbaiopercredpc.origproc_id,0)              > 0 then
      --
         vn_fase := 1.9;
         --
         insert into pr_bai_oper_cred_pc ( id
                                         , bemativimobopercredpc_id
                                         , num_proc
                                         , origproc_id )
                                   values( est_row_prbaiopercredpc.id
                                         , est_row_prbaiopercredpc.bemativimobopercredpc_id
                                         , est_row_prbaiopercredpc.num_proc
                                         , est_row_prbaiopercredpc.origproc_id
                                         );
         --
         commit;
         --
      else
         --
         vn_fase := 2;
         --
         update pr_bai_oper_cred_pc
            set num_proc = est_row_prbaiopercredpc.num_proc
          where id            = est_row_prbaiopercredpc.id;
         --
         commit;
         --
      end if;
      --
exception
   when others then
     --
     gv_resumo := '"Erro na pk_csf_api_ddo.pkb_integr_prbaiopercredpc, fase('|| vn_fase ||'). Erro = '||sqlerrm;
     --
     vn_loggenerico_id := null;
     --
     pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                          , ev_mensagem          => gv_mensagem
                          , ev_resumo            => gv_resumo
                          , en_tipo_log          => erro_de_sistema
                          , en_referencia_id     => gn_referencia_id
                          , ev_obj_referencia    => gv_obj_referencia
                          , en_empresa_id        => gn_empresa_id
                          );
     --
     -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
end pkb_integr_prbaiopercredpc;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela BEM_ATIV_IMOB_OPER_CRED_PC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_bemativimobopcredpc ( est_log_generico_ddo           in out nocopy dbms_sql.number_table
                                         , est_row_bemativimobopercredpc  in out nocopy bem_ativ_imob_oper_cred_pc%rowtype
                                         , en_multorg_id                  in            mult_org.id%type
                                         , ev_cnpj_empr                   in            varchar2
                                         , ev_cod_st_pis                  in            varchar2
                                         , ev_cod_st_cofins               in            varchar2
                                         , ev_basecalccredpc_cd           in            varchar2
                                         , ev_cod_cta                     in            varchar2
                                         , ev_cod_ccus                    in            varchar2
                                         ) is
   --
   vn_fase                     number                   := null;
   vn_loggenerico_id           log_generico_ddo.id%type;
   vd_data                     date                               := null;
   vn_bemativimobopercredpc_id bem_ativ_imob_oper_cred_pc.id%type ;
   --
begin
   --
   vn_fase := 1;
   --
   if gv_obj_referencia is null then 
     gv_obj_referencia := 'BEM_ATIV_IMOB_OPER_CRED_PC';
   end if;
   --   
   vn_fase := 2;
   --
   -- #68654 - atribui contador de total no inicio
   begin
      pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj),0) + 1;
   exception
      when others then
         null;
   end;
   --
   vn_fase := 2;
   --
   est_row_bemativimobopercredpc.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj( en_multorg_id => en_multorg_id
                                                                                  , ev_cpf_cnpj   => ev_cnpj_empr
                                                                                  );
   --
   vn_fase := 4;
   --
   --| Validar registros
   if nvl(est_row_bemativimobopercredpc.empresa_id,0) <= 0 then
      --
      vn_fase := 4.1;
      --
      gv_resumo := null;
      --
      gv_resumo := '"CNPJ da empresa não encontrado na base Compliance, ou não foi informado:" ('||trim(ev_cnpj_empr)||').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => 'Empresa não encontrada.'
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
     --
     --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
     goto sair_integracao;
     --
   end if;
   --  
   vn_fase := 5;
   --
   --| Montar o cabeçalho do log
   gv_mensagem       := null;
   gv_mensagem       := 'Empresa: '||ev_cnpj_empr||' - '||pk_csf.fkg_nome_empresa(en_empresa_id => est_row_bemativimobopercredpc.empresa_id);
   gv_mensagem       := gv_mensagem || chr(10);
   --
   vn_fase := 6;
   --
   -- Se a data fechamento não foi carregada busca a data para validação
   if pk_int_view_ddo.gd_dt_ult_fecha is null then
      --
      pk_int_view_ddo.gd_dt_ult_fecha := pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id   => est_row_bemativimobopercredpc.empresa_id
                                                                             , en_objintegr_id => pk_csf.fkg_recup_objintegr_id( ev_cd => '50' )); -- Demais Documentos e Operações - Bloco F EFD Contribuições
      --
   end if ;
   --
   vn_fase := 7;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_bemativimobopercredpc
   if nvl(est_row_bemativimobopercredpc.basecalccredpc_id,0) = 0 then
      est_row_bemativimobopercredpc.basecalccredpc_id := pk_csf_efd_pc.fkg_Base_Calc_Cred_Pc_id ( ev_cd  =>  ev_basecalccredpc_cd );
   end if;
   --
   vn_fase := 8;
   --
   if nvl(est_row_bemativimobopercredpc.codst_id_pis,0) = 0 then
      est_row_bemativimobopercredpc.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                         , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
   end if;
   --
   vn_fase := 9;
   --
   if nvl(est_row_bemativimobopercredpc.codst_id_cofins,0) = 0 then
      est_row_bemativimobopercredpc.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                            , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS
   end if;
   --
   vn_fase := 10;
   --
   if nvl(est_row_bemativimobopercredpc.planoconta_id,0) = 0 then
      est_row_bemativimobopercredpc.planoconta_id := pk_csf.fkg_Plano_Conta_id ( ev_cod_cta    =>  ev_cod_cta
                                                                               , en_empresa_id =>  est_row_bemativimobopercredpc.empresa_id );
   end if;
   --
   vn_fase := 11;
   --
   if nvl(est_row_bemativimobopercredpc.centrocusto_id,0) = 0 then
      est_row_bemativimobopercredpc.centrocusto_id := pk_csf.fkg_Centro_Custo_id ( ev_cod_ccus   => ev_cod_ccus
                                                                                 , en_empresa_id => est_row_bemativimobopercredpc.empresa_id );
   end if;
   --
   vn_fase := 12;
   --
   gn_referencia_id            := null;
   vn_bemativimobopercredpc_id := null;
   -- 
   --verifica se existe na tabela o registro e retorna o id da tabela
   if nvl(est_row_bemativimobopercredpc.id,0) = 0 then 
     ---
     begin
     -- 
       select id
         into vn_bemativimobopercredpc_id
         from bem_ativ_imob_oper_cred_pc 
        where empresa_id              = est_row_bemativimobopercredpc.empresa_id
          and ano_ref                 = est_row_bemativimobopercredpc.ano_ref
          and mes_ref                 = est_row_bemativimobopercredpc.mes_ref
          and dm_tipo_oper            = est_row_bemativimobopercredpc.dm_tipo_oper
          and basecalccredpc_id       = est_row_bemativimobopercredpc.basecalccredpc_id
          and codst_id_pis            = est_row_bemativimobopercredpc.codst_id_pis
          and codst_id_cofins         = est_row_bemativimobopercredpc.codst_id_cofins
          --
          /*and planoconta_id           = nvl(est_row_bemativimobopercredpc.planoconta_id ,planoconta_id )
          and centrocusto_id          = nvl(est_row_bemativimobopercredpc.centrocusto_id,centrocusto_id)*/
          and (planoconta_id          = nvl(est_row_bemativimobopercredpc.planoconta_id ,planoconta_id ) or planoconta_id is null)
          and (centrocusto_id         = nvl(est_row_bemativimobopercredpc.centrocusto_id,centrocusto_id) or centrocusto_id is null)        
          and vl_oper_dep             = nvl(est_row_bemativimobopercredpc.vl_oper_dep   ,vl_oper_dep   )     
          and vl_bc_cred              = nvl(est_row_bemativimobopercredpc.vl_bc_cred    ,vl_bc_cred    )  
          and vl_bc_pis               = nvl(est_row_bemativimobopercredpc.vl_bc_pis     ,vl_bc_pis     )   
          and vl_pis                  = nvl(est_row_bemativimobopercredpc.vl_pis        ,vl_pis        )   
          and vl_bc_cofins            = nvl(est_row_bemativimobopercredpc.vl_bc_cofins  ,vl_bc_cofins  ) 
          and vl_cofins               = nvl(est_row_bemativimobopercredpc.vl_cofins     ,vl_cofins     )   
          and desc_bem_imob           = est_row_bemativimobopercredpc.desc_bem_imob
          --
          and dm_ind_orig_cred        = est_row_bemativimobopercredpc.dm_ind_orig_cred
          and dm_ind_util_bem_imob    = est_row_bemativimobopercredpc.dm_ind_util_bem_imob 
          and (mes_ano_oper_aquis     = nvl(est_row_bemativimobopercredpc.mes_ano_oper_aquis,mes_ano_oper_aquis) or mes_ano_oper_aquis is null)
          and (dm_ind_nr_parc         = nvl(est_row_bemativimobopercredpc.dm_ind_nr_parc,dm_ind_nr_parc)         or dm_ind_nr_parc is null) 
          and dm_ident_bem_imob       = est_row_bemativimobopercredpc.dm_ident_bem_imob          
          ;        
     --
     exception
       when no_data_found then
         vn_bemativimobopercredpc_id := null;
       when others then
         null;
     end ;
     ---
   else  
     ---
     vn_bemativimobopercredpc_id      := est_row_bemativimobopercredpc.id;
     est_row_bemativimobopercredpc.id := null;
     --- 
   end if;
   --
   vn_fase := 13;
   --
   -- Se o id for nulo busca valor da sequence
   if (nvl(vn_bemativimobopercredpc_id,0) <= 0 or vn_bemativimobopercredpc_id is null ) then
      -- 
      select bemativimobopercredpc_seq.nextval
        into est_row_bemativimobopercredpc.id
        from dual;
      --
      gn_referencia_id := est_row_bemativimobopercredpc.id;
      --
   else
      --
      gn_referencia_id := vn_bemativimobopercredpc_id;
      --   
   end if;
   --   
   vn_fase := 14;
   --
   if nvl(est_row_bemativimobopercredpc.planoconta_id,0) = 0 and trim(ev_cod_cta) is not null then
     --
     vn_fase := 14.1;
     --
     gv_resumo := null;
     --
     gv_resumo := '"Código do plano de conta não encontrado na base compliance" ('||trim(ev_cod_cta)||').';
     --
     vn_loggenerico_id := null;
     --
     pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                          , ev_mensagem          => gv_mensagem
                          , ev_resumo            => gv_resumo
                          , en_tipo_log          => erro_de_validacao
                          , en_referencia_id     => gn_referencia_id
                          , ev_obj_referencia    => gv_obj_referencia
                          , en_empresa_id        => gn_empresa_id
                          );
     --
     -- Armazena o "loggenerico_id" na memória
     pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                             , est_log_generico_ddo => est_log_generico_ddo );
     --
   end if;
   --
   vn_fase := 15;
   --
   if nvl(est_row_bemativimobopercredpc.centrocusto_id,0) = 0 and trim(ev_cod_ccus) is not null then
      --
         vn_fase := 15.1;
         --
         gv_resumo := null;
         --
         gv_resumo := '"Código do Centro de Custo não encontrado na base compliance" ('||trim(ev_cod_ccus)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   end if;
   --
   vn_fase := 16;
   --
   if nvl(est_row_bemativimobopercredpc.mes_ref,0) < 0 then
      --
      vn_fase := 16.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Mês Referência do lançamento deve ser informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
      --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
      goto sair_integracao;
      --
   elsif nvl(est_row_bemativimobopercredpc.mes_ref,0) not between 1 and 12 then
         --
         vn_fase := 16.2;
         --
         gv_resumo := null;
         --
         gv_resumo := 'Mês Referência inválido ('||est_row_bemativimobopercredpc.mes_ref||'), deve estar entre 1 e 12.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   end if;
   --
   vn_fase := 17;
   --
   if nvl(est_row_bemativimobopercredpc.ano_ref,0) < 0 then
      --
      vn_fase := 14.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Ano Referência do lançamento deve ser informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
      --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
      goto sair_integracao;
      --
   end if;
   --
   vn_fase := 18;
   --
   if nvl(est_row_bemativimobopercredpc.dm_tipo_oper,-1) not in (0,1) then
      --
      vn_fase := 18.1;
      --
      gv_resumo := null;
      --
      if est_row_bemativimobopercredpc.dm_tipo_oper is not null then
         gv_resumo := '"Tipo de Operação" informado incorretamente ('||est_row_bemativimobopercredpc.dm_tipo_oper||'). Informar: 0-Depreciação/Amortização '||
                      'ou 1-Aquisição/Contribuição.';
      else
         gv_resumo := '"Tipo de Operação" não informado, deve ser 0-Depreciação/Amortização ou 1-Aquisição/Contribuição.';
      end if;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 19;
   --
   if nvl(est_row_bemativimobopercredpc.basecalccredpc_id,0) = 0 and trim(ev_basecalccredpc_cd) is not null then
      --
         vn_fase := 19.1;
         --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Base de Cálculo do Crédito" não encontrado na base Compliance: ('||trim(ev_basecalccredpc_cd)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
         vn_fase := 19.2;
         --
         if (est_row_bemativimobopercredpc.dm_tipo_oper = 0 and ev_basecalccredpc_cd not in ('09','11')) or
            (est_row_bemativimobopercredpc.dm_tipo_oper = 1 and ev_basecalccredpc_cd not in ('10')) then
            --
            vn_fase := 19.3;
            --
            gv_resumo := null;
            --
            gv_resumo := '"Código da Base de Cálculo do Crédito" ('||ev_basecalccredpc_cd||'), inválido para o "Indicador do Tipo de Operação" ('||
                         pk_csf.fkg_dominio('BEM_ATIV_IMOB_OPER_CRED_PC.DM_TIPO_OPER',est_row_bemativimobopercredpc.dm_tipo_oper)||'). Para o Tipo de '||
                         'Operação sendo "Depreciação/Amortização", será permitido somente os "Códigos de Base de Cálculo de Crédito" como sendo "09-Máquinas, '||
                         'equipamentos e outros bens incorporados ao ativo imobilizado (crédito sobre encargos de depreciação)", ou "11-Amortização e '||
                         'Depreciação de edificações e benfeitorias em imóveis". Para o Tipo de Operação sendo "Aquisição/Contribuição", será permitido '||
                         'somente o "Código de Base de Cálculo de Crédito" como sendo "10-Máquinas, equipamentos e outros bens incorporados ao ativo '||
                         'imobilizado (crédito com base no valor de aquisição)".';
            --
            vn_loggenerico_id := null;
            --
            pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                                 , ev_mensagem          => gv_mensagem
                                 , ev_resumo            => gv_resumo
                                 , en_tipo_log          => erro_de_validacao
                                 , en_referencia_id     => gn_referencia_id
                                 , ev_obj_referencia    => gv_obj_referencia
                                 , en_empresa_id        => gn_empresa_id
                                  );
            --
            -- Armazena o "loggenerico_id" na memória
            pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                    , est_log_generico_ddo => est_log_generico_ddo );
         --
         --#69214 inclusao de saida pq campo eh obrigatorio na integracao
         goto sair_integracao;
         --
      end if;
      --
   elsif nvl(est_row_bemativimobopercredpc.basecalccredpc_id,0) = 0 then
      --
      vn_fase := 19.4;
      --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Base de Cálculo do Crédito" deve ser informado.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
         --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
         goto sair_integracao;
         --
   end if;
   --
   vn_fase := 20;
   --
   if nvl(est_row_bemativimobopercredpc.dm_ident_bem_imob,-1) not in ('01','02','03','04','05','06','99') then
      --
      vn_fase := 20.1;
      --
      gv_resumo := null;
      --
      if est_row_bemativimobopercredpc.dm_ident_bem_imob is not null then
         gv_resumo := '"Identificação dos Bens/Grupo de Bens" informado incorretamente ('||est_row_bemativimobopercredpc.dm_ident_bem_imob||'). Informar: '||
                      '01-Edificações e Benfeitorias em Imóveis Próprios, 02-Edificações e Benfeitorias em Imóveis de Terceiros, 03-Instalações, 04-Máquinas'||
                      ', 05-Equipamentos, 06-Veículos, ou, 99-Outros Bens Incorporados ao Ativo Imobilizado.';
      else
         gv_resumo := '"Identificação dos Bens/Grupo de Bens" deve ser informado.';
      end if;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 21;
   --
   if nvl(est_row_bemativimobopercredpc.dm_ind_orig_cred, -1) not in (0,1) then
      --
      vn_fase := 21.1;
      --
      gv_resumo := null;
      --
      if est_row_bemativimobopercredpc.dm_ind_orig_cred is not null then
         gv_resumo := '"Identificador da Origem de Crédito" do bem incorporado informado incorretamente ('||est_row_bemativimobopercredpc.dm_ind_orig_cred||
                      '). Informar: 0-Aquisição no Mercado Interno ou 1-Aquisição no Mercado Externo (Importação).';
      else
         gv_resumo := '"Identificador da Origem de Crédito" do bem incorporado deve ser informado.';
      end if;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 22;
   --
   if nvl(est_row_bemativimobopercredpc.dm_ind_util_bem_imob, -1) not in (1,2,3,9) then
      --
      vn_fase := 22.1;
      --
      gv_resumo := null;
      --
      if est_row_bemativimobopercredpc.dm_ind_util_bem_imob is not null then
         gv_resumo := '"Identificador da Utilização dos Bens Incorporados" informado incorretamente ('||est_row_bemativimobopercredpc.dm_ind_util_bem_imob||
                      '). Informar: 1-Produção de Bens Destinados a Venda, 2-Prestação de Serviços, 3-Locação a Terceiros ou, 9-Outros.';
      else
         gv_resumo := '"Identificador da Utilização dos Bens Incorporados" deve ser informado.';
      end if;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
      --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
      goto sair_integracao;
      --
   end if;
   --
   vn_fase := 23;
   --
   if est_row_bemativimobopercredpc.mes_ano_oper_aquis is not null then
      --
      vn_fase := 23.1;
      --
      if nvl(est_row_bemativimobopercredpc.mes_ano_oper_aquis,0) <> 0 and
         substr(lpad(nvl(est_row_bemativimobopercredpc.mes_ano_oper_aquis,0),6,'0'),1,2) not between 1 and 12 then
         --
         vn_fase := 23.2;
         --
         gv_resumo := null;
         --
         gv_resumo := 'Mês de aquisição dos bens incorporados deve estar entre 1 e 12.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                             , en_empresa_id        => gn_empresa_id
                             );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      else
         --
         vn_fase := 23.3;
         --
         begin
            vd_data := to_date(lpad(est_row_bemativimobopercredpc.mes_ano_oper_aquis,6,'0'),'mmrrrr');
         exception
            when others then
               --
               gv_resumo := null;
               --
               gv_resumo := 'Mês/Ano de aquisição dos bens incorporados ('||lpad(est_row_bemativimobopercredpc.mes_ano_oper_aquis,6,'0')||
                            ') deve ser válido como data, e estar no formato MMAAAA.';
               --
               vn_loggenerico_id := null;
               --
               pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                                    , ev_mensagem          => gv_mensagem
                                    , ev_resumo            => gv_resumo
                                    , en_tipo_log          => erro_de_validacao
                                    , en_referencia_id     => gn_referencia_id
                                    , ev_obj_referencia    => gv_obj_referencia
                                    , en_empresa_id        => gn_empresa_id
                                    );
               --
               -- Armazena o "loggenerico_id" na memória
               pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                       , est_log_generico_ddo => est_log_generico_ddo );
               --
         end;
         --
      end if;
      --
   end if;
   --
   vn_fase := 24;
   --
   if est_row_bemativimobopercredpc.vl_oper_aquis is not null then
      --
      vn_fase := 24.1;
      --
      if nvl(est_row_bemativimobopercredpc.vl_oper_aquis,0) < 0 then
         --
         vn_fase := 24.2;
         --
         gv_resumo := null;
         --
         gv_resumo := 'Valor de Aquisição dos Bens Incorporados ao Ativo Imobilizado não pode ser menor que zero.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      end if;
      --
   end if;
   --
   vn_fase := 25;
   --
   if est_row_bemativimobopercredpc.vl_oper_dep is not null then
      --
      vn_fase := 25.1;
      --
      if nvl(est_row_bemativimobopercredpc.vl_oper_dep,0) < 0 then
         --
         vn_fase := 25.2;
         --
         gv_resumo := null;
         --
         gv_resumo := 'Valor do Encargo de Depreciação/Amortização não pode ser menor que zero.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      end if;
      --
   end if;
   --
   vn_fase := 26;
   --
   if nvl(est_row_bemativimobopercredpc.vl_bc_cred,0) < 0 then
      --
      vn_fase := 26.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor da Base de Cálculo do Credito não pode ser menor que zero.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_bemativimobopercredpc.dm_tipo_oper,0) = 0 and -- Depreciação/Amortização
         nvl(est_row_bemativimobopercredpc.vl_bc_cred,0) <> (nvl(est_row_bemativimobopercredpc.vl_oper_dep,0) - nvl(est_row_bemativimobopercredpc.parc_oper_nao_bc_cred,0)) then
         --
         vn_fase := 26.2;
         --
         gv_resumo := null;
         --
         gv_resumo := 'Para o indicador do tipo de operação "Depreciação/Amortização", o valor da base de cálculo do crédito sobre bens incorporados ao ativo '||
                      'imobilizado('||ltrim(to_char(nvl(est_row_bemativimobopercredpc.vl_bc_cred,0),'999G999G999G990D00'))||') deve ser igual ao '||
                      'cálculo: (valor do encargo de depreciação - parcela do valor de aquisição a excluir) -> ('||
                      ltrim(to_char(nvl(est_row_bemativimobopercredpc.vl_oper_dep,0),'999G999G999G990D00'))||' - '||
                      ltrim(to_char(nvl(est_row_bemativimobopercredpc.parc_oper_nao_bc_cred,0),'999G999G999G990D00'))||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   elsif nvl(est_row_bemativimobopercredpc.dm_tipo_oper,0) = 1 and -- Aquisição/Contribuição
         nvl(est_row_bemativimobopercredpc.vl_bc_cred,0) <> (nvl(est_row_bemativimobopercredpc.vl_oper_aquis,0) - nvl(est_row_bemativimobopercredpc.parc_oper_nao_bc_cred,0)) then
         --
         vn_fase := 26.3;
         --
         gv_resumo := null;
         --
         gv_resumo := 'Para o indicador do tipo de operação "Aquisição/Contribuição", o valor da base de cálculo do crédito sobre bens incorporados ao ativo '||
                      'imobilizado ('||ltrim(to_char(nvl(est_row_bemativimobopercredpc.vl_bc_cred,0),'999G999G999G990D00'))||') deve ser igual ao cálculo: '||
                      '(valor da aquisição - parcela do valor de aquisição a excluir) -> ('||
                      ltrim(to_char(nvl(est_row_bemativimobopercredpc.vl_oper_aquis,0),'999G999G999G990D00'))||' - '||
                      ltrim(to_char(nvl(est_row_bemativimobopercredpc.parc_oper_nao_bc_cred,0),'999G999G999G990D00'))||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   end if;
   --
   vn_fase := 27;
   --
   if nvl(est_row_bemativimobopercredpc.dm_tipo_oper,0) = 1 then -- 1-Aquisição/Contribuição
      --
      vn_fase := 27.1;
      --
      if est_row_bemativimobopercredpc.dm_ind_nr_parc is null then
         --
         vn_fase := 27.2;
         --
         gv_resumo := null;
         --
         gv_resumo := 'O "Indicador do Número de Parcelas" deve ser informado quando o Tipo de Operação indicar Aquisição/Contribuição.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      elsif nvl(est_row_bemativimobopercredpc.dm_ind_nr_parc,0) not in (1,2,3,4,5,9) then
            --
            vn_fase := 27.3;
            --
            gv_resumo := null;
            --
            gv_resumo := '"Indicador do Número de Parcelas" informado incorretamente (' ||est_row_bemativimobopercredpc.dm_ind_nr_parc|| '). Os possíveis '||
                         'valores são: 1-Integral (Mês de Aquisição), 2-12 Meses, 3-24 Meses, 4-48 Meses, 5-6 Meses (Embalagens de bebidas frias), 9-Outra '||
                         'periodicidade definida em Lei.';
            --
            vn_loggenerico_id := null;
            --
            pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                                 , ev_mensagem          => gv_mensagem
                                 , ev_resumo            => gv_resumo
                                 , en_tipo_log          => erro_de_validacao
                                 , en_referencia_id     => gn_referencia_id
                                 , ev_obj_referencia    => gv_obj_referencia
                                 , en_empresa_id        => gn_empresa_id
                                 );
            --
            -- Armazena o "loggenerico_id" na memória
            pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                    , est_log_generico_ddo => est_log_generico_ddo );
            --
      end if;
      --
   else -- nvl(est_row_bemativimobopercredpc.dm_tipo_oper,0) = 0 -- 0-Depreciação/Amortização
      --
      vn_fase := 27.4;
      --
      if est_row_bemativimobopercredpc.dm_ind_nr_parc is not null then
         --
         vn_fase := 27.5;
         --
         gv_resumo := null;
         --
         gv_resumo := 'O "Indicador do Número de Parcelas" não deve ser informado devido ao Tipo de Operação ser Depreciação/Amortização.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
      end if;
      --
   end if;
   --
   vn_fase := 28;
   --
   if nvl(est_row_bemativimobopercredpc.codst_id_pis,0) = 0 and trim(ev_cod_st_pis) is not null then
      --
         vn_fase := 28.1;
         --
         gv_resumo := '"Código da Situação Tributaria dos Impostos não encontrado na base Compliance:" ('||trim(ev_cod_st_pis)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_bemativimobopercredpc.codst_id_pis,0) = 0 then
      --
      vn_fase := 28.2;
      --
      gv_resumo := '"Não foi informado o Código da Situação Tributaria do imposto do PIS.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
      --#69214 inclusao de saida pq campo eh obrigatorio na ntegracao
      goto sair_integracao;
      --
   end if;
   --
   vn_fase := 29;
   --
   if nvl(est_row_bemativimobopercredpc.vl_bc_pis,0) < 0 then
      --
      vn_fase := 29.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor da Base de Cálculo do PIS não pode ser menor que zero.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 30;
   --
   if nvl(est_row_bemativimobopercredpc.aliq_pis,0) < 0 then
      --
      vn_fase := 30.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor da Alíquota PIS não pode ser menor que zero.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 31;
   --
   if nvl(est_row_bemativimobopercredpc.vl_pis,0) < 0 then
      --
      vn_fase := 31.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor do PIS não pode ser menor que zero.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_bemativimobopercredpc.vl_pis,0) <> round((nvl(est_row_bemativimobopercredpc.vl_bc_pis,0) * (nvl(est_row_bemativimobopercredpc.aliq_pis,0) / 100)),2) then
         --
         vn_fase := 31.2;
         --
         gv_resumo := null;
         --
         gv_resumo := 'O valor do crédito de PIS/PASEP ('||ltrim(to_char(nvl(est_row_bemativimobopercredpc.vl_pis,0),'999G999G999G990D00'))||') deve ser '||
                      'igual ao cálculo (vl_bc_pis * (aliq_pis / 100)) -> ('||ltrim(to_char(nvl(est_row_bemativimobopercredpc.vl_bc_pis,0),'999G999G999G990D00'))||
                      ' * ('||ltrim(to_char(nvl(est_row_bemativimobopercredpc.aliq_pis,0),'9G990D0000'))||' / 100)).';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   end if;
   --
   vn_fase := 32;
   --
   if nvl(est_row_bemativimobopercredpc.codst_id_cofins,0) = 0 and trim(ev_cod_st_cofins) is not null then
      --
      vn_fase := 32.1;
         --
         gv_resumo := '"Código da Situação Tributaria dos Impostos COFINS não encontrado na base Compliance:" ('||trim(ev_cod_st_cofins)||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_bemativimobopercredpc.codst_id_cofins,0) = 0 then
      --
      vn_fase := 32.2;
      --
      if est_row_bemativimobopercredpc.codst_id_cofins is null then
         --
         gv_resumo := '"Código da Situação Tributaria do Imposto COFINS não informado.';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                              , ev_obj_referencia    => gv_obj_referencia
                              , en_empresa_id        => gn_empresa_id
                              );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
         --#68654 --sai pq o campo é obrigatorio no insert/update
         goto sair_integracao;
         --
      end if;
      --
   end if;
   --
   vn_fase := 33;
   --
   if nvl(est_row_bemativimobopercredpc.vl_bc_cofins,0) < 0 then
      --
      vn_fase := 33.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor da Base de Cálculo da COFINS não pode ser menor que zero.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 34;
   --
   if nvl(est_row_bemativimobopercredpc.aliq_cofins,0) < 0 then
      --
      vn_fase := 34.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor da Alíquota COFINS não pode ser menor que zero.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   end if;
   --
   vn_fase := 35;
   --
   if nvl(est_row_bemativimobopercredpc.vl_cofins,0) < 0 then
      --
      vn_fase := 35.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Valor do COFINS não pode ser menor que zero.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_bemativimobopercredpc.vl_cofins,0) <> round((nvl(est_row_bemativimobopercredpc.vl_bc_cofins,0) * (nvl(est_row_bemativimobopercredpc.aliq_cofins,0) / 100)),2) then
         --
         vn_fase := 35.2;
         --
         gv_resumo := null;
         --
         gv_resumo := 'O valor do crédito de COFINS ('||ltrim(to_char(nvl(est_row_bemativimobopercredpc.vl_cofins,0),'999G999G999G990D00'))||') deve ser '||
                      'igual ao cálculo (vl_bc_cofins * (aliq_cofins / 100)) -> ('||ltrim(to_char(nvl(est_row_bemativimobopercredpc.vl_bc_cofins,0),'999G999G999G990D00'))||
                      ' * ('||ltrim(to_char(nvl(est_row_bemativimobopercredpc.aliq_cofins,0),'9G990D0000'))||' / 100)).';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
         --
   end if;
   --
   vn_fase := 36;
   --
   if (pk_int_view_ddo.gd_dt_ult_fecha is null) or (to_date((lpad(est_row_bemativimobopercredpc.mes_ref,2,'0')||est_row_bemativimobopercredpc.ano_ref),'mm/rrrr') < pk_int_view_ddo.gd_dt_ult_fecha) then
      --
      vn_fase := 36.1;
      --
      gv_resumo := null;
      --
      gv_resumo := 'Período informado para integração de Demais Documentos e Operações - Bloco F EFD-'||
                   'Contribuições (Bloco F120 e F130), está fechado para a data do registro. Data de fechamento fiscal '||
                   to_char(pk_int_view_ddo.gd_dt_ult_fecha,'dd/mm/yyyy')||' - CNPJ/CPF: '||ev_cnpj_empr||'.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
      --
   end if;
   --
   vn_fase := 37;
   --
   if (nvl(est_row_bemativimobopercredpc.id,0) > 0 or vn_bemativimobopercredpc_id > 0 ) 
    and nvl(est_row_bemativimobopercredpc.dm_tipo_oper,0) in (0,1)     
     and est_row_bemativimobopercredpc.dm_ident_bem_imob is not null  
      and nvl(est_row_bemativimobopercredpc.dm_ind_orig_cred,0) in (0,1)     
       and nvl(est_row_bemativimobopercredpc.dm_ind_util_bem_imob,0) in (1,2,3,9)  then
      --
      vn_fase := 37.1;
      --
      if nvl(est_row_bemativimobopercredpc.id,0) > 0  then 
        --
        begin
           insert into bem_ativ_imob_oper_cred_pc ( id
                                                     , empresa_id
                                                     , ano_ref
                                                     , mes_ref
                                                     , dm_tipo_oper
                                                     , basecalccredpc_id
                                                     , dm_ident_bem_imob
                                                     , dm_ind_orig_cred
                                                     , dm_ind_util_bem_imob
                                                     , mes_ano_oper_aquis
                                                     , vl_oper_aquis
                                                     , vl_oper_dep
                                                     , parc_oper_nao_bc_cred
                                                     , vl_bc_cred
                                                     , dm_ind_nr_parc
                                                     , codst_id_pis
                                                     , vl_bc_pis
                                                     , aliq_pis
                                                     , vl_pis
                                                     , codst_id_cofins
                                                     , vl_bc_cofins
                                                     , aliq_cofins
                                                     , vl_cofins
                                                     , planoconta_id
                                                     , centrocusto_id
                                                     , desc_bem_imob
                                                     , dm_st_proc
                                                     , dm_st_integra )
                                              values ( est_row_bemativimobopercredpc.id
                                                     , est_row_bemativimobopercredpc.empresa_id
                                                     , est_row_bemativimobopercredpc.ano_ref
                                                     , est_row_bemativimobopercredpc.mes_ref
                                                     , est_row_bemativimobopercredpc.dm_tipo_oper
                                                     , est_row_bemativimobopercredpc.basecalccredpc_id
                                                     , est_row_bemativimobopercredpc.dm_ident_bem_imob
                                                     , est_row_bemativimobopercredpc.dm_ind_orig_cred
                                                     , est_row_bemativimobopercredpc.dm_ind_util_bem_imob
                                                     , est_row_bemativimobopercredpc.mes_ano_oper_aquis
                                                     , nvl(est_row_bemativimobopercredpc.vl_oper_aquis,0)
                                                     , nvl(est_row_bemativimobopercredpc.vl_oper_dep,0)
                                                     , nvl(est_row_bemativimobopercredpc.parc_oper_nao_bc_cred,0)
                                                     , nvl(est_row_bemativimobopercredpc.vl_bc_cred,0)
                                                     , est_row_bemativimobopercredpc.dm_ind_nr_parc
                                                     , est_row_bemativimobopercredpc.codst_id_pis
                                                     , nvl(est_row_bemativimobopercredpc.vl_bc_pis,0)
                                                     , nvl(est_row_bemativimobopercredpc.aliq_pis,0)
                                                     , nvl(est_row_bemativimobopercredpc.vl_pis,0)
                                                     , est_row_bemativimobopercredpc.codst_id_cofins
                                                     , nvl(est_row_bemativimobopercredpc.vl_bc_cofins,0)
                                                     , nvl(est_row_bemativimobopercredpc.aliq_cofins,0)
                                                     , nvl(est_row_bemativimobopercredpc.vl_cofins,0)
                                                     , est_row_bemativimobopercredpc.planoconta_id
                                                     , est_row_bemativimobopercredpc.centrocusto_id
                                                     , est_row_bemativimobopercredpc.desc_bem_imob
                                                     , est_row_bemativimobopercredpc.dm_st_proc
                                                     , est_row_bemativimobopercredpc.dm_st_integra );
           --
           commit;
           --
        exception
           when others then
              --
              gv_resumo := null;
              --
              gv_resumo := 'Problemas ao incluir o registro - Bloco F120/F130. Erro = '||sqlerrm;
              --
              vn_loggenerico_id := null;
              --
              pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                                   , ev_mensagem          => gv_mensagem
                                   , ev_resumo            => gv_resumo
                                   , en_tipo_log          => erro_de_validacao
                                   , en_referencia_id     => gn_referencia_id
                                   , ev_obj_referencia    => gv_obj_referencia
                                   , en_empresa_id        => gn_empresa_id
                                   );
              --
              -- Armazena o "loggenerico_id" na memória
              pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                      , est_log_generico_ddo => est_log_generico_ddo );
              --
        end;
        --
     else
        --
        vn_fase := 37.3;
        --
        begin
           update bem_ativ_imob_oper_cred_pc ba
                 set ba.empresa_id            = est_row_bemativimobopercredpc.empresa_id
                   , ba.ano_ref               = est_row_bemativimobopercredpc.ano_ref
                   , ba.mes_ref               = est_row_bemativimobopercredpc.mes_ref
                   , ba.dm_tipo_oper          = est_row_bemativimobopercredpc.dm_tipo_oper
                   , ba.basecalccredpc_id     = est_row_bemativimobopercredpc.basecalccredpc_id
                   , ba.dm_ident_bem_imob     = est_row_bemativimobopercredpc.dm_ident_bem_imob
                   , ba.dm_ind_orig_cred      = est_row_bemativimobopercredpc.dm_ind_orig_cred
                   , ba.dm_ind_util_bem_imob  = est_row_bemativimobopercredpc.dm_ind_util_bem_imob
                   , ba.mes_ano_oper_aquis    = est_row_bemativimobopercredpc.mes_ano_oper_aquis
                   , ba.vl_oper_aquis         = nvl(est_row_bemativimobopercredpc.vl_oper_aquis,0)
                   , ba.vl_oper_dep           = nvl(est_row_bemativimobopercredpc.vl_oper_dep,0)
                   , ba.parc_oper_nao_bc_cred = nvl(est_row_bemativimobopercredpc.parc_oper_nao_bc_cred,0)
                   , ba.vl_bc_cred            = nvl(est_row_bemativimobopercredpc.vl_bc_cred,0)
                   , ba.dm_ind_nr_parc        = est_row_bemativimobopercredpc.dm_ind_nr_parc
                   , ba.codst_id_pis          = est_row_bemativimobopercredpc.codst_id_pis
                   , ba.vl_bc_pis             = nvl(est_row_bemativimobopercredpc.vl_bc_pis,0)
                   , ba.aliq_pis              = nvl(est_row_bemativimobopercredpc.aliq_pis,0)
                   , ba.vl_pis                = nvl(est_row_bemativimobopercredpc.vl_pis,0)
                   , ba.codst_id_cofins       = est_row_bemativimobopercredpc.codst_id_cofins
                   , ba.vl_bc_cofins          = nvl(est_row_bemativimobopercredpc.vl_bc_cofins,0)
                   , ba.aliq_cofins           = nvl(est_row_bemativimobopercredpc.aliq_cofins,0)
                   , ba.vl_cofins             = nvl(est_row_bemativimobopercredpc.vl_cofins,0)
                   , ba.planoconta_id         = est_row_bemativimobopercredpc.planoconta_id
                   , ba.centrocusto_id        = est_row_bemativimobopercredpc.centrocusto_id
                   , ba.desc_bem_imob         = est_row_bemativimobopercredpc.desc_bem_imob
                   , ba.dm_st_proc            = est_row_bemativimobopercredpc.dm_st_proc
                   , ba.dm_st_integra         = est_row_bemativimobopercredpc.dm_st_integra
               where ba.id                    = vn_bemativimobopercredpc_id --#68654 --est_row_bemativimobopercredpc.id --#69
                 and ba.dm_st_proc not in (1);  --Validada
           --
           commit;
           --
           --#68654 incluido atribuicao da variavel do update na variavel global
           est_row_bemativimobopercredpc.id := vn_bemativimobopercredpc_id ;
           --
        exception
           when others then
              --
              gv_resumo := null;
              --
              gv_resumo := 'Problemas ao alterar o registro - Bloco F120/F130. Erro = '||sqlerrm;
              --
              vn_loggenerico_id := null;
              --
              pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                                   , ev_mensagem          => gv_mensagem
                                   , ev_resumo            => gv_resumo
                                   , en_tipo_log          => erro_de_validacao
                                   , en_referencia_id     => gn_referencia_id
                                   , ev_obj_referencia    => gv_obj_referencia
                                   , en_empresa_id        => gn_empresa_id
                                   );
              --
              -- Armazena o "loggenerico_id" na memória
              pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                      , est_log_generico_ddo => est_log_generico_ddo );
              --
        end;
        --
      end if;
      --
   end if;
   --
   -- #68654 - Sair da Integração quando a erro de campo obrigatorio
   <<sair_integracao>>
   --
   null;
   --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pk_csf_api_ddo.pkb_integr_bemativimobopcredpc fase ('||vn_fase||'): ' || sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_bemativimobopcredpc;
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela PR_DEM_DOC_OPER_GER_CC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_prdemdocopergercc ( est_log_generico_ddo      in out nocopy  dbms_sql.number_table
                                       , est_row_prdemdocopergercc in out nocopy  pr_dem_doc_oper_ger_cc%rowtype
                                       , ev_cpf_cnpj               in             varchar2
                                       , en_cd_origproc            in             number ) is
   --
   vn_fase                 number := null;
   vn_loggenerico_id       log_generico_ddo.id%type;
   vn_id                   pr_dem_doc_oper_ger_cc.id%type := null;
   vn_prdemdocopergercc_id pr_dem_doc_oper_ger_cc.id%type := null;
   vn_dm_st_proc           number(1) := null;
   --
begin
   --
   vn_fase := 1;
   --
   gv_mensagem := null;
   gv_mensagem := 'Empresa: '||ev_cpf_cnpj;
   gv_mensagem := gv_mensagem || chr(10);
   -- Recebe o id da tabela pai, pq é essa tabela q a tela busca como objetos de referencia
   gn_referencia_id := est_row_prdemdocopergercc.demdocopergercc_id;
   --
   if gv_obj_referencia is null then gv_obj_referencia := 'DEM_DOC_OPER_GER_CC'; end if;
   --
   -- Buscando dados para usar na procedure pk_csf_ddo.pkb_prdemdocopergercc
   if nvl(est_row_prdemdocopergercc.origproc_id,0) = 0 then
      est_row_prdemdocopergercc.origproc_id    := pk_csf.fkg_Orig_Proc_id( en_cd    =>   en_cd_origproc );
   end if;
   --
   -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_prdemdocopergercc ( en_demdocopergercc_id   => est_row_prdemdocopergercc.demdocopergercc_id
                                       , en_origproc_id          => est_row_prdemdocopergercc.origproc_id
                                       , sn_prdemdocopergercc_id => vn_prdemdocopergercc_id
                                       , sn_dm_st_proc           => vn_dm_st_proc );
      --
   exception
      when others then
         vn_prdemdocopergercc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_prdemdocopergercc.id,0) <= 0 and nvl(vn_prdemdocopergercc_id,0) <= 0 then
      -- pr_dem_doc_oper_ger_cc
      select prdemdocopergercc_seq.nextval
        into est_row_prdemdocopergercc.id
        from dual;
      --
      vn_id := est_row_prdemdocopergercc.id;
      --
   elsif nvl(est_row_prdemdocopergercc.id,0) <= 0 and nvl(vn_prdemdocopergercc_id,0) > 0 then
      --
      est_row_prdemdocopergercc.id := vn_prdemdocopergercc_id;
      --
   elsif nvl(est_row_prdemdocopergercc.id,0) > 0 and nvl(est_row_prdemdocopergercc.id,0) <> nvl(vn_prdemdocopergercc_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_prdemdocopergercc.id||') está diferente do id encontrado '||vn_prdemdocopergercc_id||' para o registro na tabela PR_DEM_DOC_OPER_GER_CC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
   --
   vn_fase := 1.51;
   --
   --| Validar registros
   if nvl(est_row_prdemdocopergercc.origproc_id, 0) = 0 and en_cd_origproc is not null then
      --
         vn_fase := 1.52;
         --
         gv_resumo := null;
         --
         gv_resumo := '"Código da Origem do Processo não encontrado na base Compliance:" ('|| en_cd_origproc ||').';
         --
         vn_loggenerico_id := null;
         --
         pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                              , ev_mensagem          => gv_mensagem
                              , ev_resumo            => gv_resumo
                              , en_tipo_log          => erro_de_validacao
                              , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );

         --
         -- Armazena o "loggenerico_id" na memória
         pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                 , est_log_generico_ddo => est_log_generico_ddo );
      --
   elsif nvl(est_row_prdemdocopergercc.origproc_id, 0) = 0 then
      --
      vn_fase := 1.53;
      --
      gv_resumo := null;
      --
      gv_resumo := '"Código da Origem do Processo não informado.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --

   end if;
   --
   vn_fase := 1.54;
   --
   if nvl(est_row_prdemdocopergercc.id, 0)                > 0 and
      nvl(vn_id,0)                                        > 0 and
      nvl(est_row_prdemdocopergercc.demdocopergercc_id,0) > 0 and
      nvl(est_row_prdemdocopergercc.origproc_id,0)        > 0 and
      trim(est_row_prdemdocopergercc.num_proc)            is not null then
      --
      vn_fase := 1.55;
      --
      insert into pr_dem_doc_oper_ger_cc ( id
                                               , demdocopergercc_id
                                               , num_proc
                                               , origproc_id )
                                        values ( est_row_prdemdocopergercc.id
                                               , est_row_prdemdocopergercc.demdocopergercc_id
                                               , est_row_prdemdocopergercc.num_proc
                                               , est_row_prdemdocopergercc.origproc_id );
         --
         commit;
         --
      else
          --
          update pr_dem_doc_oper_ger_cc pd
             set pd.num_proc   = est_row_prdemdocopergercc.num_proc
           where pd.id         = est_row_prdemdocopergercc.id;
          --
          commit;
          --
       end if;
       --
exception
   when others then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Erro na pk_csf_api_ddo.pkb_integr_prdemdocopergercc fase ('||vn_fase||'). Erro = '||sqlerrm;
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_sistema
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
end pkb_integr_prdemdocopergercc;
--
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela DEM_DOC_OPER_GER_CC
----------------------------------------------------------------------------------------------------
procedure pkb_integr_demdocopergercc(est_log_generico_ddo    in out nocopy dbms_sql.number_table,
                                     est_row_demdocopergercc in out nocopy dem_doc_oper_ger_cc%rowtype,
                                     en_multorg_id           in mult_org.id%type,
                                     ev_cnpj_empr            in varchar2,
                                     ev_cod_part             in varchar2,
                                     ev_cod_item             in varchar2,
                                     ev_cod_st_pis           in varchar2,
                                     ev_cod_st_cofins        in varchar2,
                                     ev_basecalcredpc_cd     in varchar2,
                                     ev_cod_cta              in varchar2,
                                     ev_cod_ccus             in varchar2 ) is
  --
  vn_fase               number := null;
  vn_loggenerico_id     log_generico_ddo.id%type;
  vn_id                 dem_doc_oper_ger_cc.id%type := null;
  vn_demdocopergercc_id dem_doc_oper_ger_cc.id%type := null;
  vn_dm_st_proc         dem_doc_oper_ger_cc.dm_st_proc%type := null;
  --
begin
  --
  vn_fase := 1;
  --
  est_row_demdocopergercc.empresa_id := pk_csf.fkg_empresa_id_pelo_cpf_cnpj(en_multorg_id => en_multorg_id,
                                                                            ev_cpf_cnpj   => ev_cnpj_empr);
  --
  vn_fase := 1.1;
  --
  --| Montar o cabeçalho do log
  gv_mensagem       := null;
  gv_mensagem       := 'Empresa: ' || ev_cnpj_empr || ' - ' || pk_csf.fkg_nome_empresa(en_empresa_id => est_row_demdocopergercc.empresa_id);
  gv_mensagem       := gv_mensagem || chr(10);
  if gv_obj_referencia is null then gv_obj_referencia := 'DEM_DOC_OPER_GER_CC'; end if;
  --
  vn_fase := 1.2;
  --
  -- Se a data fechamento não foi carregada busca a data para validação
  if pk_int_view_ddo.gd_dt_ult_fecha is null then
     --
     pk_int_view_ddo.gd_dt_ult_fecha := pk_csf.fkg_recup_dtult_fecha_empresa( en_empresa_id   => est_row_demdocopergercc.empresa_id
                                                                            , en_objintegr_id => pk_csf.fkg_recup_objintegr_id( ev_cd => '50' )); -- Demais Documentos e Operações - Bloco F EFD Contribuições
     --
  end if ;
  --
  -- Buscando dados para usar na procedure pk_csf_ddo.pkb_consoperinspcrc
  if nvl(est_row_demdocopergercc.pessoa_id,0) = 0 then
     est_row_demdocopergercc.pessoa_id := pk_csf.fkg_pessoa_id_cod_part(en_multorg_id => en_multorg_id,
                                                                        ev_cod_part   => ev_cod_part);
  end if;
  --
  if nvl(est_row_demdocopergercc.item_id,0) = 0 then
     est_row_demdocopergercc.item_id := pk_csf.fkg_Item_id_conf_empr(en_empresa_id => est_row_demdocopergercc.empresa_id,
                                                                     ev_cod_item   => ev_cod_item);
  end if;
  --
  if nvl(est_row_demdocopergercc.codst_id_pis,0) = 0 then
     est_row_demdocopergercc.codst_id_pis := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_pis
                                                                  , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 4 ));  -- Tipo de Imp. PIS
  end if;
  --
  if nvl(est_row_demdocopergercc.codst_id_cofins,0) = 0 then
     est_row_demdocopergercc.codst_id_cofins := pk_csf.fkg_Cod_ST_id ( ev_cod_st      => ev_cod_st_cofins
                                                                     , en_tipoimp_id  => pk_csf.fkg_Tipo_Imposto_id ( en_cd => 5)); -- Tipo Imp. COFINS
  end if;
  --
  if nvl(est_row_demdocopergercc.basecalccredpc_id,0) = 0 then
     est_row_demdocopergercc.basecalccredpc_id := pk_csf_efd_pc.fkg_Base_Calc_Cred_Pc_id ( ev_cd  =>  ev_basecalcredpc_cd );
  end if;
  --
  if nvl(est_row_demdocopergercc.planoconta_id,0) = 0 then
     est_row_demdocopergercc.planoconta_id := pk_csf.fkg_Plano_Conta_id ( ev_cod_cta    =>  ev_cod_cta
                                                                        , en_empresa_id =>  est_row_demdocopergercc.empresa_id );
  end if;
  --
  if nvl(est_row_demdocopergercc.centrocusto_id,0) = 0 then
     est_row_demdocopergercc.centrocusto_id := pk_csf.fkg_Centro_Custo_id ( ev_cod_ccus   => ev_cod_ccus
                                                                          , en_empresa_id => est_row_demdocopergercc.empresa_id );
  end if;
  --
  -- Se o id for nulo verifica se existe na tabela o registro e retorna o id da tabela e o dm_st_proc
   begin
      --
      pk_csf_ddo.pkb_demdocopergercc ( en_empresa_id         => est_row_demdocopergercc.empresa_id
                                    , en_dm_ind_oper         => est_row_demdocopergercc.dm_ind_oper
                                    , en_pessoa_id           => est_row_demdocopergercc.pessoa_id
                                    , en_item_id             => est_row_demdocopergercc.item_id
                                    , en_dt_oper             => est_row_demdocopergercc.dt_oper
                                    , en_vl_oper             => est_row_demdocopergercc.vl_oper
                                    , en_codst_id_pis        => est_row_demdocopergercc.codst_id_pis
                                    , en_vl_bc_pis           => est_row_demdocopergercc.vl_bc_pis
                                    , en_aliq_pis            => est_row_demdocopergercc.aliq_pis
                                    , en_vl_pis              => est_row_demdocopergercc.vl_pis
                                    , en_codst_id_cofins     => est_row_demdocopergercc.codst_id_cofins
                                    , en_vl_bc_cofins        => est_row_demdocopergercc.vl_bc_cofins
                                    , en_aliq_cofins         => est_row_demdocopergercc.aliq_cofins
                                    , en_vl_cofins           => est_row_demdocopergercc.vl_cofins
                                    , en_basecalccredpc_id   => est_row_demdocopergercc.basecalccredpc_id
                                    , en_dm_ind_orig_cred    => est_row_demdocopergercc.dm_ind_orig_cred
                                    , en_planoconta_id       => est_row_demdocopergercc.planoconta_id
                                    , en_centrocusto_id      => est_row_demdocopergercc.centrocusto_id
                                    , en_desc_doc_oper       => est_row_demdocopergercc.desc_doc_oper
                                    , en_dm_gera_receita     => est_row_demdocopergercc.dm_gera_receita
                                    , sn_demdocopergercc_id  => vn_demdocopergercc_id
                                    , sn_dm_st_proc          => vn_dm_st_proc );
      --
   exception
      when others then
         vn_demdocopergercc_id := null;
         vn_dm_st_proc           := null;
   end;
   --
   vn_fase := 1.4;
   --
   -- Se o id for nulo busca valor da sequence
   if nvl(est_row_demdocopergercc.id,0) <= 0 and nvl(vn_demdocopergercc_id,0) <= 0 then
      -- dem_doc_oper_ger_cc
     select demdocopergercc_seq.nextval
       into est_row_demdocopergercc.id
       from dual;
      --
      vn_id := est_row_demdocopergercc.id;
      --
   elsif nvl(est_row_demdocopergercc.id,0) <= 0 and nvl(vn_demdocopergercc_id,0) > 0 then
      --
      est_row_demdocopergercc.id := vn_demdocopergercc_id;
      --
   elsif nvl(est_row_demdocopergercc.id,0) > 0 and nvl(est_row_demdocopergercc.id,0) <> nvl(vn_demdocopergercc_id,0) then
       --
       vn_fase := 1.5;
       --
       gv_resumo := null;
       --
       gv_resumo := '"O id integrado ('||est_row_demdocopergercc.id||') está diferente do id encontrado '||vn_demdocopergercc_id||' para o registro na tabela DEM_DOC_OPER_GER_CC.';
       --
       vn_loggenerico_id := null;
       --
       pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                            , ev_mensagem          => gv_mensagem
                            , ev_resumo            => gv_resumo
                            , en_tipo_log          => erro_de_validacao
                            , en_referencia_id     => est_row_demdocopergercc.id --gn_referencia_id
                            , ev_obj_referencia    => gv_obj_referencia
                            , en_empresa_id        => gn_empresa_id
                            );
       --
       -- Armazena o "loggenerico_id" na memória
       pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                               , est_log_generico_ddo => est_log_generico_ddo );
       --
   end if;
  --
  gn_referencia_id := est_row_demdocopergercc.id;
  --
  vn_fase := 1.53;
  --
  if nvl(est_row_demdocopergercc.empresa_id, 0) <= 0 then
    --
    vn_fase := 1.54;
    --
    gv_resumo := null;
    --
    gv_resumo := '"CNPJ da empresa não encontrado na base Compliance, ou não foi informado:" (' || trim(ev_cnpj_empr) || ').';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 1.55;
  --
  if nvl(est_row_demdocopergercc.pessoa_id, 0) = 0 and trim(ev_cod_part) is not null then
    --
      gv_resumo := null;
      --
      gv_resumo := '"Código do participante da pessoa não encontrado na base Compliance:" (' || trim(ev_cod_part) || ').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
  end if;
  --
  vn_fase := 1.6;
  --
  if nvl(est_row_demdocopergercc.item_id, 0) = 0 and trim(ev_cod_item) is not null then
    --
      gv_resumo := null;
      --
      gv_resumo := '"Código do item não encontrado na base Compliance:" (' || trim(ev_cod_item) || ').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
  end if;
  --
  vn_fase := 1.7;
  --
  if nvl(est_row_demdocopergercc.codst_id_pis, 0) = 0 and trim(ev_cod_st_pis) is not null then
      --
      gv_resumo := '"Código da Situação Tributaria dos Impostos não encontrado na base Compliance:" (' || trim(ev_cod_st_pis) || ').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
     --
  elsif nvl(est_row_demdocopergercc.codst_id_pis, 0) = 0 then
     --
      vn_fase := 1.8;
      --
      gv_resumo := 'Código da Situação Tributaria do Imposto PIS não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                           , ev_mensagem          => gv_mensagem
                           , ev_resumo            => gv_resumo
                           , en_tipo_log          => erro_de_validacao
                           , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                              , est_log_generico_ddo => est_log_generico_ddo );
      --
  end if;
  --
  vn_fase := 1.9;
  --
  if nvl(est_row_demdocopergercc.codst_id_cofins, 0) = 0 and  trim(ev_cod_st_cofins) is not null then
    --
      --
      gv_resumo := '"Código da Situação Tributaria dos Impostos COFINS não encontrado na base Compliance:" (' || trim(ev_cod_st_cofins) || ').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
      --
  elsif nvl(est_row_demdocopergercc.codst_id_cofins, 0) = 0 then
      --
      vn_fase := 1.10;
      --
      gv_resumo := '"Código da Situação Tributaria dos Impostos COFINS não informado, informação obrigatória.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
  end if;
  --
  vn_fase := 1.11;
  --
  if nvl(est_row_demdocopergercc.basecalccredpc_id, 0) = 0 and trim(ev_basecalcredpc_cd) is not null then
    --
      gv_resumo := null;
      --
      gv_resumo := '"Código da Base de Calculo do Credito não encontrado na base Compliance:" (' || trim(ev_basecalcredpc_cd) || ').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
  end if;
  --
  vn_fase := 2;
  --
  if nvl(est_row_demdocopergercc.planoconta_id, 0) = 0 and trim(ev_cod_cta) is not null then
    --
      gv_resumo := null;
      --
      gv_resumo := '"Código do plano de conta não encontrado na base compliance" (' || trim(ev_cod_cta) || ').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
  end if;
  --
  vn_fase := 2.1;
  --
  if nvl(est_row_demdocopergercc.centrocusto_id, 0) = 0 and trim(ev_cod_ccus) is not null then
      --
      gv_resumo := null;
      --
      gv_resumo := '"Código do Centro de Custo não encontrado na base compliance" (' || trim(ev_cod_ccus) || ').';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
  end if;
  --
  vn_fase := 2.2;
  --
  if nvl(est_row_demdocopergercc.dm_st_proc, -1) not in (0, 1, 2) then
    --
    gv_resumo := null;
    --
    gv_resumo := 'Situação do processo informada incorretamente: ( ' || est_row_demdocopergercc.dm_st_proc || ' ). Possíveis valores: 0, 1 e 2.';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 2.3;
  --
  if nvl(est_row_demdocopergercc.dm_ind_oper, -1) not in (0, 1, 2) then
    --
    gv_resumo := null;
    --
    gv_resumo := 'Indicador do Tipo da Operacão informada incorretamente: ( ' || est_row_demdocopergercc.dm_ind_oper || ' ). Possíveis valores: 0, 1 e 2.';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 2.4;
  --
  -- Quando o código tipo de operação for 0, será necessário validar o
  -- parâmetro indicador da origem do crédito
  if nvl(est_row_demdocopergercc.dm_ind_oper, -1) = 0 then
    --
    if nvl(est_row_demdocopergercc.dm_ind_orig_cred, -1) not in (0, 1) then
      --
      gv_resumo := null;
      --
      gv_resumo := 'Indicador de origem do crédito informada incorretamente: ( ' || est_row_demdocopergercc.dm_ind_orig_cred || ' ). Possíveis valores: 0 e 1.';
      --
      vn_loggenerico_id := null;
      --
      pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                           ev_mensagem          => gv_mensagem,
                           ev_resumo            => gv_resumo,
                           en_tipo_log          => erro_de_validacao,
                           en_referencia_id     => gn_referencia_id,
                           ev_obj_referencia    => gv_obj_referencia,
                           en_empresa_id        => gn_empresa_id
                           );
      --
      -- Armazena o "loggenerico_id" na memória
      pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                              est_log_generico_ddo => est_log_generico_ddo);
      --
    end if;
    --
  end if;
  --
  vn_fase := 2.5;
  --
  if nvl(est_row_demdocopergercc.vl_oper, -1) < 0 then
    --
    gv_resumo := null;
    --
    gv_resumo := '"Valor de Operação não pode ser negativo."';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 2.6;
  --
  if nvl(est_row_demdocopergercc.vl_bc_pis, -1) < 0 then
    --
    gv_resumo := null;
    --
    gv_resumo := '"Valor de base de cálculo do PIS não pode ser negativo."';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 2.7;
  --
  if nvl(est_row_demdocopergercc.aliq_pis, -1) < 0 then
    --
    gv_resumo := null;
    --
    gv_resumo := '"Valor da Alíquota do PIS não pode ser negativo."';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 2.8;
  --
  if nvl(est_row_demdocopergercc.vl_pis, -1) < 0 then
    --
    gv_resumo := null;
    --
    gv_resumo := '"Valor do PIS não pode ser negativo."';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 2.9;
  --
  if nvl(est_row_demdocopergercc.vl_bc_cofins, -1) < 0 then
    --
    gv_resumo := null;
    --
    gv_resumo := '"Valor de base de cálculo do COFINS não pode ser negativo."';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 3;
  --
  if nvl(est_row_demdocopergercc.aliq_cofins, -1) < 0 then
    --
    gv_resumo := null;
    --
    gv_resumo := '"Valor de Alíquota do COFINS não pode ser negativo."';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 3.1;
  --
  if nvl(est_row_demdocopergercc.vl_cofins, -1) < 0 then
    --
    gv_resumo := null;
    --
    gv_resumo := '"Valor do COFINS não pode ser negativo."';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 3.2;
  --
  if nvl(est_row_demdocopergercc.dm_gera_receita, -1) not in (0, 1) then
    --
    gv_resumo := null;
    --
    gv_resumo := 'Indicador da geração da receita informado incorretamente: (' || est_row_demdocopergercc.dm_gera_receita || ' ). Possíveis valores: 0 e 1.';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 3.3;
  --
  if (pk_int_view_ddo.gd_dt_ult_fecha is null) or (trunc( est_row_demdocopergercc.dt_oper ) < pk_int_view_ddo.gd_dt_ult_fecha) then
    --
    gv_resumo := null;
    --
    gv_resumo := 'Período informado para integração de Demais Documentos e Operações - Bloco F EFD-'||
                 'Contribuições (Bloco F100), está fechado para a data do registro. Data de fechamento fiscal '||
                 to_char(pk_int_view_ddo.gd_dt_ult_fecha,'dd/mm/yyyy')||' - CNPJ/CPF: '||ev_cnpj_empr||'.';
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_validacao,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
  end if;
  --
  vn_fase := 4;
  --
  if nvl(est_row_demdocopergercc.id, 0)              >  0 and -- pode vim preenchido por WB
     nvl(vn_id,0)                                    >  0 and -- será preenchido ser for OpenInterface
     nvl(est_row_demdocopergercc.empresa_id, 0)      >  0 and
     nvl(est_row_demdocopergercc.codst_id_pis, 0)    >  0 and
     nvl(est_row_demdocopergercc.codst_id_cofins, 0) >  0 and
     nvl(est_row_demdocopergercc.dm_ind_oper, -1)    in (0, 1, 2) and
     est_row_demdocopergercc.dt_oper                 is not null  and
     nvl(gn_tipo_integr,0)                           = 1 then
    --
    vn_fase := 4.1;
    --
    begin
      pk_agend_integr.gvtn_qtd_total(gv_cd_obj) := nvl(pk_agend_integr.gvtn_qtd_total(gv_cd_obj), 0) + 1;
    exception
      when others then
        null;
    end;
    --
    vn_fase := 4.2;
    --
    insert into dem_doc_oper_ger_cc ( id,
                                      empresa_id,
                                      dm_ind_oper,
                                      pessoa_id,
                                      item_id,
                                      dt_oper,
                                      vl_oper,
                                      codst_id_pis,
                                      vl_bc_pis,
                                      aliq_pis,
                                      vl_pis,
                                      codst_id_cofins,
                                      vl_bc_cofins,
                                      aliq_cofins,
                                      vl_cofins,
                                      basecalccredpc_id,
                                      dm_ind_orig_cred,
                                      planoconta_id,
                                      centrocusto_id,
                                      dm_st_proc,
                                      dm_st_integra,
                                      desc_doc_oper,
                                      dm_gera_receita)
                             values ( est_row_demdocopergercc.id,
                                      est_row_demdocopergercc.empresa_id,
                                      est_row_demdocopergercc.dm_ind_oper,
                                      est_row_demdocopergercc.pessoa_id,
                                      est_row_demdocopergercc.item_id,
                                      est_row_demdocopergercc.dt_oper,
                                      est_row_demdocopergercc.vl_oper,
                                      est_row_demdocopergercc.codst_id_pis,
                                      est_row_demdocopergercc.vl_bc_pis,
                                      est_row_demdocopergercc.aliq_pis,
                                      est_row_demdocopergercc.vl_pis,
                                      est_row_demdocopergercc.codst_id_cofins,
                                      est_row_demdocopergercc.vl_bc_cofins,
                                      est_row_demdocopergercc.aliq_cofins,
                                      est_row_demdocopergercc.vl_cofins,
                                      est_row_demdocopergercc.basecalccredpc_id,
                                      est_row_demdocopergercc.dm_ind_orig_cred,
                                      est_row_demdocopergercc.planoconta_id,
                                      est_row_demdocopergercc.centrocusto_id,
                                      est_row_demdocopergercc.dm_st_proc,
                                      est_row_demdocopergercc.dm_st_integra,
                                      est_row_demdocopergercc.desc_doc_oper,
                                      est_row_demdocopergercc.dm_gera_receita );
      --
      commit;
      --
   else
      --
      vn_fase := 4.4;
      --
      update dem_doc_oper_ger_cc cc
        set cc.vl_oper         = est_row_demdocopergercc.vl_oper,
            cc.vl_bc_pis       = est_row_demdocopergercc.vl_bc_pis,
            cc.aliq_pis        = est_row_demdocopergercc.aliq_pis,
            cc.vl_pis          = est_row_demdocopergercc.vl_pis,
            cc.vl_bc_cofins    = est_row_demdocopergercc.vl_bc_cofins,
            cc.aliq_cofins     = est_row_demdocopergercc.aliq_cofins,
            cc.vl_cofins       = est_row_demdocopergercc.vl_cofins,
            cc.planoconta_id   = est_row_demdocopergercc.planoconta_id,
            cc.centrocusto_id  = est_row_demdocopergercc.centrocusto_id,
            cc.dm_st_proc      = est_row_demdocopergercc.dm_st_proc,
            cc.dm_st_integra   = est_row_demdocopergercc.dm_st_integra,
            cc.desc_doc_oper   = est_row_demdocopergercc.desc_doc_oper,
            cc.dm_gera_receita = est_row_demdocopergercc.dm_gera_receita
      where cc.id              = est_row_demdocopergercc.id
        and cc.dm_st_proc      not in (1);  --Validada
      --
      commit;
      --
   end if;
  --
exception
  when others then
    --
    gv_resumo := null;
    --
    gv_resumo := 'Erro na pk_csf_api_ddo.pkb_integr_demdocopergercc fase (' || vn_fase || '). Erro = '||sqlerrm;
    --
    vn_loggenerico_id := null;
    --
    pkb_log_generico_ddo(sn_loggenericoddo_id => vn_loggenerico_id,
                         ev_mensagem          => gv_mensagem,
                         ev_resumo            => gv_resumo,
                         en_tipo_log          => erro_de_sistema,
                         en_referencia_id     => gn_referencia_id,
                         ev_obj_referencia    => gv_obj_referencia,
                         en_empresa_id        => gn_empresa_id
                           );
    --
    -- Armazena o "loggenerico_id" na memória
    pkb_gt_log_generico_ddo(en_loggenericoddo_id => vn_loggenerico_id,
                            est_log_generico_ddo => est_log_generico_ddo);
    --
end pkb_integr_demdocopergercc;
--
-----------------------------------------------------------------------------------------------------
-- Processo que consiste o registro da dem_doc_oper_ger_cc
-----------------------------------------------------------------------------------------------------
procedure pkb_consiste_demdocopergercc( est_log_generico_ddo  in out nocopy  dbms_sql.number_table
                                      , en_demdocopergercc_id in             dem_doc_oper_ger_cc.id%type ) is
   --
   vn_qtde_dem_doc_oper_ger_cc number;
   vn_loggenerico_id           log_generico_ddo.id%type;
   vn_fase                     number;
   --
begin
   --
   vn_fase := 1;
   --
   gv_mensagem := null;
   gv_mensagem := 'Consistência do Registro de "Demais Documentos e Operações Geradoras de Contribuiçõe e Credito" - Bloco F100.';
   gv_mensagem := gv_mensagem || chr(10);
   if gv_obj_referencia is null then gv_obj_referencia := 'DEM_DOC_OPER_GER_CC'; end if;
   --
   --
   gn_referencia_id := en_demdocopergercc_id;
   --
   if nvl(est_log_generico_ddo.count,0) = 0 then
      --
      if nvl(en_demdocopergercc_id,0) > 0 then
         --
         vn_fase := 1.1;
         -- valida a quantidade de "Informações dos Totais do DDO", que deve ser igual a "1"
         begin
            --
            select count(1)
              into vn_qtde_dem_doc_oper_ger_cc
              from dem_doc_oper_ger_cc cc
             where cc.id = en_demdocopergercc_id;
             --
         exception
            when others then
               vn_qtde_dem_doc_oper_ger_cc := 0;
         end;
         --
         vn_fase := 1.2;
         --
         if nvl(vn_qtde_dem_doc_oper_ger_cc,0) > 1 then
            --
            vn_fase := 1.3;
            --
            gv_resumo := 'Foi informado mais de um registro de "Demais Documentos e Operações Geradoras de Contribuiçõe e Credito".';
            --
            vn_loggenerico_id := null;
            --
            pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                                 , ev_mensagem          => gv_mensagem
                                 , ev_resumo            => gv_resumo
                                 , en_tipo_log          => erro_de_validacao
                                 , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
            --
            -- Armazena o "loggenerico_id" na memória
            pkb_gt_log_generico_ddo ( en_loggenericoddo_id => vn_loggenerico_id
                                    , est_log_generico_ddo => est_log_generico_ddo );
            --
         end if;
         --
      end if;
      --
   end if;
   --
   if nvl(est_log_generico_ddo.count,0) > 0 then
      --
      update dem_doc_oper_ger_cc cc
         set cc.dm_st_proc = 2
       where cc.id         = en_demdocopergercc_id;
      --
   end if;
   --
   vn_fase := 4;
   -- Se não contém erro de validação, Grava o Log de DDO Integrada
   gv_resumo := 'Bloco F100 integrado.';
   --
   if nvl(est_log_generico_ddo.count,0) = 0 then
      --
      gv_resumo := gv_resumo || ' Bloco F100 validado.';
      --
   end if;
   --
   vn_fase := 5;
   --
   pkb_log_generico_ddo ( sn_loggenericoddo_id => vn_loggenerico_id
                        , ev_mensagem          => gv_mensagem
                        , ev_resumo            => gv_resumo
                        , en_tipo_log          => ddo_integrada
                        , en_referencia_id     => gn_referencia_id
                           , ev_obj_referencia    => gv_obj_referencia
                           , en_empresa_id        => gn_empresa_id
                           );
   --
end pkb_consiste_demdocopergercc;
--
end pk_csf_api_ddo;
/
