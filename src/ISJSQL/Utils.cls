Class ISJSQL.Utils
{

/// ********************************************************************<br>
/// 第1引数：実行したいSQL文 <br>
/// 第2引数：出力形式の指定 <br>
/// <li> 0：XMLファイル出力</li>
/// <li> 1：HTMLファイル出力</li>
/// <li> 99：タブ区切りのテキストファイル出力）</li>
/// <li> 100：CSVファイル出力《注意：タブ区切りで生成されます》</li>
/// 第3引数：出力先ディレクトリ指定（Caché／Ensembleサーバ上ディレクトリを指定）<br>
/// ※出力ファイルは第3引数で指定するディレクトリ以下に yyyymmddhhmmss.拡張子 で生成されます<br>
/// ********************************************************************<br>
ClassMethod ToCSV(sql As %String(MAXLEN=""), format As %Integer = 99, dir As %String(MAXLEN="")) As %Status [ SqlProc ]
{
	#dim %sqlcontext As %Library.ProcedureContext
	#dim ex As %Exception.AbstractException
	#dim rset As %SQL.StatementResult
	set st=$$$OK
	try {
		// ディレクトリをチェックし存在しない場合はエラーメッセージを作成しcatchへ
		if '##class(%File).Exists(dir) {
			$$$THROWONERROR(ex,$$$ERROR($$$GeneralError,"ディレクトリが不正です::"_$get(dir)))
		}

		// $SYSTEM.SQL.Execute()メソッド詳細はドキュメントをご参照ください。
		// http://docs.intersystems.com/cache_latestj/csp/docbook/DocBook.UI.Page.cls?KEY=GSQL_shell#GSQL_shell_alternatives
		// 第1引数：実行したいSQL文
		// 第2引数：日付の表示変換モード指定　1:odbcモード（yyyy-mm-dd）
		set rset=$system.SQL.Execute(sql,1)
		if rset.%SQLCODE<0 {
			throw ##class(%Exception.SQL).CreateFromSQLCODE(rset.%SQLCODE,rset.%Message)
		}

		//　出力ファイル名の作成
		set fname=##class(%File).NormalizeDirectory(dir)_$ZSTRIP($ZDATETIME($H,8),"*P")
		
		#dim pMessages As %SQL.Manager.Messages
		do rset.%DisplayFormatted(format,fname,.pMessages)

		// pMessagesオブジェクトを%Next()し、結果が1の場合はメッセージが登録されている
		for i=1:1:pMessages.Count() {
			if (pMessages.%Next(.status)) {
				// 一般メッセージ以外のエラーの場合、[SQLCODE:の文字が含まれている
				if '(pMessages.Message["[SQLCODE:") continue
				set code=$extract($zstrip($piece(pMessages.Message,":",2),"*W"),2,*-1)
				set errmsg=pMessages.Message_"@ %DisyplayFormatted()の処理でエラーが発生しました"
				throw ##class(%Exception.SQL).CreateFromSQLCODE(code,errmsg)
			}	
		}
	}
	catch ex {
		set %sqlcontext.%SQLCODE=ex.AsSQLCODE()
		set %sqlcontext.%Message=ex.AsSQLMessage()
		set st=ex.AsStatus()
	}
	quit st
}

}
