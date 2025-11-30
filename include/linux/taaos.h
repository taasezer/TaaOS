/*
 * TaaOS Kernel Configuration
 * Custom kernel features and optimizations
 */

#ifndef _LINUX_TAAOS_H
#define _LINUX_TAAOS_H

#define TAAOS_VERSION "1.0.0"
#define TAAOS_CODENAME "Rosso Corsa"
#define TAAOS_AUTHOR "Taha Sezer"

/* TaaOS feature flags */
#define CONFIG_TAAOS_NEURAL_ENGINE 1
#define CONFIG_TAAOS_AI_BOOST 1
#define CONFIG_TAAOS_OPTIMIZATIONS 1

/* Kernel optimization flags */
#ifdef CONFIG_TAAOS_OPTIMIZATIONS
#define TAAOS_TIMER_FREQ 1000
#define TAAOS_PREEMPT_LATENCY 1
#define TAAOS_IO_SCHEDULER "bfq"
#endif

/* Neural Engine integration */
#ifdef CONFIG_TAAOS_NEURAL_ENGINE
extern int taaos_neural_engine_init(void);
extern void taaos_neural_engine_exit(void);
#endif

/* Proc filesystem entries */
#define TAAOS_PROC_DIR "taaos"
#define TAAOS_PROC_INFO "info"
#define TAAOS_PROC_STATS "stats"

#endif /* _LINUX_TAAOS_H */
