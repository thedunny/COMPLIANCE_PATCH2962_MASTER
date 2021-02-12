create or replace package csf_own.pk_csf_api_ct is

----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Especificação do pacote da API do Conhecimento de Transporte
----------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Em 28/01/2021   - Karina de Paula
-- Redmine #75607  - Ajustes na rotina de integração do CTe
-- Rotina Alterada - pkb_integr_conhec_transp => Retirado o delete da log_generico_ct e incluído na pkb_excluir_dados_ct. Alterado o tipo de log para INFORMACAO
--                   onde está como ERRO_DE_VALIDACAO sem gerar contador de erro
--                   Retirado um tratamento errado de dm_st_proc e dm_legado
--                 - pkb_excluir_dados_ct     => Incluído o delete da log_generico_ct
-- Liberado        - Release_2.9.7, Patch_2.9.6.2 e Patch_2.9.5.5
--
-- Em 19/01/2021   - Karina de Paula
-- Redmine #75107  - Tabelas que envolvem o processo de CCE conhec_transp_CCE ou evento_cte_cce/evento_cte e também r_loteintws_ct
-- Rotina Criada   - gt_row_conhec_transp_cce / pkb_integr_conhec_transp_cce
--                 - pkb_excluir_dados_ct => Incluido delete da tabela conhec_transp_cce
-- Liberado        - Patch_2.9.6.1
--
-- Em 14/01/2021   - Karina de Paula
-- Redmine #74902/75152/75102
-- Liberado        - Release_2.9.6 e Patch_2.9.6.1
--
-- Em 08/01/2020   - Karina de Paula
-- Redmine #74868  - Erro de Validação: Dominio conhec_transp.dm_st_integra
--          74768  - Liberar de validação CTE legado
--         #75061  - Erro ainda ocorre. 
-- Rotina Alterada - pkb_integr_evento_cte e pkb_integr_conhec_transp => Incluido valor do dominio dm_st_integra "10"
--                 - Criada a variavel global gn_dm_ind_emit e gn_dm_legado para receber o valor da pkb_busca_dm_ind_emit
--                 - Incluida a verificacao se integracao é de emissão própria e não legado para executar as validações
-- Liberado        - Release_2.9.6
--
-- Em 18/12/2020   - Karina de Paula
-- Redmine #74308  - Teste de Integração CT-e
-- Rotina Alterada - pkb_integr_conhec_transp => Alterada a verificacao do dm_legado para ser igual a 0, para criacao de uma nova chave
-- Liberado        - Release_2.9.6
--
-- Em 16/11/2020   - Joao Carlos - 2.9.4-5 / 2.9.5-2 / 2.9.6
-- Redmine #73332  - Correção na condição do select de and tc.cd_compat = ln.csftipolog_id para and tc.id = ln.csftipolog_id
-- Rotina Alterada - fkg_ver_erro_log_generico
--
--
-- Em 11/11/2020   - João Carlos - 2.9.4-5 / 2.9.5-2 / 2.9.6
-- Redmine #66443  - Inclusão da variável en_referencia_id na chamada da pkb_log_generico_ct - Ticket #66443
-- Rotina Alterada - fkg_integr_lote_cte, pkb_reenvia_lote_cte, PKB_AJUSTA_LOTE_CTE, pkb_excluir_lote_sem_cte, pkb_gera_lote_cte,
--                 - fkg_ct_nao_inutiliza, pkb_atual_cte_inut, pkb_relac_cte_cons_sit, pkb_atual_sit_docto
--
-- Em 14/09/2020   - Karina de Paula
-- Redmine #67105  - Criar processo de validação da CT_CONS_SIT
-- Rotina Alterada - pkb_integr_ct_cons_sit => Exclusão dessa rotina pq foi substituída pela pk_csf_api_cons_sit.pkb_integr_ct_cons_sit
--                 - pkb_excluir_dados_ct   => Retirado o update na ct_cons_sit e incluída a chamada da pk_csf_api_cons_sit.pkb_ins_atu_ct_cons_sit
--                 - pkb_relac_cte_cons_sit => Retirado o update na ct_cons_sit e incluída a chamada da pk_csf_api_cons_sit.pkb_ins_atu_ct_cons_sit
--                 - pkb_cons_cte_terc      => Retirado o insert na ct_cons_sit e incluída a chamada da pk_csf_api_cons_sit.pkb_ins_atu_ct_cons_sit
-- Liberado        - Release_2.9.5
--
-- Em 19/08/2020   - Luis Marques - 2.9.3-5 / 2.9.4-2 / 2.9.5
-- Redmine #70694  - colocar a tabela CONHEC_TRANSP_IMP_RET na rotina de exclusão
-- Rotina Alterada - pkb_excluir_dados_ct - Incluir tabela "CONHEC_TRANSP_IMP_RET" na rotina de exclusão dos CTE(s).
--
-- Em 23/07/2020   - Luis Marques - 2.9.4-2 / 2.9.5
-- Redmine #69796  - Divergência entre apuração de ICMS e livro de saídas
-- Rotina Alterada - pkb_integr_conhec_transp_imp - Colocado log de alerta para conhecimento de transporte com CST
--                   90 Outras e com valores nos campos de triburtação de ICMS Base, aliquota e valor do imposto,
--                   pode ocorrer caso parametrização de CST não tributados estiver ativa erro no Livro de Saída.
--
-- Em 05/12/2019 - Allan Magrini
-- Redmine #61656 - Regra de validação D100 campo 11
-- Criada regra de validação onde o campo CONHEC_TRANSP.DT_HR_EMISSAO>= 01/01/2019 e CONHEC_TRANSP.MODFISCAL_ID seja igual a 07, 09, 10, 11, 26 ou 27 
-- sera gerado erro de validação informando que o modelo selecionado não está mais vigente na data de emissão informada.        
-- RotinaS Criada: pkb_valida_ct_d100
--
-- Em 27/11/2019 - Luiz Armando / Luis Marques
-- Redmine #61768 - Retorno de XML CT-e e NF-e em Duplicidade
-- Rotina Alterada: PKB_RELAC_CTE_CONS_SIT - Ajustado para verificar o DM_ST_PROC do documento antes de setar DM_RET_CT_ERP 
--                  que inicia nova leitura na SEFAZ e retorna ao ERP.
--
-- Em 25/11/2019   - Allan Magrini
-- Redmine #58461  - Validação CT-e
-- Retirada a validação da forma de emissão fase 19
-- Rotina Alterada - PKB_VALIDA_CHAVE_ACESSO
--
-- Em 12/11/2019   - Marcos Ferreira
-- Redmine #60533  - Erro de validação CTe Terceiro - Forma de emissão FS-DA (FRONERI)
-- Rotina Alterada - pkb_integr_conhec_transp - Incluído associação da variável gt_row_conhec_transp
--                   pkb_valida_chave_acesso - Incluído clausula para validar forma de emissão somente para ctes de emissão própria
--
-- Em 20/09/2019   - Karina de Paula
-- Redmine #53132  - Atualizar Campos Chaves da View VW_CSF_CT_INF_OUTRO
-- Rotina Alterada - pkb_integr_r_outro_infut e pkb_integr_r_outro_infuc => Incluido o campo NRO_DOCTO para ser usado como chave na chamada da funcao pk_csf_ct.fkg_ct_inf_outro_id
--
-- Em 18/09/2019 - Luis Marques
-- Redmine #58940 - Validação incorreta do CTe
-- Rotina Alterada: pkb_integr_ct_part_icms - Ajustado para o campo "perc_icms_inter_part" Percentual provisório de 
--                  partilha entre os estados aceitar nulo ou não ser informado.
--
-- Em 09/09/2019 - Luis Marques
-- Redmine #58593 - Diversas consultas de chave de CTE duplicadas
-- Rotinas Alteradas: PKB_CONS_CTE_TERC - justado para a validação de inclusão de registros a consultar a Chave do
--                    CTE para incluir até 7 vezes  e se não existe registro para o dia.
--                    pkb_relac_cte_cons_sit - tratado o DM_ST_PROC do conhecimento caso não seja possivel a leitura
--                    na sefaz, colocado log de informação.
--
-- Em 21/08/2019 - Luis Marques
-- Redmine #57141 - Validação nota fiscal serviços
-- Rotinas Alteradas: pkb_integr_ctimpout_pis, pkb_integr_ctimpout_cofins - ajustado para mostrar Informação Geral ao inves de
--                    Avisos Genéricos
--
-- Em 08/08/2019 - Luis Marques
-- Redmine #57204 - Falha na consulta automática chave de acesso CTe (TUPPERWARE)
-- Rotina Alterada: PKB_CONS_CTE_TERC - Ajustado para se no dia já foi atingido sete leituras antes de 23:59 inserir mais
--                  um registro para oitava leitura para verificação de possivel cancelamento do conhecimento.
--
-- Em 25/07/2019 - Eduardo Linden
-- Redmine #56442 - CTE - Mudança na obtenção do Valor de operação 
-- Solicitação:  , o valor de operação (ct_reg_anal.vl_opr) irá receber o valor do campo conhec_transp_vlprest.VL_DOCTO_FISCAL, 
-- ao invés da soma do campo conhec_transp_imp.vl_base_cal
-- Rotina alterada : pkb_valida_ct_d190
--
-- Em 21/07/2019 - Luis Marques
-- Redmine #56565 - feed - Mensagem de ADVERTENCIA está deixando documento com ERRO DE VALIDAÇÂO
-- Rotinas alteradas: pkb_integr_conhec_transp, pkb_integr_ctimpout_pis e pkb_integr_ctimpout_cofins
--                    Alterado para colocar verificação de falta de Codigo de base de calculo de PIS/COFINS
--                    como advertencia e não marcar o documento com erro de validação se for só esse log.
-- Function nova: fkg_verif_erro_log_generico
--
-- Em 12/07/2019 - Luis Marques
-- Redmine #56155 - feed - Validação de chave de CT-e
-- 
-- Em 09/07/2019 e 12/07/2019 - Luis Marques
-- Redmine #27836 Validação PIS e COFINS - Gerar log de advertência durante integração dos documentos
-- Rotinas alteradas: Incluido verificação de advertencia da falta de Codigo da base de calculo do credito
--                    se existir base e aliquota de imposto for do tipo imposto (0) e cliente juridico
--                    pkb_integr_ctimpout_pis e pkb_integr_ctimpout_cofins
-- Function nova: fkg_dmindemit_conhectransp
--
-- Em 05/07/2018 - Luis Marques
-- Redmine #56042 - Parou de validar a chave de cte de terceiro
-- Rotina Alterada: pkb_integr_conhec_transp na chamada da fkg_ret_valid_integr incluido campos
--                  dm_forma_emiss para validação de forma de emissão <> 8 8 e conhecimento 
--                  não de terceiros, DM_IND_EMIT = 0 e legado (1,2,3,4), DM_LEGADO in (1,2,3,4)
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Em 07/06/2019 - Luiz Armando Azoni
-- Redmine #55207 - Erro na validação CTe Terceiro
-- Rotina Alterada:  pkb_relac_cte_cons_sit
-- Motivo: Na validação quando o campo rec.dm_situacao=5 e o campo rec.cstat=null, a variável vn_dm_st_proc ficava nula gerando erro no update da tabela conhec_transp
--				 Foi adicionado uma tratativa para corrigir esta condição e no update da tabela conhec_transp foi adicionado um tratamente de exceção, caso ocorra erro no update, 
--			       será gerado um log e o processo continuará normalmente.
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Em 31/05/2019 - Karina de Paula
-- Redmine #54663 - Validação de CTe Complementar com Valor 0
-- Rotina Alterada: pkb_integr_ct_vlprest => Incluída a verificação do pk_csf_api_ct.gt_row_conhec_transp.dm_tp_cte <> 1 para validar os campos vl_prest_serv e vl_docto_fiscal
--
-- Em 31/05/2019 - Karina de Paula
-- Redmine #53834 - Erro de validação CTe Terceiro - Forma de emissão SVC-SP (LCA)
-- Rotina Alterada: pkb_integr_conhec_transp => Incluída a chamada da fkg_ret_valid_integr =. Function retorna se o dado de integração deve ser validado ou não
--
-- Em 23/05/2019 - Karina de Paula
-- Redmine #54711 - CT-e não exclui.
-- Rotina Alterada: pkb_excluir_dados_ct => Foi descomentada a linha de delete da tabela r_loteintws_ct. Essa linha foi comentada em agosto/2017 sem explicação.
-- Porém tb foi criado o parâmetro de entrada "en_excl_rloteintwsct" para verificar se irá excluir o vínculo com a "r_loteintws_ct".
-- Foi verificado q esse processo tb é chamado na integração do CTE, por isso que o delete estava comentado. No caso de integração do CTE não podemos excluir o
-- vínculo do CTE com o lote de integração. Para solucionar o problema será criado um novo parâmetro de entrada na chamada do processo pk_csf_api_ct.pkb_excluir_dados_ct
-- que identifique se a rotina pode excluir os dados da r_loteintws_ct ou não.
-- Incluída a verificação pk_csf_ct.fkg_cte_nao_integrar
--
-- === AS ALTERAÇÕES ABAIXO ESTÃO NA ORDEM CRESCENTE USADA ANTERIORMENTE ================================================================================= --
--
-- Em 14/09/2012 por Rogério Silva.
-- Alteração no processo de validação do sufixo da placa do Veículo no Modal Rodoviário, conforme
-- a ficha 63038.
--
-- Em: 19/09/2012 por Rogério Silva.
-- Foi adicionado o campo "NRO_CARREG" no processo de validação e integração de conhecimento de transporte.
--
-- Em 28/11/2012 - Angela Inês.
-- Ficha HD 64674 - Melhoria em validações, não permitir valores zerados para os campos:
-- Rotina: pkb_integr_ct_vlprest -> conhec_transp_vlprest.vl_prest_serv e conhec_transp_vlprest.vl_docto_fiscal.
--
-- Em 03/01/2013 - Angela Inês.
-- Ficha HD 65123 - Implementar no processo de inutilização de CTe, a criação dos dados para recuperar os dados na tela de monitoramento e retornar para o ERP.
-- Rotina: pkb_atual_cte_inut.
--
-- Em 06/08/2013 - Angela Inês.
-- Redmine #451 - Validação de informações Fiscais - Ficha HD 66733.
-- Correção nas rotinas chamadas pela pkb_consistem_ct, eliminando as referências das variáveis globais, pois essa rotina será chamada de outros processos.
-- Rotina: pkb_consistem_ct e todas as chamadas dentro dessa rotina.
-- Inclusão da função de validação dos conhecimentos de transporte, através dos processos de sped fiscal, contribuições e gias.
-- Rotina: fkg_valida_ct.
--
-- Em 05/09/2013 - Angela Inês.
-- Alterar a rotina que valida os processos considerando somente conhecimentos de transporte que sejam de emissão própria (conhec_transp;dm_ind_emit = 0).
-- Rotina: fkg_valida_ct.
--
-- Em 12/09/2013 - Rogério Silva.
-- Atividade #600 -> Adicionado os procedimentos  pkb_integr_ct_aquav_cont_nf e pkb_integr_ct_aquav_cont_nfe e adicionado os campos DT_INI e DT_FIM na
-- integração do procedimento pkb_integr_conhec_transp_duto.
--
-- Em 19/09/2013 - Angela Inês.
-- Redmine #680 - Função de validação dos documentos fiscais.
-- Invalidar o conhecimento de transporte no processo de consistência dos dados, se o objeto de referência for CONHEC_TRANSP.
-- Rotina: pkb_consistem_ct.
--
-- Em 30/06/2014 - Angela Inês.
-- Redmine #3207 - Suporte - Leandro/GPA. Verificar trace enviado por email - Integração de Conhecimentos de Transportes.
-- 1) Verificar a possibilidade de recuperar o valor da função pk_csf.fkg_dm_tp_cte uma única vez dentro de cada rotina api de ct.
--    A função é chamada várias vezes dentro da mesma rotina (pkb_valida...).
--    Rotinas em pk_csf_api_ct: pk_csf.fkg_dm_tp_cte.
-- 2) Verificar a possibilidade de recuperar o valor da função pk_csf.fkg_dm_modal uma única vez dentro de cada rotina api de ct.
--    A função é chamada várias vezes dentro da mesma rotina (pkb_valida...).
--    Rotinas em pk_csf_api_ct: pk_csf.fkg_dm_modal.
--
-- Em 18/11/2014 - Rogério Silva
-- Redmine #5018 - Alterar os processos de integração NFe, CTe e NFSe (emissão própria)
-- Rotina: pkb_consistem_ct
--
-- Em 05/01/2015 - Angela Inês.
-- Redmine #5616 - Adequação dos objetos que utilizam dos novos conceitos de Mult-Org.
--
-- Em 13/01/2015 - Rogério Silva
-- Redmine #5827 - Retirar a obrigatoriedade de preenchimento da coluna "UF" da tabela "CTRODO_VEIC_PROP"
-- Rotina: pkb_integr_ctrodo_veic_prop
--
-- Em 27/01/2015 - Rogério Silva
-- Redmine #5696 - Indicação do parâmetro de integração
--
-- Em 01/06/2015 - Rogério Silva
-- Redmine #8230 - Processo de Registro de Log em Packages - Conhecimento de Transporte
--
-- Em 13/08/2015 - Angela Inês.
-- Redmine #10117 - Escrituração de documentos fiscais - Processos.
-- Inclusão do novo conceito de recuperação de data dos documentos fiscais para retorno dos registros.
--
-- Em 05/02/2016 - Rogério Silva
-- Redmine #13079 - Registro do Número do Lote de Integração Web-Service nos logs de validação
--
-- Em 14/04/2016 - Fábio Tavares
-- Redmine #16793 - Melhoria nas mensagens dos processos flex-field.
--
-- Em 27/10/2017 - Marcelo Ono
-- Redmine #35937 - Inclusão do parâmetro de entrada empresa_id, para que seja filtrado a empresa do documento na execução das rotinas programáveis.
-- Rotina: pkb_consistem_ct.
--
-- Em 07/11/2017 - Leandro Savenhago
-- Redmine #33992 - Integração de CTe cuja emissão é propria legado através da Open Interface
-- Rotina: pkb_integr_conhec_transp.
--
-- Em 29/12/2017 - Marcelo Ono
-- Redmine #36865 - Atualização no processo de validação e exclusão do Conhecimento de Transporte para Emissão Própria - CTe 3.00.
-- Rotinas: pkb_integr_conhec_transp, pkb_integr_conhec_transp_imp, pkb_integr_ct_part_icms, pkb_integr_ct_infcarga, pkb_integr_conhec_transp_subst,
--          pkb_integr_ct_inf_vinc_mult, pkb_integr_ct_transp_percurso, pkb_integr_ct_doc_ref_os, pkb_integr_ct_rodo_os, pkb_integr_ct_aereo_peri,
--          pkb_integr_ct_aquav_cont, pkb_integr_ct_aquav_cont_lacre, pkb_integr_ct_aquav_cont_nf, pkb_integr_ct_aquav_cont_nfe, pkb_integr_ct_ferrov,
--          pkb_integr_evento_cte_gtv, pkb_integr_evento_cte_gtv_esp, pkb_integr_evento_cte_desac, pkb_excluir_dados_ct, pkb_valida_chave_acesso
--          pkb_integr_CTChave_Refer, pkb_gera_lote_cte, pkb_atual_cte_inut, pkb_gera_lote_cte e fkg_integr_lote_cte.
--
-- Em 23/01/2018 - Karina de Paulas
-- Redmine #38656 - Processos de integração de Conhecimento de Transporte - Modelo D100.
-- Incluido somente explicacao da existencia de 2 cursores (c_conhec_transp e c_conhec_transp_os) para tratar o mod fiscal 57 e 67
--
-- Em 02/02/2018 - Angela Inês.
-- Redmine #39080 - Validação de Ambiente de Conhecimento de Transporte Emissão por Job Scheduller.
-- Rotinas: pkb_gera_lote_cte, pkb_consit_inutilizacao, pkb_atual_cte_inut, pkb_ajusta_lote_cte, pkb_relac_cte_cons_sit e pkb_atual_sit_docto.
--
-- Em 19/03/2018 - Karina de Paula
-- Redmine #39208 - Karina de Paula - Rotina (pkb_valida_ct_d190) criada para incluir cálculo do ICMS na tabela ct_reg_anal
--
-- Em 06/04/2018 - Angela Inês.
-- Redmine #41482 - Correção no retorno do CTE através de consulta.
-- Considerar o CTe de armazenamento (Conhec_Transp.dm_arm_cte_terc=1), para atualização do ID e do DM_ST_PROC, quando o mesmo é consultado pela tabela CT_CONS_SIT.
-- Rotina: pkb_relac_cte_cons_sit.
--
-- Em 13/04/2018 - Karina de Paula
-- Redmine #41660 - Alteração processo de Integração de Conhecimento de Transporte, adicionando Integração de PIS e COFINS.
-- Criada a variável global: gt_row_conhec_transp_imp_out
-- Criada a rotina: pkb_integr_ctimpout_pis
-- Criada a rotina: pkb_integr_ctimpout_cofins
-- Objetos Criados: gt_row_ct_compdoc_pis / gt_row_ct_compdoc_cofins
--
-- Em 23/04/2018 - Angela Inês.
-- Redmine #42053 - Alterar o Método para consultar CTe de Terceiro.
-- 1) Ao recuperar os CTEs de terceiro para consulta, considerar o período de até 8 dias e não mais 7 dias, anteriores ao dia atual.
-- 2) Alterar a data utilizada para recuperar os CTEs de terceiro no período de 8 dias (item 1), de DT_HR_EMISSAO para DT_AUT_SEFAZ.
-- 3) Como melhoria técnica utilizar variáveis para data inicial e final, considerando a inicial como sendo o sysdate e hora 00:00h, e a final como sendo o
-- sysdate menos(-) 8(oito) dias e hora 23:59h. Com isso, não utilizar a data truncando a informação de hora, e utilizar between com as datas inicial e final.
-- Rotina: pkb_cons_cte_terc.
--
-- Em 30/04/2018 - Angela Inês.
-- Redmine #42339 - Alteração na Regra de Validação de CST para Impostos PIS e COFINS - CTE.
-- Para os Impostos PIS e COFINS considerar os CSTs entre 50 e 56, 60 e 66, 70 e 75, 98 e 99, se o CTE for de Aquisição (conhec_trans.dm_ind_oper=0).
-- Para os Impostos PIS e COFINS considerar os CSTs 01, 02, 03, 04, 05, 06, 07, 08, 09, ou 49, se o CTE for de Prestação (conhec_trans.dm_ind_oper=1).
-- Rotinas: pkb_integr_ctimpout_pis e pkb_integr_ctimpout_cofins.
--
-- Em 28/08/2018 - Karina de Paula
-- Redmine #45905 - DE-PARA
-- Rotina Alterada: pkb_integr_conhec_transp_rodo => Alterada a rotina para aceitar valor nulo para o dm_lotacao
--
-- Em 20/09/2018 - Karina de Paula
-- Redmine #47066 - Integração de Conhecimento de Transporte
-- Rotina Alterada: pkb_integr_conhec_transp => Incluída a chamada da pk_csf_ct.fkg_legado_ct; criação da vn_dm_legado e incluído tratamento para LEGADO
--
-- Em 25/09/2018 - Karina de Paula
-- Redmine #47169 - Analisar o levantamento feito do CTE 3.0
-- Rotina Alterada: pkb_integr_conhec_transp_subst => Incluido campo CPF
-- Rotina Criada: pkb_integr_evento_cte_etec
--
-- Em 04/10/2018 - Karina de Paula
-- #47505 - Feed - Integração Agendamento
-- Rotina Alterada: pkb_integr_conhec_transp => Incluída a contagem da pk_agend_integr.gvtn_qtd_total(gv_cd_obj)
-- Incluida a variável global gv_cd_obj.
--
-- Em 06/11/2018 - Angela Inês.
-- Redmine #48431 - Não deixa excluir o cte qdo tem vinculo com a tabela conhec_transp_imp_ret.
-- Os detalhes das abas são excluídos por uma procedure do PL que é chamada quando o botão excluir é acionado. A procedure deleta os dados relacionados das abas
-- e depois o java exclui o principal.
-- Além da tabela mencionada na atividade, CONHEC_TRANSP_IMP_RET, foram incluídas as seguintes: CONHEC_TRANSP_CANC, CONHEC_TRANSP_CARGA, CT_CARGA_DOC_FISCAL,
-- CT_CARGA_LOCAL, CONHEC_TRANSP_ITEM, CT_ITEM_COMPL, CT_COMPL_AEREO, CT_COMPL_AQUAV, CT_COMPL_RODO, CTINFOR_FISCAL, CT_INF_PROV, R_CTINFNF_CTINFUNIDCARGA,
-- R_CTINFNFE_CTINFUNIDCARGA, R_CTINFOUTRO_CTINFUNIDCARGA, R_CTINFNF_CTINFUNIDTRANSP, R_CTINFNFE_CTINFUNIDTRANSP, R_CTINFOUTRO_CTINFUNIDTRANSP, CT_MODAIS,
-- FRETE_ITEMNF, R_CTRLINTEGRARQ_CT e R_LOTEINTWS_CT.
-- Não foram incluídas: EFD_REINF_R2010_CTE, EFD_REINF_R2020_CTE e R_CT_CT.
-- Rotina: pkb_excluir_dados_ct.
--
-- Em 07/11/2018 - Angela Inês.
-- Redmine #48476 - Correção na Validação da Placa em "Informações do Modal Rodoviário CTe Outros Serviços" e em "Veículos do Transporte da Nota Fiscal".
-- Não fazer a validação de Sufixo e Prefixo da Placa do Veículo.
-- Rotina: pkb_integr_ctrodo_veic.
--
-- Em 20/11/2018 - Angela Inês.
-- Redmine #48898 - Alterar o processo de validação da Forma de Emissão para Conhecimento de Transporte.
-- Considerar o forma de emissão parametrizada na empresa caso o conhecimento de transporte não seja legado, do contrário, considerar da própria chave enviada.
-- Após validar a chave do conhecimento de transporte, de emissão própria, e o processo verificar que houve erro, fazer a montagem da chave somente se o
-- conhecimento for legado.
-- Rotina: pkb_integr_conhec_transp.
--
-- Em 21/11/2018 - Angela Inês.
-- Redmine #48916 - Defeito - nao está integrando cte com dm_legado <> 0.
-- O processo estava considerando a situação e o legado, do conhecimento já cadastrado, porém essas informações estão da View de Integração com valor e o
-- conhecimento ainda não está no cadastro integrado. Foi necessário fazer um teste identificando se os valores da situação e do legado estão nulos para serem
-- recuperados no conhecimento caso exista, do contrário os valores serão recuperados da view de integração.
-- Outras correção foi feita na recuperação da forma de emissão, que está considerando o valor enviado na chave de acesso, porém esses conhecimentos de transporte
-- não possuem chave de acesso, ficando com o valor NULO. Foi necessário identificar se o conhecimento for legado (<>0), e a chave de acesso estiver nula, a forma
-- de emissão será 1-Normal. Se o conhecimento não for legado (=0), e a forma de emissão estiver nula, o valor será recuperado do parâmetro da empresa.
-- Rotina: pkb_integr_conhec_transp.
--
-- Em 28/01/2018 - Karina de Paula
-- Redmine #50749 - Procedure para limpar dependências da tabela CONHEC_TRANSP.
-- Rotina Alterada: pk_csf_api_ct.pkb_excluir_dados_ct => Incluída a exclusão dos dados da tabela ctinfor_fiscal
--
-- Em 29/01/2019 - Renan Alves
-- Redmine #49303 - Tela de Conhecimento de Transporte - Botão validar
-- Alteração: Foi acrescentado uma verificação para os tipos de emissões (0 - Emissão própria / 1 - Terceiros)
-- na pkb_consistem_ct, retornando uma mensagem de log específica, para cada emissão.
--
-- Em 31/01/2019 - Marcos Ferreira
-- Redmine #51090 - Valor Base Outras e Valor Base Isenta para CTe Emissao Propria
-- Solicitação: Incluir a integração dos campos VL_BASE_OUTRO, VL_IMP_OUTRO, VL_BASE_ISENTA, ALIQ_APLIC_OUTRO na Integração de impostos para Conhecimento de Transporte
-- Alterações: Criação da integração pela VW_CSF_CONHEC_TRANSP_IMP_FF
-- Procedures Criada: pkb_integr_ct_imp_ff
--
-- Em 14/02/2018 - Karina de Paula
-- Redmine #51537 - CTe não está excluindo pela tela
-- Rotina Alterada: pk_csf_api_ct.pkb_excluir_dados_ct => Incluída a exclusão dos dados da tabela ct_inf_prov
--
-- Em 18/03/2019 - Marcos Ferreira
-- Redmine Melhoria #52544: Mudar forma de geração CCT_CTE
-- Solicitação: Para evitar fraudes e aumentar a segurança, gerar o campo CCT_CTE por numero randomico
-- Alterações: Criado Função FKG_GERA_CCT_CTE_RAND e Alterado as procedures que utilizam a composição do campo CCT_CTE
-- Procedures Alteradas: FKG_GERA_CCT_CTE_RAND, PKB_INTEGR_CTCHAVE_REFER
--
-- Redmine Redmine #53636 - Correção na validação da Chave de Acesso do CTe.
-- Ao validar a chave de acesso do CTe consistimos o CNPJ da chave de acesso com o CNPJ da Empresa emitente do Conhecimento de Transporte.
-- Passar a considerar o CNPJ da chave de acesso com o CNPJ da Empresa emitente do Conhecimento de Transporte desde que o Indicador do Emitente seja Emissão Própria.
-- Passar a considerar o CNPJ da chave de acesso com o CNPJ do Participante do Conhecimento de Transporte desde que o Indicador do Emitente seja Terceiro.
-- Rotinas: pkb_integr_conhec_transp e pkb_valida_chave_acesso.
--
-- Redmine Redmine #53666 - Correção na validação da Chave de Acesso do CTe.
-- Ao validar a chave de acesso do CTe consistimos o Código do IBGE da Cidade da chave de acesso com o Código do IBGE da Cidade da Empresa emitente do
-- Conhecimento de Transporte.
-- Passar a considerar o Código do IBGE da Cidade da chave de acesso com o Código do IBGE da Cidade da Empresa emitente do Conhecimento de Transporte desde que
-- o Indicador do Emitente seja Emissão Própria.
-- Passar a considerar o Código do IBGE da Cidade da chave de acesso com o Código do IBGE da Cidade do Participante do Conhecimento de Transporte desde que o
-- Indicador do Emitente seja Terceiro.
-- Rotina: pkb_valida_chave_acesso.
--
-- Em 26/04/2019 - Karina de Paula
-- Redmine #52645 - Erro na exclusão do CT-e.
-- Rotina Alterada: pkb_excluir_dados_ct => Criada a variável global gn_ind_exclu que será usada na rotina de exclusão do CT de conversão para não chamar novamente a pk_csf_api_ct.pkb_excluir_dados_ct
--                                          gn_ind_exclu number := 0; -- Indica que o CT foi excluído (0-Não / 1-Sim).
--
-- Em 22/05/2019 - Marcos Ferreira
-- Redmine #51731 - Upload de Cte de Terceiro
-- Solicitação: Integração de XML CTe Terceiro, se rejeitar por algum motivo, não atualizar a conhec_transp.dm_st_proc
-- Procedures Alteradas: pkb_relac_cte_cons_sit
--
-- === AS ALTERAÇÕES PASSARAM A SER INCLUÍDAS NO INÍCIO DA PACKAGE ================================================================================= --
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------
--
   gt_row_inut_conhec_transp         Inutiliza_Conhec_Transp%rowtype;
--
   gt_row_lote_cte                   Lote_Cte%rowtype;
--
   gt_row_conhec_transp              Conhec_Transp%rowtype;
--
   gt_row_conhec_transp_tomador      Conhec_Transp_Tomador%rowtype;
--
   gt_row_conhec_transp_compl        Conhec_Transp_Compl%rowtype;
--
   gt_row_ct_compl_pass              Ct_Compl_Pass%rowtype;
--
   gt_row_ct_compl_obs               Ct_Compl_Obs%rowtype;
--
   gt_row_conhec_transp_emit         Conhec_Transp_Emit%rowtype;
--
   gt_row_conhec_transp_rem          Conhec_Transp_Rem%rowtype;
--
   gt_row_ctrem_loc_colet            ctrem_loc_colet%rowtype;
--
   gt_row_ctrem_inf_nf               Ctrem_Inf_Nf%rowtype;
--
   gt_row_ctrem_inf_nf_locret        Ctrem_Inf_Nf_Locret%rowtype;
--
   gt_row_ctrem_inf_nfe              Ctrem_Inf_Nfe%rowtype;
--
   gt_row_ctrem_inf_outro            Ctrem_Inf_Outro%rowtype;
--
   gt_row_conhec_transp_exped        Conhec_Transp_Exped%rowtype;
--
   gt_row_conhec_transp_receb        Conhec_Transp_Receb%rowtype;
--
   gt_row_conhec_transp_dest         Conhec_Transp_Dest%rowtype;
--
   gt_row_ctdest_locent              Ctdest_Locent%rowtype;
--
   gt_row_conhec_transp_vlprest      Conhec_Transp_Vlprest%rowtype;
--
   gt_row_ctvlprest_comp             Ctvlprest_Comp%rowtype;
--
   gt_row_conhec_transp_imp          Conhec_Transp_Imp%rowtype;
--
   gt_row_ctinfcarga_qtde            Ctinfcarga_Qtde%rowtype;
--
   gt_row_conhec_transp_infcarga     Conhec_Transp_Infcarga%rowtype;
--
   gt_row_conhec_transp_cont         Conhec_Transp_Cont%rowtype;
--
   gt_row_ctcont_lacre               Ctcont_Lacre%rowtype;
--
   gt_row_conhec_transp_docant       Conhec_Transp_Docant%rowtype;
--
   gt_row_ctdocant_papel             Ctdocant_Papel%rowtype;
--
   gt_row_ctdocant_eletr             Ctdocant_Eletr%rowtype;
--
   gt_row_conhec_transp_seg          Conhec_Transp_Seg%rowtype;
--
   gt_rown_ctrodo_inf_valeped        ctrodo_inf_valeped%rowtype;
--
   gt_row_conhec_transp_rodo         Conhec_Transp_Rodo%rowtype;
--
   gt_row_ctrodo_occ                 Ctrodo_Occ%rowtype;
--
   gt_row_ctrodo_valeped             Ctrodo_Valeped%rowtype;
--
   gt_row_ctrodo_valeped_disp        Ctrodo_Valeped_Disp%rowtype;
--
   gt_row_ctrodo_veic                Ctrodo_Veic%rowtype;
--
   gt_row_ctrodo_veic_prop           Ctrodo_Veic_Prop%rowtype;
--
   gt_row_ctrodo_lacre               Ctrodo_Lacre%rowtype;
--
   gt_row_ctrodo_moto                Ctrodo_Moto%rowtype;
--
   gt_row_conhec_transp_aereo        Conhec_Transp_Aereo%rowtype;
--
   gt_row_ct_aereo_dimen             ct_aereo_dimen%rowtype;
--
   gt_row_ct_aereo_inf_man           ct_aereo_inf_man%rowtype;
--
   gt_row_ct_aereo_carg_esp          ct_aereo_carg_esp%rowtype;
--
   gt_row_conhec_transp_aquav        Conhec_Transp_Aquav%rowtype;
--
   gt_row_ctaquav_lacre              Ctaquav_Lacre%rowtype;
--
   gt_row_ct_aquav_balsa             ct_aquav_balsa%rowtype;
--
   gt_row_ctrodo_inf_valeped         ctrodo_inf_valeped%rowtype;
--
   gt_row_ct_aquav_cont              ct_aquav_cont%rowtype;
--
   gt_row_ct_aquav_cont_lacre        ct_aquav_cont_lacre%rowtype;
--
   gt_row_ct_aquav_cont_nf           ct_aquav_cont_nf%rowtype;
--
   gt_row_ct_aquav_cont_nfe          ct_aquav_cont_nfe%rowtype;
--
   gt_row_conhec_transp_ferrov       Conhec_Transp_Ferrov%rowtype;
--
   gt_row_ctferrov_subst             Ctferrov_Subst%rowtype;
--
   gt_row_ctferrov_dcl               Ctferrov_Dcl%rowtype;
--
   gt_row_ctferrovdcl_detvag         Ctferrovdcl_Detvag%rowtype;
--
   gt_row_ctferrovdcldetvag_lacre    Ctferrovdcldetvag_Lacre%rowtype;
--
   gt_row_ctferrovdcldetvag_cont     Ctferrovdcldetvag_Cont%rowtype;
--
   gt_row_ct_ferrov_detvag           ct_ferrov_detvag%rowtype;
--
   gt_row_ct_ferrov_detvag_lacre     ct_ferrov_detvag_lacre%rowtype;
--
   gt_row_ct_ferrov_detvag_cont      ct_ferrov_detvag_cont%rowtype;
--
   gt_row_ct_ferrov_detvag_nf        ct_ferrov_detvag_nf%rowtype;
--
   gt_row_ct_ferrov_detvag_nfe       ct_ferrov_detvag_nfe%rowtype;
--
   gt_row_conhec_transp_duto         Conhec_Transp_Duto%rowtype;
--
   gt_row_conhec_transp_peri         Conhec_Transp_Peri%rowtype;
--
   gt_row_conhec_transp_veic         Conhec_Transp_Veic%rowtype;
--
   gt_row_conhec_transp_fat          conhec_transp_fat%rowtype;
--
   gt_row_conhec_transp_dup          conhec_transp_dup%rowtype;
--
   gt_row_conhec_transp_subst        Conhec_Transp_Subst%rowtype;
--
   gt_row_conhec_transp_compltado    Conhec_Transp_Compltado%rowtype;
--
   gt_row_ctcompltado_comp           Ctcompltado_Comp%rowtype;
--
   gt_row_ctcompltado_imp            Ctcompltado_Imp%rowtype;
--
   gt_row_conhec_transp_anul         Conhec_Transp_Anul%rowtype;
--
   gt_row_conhec_transp_canc         Conhec_Transp_Canc%rowtype;
--
   gt_row_conhec_transp_pdf          Conhec_Transp_Pdf%rowtype;
--
   gt_row_conhec_transp_email        Conhec_Transp_email%rowtype;
--
   gt_row_conhec_transp_impr         Conhec_Transp_impr%rowtype;
--
   gt_row_ct_aut_xml                 ct_aut_xml%rowtype;
--
   gt_row_ct_inf_nf                  ct_inf_nf%rowtype;
--
   gt_row_ct_inf_nfe                 ct_inf_nfe%rowtype;
--
   gt_row_ct_inf_outro               ct_inf_outro%rowtype;
--
   gt_row_ct_inf_unid_transp         ct_inf_unid_transp%rowtype;
--
   gt_row_ct_inf_ut_lacre            ct_inf_unid_transp_lacre%rowtype;
--
   gt_row_ct_inf_ut_carga            ct_inf_unid_transp_carga%rowtype;
--
   gt_row_ct_iut_carga_lacre         ct_iut_carga_lacre%rowtype;
--
   gt_row_ct_inf_unid_carga          ct_inf_unid_carga%rowtype;
--
   gt_row_ct_inf_uc_lacre            ct_inf_unid_carga_lacre%rowtype;
--
   gt_row_r_ctinfnf_ctinfut          r_ctinfnf_ctinfunidtransp%rowtype;
--
   gt_row_r_ctinfnf_ctinfuc          r_ctinfnf_ctinfunidcarga%rowtype;
--
   gt_row_r_ctinfnfe_ctinfut         r_ctinfnfe_ctinfunidtransp%rowtype;
--
   gt_row_r_ctinfnfe_ctinfuc         r_ctinfnfe_ctinfunidcarga%rowtype;
--
   gt_row_r_ctinfoutro_ctinfut       r_ctinfoutro_ctinfunidtransp%rowtype;
--
   gt_row_r_ctinfoutro_ctinfuc       r_ctinfoutro_ctinfunidcarga%rowtype;
--
   gt_row_ct_multimodal              ct_multimodal%rowtype;
--
   gt_row_evento_cte                 evento_cte%rowtype;
--
   gt_row_evento_cte_retorno         evento_cte_retorno%rowtype;
--
   gt_row_evento_cte_epec            evento_cte_epec%rowtype;
--
   gt_row_evento_cte_multimodal      evento_cte_multimodal%rowtype;
--
   gt_row_evento_cte_cce             evento_cte_cce%rowtype;
--
   gt_row_empresa                    Empresa%rowtype;
--
   gt_row_conhec_transp_part_icms    conhec_transp_part_icms%rowtype; -- Atualização CTe 3.0
--
   gt_row_ct_inf_vinc_mult           ct_inf_vinc_mult%rowtype;        -- Atualização CTe 3.0
--
   gt_row_conhec_transp_percurso     conhec_transp_percurso%rowtype;  -- Atualização CTe 3.0
--
   gt_row_ct_doc_ref_os              ct_doc_ref_os%rowtype;           -- Atualização CTe 3.0
--
   gt_row_ct_rodo_os                 ct_rodo_os%rowtype;              -- Atualização CTe 3.0
--
   gt_row_ct_aereo_peri              ct_aereo_peri%rowtype;           -- Atualização CTe 3.0
--
   gt_row_evento_cte_gtv             evento_cte_gtv%rowtype;          -- Atualização CTe 3.0
--
   gt_row_evento_cte_gtv_esp         evento_cte_gtv_esp%rowtype;      -- Atualização CTe 3.0
--
   gt_row_evento_cte_desac           evento_cte_desac%rowtype;        -- Atualização CTe 3.0
--
   gt_row_ct_compdoc_pis             ct_comp_doc_pis%rowtype;
--
   gt_row_ct_compdoc_cofins          ct_comp_doc_cofins%rowtype;
--
   gt_row_conhec_transp_cce          conhec_transp_cce%rowtype;
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------

   gv_cabec_log          log_generico_ct.mensagem%TYPE;
   --
   gv_cabec_log_item     Log_Generico_ct.mensagem%TYPE;
   --
   gv_mensagem_log       Log_Generico_ct.mensagem%TYPE;
   --
   gv_dominio            Dominio.descr%TYPE;
   --
   gn_notafiscal_id      Nota_Fiscal.id%TYPE;
   --
   gn_dm_tp_amb          Empresa.dm_tp_amb%TYPE := null;
   --
   gn_empresa_id         Empresa.id%type := null;
   --
   gn_processo_id        Log_Generico_ct.processo_id%TYPE := null;
   --
   gv_obj_referencia     Log_Generico_ct.obj_referencia%type default 'CONHEC_TRANSP';
   --
   gn_referencia_id      Log_Generico_ct.referencia_id%type := null;
   --
   gn_tipo_integr        number := null;
   --
   gn_multorg_id         mult_org.id%type;
   --
   gv_cd_obj             obj_integr.cd%type := '4';
   --
   -- Será usado na rotina de exclusão do CT de conversão para não chamar novamente a pk_csf_api_ct.pkb_excluir_dados_ct
   gn_ind_exclu          number := 0; -- Indica que o CT foi excluído (0-Não / 1-Sim).
   --
   gn_dm_ind_emit        conhec_transp.dm_ind_emit%type := null;
   --
   gn_dm_legado          conhec_transp.dm_legado%type := null;
   --
----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Declaração de constantes
   ERRO_DE_VALIDACAO       CONSTANT NUMBER := 1;
   ERRO_DE_SISTEMA         CONSTANT NUMBER := 2;
   CONHEC_TRANSP_INTEGRADO CONSTANT NUMBER := 34;
   INFORMACAO              CONSTANT NUMBER := 35;
   info_canc_nfe           constant number := 31;

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação do e-mail para o Conhec. Transp.
procedure pkb_integr_ct_email ( en_conhectransp_id   in conhec_transp.id%type
                              , en_dm_origem         in conhec_transp_email.dm_origem%type
                              , ev_email             in conhec_transp_email.email%type
                              , en_dm_tipo_anexo     in conhec_transp_email.dm_tipo_anexo%type
                              );

-------------------------------------------------------------------------------------------------------
-- Procedimento seta o tipo de integração que será feito
-- 0 - Somente valida os dados e registra o Log de ocorrência
-- 1 - Valida os dados e registra o Log de ocorrência e insere a informação
-- Todos os procedimentos de integração fazem referência à ele
procedure pkb_seta_tipo_integr ( en_tipo_integr in number );

-------------------------------------------------------------------------------------------------------
-- Procedimento seta o objeto de referência utilizado na Validação da Informação
procedure pkb_seta_obj_ref ( ev_objeto in varchar2 );

-------------------------------------------------------------------------------------------------------
-- Procedimento seta o "ID de Referencia" utilizado na Validação da Informação
procedure pkb_seta_referencia_id ( en_id in number );

-------------------------------------------------------------------------------------------------------
-- Procedimento exclui dados de um Conhecimento de Transporte Eletrônico
procedure pkb_excluir_dados_ct ( en_conhectransp_id   in Conhec_Transp.id%TYPE
                               , en_excl_rloteintwsct in number default 0 );

-------------------------------------------------------------------------------------------------------
-- Procedimento armazena o valor do "loggenerico_id" do Conhecimento de Transporte Eletrônico
procedure pkb_gt_log_generico_ct ( en_loggenerico    in             Log_generico_ct.id%TYPE
                                 , est_log_generico  in out nocopy  dbms_sql.number_table );

-------------------------------------------------------------------------------------------------------
-- Procedimento finaliza o Log Genérico
procedure pkb_finaliza_log_generico_ct;

-------------------------------------------------------------------------------------------------------
-- Procedimento de registro de log de erros na validação da nota fiscal
procedure pkb_log_generico_ct ( sn_loggenerico_id     out nocopy Log_Generico_ct.id%TYPE
                              , ev_mensagem        in            Log_Generico_ct.mensagem%TYPE
                              , ev_resumo          in            Log_Generico_ct.resumo%TYPE
                              , en_tipo_log        in            csf_tipo_log.cd_compat%type      default 1
                              , en_referencia_id   in            Log_Generico_ct.referencia_id%TYPE  default null
                              , ev_obj_referencia  in            Log_Generico_ct.obj_referencia%TYPE default null
                              , en_empresa_id      in            Empresa.Id%type                  default null
                              , en_dm_impressa     in            Log_Generico_ct.dm_impressa%type    default 0 );

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação do Evento Prestação de Serviço em Desacordo do CTe por parte do Tomador - Atualização CTe 3.0
procedure pkb_integr_evento_cte_desac ( est_log_generico         in out nocopy  dbms_sql.number_table
                                      , est_row_evento_cte_desac in out nocopy  evento_cte_desac%rowtype
                                      , en_conhectransp_id       in             conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação do Evento de CTe GTV (Grupo de Transporte de Valores) - Espécies Transportadas - Atualização CTe 3.0
procedure pkb_integr_evento_cte_gtv_esp ( est_log_generico           in out nocopy  dbms_sql.number_table
                                        , est_row_evento_cte_gtv_esp in out nocopy  evento_cte_gtv_esp%rowtype
                                        , en_conhectransp_id         in             conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação do Evento de CTe GTV (Grupo de Transporte de Valores) - Atualização CTe 3.0
procedure pkb_integr_evento_cte_gtv ( est_log_generico       in out nocopy  dbms_sql.number_table
                                    , est_row_evento_cte_gtv in out nocopy  evento_cte_gtv%rowtype
                                    , en_conhectransp_id     in             conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Integra dados do Evento do CTe Carta de Correção

procedure pkb_integr_evento_cte_cce ( est_log_generico              in out nocopy  dbms_sql.number_table
                                    , est_row_evento_cte_cce        in out nocopy  evento_cte_cce%rowtype
                                    , en_conhectransp_id            in             conhec_transp.id%type
                                    , ev_estrutcte_grupo            in             estrut_cte.campo%type
                                    , ev_estrutcte_campo            in             estrut_cte.campo%type
                                    );

-------------------------------------------------------------------------------------------------------
-- Integra dados do Evento do CTe Multimodal

procedure pkb_integr_evento_cte_mmodal ( est_log_generico              in out nocopy  dbms_sql.number_table
                                       , est_row_evento_cte_multimodal in out nocopy  evento_cte_multimodal%rowtype
                                       , en_conhectransp_id            in             conhec_transp.id%type
                                       );

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação do Evento que integra as informações de Eventos do CTe EPEC
procedure pkb_integr_evento_cte_epec ( est_log_generico        in out nocopy  dbms_sql.number_table
                                     , est_row_evento_cte_epec in out nocopy  evento_cte_epec%rowtype
                                     , en_conhectransp_id      in             conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Integra dados do Evento do CTe

procedure pkb_integr_evento_cte ( est_log_generico              in out nocopy  dbms_sql.number_table
                                , est_row_evento_cte            in out nocopy  evento_cte%rowtype
                                , ev_tipoeventosefaz_cd         in             tipo_evento_sefaz.cd%type
                                );
--
-- ====================================================================================================== --
-- Integra dados do Conhecimento Transporte CCE
procedure pkb_integr_conhec_transp_cce ( est_log_generico          in out nocopy  dbms_sql.number_table
                                       , est_row_conhec_transp_cce in out nocopy  conhec_transp_cce%rowtype
                                       , ev_tipoeventosefaz_cd     in             tipo_evento_sefaz.cd%type
                                       );
--
-------------------------------------------------------------------------------------------------------
-- Integra dados do Multimodal

procedure pkb_integr_ct_multimodal ( est_log_generico              in out nocopy  dbms_sql.number_table
                                   , est_row_ct_multimodal         in out nocopy  ct_multimodal%rowtype
                                   , ev_cod_part_consg             in             pessoa.cod_part%type
                                   , ev_cod_part_red               in             pessoa.cod_part%type
                                   , en_multorg_id                 in             mult_org.id%type
                                   );

-------------------------------------------------------------------------------------------------------
-- Integra o Relacionamento de Outros Documentos com a Unidade de Carga

procedure pkb_integr_r_outro_infuc ( est_log_generico              in out nocopy  dbms_sql.number_table
                                   , est_row_r_outro_infunidcarga  in out nocopy  r_ctinfoutro_ctinfunidcarga%rowtype
                                   , en_conhectransp_id            in             conhec_transp.id%type
                                   , ev_dm_tipo_doc                in             ct_inf_outro.dm_tipo_doc%type
                                   , ev_nro_docto                  in             ct_inf_outro.nro_docto%type
                                   , en_dm_tp_unid_carga           in             ct_inf_unid_carga.dm_tp_unid_carga%type
                                   , ev_ident_unid_carga           in             ct_inf_unid_carga.ident_unid_carga%type
                                   );

-------------------------------------------------------------------------------------------------------
-- Integra o Relacionamento de Outros Documentos com a Unidade de Transporte

procedure pkb_integr_r_outro_infut ( est_log_generico                in out nocopy  dbms_sql.number_table
                                   , est_row_r_outro_infunidtransp   in out nocopy  r_ctinfoutro_ctinfunidtransp%rowtype
                                   , en_conhectransp_id              in             conhec_transp.id%type
                                   , ev_dm_tipo_doc                  in             ct_inf_outro.dm_tipo_doc%type
                                   , ev_nro_docto                    in             ct_inf_outro.nro_docto%type
                                   , en_dm_tp_unid_transp            in             ct_inf_unid_transp.dm_tp_unid_transp%type
                                   , ev_ident_unid_transp            in             ct_inf_unid_transp.ident_unid_transp%type
                                   );

-------------------------------------------------------------------------------------------------------
-- Integra o Relacionamento da NFe com a Unidade de Carga

procedure pkb_integr_r_nfe_infunidcarga ( est_log_generico            in out nocopy  dbms_sql.number_table
                                        , est_row_r_nfe_infunidcarga  in out nocopy  r_ctinfnfe_ctinfunidcarga%rowtype
                                        , en_conhectransp_id          in             conhec_transp.id%type
                                        , ev_nro_chave_nfe            in             ct_inf_nfe.nro_chave_nfe%type
                                        , en_dm_tp_unid_carga         in             ct_inf_unid_carga.dm_tp_unid_carga%type
                                        , ev_ident_unid_carga         in             ct_inf_unid_carga.ident_unid_carga%type
                                        );

-------------------------------------------------------------------------------------------------------
-- Integra o Relacionamento da NFe com a Unidade de Transporte

procedure pkb_integr_r_nfe_infunidtransp ( est_log_generico              in out nocopy  dbms_sql.number_table
                                         , est_row_r_nfe_infunidtransp   in out nocopy  r_ctinfnfe_ctinfunidtransp%rowtype
                                         , en_conhectransp_id            in             conhec_transp.id%type
                                         , ev_nro_chave_nfe              in             ct_inf_nfe.nro_chave_nfe%type
                                         , en_dm_tp_unid_transp          in             ct_inf_unid_transp.dm_tp_unid_transp%type
                                         , ev_ident_unid_transp          in             ct_inf_unid_transp.ident_unid_transp%type
                                         );

-------------------------------------------------------------------------------------------------------
-- Integra o Relacionamento da Nota Fiscal com a Unidade de Carga

procedure pkb_integr_r_nf_infunidcarga ( est_log_generico            in out nocopy  dbms_sql.number_table
                                       , est_row_r_nf_infunidcarga   in out nocopy  r_ctinfnf_ctinfunidcarga%rowtype
                                       , en_conhectransp_id          in             conhec_transp.id%type
                                       , ev_cod_mod_nf               in             mod_fiscal.cod_mod%type
                                       , ev_serie_nf                 in             ct_inf_nf.serie%type
                                       , en_nro_nf                   in             ct_inf_nf.nro_nf%type
                                       , en_dm_tp_unid_carga         in             ct_inf_unid_carga.dm_tp_unid_carga%type
                                       , ev_ident_unid_carga         in             ct_inf_unid_carga.ident_unid_carga%type
                                       );

-------------------------------------------------------------------------------------------------------
-- Integra o Relacionamento da Nota Fiscal com a Unidade de Transporte

procedure pkb_integr_r_nf_infunidtransp ( est_log_generico            in out nocopy  dbms_sql.number_table
                                        , est_row_r_nf_infunidtransp  in out nocopy  r_ctinfnf_ctinfunidtransp%rowtype
                                        , en_conhectransp_id          in             conhec_transp.id%type
                                        , ev_cod_mod_nf               in             mod_fiscal.cod_mod%type
                                        , ev_serie_nf                 in             ct_inf_nf.serie%type
                                        , en_nro_nf                   in             ct_inf_nf.nro_nf%type
                                        , en_dm_tp_unid_transp        in             ct_inf_unid_transp.dm_tp_unid_transp%type
                                        , ev_ident_unid_transp        in             ct_inf_unid_transp.ident_unid_transp%type
                                        );

-------------------------------------------------------------------------------------------------------
-- Integra os Lacres das Unidades de Carga
procedure pkb_integr_ct_ct_iuc_lacre ( est_log_generico         in out nocopy  dbms_sql.number_table
                                     , est_row_ct_iuc_lacre     in out nocopy  ct_inf_unid_carga_lacre%rowtype
                                     , en_conhectransp_id       in             conhec_transp.id%type
                                     );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações das Unidades de Carga
procedure pkb_integr_ct_inf_unid_carga ( est_log_generico               in out nocopy  dbms_sql.number_table
                                       , est_row_ct_inf_unid_carga      in out nocopy  ct_inf_unid_carga%rowtype
                                       );

-------------------------------------------------------------------------------------------------------
-- Integra os Lacres das Unidades de Carga
procedure pkb_integr_ct_iut_carga_lacre ( est_log_generico               in out nocopy  dbms_sql.number_table
                                        , est_row_ct_iut_carga_lacre     in out nocopy  ct_iut_carga_lacre%rowtype
                                        , en_conhectransp_id             in             conhec_transp.id%type
                                        );

-------------------------------------------------------------------------------------------------------
-- Integra os Cargas das Unidades de Transporte
procedure pkb_integr_ct_iut_carga ( est_log_generico         in out nocopy  dbms_sql.number_table
                                  , est_row_ct_iut_carga     in out nocopy  ct_inf_unid_transp_carga%rowtype
                                  , en_conhectransp_id       in             Conhec_Transp.id%TYPE
                                  );

-------------------------------------------------------------------------------------------------------
-- Integra os Lacres das Unidades de Transporte
procedure pkb_integr_ct_iut_lacre ( est_log_generico         in out nocopy  dbms_sql.number_table
                                  , est_row_ct_iut_lacre     in out nocopy  ct_inf_unid_transp_lacre%rowtype
                                  , en_conhectransp_id       in             Conhec_Transp.id%TYPE
                                  );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações das Unidades de Transporte
procedure pkb_integr_ct_inf_unid_transp ( est_log_generico               in out nocopy  dbms_sql.number_table
                                        , est_row_ct_inf_unid_transp     in out nocopy  ct_inf_unid_transp%rowtype
                                        );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos demais documentos
procedure pkb_integr_ct_inf_outro ( est_log_generico         in out nocopy  dbms_sql.number_table
                                  , est_row_ct_inf_outro     in out nocopy  ct_inf_outro%rowtype
                                  );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas a NFe do Conhec. Transp.
procedure pkb_integr_ct_inf_nfe ( est_log_generico      in out nocopy  dbms_sql.number_table
                                , est_row_ct_inf_nfe    in out nocopy  ct_inf_nfe%rowtype
                                );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas das NF do Conhecimento de Transporte
procedure pkb_integr_ct_inf_nf ( est_log_generico      in out nocopy  dbms_sql.number_table
                               , est_row_ct_inf_nf     in out nocopy  ct_inf_nf%rowtype
                               , ev_cod_mod            in             Mod_Fiscal.cod_mod%type
                               );

-------------------------------------------------------------------------------------------------------
-- Integra as informações de Pessoas Autorizadas a fazer download do XML na Sefaz
procedure pkb_integr_ct_aut_xml ( est_log_generico      in out nocopy  dbms_sql.number_table
                                , est_row_ct_aut_xml    in out nocopy  ct_aut_xml%rowtype
                                );

-------------------------------------------------------------------------------------------------------
-- Integra as informações de envio de Impressoras do CTe
procedure pkb_integr_conhec_transp_impr ( est_log_generico   in out nocopy  dbms_sql.number_table
                                        , est_row_ct_impr    in out nocopy  Conhec_Transp_impr%rowtype
                                        );

-------------------------------------------------------------------------------------------------------
-- Integra as informações de envio de e-mail do CTe
procedure pkb_integr_conhec_transp_email ( est_log_generico   in out nocopy  dbms_sql.number_table
                                         , est_row_ct_email   in out nocopy  Conhec_Transp_email%rowtype
                                         );

-------------------------------------------------------------------------------------------------------
-- Integra as informações do detalhamento do CT-e do Tipo de Anulação de Valores      conhec_transp_anul
procedure pkb_integr_conhec_transp_anul ( est_log_generico   in out nocopy  dbms_sql.number_table
                                        , est_row_ct_anul    in out nocopy  Conhec_Transp_Anul%rowtype
                                        , en_conhectransp_id in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Impostos de complemento
procedure pkb_integr_ctcompltado_imp ( est_log_generico        in out nocopy  dbms_sql.number_table
                                     , est_row_Imp_ComCt       in out nocopy  Ctcompltado_Imp%rowtype
                                     , en_cd_imp               in             Tipo_Imposto.cd%TYPE
                                     , ev_cod_st               in             Cod_ST.cod_st%TYPE
                                     , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Valor da Prestação de complemento
procedure pkb_integr_ctcompltado_comp ( est_log_generico        in out nocopy  dbms_sql.number_table
                                      , est_row_Comp_Ct         in out nocopy  ctcompltado_comp%rowtype
                                      , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Detalhamento do CT-e complementado
procedure pkb_integr_ct_compltado ( est_log_generico        in out nocopy  dbms_sql.number_table
                                  , est_row_ct_compltado    in out nocopy  Conhec_Transp_Compltado%rowtype
                                  , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas do CT-e de substituição
procedure pkb_integr_conhec_transp_subst ( est_log_generico      in out nocopy  dbms_sql.number_table
                                         , est_row_ct_subst      in out nocopy  Conhec_Transp_Subst%rowtype
                                         , en_conhectransp_id    in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Dados da Cobrança
procedure pkb_integr_conhec_transp_dup ( est_log_generico           in out nocopy  dbms_sql.number_table
                                       , est_row_Conhec_Transp_dup  in out nocopy  Conhec_Transp_dup%rowtype
                                       );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Dados da fatura
procedure pkb_integr_conhec_transp_fat ( est_log_generico          in out nocopy  dbms_sql.number_table
                                       , est_row_Conhec_Transp_fat in out nocopy  Conhec_Transp_fat%rowtype
                                       );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações dos veículos transportados
procedure pkb_integr_conhec_transp_veic ( est_log_generico        in out nocopy  dbms_sql.number_table
                                        , est_row_ct_veic         in out nocopy  Conhec_Transp_Veic%rowtype
                                        , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas a transporte de produtos classificados pela ONU como perigosos
procedure pkb_integr_conhec_transp_peri ( est_log_generico        in out nocopy  dbms_sql.number_table
                                        , est_row_ct_peri         in out nocopy  Conhec_Transp_Peri%rowtype
                                        , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas a transporte de produtos classificados pela ONU como perigosos
procedure pkb_integr_conhec_transp_duto ( est_log_generico        in out nocopy  dbms_sql.number_table
                                        , est_row_ct_duto         in out nocopy  Conhec_Transp_Duto%rowtype
                                        , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos containeres contidos no vagão com DCL
procedure pkb_integr_ctferr_cont ( est_log_generico        in out nocopy  dbms_sql.number_table
                                 , est_row_ctferr_cont     in out nocopy  Ctferrovdcldetvag_Cont%rowtype
                                 , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Lacres dos vagões do DCL
procedure pkb_integr_ctferr_lacre ( est_log_generico        in out nocopy  dbms_sql.number_table
                                  , est_row_ctferr_lacre    in out nocopy  Ctferrovdcldetvag_Lacre%rowtype
                                  , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos de detalhes dos Vagões
procedure pkb_integr_ctferrovdcl_detvag ( est_log_generico        in out nocopy  dbms_sql.number_table
                                        , est_row_ctferr_detvag   in out nocopy  Ctferrovdcl_Detvag%rowtype
                                        , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao DCL
procedure pkb_integr_ctferrov_dcl ( est_log_generico        in out nocopy  dbms_sql.number_table
                                  , est_row_ctferr_dcl      in out nocopy  Ctferrov_Dcl%rowtype
                                  , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas a Dados do endereço da ferrovia substituída
procedure pkb_integr_ctferrov_subst ( est_log_generico        in out nocopy  dbms_sql.number_table
                                    , est_row_ctferr_subst    in out nocopy  Ctferrov_Subst%rowtype
                                    , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas modal Ferroviário
procedure pkb_integr_ct_ferrov ( est_log_generico        in out nocopy  dbms_sql.number_table
                               , est_row_ct_ferrov       in out nocopy  Conhec_Transp_Ferrov%rowtype
                               , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao lacres dos cointainers da qtde da carga no modal Aquaviário.
procedure pkb_integr_ctaquav_lacre ( est_log_generico        in out nocopy  dbms_sql.number_table
                                   , est_row_ctaquav_lacre   in out nocopy  Ctaquav_Lacre%rowtype
                                   , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas modal Aquaviário.
procedure pkb_integr_conhec_transp_aquav ( est_log_generico      in out nocopy  dbms_sql.number_table
                                         , est_row_ct_aquav      in out nocopy  Conhec_Transp_Aquav%rowtype
                                         , en_conhectransp_id    in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação das Informações do Transporte de produtos classificados pela ONU como perigosos - Atualização CTe 3.0
procedure pkb_integr_ct_aereo_peri ( est_log_generico        in out nocopy dbms_sql.number_table
                                   , est_row_ct_aereo_peri   in out nocopy ct_aereo_peri%rowtype
                                   , en_conhectransp_id      in            conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas modal Aéreo.
procedure pkb_integr_conhec_transp_aereo ( est_log_generico      in out nocopy  dbms_sql.number_table
                                         , est_row_ct_aereo      in out nocopy  Conhec_Transp_Aereo%rowtype
                                         , en_conhectransp_id    in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos motorista (rodoviário).
procedure pkb_integr_ctrodo_moto ( est_log_generico        in out nocopy  dbms_sql.number_table
                                 , est_row_ctrodo_moto     in out nocopy  Ctrodo_Moto%rowtype
                                 , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas Dados dos Veículos (Lacre).
procedure pkb_integr_ctrodo_lacre ( est_log_generico        in out nocopy  dbms_sql.number_table
                                  , est_row_ctrodo_lacre    in out nocopy  Ctrodo_Lacre%rowtype
                                  , en_conhectransp_id      in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Proprietários do Veículo.
procedure pkb_integr_ctrodo_veic_prop ( est_log_generico         in out nocopy  dbms_sql.number_table
                                      , est_row_ctrodo_veic_prop in out nocopy  Ctrodo_Veic_Prop%rowtype
                                      , en_conhectransp_id       in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Dados do Veículo.
procedure pkb_integr_ctrodo_veic ( est_log_generico         in out nocopy  dbms_sql.number_table
                                 , est_row_ctrodo_veic      in out nocopy  Ctrodo_Veic%rowtype
                                 , en_conhectransp_id       in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas dispositivos do Vale Pedágio.
procedure pkb_integr_ctrodo_valeped_disp ( est_log_generico            in out nocopy  dbms_sql.number_table
                                         , est_row_ctrodo_valeped_disp in out nocopy  Ctrodo_Valeped_Disp%rowtype
                                         , en_conhectransp_id          in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas Vale Pedágio.
procedure pkb_integr_ctrodo_valeped ( est_log_generico       in out nocopy  dbms_sql.number_table
                                    , est_row_ctrodo_valeped in out nocopy  Ctrodo_Valeped%rowtype
                                    , en_conhectransp_id     in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Vale Pedágio
procedure pkb_integr_ctrodo_inf_valeped ( est_log_generico             in out nocopy  dbms_sql.number_table
                                        , est_row_ctrodo_inf_valeped   in out nocopy  ctrodo_inf_valeped%rowtype
                                        , en_conhectransp_id           in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação das Informações do modal Rodoviário CTe Outros Serviços - Atualização CTe 3.0
procedure pkb_integr_ct_rodo_os ( est_log_generico      in out nocopy dbms_sql.number_table
                                , est_row_ct_rodo_os    in out nocopy ct_rodo_os%rowtype
                                , en_conhectransp_id    in            conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações da Dimensão da Carga do Modal Aéreo.
procedure pkb_integr_ct_aereo_dimen ( est_log_generico             in out nocopy  dbms_sql.number_table
                                    , est_row_ct_aereo_dimen       in out nocopy  ct_aereo_dimen%rowtype
                                    , en_conhectransp_id           in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações do manuseio da carga do modal Aéreo.
procedure pkb_integr_ct_aereo_inf_man ( est_log_generico             in out nocopy  dbms_sql.number_table
                                      , est_row_ct_aereo_inf_man     in out nocopy  ct_aereo_inf_man%rowtype
                                      , en_conhectransp_id           in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações do manuseio da carga especial do modal Aéreo.
procedure pkb_integr_ct_aereo_carg_esp ( est_log_generico             in out nocopy  dbms_sql.number_table
                                       , est_row_ct_aereo_carg_esp    in out nocopy  ct_aereo_carg_esp%rowtype
                                       , en_conhectransp_id           in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Balsas do modal Aquaviário.
procedure pkb_integr_ct_aquav_balsa ( est_log_generico          in out nocopy  dbms_sql.number_table
                                    , est_row_ct_aquav_balsa    in out nocopy  ct_aquav_balsa%rowtype
                                    , en_conhectransp_id        in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Conteiners do modal Aquaviário.
procedure pkb_integr_ct_aquav_cont ( est_log_generico          in out nocopy  dbms_sql.number_table
                                   , est_row_ct_aquav_cont     in out nocopy  ct_aquav_cont%rowtype
                                   , en_conhectransp_id        in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Lacres de Conteiners do modal Aquaviário.
procedure pkb_integr_ct_aquav_cont_lacre ( est_log_generico             in out nocopy  dbms_sql.number_table
                                         , est_row_ct_aquav_cont_lacre  in out nocopy  ct_aquav_cont_lacre%rowtype
                                         , en_conhectransp_id           in             Conhec_Transp.id%TYPE );
-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Notas de Conteiners do modal Aquaviário.
procedure pkb_integr_ct_aquav_cont_nf ( est_log_generico            in out nocopy dbms_sql.number_table
                                      , est_row_ct_aquav_cont_nf    in out nocopy ct_aquav_cont_nf%rowtype
                                      , en_conhectransp_id          in            Conhec_Transp.id%TYPE );
-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Notas fiscais eletrônicas de Conteiners do modal Aquaviário.
procedure pkb_integr_ct_aquav_cont_nfe ( est_log_generico            in out nocopy dbms_sql.number_table
                                       , est_row_ct_aquav_cont_nfe   in out nocopy ct_aquav_cont_nfe%rowtype
                                       , en_conhectransp_id          in            Conhec_Transp.id%TYPE );
-------------------------------------------------------------------------------------------------------
-- Integra as Informações de detalhes dos vagões.
procedure pkb_integr_ct_ferrov_detvag    ( est_log_generico            in out nocopy  dbms_sql.number_table
                                         , est_row_ct_ferrov_detvag    in out nocopy  ct_ferrov_detvag%rowtype
                                         , en_conhectransp_id          in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de lacres dos vagões.
procedure pkb_integr_ct_fer_detvag_lacre  ( est_log_generico                 in out nocopy  dbms_sql.number_table
                                          , est_row_ct_ferrov_detvag_lacre   in out nocopy  ct_ferrov_detvag_lacre%rowtype
                                          , en_conhectransp_id               in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de conteiners dos vagões.
procedure pkb_integr_ct_fer_detvag_cont  ( est_log_generico                in out nocopy  dbms_sql.number_table
                                         , est_row_ct_ferrov_detvag_cont   in out nocopy  ct_ferrov_detvag_cont%rowtype
                                         , en_conhectransp_id              in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Rateio das NF de Vagões.
procedure pkb_integr_ct_ferrov_detvag_nf   ( est_log_generico               in out nocopy  dbms_sql.number_table
                                           , est_row_ct_ferrov_detvag_nf    in out nocopy  ct_ferrov_detvag_nf%rowtype
                                           , en_conhectransp_id             in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações de Rateio das NFe de Vagões.
procedure pkb_integr_ct_fer_detvag_nfe  ( est_log_generico               in out nocopy  dbms_sql.number_table
                                        , est_row_ct_ferrov_detvag_nfe   in out nocopy  ct_ferrov_detvag_nfe%rowtype
                                        , en_conhectransp_id             in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas Ordens de Coleta associados.
procedure pkb_integr_ctrodo_occ ( est_log_generico       in out nocopy  dbms_sql.number_table
                                , est_row_ctrodo_occ     in out nocopy  Ctrodo_Occ%rowtype
                                , en_conhectransp_id     in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao do modal Rodoviário.
procedure pkb_integr_conhec_transp_rodo ( est_log_generico           in out nocopy  dbms_sql.number_table
                                        , est_row_conhec_transp_rodo in out nocopy  Conhec_Transp_Rodo%rowtype
                                        , en_conhectransp_id         in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Seguro da Carga.
procedure pkb_integr_conhec_transp_seg ( est_log_generico          in out nocopy  dbms_sql.number_table
                                       , est_row_conhec_transp_seg in out nocopy  Conhec_Transp_Seg%rowtype
                                       , en_conhectransp_id        in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Documentos de transporte anterior eletrônicos.
procedure pkb_integr_ctdocant_eletr ( est_log_generico       in out nocopy  dbms_sql.number_table
                                    , est_row_ctdocant_eletr in out nocopy  Ctdocant_Eletr%rowtype
                                    , en_conhectransp_id     in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Documentos de transporte anterior papel.
procedure pkb_integr_ctdocant_papel ( est_log_generico       in out nocopy  dbms_sql.number_table
                                    , est_row_ctdocant_papel in out nocopy  Ctdocant_Papel%rowtype
                                    , en_conhectransp_id     in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Transporte Anterior.
procedure pkb_integr_conhectransp_docant ( est_log_generico            in out nocopy  dbms_sql.number_table
                                         , est_row_conhectransp_docant in out nocopy  Conhec_Transp_Docant%rowtype
                                         , en_conhectransp_id          in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Lacres dos containers.
procedure pkb_integr_ctcont_lacre ( est_log_generico            in out nocopy  dbms_sql.number_table
                                  , est_row_ctcont_lacre        in out nocopy  Ctcont_Lacre%rowtype
                                  , en_conhectransp_id          in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas a Informações dos containers.
procedure pkb_integr_conhec_transp_cont ( est_log_generico            in out nocopy  dbms_sql.number_table
                                        , est_row_conhec_transp_cont  in out nocopy  Conhec_Transp_Cont%rowtype
                                        , en_conhectransp_id          in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas a Informações de quantidades da Carga do CT.
procedure pkb_integr_ctinfcarga_qtde ( est_log_generico         in out nocopy  dbms_sql.number_table
                                     , est_row_ctinfcarga_qtde  in out nocopy  Ctinfcarga_Qtde%rowtype
                                     , en_conhectransp_id       in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas a Informações da Carga do CT-e.
procedure pkb_integr_ct_infcarga ( est_log_generico     in out nocopy  dbms_sql.number_table
                                 , est_row_ct_infcarga  in out nocopy  Conhec_Transp_Infcarga%rowtype
                                 , en_conhectransp_id   in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação das Informações do ICMS de partilha com a UF de término do serviço de transporte na operação interestadual - Atualização CTe 3.0
procedure pkb_integr_ct_part_icms ( est_log_generico     in out nocopy dbms_sql.number_table
                                  , est_row_ct_part_icms in out nocopy conhec_transp_part_icms%rowtype
                                  , en_conhectransp_id   in            conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação das Informações do CT-e multimodal vinculado - Atualização CTe 3.0
procedure pkb_integr_ct_inf_vinc_mult ( est_log_generico         in out nocopy dbms_sql.number_table
                                      , est_row_ct_inf_vinc_mult in out nocopy ct_inf_vinc_mult%rowtype
                                      , en_conhectransp_id       in            conhec_transp.id%type );
                                      
-------------------------------------------------------------------------------------------------------
-- Procedimento de criação das Informações do Percurso do CT-e Outros Serviços - Atualização CTe 3.0
procedure pkb_integr_ct_transp_percurso ( est_log_generico           in out nocopy dbms_sql.number_table
                                        , est_row_ct_transp_percurso in out nocopy conhec_transp_percurso%rowtype
                                        , ev_sigla_estado            in            estado.sigla_estado%type
                                        , en_conhectransp_id         in            conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Procedimento de criação das Informações dos documentos referenciados CTe Outros Serviços - Atualização CTe 3.0
procedure pkb_integr_ct_doc_ref_os ( est_log_generico      in out nocopy dbms_sql.number_table
                                   , est_row_ct_doc_ref_os in out nocopy ct_doc_ref_os%rowtype
                                   , en_conhectransp_id    in            conhec_transp.id%type );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Impostos.
procedure pkb_integr_conhec_transp_imp ( est_log_generico          in out nocopy  dbms_sql.number_table
                                       , est_row_conhec_transp_imp in out nocopy  Conhec_Transp_Imp%rowtype
                                       , en_cd_imp                 in             Tipo_Imposto.cd%TYPE
                                       , ev_cod_st                 in             Cod_ST.cod_st%TYPE
                                       , en_conhectransp_id        in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Impostos - Flex Field.
procedure pkb_integr_ct_imp_ff ( est_log_generico       in out nocopy  dbms_sql.number_table
                               , en_conhectranspimp_id  in             conhec_transp_imp.id%type
                               , ev_atributo            in             varchar2
                               , ev_valor               in             varchar2 );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas Componentes do Valor da Prestação.
procedure pkb_integr_ctvlprest_comp ( est_log_generico          in out nocopy  dbms_sql.number_table
                                    , est_row_ctvlprest_comp    in out nocopy  Ctvlprest_Comp%rowtype
                                    , en_conhectransp_id        in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Valores da Prestação de Serviço.
procedure pkb_integr_ct_vlprest ( est_log_generico      in out nocopy  dbms_sql.number_table
                                , est_row_ct_vlprest    in out nocopy  Conhec_Transp_Vlprest%rowtype
                                , en_conhectransp_id    in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Local de Entrega constante na Nota Fiscal.
procedure pkb_integr_ctdest_locent ( est_log_generico      in out nocopy  dbms_sql.number_table
                                   , est_row_ctdest_locent in out nocopy  Ctdest_Locent%rowtype
                                   , en_conhectransp_id    in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao do Destinatário do CT.
procedure pkb_integr_conhec_transp_dest ( est_log_generico           in out nocopy  dbms_sql.number_table
                                        , est_row_conhec_transp_dest in out nocopy  Conhec_Transp_Dest%rowtype
                                        , en_conhectransp_id         in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao do Recebedor da Carga.
procedure pkb_integr_conhec_transp_receb ( est_log_generico            in out nocopy  dbms_sql.number_table
                                         , est_row_conhec_transp_receb in out nocopy  Conhec_Transp_Receb%rowtype
                                         , en_conhectransp_id          in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Expedidor da Carga.
procedure pkb_integr_conhec_transp_exped ( est_log_generico            in out nocopy  dbms_sql.number_table
                                         , est_row_conhec_transp_exped in out nocopy  Conhec_Transp_Exped%rowtype
                                         , en_conhectransp_id          in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos demais documentos.
procedure pkb_integr_ctrem_inf_outro ( est_log_generico         in out nocopy  dbms_sql.number_table
                                     , est_row_ctrem_inf_outro  in out nocopy  Ctrem_Inf_Outro%rowtype
                                     , en_conhectransp_id       in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas a NFe do remetente
procedure pkb_integr_ctrem_inf_nfe ( est_log_generico         in out nocopy  dbms_sql.number_table
                                   , est_row_ctrem_inf_nfe    in out nocopy  Ctrem_Inf_Nfe%rowtype
                                   , en_conhectransp_id       in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Local de retirada constante na NF
procedure pkb_integr_ctrem_inf_nf_locret ( est_log_generico            in out nocopy  dbms_sql.number_table
                                         , est_row_ctrem_inf_nf_locret in out nocopy  Ctrem_Inf_Nf_Locret%rowtype
                                         , en_conhectransp_id          in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas das NF do remetente
procedure pkb_integr_ctrem_inf_nf ( est_log_generico      in out nocopy  dbms_sql.number_table
                                  , est_row_ctrem_inf_nf  in out nocopy  Ctrem_Inf_Nf%rowtype
                                  , en_conhectransp_id    in             Conhec_Transp.id%TYPE
                                  , ev_cod_mod            in             Mod_Fiscal.cod_mod%type );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Local da Coleta do Remetente
procedure pkb_integr_ctrem_loc_colet ( est_log_generico         in out nocopy dbms_sql.number_table
                                     , est_row_ctrem_loc_colet  in out nocopy ctrem_loc_colet%rowtype
                                     , en_conhectransp_id       in            Conhec_Transp.id%TYPE
                                     );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Remetente das mercadorias transportadas pelo CT.
procedure pkb_integr_conhec_transp_rem ( est_log_generico          in out nocopy  dbms_sql.number_table
                                       , est_row_conhec_transp_rem in out nocopy  Conhec_Transp_Rem%rowtype
                                       , en_conhectransp_id        in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas do Emitente do CT.
procedure pkb_integr_conhec_transp_emit ( est_log_generico           in out nocopy  dbms_sql.number_table
                                        , est_row_conhec_transp_emit in out nocopy  Conhec_Transp_Emit%rowtype
                                        , en_conhectransp_id         in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Observações do Contribuinte/Fiscal
procedure pkb_integr_ct_compl_obs ( est_log_generico      in out nocopy  dbms_sql.number_table
                                  , est_row_ct_compl_obs  in out nocopy  Ct_Compl_Obs%rowtype
                                  , en_conhectransp_id    in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas a Sigla ou código interno da Filial/Porto/Estação/Aeroporto de Passagem
procedure pkb_integr_ct_compl_pass ( est_log_generico      in out nocopy  dbms_sql.number_table
                                   , est_row_ct_compl_pass in out nocopy  Ct_Compl_Pass%rowtype
                                   , en_conhectransp_id    in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Dados compl. do CT-e para fins operacionais ou comerciais
procedure pkb_integr_conhec_transp_compl ( est_log_generico            in out nocopy  dbms_sql.number_table
                                         , est_row_conhec_transp_compl in out nocopy  Conhec_Transp_Compl%rowtype
                                         , en_conhectransp_id          in             Conhec_Transp.id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas ao Indicador do "papel" do tomador do serviço no CT-e, pessoa que o serviço foi prestado
procedure pkb_integr_ct_tomador ( est_log_generico     in out nocopy  dbms_sql.number_table
                                , est_row_ct_tomador   in out nocopy  Conhec_Transp_Tomador%rowtype
                                , en_conhectransp_id   in             Conhec_Transp.id%TYPE );
-------------------------------------------------------------------------------------------------------
-- Integra as Informações relativas aos Dados compl. do CT-e para fins operacionais ou comerciais
procedure pkb_integr_conhec_transp ( est_log_generico           in out nocopy dbms_sql.number_table
                                   , est_row_conhec_transp      in out nocopy Conhec_Transp%rowtype
                                   , ev_cod_mod                 in            Mod_Fiscal.cod_mod%TYPE
                                   , ev_cod_matriz              in            Empresa.cod_matriz%TYPE  default null
                                   , ev_cod_filial              in            Empresa.cod_filial%TYPE  default null
                                   , ev_empresa_cpf_cnpj        in            varchar2                 default null -- CPF/CNPJ da empresa
                                   , ev_cod_part                in            Pessoa.cod_part%TYPE     default null
                                   , ev_cd_sitdocto             in            Sit_Docto.cd%TYPE        default null
                                   , ev_cod_infor               in            Infor_Comp_Dcto_Fiscal.cod_infor%TYPE default null
                                   , ev_sist_orig               in            sist_orig.sigla%type     default null
                                   , ev_cod_unid_org            in            unid_org.cd%type         default null
                                   , en_multorg_id              in            mult_org.id%type
                                   , en_empresaintegrbanco_id   in            empresa_integr_banco.id%type default null
                                   , en_loteintws_id            in            lote_int_ws.id%type          default 0
                                   , en_integra                 in out        number 
                                   );

-------------------------------------------------------------------------------------------------------
-- Procedimento válida a chave de acesso do CTe
procedure pkb_valida_chave_acesso ( est_log_generico     in out nocopy  dbms_sql.number_table
                                  , ev_nro_chave_cte     in             conhec_transp.nro_chave_cte%TYPE
                                  , en_empresa_id        in             Empresa.id%TYPE
                                  , en_pessoa_id         in             pessoa.id%type
                                  , en_dm_ind_emit       in             conhec_transp.dm_ind_emit%type
                                  , ed_dt_hr_emissao     in             conhec_transp.dt_hr_emissao%TYPE
                                  , ev_cod_mod           in             Mod_Fiscal.cod_mod%TYPE
                                  , en_serie             in             conhec_transp.serie%TYPE
                                  , en_nro_ct            in             conhec_transp.nro_ct%TYPE
                                  , en_dm_forma_emiss    in             conhec_transp.dm_forma_emiss%type
                                  , sn_cCT_cte           out            conhec_transp.cCT_cte%TYPE
                                  , sn_dig_verif_chave   out            conhec_transp.dig_verif_chave%TYPE
                                  , sn_qtde_erro         out            number );

-------------------------------------------------------------------------------------------------------
-- Procedimento integra a Chave do Conhecimento de Transporte
procedure pkb_integr_CTChave_Refer ( est_log_generico     in out nocopy  dbms_sql.number_table
                                   , en_empresa_id        in             Empresa.id%TYPE
                                   , en_conhectransp_id   in             Conhec_Transp.id%TYPE
                                   , ed_dt_hr_emissao     in             Conhec_Transp.dt_hr_emissao%TYPE
                                   , ev_cod_mod           in             Mod_Fiscal.cod_mod%TYPE
                                   , en_serie             in             Conhec_Transp.serie%TYPE
                                   , en_nro_ct            in             Conhec_Transp.nro_ct%TYPE
                                   , en_dm_forma_emiss    in             Conhec_Transp.dm_forma_emiss%type
                                   , esn_cCT_cte          in out nocopy  Conhec_Transp.cCT_cte%TYPE
                                   , sn_dig_verif_chave   out            Conhec_Transp.dig_verif_chave%TYPE
                                   , sv_nro_chave_cte     out            Conhec_Transp.nro_chave_cte%TYPE
                                   );

-------------------------------------------------------------------------------------------------------

-- Função cria o Lote de Envio da Nota Fiscal e retorna o ID
function fkg_integr_lote_cte ( est_log_generico     in out nocopy  dbms_sql.number_table
                             , en_empresa_id        in             Empresa.id%type
                             , en_modfiscal_id      in             Mod_Fiscal.id%type  --Atualização CTe 3.0
                             ) return lote_cte.id%TYPE;

-------------------------------------------------------------------------------------------------------
-- Re-envia lote que teve erro ao ser enviado a SEFAZ
procedure pkb_reenvia_lote_cte;

-------------------------------------------------------------------------------------
-- Procedimento ajusta lotes que estão com a situação 2-concluído e suas notas não
PROCEDURE PKB_AJUSTA_LOTE_CTE ( en_multorg_id in mult_org.id%type );

-------------------------------------------------------------------------------------------------------
-- Procedimento excluir lotes sem Conhecimento de Transportes
procedure pkb_excluir_lote_sem_cte ( en_multorg_id in mult_org.id%type default 0);

-------------------------------------------------------------------------------------------------------
-- Processo de criação do Lote de Conhecimento de Transportes
procedure pkb_gera_lote_cte ( en_multorg_id in mult_org.id%type );

-------------------------------------------------------------------------------------------------------
-- Função retorna os conhecimentos de transportes que não pode ser inutilizadas
function fkg_ct_nao_inutiliza ( en_empresa_id   in  Inutiliza_Conhec_Transp.empresa_id%TYPE
                              , en_dm_tp_amb    in  Inutiliza_Conhec_Transp.dm_tp_amb%TYPE
                              , ev_cod_mod      in  Mod_Fiscal.cod_mod%TYPE
                              , en_serie        in  Inutiliza_Conhec_Transp.serie%TYPE
                              , en_nro_ini      in  Inutiliza_Conhec_Transp.nro_ini%TYPE
                              , en_nro_fim      in  Inutiliza_Conhec_Transp.nro_fim%TYPE )
          return varchar2;

-------------------------------------------------------------------------------------------------------
-- Procedimento faz a integração da Inutilização do Conhecimento de Transporte
procedure pkb_integr_inutilizact ( est_log_generico           in out nocopy  dbms_sql.number_table
                                 , est_row_Inutiliza_Ct       in out nocopy  Inutiliza_Conhec_Transp%rowtype
                                 , ev_cod_mod                 in             Mod_Fiscal.cod_mod%TYPE
                                 );

-------------------------------------------------------------------------------------------------------
-- procedimento de atualiar CT-e inutilizadas
-- Depois de Homologado a Inutilização, verifica se tem algum CTe vinculada e
-- Altera o DM_ST_PROC para 8-Inutilizada e a Situação do Documento para "05-NF-e ou CT-e - Numeração inutilizada"
procedure pkb_atual_cte_inut ( en_multorg_id in mult_org.id%type );

-------------------------------------------------------------------------------------------------------
-- Procedimento de atualização do campo CONHECTRANSP_ID da tabela CT_CONS_SIT
-- Pega todos os registros que o campo CONHECTRANSP_ID estão nulos, verifica se sua chave de acesso existe
-- na tabela CONHEC_TRANSP, se exitir relacionar o campo CONHECTRANSP_ID.ID com campo CSF_CONS_SIT.CONHECTRANSP_ID
procedure pkb_relac_cte_cons_sit ( en_multorg_id in mult_org.id%type );

--------------------------------------------------------------------------------------------------------
-- Metodo para consultar CTe de Terceiro, com "Data de Autorização" menor que sete dias da data atual --
-- serve para verificar se o emitente da CTe cancelou a mesma                                         --
--------------------------------------------------------------------------------------------------------
PROCEDURE PKB_CONS_CTE_TERC ( en_multorg_id  in mult_org.id%type );

-------------------------------------------------------------------------------------------------------
-- Atualiza Situação do Conhecimento de Transporte
procedure pkb_atual_sit_docto ( en_multorg_id in mult_org.id%type );

-------------------------------------------------------------------------------------------------------
-- Procedimento que busca todas as Inutilizações com a situação "5-Não Validada"
procedure pkb_consit_inutilizacao ( en_multorg_id in mult_org.id%type );

-------------------------------------------------------------------------------------------------------
-- Procedimento que faz a integração os CT-e Cancelados
procedure pkb_integr_Conhec_Transp_Canc ( est_log_generico            in out nocopy  dbms_sql.number_table
                                        , est_row_Conhec_Transp_Canc  in out nocopy  Conhec_Transp_Canc%rowtype
                                        , en_loteintws_id             in             lote_int_ws.id%type default 0
                                        );

-------------------------------------------------------------------------------------------------------
-- Procedimento valida informação de Anulação de CT-e
-- Verifica se as informações inseridas estão dentro das regras de negócios expostas no Layout do Ct-e versão 1.03.
procedure pkb_valida_infor_anulacao ( est_log_generico     in out nocopy  dbms_sql.number_table
                                    , en_conhectransp_id   in             Conhec_Transp.Id%TYPE );

-------------------------------------------------------------------------------------------------------
-- Procedure que consiste os dados do Conhecimento de Transporte
procedure pkb_consistem_ct ( est_log_generico     in out nocopy  dbms_sql.number_table
                           , en_conhectransp_id   in             Conhec_Transp.Id%TYPE
                           );

-------------------------------------------------------------------------------------------------------
-- Função para validar os conhecimentos de transporte - utilizada nas rotinas de validações da GIA, Sped Fiscal e Contribuições
function fkg_valida_ct ( en_empresa_id      in  empresa.id%type
                       , ed_dt_ini          in  date
                       , ed_dt_fin          in  date
                       , ev_obj_referencia  in  log_generico_ct.obj_referencia%type -- processo que acessa a função: sped ou gia
                       , en_referencia_id   in  log_generico_ct.referencia_id%type ) -- identificador do processo que acessar: sped ou gia
         return boolean;

-------------------------------------------------------------------------------------------------------

procedure pkb_ret_multorg_id( est_log_generico       in out nocopy  dbms_sql.number_table
                            , ev_cod_mult_org        in             mult_org.cd%type
                            , ev_hash_mult_org       in             mult_org.hash%type
                            , sn_multorg_id          in out nocopy  mult_org.id%type
                            , ev_obj_referencia      in             log_generico_ct.obj_referencia%type
                            , en_referencia_id       in             log_generico_ct.referencia_id%type
                            );

-------------------------------------------------------------------------------------------------------

-- Procedimento valida o mult org de acordo com o COD e o HASH das tabelas Flex-Field

procedure pkb_val_atrib_multorg ( est_log_generico   in out nocopy  dbms_sql.number_table
                                , ev_obj_name        in             VARCHAR2
                                , ev_atributo        in             VARCHAR2
                                , ev_valor           in             VARCHAR2
                                , sv_cod_mult_org    out            VARCHAR2
                                , sv_hash_mult_org   out            VARCHAR2
                                , ev_obj_referencia  in             log_generico_ct.obj_referencia%type
                                , en_referencia_id   in             log_generico_ct.referencia_id%type
                                );

-------------------------------------------------------------------------------------------------------

procedure pkb_cria_nat_oper( ev_cod_nat         nat_oper.cod_nat%type
                           , ev_descr_nat       nat_oper.descr_nat%type default null
                           , en_multorg_id      mult_org.id%type);

-------------------------------------------------------------------------------------------------------

--| Função retorna o ID da NAT_OPER pelo cod_nat

function fkg_natoper_id_cod_nat ( en_multorg_id in mult_org.id%type
                                , ev_cod_nat    in Nat_Oper.cod_nat%TYPE)
return Nat_Oper.id%TYPE;
-------------------------------------------------------------------------------------------------------
--
-- Procedimento integra o imposto de PIS
-- =================================================================================================================== --
procedure pkb_integr_ctimpout_pis ( est_log_generico              in out nocopy dbms_sql.number_table
                                  , est_row_ct_comp_doc_pis       in out nocopy ct_comp_doc_pis%rowtype
                                  , ev_cpf_cnpj_emit              in            varchar2
                                  , ev_cod_st                     in            cod_st.cod_st%type
                                  , ev_cod_bc_cred_pc             in            base_calc_cred_pc.cd%type
                                  , ev_cod_cta                    in            plano_conta.cod_cta%type
                                  , en_multorg_id                 in            mult_org.id%type );
--
-- Procedimento integra o imposto de CONFINS
-- =================================================================================================================== --
procedure pkb_integr_ctimpout_cofins ( est_log_generico        in out nocopy  dbms_sql.number_table
                                     , est_ct_comp_doc_cofins  in out nocopy  ct_comp_doc_cofins%rowtype
                                     , ev_cpf_cnpj_emit        in             varchar2
                                     , ev_cod_st               in             cod_st.cod_st%type
                                     , ev_cod_bc_cred_pc       in             base_calc_cred_pc.cd%type
                                     , ev_cod_cta              in             plano_conta.cod_cta%type
                                     , en_multorg_id           in             mult_org.id%type );
-- =================================================================================================================== --
--
-------------------------------------------------------------------------------------------------------------------------------------
-- Função para retornar o tipo de emitente dó conhecimento de transporte - conhec_transp.dm_ind_emit = 0-emissão própria, 1-terceiros
-------------------------------------------------------------------------------------------------------------------------------------
function fkg_dmindemit_conhectransp ( en_conhectransp_id in conhec_transp.id%type )
return conhec_transp.dm_ind_emit%type;
--
----------------------------------------------------------------------------
-- Função para verificar se existe registro de erro grvados no Log Generico
----------------------------------------------------------------------------
function fkg_ver_erro_log_generico_ct ( en_conhec_transp_id in conhec_transp.id%type )
return number;
--
end PK_CSF_API_CT;
/
