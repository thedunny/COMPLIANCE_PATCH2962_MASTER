create or replace package csf_own.pk_despr_integr is

------------------------------------------------------------------------------------------
-- Especificação da package de Desprocessar Integração de Dados Fiscais
------------------------------------------------------------------------------------------
--
-- Em 01/02/2021   - Karina de Paula
-- Redmine #75607  - Ajustes na rotina de integração do CTe
-- Rotina Alterada - pkb_despr_conhec_transp => Incluída a verificação se o conhecimento de transporte está inutilizado, se estiver não pode ser excluído
-- Liberado        - Release_2.9.7, Patch_2.9.6.2 e Patch_2.9.5.5
--
-- Em 28/01/2021   - Karina de Paula
-- Redmine #75607  - Ajustes na rotina de integração do CTe
-- Rotina Alterada - pkb_despr_conhec_transp => Incluído o parâmetro de entrada "en_excl_rloteintwsct" na chamada da pk_csf_api_d100.pkb_excluir_dados_ct
--                   com valor "1" para excluir os dados da r_loteintws_ct e retirado o delete direto da r_loteintws_ct
--                 - Incluída a chamada da pk_csf_api_ct.pkb_excluir_dados_ct
--                 - pkb_despr_conhec_transp => Incluída a verificação se o conhecimento de transporte está inutilizado, se estiver não pode ser excluído
--
-- Em 25/01/2021  - Wendel Albino - Patch_2.9.5.4 / Patch_2.9.6-1 / Release_2.9.7
-- Redmine #75210 - Desprocessamento do Registro do Inventário não está implementado para a nova tabela do Módulo Inventário
-- Rotina Alterada- pkb_despr_inventario -> Inclusao de tabela limpeza ( invent_inf_comp_merc_st )
--
-- Em 25/11/2020 - Renan Alves
-- Redmine #73895 - Desprocessamento do Bloco M não funcionou
-- Foi alterado o lugar do delete que realiza o desprocessamento (exclusão) dos registros M300
-- e M700 que ficavam dentro dos cursores de PIS e COFINS.
-- Rotina: pkb_despr_m_pc  
-- Patch_2.9.6.1 / Patch_2.9.5.4 / Release_2.9.7
--
-- Em 07/10/2020 - Renan Alves
-- Redmine #72197 - Desprocessamento do Bloco M não funciona
-- Foi criado o processo de desprocessamento referente ao bloco M.
-- Rotina: pkb_despr_m_pc
-- Patch_2.9.5.1 / Patch_2.9.4.4 / Release_2.9.6
--
-- Em 19/06/2020 - Allan Magrini
-- Redmine #63759  - Chamada para validação de lotes WS de cupom SAT
-- Criado o processo pkb_despr_cupom_fiscal_sat e colocada a chamada na fase 6.1
-- Rotina Alterada: pkb_despr_integr
-- Rotina Criada:   pkb_despr_cupom_fiscal_sat
-- Liberado na versão - Release_2.9.4, Patch_2.9.3.3 e Patch_2.9.2.6
--
-- Em 06/03/2020 - Allan Magrini
-- Redmine #65680 - Desprocessamento de inventário não sendo realizado
-- Alterado no cursor c_inv a validação da data dt_ref pela dt_inventario
-- Rotina Alterada: pkb_despr_inventario
-- Liberado na versão - Release_2.9.3, Patch_2.9.2.3 e Patch_2.9.1.6
--
-- Em 10/02/2020 - Eduardo Linden
-- Redmine #64229 - Correção dos pontos discutidos para integração M300/350
-- Alteração na busca de registros na tabela sobre os periodos considerados. 
-- Eram considerados somente periodo anual, passa a ser considerado o periodo encaminhado no parametro da rotina.
-- Rotina Alterada: pkb_despr_dados_secf  
-- Liberado na versão - Release_2.9.3, Patch_2.9.2.2 e Patch_2.9.1.5   
--
-- Em 24/01/2020 - Luis Marques
-- Redmine #64069 - defeito - precisa ser informado o empresa_id no log_generico
-- Rotina Alterada: pkb_despr_integr - ajustado gravação de log para incluir a empresa para aparecer na tela.
--
-- Em 24/01/2020 - Luis Marques
-- Redmine #63345 - Desprocessamento de integração de Notas com data inválida
-- Rotina Alterada: pkb_despr_integr - Colocada verificação de data final menor que data inicial, caso aconteça
--                  objeto não será desprocessado.
-- 
-- Em 03/01/2020 - Luiz Armando Azoni
-- Redmine #62279 Ajuste na pk_despr_integr pois o nome ficou errado
--
-- Em 27/12/2019 - Luiz Armando Azoni
-- Redmine #62279 criação do processo de exclusao do movimento de estoque e da analise de conversão do isimp
-- Rotina Alterada: pkb_despr_movto_estq E pkb_despr_analiseconveranp
--
-- Em 29/11/2019 - Eduardo Linden
-- Redmine #61877 - Desprocessamento Ativo imobilizado não está sendo executado
-- Alteração no cursor c_imob para utilizar o campo nf_bem_ativo_imob.dt_doc.
-- Rotina Alterada: pkb_despr_cad_geral
--
-- Em 27/11/2019 - Eduardo Linden
-- Redmine #60808 - Implementar processo de desprocessamento de integração
-- Criação de procedimento para desprocessar Cadastros Gerais, inicialmente para Bens do Ativo Imobilizado.
-- Rotina Alterada: pkb_despr_integr
-- Rotina Criada:   pkb_despr_cad_geral
--
-- Em 19/08/2019 - Eduardo Linden
-- Redmine #58483 - Integração dos registros R11, R12 e R14 - DCTF
-- Criação de procedimento para desprocessar Créditos para DCTF
-- Rotina Alterada: pkb_despr_integr
-- Rotina Criada:   pkb_despr_imp_cred_dctf
--
-- === AS ALTERAÇÕES ABAIXO ESTÃO NA ORDEM CRESCENTE USADA ANTERIORMENTE ================================================================================= --
--
-- Em 22/08/2019 - Eduardo Linden
-- Redmine #50987 - Exclusão de Notas Fiscais e CTE vinculados ao REINF
-- Inclusão de validações para os registros de Nota Fiscal e de CTe se estão submetidos aos eventos R2010 e R2020 do Reinf.
-- Rotinas Alteradas: pkb_despr_conhec_transp , pkb_despr_nota_fiscal
--
-- Em 20/08/2019 - Eduardo Linden
-- Redmine #57710 - Criar nova rotina de limpeza - pk_limpa_open_interf.pkb_limpar_empr
-- Inclusão da nova rotina pk_limpa_open_interf.pkb_limpar_empr.
-- Rotina Alterada: pkb_despr_integr
--
-- Em 23/07/2019 - Allan Magrini
-- Redmine #55390 - DIMOB - Erro ao desprocessar período - Data de fechamento
-- Alterado os cursores c_loc, c _constr,  c_venda para pegar o campo de data ano_ref e as validações de data
-- Rotina Alterada: pk_despr_integr.pkb_despr_dimob
--
-- Em 10/07/2019 - Allan Magrini
-- Redmine #55390 - DIMOB - Regra de negócio (Desprocessamento considera data do contrato)
-- Alterada a validação dos cursores para verificar o ano de referência  l.ano_ref between TO_CHAR(ed_dt_ini,'YYYY') and TO_CHAR(ed_dt_fin,'YYYY')
-- Rotina Alterada: pk_despr_integr.pkb_despr_dimob
--
-- Em 02/05/2019 - Marcos Ferreira
-- Redmine #53371 - Desprocessamento indevido.
-- Solicitação: Ao desprocessar as integrações por Multi_org, desprocessar somente as empresas que o usuário tem acesso
-- Procedures Alteradas: Todas
--
-- Em 15/01/2019 - Eduardo Linden
-- Redmine #49826 - Processos de Integração e Validação do Controle de Produção e Estoque - Bloco K.
-- Inclusão na rotina para excluir os registros das tabelas dos novos registros do bloco K (K290, K291, K292, K300, K301 e K302)
-- Rotina Alterada: pkb_despr_contr_prod_estq
--
------------------------------------------------------------------------------------------
--
--| Em 09/04/2012 - Angela Inês.
--| Incluir vn_fase entre os processo de exclusão da nota fiscal - pkb_despr_nota_fiscal.
--
--| Em 23/10/2012 - Angela Inês.
--| Ficha HD 63615 - Processo Ecredac. Incluir rotina para desprocessar as integrações.
--| Rotina: pkb_despr_ecredac.
--
--| Em 21/02/2013 - Angela Inês.
--| Ficha HD 64871 - O log não está sendo gerado devido a falta de informação para o parãmetro EV_MENSAGEM, e da montagem da coluna RESUMO.
--| Rotina: pkb_reg_log_despr_integr.
--
--| Em 14/05/2013 - Angela Inês.
--| Ficha HD 66674 - Integração do Layout do Movimento Contábil com tipo de integração Integrador CSF e em Bloco.
--| Rotina: pkb_monta_rel_dados_contab.
--
--| Em 05/08/2013 - Rogério Silva.
--| Atividade #452
--
-- Em 12/09/2013 - Rogério Silva.
-- Atividade #580 - Implementar procedure pkb_despr_integr.
--
-- Em 19/03/2014 - Angela Inês.
-- Redmine #2047 - Desprocessar a integração - Controle de Produção de Estoque.
--
-- Em 14/07/2014 - Angela Inês.
-- Redmine #3272 - Desprocessar Integração - Compliance.
-- Verificar o desprocessamento das integrações: Tabelas que não estão destacadas para exclusão.
-- 1) Eliminar tabelas do processo Nota_Fiscal, pois as mesmas estão no processo de exclusão da API.
-- Rotinas: pkb_despr_nf_serv_cont, pkb_despr_nota_fiscal e pkb_despr_nf_serv_efd.
-- 2) Incluir as tabelas INF_REND_DIRF_PDF e R_GERA_INF_REND_DIRF no processo DIRF.
-- Rotina: pkb_despr_dirf.
-- 3) Incluir mensagem de erro no log genérico para cada processo, como informação geral.
-- 4) Incluir processo de verificação da data de fechamento.
--
-- Em 17/03/2015 - Angela Inês.
-- Redmine #7031 - Tabela de log para INT_LCTO_CONTABIL.
-- Correção nos processos: incluir exclusão da tabela de log caso o lançamento seja excluído.
-- Rotina: pkb_despr_dados_contab.
--
-- Em 08/06/2015 - Angela Inês.
-- Redmine #8009 - Atividades Administrativas - Execução dos scripts semanais.
-- Correção no nome do parâmetro de entrada devido ao novo processo de LOG_GENERICO.
-- Rotina: pkb_despr_ciap.
--
-- Em 11/06/2015 - Rogério Silva.
-- Redmine #8226 - Processo de Registro de Log em Packages - LOG_GENERICO
--
-- Em 10/09/2015 - Angela Inês.
-- Redmine #11507 - Desprocessar a integração - Notas fiscais Mercantis de Terceiro.
-- 1) Para as notas de terceiro (nota_fiscal.dm_ind_emit=1) que estiverem nas tabelas de consulta: alterar nas tabelas de consulta o identificador da nota para nulo (notafiscal_id = null), e pode excluir a nota.
-- 2) Para as notas de emissão própria (nota_fiscal.dm_ind_emit=0), não podem ser excluídas se o dm_st_proc for 8-inutilizada.
-- Rotina: pk_despr_integr.pkb_despr_nota_fiscal.
--
-- Em 23/10/2015 - Rogério Silva.
-- Redmine #12133 - A FUNÇÃO "DESPROCESSAR" NÃO ESTÁ FUNCIOANDO
-- Rotina: pkb_despr_nota_fiscal
--
-- Em 29/10/2015 - Rogério Silva.
-- Redmine #12552 - NFe emissão própria autorizada somente com dados na tb NOTA_FISCAL (TENDÊNCIA).
--
-- Em 08/02/2016 - Rogério Silva.
-- Redmine #15034 - Desprocessamento de dados da DIRF
--
-- Em 22/02/2016 - Rogério Silva.
-- Redmine #15650 - Alterar desprocessar de nf modelo 99 para remover notas de emissão que não tenham dados no campo NOTA_FISCAL.NFE_PROC_XML.
--
-- Em 22/02/2016 - Fábio Tavares.
-- Redmine #15143 - Criação do procedimento para desprocessar Integração do Bloco I.
--
-- Em 10/03/2016 - Angela Inês.
-- Redmine #16314 - Exclusão de Nota Fiscal de Serviços Contínuos.
-- 1) Eliminado a exclusão do relacionamento do Lote de Integração Web-Service com a Nota Fiscal (tabela R_LOTEINTWS_NF) no processo de Desprocessar a Integração
-- de Notas Fiscais de Serviço Contínuo.
-- Rotina: pk_despr_integr.pkb_despr_nf_serv_cont.
-- 2) Incluído no processo/api de exclusão da nota fiscal, a exclusão do relacionamento do Lote de Integração Web-Service com a Nota Fiscal (tabela R_LOTEINTWS_NF).
-- Rotina: pk_csf_api.pkb_excluir_dados_nf.
-- 3) Eliminar o relacionamento com o processo MDE (nota_fiscal_mde), Consulta de Evento (csf_cons_sit_evento) e Consulta de Situação (csf_cons_sit), somente se
-- a Nota não estiver armazenamento de XML (nota_fiscal.dm_arm_nfe_terc = 0).
-- Rotina: pk_csf_api.pkb_excluir_dados_nf.
--
-- Em 30/03/2016 - Fábio Tavares.
-- Redmine #16875 - Alterar os processos de desprocessar vinculando com os lotes para quando for
-- integrado por WebService
--
-- Em 31/03/2016 - Fábio Tavares.
-- Redmine #16199 - Criação do procedimento para desprocessar a Integração do DIMOB.
-- 1) Criação do metodo pkb_despr_dimob.
--
-- Em 04/04/2016 - Fábio Tavares.
-- Redmine #17134 - Criação do procedimento para desprocessar o Bloco F
-- 1) Criação do metodo pkb_despr_ddo
--
-- Em 06/04/2016 - Rogério Silva.
-- Redmine #17335 - Alterar o procedimento de desprocessamento pra sempre gravar o ID da empresa quando gerar logs.
--
-- Em 08/04/2016 - Fábio Tavares
-- Redmine #17040 - Implementar o metodo de desprocessamento da tabela int_trans_saldo_cont_ant.
-- 1)Alteração do procedimento: pkb_despr_dados_contab.
--
-- Em 02/05/2016 - Angela Inês.
-- Redmine #18392 - Desprocessar a integração - Notas Fiscais Mercantis, de Serviço e Serviço Contínuo.
-- Obs./Leandro: Desprocessar as Notas Fiscais Mercantil, Notas Fiscais de Serviço e Nota Fiscais de Serviço Continuo, que não possuem registro de XML
-- (nota_fiscal.nfe_proc_xml=null), e que a situação (nota_fiscal.dm_st_proc), não esteja como: 0-Não validada, 1-Não Processada. Aguardando Processamento,
-- 2-Processada. Aguardando Envio, 3-Enviada ao SEFAZ. Aguardando Retorno, 14-Sefaz em contingência, 18-Digitada, 19-Processada e 21-Aguardando Liberação.
-- Rotina: pkb_despr_nota_fiscal, pkb_despr_nf_serv_efd e pkb_despr_nf_serv_cont.
--
-- Em 11/10/2016 - Marcos Garcia
-- Redmine #22169 - 7.3 001 ¿ Package de Desprocessar dados integrador na Tabela definitiva.
-- Obs. Tornar de forma dinâmica o desprocessamento dos objetos de integração de forma completa, ou seja,
-- desprocessando os mesmos das tabelas fixas quanto das tabelas VW's.
--
-- Em 19/10/2016 - Marcos Garcia
-- Redmine #21380 - Package de Desprocessar Integração ¿pk_despr_integr¿ ¿ PL/SQL
-- Obs. Incluir na chamada da rotina principal "pkb_despr_integr" mais um argumento
-- especificando qual o tipo do objeto a ser desprocessado, no caso do mesmo ser nulo
-- contina a desprocessar o objeto inteiro.
--
-- Em 22/11/2016 - Leandro Savenhago
-- Redmine #25633 - NFS-e de emissao propria sumiu da base de dados após realizar desprocessamento (Aceco)
-- 1) Alterado a rotina "pkb_despr_nf_serv_efd" para não excluir as NFSe com "lote de nfs"
--
-- Em 07/12/2016 - Fábio Tavares
-- Redmine #26078 - Alteração do desprocessamento do Objeto de Integração de Notas Fiscais de Serviços EFD
-- Rotina: pkb_despr_nf_serv_efd
--
-- Em 03/01/2017 - Marcos Garcia
-- Redmine #26456 - Desprocessamento da Integração
-- Rotina: pkb_despr_integr, adicionado mais um parâmetro na chamada da rotina para verificar o desprocessamento total do objeto.
--
-- Em 25/01/2017 - Fábio Tavares
-- Redmine #27345 - Procedimento de Desprocessar Integração de Dados
-- Descrição: Foram feitos as alterações nos processos conforme solicitado na ficha, tanto para o objeto de integração
-- 6-Nota Fiscal Mercantil quanto para o 46-Pagamento de Impostos Retidos Padrão DCTF. Foi feito também os testes básicos de cada processo.
--
-- Em 01/02/2017 - Marcos Garcia
-- Redmine #27236 - Procedimento para desprocessar integração de dados.
--                - Adicionado uma condição para que as notas sejam desprocessadas, verifica se a mesma contem vínculo
--                - com a tabela de que guarda os detalhe da geração de informações sobre exportação.
--
--
-- Em 18/02/2017 - Fábio Tavares
-- Redmine #28411 -  211b_pk_despr_integr - Erro de Ortografia no Log
--
-- Em 01/03/2017 - Leandro Savenhago
-- Redmine 28832- Implementar o "Parâmetro de Formato de Data Global para o Sistema".
-- Implementar o "Parâmetro de Formato de Data Global para o Sistema".
--
-- Em 05/04/2017 - Angela Inês.
-- Redmine #29993 - Alteração nos processos: Agrupamento de dados e Desprocessamento de Integração.
-- Incluir na mensagem que indica que a Nota de Débito não pode ser excluída, a informação de que a Nota de Débito está vinculada com a geração dos créditos de
-- PIS e COFINS.
-- Rotina: pkb_despr_nf_serv_efd.
--
-- Em 17/05/2017 - Angela Inês.
-- Redmine #31156 - Melhoria na mensagem de desprocessamento de NF que tem vinculo com a geração de informação de exportação.
-- O processo estava desatualizando o processo de consulta de nota fiscal de destinatário, e o processo de download de XML, antes de verificar se a nota
-- estava vinculada com Impostos Retidos e Informações sobre Exportações. Foi corrigido o processo para que seja verificado se a nota está vinculada com Impostos
-- Retidos e Informações sobre Exportações, e depois seguir com o processo de desatualizar a consulta de nota fiscal de destinatário, anular o download de XML,
-- e assim a exclusão da nota fiscal.
-- Rotina: pkb_despr_nota_fiscal.
--
-- Em 13/06/2017 - Marcos Garcia
-- Inserido a constante info_fechamento, para registrar o tipo de log de fechamento fiscal
--
-- Em 14/06/2017 - Fábio Tavares
-- Redmine: #32037 - Desenvolver o Desprocessamento da Integração do SPED ECF
-- Rotina: pkb_despr_dados_secf.
--
-- Em 11/10/2017 - Fábio Tavares
-- Redmine: #33862 - Integração Complementar de NFS para o Sped Reinf - Desprocessamento de Integração
-- Rotina: pkb_despr_dados_reinf.
--
-- Em 06/11/2017 - Fábio Tavares
-- Redmine: #36117 - Ajustes na tabela de Parâmetro da Empresa para o REINF
-- Rotina: pkb_despr_dados_reinf.
--
-- Em 22/01/2018 - Angela Inês.
-- Redmine #38740 - Correção nos processos de Informação Sobre Exportação - Recuperação dos registros.
-- Alterar os objetos que utilizam a tabela de Informação Sobre Exportação e considerar a DATA DE AVERBAÇÃO (DT_AVB) ao invés de considerar a DATA DA
-- DECLARAÇÃO (DT_DE), para recuperação dos registros.
-- Rotina: pkb_despr_infexp.
--
-- Em 24/01/2018 - Angela Inês.
-- Redmine #38809 - Alteração nos processos de Integração e Desprocessamento de Integração - Informações sobre Exportação - Data de Averbação.
-- No processo de Desprocessamento, considerar a data de averbação para comparar com a data de fechamento fiscal.
-- Rotina: pkb_despr_infexp.
--
-- Em 24/01/2018 - Leandro Savenhago.
-- Redmine #37007 - Erro ao desprocessar integração de nota de WebService (Vopak - Amazon)
-- Rotina: pkb_despr_nf_serv_cont.
--
-- Em 12/02/2018 - Marcelo Ono
-- Redmine #39287 - Implementação da limpeza da tabela "PIR_INFO_EXT", no processo que desprocessa o Pagamento de Impostos no padrão para DCTF.
-- Rotina: pkb_despr_pgto_imp_ret.
--
-- Em 23/04/2018 - Marcelo Ono
-- Redmine #38773 - Correção no desprocessamento de comercialização de produção por produtor rural do Reinf.
-- Rotina: pkb_despr_reinf.
--
-- Em 25/04/2018 - Karina de Paula
-- Redmine #41878 - Novo processo para o registro Bloco F100 - Demais Documentos e Operações Geradoras de Contribuições e Créditos.
-- Incluída a verificação do campo dm_gera_receita = 1, nos objetos abaixo:
-- Rotina Alterada: pkb_despr_ddo
--
-- Em 20/06/2018 - Angela Inês.
-- Redmine #43888/#43894 - Desenvolver Rotina Programável - F100/F700 - Receita POC e Receita Financeira.
-- Procedimento para gravar o log/alteração dos Demais Documentos e Operações Geradoras de Contribuição e Créditos - Bloco F100, e de Deduções Diversas - Bloco F700.
-- Rotina: pkb_despr_ddo.
--
-- Em 06/07/2018 - Karina de Paula
-- Redmine #44759 - Melhoria Apuração PIS/COFINS - Bloco F100
-- Rotina Alterada: pkb_despr_ddo => Retirada a verificação dm_gera_receita
--
-- Em 09/10/2018 - Angela Inês.
-- Redmine #47697 - Correção na exclusão dos Blocos F - Processo de Desprocessamento da Integração.
-- 1) Blocos F100 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_demdocopcc).
-- 2) Blocos F120 e F130 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_bematmobpc).
-- 3) Blocos F150 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_cpeabertpc).
-- 4) Blocos F200 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_oaimobvend).
-- 5) Blocos F500 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_coipcrc).
-- 6) Blocos F510 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_coipcrcaum).
-- 7) Blocos F525 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_crdrc).
-- 8) Blocos F550 - Excluir os registros vinculados com os Lotes WebService e Processo Referenciado (r_loteintws_coircomp, pr_cons_op_ins_pc_rcomp).
-- 9) Blocos F560 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_coircompaum).
-- 10) Blocos F600 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_crfpc).
-- 11) Blocos F700 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_deddpc).
-- 12) Blocos F800 - Excluir os registros vinculados com os Lotes WebService (r_loteintws_cdepc).
-- 13) Considerar o Tipo de Objeto de Integração "2-Bens Incorp.At.Imob.-Oper.Gerad.Créd.base", para excluir os registros dos Blocos F120 e F130.
-- Rotina: pkb_despr_ddo.
--
-- Em 23/10/2018 - Karina de Paula
-- Redmine #39990 - Adpatar o processo de geração da DIRF para gerar os registros referente a pagamento de rendimentos a participantes localizados no exterior
-- Rotina Alterada: pkb_despr_dirf => Incluído delete da inf_rend_dirf_rpde
--
--
------------------------------------------------------------------------------------------

   informacao        constant number := 35; -- Informação Geral
   info_fechamento   constant number := 39; -- fechamento fiscal
   erro_de_sistema     constant number := 2;
   gn_multorg_id     mult_org.id%type;
   gn_objintegr_id   obj_integr.id%type := 0;
   gn_empresa_id     empresa.id%type;
   --
   gv_cd_tipo_obj_integr tipo_obj_integr.cd%type;
   gv_formato_data       param_global_csf.valor%type := null;
   vv_resumo          log_generico.resumo%type;

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Inventário
procedure pkb_despr_inventario ( en_empresa_id   in empresa.id%Type
                               , en_usuario_id   in neo_usuario.id%type
                               , ed_dt_ini       in date
                               , ed_dt_fin       in date
                               );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Cupom Fiscal
procedure pkb_despr_cupom_fiscal ( en_empresa_id   in empresa.id%Type
                                 , en_usuario_id   in neo_usuario.id%type
                                 , ed_dt_ini       in date
                                 , ed_dt_fin       in date
                                 );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar o conhecimento de transporte de Terceiros
procedure pkb_despr_conhec_transp ( en_empresa_id   in empresa.id%Type
                                  , en_usuario_id   in neo_usuario.id%type
                                  , ed_dt_ini       in date
                                  , ed_dt_fin       in date
                                  );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Nota Fiscal de Serviço Contínuo
procedure pkb_despr_nf_serv_cont ( en_empresa_id   in empresa.id%Type
                                 , en_usuario_id   in neo_usuario.id%type
                                 , ed_dt_ini       in date
                                 , ed_dt_fin       in date
                                 );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Nota Fiscal Mercantil
procedure pkb_despr_nota_fiscal ( en_empresa_id   in empresa.id%Type
                                , en_usuario_id   in neo_usuario.id%type
                                , ed_dt_ini       in date
                                , ed_dt_fin       in date
                                );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Nota Fiscal Serviço EFD
procedure pkb_despr_nf_serv_efd ( en_empresa_id   in empresa.id%Type
                                , en_usuario_id   in neo_usuario.id%type
                                , ed_dt_ini       in date
                                , ed_dt_fin       in date
                                );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar o DIMOB
procedure pkb_despr_dimob ( en_empresa_id in empresa.id%type
                          , en_usuario_id in neo_usuario.id%type
                          , ed_dt_ini     in date
                          , ed_dt_fin     in date
                          );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar o IBIPC
procedure pkb_despr_ibipc ( en_empresa_id in empresa.id%type
                          , en_usuario_id in neo_usuario.id%type
                          , ed_dt_ini     in date
                          , ed_dt_fin     in date
                          );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar CIAP
procedure pkb_despr_ciap ( en_empresa_id   in empresa.id%Type
                         , en_usuario_id   in neo_usuario.id%type
                         , ed_dt_ini       in date
                         , ed_dt_fin       in date
                         );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar o Bloco F

procedure pkb_despr_ddo ( en_empresa_id   in empresa.id%Type
                        , en_usuario_id   in neo_usuario.id%type
                        , ed_dt_ini       in date
                        , ed_dt_fin       in date
                        );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar eCredac
procedure pkb_despr_ecredac ( en_empresa_id   in empresa.id%Type
                            , en_usuario_id   in neo_usuario.id%type
                            , ed_dt_ini       in date
                            , ed_dt_fin       in date
                            );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Dados Contábeis
procedure pkb_despr_dados_contab ( en_empresa_id   in empresa.id%Type
                                 , en_usuario_id   in neo_usuario.id%type
                                 , ed_dt_ini       in date
                                 , ed_dt_fin       in date
                                 );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Produção Diaria de Usina
procedure pkb_despr_pdu ( en_empresa_id   in empresa.id%Type
                        , en_usuario_id   in neo_usuario.id%type
                        , ed_dt_ini       in date
                        , ed_dt_fin       in date
                        );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar MANAD
procedure pkb_despr_manad ( en_empresa_id   in empresa.id%Type
                          , en_usuario_id   in neo_usuario.id%type
                          , ed_dt_ini       in date
                          , ed_dt_fin       in date
                          );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Informações de Valores Agregados
procedure pkb_despr_iva ( en_empresa_id   in empresa.id%Type
                        , en_usuario_id   in neo_usuario.id%type
                        , ed_dt_ini       in date
                        , ed_dt_fin       in date
                        );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Controle de Creditos Fiscais de ICMS
procedure pkb_despr_cf_icms ( en_empresa_id   in empresa.id%Type
                            , en_usuario_id   in neo_usuario.id%type
                            , ed_dt_ini       in date
                            , ed_dt_fin       in date
                            );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Total de operações com cartão
procedure pkb_despr_tot_op_cart ( en_empresa_id   in empresa.id%Type
                                , en_usuario_id   in neo_usuario.id%type
                                , ed_dt_ini       in date
                                , ed_dt_fin       in date
                                );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar DIRF
procedure pkb_despr_dirf ( en_empresa_id   in empresa.id%Type
                         , en_usuario_id   in neo_usuario.id%type
                         , ed_dt_ini       in date
                         , ed_dt_fin       in date
                         );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Pagamento de Impostos no padrão para DCTF
procedure pkb_despr_pgto_imp_ret ( en_empresa_id   in empresa.id%Type
                                 , en_usuario_id   in neo_usuario.id%type
                                 , ed_dt_ini       in date
                                 , ed_dt_fin       in date
                                 );

------------------------------------------------------------------------------------------

-- Procedimento para desprocessar Créditos para DCTF
procedure pkb_despr_imp_cred_dctf ( en_empresa_id in empresa.id%Type
                                  , en_usuario_id in neo_usuario.id%type
                                  , ed_dt_ini     in date
                                  , ed_dt_fin     in date
                                  );

------------------------------------------------------------------------------------------

--| Procedimento para desprocessar Controle da Produção e do Estoque
procedure pkb_despr_contr_prod_estq ( en_empresa_id   in empresa.id%Type
                                    , en_usuario_id   in neo_usuario.id%type
                                    , ed_dt_ini       in date
                                    , ed_dt_fin       in date
                                    );

------------------------------------------------------------------------------------------
-- Procedimento para desprocessar as informações do Sped ECF
------------------------------------------------------------------------------------------
procedure pkb_despr_dados_secf ( en_empresa_id in empresa.id%type
                               , en_usuario_id in neo_usuario.id%type
                               , ed_dt_ini     in date
                               , ed_dt_fin     in date
                               );

------------------------------------------------------------------------------------------
-- Procedimento para desprocessar a informação de exportação
------------------------------------------------------------------------------------------
procedure pkb_despr_infexp ( en_empresa_id in empresa.id%type
                           , en_usuario_id in neo_usuario.id%type
                           , ed_dt_ini     in date
                           , ed_dt_fin     in date
                           );

------------------------------------------------------------------------------------------
-- Procedimento para desprocessar a informação dos Cadastros Gerais
------------------------------------------------------------------------------------------
procedure pkb_despr_cad_geral ( en_empresa_id in empresa.id%Type
                              , en_usuario_id in neo_usuario.id%type
                              , ed_dt_ini     in date
                              , ed_dt_fin     in date 
                              );

------------------------------------------------------------------------------------------
-- Procedimento para desprocessar o Bloco M
------------------------------------------------------------------------------------------
procedure pkb_despr_m_pc(en_empresa_id in empresa.id%Type,
                         en_usuario_id in neo_usuario.id%type,
                         ed_dt_ini     in date,
                         ed_dt_fin     in date); 
                         
------------------------------------------------------------------------------------------

procedure pkb_despr_integr ( en_empresa_id   in empresa.id%type
                           , en_usuario_id   in neo_usuario.id%type
                           , en_objintegr_id in obj_integr.id%type
                           , en_tipoobjintegr_id in tipo_obj_integr.id%type
                           , en_opcao        in number
                           , ed_dt_ini       in date
                           , ed_dt_fin       in date
                           , en_desp_total   in number);

------------------------------------------------------------------------------------------

procedure pkb_despr_movto_estq(en_empresa_id in empresa.id%Type
                             , en_usuario_id in neo_usuario.id%type
                             , ed_dt_ini     in date
                             , ed_dt_fin     in date);
-----------------------------------------------------------------------------------------
procedure pkb_despr_analiseconveranp(en_empresa_id in empresa.id%Type
                                   , en_usuario_id in neo_usuario.id%type
                                   , ed_dt_ini     in date
                                   , ed_dt_fin     in date);
-----------------------------------------------------------------------------------------
end pk_despr_integr;
/
