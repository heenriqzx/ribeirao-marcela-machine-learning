# Antes de divulgar o repositório ou enviar seu link a recrutadores

Há duas questões diferentes: **publicar scripts históricos para avaliação técnica** e **afirmar que o projeto é integralmente reproduzível e cientificamente validado**. A primeira pode ser realizada sem a segunda, desde que os direitos de divulgação sejam respeitados e as limitações estejam claras.

## Conferências obrigatórias antes de mudar para `Public`

1. **Permissão e autoria:** confirmar com o orientador e a equipe que estes quatro scripts e as descrições da pesquisa podem ser divulgados; verificar possíveis contribuições de terceiros.
2. **Ausência de informações restritas:** verificar a versão publicada e o histórico de commits. Não divulgar dados laboratoriais, bases completas, senhas, arquivos internos ou resultados ainda não autorizados.
3. **Transparência:** manter no `README.md` a informação de que são versões históricas, que a execução integral está pendente e que os dados necessários não são públicos.
4. **Limitação conhecida:** o script SVM histórico espera um separador diferente daquele da base recuperada e pode falhar na leitura. O código foi preservado para documentação, não apresentado como solução pronta.
5. **Sem licença presumida:** não adicionar licença MIT ou similar sem avaliação dos direitos sobre o código.

## Verificações adicionais para declarar o projeto reproduzível

- Reexecutar os quatro scripts no R, com bases autorizadas, e documentar versões dos pacotes.
- Revisar o desenho de validação e a seleção de modelos, evitando estimativas otimistas.
- Reconciliar os diferentes conjuntos de atributos dos scripts RF e SVM.
- Incluir gráficos, tabelas ou métricas **somente** após conferência e autorização.

**Atenção:** o GitHub guarda o histórico de versões. Um `.gitignore` não impede o envio manual de arquivos sensíveis e não remove o que já foi incluído em commits anteriores. Enquanto o repositório estiver `Private`, o link não ficará acessível a recrutadores que não tenham permissão.
