CONFIG_DIR=${HOME}/.config/awesome
install:
	mkdir -p $$(dirname ${CONFIG_DIR})
	ln -s ${PWD} ${CONFIG_DIR}
uninstall:
	rm ${CONFIG_DIR}
