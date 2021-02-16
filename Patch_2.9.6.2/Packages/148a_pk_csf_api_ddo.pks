create or replace package csf_own.pk_csf_api_ddo is
--
-- teste de alteração na branch deve
-- teste dani
-- Especificação do pacote de integração do Bloco F a partir de leitura de views
--
--
-- Em 01/02/2021   - Eduardo Linden 
-- Redmine #75495  - Erro na integração de registros F120, incluir o campo chave
-- Rotina alterada - pkb_integr_bemativimobopcredpc -> Inclusão do campo  dm_ident_bem_imob na busca de id da tabela bem_ativ_imob_oper_cred_pc  
-- Liberado para release 2.9.7 e patches 2.9.5.5 e 2.9.6.2
-- 
-- Em 04/12/2020 - Eduardo Linden
-- Redmine #71892 - Regra de unicidade BEM_ATIV_IMOB_OPER_CRED_PC
-- Rotina alterada -  pkb_integr_bemativimobopcredpc -> Inclusão de novos campos na busca de id da tabela bem_ativ_imob_oper_cred_pc devido a regra de unicidade
--                                                   -> Melhoria na busca do id da tabela bem_ativ_imob_oper_cred_pc
--
-- Em 24/11/2020       - Eduardo Linden
-- Redmine #73738      - Correção na rotina de integração F600
-- Rotina alterada     - pkb_integr_contrretfontepc -> Alteração a fim de evitar erro de pk na integração.
--
-- Em 02/10/2020      - Wendel Albino
-- Redmine #71316     - Erro persiste
-- Rotina Alterada    - pkb_integr_contrretfontepc -> alterada validacao do campo est_row_contr_ret_fonte_pc.id. 
--                    -  Pois quando o processo de integracao é feito via webservice , esta coluna ja vem preenchida com o id ,
--                    -  porque o registro ja foi inserido anteriormente na tabela e assim nao dar erro de pk.
--
-- Em 29/07/2020      - Wendel Albino
-- Redmine #68654     - Falha na integração do Bloco F EFD Contribuições (SANTA FÉ)
-- Rotina Alterada    - pkb_integr_bemativimobopcredpc -> alteracao na estrutura de validacao de varios campos 
--                    -  e inclusao de goto saida se a integracao nao fizer sentido.
--
-- Em 23/07/2020      - Wendel Albino
-- Redmine #69214     - Erro de validação no F600 sem causa aparente 
-- Rotina Alterada    - pkb_integr_contrretfontepc -> alteracao da validacao do id,ajustes em logs de erro e validacao de insert/update
--
-- Em 27/05/2020      - Karina de Paula
-- Redmine #67611     - Dados do bloco F continuam não integrando
-- Rotina Alterada    - pkb_integr_contrretfontepc => o select que buscava a sequence da tabela estava chamando sequence errada (correta - contrretfontepc_seq)
--
-- Em 23/04/2020      - Karina de Paula
-- Redmine #65948     - Integração Webservice - Informações referente F100
--         #66336     - Revisão Integração Bloco F no Open Interface e Web Service para respeitar campo dm_st_proc
-- Rotina Alterada    - Alterado o gn_referencia_id nas procedures de tabela pai para enviar p o log o id da tabela
--                    - Incluído nas chamadas da pk_csf_api_ddo.pkb_log_generico_ddo valor para o parâmetro de empresa_id
--                    - Incluído if para verificar se já existe valor para gv_obj_referencia, se não existir carrega
--                    - Incluído o nome correto da tabela na variável gv_resumo para a mensagem do id integrado
--                    - Alterada a verificação dos valores de id para não gerar erro de validação quando valor enviado corretamente
--                    - Incluído if de verificação se já existe os valores id's carregados em razão da integração WS
-- Liberado na versão - Release_2.9.4, Patch_2.9.3.1 e Patch_2.9.2.4
--
-- Em 08/04/2020      - Karina de Paula
-- Redmine #65948     - Integração Webservice - Informações referente F100
-- Rotina Alterada    - Verifcado se tipo de log INFORMACAO estava gerando erro de validacao
-- Liberado na versão - Release_2.9.4, Patch_2.9.3.1 e Patch_2.9.2.4
--
-- Em 24/03/2020      - Luis Marques - Release 2.9.3 / Patch 2.9.2-3 e Patch 2.9.1-6
-- Redmine #66158     - Erros
-- Rotinas Alteradas  - pkb_integr_operativimobvend, pkb_integr_credpresestabertpc, pkb_integr_bemativimobopcredpc,
--                    - pkb_limpar_loggenericoddo - Ajustadas as validações de PIS e COFINS caso não sejam informadas
--                    - e validação para base de credito caso não seja informada, colocar empresa para limpar o log
--                    - de erro.
--
-- Em 07/02/2020      - Karina de Paula
-- Redmine #64566     - Integração do Registro F525 via web service - Mensagem de Erro de Duplicidade Indevida
-- Rotina Alterada    - Todas as validações com valores não obrigatórios
-- Liberado na versão - Release_2.9.3, Patch_2.9.2.2 e Patch_2.9.1.5
--
-- Em 30/01/2020      - Karina de Paula
-- Redmine #63884     - Integração do Registro F525 via web service - Mensagem de Erro de Duplicidade Indevida
-- Rotina Alterada    - Todas as validações         => Criada a procedure e retornar além do id o também o dm_st_proc
--                    -                             => Incluído nova forma de verificação de duplicidade de registro
--                    - pkb_integr_deducaodiversapc => Estava validando domínio dm_ind_nat_ded com valor errado p inserção
-- Liberado na versão - Release_2.9.3, Patch_2.9.2.2 e Patch_2.9.1.5
--
-- Em 29/09/2019 - Karina de Paula
-- Redmine #59387 - feed - Parou de integrar para a definitiva os registro F 525,550 (559), 600 e 700
--
-- Em 29/09/2019 - Karina de Paula
-- Redmine #57581 - Realizar revisão na integração Open Interface para os registro do bloco F
--
-- ===== ABAIXO ESTÁ NA ORDEM ANTIGA CRESCENTE ==================================================================================== --
--
-- Em 09/12/2015 - Fábio Tavares Santana.
-- Ficha Redmine:
-- Criação da package de integração do Bloco F.
--
-- Em 19/08/2016 - Angela Inês.
-- Redmine #22630 - Correção no processo de Integração - Blocos F - EFD-Contribuições.
-- 1) Eliminar os csf_own dos processos (inserts/updates/deletes e outros).
-- 2) Alterar nas mensagens de log no processo de integração e o nome dos objetos de integração.
-- 3) Eliminar o 'vw_csf' das declarações das variáveis para as tabelas oficiais.
--
-- Em 19/09/2016 - Angela Inês.
-- Redmine #23572 - Correção na integração dos Blocos F - Demais Documentos e Operações - DDO - Bloco F100.
-- Alterar o processo PK_INT_VIEW_DDO/PK_CSF_API_DDO verificando as variáveis utilizadas para o campo CPF_PESSOA/COD_PART e seu tipo de NUMBER-11/VARCHAR2-60.
-- Rotina: pkb_integr_demdocopergercc.
--
-- Em 21/09/2016 - Angela Inês.
-- Redmine #23653 - Correção na validação do Código do Participante - Bloco F100.
-- Recuperar o identificador da Pessoa através do Código do Participante (vw_csf_dem_doc_oper_ger_cc.cod_part = pessoa.cod_part, pessoa.id).
-- Rotina: pkb_integr_demdocopergercc.
--
-- Em 26/10/2016 - Angela Inês.
-- Redmine #24744 - Correções no processo de Integração do Bloco F - Demais Documentos e Operações - Bloco F EFD Contribuições.
-- 1) Para integração dos registros do Bloco F600, estamos considerando como chave os campos VL_BC_RET-Valor da Base de cálculo da retenção ou do
-- recolhimento (sociedade cooperativa), e DT_RET-Data do Recebimento e Retenção. Os registros que não foram integrados possuem os campos que consideramos como chave iguais, porém o campo CNPJ-CNPJ referente a: Fonte Pagadora Responsavel pela Retenção / Recolhimento OU Pessoa Juridica Beneficiaria da Retençao / Recolhimento, está diferente.
-- Correção: Considerar o campo CNPJ como parte da chave para integração do registro.
-- Rotina: pk_csf_api_ddo.pkb_integr_contrretfontepc.
-- 2) Incluir o processo de contagem dos registros integrados com sucesso ou com erro de validação para serem informados no agendamento.
-- Rotinas: todas/pk_csf_api_ddo.
--
-- Em 06/12/2016 - Angela Inês.
-- Redmine #26047 - Geração dos registros - Blocos F120/F130 - Bens do Ativo Imobilizado com base nos Encargos de Depreciação/Amortização e no Valor de Aquisição.
-- 1) Não deve ser considerado alguns dos campos do Bloco F120 e F130 como sendo chave, os registros podem ser repetidos.
-- 2) A base de cálculo de crédito é obrigatória, devendo ser de código '09' ou '11' (base_calc_cred_pc.cd), quando o registro for do tipo Depreciação/Amortização (bem_ativ_imob_oper_cred_pc.dm_tipo_oper=0).
-- 3) A base de cálculo de crédito é obrigatória, devendo ser de código '10' (base_calc_cred_pc.cd), quando o registro for do tipo Aquisição/Contribuição (bem_ativ_imob_oper_cred_pc.dm_tipo_oper=1).
-- Rotina: pkb_integr_bemativimobopcredpc.
--
-- Em 07/12/2016 - Angela Inês.
-- Redmine #26085 - Processo de Integração e Validação do campo Indicador de Número de Parcelas - Blocos F120 e F130.
-- Na validação da integração dos registros dos Blocos F120 e F130, considerar como obrigatório se o Tipo de Operação for 1-Aquisição/Contribuição, caso o Tipo
-- de Operação seja 0-Depreciação/Amortização, o campo não deverá ser informado.
-- Rotina: pkb_integr_bemativimobopcredpc.
--
-- Em 07/02/2017 - Fábio Tavares
-- Redmine #27809 - Ajustes nas mensagens de validação do bloco F600
-- Rotina: pkb_integr_contrretfontepc.
--
-- Em 08/02/2017 - Fábio Tavares
-- Redmine #27834 - Foi corrigido a contagem dos registros integrados do bloco F
-- Rotinas: foi feita a revisão de todos os processos do bloco F.
--
-- Em 13/02/2017 - Fábio Tavares
-- Redmine #28117 - Integração do Bloco F600 - Campo código da Receita
-- Rotina: pkb_integr_contrretfontepc
--
-- Em 06/03/2017 - Fábio Tavares
-- Redmine #29077 - Ajuste na chave de Integração do Bloco F100
--
-- Em 13/03/2017 - Angela Inês.
-- Redmine #29286 - Adaptação da validação dos Blocos F120/F130: Integração e Tela/Portal.
-- Adequar as validações dos Blocos F120/F130 com a Integração e com a digitação das informações via Tela/Portal.
-- Rotinas: pkb_integr_bemativimobopcredpc e pkb_integr_prdemdocopergercc.
--
-- Em 20/09/2017 - Angela Inês.
-- Redmine #34795 - Correção na Integração dos dados da Contribuição retida na fonte - Bloco F600.
-- Alterar o processo que identifica se o registro já existe na base de dados, considerando as colunas: empresa_id, dm_ind_nat_ret, dt_ret, cod_rec,
-- dm_ind_nat_rec e cnpj.
-- Rotina: pkb_integr_contrretfontepc.
--
-- Em 08/11/2017 - Angela Inês.
-- Redmine #36303 - Validação dos Registros dos Blocos F120/F130 - Atualização.
-- No processo de validação dos Registros dos Blocos F120/F130 - Bens do Ativo Imobilizado com Operações de Crédito de PIS/COFINS, considerar a existência do
-- registro, e executar a atualização (update) do mesmo.
-- Rotina: pkb_integr_bemativimobopcredpc.
--
-- Em 23/04/2018 - Karina de Paula
-- Redmine #41878 - Novo processo para o registro Bloco F100 - Demais Documentos e Operações Geradoras de Contribuições e Créditos.
-- Rotina Alterada: pkb_integr_demdocopergercc - Incluída a verificação da nova coluna DM_GERA_RECEITA e incluída tb no insert e update da rotina
--
-- Em 20/06/2018 - Angela Inês.
-- Redmine #43888/#43894 - Desenvolver Rotina Programável - F100/F700 - Receita POC e Receita Financeira.
-- Procedimento para gravar o log/alteração dos Demais Documentos e Operações Geradoras de Contribuição e Créditos - Bloco F100, e de Deduções Diversas - Bloco F700.
-- Rotina: pkb_inclui_log_demdocopergercc e pkb_inclui_log_deddiversapc.
--
-- Em 25/09/2018 - Angela Inês.
-- Redmine #47193 - Revisar as UKs e as novas Colunas dos registros dos Blocos F.
--
-- Em 27/02/2019 - Renan Alves
-- Redmine #50434 - Integração Bloco F - pkb_integr_prconsopinspcrcaum
-- Foi alterado a tabela pr_cons_oper_ins_pc_rc para pr_cons_op_ins_pcrc_aum no update que era realizado na verificação
-- Rotina: pkb_integr_prconsopinspcrcaum
--
-- Em 01/03/2019 - Fernando Basso
-- Redmine #52018 - Ajuste de validação na integração de Contribuição Retida na Fonte (F600)
-- Correção de atribuição de valor para o campo cod_rec (pkgs - 147, 148 e 151)
--
-- Em 18/03/2019 - Renan Alves
-- Redmine #52187 - Erro ao integrar - Bloco F100 (dm_ind_orig_cred )
-- Foi incluído verificação para quando o código tipo de operação for 0, será necessário validar o
-- parâmetro indicador da origem do crédito
-- Rotina: pkb_integr_demdocopergercc
--
-- Em 25/04/2019 - Karina de Paula
-- Redmine #52071 - Erro ao validar integração de registro F100
-- Rotina Alterada: pkb_integr_demdocopergercc - Foi incluído no início da processo a verificação se existe o registro (pk_csf_ddo.fkb_dm_st_proc_demdocopergercc)
--                                               , se não existir busca o ID para inserção. Dessa forma não irá gerar um novo ID para um registro que já existe
--                                               por exemplo, uma integração WEBSERVICE.
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
   gv_cd_obj          obj_integr.cd%type := '50'; -- Demais Documentos e Operações - Bloco F EFD Contribuições
   --
--|Declaração de constantes
   erro_de_validacao  constant number := 1;
   erro_de_sistema    constant number := 2;
   informacao         constant number := 35;
   ddo_integrada      constant number := 16;

----------------------------------------------------------------------------------------------------
-- Procedimento para gravar o log/alteração das Deduções Diversas - Bloco F700
procedure pkb_inclui_log_deddiversapc( en_deducaodiversapc_id in deducao_diversa_pc.id%type
                                     , ev_resumo              in log_deducao_diversa_pc.resumo%type
                                     , ev_mensagem            in log_deducao_diversa_pc.mensagem%type
                                     , en_usuario_id          in neo_usuario.id%type
                                     , ev_maquina             in varchar2 );
----------------------------------------------------------------------------------------------------
-- Procedimento para gravar o log/alteração dos Demais Documentos e Operações Geradoras de Contribuição e Créditos - Bloco F100
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
-- Procedimento de registro de log de erros na validação do DDO
procedure pkb_seta_obj_ref ( ev_objeto in varchar2
                           );
----------------------------------------------------------------------------------------------------
--| Procedimento seta o tipo de integração que será feito
   -- 0 - Somente válida os dados e registra o Log de ocorrência
   -- 1 - Válida os dados e registra o Log de ocorrência e insere a informação
   -- Todos os procedimentos de integração fazem referência a ele
procedure pkb_seta_tipo_integr ( en_tipo_integr in number
                               );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela cred_decor_evento_pc
procedure pkb_integr_creddecoreventopc ( est_log_generico_ddo           in out nocopy dbms_sql.number_table
                                       , est_row_creddecoreventopc      in out nocopy cred_decor_evento_pc%rowtype
                                       , en_multorg_id                  in            mult_org.id%TYPE
                                       , ev_cnpj_empr                   in            varchar2
                                       , ev_tipocredpc_cd               in            varchar2
                                       );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela DEDUCAO_DIVERSA_PC
procedure pkb_integr_deducaodiversapc ( est_log_generico_ddo         in out nocopy dbms_sql.number_table
                                      , est_row_deducaodiversaspc    in out nocopy deducao_diversa_pc%rowtype
                                      , ev_cnpj_empr                 in varchar2
                                      , en_multorg_id                in mult_org.id%type
                                      );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CONTR_RET_FONTE_PC
procedure pkb_integr_contrretfontepc ( est_log_generico_ddo           in out nocopy dbms_sql.number_table
                                     , est_row_contr_ret_fonte_pc     in out nocopy contr_ret_fonte_pc%rowtype
                                     , en_multorg_id                  in            mult_org.id%type
                                     , ev_cnpj_empr                   in            varchar2
                                     );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela PR_CONS_OP_INS_PCRCOAUM
procedure pkb_integr_prconsopinspcrcoaum ( est_log_generico_ddo         in out nocopy dbms_sql.number_table
                                         , est_row_prconsopinspcrcoaum  in out nocopy pr_cons_op_ins_pcrcoaum%rowtype
                                         , ev_cpf_cnpj                  in            varchar2
                                         , en_cd_orig                   in            number
                                         );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CONS_OP_INS_PCRCOMP_AUM
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
-- Procedimento de integração da tabela PR_COMP_OP_INS_PC_RCOMP
procedure pkb_integr_prconsopinspcrcomp( est_log_generico_ddo           in out nocopy dbms_sql.number_table
                                       , est_row_pr_cons_op_ins_pcrcomp in out nocopy pr_cons_op_ins_pc_rcomp%rowtype
                                       , ev_cpf_cnpj                    in            varchar2
                                       , en_cd_orig                     in            number );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela COMP_OPER_INS_PC_RCOMP
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
-- Procedimento de integração da tabela COMP_REC_DET_RC
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
-- Procedimento de integração da tabela pr_cons_op_ins_pcrc_aum
procedure pkb_integr_prconsopinspcrcaum ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                        , est_row_prconsopinspcrcaum  in out nocopy pr_cons_op_ins_pcrc_aum%rowtype
                                        , ev_cpf_cnpj                 in            varchar2
                                        , en_cd_orig                  in            number
                                        );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CONS_OPER_INS_PC_RC_AUM
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
-- Procedimento de integração da tabela PR_CONS_OPER_INS_PC_RC
procedure pkb_integr_prconsoperinspcrc ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                       , est_row_prconsoperinspcrc   in out nocopy pr_cons_oper_ins_pc_rc%rowtype
                                       , ev_cpf_cnpj                 in            varchar2
                                       , en_cd_orig                  in            orig_proc.cd%type
                                       );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela CONS_OPER_INS_PC_RC
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
-- Procedimento de integração da tabela oper_ativ_imob_proc_ref
procedure pkb_integr_operativimobprocref ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                         , est_row_operativimobprocref in out nocopy oper_ativ_imob_proc_ref%rowtype
                                         , ev_cpf_cnpj                 in            varchar2
                                         );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela oper_ativ_imob_cus_orc
procedure pkb_integr_operativimobcusorc ( est_log_generico_ddo        in out nocopy dbms_sql.number_table
                                        , est_row_operativimobcusorc  in out nocopy oper_ativ_imob_cus_orc%rowtype
                                        , ev_cpf_cnpj                 in            varchar2
                                        , ev_cod_st_pis               in            varchar2
                                        , ev_cod_st_cofins            in            varchar2
                                        );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela oper_ativ_imob_cus_inc
procedure pkb_integr_operativimobcusinc ( est_log_generico_ddo             in out nocopy dbms_sql.number_table
                                        , est_row_operativimobcusinc       in out nocopy oper_ativ_imob_cus_inc%rowtype
                                        , en_multorg_id                    in            mult_org.id%type
                                        , ev_cpf_cnpj                      in            varchar2
                                        , ev_cod_st_pis                    in            varchar2
                                        , ev_cod_st_cofins                 in            varchar2
                                        );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela oper_ativ_imob_vend
procedure pkb_integr_operativimobvend ( est_log_generico_ddo          in out nocopy dbms_sql.number_table
                                      , est_row_operativimobvend      in out nocopy oper_ativ_imob_vend%rowtype
                                      , en_multorg_id                 in            mult_org.id%type
                                      , ev_cnpj_empr                  in            varchar2
                                      , ev_cod_st_pis                 in            varchar2
                                      , ev_cod_st_cofins              in            varchar2
                                      );

----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela cred_pres_est_abert_pc
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
-- Procedimento de integração da tabela pr_bai_oper_cred_pc
procedure pkb_integr_prbaiopercredpc ( est_log_generico_ddo    in out nocopy dbms_sql.number_table
                                     , est_row_prbaiopercredpc in out nocopy pr_bai_oper_cred_pc%rowtype
                                     , ev_cpf_cnpj             in            varchar2
                                     , en_cd_origproc          in            orig_proc.cd%type
                                     );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela bem_ativ_imob_oper_cred_pc
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
-- Procedimento de integração da tabela pr_dem_doc_oper_ger_cc
procedure pkb_integr_prdemdocopergercc ( est_log_generico_ddo      in out nocopy  dbms_sql.number_table
                                       , est_row_prdemdocopergercc in out nocopy  pr_dem_doc_oper_ger_cc%rowtype
                                       , ev_cpf_cnpj               in             varchar2
                                       , en_cd_origproc            in             number
                                       );
----------------------------------------------------------------------------------------------------
-- Procedimento de integração da tabela dem_doc_oper_ger_cc
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
