create or replace package csf_own.pk_int_view_cad is

-------------------------------------------------------------------------------------------------------
--| Especificação do pacote de procedimentos de integração e validação de Cadastros
--
-- Em 04/02/2021   - Wendel Albino - patch 2.9.5.5 / 2.9.6-2 e release 297
-- Redmine #75771  - Verificar agendamento de integração SPANI 
-- Rotina Alterada - pkb_integr_cad_geral / pkb_integr_empresa_geral ->inclusao nos sleects de multorg com rownum (nro_linhas) 
--                 -  para nao executar mais de uma vez as procedures por multiorg.
--
-- Em 10/07/2020 - Wendel Albino
-- Redmine #68319/68800 - Erros de agendamento de Integração 
-- Rotina Alterada - pkb_integracao_normal/ pkb_integracao, inclusao de parametro de entrada com nro_linhas (en_nro_linhas) para nao executar mais de uma vez procedures por multiorg.
--
-- Em 11/02/2020 - Eduardo Linden
-- Redmine #64760 - Verificar repositório - Atividade #52790
-- Correção na type tab_csf_aglut_contabil. O campo ar_cod_agl passou de varchar2(2) para varchar2(30).
-- Rotina afetada: pkb_aglut_contabil
--
-- Em 22/01/2020   - Allan Magrini
-- Redmine #48957 - Inclusão do campo de Valor do Diferencial de Alíquota em Informações dos Itens dos Documentos Fiscais do Bem.
-- Adicionada ev_valor in out na fase 61 validação atributo VL_DIF_ALIQ -- fase 3.3 adicionando na pk_csf_api_cad.pkb_integr_itnf_bem_ativo_imob o campo ev_valor
-- Rotina Alterada -  pkb_itnf_bem_ativo_imob_ff, pkb_itnf_bem_ativo_imob
--
-- Em 09/10/2019        - Karina de Paula
-- Redmine #52654/59814 - Alterar todas as buscar na tabela PESSOA para retornar o MAX ID
-- Rotinas Alteradas    - Trocada a função pk_csf.fkg_cnpj_empresa_id pela pk_csf.fkg_empresa_id_cpf_cnpj
-- NÃO ALTERE A REGRA DESSAS ROTINAS SEM CONVERSAR COM EQUIPE
--
-- ===== ABAIXO ESTÁ EM ORDEM ANTIGA CRESCENTE ========================================================================== --
--
-- Em 03/05/2011 - Angela Inês.
-- Incluído processo de item de marca comercial.
--
-- Em 23/04/2012 - Angela Inês.
-- Alterar a coluna inscr_prod para tamanho de 15.
--
-- Em 29/11/2012 - Angela Inês.
-- Ficha HD 64680 - Eliminar caracteres especiais para integração dos campos: cnpj, cpf e ie.
-- Rotinas: pkb_pessoa.
--
-- Em 11/01/2013 - Vanessa N F Ribeiro.
-- Ficha HD 65502 - Integração de novos campos de complemnto do item .
--
-- Em 20/03/2013 - Angela Inês.
-- Ficha HD 66478 - Integração individual não recupera os dados da empresa referente a banco de dados (dblink, etc.).
-- Rotinas: pkb_hist_padrao, pkb_centro_custo, pkb_plano_conta, pkb_bem_ativo_imob e pkb_item.
--
-- Em 23/05/2013 - Angela Inês.
-- Incluir ordenação por cpf_cnpj, cod_cta e dt_inc_alt, para recuperação dos dados de planos de contas.
-- Rotina: pkb_plano_conta.
--
-- Em 12/07/2013 - Angela Inês.
-- Incluir os parâmetros de data inicial e final para a execução da integração dos cadastros gerais.
-- Rotina: pkb_integracao.
-- Incluir a rotina para geração de dados dos bens imobilizados.
-- Rotina: pkb_softfacil.
--
-- Em 18/07/2013 - Angela Inês.
-- Correção na integração de cadastro de BENS, ordenando por DM_IDENT_MERC, para que recuperem primeiro os códigos que são BENS e depois os COMPONENTES.
-- Rotina: pkb_bem_ativo_imob.
--
-- Em 22/07/2013 - Rogério Silva.
-- RedMine #399
-- Rotinas: pkb_bem_ativo_imob e criação da pkb_bem_ativo_imob_compl
--
-- Em 24/07/2013 - Rogério Silva.
-- RedMine #398
-- Criação dos procedimentos: pkb_grupo_pat, pkb_subgrupo_pat e pkb_rec_imp_subgrupo_pat
--
-- Em 25/07/2013 - Rogério Silva.
-- RedMine #401
-- Criação dos procedimentos: pkb_itnf_bem_ativo_imob e pkb_itnf_bem_ativo_imob.
--
-- Em 26/07/2013 - Rogério Silva.
-- RedMine #400
-- Criação do procedimento: pkb_rec_imp_bem_ativo_imob.
--
-- Em 30/07/2013 - Rogério Silva.
-- RedMine #490
-- * Alteração do procedimento: pkb_bem_ativo_imob, foi incluido a chamada da rotina que verifica se integrou a informação da utilização do bem.
-- * Adicionado o campo COD_CCUS no procedimento pkb_subgrupo_pat.
--
-- Em 31/07/2013 - Rogério Silva.
-- RedMine #490
-- * Alteração do procedimento: pkb_bem_ativo_imob, foi incluido a chamada da rotina que verifica se integrou os impostos do bem.
--
-- Em 09/08/2013 - Angela Inês.
-- Correção na mensagem do processo de geração de dados do SGI para integração dos bens do ativo imobilizado.
--
-- Em 03/03/2014 - Angela Inês.
-- Redmine #2043 - Alterar a API de integração de cadastros incluindo o cadastro de Item componente/insumo.
--
-- Em 17/03/2014 - Angela Inês.
-- Alterar a API de integração de cadastros incluindo o cadastro de Item componente/insumo em todos os processos de integração.
--
-- Em 07/08/2014 - Angela Inês.
-- Redmine #3712 - Correção nos processos - Eliminar o comando dbms_output.put_line.
--
-- Em 26/09/2014 - Rogério Silva
-- Redmine #4067 - Processo de contagem de registros integrados do ERP (Agendamento de integração)
-- Rotinas: pkb_pessoa, pkb_unidade, pkb_item, pkb_integracao, pkb_integracao_normal, pkb_integr_cad_geral e pkb_integr_empresa_geral.
--
-- Em 16/10/2014 - Rogério Silva
-- Redmine #4067 - Processo de contagem de registros integrados do ERP (Agendamento de integração)
--
-- Em 21/10/2014 - Rogério Silva
-- Redmine #4864 - Alterar tamanho máximo da coluna "NRO" do vetor referente a "PESSOA" na integração de cadastros
--
-- Em 21/10/2014 - Rogério Silva
-- Redmine #4067 - Processo de contagem de registros integrados do ERP (Agendamento de integração)
--
-- Em 05/11/2014 - Rogério Silva
-- Redmine #5020 - Processo de contagem de registros integrados do ERP (Agendamento de integração)
--
-- Em 24/11/2014 - Leandro Savenhago
-- Redmine #5298 - Adequação da PK_INT_VIEW_CAD para Mult-Organização
-- Alterações:
--
-- Em 28/11/2014 - Rogério Silva
-- Redmine #5367 - Adequação da PK_INT_VIEW_CAD para Mult-Organização
-- Alterações referente a grupos de patrimônio
--
-- Em 01/11/2014 - Rogério Silva
-- Redmine #5367 - Adequação da PK_INT_VIEW_CAD para Mult-Organização
-- Alterações referente a Bens do ativo imobilizado
--
-- Em 02/11/2014 - Rogério Silva
-- Redmine #5367 - Adequação da PK_INT_VIEW_CAD para Mult-Organização
-- Adaptação dos processos de Natureza da Operação, Informações complementares do documento fiscal,
-- e Observação do lançamento fiscal para o multorg e web-service
--
-- Em 05/11/2014 - Rogério Silva
-- Redmine #5367 - Adequação da PK_INT_VIEW_CAD para Mult-Organização
-- Troca de chamada de procedures de ecd para cad: pkb_integr_Plano_Conta, pkb_integr_pc_referen, pkb_integr_Centro_Custo
--
-- Em 26/12/2014 - Angela Inês.
-- Atualização das versões das variáveis de contadores com processo Mult-Organização.
--
-- Em 06/01/2015 - Angela Inês.
-- Redmine #5616 - Adequação dos objetos que utilizam dos novos conceitos de Mult-Org.
--
-- Em 25/02/2015 - Angela Inês.
-- Redmine #6577 - Erro Suframa.
-- Corrigir a integração de PESSOA: utilizar a fkg_converte, replace(',','.','-','/') por nulo, e recuperar 9 caracteres.
-- Rotina: pkb_pessoa.
--
-- Em 25/02/2015 - Rogério Silva.
-- Redmine #6314 - Analisar os processos na qual a tabela UNIDADE é utilizada.
--
-- Em 19/03/2015 - Rogério Silva.
-- Redmine #6315 - Analisar os processos na qual a tabela EMPRESA é utilizada.
-- Adicionado o multorg_id na recuperação de dados da empresa conforme cnpj/cpf
-- Rotina: pkb_dados_bco_empr.
--
-- Em 23/04/2015 - Angela Inês.
-- Redmine #7784 - Erro Integração Cadastro (COOPERB).
-- Problema: Na view de integração o código do Item está vindo com caractere especial ficando: 'DEMONSTRAC?O'.
-- No Compliance esse item já está cadastrado como: 'DEMONSTRA\00C7\00C3O'.
-- Na leitura para identificar se o código já existe no Compliance os caracteres não são eliminados, e ao gravar sim, por isso o erro de UK.
-- 1) Passamos a informar o código do item a ser integrado na rotina pk_int_view_cad.pkb_item, quando houver erro no processo.
--
-- Em 03/12/2015 - Rogério Silva.
-- Redmine #13378 - Corrigir procedimento de integração de cadastros
--
-- Em 15/12/2015 - Leandro Savenhago.
-- Redmine #11501 - Agendamento de integração do tipo "Empresa logada" apenas funciona para empresas de mult org padrão (cd = 1)
-- Rotina: pkb_integracao.
-- Alterado para passar como parâmetro o ID da empresa em vez do CNPJ
--
-- Em 15/12/2015 - Leandro Savenhago.
-- Redmine #13481 - [CADASTRO] DM_TIPO_PESSOA = 2 'EXTERIOR'
-- Rotina: pkb_pessoa.
-- Realizado o teste para verificar se os dados do CPF_CNPJ são numericos
--
-- Em 06/04/2016 - Fábio Tavares
-- Redmine #17036 - Foi feita a Integração de Subcontas Correlatas.
--
-- Em 24/06/2016 - Angela Inês.
-- Redmine #20644 - Integração de Cadastros Gerais - Bem do Ativo Imobilizado.
-- Alterar os processos de integração dos campos FlexField/Série que comparam se o campo está Nulo.
-- Rotina: pkb_itnf_bem_ativo_imob_ff e pkb_nf_bem_ativo_imob_ff.
--
-- Em 09/08/2016 - Angela Inês.
-- Redmine #22231 - Correção na integração do ITEM - Campos Mult-Org - Flex-Field.
-- Não considerar os campos de mult-org, COD_MULT_ORG e HASH_MULT_ORG, para integração do ITEM.
-- Rotina: pkb_ler_item_ff.
--
-- Em 28/12/2016 - Fábio Tavares.
-- Redmine #26707 - Ajuste na Integração de ITEM de Insumo, que passou a ser filho do ITEM.
-- Rotina: pkb_ler_item, pkb_ler_item_insumo.
--
-- Em 06/01/2017 - Angela Inês.
-- Redmine #27030 - Na integração do item insumo está exigindo o NCM.
-- Alterar no processo de integração de Item Insumo o objeto de referência para os logs de inconsistência. Utilizar "ITEM_INSUMO'.
-- Rotina: pkb_item_insumo.
--
-- Em 19/01/2017 - Angela Inês.
-- Redmine #27547 - Correção na integração de Item - Campos FlexField.
-- Identificar se a view de integração está ativa para integração dos dados (checagem na tabela obj_util_integr.dm_ativo).
-- Rotina: pkb_ler_item_ff.
--
-- Em 15/02/2017
-- Redmine #27870 - Implementar a integração Table/View de Cadastros, package PK_INT_VIEW_CAD,
-- os procedimentos de leiaute e chamada da integração para os tipos VW_CSF_PARAM_ITEM_ENTR e VW_CSF_PARAM_OPER_FISCAL_ENTR.
-- Rotina : pkb_ler_item_fornc_eu
--
-- Em 21/02/2017 - Fábio Tavares.
-- Redmine #28581 - Unidade a ser convertida (**) esta invalida. (Sal Cisne)
-- Rotina: pkb_conv_unid
--
-- Em 01/03/2017 - Leandro Savenhago
-- Redmine 28832- Implementar o "Parâmetro de Formato de Data Global para o Sistema".
-- Implementar o "Parâmetro de Formato de Data Global para o Sistema".
--
-- Em 15/03/2017 - Angela Inês.
-- Redmine #29359 - Correção na Integração de Cadastros - Função de conversão de caracteres.
-- Alterar em todos os processos de integração de cadastro, eliminando a função de conversão de caracteres (pk_csf.fkg_converte), nas condições (where).
-- Rotinas: todas.
--
-- Em 16/03/2017 - Fábio Tavares.
-- Redmine #29332 - Integração de Centro de Custo( Foi retirado a função do fkg_converte dos processos de integração da flex-field )
--
-- Em 06/04/2017 - Fábio Tavares
-- Redmine #27483 - Melhorias referentes ao plano de contas referencial
-- Relacionado ao Periodo de Referencia de um plano de conta e centro de custo da empresa para o plano de conta do ECD.
--
--  Em 13/04/2017 - Melina carniel
-- Redmine #30177 - Alteração do campo DESCRIÇÃO do ITEM/Produto
-- Alterar o tamanho do campo DESCR_ITEM na view de integração VW_CSF_ITEM: de Varchar2 (60), para Varchar2 (120).
--
-- Em 26/05/2017 - Fábio Tavares
-- Redmine #31472 - INTEGRAÇÃO AGLUTINAÇÃO CONTÁBIL
--
-- Em 23/06/2017 - Marcos Garcia
-- Redmine #32113 - Alterar o processo de integração de cadastro: PK_INT_VIEW_CAD.
-- Por conta da alteração na felx-field VW_CSF_PC_REFEREN_FF, o processo de integração, agora, irá
-- contar com o campo cod_ccus para a recuperação dos dados.
--
--  Em 30/06/2017 - Leandro Savenhago
-- Redmine #31839 - CRIAÇÃO DOS OBJETOS DE INTEGRAÇÃO - STAFE
-- Criação do Procedimento PKB_STAFE
--
-- Em 22/08/2017 - Fábio Tavares
-- Redmine #33792 - Integração de Cadastros para o Sped Reinf - Integração INT_VIEW 
--
-- Em 26/09/2017 - Marcos Garcia
-- Redmine 34961 - Alteração de campo das views
-- Alterado todos os campos cod_ind_bem para 60 caracteres.
--
-- Em 10/10/2017 - Marcelo Ono
-- Redmine #34945 - Correção na integração de Plano de Contas
-- Incluído a ordenação por nível de plano de conta crescente, garantindo que os planos de contas superiores sejam cadastrados antes dos planos contas filhos. 
-- Rotina: pkb_plano_conta
--
-- Em 02/02/2018 - Angela Inês.
-- Redmine #39021 - Processo de Agendamento de Integração - alteração nos processos do tipo Todas as Empresas.
-- Na tela/portal do agendamento, quando selecionamos o campo "Tipo" como sendo "Todas as empresas" (agend_integr.dm_tipo=3), o processo de agendamento
-- (pk_agend_integr.pkb_inicia_agend_integr), executa a rotina pk_agend_integr.pkb_inicia_agend_integr/pkb_agend_integr_csf.
-- Utilizando esse processo, incluir nas rotinas relacionadas a cada objeto de integração, o processo criado para o cliente Usina Santa Fé, rotina com o nome
-- padrão "PKB_STAFE". Essa rotina está sendo utilizada nas integrações, porém quando o agendamento é feito por empresa (agend_integr.dm_tipo=1).
-- Com essa mudança a integração passará a ser feita também para a opção de "Todas as empresas".
-- Rotina: pkb_integr_cad_geral.
--
-- Em 07/02/2018 - Marcelo Ono
-- Redmine 38773 - Correções e implementações nos processos do REINF.
-- 1- Corrigido as mensagens de logs nas rotinas de integração do processo administrativo/judiciário do EFD Reinf;
-- Rotina: pkb_ler_proc_adm_efd_reinf, pkb_ler_proc_adm_efd_reinf_ff, pkb_ler_procadmefdreinfinftrib.
--
-- Em 12/02/2018 - Marcelo Ono
-- Redmine #39282 - Implementado a Integração de Informações de pagamentos de impostos retidos/SPED REINF.
-- Rotina: pkb_pessoa, pkb_pessoa_info_pir.
--
-- Em 19/03/2018 - Angela Inês.
-- Redmine #40695 - Correção na integração de Bens do Ativo Imobilizado - Cadastros Gerais.
-- Considerar as informações de Código do Bem eliminando os caracteres especiais da mesma forma que é utilizado no Integração de CIAP.
-- Rotinas: pkb_bem_ativo_imob, pkb_bem_ativo_imob_ff, pkb_infor_util_bem, pkb_infor_util_bem_ff, pkb_bem_ativo_imob_compl e pkb_bem_ativo_imob_compl_ff.
-- Rotinas: pkb_nf_bem_ativo_imob, pkb_nf_bem_ativo_imob_ff, pkb_itnf_bem_ativo_imob, pkb_itnf_bem_ativo_imob_ff e pkb_rec_imp_bem_ativo_imob.
-- Rotina: pkb_rec_imp_bem_ativo_imob_ff.
--
-- Em 21/03/2018 - Angela Inês.
-- Redmine #40795 - Correção na Integração de Cadastro do BEM/Gerais e Integração do CIAP.
-- Deixar a Integração do Cadastro do BEM não considerando a função FKG_CONVERTE na coluna COD_IND_BEM, em todas as views de integração.
-- Rotinas: pkb_bem_ativo_imob, pkb_bem_ativo_imob_ff, pkb_infor_util_bem, pkb_infor_util_bem_ff, pkb_bem_ativo_imob_compl e pkb_bem_ativo_imob_compl_ff.
-- Rotinas: pkb_nf_bem_ativo_imob, pkb_nf_bem_ativo_imob_ff, pkb_itnf_bem_ativo_imob, pkb_itnf_bem_ativo_imob_ff e pkb_rec_imp_bem_ativo_imob.
-- Rotina: pkb_rec_imp_bem_ativo_imob_ff.
--
-- Em 18/05/2018 - Angela Inês.
-- Redmine #42611 - Processo de Integração de Cadastro - Monitoramento.
-- Executar o processo do Cliente Usina Santa Fé apenas uma vez no processo de Integração para todas as empresas.
-- Rotina: pkb_integr_cad_geral.
--
-- Em 28/06/2018 - Angela Inês.
-- Redmine #44509 - Incluir a coluna de percentual de rateio de item nos parâmetros da DIPAM-GIA.
-- 1) Incluir no documento de leiaute de Integração de Cadastro a coluna de percentual de rateio de item, PERC_RATEIO_ITEM, nos parâmetros da DIPAM-GIA.
-- 2) Alterar o processo de Integração e Validação dos Cadastros Gerais, incluindo a coluna de percentual de rateio de item, PERC_RATEIO_ITEM, nos parâmetros da DIPAM-GIA.
-- Rotina: pkb_ler_param_dipamgia.
--
-- Em 19/09/2018 - Marcos Ferreira
-- Redmine #46825 - Alteração tamanho campo tabela "PROC_ADM_EFD_REINF"
-- Solicitação: Adequação de novo layout expedido pelo Governo - Adequação de tamanho de campos
-- Alterações: Aumento do tamanho do campo cod_ident_vara de varchar2(2) para varchar2(4)
-- Procedures Alteradas: type tab_proc_adm_efd_reinf
--
-- Em 18/10/2018 - Karina de Paula
-- Redmine #39990 - Adpatar o processo de geração da DIRF para gerar os registros referente a pagamento de rendimentos a participantes localizados no exterior
-- Rotina Alterada: pk_int_view_cad.pkb_pessoa    => Alterada a chamada da pkb_pessoa_ff com a inclusão do COD_NIF e carrega a pk_csf_api_cad.gt_row_pessoa.cod_nif;
-- Rotina Alterada: pk_int_view_cad.pkb_pessoa_ff => Incluído o COD_NIF nos parâmetros de entrada da pb, incluído COD_NIF nos campos da view VW_CSF_PESSOA_FF
--                                                   e incluída a chamada da NOVA pk_csf_api_cad.pkb_val_atrib_nif;
--                                                   e incluída a chamada da NOVA pk_csf_api_cad.pkb_val_atrib_nif;
--
-- Em 18/02/2019 - Angela Inês.
-- Redmine #51632 - Falha na integração de cadastros gerais - ORA-06502 PL/SQL numeric or value error (ALTA GENETICS).
-- Conforme solicitação, foi necessário incluir o comando FKG_CONVERTE na coluna de Centro de Custo devido a ferramenta utilizada pelo cliente. A definição dos 
-- campos da tabela faz com que o tamanho fique maior na leitura do processo da Compliance, causando inconsitência de dados.
-- Esse comando foi aplicado em vários processos de Integração devido a necessidade desse cliente.
-- Rotina: pkb_pc_referen.
--
-- Em 12/09/2019 - Luis Marques
-- Redmine #58615 - Erros no SPED DF
-- Rotina Alterada: pkb_pessoa_ff - Incluido novo campo flex-field para inclusão da Natureza/Setor da pessoa
--                  (0 - Pessoa Setor Privado / 1 - Pessoa Setor Publico)
--
--
-------------------------------------------------------------------------------------------------------

-- Especificação de array

--| Informações de Pessoa
   type tab_csf_pessoa is record ( cod_part           varchar2(60)
                                 , dm_tipo_pessoa     number(1)
                                 , nome               varchar2(60)
                                 , fantasia           varchar2(60)
                                 , lograd             varchar2(60)
                                 , nro                varchar2(60)
                                 , cx_postal          varchar2(10)
                                 , compl              varchar2(60)
                                 , bairro             varchar2(60)
                                 , cidade_ibge        varchar2(7)
                                 , cep                number(8)
                                 , fone               varchar2(14)
                                 , fax                varchar2(14)
                                 , email              varchar2(60)
                                 , cod_siscomex_pais  number(4)
                                 , cpf_cnpj           varchar2(14)
                                 , rg_ie              varchar2(14)
                                 , iest               varchar2(14)
                                 , im                 varchar2(15)
                                 , suframa            varchar2(14)
                                 , inscr_prod         varchar2(15)
                                 );
--
   type t_tab_csf_pessoa is table of tab_csf_pessoa index by binary_integer;
   vt_tab_csf_pessoa t_tab_csf_pessoa;
--
--| Informações Flex-Field de Pessoa
   type tab_csf_pessoa_ff is record ( cod_part           varchar2(60)
                                    , atributo           varchar2(30)
                                    , valor              varchar2(255)
                                    );
--
   type t_tab_csf_pessoa_ff is table of tab_csf_pessoa_ff index by binary_integer;
   vt_tab_csf_pessoa_ff t_tab_csf_pessoa_ff;
--
--| Informações de Parâmetros de Pessoa
   type tab_csf_pessoa_tipo_param is record ( cod_part           varchar2(60)
                                            , cd_tipo_param      varchar2(10)
                                            , valor_tipo_param   varchar2(10)
                                            );
--
   type t_tab_csf_pessoa_tipo_param is table of tab_csf_pessoa_tipo_param index by binary_integer;
   vt_tab_csf_pessoa_tipo_param t_tab_csf_pessoa_tipo_param;
--
--| Informações de pagamentos de impostos retidos/SPED REINF
   type tab_csf_pessoa_info_pir is record ( cod_part              varchar2(60)
                                          , dm_ind_nif            number(1)
                                          , nif_benef             varchar2(20)   
                                          , cd_fonte_pagad_reinf  varchar2(3)    
                                          , dt_laudo_molestia     date
                                          );

   type t_tab_csf_pessoa_info_pir is table of tab_csf_pessoa_info_pir index by binary_integer;
   vt_tab_csf_pessoa_info_pir t_tab_csf_pessoa_info_pir;
--
--| Informações Flex-Field de Unidades de Medida
   type tab_csf_unidade_ff is record ( sigla_unid         varchar2(6)
                                     , atributo           varchar2(30)
                                     , valor              varchar2(255)
                                     );
--
   type t_tab_csf_unidade_ff is table of tab_csf_unidade_ff index by binary_integer;
   vt_tab_csf_unidade_ff t_tab_csf_unidade_ff;
--
--| Informações de Unidades de Medida
   type tab_csf_unidade is record ( sigla_unid        varchar2(6)
                                  , descr             varchar2(20) );
--
   type t_tab_csf_unidade is table of tab_csf_unidade index by binary_integer;
   vt_tab_csf_unidade t_tab_csf_unidade;
--
--| Informações de produtos e/ou serviços Flex Field
   type tab_csf_item_ff is record ( cpf_cnpj      varchar2(14)
                                  , cod_item      varchar2(60)
                                  , atributo      varchar2(30)
                                  , valor         varchar2(255)
                                  );
--
   type t_tab_csf_item_ff is table of tab_csf_item_ff index by binary_integer;
   vt_tab_csf_item_ff t_tab_csf_item_ff;
--
--| Informações de produtos e/ou serviços
   type tab_csf_item is record ( cpf_cnpj      varchar2(14)
                               , cod_item      varchar2(60)
                               , descr_item    varchar2(120)
                               , sigla_unid    varchar2(6)
                               , dm_orig_merc  number(1)
                               , tipo_item     varchar2(2)
                               , cod_ncm       varchar2(8)
                               , ex_tipi       varchar2(2)
                               , cod_barra     varchar2(255)
                               , cod_ant_item  varchar2(60)
                               , tipo_servico  varchar2(6)
                               , aliq_icms     number(5,2)
                               , cod_prod_anp  number(9) );
--
   type t_tab_csf_item is table of tab_csf_item index by binary_integer;
   vt_tab_csf_item t_tab_csf_item;
--
--| Informações de Códigos de Grupos por Marca Comercial/Refrigerante
   type tab_csf_item_marca_comerc is record ( cpf_cnpj    varchar2(14)
                                            , cod_item    varchar2(60)
                                            , dm_cod_tab  varchar2(2)
                                            , cod_gru     varchar2(2)
                                            , marca_com   varchar2(60) );
--
   type t_tab_csf_item_marca_comerc is table of tab_csf_item_marca_comerc index by binary_integer;
   vt_tab_csf_item_marca_comerc t_tab_csf_item_marca_comerc;
--
--| Informações de conversão de unidade do item
   type tab_csf_conv_unid is record ( cpf_cnpj    varchar2(14)
                                    , cod_item    varchar2(60)
                                    , sigla_unid  varchar2(60)
                                    , fat_conv    number(13,6) );
--
   type t_tab_csf_conv_unid is table of tab_csf_conv_unid index by binary_integer;
   vt_tab_csf_conv_unid t_tab_csf_conv_unid;
--
--| Informações de conversão de unidade do item
   type tab_csf_conv_unid_ff is record ( cpf_cnpj    varchar2(14)
                                       , cod_item    varchar2(60)
                                       , sigla_unid  varchar2(60)
                                       , atributo    varchar2(30)
                                       , valor       varchar2(255) );
--
   type t_tab_csf_conv_unid_ff is table of tab_csf_conv_unid_ff index by binary_integer;
   vt_tab_csf_conv_unid_ff t_tab_csf_conv_unid_ff;
--
--| Informações Flex Field dos grupos do patrimonio
   type tab_csf_grupo_pat_ff is record ( cd            varchar2(10)
                                       , atributo      varchar2(30)
                                       , valor         varchar2(255)
                                       );
--
   type t_tab_csf_grupo_pat_ff is table of tab_csf_grupo_pat_ff index by binary_integer;
   vt_tab_csf_grupo_pat_ff t_tab_csf_grupo_pat_ff;
--
--| Informações dos grupos do patrimonio
   type tab_csf_grupo_pat is record ( cd       varchar2(10)
                                    , descr    varchar2(50) );
--
   type t_tab_csf_grupo_pat is table of tab_csf_grupo_pat index by binary_integer;
   vt_tab_csf_grupo_pat t_tab_csf_grupo_pat;
--
--| Informações dos subgrupos do patrimonio
   type tab_csf_subgrupo_pat is record ( cd_grupopat          varchar2(10)
                                       , cd_subgrupopat       varchar2(10)
                                       , descr                varchar2(50)
                                       , vida_util_fiscal     number(3)   
                                       , vida_util_real       number(3)   
                                       , dm_formacao          number(1)   
                                       , dm_deprecia          number(1)   
                                       , dm_tipo_rec_pis      number(1)   
                                       , dm_tipo_rec_cofins   number(1) 
                                       , cod_ccus             varchar2(60) );
--
   type t_tab_csf_subgrupo_pat is table of tab_csf_subgrupo_pat index by binary_integer;
   vt_tab_csf_subgrupo_pat t_tab_csf_subgrupo_pat;
--
--| Informações Flex Field dos subgrupos do patrimonio
   type tab_csf_subgrupo_pat_ff is record ( cd_grupopat          varchar2(10)
                                          , cd_subgrupopat       varchar2(10)
                                          , atributo             varchar2(30)
                                          , valor                varchar2(255) );
--
   type t_tab_csf_subgrupo_pat_ff is table of tab_csf_subgrupo_pat_ff index by binary_integer;
   vt_tab_csf_subgrupo_pat_ff t_tab_csf_subgrupo_pat_ff;
--
--| Informações dos impostos dos subgrupos do patrimonio
   type tab_csf_imp_subgrupo_pat is record ( cd_grupopat       varchar2(10)
                                           , cd_subgrupopat    varchar2(10)
                                           , cd_tipo_imp       number(3)   
                                           , aliq              number(5,2) 
                                           , qtde_mes          number(3) );
--
   type t_tab_csf_imp_subgrupo_pat is table of tab_csf_imp_subgrupo_pat index by binary_integer;
   vt_tab_csf_imp_subgrupo_pat t_tab_csf_imp_subgrupo_pat;
--     
--| Informações Flex Field dos impostos dos subgrupos do patrimonio
   type tab_csf_imp_subgrupo_pat_ff is record ( cd_grupopat       varchar2(10)
                                              , cd_subgrupopat    varchar2(10)
                                              , cd_tipo_imp       number(3)
                                              , atributo          varchar2(30)
                                              , valor             varchar2(255));
--
   type t_tab_csf_imp_subgrupo_pat_ff is table of tab_csf_imp_subgrupo_pat_ff index by binary_integer;
   vt_tab_csf_imp_subgrupo_pat_ff t_tab_csf_imp_subgrupo_pat_ff;
--
--| Informações Flex Field dos bens do ativo imobilizado
   type tab_csf_bem_ativo_imob_ff is record ( cpf_cnpj      varchar2(14)
                                            , cod_ind_bem   varchar2(60)
                                            , atributo      varchar2(30)
                                            , valor         varchar2(255)
                                            );
--
   type t_tab_csf_bem_ativo_imob_ff is table of tab_csf_bem_ativo_imob_ff index by binary_integer;
   vt_tab_csf_bem_ativo_imob_ff t_tab_csf_bem_ativo_imob_ff;
--
--| Informações dos bens do ativo imobilizado
   type tab_csf_bem_ativo_imob is record ( cpf_cnpj       varchar2(14)
                                         , cod_ind_bem    varchar2(60)
                                         , dm_ident_merc  number(1)
                                         , descr_item     varchar2(255)
                                         , cod_prnc       varchar2(15)
                                         , cod_cta        varchar2(60)
                                         , nr_parc        number(3) );
--
   type t_tab_csf_bem_ativo_imob is table of tab_csf_bem_ativo_imob index by binary_integer;
   vt_tab_csf_bem_ativo_imob t_tab_csf_bem_ativo_imob;
--
--| Informações sobre a informação da utilização do bem
   type tab_csf_util_bem is record ( cpf_cnpj      varchar2(14)
                                   , cod_ind_bem   varchar2(60)
                                   , cod_ccus      varchar2(60)
                                   , func          varchar2(255)
                                   , vida_util     number );
--
   type t_tab_csf_util_bem is table of tab_csf_util_bem index by binary_integer;
   vt_tab_csf_util_bem t_tab_csf_util_bem;
--
--| Informações sobre a informação da utilização do bem
   type tab_csf_util_bem_ff is record ( cpf_cnpj      varchar2(14)
                                      , cod_ind_bem   varchar2(60)
                                      , cod_ccus      varchar2(60)
                                      , atributo      varchar2(30)
                                      , valor         varchar2(255));
--
   type t_tab_csf_util_bem_ff is table of tab_csf_util_bem_ff index by binary_integer;
   vt_tab_csf_util_bem_ff t_tab_csf_util_bem_ff;
--
--| Informações complementares dos bens do ativo imobilizado
   type tab_csf_bem_ativo_imob_comp is record ( cpf_cnpj            varchar2(14)
                                              , cod_ind_bem         varchar2(60)
                                              , cod_item            varchar2(60)
                                              , cod_grupopat        varchar2(10)
                                              , cod_subgrupopat     varchar2(10)
                                              , vida_util_fiscal    number(3)
                                              , vida_util_real      number(3)
                                              , dt_aquis            date
                                              , vl_aquis            number(15,2)
                                              , dt_ini_form         date
                                              , dt_fin_form         date
                                              , dm_deprecia         number(1)
                                              , dm_situacao         number(1)
                                              , dm_tipo_rec_pis     number(1)
                                              , dm_tipo_rec_cofins  number(1));
--
   type t_tab_csf_bem_ativo_imob_comp is table of tab_csf_bem_ativo_imob_comp index by binary_integer;
   vt_tab_csf_bem_ativo_imob_comp t_tab_csf_bem_ativo_imob_comp;
--
--| Informações Flex Field complementares dos bens do ativo imobilizado
   type tab_bem_ativo_imob_comp_ff is record ( cpf_cnpj            varchar2(14)
                                             , cod_ind_bem         varchar2(60)
                                             , atributo            varchar2(30)
                                             , valor               varchar2(255));
--
   type t_tab_bem_ativo_imob_comp_ff is table of tab_bem_ativo_imob_comp_ff index by binary_integer;
   vt_tab_bem_ativo_imob_comp_ff t_tab_bem_ativo_imob_comp_ff;
--
--| Informações sobre os documentos fiscais do bem
   type tab_csf_nf_bem_ativo_imob is record ( cpf_cnpj      varchar2(14)
                                            , cod_ind_bem   varchar2(60)
                                            , dm_ind_emit   number(1)
                                            , cod_part      varchar2(60)
                                            , cod_mod       varchar2(2) 
                                            , serie         varchar2(3) 
                                            , num_doc       number(9)   
                                            , chv_nfe_cte   varchar2(44)
                                            , dt_doc        date
                                            );
--
   type t_tab_csf_nf_bem_ativo_imob is table of tab_csf_nf_bem_ativo_imob index by binary_integer;
   vt_tab_csf_nf_bem_ativo_imob t_tab_csf_nf_bem_ativo_imob;
--
--| Informações sobre os documentos fiscais do bem
   type tab_csf_nf_bemativo_imob_ff is record ( cpf_cnpj      varchar2(14)
                                              , cod_ind_bem   varchar2(60)
                                              , dm_ind_emit   number(1)
                                              , cod_part      varchar2(60)
                                              , cod_mod       varchar2(2)
                                              , serie         varchar2(3)
                                              , num_doc       number(9)
                                              , atributo      varchar2(30)
                                              , valor         varchar2(255)
                                              );
--
   type t_tab_csf_nf_bemativo_imob_ff is table of tab_csf_nf_bemativo_imob_ff index by binary_integer;
   vt_tab_csf_nf_bemativo_imob_ff t_tab_csf_nf_bemativo_imob_ff;
--
--| Informações sobre os documentos fiscais do bem
   type tab_csf_itnf_bem_ativo_imob is record ( cpf_cnpj      varchar2(14)
                                              , cod_ind_bem   varchar2(60)
                                              , dm_ind_emit   number(1)
                                              , cod_part      varchar2(60)
                                              , cod_mod       varchar2(2)
                                              , serie         varchar2(3)
                                              , num_doc       number(9)
                                              , num_item      number
                                              , cod_item      varchar2(60)
                                              , vl_item       number(15,2)
                                              , vl_icms       number(15,2)
                                              , vl_bc_pis     number(15,2)
                                              , vl_bc_cofins  number(15,2)
                                              , vl_frete      number(15,2)
                                              , vl_icms_st    number(15,2) 
                                              );
--
   type t_tab_csf_itnf_bem_ativo_imob is table of tab_csf_itnf_bem_ativo_imob index by binary_integer;
   vt_tab_csf_itnf_bem_ativo_imob t_tab_csf_itnf_bem_ativo_imob;
--
--| Informações flex field sobre os documentos fiscais do bem
   type tab_itnf_bem_ativo_imob_ff is record ( cpf_cnpj      varchar2(14)
                                             , cod_ind_bem   varchar2(60)
                                             , dm_ind_emit   number(1)
                                             , cod_part      varchar2(60)
                                             , cod_mod       varchar2(2)
                                             , serie         varchar2(3)
                                             , num_doc       number(9)
                                             , num_item      number(3)
                                             , atributo      varchar2(30)
                                             , valor         varchar2(255)
                                             );
--
   type t_tab_itnf_bem_ativo_imob_ff is table of tab_itnf_bem_ativo_imob_ff index by binary_integer;
   vt_tab_itnf_bem_ativo_imob_ff t_tab_itnf_bem_ativo_imob_ff;
--
--| Informações sobre os impostos do bem
   type tab_csf_rec_imp_bem_ativo is record ( cpf_cnpj             varchar2(14)
                                            , cod_ind_bem          varchar2(60)
                                            , cd_tipo_imp          number(3)   
                                            , aliq                 number(5,2) 
                                            , qtde_mes             number(3)   
                                            , qtde_mes_real        number(3) );
--
   type t_tab_csf_rec_imp_bem_ativo is table of tab_csf_rec_imp_bem_ativo index by binary_integer;
   vt_tab_csf_rec_imp_bem_ativo t_tab_csf_rec_imp_bem_ativo;
--
--| Informações flex field sobre os impostos do bem
   type tab_csf_recimp_bem_ativo_ff is record ( cpf_cnpj             varchar2(14)
                                              , cod_ind_bem          varchar2(60)
                                              , cd_tipo_imp          number(3)
                                              , atributo             varchar2(30)
                                              , valor                varchar2(255));
--
   type t_tab_csf_recimp_bem_ativo_ff is table of tab_csf_recimp_bem_ativo_ff index by binary_integer;
   vt_tab_csf_recimp_bem_ativo_ff t_tab_csf_recimp_bem_ativo_ff;
--
--| Informações Flex Field da Natureza da Operação/Prestação
   type tab_csf_nat_oper_ff is record ( cod_nat       varchar2(10)
                                      , atributo      varchar2(30)
                                      , valor         varchar2(255)
                                      );
--
   type t_tab_csf_nat_oper_ff is table of tab_csf_nat_oper_ff index by binary_integer;
   vt_tab_csf_nat_oper_ff t_tab_csf_nat_oper_ff;
--
--| Informações da Natureza da Operação/Prestação
   type tab_csf_nat_oper is record ( cod_nat       varchar2(10)
                                   , descr_nat     varchar2(255) );
--
   type t_tab_csf_nat_oper is table of tab_csf_nat_oper index by binary_integer;
   vt_tab_csf_nat_oper t_tab_csf_nat_oper;
--
--| Informações Flex Field complementar do documento fiscal
   type tab_csf_inf_comp_dcto_fis_ff is record ( cod_infor  varchar2(10)
                                      , atributo      varchar2(30)
                                      , valor         varchar2(255) );
--
   type t_tab_csf_inf_comp_dcto_fis_ff is table of tab_csf_inf_comp_dcto_fis_ff index by binary_integer;
   vt_tab_csf_inf_comp_dcto_fi_ff t_tab_csf_inf_comp_dcto_fis_ff;
--
--| Informações complementar do documento fiscal
   type tab_csf_inf_comp_dcto_fis is record ( cod_infor  varchar2(10)
                                            , txt        varchar2(255) );
--
   type t_tab_csf_inf_comp_dcto_fis is table of tab_csf_inf_comp_dcto_fis index by binary_integer;
   vt_tab_csf_inf_comp_dcto_fis t_tab_csf_inf_comp_dcto_fis;
--
--| Informações de observações do lançamento fiscal
   type tab_obs_lancto_fiscal_ff is record ( cod_obs       varchar2(6)
                                           , atributo      varchar2(30)
                                           , valor         varchar2(255) );
--
   type t_tab_obs_lancto_fiscal_ff is table of tab_obs_lancto_fiscal_ff index by binary_integer;
   vt_tab_obs_lancto_fiscal_ff t_tab_obs_lancto_fiscal_ff;
--
--| Informações de observações do lançamento fiscal
   type tab_obs_lancto_fiscal is record ( cod_obs   varchar2(6)
                                        , txt       varchar2(255));
--
   type t_tab_obs_lancto_fiscal is table of tab_obs_lancto_fiscal index by binary_integer;
   vt_tab_obs_lancto_fiscal t_tab_obs_lancto_fiscal;
--
--| Informações do plano de contas contábeis
   type tab_csf_plano_conta_ff is record ( cpf_cnpj     varchar2(14)
                                         , cod_cta      varchar2(255)
                                         , atributo  varchar2(30)
                                         , valor     varchar2(255) );
--
   type t_tab_csf_plano_conta_ff is table of tab_csf_plano_conta_ff index by binary_integer;
   vt_tab_csf_plano_conta_ff t_tab_csf_plano_conta_ff;
--
--| Informações do plano de contas contábeis
   type tab_csf_plano_conta is record ( cpf_cnpj     varchar2(14)
                                      , cod_cta      varchar2(255)
                                      , dt_inc_alt   date
                                      , cod_nat_pc   varchar2(2)
                                      , dm_ind_cta   varchar2(1)
                                      , nivel        number(2)
                                      , cod_cta_sup  varchar2(255)
                                      , descr_cta    varchar2(255) );
--
   type t_tab_csf_plano_conta is table of tab_csf_plano_conta index by binary_integer;
   vt_tab_csf_plano_conta t_tab_csf_plano_conta;
--
--| Informações do plano de contas referencial
   type tab_csf_pc_referen is record ( cpf_cnpj     varchar2(14)
                                     , cod_cta      varchar2(255)
                                     , cod_ent_ref  varchar2(2)
                                     , cod_cta_ref  varchar2(30)
                                     , cod_ccus     varchar2(30) );
--
   type t_tab_csf_pc_referen is table of tab_csf_pc_referen index by binary_integer;
   vt_tab_csf_pc_referen t_tab_csf_pc_referen; 
--
--| Informações do plano de contas referencial por Periodo
   type tab_csf_pc_referen_period is record ( cpf_cnpj     varchar2(14)
                                            , cod_cta      varchar2(255)
                                            , cod_ent_ref  varchar2(2)
                                            , cod_cta_ref  varchar2(30)
                                            , cod_ccus     varchar2(30)
                                            , dt_ini       date
                                            , dt_fin       date);
--
   type t_tab_csf_pc_referen_period is table of tab_csf_pc_referen_period index by binary_integer;
   vt_tab_csf_pc_referen_period  t_tab_csf_pc_referen_period;
--
--| Informações do plano de contas referencial
   type tab_csf_pc_referen_ff is record ( cpf_cnpj     varchar2(14)
                                        , cod_cta      varchar2(255)
                                        , cod_ent_ref  varchar2(2)
                                        , cod_cta_ref  varchar2(30)
                                        , cod_ccus     varchar2(30)
                                        , atributo     varchar2(30)
                                        , valor        varchar2(255));
--
   type t_tab_csf_pc_referen_ff is table of tab_csf_pc_referen_ff index by binary_integer;
   vt_tab_csf_pc_referen_ff t_tab_csf_pc_referen_ff;
--
--| Informações das subconta_correlata
   type tab_csf_subconta_correlata is record ( cpf_cnpj      varchar2(14)
                                             , cod_cta       varchar2(255)
                                             , cod_idt       varchar2(6)
                                             , cod_cta_corr  varchar2(255)
                                             , cd_natsubcnt  varchar2(2));
--
   type t_tab_csf_subconta_correlata is table of tab_csf_subconta_correlata index by binary_integer;
   vt_tab_csf_subconta_correlata  t_tab_csf_subconta_correlata;
--
--| Informações do de-para Plano de Contas e Aglutinação Contábil Societária    
   type tab_csf_pc_aglut_contabil is record ( cpf_cnpj_emit  varchar2(14)
                                            , cod_cta        varchar2(255)
                                            , cod_agl        varchar2(30)
                                            , cod_ccus       varchar2(30)
                                            );
--
   type t_tab_csf_pc_aglut_contabil is table of tab_csf_pc_aglut_contabil index by binary_integer;
   vt_tab_csf_pc_aglut_contabil     t_tab_csf_pc_aglut_contabil;
--
--| Informações de Aglutinação Contábil Societária
   type tab_csf_aglut_contabil is record ( cpf_cnpj_emit     varchar2(14)
                                         , cod_nat           varchar2(2)
                                         , cod_agl           varchar2(30)
                                         , descr_agl         varchar2(255)
                                         , nivel             number(2)
                                         , dm_ind_cta        varchar2(1)
                                         , ar_cod_agl        varchar2(30)/*varchar2(2)*/
                                         , dt_ini            date
                                         , dt_fin            date
                                         );
--
   type t_tab_csf_aglut_contabil is table of tab_csf_aglut_contabil index by binary_integer;
   vt_tab_csf_aglut_contabil     t_tab_csf_aglut_contabil;
--
--| Informações de centro de custos
   type tab_csf_centro_custo_ff is record ( cpf_cnpj    varchar2(14)
                                          , cod_ccus    varchar2(30)
                                          , atributo    varchar2(30)
                                          , valor       varchar2(255) );
--
   type t_tab_csf_centro_custo_ff is table of tab_csf_centro_custo_ff index by binary_integer;
   vt_tab_csf_centro_custo_ff t_tab_csf_centro_custo_ff;
--
--| Informações de centro de custos
   type tab_csf_centro_custo is record ( cpf_cnpj    varchar2(14)
                                       , cod_ccus    varchar2(30)
                                       , dt_inc_alt  date
                                       , descr_ccus  varchar2(255) );
--
   type t_tab_csf_centro_custo is table of tab_csf_centro_custo index by binary_integer;
   vt_tab_csf_centro_custo t_tab_csf_centro_custo;
--
--| Informações do histórico padrão dos lançamentos contábeis
   type tab_csf_hist_padrao_ff is record ( cpf_cnpj    varchar2(14)
                                         , cod_hist    varchar2(30)
                                         , atributo    varchar2(30)
                                         , valor       varchar2(255));
--
   type t_tab_csf_hist_padrao_ff is table of tab_csf_hist_padrao_ff index by binary_integer;
   vt_tab_csf_hist_padrao_ff t_tab_csf_hist_padrao_ff;
--
--| Informações do histórico padrão dos lançamentos contábeis
   type tab_csf_hist_padrao is record ( cpf_cnpj    varchar2(14)
                                      , cod_hist    varchar2(30)
                                      , descr_hist  varchar2(255) );
--
   type t_tab_csf_hist_padrao is table of tab_csf_hist_padrao index by binary_integer;
   vt_tab_csf_hist_padrao t_tab_csf_hist_padrao;
--
--| Procedimento integra os dados de Parâmetros de Cálculo de ICMS-ST
   type tab_item_param_icmsst_ff is record ( cpf_cnpj    	        varchar2(14)
                                               , cod_item    	        varchar2(60)
                                               , sigla_uf_dest	        varchar2(2)
                                               , cfop_orig	        number(4)
                                               , dt_ini		        date
                                               , dt_fin		        date
                                               , atributo               varchar2(30)
                                               , valor                  varchar2(255));
--
   type t_tab_item_param_icmsst_ff is table of tab_item_param_icmsst_ff index by binary_integer;
   vt_tab_item_param_icmsst_ff t_tab_item_param_icmsst_ff;
--
--| Procedimento integra os dados de Parâmetros de Cálculo de ICMS-ST
   type tab_csf_item_param_icmsst is record ( cpf_cnpj    	  varchar2(14)
                                            , cod_item    	  varchar2(60)
                                            , sigla_uf_dest	  varchar2(2)
                                            , cfop_orig		  number(4)
                                            , dm_mod_base_calc_st number(1)
                                            , dt_ini		  date
                                            , dt_fin		  date
                                            , aliq_dest		  number(5,2)
                                            , cod_obs		  varchar2(6)
                                            , cfop_dest		  number(4)
                                            , cod_st		  varchar2(2)
                                            , indice		  number(10,4)
                                            , perc_reduc_bc	  number(5,2)
                                            , dm_ajusta_mva	  number(1)
                                            , dm_efeito		  number(1) );
--
   type t_tab_csf_item_param_icmsst is table of tab_csf_item_param_icmsst index by binary_integer;
   vt_tab_csf_item_param_icmsst t_tab_csf_item_param_icmsst;
   
--| Informações de Complemento do item
   type tab_csf_item_compl is record ( cpf_cnpj               varchar2(14)
                                     , cod_item	              varchar2(60)
                                     , csosn                  varchar2(3)
                                     , cst_icms	              varchar2(3)
                                     , per_red_bc_icms	      number(6,2)
                                     , bc_icms_st             number(6,2)
                                     , cst_ipi_entrada	      varchar2(2)
                                     , cst_ipi_saida          varchar2(2)
                                     , aliq_ipi	              number(6,2)
                                     , cst_pis_entrada	      varchar2(2)
                                     , cst_pis_saida          varchar2(2)
                                     , nat_rec_pis            varchar2(3)
                                     , aliq_pis	              number(6,2)
                                     , cst_cofins_entrada     varchar2(2)
                                     , cst_cofins_saida	      varchar2(2)
                                     , nat_rec_cofins	      varchar2(3)
                                     , aliq_cofins	      number(6,2)
                                     , aliq_iss	              number(6,2)
                                     , cod_cta	              varchar2(25)
                                     , observacao             varchar2(60)
                                     , vl_est_venda           number(7,2)
                                     );
--
   type t_tab_csf_item_compl is table of tab_csf_item_compl index by binary_integer;
   vt_tab_csf_item_compl t_tab_csf_item_compl;
--

--| Controle de Versão Contábil
   type tab_csf_ctrl_ver_contab is record ( cpf_cnpj_emit   varchar2(14)
                                          , cd              varchar2(10)
                                          , descr           varchar2(50)
                                          , dm_tipo         number(1)
                                          , dt_ini          date
                                          , dt_fin          date
                                          );
--
   type t_tab_csf_ctrl_ver_contab is table of tab_csf_ctrl_ver_contab index by binary_integer;
   vt_tab_csf_ctrl_ver_contab t_tab_csf_ctrl_ver_contab;

-- Item Componente/Insumo - Bloco K - Sped Fiscal
   type tab_csf_item_insumo is record ( cpf_cnpj_emit   varchar2(14)
                                      , cod_item        varchar2(60)
                                      , cod_item_comp   varchar2(60)
                                      , qtd_comp        number(17,6)
                                      , perda           number(5,2)
                                      );
--
   type t_tab_csf_item_insumo is table of tab_csf_item_insumo index by binary_integer;
   vt_tab_csf_item_insumo t_tab_csf_item_insumo;
--
--| Retorno dos dados da Abertura do FCI

 type tab_abertura_fci is record ( cnpj_empr                varchar2(14)
                                 , mes_ref                  varchar2(2)
                                 , ano_ref                  number(4)
                                 , nro_prot                 varchar2(10)
                                 );
--
 type t_tab_abertura_fci   is table of tab_abertura_fci index by binary_integer;
 vt_tab_abertura_fci       t_tab_abertura_fci;
--
--| Retorno dos dados do FCI
 type tab_retorno_fci is record ( cnpj_empr                varchar2(14)
                                , mes_ref                  varchar2(2)
                                , ano_ref                  number(4)
                                , cod_item                 varchar2(60)
                                , coef_import              number(6,2)
                                , nro_fci                  varchar2(36)
                                , vl_saida                 number(7,2)
                                , vl_entr_tot              number(8,2)
                                );
--
 type t_tab_retorno_fci   is table of tab_retorno_fci index by binary_integer;
 vt_tab_retorno_fci       t_tab_retorno_fci;
--
--| Processo de leitura dos Parâmetros DE-PARA de Item de Fornecedor para Emp. Usuária
  type tab_csf_param_item_entr is record ( cpf_cnpj_emit  varchar2(14)
                                         , cnpj_orig      varchar2(14)
                                         , cod_ncm_orig   varchar2(8)
                                         , cod_item_orig  varchar2(60)
                                         , cod_item_dest  varchar2(60)
                                         );
  --
  type t_tab_csf_param_item_entr is table of tab_csf_param_item_entr index by binary_integer;
  vt_tab_csf_param_item_entr t_tab_csf_param_item_entr;
--
--| Parâmetros de conversão de nfe
  type tab_param_oper_fiscal_entr is record ( cpf_cnpj_emit      varchar2(14)
                                            , cfop_orig          number(4)
                                            , cnpj_orig          varchar2(14)
                                            , dm_raiz_cnpj_orig  number(1)
                                            , cod_ncm_orig       varchar2(8)
                                            , cod_item_orig      varchar2(60)
                                            , cod_st_icms_orig   varchar2(3)
                                            , cod_st_ipi_orig    varchar2(2)
                                            , cfop_dest          number(4)
                                            , dm_rec_icms        number(1)
                                            , cod_st_icms_dest   varchar2(3)
                                            , dm_rec_ipi         number(1)
                                            , cod_st_ipi_dest    varchar2(2)
                                            , dm_rec_pis         number(1)
                                            , cod_st_pis_dest    varchar2(2)
                                            , dm_rec_cofins      number(1)
                                            , cod_st_cofins_dest varchar2(2)
                                            );
  --
  type t_tab_param_oper_fiscal_entr is table of tab_param_oper_fiscal_entr index by binary_integer;
  vt_tab_param_oper_fiscal_entr t_tab_param_oper_fiscal_entr;
--
   type tab_param_dipamgia is record ( cpf_cnpj          varchar2(14)
                                     , ibge_estado       varchar2(2)
                                     , cd_dipamgia       varchar2(10)
                                     , cd_cfop           number(4)
                                     , cod_item          varchar2(60)
                                     , cod_ncm           varchar2(8)
                                     , perc_rateio_item  number(5,2)
                                     );
--
  type t_tab_param_dipamgia is table of tab_param_dipamgia index by binary_integer;
   vt_tab_param_dipamgia t_tab_param_dipamgia;
--
   type tab_param_dipamgia_ff is record ( cpf_cnpj          varchar2(14)
                                        , ibge_estado       varchar2(2)
                                        , cd_dipamgia       varchar2(10)
                                        , cd_cfop           number(4)
                                        , cod_item          varchar2(60)
                                        , cod_ncm           varchar2(8)
                                        , atributo          varchar2(30)
                                        , valor             varchar2(255)
                                        );
--
   type t_tab_param_dipamgia_ff is table of tab_param_dipamgia_ff index by binary_integer;
   vt_tab_param_dipamgia_ff  t_tab_param_dipamgia_ff;
--
   type tab_proc_adm_efd_reinf is record ( cpf_cnpj                varchar2(14)
                                         , dm_tp_proc              number(1)
                                         , nro_proc                varchar2(21)
                                         , dt_ini                  date
                                         , dt_fin                  date
                                         , ibge_cidade             varchar2(7)
                                         , cod_ident_vara          varchar2(4)
                                         , dm_ind_auditoria        number(1)
                                         , dm_reinf_legado         number(1)
                                         );
--
   type t_tab_proc_adm_efd_reinf is table of tab_proc_adm_efd_reinf index by binary_integer;
   vt_tab_proc_adm_efd_reinf t_tab_proc_adm_efd_reinf;
--
  type tab_proc_adm_efd_reinf_ff is record ( cpf_cnpj                varchar2(14)
                                            , dm_tp_proc                 number(1)
                                            , nro_proc                   varchar2(21)
                                            , atributo                   varchar2(30)
                                            , valor                      varchar2(255)
                                            );
--
   type t_tab_proc_adm_efd_reinf_ff is table of tab_proc_adm_efd_reinf_ff index by binary_integer;
   vt_tab_proc_adm_efd_reinf_ff t_tab_proc_adm_efd_reinf_ff;
--
   type tab_procadmefdreinfinftrib is record ( cpf_cnpj                   varchar2(14)
                                             , dm_tp_proc                 number(1)
                                             , nro_proc                   varchar2(21)
                                             , cod_susp                   number(14)
                                             , cd_ind_susp_exig           varchar2(2)
                                             , dt_decisao                 date
                                             , dm_ind_deposito            varchar2(1)
                                             );
--
   type t_tab_procadmefdreinfinftrib is table of tab_procadmefdreinfinftrib index by binary_integer;
   vt_tab_procadmefdreinfinftrib t_tab_procadmefdreinfinftrib;
--
-------------------------------------------------------------------------------------------------------

   gv_sql varchar2(4000) := null;

-------------------------------------------------------------------------------------------------------

   gv_aspas           char(1) := null;
   gv_nome_dblink     empresa.nome_dblink%type := null;
   gv_owner_obj       empresa.owner_obj%type := null;
   gv_formato_dt_erp  empresa.formato_dt_erp%type := null;

-------------------------------------------------------------------------------------------------------

-- Declaração de constantes

   erro_de_validacao  constant number := 1;
   erro_de_sistema    constant number := 2;
   informacao         constant number := 35;

-------------------------------------------------------------------------------------------------------

   gv_cabec_log       Log_Generico_Cad.mensagem%TYPE;
   gv_cabec_log_item  Log_Generico_Cad.mensagem%TYPE;
   gv_mensagem_log    Log_Generico_Cad.mensagem%TYPE;
   gv_obj_referencia  Log_Generico_Cad.obj_referencia%type default null;
   gn_referencia_id   Log_Generico_Cad.referencia_id%type := null;
   gv_cd_obj          obj_integr.cd%type := '1';
   gn_multorg_id      mult_org.id%type;
   gv_multorg_cd      mult_org.cd%type;
   gn_empresa_id      empresa.id%type;
   gv_sistema_em_nuvem varchar2(10);
   gv_formato_data       param_global_csf.valor%type := null;

-------------------------------------------------------------------------------------------------------
-- Procedimento Parâmetros de Conversão de NFe
procedure pkb_ler_oper_fiscal_ent(ev_cpf_cnpj in varchar2);

-- Processo de leitura dos Parâmetros DE-PARA de Item de Fornecedor para Emp. Usuária
procedure pkb_ler_item_fornc_eu ( ev_cpf_cnpj in varchar2);

-- Processo de leitura do Retorno dos dados da Ficha de Conteudo de Importação
procedure pkb_ler_retorno_fci ( est_log_generico     in out nocopy dbms_sql.number_table
                              , en_aberturafciarq_id in            abertura_fci_arq.id%type
                              , ev_cnpj_empr         in            varchar2
                              , ev_mes_ref           in            varchar2
                              , en_ano_ref           in            number
                              );

-- Processo que ira ler todos os registros da VW_CSF_RETORNO_FCI
procedure pkb_legado_fci ( ev_cpf_cnpj in varchar2 );

--| Procedimento de integração do Item Componente/Insumo - Bloco K - Sped Fiscal
--procedure pkb_item_insumo ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integração do Controle de Versão Contábil
procedure pkb_ctrl_ver_contab ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integração Flex Field do Histórico Padrão
procedure pkb_hist_padrao_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                            , ev_cpf_cnpj        in  varchar2
                            , ev_cod_hist       in  varchar2
                            , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integração do Histórico Padrão
procedure pkb_hist_padrao ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integração Flex Field do centro de custo
procedure pkb_centro_custo_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                             , ev_cpf_cnpj        in  varchar2
                             , ev_cod_ccus        in  varchar2
                             , sn_multorg_id      in out mult_org.id%type);

--| Procedimento de integração do centro de custo
procedure pkb_centro_custo ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integração Flex Field do plano de contas
procedure pkb_plano_conta_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                            , ev_cpf_cnpj       in  varchar2
                            , ev_cod_cta        in  varchar2
                            , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integração do plano de contas
procedure pkb_plano_conta ( ev_cpf_cnpj in  varchar2 );

--| Procedimento de integração de Observação do Lançamento Fiscal
procedure pkb_obs_lancto_fiscal_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                                  , ev_cod_obs        in  varchar2
                                  , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integração de Observação do Lançamento Fiscal
procedure pkb_obs_lancto_fiscal;

--| Procedimento de integração Flex Field de informações complementar do documento fiscal
procedure pkb_infor_comp_dcto_fiscal_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                                       , ev_cod_infor      in  varchar2
                                       , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integração de informações complementar do documento fiscal
procedure pkb_inf_comp_dcto_fis;

--| Procedimento de integração Flex Field de Natureza da Operação
procedure pkb_nat_oper_ff( est_log_generico  in    out nocopy  dbms_sql.number_table
                         , ev_cod_nat        in  varchar2
                         , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integração de Natureza da Operação
procedure pkb_nat_oper;

--| Procedimento de integração de dados Flex Field dos Grupos de Patrimonio
procedure pkb_grupo_pat_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                          , ev_cd             in  varchar2
                          , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integração dos Grupos de Patrimonio
procedure pkb_grupo_pat ( ev_cpf_cnpj in varchar2 );

--| Procedimento de integração Flex Field de Bens do ativo Imobilizado
procedure pkb_bem_ativo_imob_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                               , ev_cpf_cnpj       in  varchar2
                               , ev_cod_ind_bem    in  varchar2
                               , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integração de Bens do ativo Imobilizado
procedure pkb_bem_ativo_imob ( ev_cpf_cnpj in varchar2 );

--| Procedimento de integração Flex Field de Item (Produtos/Serviços)
procedure pkb_item_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                     , ev_cpf_cnpj       in  varchar2
                     , ev_cod_item       in  varchar2
                     , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integração de Item (Produtos/Serviços)
procedure pkb_item ( ev_cpf_cnpj in varchar2 );

--| Procedimento de integração de campos FlexField de Unidade
procedure pkb_unidade_ff( est_log_generico  in  out nocopy  dbms_sql.number_table
                        , ev_sigla_unid     in  varchar2
                        , sn_multorg_id     in out mult_org.id%type);

--| Procedimento de integração de Unidades de Medidas
procedure pkb_unidade;

--| Procedimento de integração de Pessoa
procedure pkb_pessoa;

--| Procedimento de integração de campos FlexField de Pessoa
procedure pkb_pessoa_ff( est_log_generico in out nocopy  dbms_sql.number_table
                       , ev_cod_part      in varchar2
                       , sn_multorg_id    in out mult_org.id%type
                       , sv_cod_nif       in out pessoa.cod_nif%type );

--| Procedimento integra os dados Flex Field de Parâmetros de Cálculo de ICMS-ST
procedure pkb_item_param_icmsst_ff( est_log_generico    in  out nocopy  dbms_sql.number_table
                                  , ev_cpf_cnpj         varchar2
                                  , ev_cod_item         varchar2
                                  , ev_sigla_uf_dest    varchar2
                                  , en_cfop_orig        number
                                  , ed_dt_ini           date
                                  , ed_dt_fin           date
                                  , sn_multorg_id       in out mult_org.id%type);

--| Procedimento integra os dados de Parâmetros de Cálculo de ICMS-ST
procedure pkb_item_param_icmsst ( ev_cpf_cnpj  in  varchar2 );

-------------------------------------------------------------------------------------------------------

--| Procedimento que inicia a integração de cadastros
procedure pkb_integracao ( en_empresa_id  in  empresa.id%type
                         , ed_dt_ini      in  date
                         , ed_dt_fin      in  date
                         , en_nro_linha   in  number default 1 --#68800 
                         );

-------------------------------------------------------------------------------------------------------------------------------

--| Procedimento que inicia a integração de cadastros Normal, com todas as empresas

procedure pkb_integracao_normal ( en_multorg_id in mult_org.id%type
                                , ed_dt_ini     in  date
                                , ed_dt_fin     in  date
                                );

-------------------------------------------------------------------------------------------------------

-- Processo de integração informando todas as empresas matrizes
procedure pkb_integr_cad_geral ( en_multorg_id in mult_org.id%type
                               , ed_dt_ini     in  date
                               , ed_dt_fin     in  date
                               );

-------------------------------------------------------------------------------------------------------

-- Processo de integração informando todas as empresas matrizes
procedure pkb_integr_empresa_geral ( en_paramintegrdados_id in param_integr_dados.id%type 
                                   , en_empresa_id          in empresa.id%type
                                   );

-------------------------------------------------------------------------------------------------------

end pk_int_view_cad;
/
