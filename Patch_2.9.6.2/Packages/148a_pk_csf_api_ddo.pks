create or replace package csf_own.pk_csf_api_ddo is
--
-- Especifica��o do pacote de integra��o do Bloco F a partir de leitura de views
--
-- Em 01/02/2021   - Eduardo Linden 
-- Redmine #75495  - Erro na integra��o de registros F120, incluir o campo chave
-- Rotina alterada - pkb_integr_bemativimobopcredpc -> Inclus�o do campo  dm_ident_bem_imob na busca de id da tabela bem_ativ_imob_oper_cred_pc  
-- Liberado para release 2.9.7 e patches 2.9.5.5 e 2.9.6.2
-- 
-- Em 04/12/2020 - Eduardo Linden
-- Redmine #71892 - Regra de unicidade BEM_ATIV_IMOB_OPER_CRED_PC
-- Rotina alterada -  pkb_integr_bemativimobopcredpc -> Inclus�o de novos campos na busca de id da tabela bem_ativ_imob_oper_cred_pc devido a regra de unicidade
--                                                   -> Melhoria na busca do id da tabela bem_ativ_imob_oper_cred_pc
--
-- Em 24/11/2020       - Eduardo Linden
-- Redmine #73738      - Corre��o na rotina de integra��o F600
-- Rotina alterada     - pkb_integr_contrretfontepc -> Altera��o a fim de evitar erro de pk na integra��o.
--
-- Em 02/10/2020      - Wendel Albino
-- Redmine #71316     - Erro persiste
-- Rotina Alterada    - pkb_integr_contrretfontepc -> alterada validacao do campo est_row_contr_ret_fonte_pc.id. 
--                    -  Pois quando o processo de integracao � feito via webservice , esta coluna ja vem preenchida com o id ,
--                    -  porque o registro ja foi inserido anteriormente na tabela e assim nao dar erro de pk.
--
-- Em 29/07/2020      - Wendel Albino
-- Redmine #68654     - Falha na integra��o do Bloco F EFD Contribui��es (SANTA F�)
-- Rotina Alterada    - pkb_integr_bemativimobopcredpc -> alteracao na estrutura de validacao de varios campos 
--                    -  e inclusao de goto saida se a integracao nao fizer sentido.
--
-- Em 23/07/2020      - Wendel Albino
-- Redmine #69214     - Erro de valida��o no F600 sem causa aparente 
-- Rotina Alterada    - pkb_integr_contrretfontepc -> alteracao da validacao do id,ajustes em logs de erro e validacao de insert/update
--
-- Em 27/05/2020      - Karina de Paula
-- Redmine #67611     - Dados do bloco F continuam n�o integrando
-- Rotina Alterada    - pkb_integr_contrretfontepc => o select que buscava a sequence da tabela estava chamando sequence errada (correta - contrretfontepc_seq)
--
-- Em 23/04/2020      - Karina de Paula
-- Redmine #65948     - Integra��o Webservice - Informa��es referente F100
--         #66336     - Revis�o Integra��o Bloco F no Open Interface e Web Service para respeitar campo dm_st_proc
-- Rotina Alterada    - Alterado o gn_referencia_id nas procedures de tabela pai para enviar p o log o id da tabela
--                    - Inclu�do nas chamadas da pk_csf_api_ddo.pkb_log_generico_ddo valor para o par�metro de empresa_id
--                    - Inclu�do if para verificar se j� existe valor para gv_obj_referencia, se n�o existir carrega
--                    - Inclu�do o nome correto da tabela na vari�vel gv_resumo para a mensagem do id integrado
--                    - Alterada a verifica��o dos valores de id para n�o gerar erro de valida��o quando valor enviado corretamente
--                    - Inclu�do if de verifica��o se j� existe os valores id's carregados em raz�o da integra��o WS
-- Liberado na vers�o - Release_2.9.4, Patch_2.9.3.1 e Patch_2.9.2.4
--
-- Em 08/04/2020      - Karina de Paula
-- Redmine #65948     - Integra��o Webservice - Informa��es referente F100
-- Rotina Alterada    - Verifcado se tipo de log INFORMACAO estava gerando erro de validacao
-- Liberado na vers�o - Release_2.9.4, Patch_2.9.3.1 e Patch_2.9.2.4
--
-- Em 24/03/2020      - Luis Marques - Release 2.9.3 / Patch 2.9.2-3 e Patch 2.9.1-6
-- Redmine #66158     - Erros
-- Rotinas Alteradas  - pkb_integr_operativimobvend, pkb_integr_credpresestabertpc, pkb_integr_bemativimobopcredpc,
--                    - pkb_limpar_loggenericoddo - Ajustadas as valida��es de PIS e COFINS caso n�o sejam informadas
--                    - e valida��o para base de credito caso n�o seja informada, colocar empresa para limpar o log
--                    - de erro.
--
-- Em 07/02/2020      - Karina de Paula
-- Redmine #64566     - Integra��o do Registro F525 via web service - Mensagem de Erro de Duplicidade Indevida
-- Rotina Alterada    - Todas as valida��es com valores n�o obrigat�rios
-- Liberado na vers�o - Release_2.9.3, Patch_2.9.2.2 e Patch_2.9.1.5
--
-- Em 30/01/2020      - Karina de Paula
-- Redmine #63884     - Integra��o do Registro F525 via web service - Mensagem de Erro de Duplicidade Indevida
-- Rotina Alterada    - Todas as valida��es         => Criada a procedure e retornar al�m do id o tamb�m o dm_st_proc
--                    -                             => Inclu�do nova forma de verifica��o de duplicidade de registro
--                    - pkb_integr_deducaodiversapc => Estava validando dom�nio dm_ind_nat_ded com valor errado p inser��o
-- Liberado na vers�o - Release_2.9.3, Patch_2.9.2.2 e Patch_2.9.1.5
--
-- Em 29/09/2019 - Karina de Paula
-- Redmine #59387 - feed - Parou de integrar para a definitiva os registro F 525,550 (559), 600 e 700
--
-- Em 29/09/2019 - Karina de Paula
-- Redmine #57581 - Realizar revis�o na integra��o Open Interface para os registro do bloco F
--
-- ===== ABAIXO EST� NA ORDEM ANTIGA CRESCENTE ==================================================================================== --
--
-- Em 09/12/2015 - F�bio Tavares Santana.
-- Ficha Redmine:
-- Cria��o da package de integra��o do Bloco F.
--
-- Em 19/08/2016 - Angela In�s.
-- Redmine #22630 - Corre��o no processo de Integra��o - Blocos F - EFD-Contribui��es.
-- 1) Eliminar os csf_own dos processos (inserts/updates/deletes e outros).
-- 2) Alterar nas mensagens de log no processo de integra��o e o nome dos objetos de integra��o.
-- 3) Eliminar o 'vw_csf' das declara��es das vari�veis para as tabelas oficiais.
--
-- Em 19/09/2016 - Angela In�s.
-- Redmine #23572 - Corre��o na integra��o dos Blocos F - Demais Documentos e Opera��es - DDO - Bloco F100.
-- Alterar o processo PK_INT_VIEW_DDO/PK_CSF_API_DDO verificando as vari�veis utilizadas para o campo CPF_PESSOA/COD_PART e seu tipo de NUMBER-11/VARCHAR2-60.
-- Rotina: pkb_integr_demdocopergercc.
--
-- Em 21/09/2016 - Angela In�s.
-- Redmine #23653 - Corre��o na valida��o do C�digo do Participante - Bloco F100.
-- Recuperar o identificador da Pessoa atrav�s do C�digo do Participante (vw_csf_dem_doc_oper_ger_cc.cod_part = pessoa.cod_part, pessoa.id).
-- Rotina: pkb_integr_demdocopergercc.
--
-- Em 26/10/2016 - Angela In�s.
-- Redmine #24744 - Corre��es no processo de Integra��o do Bloco F - Demais Documentos e Opera��es - Bloco F EFD Contribui��es.
-- 1) Para integra��o dos registros do Bloco F600, estamos considerando como chave os campos VL_BC_RET-Valor da Base de c�lculo da reten��o ou do
-- recolhimento (sociedade cooperativa), e DT_RET-Data do Recebimento e Reten��o. Os registros que n�o foram integrados possuem os campos que consideramos como chave iguais, por�m o campo CNPJ-CNPJ referente a: Fonte Pagadora Responsavel pela Reten��o / Recolhimento OU Pessoa Juridica Beneficiaria da Reten�ao / Recolhimento, est� diferente.
-- Corre��o: Considerar o campo CNPJ como parte da chave para integra��o do registro.
-- Rotina: pk_csf_api_ddo.pkb_integr_contrretfontepc.
-- 2) Incluir o processo de contagem dos registros integrados com sucesso ou com erro de valida��o para serem informados no agendamento.
-- Rotinas: todas/pk_csf_api_ddo.
--
-- Em 06/12/2016 - Angela In�s.
-- Redmine #26047 - Gera��o dos registros - Blocos F120/F130 - Bens do Ativo Imobilizado com base nos Encargos de Deprecia��o/Amortiza��o e no Valor de Aquisi��o.
-- 1) N�o deve ser considerado alguns dos campos do Bloco F120 e F130 como sendo chave, os registros podem ser repetidos.
-- 2) A base de c�lculo de cr�dito � obrigat�ria, devendo ser de c�digo '09' ou '11' (base_calc_cred_pc.cd), quando o registro for do tipo Deprecia��o/Amortiza��o (bem_ativ_imob_oper_cred_pc.dm_tipo_oper=0).
-- 3) A base de c�lculo de cr�dito � obrigat�ria, devendo ser de c�digo '10' (base_calc_cred_pc.cd), quando o registro for do tipo Aquisi��o/Contribui��o (bem_ativ_imob_oper_cred_pc.dm_tipo_oper=1).
-- Rotina: pkb_integr_bemativimobopcredpc.
--
-- Em 07/12/2016 - Angela In�s.
-- Redmine #26085 - Processo de Integra��o e Valida��o do campo Indicador de N�mero de Parcelas - Blocos F120 e F130.
-- Na valida��o da integra��o dos registros dos Blocos F120 e F130, considerar como obrigat�rio se o Tipo de Opera��o for 1-Aquisi��o/Contribui��o, caso o Tipo
-- de Opera��o seja 0-Deprecia��o/Amortiza��o, o campo n�o dever� ser informado.
-- Rotina: pkb_integr_bemativimobopcredpc.
--
-- Em 07/02/2017 - F�bio Tavares
-- Redmine #27809 - Ajustes nas mensagens de valida��o do bloco F600
-- Rotina: pkb_integr_contrretfontepc.
--
-- Em 08/02/2017 - F�bio Tavares
-- Redmine #27834 - Foi corrigido a contagem dos registros integrados do bloco F
-- Rotinas: foi feita a revis�o de todos os processos do bloco F.
--
-- Em 13/02/2017 - F�bio Tavares
-- Redmine #28117 - Integra��o do Bloco F600 - Campo c�digo da Receita
-- Rotina: pkb_integr_contrretfontepc
--
-- Em 06/03/2017 - F�bio Tavares
-- Redmine #29077 - Ajuste na chave de Integra��o do Bloco F100
--
-- Em 13/03/2017 - Angela In�s.
-- Redmine #29286 - Adapta��o da valida��o dos Blocos F120/F130: Integra��o e Tela/Portal.
-- Adequar as valida��es dos Blocos F120/F130 com a Integra��o e com a digita��o das informa��es via Tela/Portal.
-- Rotinas: pkb_integr_bemativimobopcredpc e pkb_integr_prdemdocopergercc.
--
-- Em 20/09/2017 - Angela In�s.
-- Redmine #34795 - Corre��o na Integra��o dos dados da Contribui��o retida na fonte - Bloco F600.
-- Alterar o processo que identifica se o registro j� existe na base de dados, considerando as colunas: empresa_id, dm_ind_nat_ret, dt_ret, cod_rec,
-- dm_ind_nat_rec e cnpj.
-- Rotina: pkb_integr_contrretfontepc.
--
-- Em 08/11/2017 - Angela In�s.
-- Redmine #36303 - Valida��o dos Registros dos Blocos F120/F130 - Atualiza��o.
-- No processo de valida��o dos Registros dos Blocos F120/F130 - Bens do Ativo Imobilizado com Opera��es de Cr�dito de PIS/COFINS, considerar a exist�ncia do
-- registro, e executar a atualiza��o (update) do mesmo.
-- Rotina: pkb_integr_bemativimobopcredpc.
--
-- Em 23/04/2018 - Karina de Paula
-- Redmine #41878 - Novo processo para o registro Bloco F100 - Demais Documentos e Opera��es Geradoras de Contribui��es e Cr�ditos.
-- Rotina Alterada: pkb_integr_demdocopergercc - Inclu�da a verifica��o da nova coluna DM_GERA_RECEITA e inclu�da tb no insert e update da rotina
--
-- Em 20/06/2018 - Angela In�s.
-- Redmine #43888/#43894 - Desenvolver Rotina Program�vel - F100/F700 - Receita POC e Receita Financeira.
-- Procedimento para gravar o log/altera��o dos Demais Documentos e Opera��es Geradoras de Contribui��o e Cr�ditos - Bloco F100, e de Dedu��es Diversas - Bloco F700.
-- Rotina: pkb_inclui_log_demdocopergercc e pkb_inclui_log_deddiversapc.
--
-- Em 25/09/2018 - Angela In�s.
-- Redmine #47193 - Revisar as UKs e as novas Colunas dos registros dos Blocos F.
--
-- Em 27/02/2019 - Renan Alves
-- Redmine #50434 - Integra��o Bloco F - pkb_integr_prconsopinspcrcaum
-- Foi alterado a tabela pr_cons_oper_ins_pc_rc para pr_cons_op_ins_pcrc_aum no update que era realizado na verifica��o
-- Rotina: pkb_integr_prconsopinspcrcaum
--
-- Em 01/03/2019 - Fernando Basso
-- Redmine #52018 - Ajuste de valida��o na integra��o de Contribui��o Retida na Fonte (F600)
-- Corre��o de atribui��o de valor para o campo cod_rec (pkgs - 147, 148 e 151)
--
-- Em 18/03/2019 - Renan Alves
-- Redmine #52187 - Erro ao integrar - Bloco F100 (dm_ind_orig_cred )
-- Foi inclu�do verifica��o para quando o c�digo tipo de opera��o for 0, ser� necess�rio validar o
-- par�metro indicador da origem do cr�dito
-- Rotina: pkb_integr_demdocopergercc
--
-- Em 25/04/2019 - Karina de Paula
-- Redmine #52071 - Erro ao validar integra��o de registro F100
-- Rotina Alterada: pkb_integr_demdocopergercc - Foi inclu�do no in�cio da processo a verifica��o se existe o registro (pk_csf_ddo.fkb_dm_st_proc_demdocopergercc)
--                                               , se n�o existir busca o ID para inser��o. Dessa forma n�o ir� gerar um novo ID para um registro que j� existe
--                                               por exemplo, uma integra��o WEBSERVICE.
--
-- ========================================================================================================================================= --
--
-- F100
  gt_row_dem_doc_oper_ger_cc          dem_doc_oper_ger_cc%rowtype;
  gt_row_pr_dem_doc_oper_ger_cc       pr_dem_doc_oper_ger_cc%rowtype;
--
-- F120
  gt_row_bemativimob_opercred_pc      bem_ativ_imob_oper_cred_pc%rowtype;
  gt_row_pr_bai_oper_cred_pc          pr_bai_oper_cred_pc%rowtype;
--
-- F150
  gt_row_cred_pres_est_abert_pc       cred_pres_est_abert_pc%rowtype;
--
-- F200
  gt_row_oper_ativ_imob_vend          oper_ativ_imob_vend%rowtype;
--
-- F205
  gt_row_oper_ativ_imob_cus_inc       oper_ativ_imob_cus_inc%rowtype;
--
-- F210
  gt_row_oper_ativ_imob_cus_orc       oper_ativ_imob_cus_orc%rowtype;
--
-- F211
  gt_row_oper_ativ_imob_proc_ref      oper_ativ_imob_proc_ref%rowtype;
--
-- F500
  gt_row_cons_oper_ins_pc_rc          cons_oper_ins_pc_rc%rowtype;
--
-- F509
  gt_row_pr_cons_oper_ins_pc_rc       pr_cons_oper_ins_pc_rc%rowtype;
--
-- F510
  gt_row_cons_oper_ins_pc_rc_aum      cons_oper_ins_pc_rc_aum%rowtype;
--
-- F519
  gt_row_pr_cons_op_ins_pcrc_aum      pr_cons_op_ins_pcrc_aum%rowtype;
--
-- F525
  gt_row_comp_rec_det_rc              comp_rec_det_rc%rowtype;
--
-- F550
  gt_row_cons_oper_ins_pc_rcomp       cons_oper_ins_pc_rcomp%rowtype;
--
-- F559
  gt_row_pr_cons_op_ins_pc_rcomp      pr_cons_op_ins_pc_rcomp%rowtype;
--
-- F560
  gt_row_cons_op_ins_pcrcomp_aum      cons_op_ins_pcrcomp_aum%rowtype;
--
-- F569
  gt_row_pr_cons_op_ins_pcrcoaum      pr_cons_op_ins_pcrcoaum%rowtype;
--
-- F600
  gt_row_contr_ret_fonte_pc           contr_ret_fonte_pc%rowtype;
--
-- F700
  gt_row_deducao_diversa_pc           deducao_diversa_pc%rowtype;
--
-- F800
  gt_row_cred_decor_evento_pc       cred_decor_evento_pc%rowtype;
--
----------------------------------------------------------------------------------------------------

   gv_resumo          log_generico_ddo.resumo%type;
   gv_mensagem        log_generico_ddo.mensagem%type;
   gn_processo_id     log_generico_ddo.processo_id%TYPE := null;
   gn_empresa_id      empresa.id%type;
   --
   gn_tipo_integr     number := null;
   gv_obj_referencia  log_generico_ddo.obj_referencia%type;
   gn_referencia_id   log_generico_ddo.referencia_id%type := null;
   gv_cd_obj          obj_integr.cd%type := '50'; -- Demais Documentos e Opera��es - Bloco F EFD Contribui��es
   --
--|Declara��o de constantes
   erro_de_validacao  constant number := 1;
   erro_de_sistema    constant number := 2;
   informacao         constant number := 35;
   ddo_integrada      constant number := 16;

----------------------------------------------------------------------------------------------------
-- Procedimento para gravar o log/altera��o das Dedu��es Diversas - Bloco F700
procedure pkb_inclui_log_deddiversapc( en_deducaodiversapc_id in deducao_diversa_pc.id%type
                                     , ev_resumo              in log_deducao_diversa_pc.resumo%type
                                     , ev_mensagem            in log_deducao_diversa_pc.mensagem%type
                                     , en_usuario_id          in neo_usuario.id%type
                                     , ev_maquina             in varchar2 );
----------------------------------------------------------------------------------------------------
-- Procedimento para gravar o log/altera��o dos Demais Documentos e Opera��es Geradoras de Contribui��o e Cr�ditos - Bloco F100
procedure pkb_inclui_log_demdocopergercc( en_demdocopergercc_id in dem_doc_oper_ger_cc.id%type
                                        , ev_resumo             in log_dem_doc_oper_ger_cc.resumo%type
                                        , ev_mensagem           in log_dem_doc_oper_ger_cc.mensagem%type
                                        , en_usuario_id         in neo_usuario.id%type
                                        , ev_maquina            in varchar2 );
----------------------------------------------------------------------------------------------------
-- Procedimento que finaliza o log generico.
procedure pkb_finaliza_log_generico_ddo;
----------------------------------------------------------------------------------------------------
--  Procedimento armazena o valor do "loggenerico_id"
procedure pkb_gt_log_generico_ddo ( en_loggenericoddo_id  in             Log_generico_ddo.id%TYPE
                                  , est_log_generico_ddo  in out nocopy  dbms_sql.number_table
                                  );
----------------------------------------------------------------------------------------------------
-- Procedimento que armazena o log_generico_ddo
procedure pkb_log_generico_ddo( sn_loggenericoddo_id   out nocopy    log_generico_ddo.id%type
                              , ev_mensagem            in            log_generico_ddo.mensagem%type
                              , ev_resumo              in            log_generico_ddo.resumo%type
                              , en_tipo_log            in            csf_tipo_log.cd_compat%type      default 1
                              , en_referencia_id       in            Log_Generico_ddo.referencia_id%TYPE  default null
                              , ev_obj_referencia      in            Log_Generico_ddo.obj_referencia%TYPE default null
                              , en_empresa_id          in            Empresa.Id%type                  default null
                              , en_dm_impressa         in            Log_Generico_ddo.dm_impressa%type    default 0
                              );
----------------------------------------------------------------------------------------------------
-- Procedimento que limpa a tabela log_generico_ddo
procedure pkb_limpar_loggenericoddo( en_empresa_id     in            Empresa.Id%type );
----------------------------------------------------------------------------------------------------
-- Procedimento de registro de log de erros na valida��o do DDO
procedure pkb_seta_obj_ref ( ev_objeto in varchar2
                           );
----------------------------------------------------------------------------------------------------
--| Procedimento seta o tipo de integra��o que ser� feito
   -- 0 - Somente v�lida os dados e registra o Log de ocorr�ncia
   -- 1 - V�lida os dados e registra o Log de ocorr�ncia e insere a informa��o
   -- Todos os procedimentos de integra��o fazem refer�ncia a ele
procedure pkb_seta_tipo_integr ( en_tipo_integr in number
                               );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela cred_decor_evento_pc
procedure pkb_integr_creddecoreventopc ( est_log_generico_ddo           in out nocopy dbms_sql.number_table
                                       , est_row_creddecoreventopc      in out nocopy cred_decor_evento_pc%rowtype
                                       , en_multorg_id                  in            mult_org.id%TYPE
                                       , ev_cnpj_empr                   in            varchar2
                                       , ev_tipocredpc_cd               in            varchar2
                                       );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela DEDUCAO_DIVERSA_PC
procedure pkb_integr_deducaodiversapc ( est_log_generico_ddo         in out nocopy dbms_sql.number_table
                                      , est_row_deducaodiversaspc    in out nocopy deducao_diversa_pc%rowtype
                                      , ev_cnpj_empr                 in varchar2
                                      , en_multorg_id                in mult_org.id%type
                                      );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela CONTR_RET_FONTE_PC
procedure pkb_integr_contrretfontepc ( est_log_generico_ddo           in out nocopy dbms_sql.number_table
                                     , est_row_contr_ret_fonte_pc     in out nocopy contr_ret_fonte_pc%rowtype
                                     , en_multorg_id                  in            mult_org.id%type
                                     , ev_cnpj_empr                   in            varchar2
                                     );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela PR_CONS_OP_INS_PCRCOAUM
procedure pkb_integr_prconsopinspcrcoaum ( est_log_generico_ddo         in out nocopy dbms_sql.number_table
                                         , est_row_prconsopinspcrcoaum  in out nocopy pr_cons_op_ins_pcrcoaum%rowtype
                                         , ev_cpf_cnpj                  in            varchar2
                                         , en_cd_orig                   in            number
                                         );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela CONS_OP_INS_PCRCOMP_AUM
procedure pkb_integr_consopinspcrcompaum ( est_log_generico_ddo          in out nocopy dbms_sql.number_table
                                         , est_row_consopinspcrcompaum   in out nocopy cons_op_ins_pcrcomp_aum%rowtype
                                         , ev_cnpj_empr                  in            varchar2
                                         , en_multorg_id                 in            mult_org.id%type
                                         , ev_cod_st_pis                 in            varchar2
                                         , ev_cod_st_cofins              in            varchar2
                                         , ev_cod_mod                    in            varchar2
                                         , ev_cod_cta                    in            varchar2
                                         , en_cfop                       in            number
                                         );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela PR_COMP_OP_INS_PC_RCOMP
procedure pkb_integr_prconsopinspcrcomp( est_log_generico_ddo           in out nocopy dbms_sql.number_table
                                       , est_row_pr_cons_op_ins_pcrcomp in out nocopy pr_cons_op_ins_pc_rcomp%rowtype
                                       , ev_cpf_cnpj                    in            varchar2
                                       , en_cd_orig                     in            number );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela COMP_OPER_INS_PC_RCOMP
procedure pkb_integr_consoperinspcrcomp ( est_log_generico_ddo          in out nocopy dbms_sql.number_table
                                        , est_row_consoperinspcrcomp    in out nocopy cons_oper_ins_pc_rcomp%rowtype
                                        , ev_cnpj_empr                  in            varchar2
                                        , en_multorg_id                 in            mult_org.id%type
                                        , ev_cod_st_pis                 in            varchar2
                                        , ev_cod_st_cofins              in            varchar2
                                        , ev_cod_mod                    in            varchar2
                                        , ev_cod_cta                    in            varchar2
                                        , en_cfop                       in            number
                                        );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela COMP_REC_DET_RC
procedure pkb_integr_comp_rec_det_rc ( est_log_generico_ddo     in out nocopy dbms_sql.number_table
                                     , est_row_comp_rec_det_rc  in out nocopy comp_rec_det_rc%rowtype
                                     , ev_cnpj_empr             in            varchar2
                                     , en_multorg_id            in            mult_org.id%type
                                     , ev_cod_part              in            varchar2
                                     , ev_cod_item              in            varchar2
                                     , ev_cod_st_pis            in            varchar2
                                     , ev_cod_st_cofins         in            varchar2
                                     , ev_cod_cta               in            varchar2
                                     );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela pr_cons_op_ins_pcrc_aum
procedure pkb_integr_prconsopinspcrcaum ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                        , est_row_prconsopinspcrcaum  in out nocopy pr_cons_op_ins_pcrc_aum%rowtype
                                        , ev_cpf_cnpj                 in            varchar2
                                        , en_cd_orig                  in            number
                                        );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela CONS_OPER_INS_PC_RC_AUM
procedure pkb_integr_consoperinspcrcaum ( est_log_generico_ddo         in out nocopy dbms_sql.number_table
                                        , est_row_consoperinspcrcaum   in out nocopy cons_oper_ins_pc_rc_aum%rowtype
                                        , ev_cnpj_empr                 in            varchar2
                                        , en_multorg_id                in            mult_org.id%type
                                        , ev_cod_st_pis                in            varchar2
                                        , ev_cod_st_cofins             in            varchar2
                                        , ev_cod_mod                   in            varchar2
                                        , ev_cod_cta                   in            varchar2
                                        , en_cfop                      in            number
                                        );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela PR_CONS_OPER_INS_PC_RC
procedure pkb_integr_prconsoperinspcrc ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                       , est_row_prconsoperinspcrc   in out nocopy pr_cons_oper_ins_pc_rc%rowtype
                                       , ev_cpf_cnpj                 in            varchar2
                                       , en_cd_orig                  in            orig_proc.cd%type
                                       );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela CONS_OPER_INS_PC_RC
procedure pkb_integr_consoperinspcrc ( est_log_generico_ddo         in out nocopy  dbms_sql.number_table
                                     , est_row_consoperinspcrc      in out nocopy  cons_oper_ins_pc_rc%rowtype
                                     , ev_cnpj_empr                 in             varchar2
                                     , en_multorg_id                in             mult_org.id%type
                                     , ev_cod_st_pis                in             varchar2
                                     , ev_cod_st_cofins             in             varchar2
                                     , ev_cod_mod                   in             varchar2
                                     , ev_cod_cta                   in             varchar2
                                     , en_cfop                      in             number
                                     );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela oper_ativ_imob_proc_ref
procedure pkb_integr_operativimobprocref ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                         , est_row_operativimobprocref in out nocopy oper_ativ_imob_proc_ref%rowtype
                                         , ev_cpf_cnpj                 in            varchar2
                                         );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela oper_ativ_imob_cus_orc
procedure pkb_integr_operativimobcusorc ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                        , est_row_operativimobcusorc  in out nocopy oper_ativ_imob_cus_orc%rowtype
                                        , ev_cpf_cnpj                 in            varchar2
                                        , ev_cod_st_pis               in            varchar2
                                        , ev_cod_st_cofins            in            varchar2
                                        );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela oper_ativ_imob_cus_inc
procedure pkb_integr_operativimobcusinc ( est_log_generico_ddo             in out nocopy dbms_sql.number_table
                                        , est_row_operativimobcusinc       in out nocopy oper_ativ_imob_cus_inc%rowtype
                                        , en_multorg_id                    in            mult_org.id%type
                                        , ev_cpf_cnpj                      in            varchar2
                                        , ev_cod_st_pis                    in            varchar2
                                        , ev_cod_st_cofins                 in            varchar2
                                        );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela oper_ativ_imob_vend
procedure pkb_integr_operativimobvend ( est_log_generico_ddo          in out nocopy dbms_sql.number_table
                                      , est_row_operativimobvend      in out nocopy oper_ativ_imob_vend%rowtype
                                      , en_multorg_id                 in            mult_org.id%type
                                      , ev_cnpj_empr                  in            varchar2
                                      , ev_cod_st_pis                 in            varchar2
                                      , ev_cod_st_cofins              in            varchar2
                                      );

----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela cred_pres_est_abert_pc
procedure pkb_integr_credpresestabertpc ( est_log_generico_ddo          in out nocopy dbms_sql.number_table
                                        , est_row_credpresestabertpc    in out nocopy cred_pres_est_abert_pc%rowtype
                                        , en_multorg_id                 in            mult_org.id%type
                                        , ev_cnpj_empr                  in            varchar2
                                        , ev_basecalccredpc_cd          in            varchar2
                                        , ev_cod_st_pis                 in            varchar2
                                        , ev_cod_st_cofins              in            varchar2
                                        , ev_cod_cta                    in            varchar2
                                        );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela pr_bai_oper_cred_pc
procedure pkb_integr_prbaiopercredpc ( est_log_generico_ddo    in out nocopy dbms_sql.number_table
                                     , est_row_prbaiopercredpc in out nocopy pr_bai_oper_cred_pc%rowtype
                                     , ev_cpf_cnpj             in            varchar2
                                     , en_cd_origproc          in            orig_proc.cd%type
                                     );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela bem_ativ_imob_oper_cred_pc
procedure pkb_integr_bemativimobopcredpc ( est_log_generico_ddo           in out nocopy dbms_sql.number_table
                                         , est_row_bemativimobopercredpc  in out nocopy bem_ativ_imob_oper_cred_pc%rowtype
                                         , en_multorg_id                  in            mult_org.id%type
                                         , ev_cnpj_empr                   in            varchar2
                                         , ev_cod_st_pis                  in            varchar2
                                         , ev_cod_st_cofins               in            varchar2
                                         , ev_basecalccredpc_cd           in            varchar2
                                         , ev_cod_cta                     in            varchar2
                                         , ev_cod_ccus                    in            varchar2
                                         );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela pr_dem_doc_oper_ger_cc
procedure pkb_integr_prdemdocopergercc ( est_log_generico_ddo      in out nocopy  dbms_sql.number_table
                                       , est_row_prdemdocopergercc in out nocopy  pr_dem_doc_oper_ger_cc%rowtype
                                       , ev_cpf_cnpj               in             varchar2
                                       , en_cd_origproc            in             number
                                       );
----------------------------------------------------------------------------------------------------
-- Procedimento de integra��o da tabela dem_doc_oper_ger_cc
procedure pkb_integr_demdocopergercc ( est_log_generico_ddo             in out nocopy  dbms_sql.number_table
                                     , est_row_demdocopergercc          in out nocopy  dem_doc_oper_ger_cc%rowtype
                                     , en_multorg_id                    in             mult_org.id%type
                                     , ev_cnpj_empr                     in             varchar2
                                     , ev_cod_part                      in             varchar2
                                     , ev_cod_item                      in             varchar2
                                     , ev_cod_st_pis                    in             varchar2
                                     , ev_cod_st_cofins                 in             varchar2
                                     , ev_basecalcredpc_cd              in             varchar2
                                     , ev_cod_cta                       in             varchar2
                                     , ev_cod_ccus                      in             varchar2
                                     );
----------------------------------------------------------------------------------------------------
-- Procedimento que Valida dados Integrados
procedure pkb_consiste_demdocopergercc( est_log_generico_ddo    in out nocopy  dbms_sql.number_table
                                      , en_demdocopergercc_id   in             dem_doc_oper_ger_cc.id%type );
----------------------------------------------------------------------------------------------------
end pk_csf_api_ddo;
/
