class Doble_list
	def initialize
		@head=@tail=nil
	end 
	def add(id, linea, columna, clase)
		node=clase.new(id,linea,columna)
		node.act_next(@head) unless @head.nil?
		@head.act_prev(node) unless @head.nil?
		@head=node unless @head.nil?
		@tail=node if @tail.nil?
		@head=node if @head.nil?
	end 
	def head
		@head
	end
	def tail
		@tail
	end
	def to_s
		node=@tail
		while node!=nil
			puts "linea #{node.linea}, columna #{node.columna}: #{node.to_s} '#{node.id}'"
			node=node.prev
		end
		puts "Documento vacio" if @tail.nil?
	end
end 

class Token
	def initialize(id,linea,columna)
		@id=id
		@linea=linea
		@columna=columna
		@next=nil
		@prev=nil
		@nombre=self.obtener_nombre
	end
	def act_next(node)
		@next=node
	end 
	def obtener_nombre
		nil
	end
	def act_prev(node)
		@prev=node
	end 
	def next
		@next
	end
	def prev
		@prev
	end
	def linea
		@linea
	end
	def columna
		@columna
	end
	def id
		@id
	end
	def tipo
		self.class
	end
	def to_s
    	@nombre
  end
end

$Token = {
	Tipodedatos: /\A(boolean|number)\b/,
	OperadoresLogicos: /\A(not|and|or)\b/,
	LiteralBoleano: /\A(true|false)\b/,
	PalabraReservada: /\A(program|with|do|then|from|to|by|write|writeln|begin|func|while|if|end|repeat|times)\b/,
	OperadoresAritmeticos: /\A(-|\*|\/|%|\+|div\b|mod\b)/,
	Identificadores: /\A[a-z]\w*/,
	OperadoresComparacion_binarios: /\A(\/=|>=|<=|==)/,
	OperadoresComparacion_unarios: /\A(=|<|>)/,
	Signo: /\A(\(|\)|;)/,
	Number: /\A[0-9]+(.[0-9]+){0,1}/,
	Str: /\A".*([^\\]|\\\\)"/
}

class Tipodedatos < Token
	def obtener_nombre
		@nombre="tipo de datos"
	end
end

class OperadoresLogicos < Token
	def obtener_nombre
		@nombre="operador logico"
	end
end

class PalabraReservada < Token
	def obtener_nombre
		@nombre="palabra reservada"
	end
end

class Identificadores < Token
	def obtener_nombre
		@nombre="identificador"
	end
end

class LiteralBoleano < Token
	def obtener_nombre
		@nombre="literal boleano"
	end
end

class OperadoresComparacion_binarios < Token
	def obtener_nombre
		@nombre="signo"
	end
end

class OperadoresAritmeticos < Token
	def obtener_nombre
		@nombre="signo"
	end
end

class OperadoresComparacion_unarios < Token
	def obtener_nombre
		@nombre="signo"
	end
end

class Signo < Token
	def obtener_nombre
		@nombre="signo"
	end
end

class Number < Token
	def obtener_nombre
		@nombre="literal numerico"
	end
end

class Inesperado < Token
	def obtener_nombre
		@nombre="caracter inesperado"
	end
end

class Comilla_abierta < Token
	def obtener_nombre
		@nombre="frontera de String no permitido"
	end
end

class Str < Token
	def obtener_nombre
		@nombre="string"
	end
end

class Str_incorecto < Token
	def obtener_nombre
		@nombre="caracter incorrecto dentro de un string"
	end
end

class Lexer 
	def initialize 
		@lista=Doble_list.new								#Lista que contiene los tokens reconocidos
		@listaerror=Doble_list.new							#Lista que contiene los caracteres no admitidos
		@comilla_abierta=false								#Variable booleana que indica si se ha encontrado un string que incluye saltos de linea
	end

	def catch_lexeme(fila,linea)
		linea=linea.sub(/#.*$/,"")													#Elimina los comentarios de la linea, si existen
		count=1
		linea,count=self.eliminar_espacios_sin_caracter(linea,count)				#Obtiene el string sin espacios en blanco al inicio
		while !linea.empty?
			error=true
			#En caso de encontrase string con saltos de linea incluidos, realiza este proceso para identificar cuando finaliza y los caracteres
			#invalidos que consiga
			if @comilla_abierta 													
				linea,count=self.proceso_salto_de_linea_en_string(linea,count,fila)
			else
			#busqueda de lexema que coincida con alguna expresion regular definida
				$Token.each do |key,value|												#Busqueda de expresión regular que corresponde al token
					if linea=~value
						clase=Object::const_get(key)
						@lista.add($&,fila, count, clase)
						if clase.eql? Str
							self.analisis_str($&[1..($&.length-2)], fila, count)
						end
						count=count+$&.length
						linea=$'
						linea,count=self.eliminar_espacios_sin_caracter(linea, count)
						error=false
						break
					end
				end
				#En caso de no encontrar ninguna expresion regular, realiza el proceso correspondiente para identificar el caracter
				#no valido encontrado
				if error
					linea,count=self.proceso_no_encontrar_caracter(linea, count, fila)
				end
			end 
		end
	end 

	#Proceso para eliminar los espacios en blanco al inicio de la linea, en caso de encontrar un \t, suma 4  columnas
	def eliminar_espacios_sin_caracter(linea, count)
		linea=~/\A\s*/
		c=count
		for i in(0..($&.length-1))
			if linea[i]=~/\t/
				c=c+4
			else 
				c=c+1
			end
		end
		linea=~/\A\s*/
		return [$',c]
	end 

	#Una vez encontrado un string, realiza esta rutina en busqueda de caracteres no validos dentro del string
	def analisis_str (linea, fila, c)
		count=c
		while !linea.empty?
			if linea=~/\A[^\\"]+/
				count=count+$&.length
				linea=$'
				linea,count=self.eliminar_espacios_sin_caracter(linea, count)
			elsif linea=~/\A\\["n\\]/
				count=count+$&.length
				linea=$'
				linea,count=self.eliminar_espacios_sin_caracter(linea, count)
			elsif linea=~/\A"/
				count=count+$&.length
				@listaerror.add($&, fila, count, Str_incorecto)
				linea=$'
				linea,count=self.eliminar_espacios_sin_caracter(linea, count)
			else 
				count=count+1	
				@listaerror.add(linea[0],fila,count, Str_incorecto)
				linea=linea[1..linea.length-1]
				linea,count=self.eliminar_espacios_sin_caracter(linea, count)
			end
		end
	end 

	#Rutina a realizar no coincide ninguna expresion regular con la linea leida
	def proceso_no_encontrar_caracter(linea, count, fila)
		if linea=~/\A[A-Z]\w*/
			@listaerror.add($&,fila,count,Inesperado)
			count=count+$&.length
			linea=$'
			linea,count=self.eliminar_espacios_sin_caracter(linea, count)
		elsif linea=~/\A"/
			@listaerror.add($&, fila, count, Comilla_abierta)
			count=count+$&.length
			linea=$'
			linea,count=self.eliminar_espacios_sin_caracter(linea, count)
			@comilla_abierta=true
		else 																#Proceso cuando el caracter es inesperado
			@listaerror.add(linea[0],fila,count,Inesperado)
			count=count+1
			linea=linea[1..linea.length-1]
			linea,count=self.eliminar_espacios_sin_caracter(linea, count)
		end
		return [linea,count]
	end

	#Rutina a realizar cuando se encuentra un salto de linea dentro de un string
	def proceso_salto_de_linea_en_string(l,c,fila)
		linea=l
		count=c
		if linea=~/\A[^\\"]+/
			#puts 1
			count=count+$&.length
			linea=$'
			linea,count=self.eliminar_espacios_sin_caracter(linea, count)
		elsif linea=~/\A\\("|n|\\)/
			#puts 2
			count=count+$&.length
			linea=$'
			linea,count=self.eliminar_espacios_sin_caracter(linea, count)
		elsif linea=~/\A"/
			#puts 3
			#count=count+1
			@listaerror.add($&, fila, count, Comilla_abierta)
			count=count+1
			linea=$'
			linea,count=self.eliminar_espacios_sin_caracter(linea, count)
			@comilla_abierta=false
		else 	
			#count=count+1
			#puts 4
			@listaerror.add(linea[0],fila,count,Str_incorecto)
			count=count+1
			linea=linea[1..linea.length-1]
			linea,count=self.eliminar_espacios_sin_caracter(linea, count)
		end
		return [linea,count]
	end

	def to_s
		if @listaerror.head.nil?
			@lista.to_s
		else 
			@listaerror.to_s
		end
	end

end