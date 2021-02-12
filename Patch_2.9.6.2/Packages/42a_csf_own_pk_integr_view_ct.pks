create or replace package csf_own.pk_integr_view_ct is

-------------------------------------------------------------------------------------------------------
-- Especificação do pacote de integração de Conhecimentos de Transportes a partir de leitura de views
-------------------------------------------------------------------------------------------------------
--
-- Em 28/01/2021   - Karina de Paula
-- Redmine #75607  - Ajustes na rotina de integração do CTe
-- Rotina Alterada - pkb_ler_Conhec_Transp => Incluído novo parâmetro "en_integra", sendo o valor igual a "0" saíra da integração
--                 - pkb_ler_conhec_transp_imp / pkb_ler_ctcompltado_imp => => Campo dm_inf_imp recebe valor default "0" se estiver nulo
-- Liberado        - Release_2.9.7, Patch_2.9.6.2 e Patch_2.9.5.5
--
-- Em 14/09/2020   - Karina de Paula
-- Redmine #67105  - Criar processo de validação da CT_CONS_SIT
-- Rotina Alterada - pkb_seta_integr_erp_ct_cs      => Retirado o update na ct_cons_sit e incluída a chamada da pk_csf_api_cons_sit.pkb_ins_atu_ct_cons_sit
--                 - pkb_seta_integr_erp_ct_cs      => Incluído o parâmetro de entrada empresa_id
--                 - pkb_int_ct_cons_sit            => Incluída a empresa_id na chamada da pkb_seta_integr_erp_ct_cs e no cursor o novo domínio 7
--                 - fkg_verif_int_ct_cons_sit      => Retirada linha comentada
--                 - pkb_alter_sit_integra_cte_canc => Retirado o update na ct_cons_sit e incluída a chamada da pk_csf_api_cons_sit.pkb_ins_atu_ct_cons_sit
--                 - pkb_alter_sit_integra_cte      => Retirado o update na ct_cons_sit e incluída a chamada da pk_csf_api_cons_sit.pkb_ins_atu_ct_cons_sit
--                 - pkb_ret_infor_erp              => Incluído o parâmetro de entrada empresa_id na chamada da pkb_alter_sit_integra_cte
--                 - pkb_ret_infor_resp_erp         => Incluído o parâmetro de entrada empresa_id na chamada da pkb_alter_sit_integra_cte
-- Liberado        - Release_2.9.5
--
-- Em 25/03/2020     - Allan Magrini
-- Redmine #65041    - Falha na integração da tag CT-e terceiro <nDoc> (CEVA LOG)
-- Alterado o campo nro_docto para varchar2(30)
-- Rotinas Alteradas - tab_csf_ct_inf_outro 
--
-- Em 09/10/2019        - Karina de Paula
-- Redmine #52654/59814 - Alterar todas as buscar na tabela PESSOA para retornar o MAX ID
-- Rotinas Alteradas    - Trocada a função pk_csf.fkg_cnpj_empresa_id pela pk_csf.fkg_empresa_id_cpf_cnpj
-- NÃO ALTERE A REGRA DESSAS ROTINAS SEM CONVERSAR COM EQUIPE
--
-- Em 20/09/2019   - Karina de Paula
-- Redmine #53132  - Atualizar Campos Chaves da View VW_CSF_CT_INF_OUTRO
-- Rotina Alterada - pkb_ler_r_outro_ctinfunidtrans => Incluido o campo NRO_DOCTO na chamada da pk_csf_api_ct.pkb_integr_r_outro_infut, na montagem do select
-- dinamico e nos campos do vetor vt_tab_csf_r_outr_ctunidtransp
-- pkb_ler_r_outro_ctinfunidcarga => Incluido o campo NRO_DOCTO na chamada da pk_csf_api_ct.pkb_integr_r_outro_infuc, na montagem do select
-- dinamico e nos campos do vetor vt_tab_csf_r_outr_ctunidcarga
--
-- Em 26/07/2019 - Luis Marques
-- Redmine #56729 - eed - CT-e e NFS-e ainda ficam com erro de validação
-- Rotinas Alteradas: pkb_ler_Conhec_Transp
--                    Alterado validação para aviso não gerar erro de validação
--
-- Em 23/07/2019 - Luis Marques
-- Redmine #56565 - feed - Mensagem de ADVERTENCIA está deixando documento com ERRO DE VALIDAÇÂO
-- Rotina alterada: pkb_ler_Conhec_Transp
--                  Alterado para colocar verificação de falta de Codigo de base de calculo de PIS/COFINS
--                  como advertencia e não marcar o documento com erro de validação se for só esse log.
-- 
-- Em 23/05/2019 - Karina de Paula
-- Redmine #54711 - CT-e não exclui.
-- Rotina Alterada: PK_INTEGR_VIEW_CT => Incluído o parâmetro de entrada en_excl_rloteintwsct na chamada da rotina pk_csf_api_ct.pkb_excluir_dados_ct
--
-- === AS ALTERAÇÕES ABAIXO ESTÃO NA ORDEM CRESCENTE USADA ANTERIORMENTE ================================================================================= --
--
-- Em: 19/09/2012 Rogério Silva.
-- Foi adicionado o campo "NRO_CARREG" no processo de integração de conhecimento de transporte.
--
-- Em: 25/02/2013 Rogério Silva.
-- Foi substituida a função pk_csf.fkg_busca_conhectransp_id por pk_csf_ct.fkg_busca_conhectransp_id.
-- Rotinas: pkb_ler_Conhec_Transp e pkb_ler_Conhec_Transp_Canc.
--
-- Em 22/08/2013 Rogério Silva.
-- Atividade Melhoria #416 Redmine
-- Alterado o processo de recuperação de dados, de join, para uso de funções.
-- Modificado o procedimento pkb_ret_infor_erro_ct_erp para que ficasse igual ao de nota fiscal de serviço.
-- Removido a váriavel GV_TRIM_ASPAS e substituido por GV_ASPAS
-- Resolvido erros como:  usar apas em valor numérico e não utiliza-las em valores do tipo VARCHAR2.
-- Retirar a função trim() e trunc() de dentro das strings que vão ser executadas em banco não-oracle.
-- Utilizar parametro de formato de data da empresa no lugar de fixo 'dd/mm/rrrr'.
-- Trocar condição de utilização de cod_part na clausula where de quando for null para quando for not null.
--
-- Atividade #600 -> Adicionado os procedimentos pkb_ler_conhec_transp_fat, pkb_ler_conhec_transp_dup, pkb_ler_ct_aquav_cont_nf
-- e pkb_ler_ct_aquav_cont_nf e adicionado os campos DT_INI e DT_FIM na integração do procedimento pkb_integr_conhec_transp_duto.
--
-- Em 07/11/2013 - Rogério Silva
-- Alterado o tamanho do campo "renavam" de 9 para 11 na definição do tipo "tab_csf_ctrodo_veic"
--
-- Em 30/06/2014 - Angela Inês.
-- Redmine #3207 - Suporte - Leandro/GPA. Verificar trace enviado por email - Integração de Conhecimentos de Transportes.
-- 1) Corrigir a ordem/where dos select/cursores.
--    Rotinas: pkb_int_infor_erp, pkb_ret_infor_erp, pkb_ret_infor_resp_erp e pkb_ret_infor_canc_erp.
-- 2) Tirar a função pk_csf.fkg_ret_hr_aut_empresa_id de dentro dos loops, pois a mesma não está sendo utilizada.
--    Rotinas: pkb_int_infor_erp, pkb_ret_infor_erp, pkb_ret_infor_resp_erp e pkb_ret_infor_canc_erp.
-- 3) Verificar se as variáveis de todas as funções de dentro dos loops estão sendo utilizadas.
--    Rotinas: pkb_int_infor_erp, pkb_ret_infor_erp, pkb_ret_infor_resp_erp e pkb_ret_infor_canc_erp.
-- 4) Eliminar a função pk_csf.fkg_empresa_id_pelo_cpf_cnpj de dentro do loop e colocar antes do loop.
--    Rotinas: pkb_ler_conhec_transp e pkb_ler_conhec_transp_canc.
-- 5) Eliminar a função pk_csf.fkg_nome_empresa de dentro do loop e colocar antes do loop.
--    Rotina: pkb_ler_conhec_transp.
--
-- Em 05/01/2015 - Angela Inês.
-- Redmine #5616 - Adequação dos objetos que utilizam dos novos conceitos de Mult-Org.
--
-- Em 27/01/2015 - Rogério Silva
-- Redmine #5696 - Indicação do parâmetro de integração
--
-- Em 01/06/2015 - Rogério Silva
-- Redmine #8230 - Processo de Registro de Log em Packages - Conhecimento de Transporte
--
-- Em 01/07/2015 - Rogério Silva.
-- Redmine #9707 - Avaliar os processos que utilizam empresa_integr_banco.dm_ret_infor_integr: variáveis locais e globais.
--
-- Em 30/08/2016 - Marcos Garcia
-- Redmine #22304 - Alterar os processos de integração/validação.
--
-- Em 01/03/2017 - Leandro Savenhago
-- Redmine 28832- Implementar o "Parâmetro de Formato de Data Global para o Sistema".
-- Implementar o "Parâmetro de Formato de Data Global para o Sistema".
--
-- Em 07/11/2017 - Leandro Savenhago
-- Redmine 33993- Integração de CTe cuja emissão é propria legado através da Open Interface
--
-- Em 26/12/2017 - Marcelo Ono
-- Redmine #36867 - Atualização no processo de Integração do Conhecimento de Transporte para Emissão Própria - CTe 3.00.
-- Rotinas: pkb_ler_Conhec_Transp, pkb_ler_conhec_transp_compl, pkb_ler_conhec_transp_imp, pkb_ler_ct_part_icms, pkb_ler_conhec_transp_infcarga,
--          pkb_ler_conhec_transp_subst, pkb_ler_ct_inf_vinc_mult, pkb_ler_conhec_transp_percurso, pkb_ler_ct_doc_ref_os, pkb_ler_ct_rodo_os,
--          pkb_ler_ct_aereo_peri, pkb_ler_conhec_transp_ferrov, pkb_ler_evento_cte_gtv, pkb_ler_evento_cte_gtv_esp e pkb_ler_evento_cte_desac.
--
-- Em 03/01/2018 - Marcelo Ono
-- Redmine #36867 - Correções no processo de Integração de Conhecimento de Transporte para Emissão Própria.
-- 1- Alterado a coluna "DT_HR_ENT_SIST" pela coluna "DT_SAI_ENT" no filtro da view "VW_CSF_CONHEC_TRANSP".
-- 2- Implementado o processo para recuperar o CPF ou CNPJ do Emitente (variável; vv_cpf_cnpj_emit).
-- 3- Incluído a chamada da procedure "pkb_ler_ct_aquav_cont_nfe" na procedure "pkb_ler_ct_aquav_cont".
-- 4- Corrigido a limpeza do array "vt_tab_csf_ct_aquav_cont_nf", pois haviam duas limpezas para o array "vt_tab_csf_ct_aquav_cont_nfe".
-- Rotina: pkb_seta_where_periodo, pkb_integr_periodo, pkb_ler_ct_aquav_cont e pkb_limpa_array.
--
-- Em 02/02/2018 - Angela Inês.
-- Redmine #39082 - Integração Open-Interface de Conhecimento de Transporte Emissão por Job Scheduller.
-- Rotina: pkb_integr_multorg.
--
-- Em 26/02/2018 - Angela Inês.
-- Redmine #39446 - Adequação de View X Tabela - CTe.
-- Alterado o tamanho da coluna COD_CTA de 30 caracteres para 60 caracteres.
-- Variável global: vt_tab_csf_conhec_transp.cod_cta.
--
-- Em 13/04/2018 - Karina de Paula
-- Redmine #41660 - Alteração processo de Integração de Conhecimento de Transporte, adicionando Integração de PIS e COFINS.
-- Rotina Criada:   pkb_ler_conhec_transp_imp_out
-- Objetos Criados: tab_csf_conhec_transp_impout / vt_tab_csf_ct_imp_out
-- Rotina Alterada: pkb_ler_Conhec_Transp => Incluída a chamada da nova procedure pkb_ler_conhec_transp_imp_out
--
-- Em 25/04/2018 - Karina de Paula
-- Redmine #42163 - Alteração do Layout Leiaute_Integr_OI_XX_CT_V2.7.pdf adicionar processo de integração de PIS e Cofins.
--
-- Em 20/09/2018 - Karina de Paula
-- Redmine #47066 - Integração de Conhecimento de Transporte
-- Rotina alterada: pkb_seta_where_emissao_propria => Incluída a regra abaixo:
-- Regra1: No caso de integração de documentos fiscais ao Portal do Compliance com a Finalidade de emitir o conhecimento de transporte perante a Sefaz,
-- os campos DM_ST_PROC e DM_LEGADO devem receber o valor 0.
-- Regra2: No caso de integração de documentos fiscais cuja emissão é própria ao Portal do Compliance com a finalidade escrituração fiscal, ou seja,
-- os documentos fiscais não serão transmitidos a Sefaz considerar o “de-para” abaixo:
--_ Conhecimento de Transporte Aprovada:   DM_ST_PROC = 4 DM_LEGADO = 1
--_ Conhecimento de Transporte Denegada    DM_ST_PROC = 6 DM_LEGADO = 2
--_ Conhecimento de Transporte Cancelada   DM_ST_PROC = 7 DM_LEGADO = 3
--_ Conhecimento de Transporte Inutilizada DM_ST_PROC = 8 DM_LEGADO = 4
--
-- Em 25/09/2018 - Karina de Paula
-- Redmine #47169 - Analisar o levantamento feito do CTE 3.0
-- Rotina Alterada: pkb_ler_conhec_transp_subst => Incluido campo CPF
-- Rotina Criada: pkb_ler_evento_cte_epec
-- Rotina Alterada: pkb_ler_evento_cte => Incluída a chamada da pkb_ler_evento_cte_epec
--
-- Redmine #47259 - Integração de Conhecimento de Transporte pela tela de "Agendamento de Integração"
-- Rotina Alterada: pkb_integr_periodo => Alterada para trabalhar com multorg e foi incluídos os processos conforme a pkb_integr_multorg
--                  que é usada pelo JOB SCHEDULER
--
-- Em 04/10/2018 - Karina de Paula
-- #47505 - Feed - Integração Agendamento
-- Rotina Alterada: pkb_ler_Conhec_Transp => Incluída a chamada da pk_agend_integr.gvtn_qtd_erp / gvtn_qtd_total / gvtn_qtd_erro / gvtn_qtd_sucesso
-- Incluida a variável global gv_cd_obj. Alterada a ordem da vt_log_generico.delete para não excluir os logs do inicio do processo
--
-- Em 18/10/2018 - Karina de Paula
-- Redmine #47741 - feed - o Contador continua aparecendo mais registros
-- Rotina Alterada: pkb_seta_where_emissao_propria => Incluído parâmetro de data
--
-- Em 27/11/2018 - Angela Inês.
-- Redmine #49137 - Alteração na Integração e Validação de CTe.
-- Ao realizar o agendamento de integração, do tipo Normal, utilizar como condição, a rotina pkb_seta_where_periodo, que trata somente os conhecimentos de
-- emissão própria e terceiro, sem considerar a situação (dm_st_proc), ou legado (dm_legado). A rotina que está sendo chamada, pkb_seta_where_emissao_propria,
-- deverá ser, e está, sendo chamada pelo processo de integração on-line, via job. E neste caso, considera os conhecimentos tratando situação (dm_st_proc), e
-- legado (dm_legado).
-- Rotina: pkb_integracao.
--
-- Em 29/11/2018 - Karina de Paula
-- Redmine #49158 - Integração de Conhecimentos de Transporte cuja emissão é própria através da tela de Agendamento
-- Rotina Alterada: pkb_seta_where_emissao_propria => Retirada a Regra2
--
-- Em 30/11/2018 - Angela Inês.
-- Redmine #49244 - Alterar a integração OnLine de CTe.
-- Não considerar os CTes de Terceiro, somente de Emissão Própria.
-- Rotina: pkb_seta_where_emissao_propria.
--
-- Em 12/12/2018 - Angela Inês.
-- Redmine #49636 - Correção na integração de CTE - Situação do Processo - DM_ST_PROC.
-- Para a integração do CTe, através da View VW_CSF_CONHEC_TRANSP, temos a coluna DM_ST_PROC, como tipo numérico e o tamanho de 2 dígitos.
-- A variável/vetor utilizada para armazenar o valor dessa coluna está declarada como tipo numérico porém com tamanho de 1 dígito.
-- A correção será nessa variável, considerando como tipo numérico e o tamanho de 2 dígitos.
-- Variável: vt_tab_csf_conhec_transp.dm_st_proc.
--
-- Em 31/01/2019 - Marcos Ferreira
-- Redmine #51090 - Valor Base Outras e Valor Base Isenta para CTe Emissao Propria
-- Solicitação: Incluir a integração dos campos VL_BASE_OUTRO, VL_IMP_OUTRO, VL_BASE_ISENTA, ALIQ_APLIC_OUTRO na Integração de impostos para Conhecimento de Transporte
-- Alterações: Criação da integração pela VW_CSF_CONHEC_TRANSP_IMP_FF
-- Procedures Alteradas: pkb_ler_conhec_transp_imp, pkb_ler_conhec_transp_imp_ff
--
-- Em 13/02/2019 - Karina de Paula
-- Redmine #51465 - Falha na integração da tag <xOrig> (TUPPERWARE)
-- Rotina Alterada: vt_tab_csf_conhec_transp_compl => Alterado o tamanho do campo orig_fluxo para varchar2(60)
--                  pkb_ler_conhec_transp_compl    => Arrumado o número das fases
--
-- === AS ALTERAÇÕES PASSARAM A SER INCLUÍDAS NO INÍCIO DA PACKAGE ================================================================================= --
--
-------------------------------------------------------------------------------------------------------------------------------------------

   --| informações de Conhecimentos de Transportes não integrados: VW_CSF_CONHEC_TRANSP
   -- Nível - 0

      type tab_csf_conhec_transp is record ( cpf_cnpj_emit	    varchar2(14)
                                           , dm_ind_emit	    number(1)
                                           , dm_ind_oper	    number(1)
                                           , cod_part	            varchar2(60)
                                           , cod_mod	            varchar2(2)
                                           , serie	            varchar2(3)
                                           , nro_ct	            number(9)
                                           , sit_docto	            varchar2(2)
                                           , uf_ibge_emit	    number(2)
                                           , cfop	            number(4)
                                           , nat_oper	            varchar2(60)
                                           , dm_for_pag	            number(1)
                                           , subserie	            varchar2(2)
                                           , dt_hr_emissao	    date
                                           , dm_tp_cte	            number(1)
                                           , dm_proc_emiss	    number(1)
                                           , vers_apl_cte	    varchar2(20)
                                           , chave_cte_ref	    varchar2(44)
                                           , ibge_cidade_emit	    number(7)
                                           , descr_cidade_emit	    varchar2(60)
                                           , sigla_uf_emit	    varchar2(2)
                                           , dm_modal	            varchar2(2)
                                           , dm_tp_serv	            number(1)
                                           , ibge_cidade_ini	    number(7)
                                           , descr_cidade_ini	    varchar2(60)
                                           , sigla_uf_ini	    varchar2(2)
                                           , ibge_cidade_fim   	    number(7)
                                           , descr_cidade_fim	    varchar2(60)
                                           , sigla_uf_fim	    varchar2(2)
                                           , dm_retira	            number(1)
                                           , det_retira	            varchar2(160)
                                           , dm_tomador	            number(1)
                                           , inf_adic_fisco	    varchar2(2000)
                                           , dm_st_proc        	    number(2)
                                           , usuario	            varchar2(100)
                                           , vias_dacte_custom	    number(2)
                                           , dm_ind_frt       	    number(1)
                                           , cod_infor        	    varchar2(6)
                                           , cod_cta          	    varchar2(60)
                                           , sist_orig              varchar2(10)
                                           , unid_org               varchar2(20)
                                           , dt_sai_ent             date
                                           , nro_carreg             number(20)
                                           , dm_leitura             number(1)
                                           , nro_chave_cte          varchar2(44)
                                           , dm_legado              number(1)
                                           , dm_global              number(1)     --Atualização CTe 3.0
                                           , dm_ind_ie_toma         number(1)     --Atualização CTe 3.0
                                           , vl_tot_trib            number(15,2)  --Atualização CTe 3.0
                                           , obs_global             varchar2(256) --Atualização CTe 3.0
                                           , descr_serv             varchar2(30)  --Atualização CTe 3.0
                                           , qtde_carga_os          number(15,4)  --Atualização CTe 3.0
                                           );
   --
      type t_tab_csf_conhec_transp is table of tab_csf_conhec_transp index by binary_integer;
      vt_tab_csf_conhec_transp t_tab_csf_conhec_transp;
--

--| Informações do Registro de Eventos do CTe: VW_CSF_EVENTO_CTE
   -- Nível 1
      type tab_csf_evento_cte is record ( cpf_cnpj_emit      varchar2(14)
                                        , dm_ind_emit        number(1)
                                        , dm_ind_oper        number(1)
                                        , cod_part	     varchar2(60)
                                        , cod_mod	     varchar2(2)
                                        , serie	             varchar2(3)
                                        , nro_ct             number(9)
                                        , dt_solic           date
                                        , tipoeventosefaz_cd varchar2(10)
                                        , dm_st_proc         number(1)
                                        );
   --
      type t_tab_csf_evento_cte is table of tab_csf_evento_cte index by binary_integer;
      vt_tab_csf_evento_cte t_tab_csf_evento_cte;
--

--| Informações do Registro de Eventos do CTe Multimodal: VW_CSF_EVENTO_CTE_MULTIMODAL
   -- Nível 2
      type tab_csf_evento_cte_multimodal is record ( cpf_cnpj_emit      varchar2(14)
                                                   , dm_ind_emit        number(1)
                                                   , dm_ind_oper        number(1)
                                                   , cod_part	        varchar2(60)
                                                   , cod_mod	        varchar2(2)
                                                   , serie	        varchar2(3)
                                                   , nro_ct             number(9)
                                                   , dt_solic           date
                                                   , descr_registro     varchar2(1000)
                                                   , nro_doc            varchar2(43)
                                                   );
   --
      type t_tab_csf_evento_cte_multimod is table of tab_csf_evento_cte_multimodal index by binary_integer;
      vt_tab_csf_evento_cte_multimod t_tab_csf_evento_cte_multimod;
--

--| Informações do Registro de Eventos do CTe Multimodal: VW_CSF_EVENTO_CTE_CCE
   -- Nível 2
      type tab_csf_evento_cte_cce is record ( cpf_cnpj_emit      varchar2(14)
                                            , dm_ind_emit        number(1)
                                            , dm_ind_oper        number(1)
                                            , cod_part	         varchar2(60)
                                            , cod_mod	         varchar2(2)
                                            , serie	         varchar2(3)
                                            , nro_ct             number(9)
                                            , dt_solic           date
                                            , estrutcte_grupo    varchar2(30)
                                            , estrutcte_campo    varchar2(30)
                                            , valor_alterado     varchar2(500)
                                            , nro_item_alter     number(2)
                                            );
   --
      type t_tab_csf_evento_cte_cce is table of tab_csf_evento_cte_cce index by binary_integer;
      vt_tab_csf_evento_cte_cce t_tab_csf_evento_cte_cce;
--

--| Informações do Registro de Evento de CTe GTV (Grupo de Transporte de Valores): VW_CSF_EVENTO_CTE_GTV - Atualização CTe 3.0
   -- Nível 2
      type tab_csf_evento_cte_gtv is record ( cpf_cnpj_emit      varchar2(14)
                                            , dm_ind_emit        number(1)
                                            , dm_ind_oper        number(1)
                                            , cod_part	         varchar2(60)
                                            , cod_mod	         varchar2(2)
                                            , serie	         varchar2(3)
                                            , nro_ct             number(9)
                                            , dt_solic           date
                                            , nro_doc            varchar2(20)
                                            , id_aidf            varchar2(20)
                                            , serie_doc          varchar2(3)
                                            , subserie_doc       varchar2(3)
                                            , dt_emiss           date
                                            , dig_verif          number(1)
                                            , qtde_carga         number(15,4)
                                            );
   --
      type t_tab_csf_evento_cte_gtv is table of tab_csf_evento_cte_gtv index by binary_integer;
      vt_tab_csf_evento_cte_gtv t_tab_csf_evento_cte_gtv;
--

--| Informações do Registro de Evento de CTe GTV (Grupo de Transporte de Valores) - Espécies Transportadas: VW_CSF_EVENTO_CTE_GTV_ESP - Atualização CTe 3.0
   -- Nível 3
      type tab_csf_evento_cte_gtv_esp is record ( cpf_cnpj_emit  varchar2(14)
                                                , dm_ind_emit    number(1)
                                                , dm_ind_oper    number(1)
                                                , cod_part	 varchar2(60)
                                                , cod_mod	 varchar2(2)
                                                , serie	         varchar2(3)
                                                , nro_ct         number(9)
                                                , dt_solic       date
                                                , nro_doc        varchar2(20)
                                                , id_aidf        varchar2(20)
                                                , dm_tp_especie  number(1)
                                                , vl_esp         number(15,2)
                                                );
   --
      type t_tab_csf_evento_cte_gtv_esp is table of tab_csf_evento_cte_gtv_esp index by binary_integer;
      vt_tab_csf_evento_cte_gtv_esp t_tab_csf_evento_cte_gtv_esp;
--

--| Informações do Registro de Informações dos documentos referenciados CTe Outros Serviços: VW_CSF_EVENTO_CTE_DESAC - Atualização CTe 3.0
   -- Nível 1
      type tab_csf_evento_cte_desac is record ( cpf_cnpj_emit      varchar2(14)
                                              , dm_ind_emit        number(1)
                                              , dm_ind_oper        number(1)
                                              , cod_part	   varchar2(60)
                                              , cod_mod	           varchar2(2)
                                              , serie	           varchar2(3)
                                              , nro_ct             number(9)
                                              , dt_solic           date
                                              , dm_ind_desac_oper  varchar2(1)
                                              , obs                varchar2(255)
                                              );
   --
      type t_tab_csf_evento_cte_desac is table of tab_csf_evento_cte_desac index by binary_integer;
      vt_tab_csf_evento_cte_desac t_tab_csf_evento_cte_desac;
--
--| Informações das Informações de Evento do CTe EPEC: VW_CSF_EVENTO_CTE_EPEC
   -- Nível 1
      type tab_csf_evento_cte_epec is record ( cpf_cnpj_emit      varchar2(14)
                                             , dm_ind_emit        number(1)
                                             , dm_ind_oper        number(1)
                                             , cod_part	          varchar2(60)
                                             , cod_mod	          varchar2(2)
                                             , serie	          varchar2(3)
                                             , nro_ct             number(9)
                                             , dt_solic           date
                                             , just_cont          varchar2(255)
                                             );
   --
      type t_tab_csf_evento_cte_epec is table of tab_csf_evento_cte_epec index by binary_integer;
      vt_tab_csf_evento_cte_epec t_tab_csf_evento_cte_epec;
--
--| Informações das Unidades de Carga (Containeres/ULD/Outros) do Conhecimento de Transporte: VW_CSF_CT_INF_UNID_CARGA
   -- Nível 1
      type tab_csf_ct_inf_unid_carga is record ( cpf_cnpj_emit      varchar2(14)
                                               , dm_ind_emit        number(1)
                                               , dm_ind_oper        number(1)
                                               , cod_part	    varchar2(60)
                                               , cod_mod	    varchar2(2)
                                               , serie	            varchar2(3)
                                               , nro_ct             number(9)
                                               , dm_tp_unid_carga   number(1)
                                               , ident_unid_carga   varchar2(20)
                                               , qtde_rat_tot       number(5,2)
                                               );
   --
      type t_tab_csf_ct_inf_unid_carga is table of tab_csf_ct_inf_unid_carga index by binary_integer;
      vt_tab_csf_ct_inf_unid_carga t_tab_csf_ct_inf_unid_carga;
--
--| Informações dos Lacres das Unidades de Carga (Containeres/ULD/Outros) do Conhecimento de Transporte: VW_CSF_CT_INF_UNID_CARGA_LACRE
   -- Nível 2
      type tab_csf_ct_unid_carga_lacre is record ( cpf_cnpj_emit      varchar2(14)
                                                 , dm_ind_emit        number(1)
                                                 , dm_ind_oper        number(1)
                                                 , cod_part	      varchar2(60)
                                                 , cod_mod	      varchar2(2)
                                                 , serie	      varchar2(3)
                                                 , nro_ct             number(9)
                                                 , dm_tp_unid_carga   number(1)
                                                 , ident_unid_carga   varchar2(20)
                                                 , nro_lacre          varchar2(20)
                                                 );
   --
      type t_tab_csf_ct_unid_carga_lacre is table of tab_csf_ct_unid_carga_lacre index by binary_integer;
      vt_tab_csf_ct_unid_carga_lacre t_tab_csf_ct_unid_carga_lacre;
--

--| Informações das Unidades de Transporte (Carreta/Reboque/Vagão) do Conhecimento de Transporte: VW_CSF_CT_INF_UNID_TRANSP
   -- Nível 1
      type tab_csf_ct_inf_unid_transp is record ( cpf_cnpj_emit      varchar2(14)
                                                , dm_ind_emit        number(1)
                                                , dm_ind_oper        number(1)
                                                , cod_part	     varchar2(60)
                                                , cod_mod	     varchar2(2)
                                                , serie	             varchar2(3)
                                                , nro_ct             number(9)
                                                , dm_tp_unid_transp  number(1)
                                                , ident_unid_transp  varchar2(20)
                                                , qtde_rat_tot       number(5,2)
                                                );
   --
      type t_tab_csf_ct_inf_unid_transp is table of tab_csf_ct_inf_unid_transp index by binary_integer;
      vt_tab_csf_ct_inf_unid_transp t_tab_csf_ct_inf_unid_transp;
--

--| Informações dos Lacres das Unidades de Transporte (Carreta/Reboque/Vagão) do Conhecimento de Transporte: VW_CSF_CT_INF_UNID_TRANSP_LACR
   -- Nível 2
      type tab_csf_ct_unid_transp_lacr is record ( cpf_cnpj_emit      varchar2(14)
                                                 , dm_ind_emit        number(1)
                                                 , dm_ind_oper        number(1)
                                                 , cod_part	      varchar2(60)
                                                 , cod_mod	      varchar2(2)
                                                 , serie	      varchar2(3)
                                                 , nro_ct             number(9)
                                                 , dm_tp_unid_transp  number(1)
                                                 , ident_unid_transp  varchar2(20)
                                                 , nro_lacre          varchar2(20)
                                                 );
   --
      type t_tab_csf_ct_unid_transp_lacr is table of tab_csf_ct_unid_transp_lacr index by binary_integer;
      vt_tab_csf_ct_unid_transp_lacr t_tab_csf_ct_unid_transp_lacr;
--

--| Informações das Cargas das Unidades de Transporte (Carreta/Reboque/Vagão) do Conhecimento de Transporte: VW_CSF_CT_INF_UNID_TRANSP_CARG
   -- Nível 2
      type tab_csf_ct_unid_transp_carg is record ( cpf_cnpj_emit      varchar2(14)
                                                 , dm_ind_emit        number(1)
                                                 , dm_ind_oper        number(1)
                                                 , cod_part	      varchar2(60)
                                                 , cod_mod	      varchar2(2)
                                                 , serie	      varchar2(3)
                                                 , nro_ct             number(9)
                                                 , dm_tp_unid_transp  number(1)
                                                 , ident_unid_transp  varchar2(20)
                                                 , dm_tp_unid_carga   number(1)
                                                 , ident_unid_carga   varchar2(20)
                                                 , qtde_rat           number(5,2)
                                                 );
   --
      type t_tab_csf_ct_unid_transp_carg is table of tab_csf_ct_unid_transp_carg index by binary_integer;
      vt_tab_csf_ct_unid_transp_carg t_tab_csf_ct_unid_transp_carg;
--

--| Informações dos Lacres das Cargas das Unidades de Transporte (Carreta/Reboque/Vagão) do Conhecimento de Transporte: VW_CSF_CT_IUT_CARGA_LACRE
   -- Nível 3
      type tab_csf_ct_iut_carga_lacre is record ( cpf_cnpj_emit       varchar2(14)
                                                , dm_ind_emit        number(1)
                                                , dm_ind_oper        number(1)
                                                , cod_part	      varchar2(60)
                                                , cod_mod	      varchar2(2)
                                                , serie	      varchar2(3)
                                                , nro_ct             number(9)
                                                , dm_tp_unid_transp  number(1)
                                                , ident_unid_transp  varchar2(20)
                                                , dm_tp_unid_carga   number(1)
                                                , ident_unid_carga   varchar2(20)
                                                , nro_lacre          varchar2(20)
                                                );
   --
      type t_tab_csf_ct_iut_carga_lacre is table of tab_csf_ct_iut_carga_lacre index by binary_integer;
      vt_tab_csf_ct_iut_carga_lacre t_tab_csf_ct_iut_carga_lacre;
--

--| Informações dos demais documentos do Conhecimento de Transporte: VW_CSF_CT_INF_OUTRO
   -- Nível 1
      type tab_csf_ct_inf_outro is record ( cpf_cnpj_emit    varchar2(14)
                                          , dm_ind_emit      number(1)
                                          , dm_ind_oper      number(1)
                                          , cod_part	     varchar2(60)
                                          , cod_mod	     varchar2(2)
                                          , serie	     varchar2(3)
                                          , nro_ct           number(9)
                                          , dm_tipo_doc      varchar2(2)
                                          , descr_outros     varchar2(100)
                                          , nro_docto        varchar2(20)
                                          , dt_emissao       date
                                          , vl_doc_fisc      number(15,2)
                                          , dt_prev_ent      date
                                          );
   --
      type t_tab_csf_ct_inf_outro is table of tab_csf_ct_inf_outro index by binary_integer;
      vt_tab_csf_ct_inf_outro t_tab_csf_ct_inf_outro;
--

--| Informações do Relacionamento de Outro Documento com Informação da Unidade do Transporte: VW_CSF_R_OUTRO_CTINFUNIDTRANSP
   -- Nível 2
      type tab_csf_r_out_ctinfunidtransp is record ( cpf_cnpj_emit     varchar2(14)
                                                   , dm_ind_emit       number(1)
                                                   , dm_ind_oper       number(1)
                                                   , cod_part	       varchar2(60)
                                                   , cod_mod	       varchar2(2)
                                                   , serie	       varchar2(3)
                                                   , nro_ct            number(9)
                                                   , dm_tipo_doc       varchar2(2)
                                                   , dm_tp_unid_transp number(1)
                                                   , ident_unid_transp varchar2(20)
                                                   , nro_docto         varchar2(20)
                                                   );
   --
      type t_tab_csf_r_out_ctinunidtransp is table of tab_csf_r_out_ctinfunidtransp index by binary_integer;
      vt_tab_csf_r_outr_ctunidtransp t_tab_csf_r_out_ctinunidtransp;
--

--| Informações do Relacionamento de Outro Documento com Informação da Unidade da Carga: VW_CSF_R_OUTRO_CTINFUNIDCARGA
   -- Nível 2
      type tab_csf_r_out_ctinfunidcarga is record ( cpf_cnpj_emit      varchar2(14)
                                                   , dm_ind_emit       number(1)
                                                   , dm_ind_oper       number(1)
                                                   , cod_part	       varchar2(60)
                                                   , cod_mod	       varchar2(2)
                                                   , serie	       varchar2(3)
                                                   , nro_ct            number(9)
                                                   , dm_tipo_doc       varchar2(2)
                                                   , dm_tp_unid_carga  number(1)
                                                   , ident_unid_carga  varchar2(20)
                                                   , nro_docto         varchar2(20)
                                                   );
   --
      type t_tab_csf_r_out_ctinunidcarga is table of tab_csf_r_out_ctinfunidcarga index by binary_integer;
      vt_tab_csf_r_outr_ctunidcarga t_tab_csf_r_out_ctinunidcarga;
--

--| Informações do ICMS de partilha com a UF de término do serviço de transporte na operação interestadual do CT-e: VW_CSF_CONHEC_TRANSP_PART_ICMS - Atualização CTe 3.0
   -- Nível 1
      type tab_csf_ct_part_icms is record ( cpf_cnpj_emit        varchar2(14)
                                          , dm_ind_emit	         number(1)
                                          , dm_ind_oper          number(1)
                                          , cod_part	         varchar2(60)
                                          , cod_mod              varchar2(2)
                                          , serie                varchar2(3)
                                          , nro_ct               number(9)
                                          , vl_bc_uf_fim         number(15,2)
                                          , perc_fcp_uf_fim      number(5,2)
                                          , perc_icms_uf_fim     number(5,2)
                                          , perc_icms_inter      number(5,2)
                                          , perc_icms_inter_part number(5,2)
                                          , vl_fcp_uf_fim        number(15,2)
                                          , vl_icms_uf_fim       number(15,2)
                                          , vl_icms_uf_ini       number(15,2)
                                         );
   --
      type t_tab_csf_ct_part_icms is table of tab_csf_ct_part_icms index by binary_integer;
      vt_tab_csf_ct_part_icms t_tab_csf_ct_part_icms;
--

--| Informações do CT-e multimodal vinculado: VW_CSF_CT_INF_VINC_MULT - Atualização CTe 3.0
   -- Nível 1
      type tab_csf_ct_inf_vinc_mult is record ( cpf_cnpj_emit varchar2(14)
                                              , dm_ind_emit   number(1)
                                              , dm_ind_oper   number(1)
                                              , cod_part      varchar2(60)
                                              , cod_mod       varchar2(2)
                                              , serie         varchar2(3)
                                              , nro_ct        number(9)
                                              , nro_chave_cte varchar2(44)
                                              );
   --
      type t_tab_csf_ct_inf_vinc_mult is table of tab_csf_ct_inf_vinc_mult index by binary_integer;
      vt_tab_csf_ct_inf_vinc_mult t_tab_csf_ct_inf_vinc_mult;
--

--| Informações do Percurso do CT-e Outros Serviços: VW_CSF_CONHEC_TRANSP_PERCURSO - Atualização CTe 3.0
   -- Nível 1
      type tab_csf_ct_transp_percurso is record ( cpf_cnpj_emit varchar2(14)
                                                , dm_ind_emit   number(1)
                                                , dm_ind_oper   number(1)
                                                , cod_part      varchar2(60)
                                                , cod_mod       varchar2(2)
                                                , serie         varchar2(3)
                                                , nro_ct        number(9)
                                                , seq           number(2)
                                                , uf            varchar2(2)
                                                );
   --
      type t_tab_csf_ct_transp_percurso is table of tab_csf_ct_transp_percurso index by binary_integer;
      vt_tab_csf_ct_transp_percurso t_tab_csf_ct_transp_percurso;
--

--| Informações dos documentos referenciados CTe Outros Serviços: VW_CSF_CT_DOC_REF_OS - Atualização CTe 3.0
   -- Nível 1
      type tab_csf_ct_doc_ref_os is record ( cpf_cnpj_emit varchar2(14)
                                           , dm_ind_emit   number(1)
                                           , dm_ind_oper   number(1)
                                           , cod_part      varchar2(60)
                                           , cod_mod       varchar2(2)
                                           , serie         varchar2(3)
                                           , nro_ct        number(9)
                                           , nro_doc       varchar2(20)
                                           , serie_doc     varchar2(3)
                                           , subserie_doc  varchar2(3)
                                           , dt_emiss      date
                                           , vl_transp     number(15,2)
                                           );
   --
      type t_tab_csf_ct_doc_ref_os is table of tab_csf_ct_doc_ref_os index by binary_integer;
      vt_tab_csf_ct_doc_ref_os t_tab_csf_ct_doc_ref_os;
--

--| Informações das NF-e do Conhecimento de Transporte: VW_CSF_CT_INF_NFE
   -- Nível 1
      type tab_csf_ct_inf_nfe is record ( cpf_cnpj_emit    varchar2(14)
                                        , dm_ind_emit      number(1)
                                        , dm_ind_oper      number(1)
                                        , cod_part	   varchar2(60)
                                        , cod_mod	   varchar2(2)
                                        , serie	           varchar2(3)
                                        , nro_ct           number(9)
                                        , nro_chave_nfe    varchar2(44)
                                        , pin              number(9)   
                                        , dt_prev_ent      date
                                        );
   --
      type t_tab_csf_ct_inf_nfe is table of tab_csf_ct_inf_nfe index by binary_integer;
      vt_tab_csf_ct_inf_nfe t_tab_csf_ct_inf_nfe;
--

--| Informações do Relacionamento de NF-e com Informação da Unidade de Transporte: VW_CSF_R_NFE_CTINFUNIDTRANSP
   -- Nível 2
      type tab_csf_r_nfe_ctinfunidtransp is record ( cpf_cnpj_emit      varchar2(14)
                                                   , dm_ind_emit        number(1)
                                                   , dm_ind_oper        number(1)
                                                   , cod_part	        varchar2(60)
                                                   , cod_mod	        varchar2(2)
                                                   , serie	        varchar2(3)
                                                   , nro_ct             number(9)
                                                   , nro_chave_nfe      varchar2(44)
                                                   , dm_tp_unid_transp  number(1)   
                                                   , ident_unid_transp  varchar2(20)
                                                   );
   --
      type t_tab_csf_r_nfe_ctinunidtransp is table of tab_csf_r_nfe_ctinfunidtransp index by binary_integer;
      vt_tab_csf_r_nfe_infunidtransp t_tab_csf_r_nfe_ctinunidtransp;
--

--| Informações do Relacionamento de NF-e com Informação da Unidade de CARGA: VW_CSF_R_NFE_CTINFUNIDCARGA
   -- Nível 2
      type tab_csf_r_nfe_ctinfunidcarga is record ( cpf_cnpj_emit      varchar2(14)
                                                  , dm_ind_emit        number(1)
                                                  , dm_ind_oper        number(1)
                                                  , cod_part	       varchar2(60)
                                                  , cod_mod	       varchar2(2)
                                                  , serie	       varchar2(3)
                                                  , nro_ct             number(9)
                                                  , nro_chave_nfe      varchar2(44)
                                                  , dm_tp_unid_carga   number(1)
                                                  , ident_unid_carga   varchar2(20)
                                                  );
   --
      type t_tab_csf_r_nfe_ctinunidcarga is table of tab_csf_r_nfe_ctinfunidcarga index by binary_integer;
      vt_tab_csf_r_nfe_infunidcarga t_tab_csf_r_nfe_ctinunidcarga;
--

--| Informações das NFs do Conhecimento de Transporte: VW_CSF_CT_INF_NF
   -- Nível 1
      type tab_csf_ct_inf_nf is record ( cpf_cnpj_emit    varchar2(14)
                                       , dm_ind_emit      number(1)
                                       , dm_ind_oper      number(1)
                                       , cod_part	  varchar2(60)
                                       , cod_mod	  varchar2(2)
                                       , serie	          varchar2(3)
                                       , nro_ct           number(9)
                                       , cod_mod_nf       varchar2(2)
                                       , serie_nf         varchar2(3)
                                       , nro_nf           varchar2(20)
                                       , dt_emissao       date
                                       , nro_roma_nf      varchar2(20)
                                       , nro_ped_nf       varchar2(20)
                                       , vl_bc_icms       number(15,2)
                                       , vl_icms          number(15,2)
                                       , vl_bc_icmsst     number(15,2)
                                       , vl_icmsst        number(15,2)
                                       , vl_total_prod    number(15,2)
                                       , vl_total_nf      number(15,2)
                                       , cfop             number(4)
                                       , peso_kg          number(15,3)
                                       , pin              number(9)
                                       , dt_prev_ent      date 
                                       );
   --
      type t_tab_csf_ct_inf_nf is table of tab_csf_ct_inf_nf index by binary_integer;
      vt_tab_csf_ct_inf_nf t_tab_csf_ct_inf_nf;
--

--| Informações do Relacionamento de Nota Fiscal com Informação da Unidade do Transporte: VW_CSF_R_NF_CTINFUNIDTRANSP
   -- Nível 2
      type tab_csf_r_nf_ctinfunidtransp is record ( cpf_cnpj_emit      varchar2(14)
                                                  , dm_ind_emit        number(1)
                                                  , dm_ind_oper        number(1)
                                                  , cod_part	       varchar2(60)
                                                  , cod_mod	       varchar2(2)
                                                  , serie	       varchar2(3)
                                                  , nro_ct             number(9)
                                                  , cod_mod_nf         varchar2(2)  
                                                  , serie_nf           varchar2(3)  
                                                  , nro_nf             varchar2(20) 
                                                  , dm_tp_unid_transp  number(1)
                                                  , ident_unid_transp  varchar2(20)
                                                  );
   --
      type t_tab_csf_r_nf_ctinfunidtransp is table of tab_csf_r_nf_ctinfunidtransp index by binary_integer;
      vt_tab_csf_r_nf_infunidtransp t_tab_csf_r_nf_ctinfunidtransp;
--

--| Informações do Relacionamento de Nota Fiscal com Informação da Unidade de Carga: VW_CSF_R_NF_CTINFUNIDCARGA
   -- Nível 2
      type tab_csf_r_nf_ctinfunidcarga is record ( cpf_cnpj_emit      varchar2(14)
                                                 , dm_ind_emit        number(1)
                                                 , dm_ind_oper        number(1)
                                                 , cod_part	      varchar2(60)
                                                 , cod_mod	      varchar2(2)
                                                 , serie	      varchar2(3)
                                                 , nro_ct             number(9)
                                                 , cod_mod_nf         varchar2(2)
                                                 , serie_nf           varchar2(3)
                                                 , nro_nf             varchar2(20)
                                                 , dm_tp_unid_carga   number(1)
                                                 , ident_unid_carga   varchar2(20)
                                                 );
   --
      type t_tab_csf_r_nf_ctinfunidcarga is table of tab_csf_r_nf_ctinfunidcarga index by binary_integer;
      vt_tab_csf_r_nf_infunidcarga t_tab_csf_r_nf_ctinfunidcarga;
--

--| Informações do MULTIMODAL: VW_CSF_CT_MULTIMODAL
   -- Nível 1
      type tab_csf_ct_multimodal is record ( cpf_cnpj_emit    varchar2(14)
                                           , dm_ind_emit      number(1)
                                           , dm_ind_oper      number(1)
                                           , cod_part	      varchar2(60)
                                           , cod_mod	      varchar2(2)
                                           , serie	      varchar2(3)
                                           , nro_ct           number(9)
                                           , cod_part_consg   varchar2(60)
                                           , cod_part_red     varchar2(60)
                                           , cod_mun_orig     number(7)   
                                           , cod_mun_dest     number(7)
                                           , otm              varchar2(20)
                                           , dm_ind_nat_frt   number(2)   
                                           , vl_liq_frt       number(15,2)
                                           , vl_gris          number(15,2)
                                           , vl_pdg           number(15,2)
                                           , vl_out           number(15,2)
                                           , vl_frt           number(15,2)
                                           , veic_id          varchar2(7) 
                                           , uf_id            varchar2(2)
                                           );
   --
      type t_tab_csf_ct_multimodal is table of tab_csf_ct_multimodal index by binary_integer;
      vt_tab_csf_ct_multimodal t_tab_csf_ct_multimodal;
--

--| Informações dos Participantes autorizados a fazer download do XML: VW_CSF_CT_AUT_XML
   -- Nível 1
      type tab_csf_ct_aut_xml is record ( cpf_cnpj_emit    varchar2(14)
                                        , dm_ind_emit      number(1)
                                        , dm_ind_oper      number(1)
                                        , cod_part	   varchar2(60)
                                        , cod_mod	   varchar2(2)
                                        , serie	           varchar2(3)
                                        , nro_ct           number(9)
                                        , cnpj             varchar2(14)
                                        , cpf              varchar2(11)
                                        );
   --
      type t_tab_csf_ct_aut_xml is table of tab_csf_ct_aut_xml index by binary_integer;
      vt_tab_csf_ct_aut_xml t_tab_csf_ct_aut_xml;
--

--| Informações dos Dados da Fatura do CT-e: VW_CSF_CONHEC_TRANSP_FAT
   -- Nível 1
      type tab_csf_ct_fat is record ( cpf_cnpj_emit    varchar2(14)
                                    , dm_ind_emit      number(1)
                                    , dm_ind_oper      number(1)
                                    , cod_part	       varchar2(60)
                                    , cod_mod	       varchar2(2)
                                    , serie	       varchar2(3)
                                    , nro_ct           number(9)
                                    , nro_fat          varchar2(60)
                                    , vl_orig          number(15,2)
                                    , vl_desc          number(15,2)
                                    , vl_liq           number(15,2)
                                    );
   --
      type t_tab_csf_ct_fat is table of tab_csf_ct_fat index by binary_integer;
      vt_tab_csf_ct_fat t_tab_csf_ct_fat;
--

--| Informações dos Dados daa Duplicatas do CT-e: VW_CSF_CONHEC_TRANSP_DUP
   -- Nível 1
      type tab_csf_ct_dup is record ( cpf_cnpj_emit    varchar2(14)
                                    , dm_ind_emit      number(1)
                                    , dm_ind_oper      number(1)
                                    , cod_part	       varchar2(60)
                                    , cod_mod	       varchar2(2)
                                    , serie	       varchar2(3)
                                    , nro_ct           number(9)
                                    , nro_dup          varchar2(60)
                                    , dt_venc          date
                                    , vl_dup           number(15,2)
                                    );
   --
      type t_tab_csf_ct_dup is table of tab_csf_ct_dup index by binary_integer;
      vt_tab_csf_ct_dup t_tab_csf_ct_dup;
--

--| informações do tomador do serviço:VW_CSF_CONHEC_TRANSP_TOMADOR
   -- Nível 1
      type tab_csf_ct_tomador  is record ( cpf_cnpj_emit       varchar2(14)
                                         , dm_ind_emit	       number(1)
                                         , dm_ind_oper	       number(1)
                                         , cod_part	       varchar2(60)
                                         , cod_mod	       varchar2(2)
                                         , serie	       varchar2(3)
                                         , nro_ct              number(9)
                                         , cnpj	               varchar2(14)
                                         , cpf	               varchar2(11)
                                         , ie	               varchar2(14)
                                         , nome	               varchar2(60)
                                         , nome_fant	       varchar2(60)
                                         , fone	               varchar2(14)
                                         , lograd	       varchar2(255)
                                         , nro	               varchar2(60)
                                         , compl	       varchar2(60)
                                         , bairro	       varchar2(60)
                                         , ibge_cidade	       number(7)
                                         , descr_cidade	       varchar2(60)
                                         , cep                 varchar2(8)
                                         , uf                  varchar2(2)
                                         , cod_pais	       number(4)
                                         , descr_pais	       varchar2(60)
                                         , email	       varchar2(60)
                                         );
   --
      type t_tab_csf_ct_tomador is table of tab_csf_ct_tomador index by binary_integer;
      vt_tab_csf_ct_tomador t_tab_csf_ct_tomador;
--

--| informações do complementares: VW_CSF_CONHEC_TRANSP_COMPL
   -- Nível 1
      type tab_csf_conhec_transp_compl  is record ( cpf_cnpj_emit       varchar2(14)
                                                  , dm_ind_emit	        number(1)
                                                  , dm_ind_oper         number(1)
                                                  , cod_part	        varchar2(60)
                                                  , cod_mod            	varchar2(2)
                                                  , serie             	varchar2(3)
                                                  , nro_ct              number(9)
                                                  , carac_adic_transp	varchar2(15)
                                                  , carac_adic_serv	varchar2(30)
                                                  , emitente	        varchar2(20)
                                                  , orig_fluxo	        varchar2(60)
                                                  , dest_fluxo	        varchar2(60)  --Atualização CTe 3.0
                                                  , rota_fluxo	        varchar2(10)
                                                  , dm_tp_per_entr	number(1)
                                                  , dt_prog	        date
                                                  , dt_ini             	date
                                                  , dt_fim           	date
                                                  , dm_tp_hor_entr    	number(1)
                                                  , hora_prog        	varchar2(8)
                                                  , hora_ini	        varchar2(8)
                                                  , hora_fim	        varchar2(8)
                                                  , orig_calc_frete    	varchar2(40)
                                                  , dest_calc_frete	varchar2(40)
                                                  , obs_geral           varchar2(2000)
                                                  );
   --
      type t_tab_csf_conhec_transp_compl is table of tab_csf_conhec_transp_compl index by binary_integer;
      vt_tab_csf_conhec_transp_compl t_tab_csf_conhec_transp_compl;

   --| informações de Sigla ou código interno da Filial/Porto/Estação/Aeroporto de Passagem: VW_CSF_CT_COMPL_PASS
   -- Nível 2
      type tab_csf_ct_compl_pass is record ( cpf_cnpj_emit  varchar2(14)
                                           , dm_ind_emit    number(1)
                                           , dm_ind_oper    number(1)
                                           , cod_part	    varchar2(60)
                                           , cod_mod        varchar2(2)
                                           , serie          varchar2(3)
                                           , nro_ct         number(9)
                                           , pass           varchar2(15)
                                           );
   --
      type t_tab_csf_ct_compl_pass is table of tab_csf_ct_compl_pass index by binary_integer;
      vt_tab_csf_ct_compl_pass t_tab_csf_ct_compl_pass;

   --| informações de Observações do Contribuinte/Fiscal: VW_CSF_CT_COMPL_OBS
   -- Nível 2
      type tab_csf_ct_compl_obs is record ( cpf_cnpj_emit varchar2(14)
                                          , dm_ind_emit	  number(1)
                                          , dm_ind_oper   number(1)
                                          , cod_part	  varchar2(60)
                                          , cod_mod       varchar2(2)
                                          , serie         varchar2(3)
                                          , nro_ct        number(9)
                                          , dm_tipo	  number(1)
                                          , campo	  varchar2(20)
                                          , texto	  varchar2(160)
                                          );
   --
      type t_tab_csf_ct_compl_obs is table of tab_csf_ct_compl_obs index by binary_integer;
      vt_tab_csf_ct_compl_obs t_tab_csf_ct_compl_obs;

   --| informações do Emitente: VW_CSF_CONHEC_TRANSP_EMIT
   -- Nível 1
      type tab_csf_conhec_transp_emit is record ( cpf_cnpj_emit	   varchar2(14)
                                                , dm_ind_emit	   number(1)
                                                , dm_ind_oper      number(1)
                                                , cod_part	   varchar2(60)
                                                , cod_mod          varchar2(2)
                                                , serie            varchar2(3)
                                                , nro_ct           number(9)
                                                , ie	           varchar2(14)
                                                , nome	           varchar2(60)
                                                , nome_fant        varchar2(60)
                                                , lograd	   varchar2(60)
                                                , nro	           varchar2(60)
                                                , compl	           varchar2(60)
                                                , bairro	   varchar2(60)
                                                , ibge_cidade	   number(7)
                                                , descr_cidade	   varchar2(60)
                                                , cep	           varchar2(8)
                                                , uf	           varchar2(2)
                                                , cod_pais	   number(4)
                                                , descr_pais	   varchar2(60)
                                                , fone	           varchar2(14)
                                                , dm_ind_sn        number(1)
                                                , cnpj	           varchar2(14)
                                                );
   --
      type t_tab_csf_conhec_transp_emit is table of tab_csf_conhec_transp_emit index by binary_integer;
      vt_tab_csf_conhec_transp_emit t_tab_csf_conhec_transp_emit;

   --| informações do Remetente das mercadorias transportadas pelo CT : VW_CSF_CONHEC_TRANSP_REM
   -- Nível 1
      type tab_csf_conhec_transp_rem is record ( cpf_cnpj_emit	  varchar2(14)
                                               , dm_ind_emit	  number(1)
                                               , dm_ind_oper      number(1)
                                               , cod_part	  varchar2(60)
                                               , cod_mod          varchar2(2)
                                               , serie            varchar2(3)
                                               , nro_ct           number(9)
                                               , cnpj	          varchar2(14)
                                               , cpf	          varchar2(11)
                                               , ie	          varchar2(14)
                                               , nome	          varchar2(60)
                                               , nome_fant	  varchar2(60)
                                               , fone             varchar2(14)
                                               , lograd	          varchar2(255)
                                               , nro	          varchar2(60)
                                               , compl	          varchar2(60)
                                               , bairro	          varchar2(60)
                                               , ibge_cidade	  number(7)
                                               , descr_cidade     varchar2(60)
                                               , cep              varchar2(8)
                                               , uf	          varchar2(2)
                                               , cod_pais	  number(4)
                                               , descr_pais	  varchar2(60)
                                               , email            varchar2(60)
                                               );
   --
      type t_tab_csf_conhec_transp_rem is table of tab_csf_conhec_transp_rem index by binary_integer;
      vt_tab_csf_conhec_transp_rem t_tab_csf_conhec_transp_rem;

   --| informações da Remetente das mercadorias transportadas pelo CT: VW_CSF_CTREM_INF_NF
   -- Nível 2
      type tab_csf_ctrem_inf_nf is record ( cpf_cnpj_emit   varchar2(14)
                                          , dm_ind_emit     number(1)
                                          , dm_ind_oper     number(1)
                                          , cod_part	    varchar2(60)
                                          , cod_mod         varchar2(2)
                                          , serie           varchar2(3)
                                          , nro_ct          number(9)
                                          , serie_nf	    varchar2(3)
                                          , nro_nf	    varchar2(20)
                                          , dt_emissao	    date
                                          , nro_roma_nf     varchar2(20)
                                          , nro_ped_nf	    varchar2(20)
                                          , vl_bc_icms	    number(15,2)
                                          , vl_icms	    number(15,2)
                                          , vl_bc_icmsst    number(15,2)
                                          , vl_icmsst	    number(15,2)
                                          , vl_total_prod   number(15,2)
                                          , vl_total_nf     number(15,2)
                                          , cfop	    number(4)
                                          , peso_kg	    number(15,3)
                                          , pin	            number(9)
                                          , cod_mod_nf      varchar2(2)
                                          );
   --
      type t_tab_csf_ctrem_inf_nf is table of tab_csf_ctrem_inf_nf index by binary_integer;
      vt_tab_csf_ctrem_inf_nf t_tab_csf_ctrem_inf_nf;

   --| informações do Local de retirada constante na NF: VW_CSF_CTREM_INF_NF_LOCRET
   -- Nível 3
      type tab_csf_ctrem_inf_nf_locret is record ( cpf_cnpj_emit  varchar2(14)
                                                 , dm_ind_emit	  number(1)
                                                 , dm_ind_oper    number(1)
                                                 , cod_part	  varchar2(60)
                                                 , cod_mod        varchar2(2)
                                                 , serie          varchar2(3)
                                                 , nro_ct         number(9)
                                                 , serie_nf	  varchar2(3)
                                                 , nro_nf	  varchar2(20)
                                                 , cnpj	          varchar2(14)
                                                 , cpf	          varchar2(11)
                                                 , nome	          varchar2(60)
                                                 , lograd	  varchar2(255)
                                                 , nro	          varchar2(60)
                                                 , compl	  varchar2(60)
                                                 , bairro	  varchar2(60)
                                                 , ibge_cidade    number(7)
                                                 , descr_cidade	  varchar2(60)
                                                 , uf	          varchar2(2)
                                                 );
   --
      type t_tab_csf_ctrem_inf_nf_locret is table of tab_csf_ctrem_inf_nf_locret index by binary_integer;
      vt_tab_csf_ctrem_inf_nf_locret t_tab_csf_ctrem_inf_nf_locret;

   --| informações das Notas Fiscais Eletrônicas do remetente: VW_CSF_CTREM_INF_NFE
   -- Nível 2
      type tab_csf_ctrem_inf_nfe is record ( cpf_cnpj_emit  varchar2(14)
                                           , dm_ind_emit    number(1)
                                           , dm_ind_oper    number(1)
                                           , cod_part	    varchar2(60)
                                           , cod_mod        varchar2(2)
                                           , serie          varchar2(3)
                                           , nro_ct         number(9)
                                           , nro_chave_nfe  varchar2(44)
                                           , pin	    number(9)
                                           );
   --
      type t_tab_csf_ctrem_inf_nfe is table of tab_csf_ctrem_inf_nfe index by binary_integer;
      vt_tab_csf_ctrem_inf_nfe t_tab_csf_ctrem_inf_nfe;

   --| informações dos demais documentos do remetente: VW_CSF_CTREM_INF_OUTRO
   -- Nível 2
      type tab_csf_ctrem_inf_outro is record ( cpf_cnpj_emit   varchar2(14)
                                             , dm_ind_emit     number(1)
                                             , dm_ind_oper     number(1)
                                             , cod_part	       varchar2(60)
                                             , cod_mod         varchar2(2)
                                             , serie           varchar2(3)
                                             , nro_ct          number(9)
                                             , dm_tipo_doc     varchar2(2)
                                             , descr_outros    varchar2(60)
                                             , nro_docto       varchar2(20)
                                             , dt_emissao      date
                                             , vl_doc_fisc     number(15,2)
                                             );
   --
      type t_tab_csf_ctrem_inf_outro is table of tab_csf_ctrem_inf_outro index by binary_integer;
      vt_tab_csf_ctrem_inf_outro t_tab_csf_ctrem_inf_outro;

   --| informações do local da coleta do remetente: VW_CSF_CTREM_LOC_COLET
   -- Nível 2
      type tab_csf_ctrem_loc_colet is record ( cpf_cnpj_emit   varchar2(14)
                                             , dm_ind_emit     number(1)
                                             , dm_ind_oper     number(1)
                                             , cod_part	       varchar2(60)
                                             , cod_mod         varchar2(2)
                                             , serie           varchar2(3)
                                             , nro_ct          number(9)
                                             , cnpj            varchar2(14)
                                             , cpf             varchar2(11)
                                             , nome            varchar2(60)
                                             , lograd          varchar2(255)
                                             , nro             varchar2(60)
                                             , compl           varchar2(60)
                                             , bairro          varchar2(60)
                                             , ibge_cidade     varchar2(7)
                                             , descr_cidade    varchar2(60)
                                             , UF              varchar2(2)
                                             );
   --
      type t_tab_csf_ctrem_loc_colet is table of tab_csf_ctrem_loc_colet index by binary_integer;
      vt_tab_csf_ctrem_loc_colet t_tab_csf_ctrem_loc_colet;

   --| informações do Expedidor da Carga: VW_CSF_CONHEC_TRANSP_EXPED
   -- Nível 1
      type tab_csf_conhec_transp_exped is record ( cpf_cnpj_emit    varchar2(14)
                                                 , dm_ind_emit	    number(1)
                                                 , dm_ind_oper      number(1)
                                                 , cod_part	    varchar2(60)
                                                 , cod_mod          varchar2(2)
                                                 , serie            varchar2(3)
                                                 , nro_ct           number(9)
                                                 , cnpj	            varchar2(14)
                                                 , cpf              varchar2(11)
                                                 , ie               varchar2(14)
                                                 , nome             varchar2(60)
                                                 , nome_fant        varchar2(60)
                                                 , fone             varchar2(14)
                                                 , lograd           varchar2(255)
                                                 , nro              varchar2(60)
                                                 , compl            varchar2(60)
                                                 , bairro           varchar2(60)
                                                 , ibge_cidade      number(7)
                                                 , descr_cidade     varchar2(60)
                                                 , cep              varchar2(8)
                                                 , uf               varchar2(2)
                                                 , cod_pais	    number(4)
                                                 , descr_pais       varchar2(60)
                                                 , email            varchar2(60)
                                                 );
   --
      type t_tab_csf_conhec_transp_exped is table of tab_csf_conhec_transp_exped index by binary_integer;
      vt_tab_csf_conhec_transp_exped t_tab_csf_conhec_transp_exped;

   --| informações do Recebedor da Carga: VW_CSF_CONHEC_TRANSP_RECEB
   -- Nível 1
      type tab_csf_conhec_transp_receb is record ( cpf_cnpj_emit    varchar2(14)
                                                 , dm_ind_emit	    number(1)
                                                 , dm_ind_oper      number(1)
                                                 , cod_part	    varchar2(60)
                                                 , cod_mod          varchar2(2)
                                                 , serie            varchar2(3)
                                                 , nro_ct           number(9)
                                                 , cnpj	            varchar2 (14)
                                                 , cpf	            varchar2 (11)
                                                 , ie	            varchar2 (14)
                                                 , nome	            varchar2 (60)
                                                 , nome_fant        varchar2 (60)
                                                 , fone             varchar2 (14)
                                                 , lograd           varchar2 (255)
                                                 , nro              varchar2 (60)
                                                 , compl            varchar2 (60)
                                                 , bairro           varchar2 (60)
                                                 , ibge_cidade      varchar2 (7)
                                                 , descr_cidade     varchar2 (60)
                                                 , cep	            varchar2 (8)
                                                 , uf	            varchar2 (2)
                                                 , cod_pais	    varchar2 (4)
                                                 , descr_pais	    varchar2 (60)
                                                 , email            varchar2(60)
                                                 );
   --
      type t_tab_csf_conhec_transp_receb is table of tab_csf_conhec_transp_receb index by binary_integer;
      vt_tab_csf_conhec_transp_receb t_tab_csf_conhec_transp_receb;

   --| informações do Destinatário da Carga: VW_CSF_CONHEC_TRANSP_DEST
   -- Nível 1
      type tab_csf_conhec_transp_dest is record ( cpf_cnpj_emit	   varchar2(14)
                                                 , dm_ind_emit	   number(1)
                                                 , dm_ind_oper     number(1)
                                                 , cod_part	   varchar2(60)
                                                 , cod_mod         varchar2(2)
                                                 , serie           varchar2(3)
                                                 , nro_ct          number(9)
                                                 , cnpj	           varchar2(14)
                                                 , cpf	           varchar2(11)
                                                 , ie	           varchar2(14)
                                                 , nome	           varchar2(60)
                                                 , nome_fant	   varchar2(60)
                                                 , fone	           varchar2(14)
                                                 , lograd	   varchar2(255)
                                                 , nro	           varchar2(60)
                                                 , compl	   varchar2(60)
                                                 , bairro	   varchar2(60)
                                                 , ibge_cidade	   number(7)
                                                 , descr_cidade	   varchar2(60)
                                                 , cep	           varchar2(8)
                                                 , uf	           varchar2(2)
                                                 , cod_pais	   number(4)
                                                 , descr_pais	   varchar2(60)
                                                 , suframa         number(9)
                                                 , email           varchar2(60)
                                                 );
   --
      type t_tab_csf_conhec_transp_dest is table of tab_csf_conhec_transp_dest index by binary_integer;
      vt_tab_csf_conhec_transp_dest t_tab_csf_conhec_transp_dest;

   --| informações do do Local de Entrega constante na Nota Fiscal: VW_CSF_CTDEST_LOCENT
   -- Nível 2
      type tab_csf_ctdest_locent is record ( cpf_cnpj_emit	varchar2(14)
                                           , dm_ind_emit	number(1)
                                           , dm_ind_oper      	number(1)
                                           , cod_part	        varchar2(60)
                                           , cod_mod            varchar2(2)
                                           , serie             	varchar2(3)
                                           , nro_ct            	number(9)
                                           , cnpj             	varchar2(14)
                                           , cpf              	varchar2(11)
                                           , nome             	varchar2(60)
                                           , lograd           	varchar2(255)
                                           , nro              	varchar2(60)
                                           , compl            	varchar2(60)
                                           , bairro            	varchar2(60)
                                           , ibge_cidade      	number(7)
                                           , descr_cidade      	varchar2(60)
                                           , uf	                varchar2(2)
                                           );
   --
      type t_tab_csf_ctdest_locent is table of tab_csf_ctdest_locent index by binary_integer;
      vt_tab_csf_ctdest_locent t_tab_csf_ctdest_locent;

   --| informações de Valores da Prestação de Serviço: VW_CSF_CONHEC_TRANSP_VLPREST
   -- Nível 1
      type tab_csf_conhec_transp_vlprest is record ( cpf_cnpj_emit	varchar2(14)
                                                   , dm_ind_emit	number(1)
                                                   , dm_ind_oper      	number(1)
                                                   , cod_part	        varchar2(60)
                                                   , cod_mod            varchar2(2)
                                                   , serie             	varchar2(3)
                                                   , nro_ct            	number(9)
                                                   , vl_prest_serv	number(15,2)
                                                   , vl_receb	        number(15,2)
                                                   , vl_docto_fiscal	number(15,2)
                                                   , vl_desc	        number(15,2)
                                                   , vl_tot_trib        number(15,2)
                                                   );
   --
      type t_tab_csf_ct_vlprest is table of tab_csf_conhec_transp_vlprest index by binary_integer;
      vt_tab_csf_ct_vlprest t_tab_csf_ct_vlprest;

   --| informações de Componentes do Valor da Prestação: VW_CSF_CTVLPREST_COMP
   -- Nível 2
      type tab_csf_ctvlprest_comp is record ( cpf_cnpj_emit	varchar2(14)
                                            , dm_ind_emit	number(1)
                                            , dm_ind_oper      	number(1)
                                            , cod_part	        varchar2(60)
                                            , cod_mod           varchar2(2)
                                            , serie             varchar2(3)
                                            , nro_ct            number(9)
                                            , nome	        varchar2(15)
                                            , valor             number(15,2)
                                            );
   --
      type t_tab_csf_ctvlprest_comp is table of tab_csf_ctvlprest_comp index by binary_integer;
      vt_tab_csf_ctvlprest_comp t_tab_csf_ctvlprest_comp;

   --| informações relativas aos Impostos: VW_CSF_CONHEC_TRANSP_IMP
   -- Nível 1
      type tab_csf_conhec_transp_imp is record ( cpf_cnpj_emit	     varchar2(14)
                                               , dm_ind_emit	     number(1)
                                               , dm_ind_oper         number(1)
                                               , cod_part	     varchar2(60)
                                               , cod_mod             varchar2(2)
                                               , serie               varchar2(3)
                                               , nro_ct              number(9)
                                               , cod_imposto	     number(2)
                                               , cod_st	             varchar2(2)
                                               , vl_base_calc	     number(15,2)
                                               , aliq_apli	     number(5,2)
                                               , vl_imp_trib	     number(15,2)
                                               , perc_reduc	     number(5,2)
                                               , vl_cred	     number(15,2)
                                               , dm_inf_imp          number(1)
                                               , dm_outra_uf         number(1) --Atualização CTe 3.0
                                               );
   --
      type t_tab_csf_conhec_transp_imp is table of tab_csf_conhec_transp_imp index by binary_integer;
      vt_tab_csf_conhec_transp_imp t_tab_csf_conhec_transp_imp;


      --  Informações relativas aos Impostos - Flex Field: VW_CSF_CONHEC_TRANSP_IMP_FF
      --  Nível 2
      type tab_csf_conhec_transp_imp_ff is table of vw_csf_conhec_transp_imp_ff%rowtype index by binary_integer;
      vt_tab_csf_ctransp_imp_ff tab_csf_conhec_transp_imp_ff;


      --| informações da Carga do CT-e: VW_CSF_CONHEC_TRANSP_INFCARGA
      -- Nível 1
      type tab_csf_ct_infcarga is record ( cpf_cnpj_emit      varchar2(14)
                                         , dm_ind_emit	      number(1)
                                         , dm_ind_oper        number(1)
                                         , cod_part	      varchar2(60)
                                         , cod_mod            varchar2(2)
                                         , serie              varchar2(3)
                                         , nro_ct             number(9)
                                         , vl_total_merc      number(15,2)
                                         , prod_predom        varchar2(60)
                                         , outra_caract       varchar2(30)
                                         , vl_carga_averb     number(15,2) --Atualização CTe 3.0
                                         );
   --
      type t_tab_csf_ct_infcarga is table of tab_csf_ct_infcarga index by binary_integer;
      vt_tab_csf_ct_infcarga t_tab_csf_ct_infcarga;

   --| informações de quantidades da Carga do CT: VW_CSF_CTINFCARGA_QTDE
   -- Nível 2
      type tab_csf_ctinfcarga_qtde is record ( cpf_cnpj_emit    varchar2(14)
                                             , dm_ind_emit      number(1)
                                             , dm_ind_oper     	number(1)
                                             , cod_part	        varchar2(60)
                                             , cod_mod          varchar2(2)
                                             , serie           	varchar2(3)
                                             , nro_ct          	number(9)
                                             , dm_cod_unid     	varchar2(2)
                                             , tipo_medida     	varchar2(20)
                                             , qtde_carga      	number(15,2)
                                             );
   --
      type t_tab_csf_ctinfcarga_qtde is table of tab_csf_ctinfcarga_qtde index by binary_integer;
      vt_tab_csf_ctinfcarga_qtde t_tab_csf_ctinfcarga_qtde;

   --| informações dos containers: VW_CSF_CONHEC_TRANSP_CONT
   -- Nível 1
      type tab_csf_conhec_transp_cont is record ( cpf_cnpj_emit	    varchar2(14)
                                                , dm_ind_emit	    number(1)
                                                , dm_ind_oper       number(1)
                                                , cod_part	    varchar2(60)
                                                , cod_mod           varchar2(2)
                                                , serie             varchar2(3)
                                                , nro_ct            number(9)
                                                , nro_cont          number(20)
                                                , dt_prevista	    date
                                                );
   --
      type t_tab_csf_conhec_transp_cont is table of tab_csf_conhec_transp_cont index by binary_integer;
      vt_tab_csf_conhec_transp_cont t_tab_csf_conhec_transp_cont;

   --| informações de Lacres dos containers: VW_CSF_CTCONT_LACRE
   -- Nível 2
      type tab_csf_ctcont_lacre is record ( cpf_cnpj_emit    varchar2(14)
                                          , dm_ind_emit	     number(1)
                                          , dm_ind_oper      number(1)
                                          , cod_part	     varchar2(60)
                                          , cod_mod          varchar2(2)
                                          , serie            varchar2(3)
                                          , nro_ct           number(9)
                                          , nro_cont	     number(20)
                                          , nro_lacre	     varchar2(20)
                                          );
   --
      type t_tab_csf_ctcont_lacre is table of tab_csf_ctcont_lacre index by binary_integer;
      vt_tab_csf_ctcont_lacre t_tab_csf_ctcont_lacre;

   --| informações de Lacres dos containers: VW_CSF_CONHEC_TRANSP_DOCANT
   -- Nível 1
      type tab_csf_ct_docant is record ( cpf_cnpj_emit  varchar2(14)
                                       , dm_ind_emit	number(1)
                                       , dm_ind_oper    number(1)
                                       , cod_part	varchar2(60)
                                       , cod_mod        varchar2(2)
                                       , serie          varchar2(3)
                                       , nro_ct         number(9)
                                       , cnpj           varchar2(14)
                                       , cpf            varchar2(11)
                                       , ie             varchar2(14)
                                       , uf             varchar2(2)
                                       , nome           varchar2(60)
                                       );
   --
      type t_tab_csf_ct_docant is table of tab_csf_ct_docant index by binary_integer;
      vt_tab_csf_ct_docant t_tab_csf_ct_docant;


   --| informações de Documentos de Transporte Anterior: VW_CSF_CTDOCANT_PAPEL
   -- Nível 2
      type tab_csf_ctdocant_papel is record ( cpf_cnpj_emit	varchar2(14)
                                            , dm_ind_emit	number(1)
                                            , dm_ind_oper      	number(1)
                                            , cod_part	        varchar2(60)
                                            , cod_mod           varchar2(2)
                                            , serie             varchar2(3)
                                            , nro_ct            number(9)
                                            , cnpj              varchar2(14)
                                            , cpf               varchar2(11)
                                            , dm_tp_doc        	varchar2(2)
                                            , serie_doc	        varchar2(3)
                                            , sub_serie         varchar2(2)
                                            , nro_docto        	varchar2(30)
                                            , dt_emissao        date
                                            );
   --
      type t_tab_csf_ctdocant_papel is table of tab_csf_ctdocant_papel index by binary_integer;
      vt_tab_csf_ctdocant_papel t_tab_csf_ctdocant_papel;

   --| informações de Documentos de Transporte Anterior: VW_CSF_CTDOCANT_ELETR
   -- Nível 2
      type tab_csf_ctdocant_eletr is record ( cpf_cnpj_emit	varchar2(14)
                                            , dm_ind_emit	number(1)
                                            , dm_ind_oper      	number(1)
                                            , cod_part	        varchar2(60)
                                            , cod_mod           varchar2(2)
                                            , serie             varchar2(3)
                                            , nro_ct            number(9)
                                            , cnpj	        varchar2(14)
                                            , cpf	        varchar2(11)
                                            , nro_chave_cte	varchar2(44)
                                            );
   --
      type t_tab_csf_ctdocant_eletr is table of tab_csf_ctdocant_eletr index by binary_integer;
      vt_tab_csf_ctdocant_eletr t_tab_csf_ctdocant_eletr;

   --| informações de Seguro da Carga: VW_CSF_CONHEC_TRANSP_SEG
   -- Nível 1
      type tab_csf_conhec_transp_seg is record ( cpf_cnpj_emit	   varchar2(14)
                                               , dm_ind_emit	   number(1)
                                               , dm_ind_oper       number(1)
                                               , cod_part	   varchar2(60)
                                               , cod_mod           varchar2(2)
                                               , serie             varchar2(3)
                                               , nro_ct            number(9)
                                               , dm_resp_seg       number(1)
                                               , descr_seguradora  varchar2(30)
                                               , nro_apolice       varchar2(20)
                                               , nro_averb         varchar2(20)
                                               , vl_merc	   number(15,2)
                                               );
   --
      type t_tab_csf_conhec_transp_seg is table of tab_csf_conhec_transp_seg index by binary_integer;
      vt_tab_csf_conhec_transp_seg t_tab_csf_conhec_transp_seg;

   --| informações do modal Rodoviário: VW_CSF_CONHEC_TRANSP_RODO
   -- Nível 1
      type tab_csf_conhec_transp_rodo is record ( cpf_cnpj_emit	    varchar2(14)
                                                , dm_ind_emit	    number(1)
                                                , dm_ind_oper       number(1)
                                                , cod_part	    varchar2(60)
                                                , cod_mod           varchar2(2)
                                                , serie             varchar2(3)
                                                , nro_ct            number(9)
                                                , rntrc             number(20)
                                                , dt_prev_entr      date
                                                , dm_lotacao        number(1)
                                                , serie_ctrb        number(3)
                                                , nro_ctrb	    number(6)
                                                , ciot              number(12)
                                                );
   --
      type t_tab_csf_conhec_transp_rodo is table of tab_csf_conhec_transp_rodo index by binary_integer;
      vt_tab_csf_conhec_transp_rodo t_tab_csf_conhec_transp_rodo;

   --| informações das Ordens de Coleta associados: VW_CSF_CTRODO_OCC
   -- Nível 2
      type tab_csf_ctrodo_occ is record ( cpf_cnpj_emit	        varchar2(14)
                                        , dm_ind_emit	        number(1)
                                        , dm_ind_oper      	number(1)
                                        , cod_part	        varchar2(60)
                                        , cod_mod          	varchar2(2)
                                        , serie            	varchar2(3)
                                        , nro_ct                number(9)
                                        , serie_occ             varchar2(3)
                                        , nro_occ          	number(6)
                                        , dt_emissao       	date
                                        , cnpj	                varchar2(14)
                                        , cod_int          	varchar2(10)
                                        , ie               	varchar2(14)
                                        , uf               	varchar2(2)
                                        , fone             	varchar2(14)
                                        );
   --
      type t_tab_csf_ctrodo_occ is table of tab_csf_ctrodo_occ index by binary_integer;
      vt_tab_csf_ctrodo_occ t_tab_csf_ctrodo_occ;

   --| informações de Vale Pedágio: VW_CSF_CTRODO_INF_VALEPED
   -- Nível 2
      type tab_csf_ctrodo_inf_valeped is record ( cpf_cnpj_emit	    varchar2(14)
                                                , dm_ind_emit	    number(1)
                                                , dm_ind_oper       number(1)
                                                , cod_part	    varchar2(60)
                                                , cod_mod           varchar2(2)
                                                , serie             varchar2(3)
                                                , nro_ct            number(9)
                                                , cnpj_forn         varchar2(14)
                                                , nro_compra        number(20)
                                                , cnpj_pgto         varchar2(14)
                                                , vl_vale_ped       number(15,2)
                                                );
   --
      type t_tab_csf_ctrodo_inf_valeped is table of tab_csf_ctrodo_inf_valeped index by binary_integer;
      vt_tab_csf_ctrodo_inf_valeped t_tab_csf_ctrodo_inf_valeped;

   --| informações de Dimensões da Carga do Modal Aéreo: VW_CSF_CT_AEREO_DIMEN
   -- Nível 2
      type tab_csf_ct_aereo_dimen is record ( cpf_cnpj_emit       varchar2(14)
                                            , dm_ind_emit         number(1)
                                            , dm_ind_oper         number(1)
                                            , cod_part            varchar2(60)
                                            , cod_mod             varchar2(2)
                                            , serie               varchar2(3)
                                            , nro_ct              number(9)
                                            , dimensao            varchar2(14)
                                            );
    --
    type t_tab_csf_ct_aereo_dimen is table of tab_csf_ct_aereo_dimen index by binary_integer;
    vt_tab_csf_ct_aereo_dimen t_tab_csf_ct_aereo_dimen;

   --| informações de manuseio da carga do modal Aéreo: VW_CSF_CT_AEREO_INF_MAN
   -- Nível 2
      type tab_csf_ct_aereo_inf_man is record ( cpf_cnpj_emit      varchar2(14)
                                              , dm_ind_emit        number(1)
                                              , dm_ind_oper        number(1)
                                              , cod_part           varchar2(60)
                                              , cod_mod            varchar2(2)
                                              , serie              varchar2(3)
                                              , nro_ct             number(9)
                                              , dm_manuseio        number(2)
                                              );
    --
    type t_tab_csf_ct_aereo_inf_man is table of tab_csf_ct_aereo_inf_man index by binary_integer;
    vt_tab_csf_ct_aereo_inf_man t_tab_csf_ct_aereo_inf_man;

   --| informações de Transporte de produtos classificados pela ONU como perigosos: VW_CSF_CT_AEREO_PERI
   -- Nível 2
      type tab_csf_ct_aereo_peri is record ( cpf_cnpj_emit      varchar2(14)
                                           , dm_ind_emit        number(1)
                                           , dm_ind_oper        number(1)
                                           , cod_part           varchar2(60)
                                           , cod_mod            varchar2(2)
                                           , serie              varchar2(3)
                                           , nro_ct             number(9)
                                           , nro_onu            varchar2(4)
                                           , qtde_tot_emb       varchar2(20)
                                           , qtde_tot_atr_peri  number(15,4)
                                           , dm_unid_med        number(1)
                                           );
    --
    type t_tab_csf_ct_aereo_peri is table of tab_csf_ct_aereo_peri index by binary_integer;
    vt_tab_csf_ct_aereo_peri t_tab_csf_ct_aereo_peri;

   --| informações de carga especial do modal Aéreo: VW_CSF_CT_AEREO_CARG_ESP
   -- Nível 2
      type tab_csf_ct_aereo_carg_esp is record ( cpf_cnpj_emit     varchar2(14)
                                               , dm_ind_emit       number(1)
                                               , dm_ind_oper       number(1)
                                               , cod_part          varchar2(60)
                                               , cod_mod           varchar2(2)
                                               , serie             varchar2(3)
                                               , nro_ct            number(9)
                                               , cod_imp           varchar2(3)
                                               );
   --
    type t_tab_csf_ct_aereo_carg_esp is table of tab_csf_ct_aereo_carg_esp index by binary_integer;
    vt_tab_csf_ct_aereo_carg_esp t_tab_csf_ct_aereo_carg_esp;

   --| informações de Balsas do modal Aquaviário: VW_CSF_CT_AQUAV_BALSA
   -- Nível 2
      type tab_csf_ct_aquav_balsa is record ( cpf_cnpj_emit      varchar2(14)
                                            , dm_ind_emit        number(1)
                                            , dm_ind_oper        number(1)
                                            , cod_part           varchar2(60)
                                            , cod_mod            varchar2(2)
                                            , serie              varchar2(3)
                                            , nro_ct             number(9)
                                            , balsa              varchar2(60)
                                            );
   --
    type t_tab_csf_ct_aquav_balsa is table of tab_csf_ct_aquav_balsa index by binary_integer;
    vt_tab_csf_ct_aquav_balsa t_tab_csf_ct_aquav_balsa;

   --| informações de Conteiners do modal Aquaviário: VW_CSF_CT_AQUAV_CONT
   -- Nível 2
      type tab_csf_ct_aquav_cont is record ( cpf_cnpj_emit       varchar2(14)
                                           , dm_ind_emit         number(1)
                                           , dm_ind_oper         number(1)
                                           , cod_part            varchar2(60)
                                           , cod_mod             varchar2(2)
                                           , serie               varchar2(3)
                                           , nro_ct              number(20)
                                           , conteiner           varchar2(20)
                                           );
   --
    type t_tab_csf_ct_aquav_cont is table of tab_csf_ct_aquav_cont index by binary_integer;
    vt_tab_csf_ct_aquav_cont t_tab_csf_ct_aquav_cont;

   --| informações de Notas fiscais eletônicas de Conteiners do modal Aquaviário: VW_CSF_CT_AQUAV_CONT_NFE
   -- Nível 2
      type tab_csf_ct_aquav_cont_nfe is record ( cpf_cnpj_emit       varchar2(14)
                                               , dm_ind_emit         number(1)
                                               , dm_ind_oper         number(1)
                                               , cod_part            varchar2(60)
                                               , cod_mod             varchar2(2)
                                               , serie               varchar2(3)
                                               , nro_ct              number(9)
                                               , conteiner           varchar2(20)
                                               , nro_chave_nfe       varchar2(44)
                                               , unid_med_rat        number(5,2)
                                               );
   --
    type t_tab_csf_ct_aquav_cont_nfe is table of tab_csf_ct_aquav_cont_nfe index by binary_integer;
    vt_tab_csf_ct_aquav_cont_nfe t_tab_csf_ct_aquav_cont_nfe;

    --| informações de Notas de Conteiners do modal Aquaviário: VW_CSF_CT_AQUAV_CONT_NF
   -- Nível 2
      type tab_csf_ct_aquav_cont_nf is record ( cpf_cnpj_emit       varchar2(14)
                                              , dm_ind_emit         number(1)
                                              , dm_ind_oper         number(1)
                                              , cod_part            varchar2(60)
                                              , cod_mod             varchar2(2)
                                              , serie               varchar2(3)
                                              , nro_ct              number(9)
                                              , conteiner           varchar2(20)
                                              , serie_nf            varchar2(3)
                                              , nro_nf              number(9)
                                              , unid_med_rat        number(5,2)
                                              );
   --
    type t_tab_csf_ct_aquav_cont_nf is table of tab_csf_ct_aquav_cont_nf index by binary_integer;
    vt_tab_csf_ct_aquav_cont_nf t_tab_csf_ct_aquav_cont_nf;

   --| informações de Lacres de Conteiners do modal Aquaviário: VW_CSF_CT_AQUAV_CONT_LACRE
   -- Nível 2
      type tab_csf_ct_aquav_cont_lacre is record ( cpf_cnpj_emit       varchar2(14)
                                                 , dm_ind_emit         number(1)
                                                 , dm_ind_oper         number(1)
                                                 , cod_part            varchar2(60)
                                                 , cod_mod             varchar2(2)
                                                 , serie               varchar2(3)
                                                 , nro_ct              number(9)
                                                 , conteiner           varchar2(20)
                                                 , lacre               varchar2(20)
                                                 );
   --
    type t_tab_csf_ct_aquav_cont_lacre is table of tab_csf_ct_aquav_cont_lacre index by binary_integer;
    vt_tab_csf_ct_aquav_cont_lacre t_tab_csf_ct_aquav_cont_lacre;

   --| informações de detalhes dos vagões: VW_CSF_CT_FERROV_DETVAG
   -- Nível 2
      type tab_csf_ct_ferrov_detvag is record ( cpf_cnpj_emit       varchar2(14)
                                              , dm_ind_emit         number(1)
                                              , dm_ind_oper         number(1)
                                              , cod_part            varchar2(60)
                                              , cod_mod             varchar2(2)
                                              , serie               varchar2(3)
                                              , nro_ct              number(9)
                                              , nro_vagao           number(8)
                                              , cap_ton             number(5,2)
                                              , tipo_vagao          varchar2(3)
                                              , peso_real           number(5,2)
                                              , peso_bc_frete       number(5,2)
                                              );
   --
    type t_tab_csf_ct_ferrov_detvag is table of tab_csf_ct_ferrov_detvag index by binary_integer;
    vt_tab_csf_ct_ferrov_detvag t_tab_csf_ct_ferrov_detvag;

   --| informações de lacres dos vagões: VW_CSF_CT_FERROV_DETVAG_LACRE
   -- Nível 2
      type tab_csf_ct_ferrov_detvag_lacre is record ( cpf_cnpj_emit      varchar2(14)
                                                    , dm_ind_emit        number(1)
                                                    , dm_ind_oper        number(1)
                                                    , cod_part           varchar2(60)
                                                    , cod_mod            varchar2(2)   
                                                    , serie              varchar2(3)   
                                                    , nro_ct             number(9)
                                                    , nro_vagao          number(8)     
                                                    , nro_lacre          varchar2(20) 
                                                    );
   --
    type t_tab_csf_ct_fer_detvag_lacre is table of tab_csf_ct_ferrov_detvag_lacre index by binary_integer;
    vt_tab_csf_ct_fer_detvag_lacre t_tab_csf_ct_fer_detvag_lacre;

   --| informações de conteiners dos vagões: VW_CSF_CT_FERROV_DETVAG_CONT
   -- Nível 2
      type tab_csf_ct_ferrov_detvag_cont is record ( cpf_cnpj_emit       varchar2(14)
                                                    , dm_ind_emit        number(1)
                                                    , dm_ind_oper        number(1)
                                                    , cod_part           varchar2(60)
                                                    , cod_mod            varchar2(2)
                                                    , serie              varchar2(3)
                                                    , nro_ct             number(9)
                                                    , nro_vagao          number(8)
                                                    , nro_cont           number(20)
                                                    , dt_prev            date 
                                                    );
   --
    type t_tab_csf_ct_fer_detvag_cont is table of tab_csf_ct_ferrov_detvag_cont index by binary_integer;
    vt_tab_csf_ct_fer_detvag_cont t_tab_csf_ct_fer_detvag_cont;

   --| informações do Rateio das NF de Vagões: VW_CSF_CT_FERROV_DETVAG_NF
   -- Nível 2
      type tab_csf_ct_ferrov_detvag_nf is record ( cpf_cnpj_emit      varchar2(14)
                                                 , dm_ind_emit        number(1)
                                                 , dm_ind_oper        number(1)
                                                 , cod_part           varchar2(60)
                                                 , cod_mod            varchar2(2)
                                                 , serie              varchar2(3)
                                                 , nro_ct             number(9)
                                                 , nro_vagao          number(8)
                                                 , serie_nf           varchar2(3)
                                                 , nro_nf             number(20)
                                                 , peso_rat           number(5,2) 
                                                 );
   --
    type t_tab_csf_ct_ferrov_detvag_nf is table of tab_csf_ct_ferrov_detvag_nf index by binary_integer;
    vt_tab_csf_ct_ferrov_detvag_nf t_tab_csf_ct_ferrov_detvag_nf;

   --| informações do Rateio das NFe de Vagões: VW_CSF_CT_FERROV_DETVAG_NFE
   -- Nível 2
      type tab_csf_ct_ferrov_detvag_nfe is record ( cpf_cnpj_emit        varchar2(14)
                                                  , dm_ind_emit          number(1)     
                                                  , dm_ind_oper          number(1)     
                                                  , cod_part             varchar2(60)  
                                                  , cod_mod              varchar2(2)   
                                                  , serie                varchar2(3)
                                                  , nro_ct               number(9)     
                                                  , nro_vagao            number(8)     
                                                  , nro_chave_nfe        varchar2(44)  
                                                  , peso_rat             number(5,2) 
                                                  );
   --
    type t_tab_csf_ct_ferrov_detvag_nfe is table of tab_csf_ct_ferrov_detvag_nfe index by binary_integer;
    vt_tab_csf_ct_fer_detvag_nfe t_tab_csf_ct_ferrov_detvag_nfe;

   --| informações de Vale Pedágio: VW_CSF_CTRODO_VALEPED
   -- Nível 2
      type tab_csf_ctrodo_valeped is record ( cpf_cnpj_emit	varchar2(14)
                                            , dm_ind_emit     	number(1)
                                            , dm_ind_oper      	number(1)
                                            , cod_part	        varchar2(60)
                                            , cod_mod           varchar2(2)
                                            , serie             varchar2(3)
                                            , nro_ct            number(9)
                                            , dm_resp_pagto     number(1)
                                            , nro_reg          	varchar2 (9)
                                            , vl_total_valeped	number(15,2) 
                                            );
   --
      type t_tab_csf_ctrodo_valeped is table of tab_csf_ctrodo_valeped index by binary_integer;
      vt_tab_csf_ctrodo_valeped t_tab_csf_ctrodo_valeped;

   --| informações dos dispositivos do Vale Pedágio: VW_CSF_CTRODO_VALEPED_DISP
   -- Nível 3
      type tab_csf_ctrodo_valeped_disp is record ( cpf_cnpj_emit	varchar2(14)
                                                 , dm_ind_emit	        number(1)
                                                 , dm_ind_oper      	number(1)
                                                 , cod_part	        varchar2(60)
                                                 , cod_mod              varchar2(2)
                                                 , serie             	varchar2(3)
                                                 , nro_ct            	number(9)
                                                 , dm_resp_pagto    	number(1)
                                                 , dm_tp_disp       	number(1)
                                                 , empr_forn        	varchar2(30)
                                                 , dt_vig	        date
                                                 , nro_disp	        varchar2(20)
                                                 , nro_comp	        varchar2(14) 
                                                 );
   --
      type t_tab_csf_ctrodo_valeped_disp is table of tab_csf_ctrodo_valeped_disp index by binary_integer;
      vt_tab_csf_ctrodo_valeped_disp t_tab_csf_ctrodo_valeped_disp;

   --| informações de Dados dos Veículos: VW_CSF_CTRODO_VEIC
   -- Nível 1
      type tab_csf_ctrodo_veic is record ( cpf_cnpj_emit	varchar2(14)
                                         , dm_ind_emit	        number(1)
                                         , dm_ind_oper      	number(1)
                                         , cod_part	        varchar2(60)
                                         , cod_mod              varchar2(2)
                                         , serie             	varchar2(3)
                                         , nro_ct            	number(9)
                                         , placa	        varchar2(9)
                                         , cod_int_veic	        varchar2(10)
                                         , renavam	        varchar2(11)
                                         , tara	                number(6)
                                         , cap_kg	        number(6)
                                         , cap_m3	        number(6)
                                         , dm_tp_prop	        varchar2(1)
                                         , dm_tp_veic       	number(1)
                                         , dm_tp_rod	        varchar2(2)
                                         , dm_tp_car        	varchar2(2)
                                         , uf                	varchar2(2) 
                                         );
   --
      type t_tab_csf_ctrodo_veic is table of tab_csf_ctrodo_veic index by binary_integer;
      vt_tab_csf_ctrodo_veic t_tab_csf_ctrodo_veic;

   --| informações de Proprietários do Veículo: VW_CSF_CTRODO_VEIC_PROP
   -- Nível 2
      type tab_csf_ctrodo_veic_prop is record ( cpf_cnpj_emit	      varchar2(14)
                                              , dm_ind_emit	      number(1)
                                              , dm_ind_oper           number(1)
                                              , cod_part	      varchar2(60)
                                              , cod_mod               varchar2(2)
                                              , serie                 varchar2(3)
                                              , nro_ct                number(9)
                                              , placa	              varchar2(9)
                                              , cpf                   varchar2(11)
                                              , cnpj	              varchar2(14)
                                              , rntrc                 varchar2(14)
                                              , nome                  varchar2(60)
                                              , ie                    varchar2(14)
                                              , uf                    varchar2(2)
                                              , dm_tp_prop            number(1) 
                                              );
   --
      type t_tab_csf_ctrodo_veic_prop is table of tab_csf_ctrodo_veic_prop index by binary_integer;
      vt_tab_csf_ctrodo_veic_prop t_tab_csf_ctrodo_veic_prop;

   --| informações Dados dos Veículos: VW_CSF_CTRODO_LACRE
   -- Nível 1
      type tab_csf_ctrodo_lacre is record ( cpf_cnpj_emit	varchar2(14)
                                          , dm_ind_emit	        number(1)
                                          , dm_ind_oper      	number(1)
                                          , cod_part	        varchar2(60)
                                          , cod_mod            	varchar2(2)
                                          , serie             	varchar2(3)
                                          , nro_ct            	number(9)
                                          , nro_lacre         	varchar2(20) 
                                          );
   --
      type t_tab_csf_ctrodo_lacre is table of tab_csf_ctrodo_lacre index by binary_integer;
      vt_tab_csf_ctrodo_lacre t_tab_csf_ctrodo_lacre;

   --| informações do(s) Motorista(s): VW_CSF_CTRODO_MOTO
   -- Nível 1
      type tab_csf_ctrodo_moto is record ( cpf_cnpj_emit      varchar2(14)
                                         , dm_ind_emit	      number(1)
                                         , dm_ind_oper        number(1)
                                         , cod_part	      varchar2(60)
                                         , cod_mod            varchar2(2)
                                         , serie              varchar2(3)
                                         , nro_ct             number(9)
                                         , cpf                varchar2(11)
                                         , nome               varchar2(60) 
                                         );
   --
      type t_tab_csf_ctrodo_moto is table of tab_csf_ctrodo_moto index by binary_integer;
      vt_tab_csf_ctrodo_moto t_tab_csf_ctrodo_moto;

   --| informações dos documentos referenciados CTe Outros Serviços: VW_CSF_CT_RODO_OS - Atualização CTe 3.0
   -- Nível 1
      type tab_csf_ct_rodo_os is record ( cpf_cnpj_emit	    varchar2(14)
                                        , dm_ind_emit	    number(1)
                                        , dm_ind_oper       number(1)
                                        , cod_part	    varchar2(60)
                                        , cod_mod           varchar2(2)
                                        , serie             varchar2(3)
                                        , nro_ct            number(9)
                                        , taf               number(12)
                                        , nro_reg_rest      number(25)
                                        , placa             varchar2(7)
                                        , uf_placa          varchar2(2)
                                        , cpf_cnpj_prop     varchar2(14)
                                        , taf_prop          number(12)
                                        , nro_reg_rest_prop number(25)
                                        , nome_prop         varchar2(60)
                                        , ie_prop           varchar2(14)
                                        , uf_prop           varchar2(2)
                                        , dm_tp_prop        number(1)
                                        );
   --
      type t_tab_csf_ct_rodo_os is table of tab_csf_ct_rodo_os index by binary_integer;
      vt_tab_csf_ct_rodo_os t_tab_csf_ct_rodo_os;

   --| informações do modal Aéreo: VW_CSF_CONHEC_TRANSP_AEREO
   -- Nível 1
      type tab_csf_conhec_transp_aereo is record ( cpf_cnpj_emit      varchar2(14)
                                                 , dm_ind_emit	      number(1)
                                                 , dm_ind_oper        number(1)
                                                 , cod_part	      varchar2(60)
                                                 , cod_mod            varchar2(2)
                                                 , serie              varchar2(3)
                                                 , nro_ct             number(9)
                                                 , nro_minuta	      number(9)
                                                 , nro_oper	      number(14)
                                                 , dt_prev_entr       date
                                                 , loja_ag_emiss      varchar2(20)
                                                 , cod_iata	      varchar2(14)
                                                 , trecho             varchar2(7)
                                                 , cl                 varchar2(2)
                                                 , cod_tarifa         varchar2(4)
                                                 , vl_tarifa          number(15,2) 
                                                 );
   --
      type t_tab_csf_conhec_transp_aereo is table of tab_csf_conhec_transp_aereo index by binary_integer;
      vt_tab_csf_conhec_transp_aereo t_tab_csf_conhec_transp_aereo;

   --| informações do modal Aquaviário: VW_CSF_CONHEC_TRANSP_AQUAV
   -- Nível 1
      type tab_csf_conhec_transp_aquav is record ( cpf_cnpj_emit      varchar2(14)
                                                 , dm_ind_emit	      number(1)
                                                 , dm_ind_oper        number(1)
                                                 , cod_part	      varchar2(60)
                                                 , cod_mod            varchar2(2)
                                                 , serie              varchar2(3)
                                                 , nro_ct             number(9)
                                                 , vl_prest_bc_afrmm  number(15,2)
                                                 , vl_afrmm	      number(15,2)
                                                 , nro_booking        varchar2(10)
                                                 , nro_ctrl	      varchar2(10)
                                                 , ident_navio        varchar2(60)
                                                 , nro_viagem         varchar2(10)
                                                 , dm_direcao         varchar2(1)
                                                 , port_emb	      varchar2(60)
                                                 , port_transb        varchar2(10)
                                                 , port_dest          varchar2(10)
                                                 , dm_tp_nav          number(1)
                                                 , irin	              varchar2(10) 
                                                 );
   --
      type t_tab_csf_conhec_transp_aquav is table of tab_csf_conhec_transp_aquav index by binary_integer;
      vt_tab_csf_conhec_transp_aquav t_tab_csf_conhec_transp_aquav;

   --| informações de grupo de informações dos lacres dos cointainers da qtde da carga: VW_CSF_CTAQUAV_LACRE
   -- Nível 2
      type tab_csf_ctaquav_lacre  is record ( cpf_cnpj_emit	varchar2(14)
                                            , dm_ind_emit	number(1)
                                            , dm_ind_oper      	number(1)
                                            , cod_part	        varchar2(60)
                                            , cod_mod           varchar2(2)
                                            , serie             varchar2(3)
                                            , nro_ct            number(9)
                                            , nro_lacre        	varchar2(20) 
                                            );
   --
      type t_tab_csf_ctaquav_lacre is table of tab_csf_ctaquav_lacre index by binary_integer;
      vt_tab_csf_ctaquav_lacre t_tab_csf_ctaquav_lacre;

   --| informações do modal Ferroviário: VW_CSF_CONHEC_TRANSP_FERROV
   -- Nível 1
      type tab_csf_ct_ferrov is record ( cpf_cnpj_emit	    varchar2(14)
                                       , dm_ind_emit	    number(1)
                                       , dm_ind_oper        number(1)
                                       , cod_part	    varchar2(60)
                                       , cod_mod            varchar2(2)
                                       , serie              varchar2(3)
                                       , nro_ct             number(9)
                                       , dm_tp_traf         number(1)
                                       , fluxo_ferrov       varchar2(10)
                                       , id_trem            varchar2(7)
                                       , vl_frete	    number(15,2)
                                       , dm_resp_fat        number(1)
                                       , dm_ferr_emit       number(1)
                                       , nro_chave_cte_orig varchar2(44) --Atualização CTe 3.0
                                       );
   --
      type t_tab_csf_ct_ferrov is table of tab_csf_ct_ferrov index by binary_integer;
      vt_tab_csf_ct_ferrov t_tab_csf_ct_ferrov;

   --| informações de Dados do endereço da ferrovia substituída: VW_CSF_CTFERROV_SUBST
   -- Nível 2
      type tab_csf_ctferrov_subst is record ( cpf_cnpj_emit	varchar2(14)
                                            , dm_ind_emit	number(1)
                                            , dm_ind_oper      	number(1)
                                            , cod_part	        varchar2(60)
                                            , cod_mod           varchar2(2)
                                            , serie             varchar2(3)
                                            , nro_ct            number(9)
                                            , cnpj              varchar2(14)
                                            , cod_int           varchar2(10)
                                            , ie                varchar2(14)
                                            , nome              varchar2(60)
                                            , lograd            varchar2(255)
                                            , nro              	varchar2(60)
                                            , compl            	varchar2(60)
                                            , bairro           	varchar2(60)
                                            , ibge_cidade       number(7)
                                            , descr_cidade     	varchar2(60)
                                            , cep              	number(8)
                                            , uf               	varchar2(2) 
                                            );
   --
      type t_tab_csf_ctferrov_subst is table of tab_csf_ctferrov_subst index by binary_integer;
      vt_tab_csf_ctferrov_subst t_tab_csf_ctferrov_subst;

   --| informações da DCL: VW_CSF_CTFERROV_DCL
   -- Nível 2
      type tab_csf_ctferrov_dcl is record ( cpf_cnpj_emit	varchar2(14)
                                          , dm_ind_emit	        number(1)
                                          , dm_ind_oper      	number(1)
                                          , cod_part	        varchar2(60)
                                          , cod_mod            	varchar2(2)
                                          , serie             	varchar2(3)
                                          , nro_ct            	number(9)
                                          , serie_dcl           varchar2(3)
                                          , nro_dcl            	number(20)
                                          , dt_emissao       	date
                                          , qtde_vagao       	number(5)
                                          , peso_calc_ton      	number(15,2)
                                          , vl_tarifa          	number(15,2)
                                          , vl_frete	        number(15,2)
                                          , vl_serv_aces       	number(15,2)
                                          , vl_total_serv     	number(15,2)
                                          , id_trem	        varchar2(7) 
                                          );
   --
      type t_tab_csf_ctferrov_dcl is table of tab_csf_ctferrov_dcl index by binary_integer;
      vt_tab_csf_ctferrov_dcl t_tab_csf_ctferrov_dcl;

   --| informações de detalhes dos Vagões: VW_CSF_CTFERROVDCL_DETVAG
   -- Nível 3
      type tab_csf_ctferrovdcl_detvag is record ( cpf_cnpj_emit	      varchar2(14)
                                                , dm_ind_emit	      number(1)
                                                , dm_ind_oper         number(1)
                                                , cod_part	      varchar2(60)
                                                , cod_mod             varchar2(2)
                                                , serie               varchar2(3)
                                                , nro_ct              number(9)
                                                , serie_dcl           varchar2(3)
                                                , nro_dcl             number(20)
                                                , dt_emissao          date
                                                , nro_vagao           number(8)
                                                , cap_ton	      number(5,2)
                                                , tipo_vagao          varchar2(3)
                                                , peso_real           number(5,2)
                                                , peso_bc_frete       number(5,2) 
                                                );
   --
      type t_tab_csf_ctferrovdcl_detvag is table of tab_csf_ctferrovdcl_detvag index by binary_integer;
      vt_tab_csf_ctferrovdcl_detvag t_tab_csf_ctferrovdcl_detvag;

   --| informações de Lacres dos vagões do DCL: VW_CSF_CTFERROVDCLDETVAG_LACRE
   -- Nível 4
      type tab_csf_ctferdetvag_lacre is record ( cpf_cnpj_emit	  varchar2(14)
                                               , dm_ind_emit	  number(1)
                                               , dm_ind_oper      number(1)
                                               , cod_part	  varchar2(60)
                                               , cod_mod          varchar2(2)
                                               , serie            varchar2(3)
                                               , nro_ct           number(9)
                                               , serie_dcl        varchar2(3)
                                               , nro_dcl          number(20)
                                               , dt_emissao       date
                                               , nro_vagao        number(8)
                                               , nro_lacre        varchar2(20) 
                                               );
   --
      type t_tab_csf_ctferdetvag_lacre is table of tab_csf_ctferdetvag_lacre index by binary_integer;
      vt_tab_csf_ctferdetvag_lacre t_tab_csf_ctferdetvag_lacre;

   --| informações containeres contidos no vagão com DCL: VW_CSF_CTFERROVDCLDETVAG_CONT
   -- Nível 4
      type tab_csf_ctferdetvag_cont is record ( cpf_cnpj_emit	  varchar2(14)
                                              , dm_ind_emit	  number(1)
                                              , dm_ind_oper       number(1)
                                              , cod_part	  varchar2(60)
                                              , cod_mod           varchar2(2)
                                              , serie             varchar2(3)
                                              , nro_ct            number(9)
                                              , serie_dcl         varchar2(3)
                                              , nro_dcl           number(20)
                                              , dt_emissao        date
                                              , nro_vagao         number(8)
                                              , nro_cont	  number(20)
                                              , dt_prev           date 
                                              );
   --
      type t_tab_csf_ctferdetvag_cont is table of tab_csf_ctferdetvag_cont index by binary_integer;
      vt_tab_csf_ctferdetvag_cont t_tab_csf_ctferdetvag_cont;

   --| informações do modal Dutoviário: VW_CSF_CONHEC_TRANSP_DUTO
   -- Nível 1
      type tab_csf_conhec_transp_duto is record ( cpf_cnpj_emit	    varchar2(14)
                                                , dm_ind_emit	    number(1)
                                                , dm_ind_oper       number(1)
                                                , cod_part	    varchar2(60)
                                                , cod_mod           varchar2(2)
                                                , serie             varchar2(3)
                                                , nro_ct            number(9)
                                                , vl_tarifa         number(15,6)
                                                , dt_ini            date
                                                , dt_fin            date 
                                                );
   --
      type t_tab_csf_conhec_transp_duto is table of tab_csf_conhec_transp_duto index by binary_integer;
      vt_tab_csf_conhec_transp_duto t_tab_csf_conhec_transp_duto;

   --| informações de transporte de produtos classificados pela ONU como perigosos: VW_CSF_CONHEC_TRANSP_PERI
   -- Nível 1
      type tab_csf_conhec_transp_peri is record ( cpf_cnpj_emit	   varchar2(14)
                                                , dm_ind_emit	   number(1)
                                                , dm_ind_oper      number(1)
                                                , cod_part	   varchar2(60)
                                                , cod_mod          varchar2(2)
                                                , serie            varchar2(3)
                                                , nro_ct           number(9)
                                                , nro_onu          varchar2(4)
                                                , nome_aprop       varchar2(150)
                                                , classe_risco     varchar2(40)
                                                , grupo_emb        varchar2(6)
                                                , qtde_total_prod  varchar2(20)
                                                , qtde_vol_tipo    varchar2(60)
                                                , ponto_fulgor     varchar2(6) 
                                                );
   --
      type t_tab_csf_conhec_transp_peri is table of tab_csf_conhec_transp_peri index by binary_integer;
      vt_tab_csf_conhec_transp_peri t_tab_csf_conhec_transp_peri;

   --| informações dos veículos transportados: VW_CSF_CONHEC_TRANSP_VEIC
   -- Nível 1
      type tab_csf_conhec_transp_veic is record ( cpf_cnpj_emit	        varchar2(14)
                                                , dm_ind_emit	        number(1)
                                                , dm_ind_oper       	number(1)
                                                , cod_part	        varchar2(60)
                                                , cod_mod            	varchar2(2)
                                                , serie             	varchar2(3)
                                                , nro_ct            	number(9)
                                                , chassi            	varchar2(17)
                                                , cod_cod          	varchar2(4)
                                                , descr_cor        	varchar2(40)
                                                , cod_modelo       	varchar2(6)
                                                , vl_unit	        number(15,2)
                                                , vl_frete	        number(15,2)
                                                );
   --
      type t_tab_csf_conhec_transp_veic is table of tab_csf_conhec_transp_veic index by binary_integer;
      vt_tab_csf_conhec_transp_veic t_tab_csf_conhec_transp_veic;

   --| informações do CT-e de substituição: VW_CSF_CONHEC_TRANSP_SUBST
   -- Nível 1
      type tab_csf_conhec_transp_subst is record ( cpf_cnpj_emit      varchar2(14)
                                                 , dm_ind_emit	      number(1)
                                                 , dm_ind_oper        number(1)
                                                 , cod_part	      varchar2(60)
                                                 , cod_mod            varchar2(2)
                                                 , serie              varchar2(3)
                                                 , nro_ct             number(9)
                                                 , nro_chave_cte_sub  varchar2(44)
                                                 , nro_chave_nfe_tom  varchar2(44)
                                                 , cnpj	              varchar2(14)
                                                 , cod_mod_sub        varchar2(2)
                                                 , serie_sub          varchar2(3)
                                                 , subserie           varchar2(3)
                                                 , nro                number(6)
                                                 , vl_doc_fiscal      number(15,2)
                                                 , dt_emissao         date
                                                 , nro_chave_cte_tom  varchar2(44)
                                                 , nro_chave_cte_anul varchar2(44) 
                                                 , dm_ind_alt_toma    number(1) --Atualização CTe 3.0
                                                 , cpf                varchar2(11)
                                                 );
   --
      type t_tab_csf_conhec_transp_subst is table of tab_csf_conhec_transp_subst index by binary_integer;
      vt_tab_csf_conhec_transp_subst t_tab_csf_conhec_transp_subst;

   --|informações de Detalhamento do CT-e complementado: VW_CSF_CONHEC_TRANSP_COMPLTADO
   -- Nível 1
      type tab_csf_ct_compltado is record ( cpf_cnpj_emit	varchar2(14)
                                          , dm_ind_emit	        number(1)
                                          , dm_ind_oper      	number(1)
                                          , cod_part	        varchar2(60)
                                          , cod_mod            	varchar2(2)
                                          , serie             	varchar2(3)
                                          , nro_ct            	number(9)
                                          , nro_chave_cte_comp	varchar2(44)
                                          , vl_total_prest    	number(15,2)
                                          , inf_ad_fiscal     	varchar2(1000) 
                                          );
   --
      type t_tab_csf_ct_compltado is table of tab_csf_ct_compltado index by binary_integer;
      vt_tab_csf_ct_compltado t_tab_csf_ct_compltado;

   --|informações de Componentes do Valor da Prestação de complemento: VW_CSF_CTCOMPLTADO_COMP
   -- Nível 2
      type tab_csf_ctcompltado_comp is record ( cpf_cnpj_emit	        varchar2(14)
                                              , dm_ind_emit	        number(1)
                                              , dm_ind_oper      	number(1)
                                              , cod_part	        varchar2(60)
                                              , cod_mod            	varchar2(2)
                                              , serie             	varchar2(3)
                                              , nro_ct            	number(9)
                                              , nro_chave_cte_comp	varchar2(44)
                                              , nome              	varchar2(15)
                                              , valor             	number(15,2) 
                                              );
   --
      type t_tab_csf_ctcompltado_comp is table of tab_csf_ctcompltado_comp index by binary_integer;
      vt_tab_csf_ctcompltado_comp t_tab_csf_ctcompltado_comp;

   --|informações relativas aos Impostos de complemento: VW_CSF_CTCOMPLTADO_IMP
   -- Nível 2
      type tab_csf_ctcompltado_imp is record ( cpf_cnpj_emit	  varchar2(14)
                                             , dm_ind_emit	  number(1)
                                             , dm_ind_oper        number(1)
                                             , cod_part	          varchar2(60)
                                             , cod_mod            varchar2(2)
                                             , serie              varchar2(3)
                                             , nro_ct             number(9)
                                             , nro_chave_cte_comp varchar2(44)
                                             , cod_imposto        number(2)
                                             , cod_st	          varchar2(2)
                                             , vl_base_calc       number(15,2)
                                             , aliq_apli          number(5,2)
                                             , vl_imp_trib        number(15,2)
                                             , perc_reduc         number(5,2)
                                             , vl_cred	          number(15,2)
                                             , dm_inf_imp         number(1) 
                                             );
   --
      type t_tab_csf_ctcompltado_imp is table of tab_csf_ctcompltado_imp index by binary_integer;
      vt_tab_csf_ctcompltado_imp t_tab_csf_ctcompltado_imp;

   --|informações de Detalhamento do CT-e do tipo Anulação de Valores: VW_CSF_CONHEC_TRANSP_ANUL
   -- Nível 1
      type tab_csf_conhec_transp_anul is record ( cpf_cnpj_emit	        varchar2(14)
                                                , dm_ind_emit	        number(1)
                                                , dm_ind_oper        	number(1)
                                                , cod_part	        varchar2(60)
                                                , cod_mod            	varchar2(2)
                                                , serie             	varchar2(3)
                                                , nro_ct            	number(9)
                                                , nro_chave_cte_anul	varchar2(44)
                                                , dt_emissao       	date 
                                                );
   --
      type t_tab_csf_conhec_transp_anul is table of tab_csf_conhec_transp_anul index by binary_integer;
      vt_tab_csf_conhec_transp_anul t_tab_csf_conhec_transp_anul;

   --|informações de Cancelamento: VW_CSF_CONHEC_TRANSP_CANC
   -- Nível 1
      type tab_csf_conhec_transp_canc is record ( cpf_cnpj_emit	   varchar2(14)
                                                , dm_ind_emit	   number(1)
                                                , dm_ind_oper      number(1)
                                                , cod_part	   varchar2(60)
                                                , cod_mod          varchar2(2)
                                                , serie            varchar2(3)
                                                , nro_ct           number(9)
                                                , dt_canc          date
                                                , justif           varchar2(255) 
                                                );
   --
      type t_tab_csf_conhec_transp_canc is table of tab_csf_conhec_transp_canc index by binary_integer;
      vt_tab_csf_conhec_transp_canc t_tab_csf_conhec_transp_canc;

   --|informações de Cancelamento: VW_CSF_CONHEC_TRANSP_EMAIL

      type tab_csf_ct_email is record ( cpf_cnpj_emit	varchar2(14)
                                      , dm_ind_emit	number(1)
                                      , dm_ind_oper     number(1)
                                      , cod_part	varchar2(60)
                                      , cod_mod         varchar2(2)
                                      , serie           varchar2(3)
                                      , nro_ct          number(9)
                                      , email           varchar2(4000)
                                      , dm_tipo_anexo   number(1)
                                      );
   --
      type t_tab_csf_ct_email is table of tab_csf_ct_email index by binary_integer;
      vt_tab_csf_ct_email t_tab_csf_ct_email;

   --|informações de Cancelamento: VW_CSF_CONHEC_TRANSP_IMPR

      type tab_csf_ct_impr is record ( cpf_cnpj_emit	varchar2(14)
                                     , dm_ind_emit	number(1)
                                     , dm_ind_oper      number(1)
                                     , cod_part	        varchar2(60)
                                     , cod_mod          varchar2(2)
                                     , serie            varchar2(3)
                                     , nro_ct           number(9)
                                     , dm_tipo_impr     number(1)
                                     , descr_impr       varchar2(255)
                                     );
   --
      type t_tab_csf_ct_impr is table of tab_csf_ct_impr index by binary_integer;
      vt_tab_csf_ct_impr t_tab_csf_ct_impr;
   
   --| informações de Conhecimentos de Transportes não integrados: VW_CSF_CONHEC_TRANSP_FF

      type tab_csf_conhec_transp_ff is record ( cpf_cnpj_emit	    varchar2(14)
                                              , dm_ind_emit	    number(1)
                                              , dm_ind_oper	    number(1)
                                              , cod_part	    varchar2(60)
                                              , cod_mod	            varchar2(2)
                                              , serie	            varchar2(3)
                                              , nro_ct	            number(9)
                                              , atributo            varchar2(30)
                                              , valor               varchar2(255) 
                                              );
   --
      type t_tab_csf_conhec_transp_ff is table of tab_csf_conhec_transp_ff index by binary_integer;
      vt_tab_csf_conhec_transp_ff t_tab_csf_conhec_transp_ff;

   --|informações de Cancelamento: VW_CSF_CONHEC_TRANSP_CANC_FF

      type tab_conhec_transp_canc_ff is record ( cpf_cnpj_emit	   varchar2(14)
                                               , dm_ind_emit	   number(1)
                                               , dm_ind_oper       number(1)
                                               , cod_part	   varchar2(60)
                                               , cod_mod           varchar2(2)
                                               , serie             varchar2(3)
                                               , nro_ct            number(9)
                                               , atributo          varchar2(30)
                                               , valor             varchar2(255)
                                               );
   --
      type t_tab_conhec_transp_canc_ff is table of tab_conhec_transp_canc_ff index by binary_integer;
      vt_tab_conhec_transp_canc_ff t_tab_conhec_transp_canc_ff;
--
-- ========================================================================================================================= --
--
--| informações relativas aos Impostos: VW_CSF_CONHEC_TRANSP_IMP_OUT
-- Nível 1
   type tab_csf_conhec_transp_impout is record ( cpf_cnpj_emit      varchar2(14)
                                               , dm_ind_emit        number(1)
                                               , dm_ind_oper        number(1)
                                               , cod_part	    varchar2(60)
                                               , cod_mod	    varchar2(2)
                                               , serie	            varchar2(3)
                                               , nro_ct	            number(9)
                                               , cod_imposto	    number(2)
                                               , dm_tipo	    number(1)
                                               , cod_st	            varchar2(2)
                                               , vl_item	    number(13,2)
                                               , vl_base_calc	    number(13,2)
                                               , aliq_apli	    number(3,2)
                                               , vl_imp_trib	    number(13,2)
                                               , vl_deducao	    number(13,2)
                                               , dm_ind_nat_frt	    number(1)
                                               , cod_tiporetimp	    varchar2(10)
                                               , cod_rec_tiporetimp varchar2(2)
                                               , cod_nat_rec_pc	    number(3)
                                               , cod_bc_cred_pc	    varchar2(2)
                                               , cod_cta	    varchar2(60) );
   --
   type t_tab_csf_conhec_transp_impout is table of tab_csf_conhec_transp_impout index by binary_integer;
   vt_tab_csf_ct_imp_out t_tab_csf_conhec_transp_impout;
--
-- ========================================================================================================================= --
--
   gv_sql                     varchar2(4000) := null;
   gv_where                   varchar2(4000) := null;
   gn_rel_part                number := 0;
   gd_dt_ini_integr           date := null;
   gv_resumo                  log_generico_ct.resumo%type := null;
   gv_cabec_ct                varchar2(4000) := null;
   gn_multorg_id              mult_org.id%type;
   gv_cd_obj                  obj_integr.cd%type := '4';
   gn_empresaintegrbanco_id   empresa_integr_banco.id%type;

-------------------------------------------------------------------------------------------------------
   
   gv_aspas           char(1) := null;
   gv_formato_dt_erp  empresa.formato_dt_erp%type := 'dd/mm/rrrr';
   gv_owner_obj       empresa.owner_obj%type;
   gv_nome_dblink     empresa.nome_dblink%type := null;
   gv_sist_orig       sist_orig.sigla%type := null;
   gn_dm_ind_emit     conhec_transp.dm_ind_emit%type := null;
   gv_formato_data    param_global_csf.valor%type := null;

-------------------------------------------------------------------------------------------------------
--| Procedimento que inicia a integração dos conhecimentos de transporte
procedure pkb_integracao ( en_empresa_id  in  empresa.id%type
                         , ed_dt_ini      in  date
                         , ed_dt_fin      in  date );
--
-------------------------------------------------------------------------------------------------------
--| Procedimento que inicia a integração de Conhecimento de Transporte Emissão através do Mult-Org.
--| Esse processo estará sendo executado por JOB SCHEDULER, especifícamente para Ambiente Amazon.
--| A rotina deverá executar o mesmo procedimento da rotina pkb_integracao, porém com a identificação da mult-org.
procedure pkb_integr_multorg ( en_multorg_id in mult_org.id%type );

-------------------------------------------------------------------------------------------------------
--| Procedimento que inicia a integração de Conhecimentos de Transporte por empresa e período
procedure pkb_integr_periodo ( en_multorg_id  in mult_org.id%type
                             , ed_dt_ini      in  date
                             , ed_dt_fin      in  date );

-------------------------------------------------------------------------------------------------------
--| Procedimento Gera o Retorno para o ERP
procedure pkb_gera_retorno ( ev_sist_orig in varchar2 default null );

-------------------------------------------------------------------------------------------------------

-- Para Debugar -- 
--procedure pkb_ler_Conhec_Transp ( ev_cpf_cnpj_emit in varchar2 );

end pk_integr_view_ct;
/
