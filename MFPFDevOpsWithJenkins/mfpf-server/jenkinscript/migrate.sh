   #### Migrate the project WAR files
   # check if user has overridden JAVA_HOME . else set to standard location
   if [ -z "$JAVA_HOME" ]
   then
      # export JAVA_HOME = "/usr/java"
      echo "JAVA_HOME not set. Please set JAVA_HOME for MFP migration to continue"
      exit 1
   else
      echo "JAVA_HOME:" $JAVA_HOME
   fi

   for d in ../usr/projects/*/
   do
       if [[ -d $d ]]; then
         for war in $d/bin/*.war; do
            echo "******* Migrating:" $war "********"
            ../../mfpf-libs/apache-ant-1.9.4/bin/ant -f migrate.xml -Dwarfile=$war
         done
       fi
   done

